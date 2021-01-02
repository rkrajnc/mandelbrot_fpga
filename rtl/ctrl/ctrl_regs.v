// ctrl_regs.v
// control registers module
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


module ctrl_regs #(
  // QMEM bus params
  parameter QAW = 22,             // qmem address width
  parameter QDW = 32,             // qmem data width
  parameter QSW = QDW/8,          // qmem select width
  // width params
  parameter FPW = 2*27            // mandelbrot params width
)(
  // system
  input  wire           clk,
  input  wire           rst,
  // qmem bus
  input  wire [QAW-1:0] adr,
  input  wire           cs,
  input  wire           we,
  input  wire [QSW-1:0] sel,
  input  wire [QDW-1:0] dat_w,
  output reg  [QDW-1:0] dat_r,
  output wire           ack,
  output wire           err,
  // io
  input  wire           man_done,
  output reg            man_init,
  output reg  [FPW-1:0] man_x0,
  output reg  [FPW-1:0] man_y0,
  output reg  [FPW-1:0] man_xs,
  output reg  [FPW-1:0] man_ys
);


//// local parameters ////
// address width for register decoding
localparam RAW = 4;

// man_done reg [RO]
localparam [RAW-1:0] MAN_DONE_ADR   = 'h00;
// man_init reg [WO]
localparam [RAW-1:0] MAN_INIT_ADR   = 'h01;
// man_x0_0 reg [WO]
localparam [RAW-1:0] MAN_X0_0_ADR   = 'h02;
// man_x0_1 reg [WO]
localparam [RAW-1:0] MAN_X0_1_ADR   = 'h03;
// man_y0_0 reg [WO]
localparam [RAW-1:0] MAN_Y0_0_ADR   = 'h04;
// man_y0_1 reg [WO]
localparam [RAW-1:0] MAN_Y0_1_ADR   = 'h05;
// man_xs_0 reg [WO]
localparam [RAW-1:0] MAN_XS_0_ADR   = 'h06;
// man_xs_1 reg [WO]
localparam [RAW-1:0] MAN_XS_1_ADR   = 'h07;
// man_ys_0 reg [WO]
localparam [RAW-1:0] MAN_YS_0_ADR   = 'h08;
// man_ys_1 reg [WO]
localparam [RAW-1:0] MAN_YS_1_ADR   = 'h09;


//// write regs decoder ////
reg man_init_wren = 0;
reg man_x0_0_wren = 0;
reg man_x0_1_wren = 0;
reg man_y0_0_wren = 0;
reg man_y0_1_wren = 0;
reg man_xs_0_wren = 0;
reg man_xs_1_wren = 0;
reg man_ys_0_wren = 0;
reg man_ys_1_wren = 0;

always @ (*) begin
  if (cs && we) begin
    man_init_wren = 1'b0;
    man_x0_0_wren = 1'b0;
    man_x0_1_wren = 1'b0;
    man_y0_0_wren = 1'b0;
    man_y0_1_wren = 1'b0;
    man_xs_0_wren = 1'b0;
    man_xs_1_wren = 1'b0;
    man_ys_0_wren = 1'b0;
    man_ys_1_wren = 1'b0;
    case(adr[RAW+2-1:2])
      MAN_INIT_ADR : man_init_wren = 1'b1;
      MAN_X0_0_ADR : man_x0_0_wren = 1'b1;
      MAN_X0_1_ADR : man_x0_1_wren = 1'b1;
      MAN_Y0_0_ADR : man_y0_0_wren = 1'b1;
      MAN_Y0_1_ADR : man_y0_1_wren = 1'b1;
      MAN_XS_0_ADR : man_xs_0_wren = 1'b1;
      MAN_XS_1_ADR : man_xs_1_wren = 1'b1;
      MAN_YS_0_ADR : man_ys_0_wren = 1'b1;
      MAN_YS_1_ADR : man_ys_1_wren = 1'b1;
      default : begin
        man_init_wren = 1'b0;
        man_x0_0_wren = 1'b0;
        man_x0_1_wren = 1'b0;
        man_y0_0_wren = 1'b0;
        man_y0_1_wren = 1'b0;
        man_xs_0_wren = 1'b0;
        man_xs_1_wren = 1'b0;
        man_ys_0_wren = 1'b0;
        man_ys_1_wren = 1'b0;
      end
    endcase
  end else begin
    man_init_wren = 1'b0;
    man_x0_0_wren = 1'b0;
    man_x0_1_wren = 1'b0;
    man_y0_0_wren = 1'b0;
    man_y0_1_wren = 1'b0;
    man_xs_0_wren = 1'b0;
    man_xs_1_wren = 1'b0;
    man_ys_0_wren = 1'b0;
    man_ys_1_wren = 1'b0;
  end
end


//// man_init ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    man_init <= #1 1'b0;
  else if (man_init_wren)
    man_init <= #1 dat_w[0];
end


//// man_x0 ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    man_x0 <= #1 54'h3bd55555555556;
  else if (man_x0_0_wren)
    man_x0[31: 0] <= #1 dat_w[31:0];
  else if (man_x0_1_wren)
    man_x0[53:32] <= #1 dat_w[21:0];
end


//// man_y0 ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    man_y0 <= #1 54'h3e000000000000;
  else if (man_y0_0_wren)
    man_y0[31: 0] <= #1 dat_w[31:0];
  else if (man_y0_1_wren)
    man_y0[53:32] <= #1 dat_w[21:0];
end


//// man_xs ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    man_xs <= #1 54'h0001b4e81b4e81;
  else if (man_xs_0_wren)
    man_xs[31: 0] <= #1 dat_w[31:0];
  else if (man_xs_1_wren)
    man_xs[53:32] <= #1 dat_w[21:0];
end


//// man_ys ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    man_ys <= #1 54'h0001b4e81b4e81;
  else if (man_ys_0_wren)
    man_ys[31: 0] <= #1 dat_w[31:0];
  else if (man_ys_1_wren)
    man_ys[53:32] <= #1 dat_w[21:0];
end


//// man_done read ////
reg [1:0] man_done_r;

always @ (posedge clk, posedge rst) begin
  if (rst)
    man_done_r <= #1 2'b00;
  else
    man_done_r <= #1 {man_done_r[0], man_done};
end

always @ (posedge clk) begin
  if (cs && !we) begin
    case(adr[RAW+2-1:2])
      MAN_DONE_ADR  : dat_r <= #1 {31'h0, man_done_r[1]};
      default       : dat_r <= #1 32'hxxxxxxxx;
    endcase
  end
end


//// ack ////
assign ack = 1'b1;


//// err ////
assign err = 1'b0;


endmodule

