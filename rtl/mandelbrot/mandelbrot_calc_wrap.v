// mandelbrot_calc_wrap.v
// mandelbrot calculation pipeline wrapper with in / out stream regs
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


module mandelbrot_calc_wrap #(
  parameter MAXITERS  = 256,              // max number of iterations
  parameter IW        = $clog2(MAXITERS), // width of iteration vars
  parameter FPW       = 2*27,             // bitwidth of fixed-point numbers
  parameter AW        = 11                // address width
)(
  // system
  input  wire           clk,      // clock
  input  wire           clk_en,   // clock enable
  input  wire           rst,      // reset
  // input cooridnates
  input  wire           in_vld,   // input valid
  output reg            in_rdy,   // input ack
  input  wire [FPW-1:0] x_man,    // mandelbrot x coordinate
  input  wire [FPW-1:0] y_man,    // mandelbrot y cooridnate
  input  wire [ AW-1:0] adr_i,    // mandelbrot coordinate address input
  // output
  output reg            out_vld,  // output valid
  input  wire           out_rdy,  // output ack
  output wire [ IW-1:0] niter,    // number of iterations
  output reg  [ AW-1:0] adr_o     // mandelbrot cooridnate address output
);


//// in stream reg ////
localparam IDW = FPW+FPW+AW;

wire [ IDW-1:0] ir_in_dat;
wire            ir_out_vld;
wire            ir_out_rdy;
wire [ IDW-1:0] ir_out_dat;

assign ir_in_dat = {adr_i, y_man, x_man};

stream_reg #(
  .DW   (IDW) // data width
) in_reg (
  .clk      (clk        ),  // clock
  .clk_en   (clk_en     ),  // clock enable
  .rst      (rst        ),  // reset
  .in_vld   (in_vld     ),  // input valid
  .in_rdy   (in_rdy     ),  // input ack
  .in_dat   (ir_in_dat  ),  // input data
  .out_vld  (ir_out_vld ),  // output valid
  .out_rdy  (ir_out_rdy ),  // output ack
  .out_dat  (ir_out_dat )   // output data
);


//// mandelbrot_calc ////
wire [ FPW-1:0] calc_x;
wire [ FPW-1:0] calc_y;
wire [  AW-1:0] calc_adr;
wire            or_in_rdy;
wire            or_in_vld;
wire [  IW-1:0] or_in_niter;
wire [  AW-1:0] or_in_adr;

assign {calc_adr, calc_y, calc_x} = ir_out_dat;

mandelbrot_calc #(
  .MAXITERS (MAXITERS), // max number of iterations
  .IW       (IW),       // width of iteration vars
  .FPW      (FPW),      // bitwidth of fixed-point numbers
  .AW       (AW)        // address width
) mandelbrot_calc (
  .clk      (clk        ),  // clock
  .clk_en   (clk_en     ),  // clock enable
  .rst      (rst        ),  // reset
  .in_vld   (ir_out_vld ),  // input valid
  .in_rdy   (ir_out_rdy ),  // input ack
  .x_man    (calc_x     ),  // mandelbrot x coordinate
  .y_man    (calc_y     ),  // mandelbrot y cooridnate
  .adr_i    (calc_adr   ),  // mandelbrot coordinate address input
  .out_rdy  (or_in_rdy  ),  // output ack
  .out_vld  (or_in_vld  ),  // output valid
  .niter    (or_in_niter),  // number of iterations
  .adr_o    (or_in_adr  )   // mandelbrot coordinate address output
);


//// out stream reg ////
localparam ODW = IW+AW;

wire [ODW-1:0] or_in_dat;
wire [ODW-1:0] out_dat;

assign or_in_dat = {or_in_niter, or_in_adr};

stream_reg #(
  .DW   (ODW) // data width
) out_reg (
  .clk      (clk        ),  // clock
  .clk_en   (clk_en     ),  // clock enable
  .rst      (rst        ),  // reset
  .in_vld   (or_in_vld  ),  // input valid
  .in_rdy   (or_in_rdy  ),  // input ack
  .in_dat   (or_in_dat  ),  // input data
  .out_vld  (out_vld    ),  // output valid
  .out_rdy  (out_rdy    ),  // output ack
  .out_dat  (out_dat    )   // output data
);

assign {niter, adr_o} = out_dat;


endmodule

