// mandelbrot_top.v
// top-level mandelbrot module
// 2020, Rok Krajnc <rok.krajnc@gmail,com>


module mandelbrot_top #(
  parameter NCALC     = 8,                  // number of mandelbrot calculation engines
  parameter FPW       = 2*27,               // bitwidth of fixed-point numbers
  parameter MAXITERS  = 256,                // max number of iterations
  parameter IW        = $clog2(MAXITERS),   // width of iteration output value
  parameter AW        = 12,                 // address width
  parameter CW        = 12,                 // screen coordinates counters width
  parameter FD        = 8                   // fifo depth
)(
  // system
  input  wire                   clk,        // clock
  input  wire                   clk_en,     // clock enable
  input  wire                   rst,        // reset
  // control
  input  wire                   init,       // enable mandelbrot calculation (posedge sensitive!)
  output wire                   done,       // mandelbrot engine done
  // config
  input  wire        [  CW-1:0] hres,       // horizontal resolution
  input  wire        [  CW-1:0] vres,       // vertical resolution
  input  wire        [  32-1:0] npixels,    // number of pixels (for stats)
  input  wire signed [ FPW-1:0] man_x0,     // leftmost Mandelbrot coordinate
  input  wire signed [ FPW-1:0] man_y0,     // uppermost Mandelbrot coordinate
  input  wire signed [ FPW-1:0] man_xs,     // Mandelbrot x step
  input  wire signed [ FPW-1:0] man_ys,     // Mandelbrot y step
  // stats output
  output reg         [  32-1:0] niters,     // number of all iterations
  output reg         [  32-1:0] timer,      // timer
  output reg                    stats_done, // statistics done
  // mandelbrot output
  input  wire                   out_rdy,    // output ready to receive (ack)
  output wire                   out_vld,    // output valid
  output wire        [  IW-1:0] out_dat,    // number of iterations
  output wire        [  AW-1:0] out_adr     // mandelbrot coordinate address output
);


//// mandelbrot coordinates ////
wire            coord_rdy;
wire            coord_vld;
wire [ FPW-1:0] x;
wire [ FPW-1:0] y;
wire [  AW-1:0] adr;

mandelbrot_coords #(
  .CW     (CW    ), // screen counter width
  .AW     (AW    ), // address width
  .FPW    (FPW   )  // fixed point size
) mandelbrot_coords (
  .clk      (clk      ),  // clock
  .clk_en   (clk_en   ),  // clock enable
  .rst      (rst      ),  // reset
  .init     (init     ),  // initialize coord engine
  .done     (done     ),  // coord engine done
  .hres     (hres     ),  // horizontal resolution
  .vres     (vres     ),  // vertical resolution
  .man_x0   (man_x0   ),  // leftmost Mandelbrot coordinate
  .man_y0   (man_y0   ),  // uppermost Mandelbrot coordinate
  .man_xs   (man_xs   ),  // Mandelbrot x step
  .man_ys   (man_ys   ),  // Mandelbrot y step
  .out_rdy  (coord_rdy),  // output ready to recieve (ack)
  .out_vld  (coord_vld),  // output valid
  .x        (x        ),  // Mandelbrot x coordinate output
  .y        (y        ),  // Mandelbrot y coordinate output
  .adr      (adr      )   // Mandelbrot address output
);


//// coord-to-calc fifo ////
localparam FDW = FPW+FPW+AW;

wire            fifo_en;
wire [ FDW-1:0] fifo_in;
wire [ FDW-1:0] fifo_out;
wire            fifo_wr_en;
wire            fifo_rd_en;
wire            fifo_full;
wire            fifo_empty;

assign fifo_en    = 1'b1;
assign fifo_in    = {adr, y, x};
assign fifo_wr_en = coord_vld && !fifo_full;
assign coord_rdy  = !fifo_full;

sync_fifo #(
  .FD   (FD),   // fifo depth
  .DW   (FDW)   // data width
) mandelbrot_fifo (
  .clk      (clk        ), // clock
  .clk_en   (clk_en     ), // clock enable
  .rst      (rst        ), // reset
  .en       (fifo_en    ), // enable (if !en, reset fifo)
  .in       (fifo_in    ), // write data
  .out      (fifo_out   ), // read data
  .wr_en    (fifo_wr_en ), // fifo write enable
  .rd_en    (fifo_rd_en ), // fifo read enable
  .full     (fifo_full  ), // fifo full
  .empty    (fifo_empty ), // fifo empty
  .half     (           )  // fifo is less than half full
);


//// stream_distributor ////
wire sd_in_vld;
wire sd_in_rdy;
wire [ NCALC-1:0] sd_out_vld;
wire [ NCALC-1:0] sd_out_rdy;
wire [   FDW-1:0] sd_out_dat;

assign sd_in_vld = !fifo_empty;
assign fifo_rd_en = sd_in_rdy && !fifo_empty;

stream_distributor #(
  .NS (NCALC),  // number of sinks
  .DW (FDW)     // data width
) mandelbrot_sd (
  .clk      (clk        ),  // clock
  .clk_en   (clk_en     ),  // clock enable
  .rst      (rst        ),  // reset
  .in_vld   (sd_in_vld  ),  // input valid
  .in_rdy   (sd_in_rdy  ),  // input ack
  .in_dat   (fifo_out   ),  // input data
  .out_vld  (sd_out_vld ),  // output valid
  .out_rdy  (sd_out_rdy ),  // output ack
  .out_dat  (sd_out_dat )   // output data
);


//// mandelbrot calculate ////
wire [ FPW-1:0] calc_x;
wire [ FPW-1:0] calc_y;
wire [  AW-1:0] calc_adr;

assign {calc_adr, calc_y, calc_x} = sd_out_dat;

// TODO!
wire [NCALC-1:0] sc_in_vld;
wire [NCALC-1:0] sc_in_rdy;
wire [NCALC*IW-1:0] calc_iters;
wire [NCALC*AW-1:0] calc_adrs;

mandelbrot_calc #(
  .MAXITERS (MAXITERS), // max number of iterations
  .IW       (IW),       // width of iteration vars
  .FPW      (FPW),      // bitwidth of fixed-point numbers
  .AW       (AW)        // address width
) mandelbrot_calc_wrap[NCALC-1:0] (
  .clk      (clk        ),  // clock
  .clk_en   (clk_en     ),  // clock enable
  .rst      (rst        ),  // reset
  .in_vld   (sd_out_vld ),  // input valid
  .in_rdy   (sd_out_rdy ),  // input ack
  .x_man    (calc_x     ),  // mandelbrot x coordinate
  .y_man    (calc_y     ),  // mandelbrot y cooridnate
  .adr_i    (calc_adr   ),  // mandelbrot coordinate address input
  .out_rdy  (sc_in_rdy  ),  // output ack
  .out_vld  (sc_in_vld  ),  // output valid
  .niter    (calc_iters ),  // number of iterations
  .adr_o    (calc_adrs  )   // mandelbrot coordinate address output
);

wire [NCALC-1:0][AW+IW-1:0] calc_data;

genvar d;
generate for (d=0; d<NCALC; d=d+1)  begin : SC_DAT_BLK
  assign calc_data[d] = {calc_iters[(d+1)*IW-1:d*IW], calc_adrs[(d+1)*AW-1:d*AW]};
end endgenerate


//// stream collector ////
localparam SCW = AW+IW;

wire [SCW-1:0] sc_out_dat;

stream_collector #(
  .NS (NCALC),  // number of sinks
  .DW (SCW)     // data width
) mandelbrot_sc (
  .clk      (clk        ),  // clock
  .clk_en   (clk_en     ),  // clock enable
  .rst      (rst        ),  // reset
  .in_vld   (sc_in_vld  ),  // input valid
  .in_rdy   (sc_in_rdy  ),  // input ack
  .in_dat   (calc_data  ),  // input data
  .out_vld  (out_vld    ),  // output valid
  .out_rdy  (out_rdy    ),  // output ack
  .out_dat  (sc_out_dat )   // output data
);

assign {out_dat, out_adr} = sc_out_dat;


//// stats ////
reg           init_r;
wire          init_posedge;
reg  [32-1:0] niters_r;
reg  [32-1:0] pixel_cnt;

assign init_posedge = init && ~init_r;

always @ (posedge clk) begin
  if (clk_en) begin
    init_r <= #1 init;
    timer <= #1 stats_done ? timer : timer + 'd1;
    if (init_posedge) begin
      pixel_cnt   <= #1 npixels;
      timer       <= #1 'd0;
      niters_r    <= #1 'd0;
      stats_done  <= #1 1'b0;
    end else if (out_vld && out_rdy) begin
      pixel_cnt   <= #1 pixel_cnt - 'd1;
      niters_r    <= #1 niters_r + out_dat;
    end else if (~|pixel_cnt) begin
      pixel_cnt   <= #1 npixels;
      niters      <= #1 niters_r;
      stats_done  <= #1 1'b1;
    end
  end
end


endmodule

