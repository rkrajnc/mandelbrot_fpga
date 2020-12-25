// mandelbrot_calc_tb.sv
// testbench for the mandelbrot_calc module
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


`timescale 1ns/10ps
`default_nettype none


module mandelbrot_calc_tb();


//// local parameters ////
localparam CLK_HPER = 10; // clock half-period

localparam FPW  = 1*27; // fixed-point width
localparam FP_S = 1;
localparam FP_I = 4;
localparam FP_F = FPW - FP_S - FP_I;
localparam IW   = 8;
localparam MI   = 256;
localparam AW   = 11;


//// clock ////
reg clk;
reg clk_en = 1'b1;

initial begin
  clk = 0;
  forever #CLK_HPER clk = !clk;
end


//// reset ////
reg rst;

initial begin
  rst = 1;
  repeat (10) @ (posedge clk); #1;
  rst = 0;
end


//// testbench ////
reg             in_vld = 0;
wire            in_rdy;
reg  [ FPW-1:0] x_man;
reg  [ FPW-1:0] y_man;
reg  [  AW-1:0] adr_i;
wire            out_vld;
wire            out_rdy;
wire [  IW-1:0] niter;
wire [  AW-1:0] adr_o;

initial begin
  x_man = {FPW{1'bx}};
  y_man = {FPW{1'bx}};
  in_vld = 1'b0;
  $display("TB : starting");

  // wait for reset
  $display("TB : waiting for reset ...");
  wait(!rst);
  repeat(10) @ (posedge clk); #1;

  x_man = {1'h0, 4'h1, {FP_F{1'b0}}};
  y_man = {1'h1, 4'hf, 1'b1, {(FP_F-1){1'b1}}};
  in_vld <= #1 1'b1;
  @ (posedge clk); #1;
  x_man = {FPW{1'bx}};
  y_man = {FPW{1'bx}};
  in_vld <= #1 1'b0;

  repeat(200) @ (posedge clk); #1;

  // done
  repeat(10) @ (posedge clk); #1;
  $display("TB : done");
  $finish(0);
end


//// DUT ////
mandelbrot_calc #(
  .MAXITERS (MI ),
  .IW       (IW ),
  .FPW      (FPW),
  .AW       (AW )
) DUT (
  .clk      (clk    ),  // clock
  .clk_en   (clk_en ),  // clock enable
  .rst      (rst    ),  // reset
  .in_vld   (in_vld ),  // input valid
  .in_rdy   (in_rdy ),  // input ack
  .x_man    (x_man  ),  // mandelbrot x coordinate
  .y_man    (y_man  ),  // mandelbrot y cooridnate
  .adr_i    (adr_i  ),  // mandelbrot coordinate address input
  .out_vld  (out_vld),  // output valid
  .out_rdy  (out_rdy),  // output ready
  .niter    (niter  ),  // number of iterations
  .adr_o    (adr_o  )   // mandelbrot cooridnate address output
);


//// dump variables for icarus ////
`ifdef SIM_ICARUS
  `ifdef SIM_WAVES
    initial begin
      $dumpfile(`WAV_FILE);
      $dumpvars(0, mandelbrot_calc_tb);
    end
  `endif
`endif


endmodule

