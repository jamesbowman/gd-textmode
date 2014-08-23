`default_nettype none

module top(
  input clka,
  output [2:0] vga_red,
  output [2:0] vga_green,
  output [2:0] vga_blue,
  output vga_hsync_n,
  output vga_vsync_n,

  input SCK,  // arduino 13
  input MOSI, // arduino 11
  output MISO, // arduino 12
  input SSEL, // arduino 9
  input AUX,  // arduino 2
  output AUDIOL,
  output AUDIOR,

  output flashMOSI,
  input  flashMISO,
  output flashSCK,
  output flashSSEL
  );

  wire ck_fb;
  wire clk;
  DCM #(
     .CLKFX_MULTIPLY(13),
     .CLKFX_DIVIDE(5),
     .DFS_FREQUENCY_MODE("LOW"), // HIGH or LOW frequency mode for frequency synthesis
     .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
     .STARTUP_WAIT("TRUE")    // Delay configuration DONE until DCM LOCK, TRUE/FALSE
  ) DCM_inst (
     .CLK0(ck_fb),    
     .CLKFX(clk), 
     .CLKFB(ck_fb),    // DCM clock feedback
     .CLKIN(clka),     // Clock input (from IBUFG, BUFG or DCM)
     .RST(0)
  );

  wire we;
  wire [7:0] wd;
  wire textMISO;

  spi _s (.clk(clk),
          .SCK(SCK),
          .MOSI(MOSI),
          .MISO(textMISO),
          .SSEL(SSEL),
          .we(we),
          .byte_recv(wd),
          .byte_xmit(8'ha0));

  reg [1:0] state;    // 0: scroll, 1: hibyte, 2: lobyte, 3: data
  reg [6:0] scroll;   // Y scroll register, 0-127
  reg[14:0] a;
  wire wclk = SCK;

  textmode tm(.wclk(wclk), 
              .write(we & (state == 3)),
              .addr(a),
              .d(wd),
              .scroll(scroll),
              .clk(clk),
              .vga_red(vga_red),
              .vga_green(vga_green),
              .vga_blue(vga_blue),
              .vga_hsync_n(vga_hsync_n),
              .vga_vsync_n(vga_vsync_n));

  always @(posedge SSEL or posedge SCK)
    if (SSEL == 1)
      state <= 0;
    else if (we)
      case (state)
      0:  begin scroll <= wd[6:0]; state <= 1; end
      1:  begin a[14:8] <= wd[6:0]; state <= 2; end
      2:  begin a[7:0] <= wd; state <= 3; end
      3:  begin a <= a + 1; end
      endcase

  assign AUDIOL = 0;
  assign AUDIOR = 0;

  assign flashMOSI = MOSI;
  assign flashSCK = SCK;
  assign flashSSEL = AUX;

  assign MISO = (SSEL == 0) ? textMISO : flashMISO;

endmodule

module spi(
  input clk,
  input SCK, input MOSI, output MISO, input SSEL,

  output we,
  output [7:0] byte_recv,
  input [7:0] byte_xmit);

  reg [2:0] bit;
  reg [7:0] recv;
  wire [7:0] recvN = {recv[6:0], MOSI};

  always @(posedge SSEL or posedge SCK)
    if (SSEL == 1)
      bit <= 7;
    else begin
      recv <= recvN;
      bit <= bit - 1;
    end

  assign MISO = byte_xmit[bit[2:0]];
  assign byte_recv = recvN;
  assign we = !SSEL & (bit == 0);
endmodule

module ram16k(
    input           wclk,
    input           We,
    input  [13:0]    Waddr,
    input  [7:0]   Din,

    input           rclk,
    input  [13:0]    Raddr,
    output [7:0]   Dout);
 
    //synthesis attribute ram_style of mem is block
    reg    [7:0]  mem[0:16383]; //pragma attribute mem ram_block TRUE
    reg    [13:0]  raddr_reg;
 
    initial begin
        $readmemh("init.hex", mem);
    end

    always @ (posedge wclk)
      if (We)
        mem[Waddr]  <= Din;  
 
    always @ (posedge rclk)
      raddr_reg  <= Raddr;
      // Dout  <= mem[raddr_reg];   //registered read
 
    assign Dout = mem[raddr_reg];  //unregistered read            

endmodule

// The 16 standard VGA colors
module vga16(input [3:0] i,
             output [2:0] r,
             output [2:0] g,
             output [2:0] b);

  reg [5:0] rgbRGB;
  always @*
  case (i)
    0:    rgbRGB = 6'b000000;
    1:    rgbRGB = 6'b000001;
    2:    rgbRGB = 6'b000010;
    3:    rgbRGB = 6'b000011;
    4:    rgbRGB = 6'b000100;
    5:    rgbRGB = 6'b000101;
    6:    rgbRGB = 6'b010100;
    7:    rgbRGB = 6'b000111;
    8:    rgbRGB = 6'b111000;
    9:    rgbRGB = 6'b111001;
    10:   rgbRGB = 6'b111010;
    11:   rgbRGB = 6'b111011;
    12:   rgbRGB = 6'b111100;
    13:   rgbRGB = 6'b111101;
    14:   rgbRGB = 6'b111110;
    15:   rgbRGB = 6'b111111;
  endcase
  assign r = {rgbRGB[2],rgbRGB[5],rgbRGB[2]};
  assign g = {rgbRGB[1],rgbRGB[4],rgbRGB[1]};
  assign b = {rgbRGB[0],rgbRGB[3],rgbRGB[0]};
endmodule

module textmode(
  input wclk,
  input write,
  input [14:0] addr,
  input [7:0] d,

  input clk,
  input [6:0] scroll,
  output reg [2:0] vga_red,
  output reg [2:0] vga_green,
  output reg [2:0] vga_blue,
  output reg vga_hsync_n,
  output reg vga_vsync_n);

  // http://tinyvga.com/vga-timing/1024x768@60Hz

  // hcounter:
  //  0   -1023   visible area
  //  1024-1047   front porch
  //  1048-1183   sync pulse
  //  1184-1343   back porch

  reg [10:0] hcounter;
  wire [10:0] hcounterN = (hcounter == 11'd1343) ? 11'd0 : (hcounter + 11'd1);

  // vcounter:
  //  0  -767     visble area
  //  768-770     front porch
  //  771-776     sync pulse
  //  777-805     back porch

  reg [9:0] vcounter;
  reg [9:0] vcounterN;
  always @*
    if (hcounterN != 11'd0)
      vcounterN = vcounter;
    else if (vcounter != 10'd805)
      vcounterN = vcounter + 1;
    else
      vcounterN = 10'd0;

  wire visible = (hcounter < 1024) & (vcounter < 768);

  wire [7:0] ram_char, ram_attr;
  wire [6:0] row = scroll + vcounterN[9:4];
  wire [13:0] raddr = {row, hcounterN[9:3]};
  ram16k attr(.wclk(wclk), .rclk(clk), .We(write & (addr[0] == 0)), .Waddr(addr[14:1]), .Raddr(raddr), .Din(d), .Dout(ram_char));
  ram16k char(.wclk(wclk), .rclk(clk), .We(write & (addr[0] == 1)), .Waddr(addr[14:1]), .Raddr(raddr), .Din(d), .Dout(ram_attr));

  // assign cc = hcounterN[10:3] + vcounterN[9:4];
  wire pix;
  fontrom fr(.clk(clk), .ch(ram_char), .row(vcounterN[3:0]), .col(hcounterN[2:0] - 1), .pix(pix));

  reg pix_;
  reg [7:0] attr1, attr2;
  always @(posedge clk) begin
    pix_ <= pix;
    {attr2, attr1} <= {attr1, ram_attr};
  end
  wire [3:0] index = pix_ ? attr2[3:0] : attr2[7:4];
  wire [2:0] r, g, b;
  vga16 rgb(.i(index), .r(r), .g(g), .b(b));

  always @(posedge clk) begin
    hcounter <= hcounterN;
    vcounter <= vcounterN;
    vga_hsync_n <= !((1048 <= hcounter) & (hcounter < 1184));
    vga_vsync_n <= !((771 <= vcounter) & (vcounter < 777));
    vga_red   <= visible ? r : 3'b000;
    vga_green <= visible ? g : 3'b000;
    vga_blue  <= visible ? b : 3'b000;
  end
endmodule

