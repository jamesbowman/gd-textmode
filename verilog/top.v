`define YES

module lfsre(
    input clk,
    output reg [16:0] lfsr);
wire d0;

xnor(d0,lfsr[16],lfsr[13]);

always @(posedge clk) begin
    lfsr <= {lfsr[15:0],d0};
end
endmodule

module oldram256x1s(
  input d,
  input we,
  input wclk,
  input [7:0] a,
  output o);

  wire sel0 = (a[7:6] == 0);
  wire o0;
  RAM64X1S r0(.O(o0), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE(sel0 & we));

  wire sel1 = (a[7:6] == 1);
  wire o1;
  RAM64X1S r1(.O(o1), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE(sel1 & we));

  wire sel2 = (a[7:6] == 2);
  wire o2;
  RAM64X1S r2(.O(o2), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE(sel2 & we));

  wire sel3 = (a[7:6] == 3);
  wire o3;
  RAM64X1S r3(.O(o3), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE(sel3 & we));

  assign o = (a[7] == 0) ? ((a[6] == 0) ? o0 : o1) : ((a[6] == 0) ? o2 : o3);
endmodule

module ring64(
  input clk,
  input i,
  output o);

  wire o0, o1, o2;
  SRL16E ring0( .CLK(clk), .CE(1), .D(i),  .A0(1), .A1(1), .A2(1), .A3(1), .Q(o0));
  SRL16E ring1( .CLK(clk), .CE(1), .D(o0), .A0(1), .A1(1), .A2(1), .A3(1), .Q(o1));
  SRL16E ring2( .CLK(clk), .CE(1), .D(o1), .A0(1), .A1(1), .A2(1), .A3(1), .Q(o2));
  SRL16E ring3( .CLK(clk), .CE(1), .D(o2), .A0(1), .A1(1), .A2(1), .A3(1), .Q(o));
endmodule

module ram256x1s(
  input d,
  input we,
  input wclk,
  input [7:0] a,
  output o);

  wire [1:0] rsel = a[7:6];
  wire [3:0] oo;
  genvar i;
  generate 
    for (i = 0; i < 4; i=i+1) begin : ramx
    RAM64X1S r0(.O(oo[i]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE((rsel == i) & we));
    end
  endgenerate

  assign o = oo[rsel];
endmodule

module ram448x1s(
  input d,
  input we,
  input wclk,
  input [8:0] a,
  output o);

  wire [2:0] rsel = a[8:6];
  wire [7:0] oo;
  genvar i;
  generate 
    for (i = 0; i < 7; i=i+1) begin : ramx
      RAM64X1S r0(.O(oo[i]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE((rsel == i) & we));
    end
  endgenerate

  assign o = oo[rsel];
endmodule

module ram400x1s(
  input d,
  input we,
  input wclk,
  input [8:0] a,
  output o);

  wire [2:0] rsel = a[8:6];
  wire [6:0] oo;
  genvar i;
  generate 
    for (i = 0; i < 6; i=i+1) begin : ramx
      RAM64X1S r0(.O(oo[i]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d), .WCLK(wclk), .WE((rsel == i) & we));
    end
  endgenerate
  RAM16X1S r6(.O(oo[6]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .D(d), .WCLK(wclk), .WE((rsel == 6) & we));

  assign o = oo[rsel];
endmodule

module ram256x8s(
  input [7:0] d,
  input we,
  input wclk,
  input [7:0] a,
  output [7:0] o);
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      ram256x1s ramx(
        .d(d[i]),
        .we(we),
        .wclk(wclk),
        .a(a),
        .o(o[i]));
    end
  endgenerate
endmodule

module ram32x8s(
  input [7:0] d,
  input we,
  input wclk,
  input [4:0] a,
  output [7:0] o);
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      RAM32X1S r0(.O(o[i]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .D(d[i]), .WCLK(wclk), .WE(we));
    end
  endgenerate
endmodule

module ram64x8s(
  input [7:0] d,
  input we,
  input wclk,
  input [5:0] a,
  output [7:0] o);
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      RAM64X1S r0(.O(o[i]), .A0(a[0]), .A1(a[1]), .A2(a[2]), .A3(a[3]), .A4(a[4]), .A5(a[5]), .D(d[i]), .WCLK(wclk), .WE(we));
    end
  endgenerate
endmodule

module mRAM32X1D(
  input D,
  input WE,
  input WCLK,
  input A0,     // port A
  input A1,
  input A2,
  input A3,
  input A4,
  input DPRA0,  // port B
  input DPRA1,
  input DPRA2,
  input DPRA3,
  input DPRA4,
  output DPO,   // port A out
  output SPO);  // port B out

  parameter INIT = 32'b0;
  wire hDPO;
  wire lDPO;
  wire hSPO;
  wire lSPO;
  RAM16X1D
    #( .INIT(INIT[15:0]) ) 
    lo(
    .D(D),
    .WE(WE & !A4),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPO(lDPO),
    .SPO(lSPO));
  RAM16X1D
    #( .INIT(INIT[31:16]) ) 
  hi(
    .D(D),
    .WE(WE & A4),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPO(hDPO),
    .SPO(hSPO));
  assign DPO = DPRA4 ? hDPO : lDPO;
  assign SPO = A4 ? hSPO : lSPO;
endmodule

module mRAM64X1D(
  input D,
  input WE,
  input WCLK,
  input A0,     // port A
  input A1,
  input A2,
  input A3,
  input A4,
  input A5,
  input DPRA0,  // port B
  input DPRA1,
  input DPRA2,
  input DPRA3,
  input DPRA4,
  input DPRA5,
  output DPO,   // port A out
  output SPO);  // port B out

  parameter INIT = 64'b0;
  wire hDPO;
  wire lDPO;
  wire hSPO;
  wire lSPO;
  mRAM32X1D
    #( .INIT(INIT[31:0]) ) 
    lo(
    .D(D),
    .WE(WE & !A5),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPO(lDPO),
    .SPO(lSPO));
  mRAM32X1D
    #( .INIT(INIT[63:32]) ) 
  hi(
    .D(D),
    .WE(WE & A5),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPO(hDPO),
    .SPO(hSPO));
  assign DPO = DPRA5 ? hDPO : lDPO;
  assign SPO = A5 ? hSPO : lSPO;
endmodule

module mRAM128X1D(
  input D,
  input WE,
  input WCLK,
  input A0,     // port A
  input A1,
  input A2,
  input A3,
  input A4,
  input A5,
  input A6,
  input DPRA0,  // port B
  input DPRA1,
  input DPRA2,
  input DPRA3,
  input DPRA4,
  input DPRA5,
  input DPRA6,
  output DPO,   // port A out
  output SPO);  // port B out
  parameter INIT = 128'b0;

  wire hDPO;
  wire lDPO;
  wire hSPO;
  wire lSPO;
  mRAM64X1D
    #( .INIT(INIT[63:0]) ) 
    lo(
    .D(D),
    .WE(WE & !A6),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .A5(A5),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPRA5(DPRA5),
    .DPO(lDPO),
    .SPO(lSPO));
  mRAM64X1D
    #( .INIT(INIT[127:64]) ) 
    hi(
    .D(D),
    .WE(WE & A6),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .A5(A5),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPRA5(DPRA5),
    .DPO(hDPO),
    .SPO(hSPO));
  assign DPO = DPRA6 ? hDPO : lDPO;
  assign SPO = A6 ? hSPO : lSPO;
endmodule


module mRAM256X1D(
  input D,
  input WE,
  input WCLK,
  input A0,     // port A
  input A1,
  input A2,
  input A3,
  input A4,
  input A5,
  input A6,
  input A7,
  input DPRA0,  // port B
  input DPRA1,
  input DPRA2,
  input DPRA3,
  input DPRA4,
  input DPRA5,
  input DPRA6,
  input DPRA7,
  output DPO,   // port A out
  output SPO);  // port B out

  wire hDPO;
  wire lDPO;
  wire hSPO;
  wire lSPO;
  mRAM128X1D
    lo(
    .D(D),
    .WE(WE & !A7),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .A5(A5),
    .A6(A6),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPRA5(DPRA5),
    .DPRA6(DPRA6),
    .DPO(lDPO),
    .SPO(lSPO));
  mRAM128X1D
  hi(
    .D(D),
    .WE(WE & A7),
    .WCLK(WCLK),
    .A0(A0),
    .A1(A1),
    .A2(A2),
    .A3(A3),
    .A4(A4),
    .A5(A5),
    .A6(A6),
    .DPRA0(DPRA0),
    .DPRA1(DPRA1),
    .DPRA2(DPRA2),
    .DPRA3(DPRA3),
    .DPRA4(DPRA4),
    .DPRA5(DPRA5),
    .DPRA6(DPRA6),
    .DPO(hDPO),
    .SPO(hSPO));
  assign DPO = DPRA7 ? hDPO : lDPO;
  assign SPO = A7 ? hSPO : lSPO;
endmodule

module ram32x8d(
  input [7:0] ad,
  input wea,
  input wclk,
  input [4:0] a,
  input [4:0] b,
  output [7:0] ao,
  output [7:0] bo
  );
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      mRAM32X1D ramx(
        .D(ad[i]),
        .WE(wea),
        .WCLK(wclk),
        .A0(a[0]),
        .A1(a[1]),
        .A2(a[2]),
        .A3(a[3]),
        .A4(a[4]),
        .DPRA0(b[0]),
        .DPRA1(b[1]),
        .DPRA2(b[2]),
        .DPRA3(b[3]),
        .DPRA4(b[4]),
        .SPO(ao[i]),
        .DPO(bo[i]));
    end
  endgenerate
endmodule

module ram64x8d(
  input [7:0] ad,
  input wea,
  input wclk,
  input [5:0] a,
  input [5:0] b,
  output [7:0] ao,
  output [7:0] bo
  );
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      mRAM64X1D ramx(
        .D(ad[i]),
        .WE(wea),
        .WCLK(wclk),
        .A0(a[0]),
        .A1(a[1]),
        .A2(a[2]),
        .A3(a[3]),
        .A4(a[4]),
        .A5(a[5]),
        .DPRA0(b[0]),
        .DPRA1(b[1]),
        .DPRA2(b[2]),
        .DPRA3(b[3]),
        .DPRA4(b[4]),
        .DPRA5(b[5]),
        .SPO(ao[i]),
        .DPO(bo[i]));
    end
  endgenerate
endmodule

// Same but latched read port, for CPU
module ram32x8rd(
  input wclk,
  input [15:0] ad,
  input wea,
  input [4:0] a,
  input [4:0] b,
  output reg [15:0] ao,
  output reg [15:0] bo
  );
  wire [15:0] _ao;
  wire [15:0] _bo;
  always @(posedge wclk)
  begin
    ao <= _ao;
    bo <= _bo;
  end
  genvar i;
  generate 
    for (i = 0; i < 16; i=i+1) begin : ramx
      mRAM32X1D ramx(
        .D(ad[i]),
        .WE(wea),
        .WCLK(wclk),
        .A0(a[0]),
        .A1(a[1]),
        .A2(a[2]),
        .A3(a[3]),
        .A4(a[4]),
        .DPRA0(b[0]),
        .DPRA1(b[1]),
        .DPRA2(b[2]),
        .DPRA3(b[3]),
        .DPRA4(b[4]),
        .SPO(_ao[i]),
        .DPO(_bo[i]));
    end
  endgenerate
endmodule

module ram128x8rd(
  input wclk,
  input [15:0] ad,
  input wea,
  input [6:0] a,
  input [6:0] b,
  output reg [15:0] ao,
  output reg [15:0] bo
  );
  wire [15:0] _ao;
  wire [15:0] _bo;
  always @(posedge wclk)
  begin
    ao <= _ao;
    bo <= _bo;
  end
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      mRAM128X1D ramx(
        .D(ad[i]),
        .WE(wea),
        .WCLK(wclk),
        .A0(a[0]),
        .A1(a[1]),
        .A2(a[2]),
        .A3(a[3]),
        .A4(a[4]),
        .A5(a[5]),
        .A6(a[6]),
        .DPRA0(b[0]),
        .DPRA1(b[1]),
        .DPRA2(b[2]),
        .DPRA3(b[3]),
        .DPRA4(b[4]),
        .DPRA5(b[5]),
        .DPRA6(b[6]),
        .SPO(_ao[i]),
        .DPO(_bo[i]));
    end
  endgenerate
endmodule

module ram256x8rd(
  input wclk,
  input [7:0] ad,
  input wea,
  input [7:0] a,
  input [7:0] b,
  output reg [7:0] ao,
  output reg [7:0] bo
  );
  wire [7:0] _ao;
  wire [7:0] _bo;
  always @(posedge wclk)
  begin
    ao <= _ao;
    bo <= _bo;
  end
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      mRAM256X1D ramx(
        .D(ad[i]),
        .WE(wea),
        .WCLK(wclk),
        .A0(a[0]),
        .A1(a[1]),
        .A2(a[2]),
        .A3(a[3]),
        .A4(a[4]),
        .A5(a[5]),
        .A6(a[6]),
        .A7(a[7]),
        .DPRA0(b[0]),
        .DPRA1(b[1]),
        .DPRA2(b[2]),
        .DPRA3(b[3]),
        .DPRA4(b[4]),
        .DPRA5(b[5]),
        .DPRA6(b[6]),
        .DPRA7(b[7]),
        .SPO(_ao[i]),
        .DPO(_bo[i]));
    end
  endgenerate
endmodule

module ram448x9s(
  input [8:0] d,
  input we,
  input wclk,
  input [8:0] a,
  output [8:0] o);
  genvar i;
  generate 
    for (i = 0; i < 9; i=i+1) begin : ramx
      ram448x1s ramx(
        .d(d[i]),
        .we(we),
        .wclk(wclk),
        .a(a),
        .o(o[i]));
    end
  endgenerate
endmodule

module ram400x9s(
  input [8:0] d,
  input we,
  input wclk,
  input [8:0] a,
  output [8:0] o);
  genvar i;
  generate 
    for (i = 0; i < 9; i=i+1) begin : ramx
      ram400x1s ramx(
        .d(d[i]),
        .we(we),
        .wclk(wclk),
        .a(a),
        .o(o[i]));
    end
  endgenerate
endmodule

module ram400x8s(
  input [7:0] d,
  input we,
  input wclk,
  input [8:0] a,
  output [7:0] o);
  genvar i;
  generate 
    for (i = 0; i < 8; i=i+1) begin : ramx
      ram400x1s ramx(
        .d(d[i]),
        .we(we),
        .wclk(wclk),
        .a(a),
        .o(o[i]));
    end
  endgenerate
endmodule

module ram400x7s(
  input [6:0] d,
  input we,
  input wclk,
  input [8:0] a,
  output [6:0] o);
  genvar i;
  generate 
    for (i = 0; i < 7; i=i+1) begin : ramx
      ram400x1s ramx(
        .d(d[i]),
        .we(we),
        .wclk(wclk),
        .a(a),
        .o(o[i]));
    end
  endgenerate
endmodule

// SPI can be many things, so to be clear, this implementation:
//   MSB first
//   CPOL 0, leading edge when SCK rises
//   CPHA 0, sample on leading, setup on trailing

module SPI_memory(
  input clk,
  input SCK, input MOSI, output MISO, input SSEL,
  output wire [15:0] raddr,   // read address
  output reg [15:0] waddr,    // write address
  output reg [7:0] data_w,
  input [7:0] data_r,
  output reg we,
  output reg re,
  output mem_clk
);
  reg [15:0] paddr;
  reg [4:0] count;
  wire [4:0] _count = (count == 23) ? 16 : (count + 1);

  assign mem_clk = clk;

  // sync SCK to the FPGA clock using a 3-bits shift register
  reg [2:0] SCKr;  always @(posedge clk) SCKr <= {SCKr[1:0], SCK};
  wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
  wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges

  // same thing for SSEL
  reg [2:0] SSELr;  always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
  wire SSEL_active = ~SSELr[1];  // SSEL is active low
  wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
  wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge

// and for MOSI
  reg [1:0] MOSIr;  always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
  wire MOSI_data = MOSIr[1];

  assign raddr = (count[4] == 0) ? {paddr[14:0], MOSI_data} : paddr;

  always @(posedge clk)
  begin
    if (~SSEL_active) begin
      count <= 0;
      re <= 0;
      we <= 0;
    end else
      if (SCK_risingedge) begin
        if (count[4] == 0) begin
          we <= 0;
          paddr <= raddr;
          re <= (count == 15);
        end else begin
          data_w <= {data_w[6:0], MOSI_data};
          if (count == 23) begin
            we <= paddr[15];
            re <= !paddr[15];
            waddr <= paddr;
            paddr <= paddr + 1;
          end else begin
            we <= 0;
            re <= 0;
          end
        end
        count <= _count;
      end
      if (SCK_fallingedge) begin
        re <= 0;
        we <= 0;
      end
  end

  reg readbit;
  always @*
  begin
    case (count[2:0])
    3'd0: readbit <= data_r[7];
    3'd1: readbit <= data_r[6];
    3'd2: readbit <= data_r[5];
    3'd3: readbit <= data_r[4];
    3'd4: readbit <= data_r[3];
    3'd5: readbit <= data_r[2];
    3'd6: readbit <= data_r[1];
    3'd7: readbit <= data_r[0];
    endcase
  end
  assign MISO = readbit;

endmodule

// This is a Delta-Sigma Digital to Analog Converter
`define MSBI 12 // Most significant Bit of DAC input, 12 means 13-bit

module dac(DACout, DACin, Clk, Reset);
output DACout;         // This is the average output that feeds low pass filter
reg DACout;            // for optimum performance, ensure that this ff is in IOB
input [`MSBI:0] DACin; // DAC input (excess 2**MSBI)
input Clk;
input Reset;
reg [`MSBI+2:0] DeltaAdder; // Output of Delta adder
reg [`MSBI+2:0] SigmaAdder; // Output of Sigma adder
reg [`MSBI+2:0] SigmaLatch; // Latches output of Sigma adder
reg [`MSBI+2:0] DeltaB; // B input of Delta adder

always @(SigmaLatch) DeltaB = {SigmaLatch[`MSBI+2], SigmaLatch[`MSBI+2]} << (`MSBI+1);
always @(DACin or DeltaB) DeltaAdder = DACin + DeltaB;
always @(DeltaAdder or SigmaLatch) SigmaAdder = DeltaAdder + SigmaLatch;
always @(posedge Clk or posedge Reset)
begin
  if (Reset) begin
    SigmaLatch <= #1 1'b1 << (`MSBI+1);
    DACout <= #1 1'b0;
  end else begin
    SigmaLatch <= #1 SigmaAdder;
    DACout <= #1 SigmaLatch[`MSBI+2];
  end
end
endmodule

module top(
  input clka,
  output [2:0] vga_red,
  output [2:0] vga_green,
  output [2:0] vga_blue,
  output reg vga_hsync_n,
  output reg vga_vsync_n,

  input SCK,  // arduino 13
  input MOSI, // arduino 11
  inout MISO, // arduino 12
  input SSEL, // arduino 9
  inout AUX,  // arduino 2
  output AUDIOL,
  output AUDIOR,

  output flashMOSI,
  input  flashMISO,
  output flashSCK,
  output flashSSEL

  );

  wire mem_clk;
  wire [7:0] host_mem_data_wr;
  reg [7:0] mem_data_rd;
  reg [7:0] latched_mem_data_rd;
  wire [14:0] mem_w_addr;   // Combined write address
  wire [14:0] mem_r_addr;   // Combined read address
  wire [14:0] host_mem_w_addr;
  wire [14:0] host_mem_r_addr;
  wire host_mem_wr;
  wire mem_rd;

  wire clk;
  ck_div #(.DIV_BY(5), .MULT_BY(13)) ck_gen(.ck_in(clka), .ck_out(clk));

  assign AUDIOL = 0;
  assign AUDIOR = 0;

  assign flashMOSI = 0;
  assign flashSCK = 0;
  assign flashSSEL = 0;

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
  wire [9:0] vcounterN = (hcounterN != 11'd0) ? vcounter : ((vcounter == 10'd805) ? 10'd0 : (vcounter + 10'd1));

  always @(posedge clk) begin
    hcounter <= hcounterN;
    vcounter <= vcounterN;
    vga_hsync_n <= !((1048 <= hcounter) & (hcounter < 1184));
    vga_vsync_n <= !((771 <= vcounter) & (vcounter < 777));
  end

  assign vga_red = 3'b000;
  assign vga_green = 3'b000;
  assign vga_blue = 3'b000;
    
endmodule // top
