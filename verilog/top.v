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

  // Convert 25MHz input clock to 65MHz by multiplying by 13/5.
  wire ck_fb, clk;
  DCM #(
     .CLKFX_MULTIPLY(13),
     .CLKFX_DIVIDE(5),
     .DFS_FREQUENCY_MODE("LOW"),
     .DUTY_CYCLE_CORRECTION("TRUE"),
     .STARTUP_WAIT("TRUE")
  ) DCM_inst (
     .CLKIN(clka),     // Clock input (from IBUFG, BUFG or DCM)
     .CLK0(ck_fb),    
     .CLKFX(clk), 
     .CLKFB(ck_fb),    // DCM clock feedback
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

  assign {AUDIOL, AUDIOR} = 2'b00;
  assign flashMOSI = MOSI;
  assign flashSCK = SCK;
  assign flashSSEL = AUX;

  assign MISO = (SSEL == 0) ? textMISO : flashMISO;
endmodule

// SPI controller
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

// A 16384x8 RAM with one write port and one read port
module ram16k(
  input         wclk,
  input         write,
  input [13:0]  waddr,
  input [7:0]   din,

  input         rclk,
  input  [13:0] raddr,
  output [7:0]  dout);

  //synthesis attribute ram_style of mem is block
  reg    [7:0]  mem[0:16383]; //pragma attribute mem ram_block TRUE
  reg    [13:0]  raddr_reg;

  always @ (posedge wclk)
    if (write)
      mem[waddr]  <= din;  

  always @ (posedge rclk)
    raddr_reg  <= raddr;

  assign dout = mem[raddr_reg];
endmodule

module textmode(
  input wclk,                   // write clock
  input write,                  // write enable
  input [14:0] addr,            // write address 0-32767
  input [7:0] d,                // write data

  input clk,                    // pixel clock
  input [6:0] scroll,           // Y scroll value, 0-127
  output reg [2:0] vga_red,     // VGA output signals
  output reg [2:0] vga_green,
  output reg [2:0] vga_blue,
  output reg vga_hsync_n,
  output reg vga_vsync_n);

  // These timing values come from
  // http://tinyvga.com/vga-timing/1024x768@60Hz

  // hcounter:
  //  0   -1023   visible area
  //  1024-1047   front porch
  //  1048-1183   sync pulse
  //  1184-1343   back porch

  reg [10:0] hcounter;
  wire [10:0] hcounterN = (hcounter == 11'd1343) ? 11'd0 : (hcounter + 11'd1);

  // vcounter:
  //  0  -767     visible area
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
  ram16k attr(.wclk(wclk), .rclk(clk), .write(write & (addr[0] == 0)), .waddr(addr[14:1]), .raddr(raddr), .din(d), .dout(ram_char));
  ram16k char(.wclk(wclk), .rclk(clk), .write(write & (addr[0] == 1)), .waddr(addr[14:1]), .raddr(raddr), .din(d), .dout(ram_attr));

  wire pix;
  fontrom fr(.clk(clk), .ch(ram_char), .row(vcounterN[3:0]), .col(hcounterN[2:0] - 1), .pix(pix));

  reg pix_;
  reg [7:0] attr1, attr2;
  reg [1:0] visible_;
  reg [1:0] hsync_;
  always @(posedge clk) begin
    pix_ <= pix;
    {attr2, attr1} <= {attr1, ram_attr};
    visible_ <= {visible_[0], visible};
    hsync_ <= {hsync_[0], !((1048 <= hcounter) & (hcounter < 1184))};
  end
  wire [3:0] index = pix_ ? attr2[3:0] : attr2[7:4];
  reg [2:0] r, g, b;
  always @*
    case (index)
    0:    {r, g, b} = { 3'b000, 3'b000, 3'b000 };
    1:    {r, g, b} = { 3'b000, 3'b000, 3'b101 };
    2:    {r, g, b} = { 3'b000, 3'b101, 3'b000 };
    3:    {r, g, b} = { 3'b000, 3'b101, 3'b101 };
    4:    {r, g, b} = { 3'b101, 3'b000, 3'b000 };
    5:    {r, g, b} = { 3'b101, 3'b000, 3'b101 };
    6:    {r, g, b} = { 3'b101, 3'b010, 3'b000 };
    7:    {r, g, b} = { 3'b101, 3'b101, 3'b101 };
    8:    {r, g, b} = { 3'b010, 3'b010, 3'b010 };
    9:    {r, g, b} = { 3'b010, 3'b010, 3'b111 };
    10:   {r, g, b} = { 3'b010, 3'b111, 3'b010 };
    11:   {r, g, b} = { 3'b010, 3'b111, 3'b111 };
    12:   {r, g, b} = { 3'b111, 3'b010, 3'b010 };
    13:   {r, g, b} = { 3'b111, 3'b010, 3'b111 };
    14:   {r, g, b} = { 3'b111, 3'b111, 3'b010 };
    15:   {r, g, b} = { 3'b111, 3'b111, 3'b111 };
    endcase

  always @(posedge clk) begin
    hcounter <= hcounterN;
    vcounter <= vcounterN;
    vga_hsync_n <= hsync_[1];
    vga_vsync_n <= !((771 <= vcounter) & (vcounter < 777));
    vga_red   <= visible_[1] ? r : 3'b000;
    vga_green <= visible_[1] ? g : 3'b000;
    vga_blue  <= visible_[1] ? b : 3'b000;
  end
endmodule
