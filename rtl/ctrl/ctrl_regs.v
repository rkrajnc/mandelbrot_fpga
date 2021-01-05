// ctrl_regs.v
// control registers module
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


module ctrl_regs #(
  // QMEM bus params
  parameter QAW = 22,             // qmem address width
  parameter QDW = 32,             // qmem data width
  parameter QSW = QDW/8,          // qmem select width
  // width params
  parameter FPW = 2*27,           // mandelbrot params width
  parameter CW  = 12              // video counter width
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
  output reg  [FPW-1:0] man_ys,
  output reg  [ CW-1:0] man_hres,
  output reg  [ CW-1:0] man_vres,
  output reg  [ 32-1:0] man_npixels,
  input  wire [ 32-1:0] man_niters,
  input  wire [ 32-1:0] man_timer,
  input  wire           man_st_done,
  output reg  [  3-1:0] vid_fader,
  output reg            con_we,
  output reg  [QAW-2:0] con_adr,
  output reg  [  8-1:0] con_dat_w
);


//// local parameters ////
// address width for register decoding
localparam RAW = 11;

// man_done reg [RO]
localparam [RAW-1:0] MAN_DONE_ADR     = 'h00;
// man_init reg [WO]
localparam [RAW-1:0] MAN_INIT_ADR     = 'h01;
// man_x0_0 reg [WO]
localparam [RAW-1:0] MAN_X0_0_ADR     = 'h02;
// man_x0_1 reg [WO]
localparam [RAW-1:0] MAN_X0_1_ADR     = 'h03;
// man_y0_0 reg [WO]
localparam [RAW-1:0] MAN_Y0_0_ADR     = 'h04;
// man_y0_1 reg [WO]
localparam [RAW-1:0] MAN_Y0_1_ADR     = 'h05;
// man_xs_0 reg [WO]
localparam [RAW-1:0] MAN_XS_0_ADR     = 'h06;
// man_xs_1 reg [WO]
localparam [RAW-1:0] MAN_XS_1_ADR     = 'h07;
// man_ys_0 reg [WO]
localparam [RAW-1:0] MAN_YS_0_ADR     = 'h08;
// man_ys_1 reg [WO]
localparam [RAW-1:0] MAN_YS_1_ADR     = 'h09;
// man_hres reg [WO]
localparam [RAW-1:0] MAN_HRES_ADR     = 'h0a;
// man_vres reg [WO]
localparam [RAW-1:0] MAN_VRES_ADR     = 'h0b;
// man_npixels reg [WO]
localparam [RAW-1:0] MAN_NPIXELS_ADR  = 'h0c;
// man_st_done reg [RO]
localparam [RAW-1:0] MAN_ST_DONE_ADR  = 'h0d;
// man_niters reg [RO]
localparam [RAW-1:0] MAN_NITERS_ADR   = 'h0e;
// man_timer reg [RO]
localparam [RAW-1:0] MAN_TIMER_ADR    = 'h0f;
// vid_fader reg [WO]
localparam [RAW-1:0] VID_FADER_ADR    = 'h10;
// timer en reg [WO]
localparam [RAW-1:0] TIMER_EN_ADR     = 'h20;
// timer clr reg [WO]
localparam [RAW-1:0] TIMER_CLR_ADR    = 'h21;
// timer reg [RW]
localparam [RAW-1:0] TIMER_ADR        = 'h22;


//// sync signals ////
reg [1:0] man_done_r;
reg [1:0] man_st_done_r;

always @ (posedge clk, posedge rst) begin
  if (rst) begin
    man_done_r <= #1 2'b11;
    man_st_done_r <= #1 2'b11;
  end else begin
    man_done_r <= #1 {man_done_r[0], man_done};
    man_st_done_r <= #1 {man_st_done_r[0], man_st_done};
  end
end


//// write regs decoder ////
reg man_init_wren     = 0;
reg man_x0_0_wren     = 0;
reg man_x0_1_wren     = 0;
reg man_y0_0_wren     = 0;
reg man_y0_1_wren     = 0;
reg man_xs_0_wren     = 0;
reg man_xs_1_wren     = 0;
reg man_ys_0_wren     = 0;
reg man_ys_1_wren     = 0;
reg man_hres_wren     = 0;
reg man_vres_wren     = 0;
reg man_npixels_wren  = 0;
reg vid_fader_wren    = 0;
reg timer_en_wren     = 0;
reg timer_clr_wren    = 0;
reg timer_wren        = 0;

always @ (*) begin
  if (cs && we) begin
    man_init_wren     = 1'b0;
    man_x0_0_wren     = 1'b0;
    man_x0_1_wren     = 1'b0;
    man_y0_0_wren     = 1'b0;
    man_y0_1_wren     = 1'b0;
    man_xs_0_wren     = 1'b0;
    man_xs_1_wren     = 1'b0;
    man_ys_0_wren     = 1'b0;
    man_ys_1_wren     = 1'b0;
    man_hres_wren     = 1'b0;
    man_vres_wren     = 1'b0;
    man_npixels_wren  = 1'b0;
    vid_fader_wren    = 1'b0;
    timer_en_wren     = 1'b0;
    timer_clr_wren    = 1'b0;
    timer_wren        = 1'b0;
    case(adr[RAW+2-1:2])
      MAN_INIT_ADR    : man_init_wren     = 1'b1;
      MAN_X0_0_ADR    : man_x0_0_wren     = 1'b1;
      MAN_X0_1_ADR    : man_x0_1_wren     = 1'b1;
      MAN_Y0_0_ADR    : man_y0_0_wren     = 1'b1;
      MAN_Y0_1_ADR    : man_y0_1_wren     = 1'b1;
      MAN_XS_0_ADR    : man_xs_0_wren     = 1'b1;
      MAN_XS_1_ADR    : man_xs_1_wren     = 1'b1;
      MAN_YS_0_ADR    : man_ys_0_wren     = 1'b1;
      MAN_YS_1_ADR    : man_ys_1_wren     = 1'b1;
      MAN_HRES_ADR    : man_hres_wren     = 1'b1;
      MAN_VRES_ADR    : man_vres_wren     = 1'b1;
      MAN_NPIXELS_ADR : man_npixels_wren  = 1'b1;
      VID_FADER_ADR   : vid_fader_wren    = 1'b1;
      TIMER_EN_ADR    : timer_en_wren     = 1'b1;
      TIMER_CLR_ADR   : timer_clr_wren    = 1'b1;
      TIMER_ADR       : timer_wren        = 1'b1;
      default : begin
        man_init_wren     = 1'b0;
        man_x0_0_wren     = 1'b0;
        man_x0_1_wren     = 1'b0;
        man_y0_0_wren     = 1'b0;
        man_y0_1_wren     = 1'b0;
        man_xs_0_wren     = 1'b0;
        man_xs_1_wren     = 1'b0;
        man_ys_0_wren     = 1'b0;
        man_ys_1_wren     = 1'b0;
        man_hres_wren     = 1'b0;
        man_vres_wren     = 1'b0;
        man_npixels_wren  = 1'b0;
        vid_fader_wren    = 1'b0;
        timer_en_wren     = 1'b0;
        timer_clr_wren    = 1'b0;
        timer_wren        = 1'b0;
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
    man_hres_wren     = 1'b0;
    man_vres_wren     = 1'b0;
    man_npixels_wren  = 1'b0;
    vid_fader_wren    = 1'b0;
    timer_en_wren     = 1'b0;
    timer_clr_wren    = 1'b0;
    timer_wren        = 1'b0;
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


//// man_hres ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    man_hres <= #1 'd800;
  else if (man_hres_wren)
    man_hres <= #1 dat_w[CW-1:0];
end


//// man_vres ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    man_vres <= #1 'd600;
  else if (man_vres_wren)
    man_vres <= #1 dat_w[CW-1:0];
end


//// man_npixels ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    man_npixels <= #1 800*600;
  else if (man_npixels_wren)
    man_npixels <= #1 dat_w[32-1:0];
end


//// vid_fader ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    vid_fader <= #1 'd0;
  else if (vid_fader_wren)
    vid_fader <= #1 dat_w[3-1:0];
end


//// timer ////
reg          timer_en;
reg [32-1:0] timer=0;

always @ (posedge clk, posedge rst) begin
  if (rst)
    timer_en <= #1 1'b0;
  else if (timer_en_wren)
    timer_en <= #1 dat_w[0];
end

always @ (posedge clk) begin
  if (timer_clr_wren && dat_w[0])
    timer <= #1 'd0;
  else if (timer_wren)
    timer <= #1 dat_w[32-1:0];
  else if (timer_en)
    timer <= #1 timer + 'd1;
end


//// registers read ////
always @ (posedge clk) begin
  if (cs && !we) begin
    case(adr[RAW+2-1:2])
      MAN_DONE_ADR    : dat_r <= #1 {31'h0, man_done_r[1]};
      MAN_ST_DONE_ADR : dat_r <= #1 {31'h0, man_st_done_r[1]};
      MAN_NITERS_ADR  : dat_r <= #1 man_niters;
      MAN_TIMER_ADR   : dat_r <= #1 man_timer;
      TIMER_ADR       : dat_r <= #1 timer;
      default         : dat_r <= #1 32'hxxxxxxxx;
    endcase
  end
end


//// ack ////
assign ack = 1'b1;


//// err ////
assign err = 1'b0;


//// con bus ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    con_we <= #1 1'b0;
  else
    con_we <= #1 adr[11] && cs && we;
end

always @ (posedge clk) begin
  con_adr <= #1 adr;
  con_dat_w <= #1 dat_w[7:0];
end


endmodule

