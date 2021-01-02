// mandelbrot_top.v
// top-level mandelbrot module
// 2020, Rok Krajnc <rok.krajnc@gmail,com>


module mandelbrot_top #(
  parameter FPW       = 2*27,             // bitwidth of fixed-point numbers
  parameter MAXITERS  = 256,              // max number of iterations
  parameter IW        = $clog2(MAXITERS), // width of iteration output value
  parameter AW        = 12,               // address width
  parameter CW        = 12,               // screen coordinates counters width
  parameter FD        = 8                 // fifo depth
)(
  // system
  input  wire                   clk,      // clock
  input  wire                   clk_en,   // clock enable
  input  wire                   rst,      // reset
  // control
  input  wire                   init,     // enable mandelbrot calculation (posedge sensitive!)
  output wire                   done,     // mandelbrot engine done
  // config
  input  wire signed [ FPW-1:0] man_x0,   // leftmost Mandelbrot coordinate
  input  wire signed [ FPW-1:0] man_y0,   // uppermost Mandelbrot coordinate
  input  wire signed [ FPW-1:0] man_xs,   // Mandelbrot x step
  input  wire signed [ FPW-1:0] man_ys,   // Mandelbrot y step
  // mandelbrot output
  input  wire                   out_rdy,  // output ready to receive (ack)
  output wire                   out_vld,  // output valid
  output wire        [  IW-1:0] out_dat,  // number of iterations
  output wire        [  AW-1:0] out_adr   // mandelbrot coordinate address output
);


//// mandelbrot coordinates ////
localparam [CW-1:0] HRES = 'd799; // TODO!
localparam [CW-1:0] VRES = 'd599;

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
  .hres     (HRES     ),  // horizontal resolution
  .vres     (VRES     ),  // vertical resolution
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


//// mandelbrot calculate ////
wire            calc_vld;
wire            calc_rdy;
wire [ FPW-1:0] calc_x;
wire [ FPW-1:0] calc_y;
wire [  AW-1:0] calc_adr;

assign calc_vld   = !fifo_empty;
assign fifo_rd_en = calc_rdy && !fifo_empty;
assign {calc_adr, calc_y, calc_x} = fifo_out;

mandelbrot_calc #(
  .MAXITERS (MAXITERS), // max number of iterations
  .IW       (IW),       // width of iteration vars
  .FPW      (FPW),      // bitwidth of fixed-point numbers
  .AW       (AW)        // address width
) mandelbrot_calc (
  .clk      (clk      ),  // clock
  .clk_en   (clk_en   ),  // clock enable
  .rst      (rst      ),  // reset
  .in_vld   (calc_vld ),  // input valid
  .in_rdy   (calc_rdy ),  // input ack
  .x_man    (calc_x   ),  // mandelbrot x coordinate
  .y_man    (calc_y   ),  // mandelbrot y cooridnate
  .adr_i    (calc_adr ),  // mandelbrot coordinate address input
  .out_rdy  (out_rdy  ),  // output ack
  .out_vld  (out_vld  ),  // output valid
  .niter    (out_dat  ),  // number of iterations
  .adr_o    (out_adr  )   // mandelbrot coordinate address output
);


endmodule

