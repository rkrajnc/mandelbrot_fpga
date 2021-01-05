// mandelbrot_coors.v
// 2020, rok.krajnc@gmail.com


module mandelbrot_coords #(
  parameter CW    = 12,     // screen counter width
  parameter AW    = 12,     // address width
  parameter FPW   = 27      // fixed point size
)(
  // system
  input  wire                   clk,      // clock
  input  wire                   clk_en,   // clock enable
  input  wire                   rst,      // reset
  // control
  input  wire                   init,     // initialize coord engine
  output reg                    done,     // coord engine done
  // config
  input  wire        [  CW-1:0] hres,     // horizontal resolution
  input  wire        [  CW-1:0] vres,     // vertical resolution
  input  wire signed [ FPW-1:0] man_x0,   // leftmost Mandelbrot coordinate
  input  wire signed [ FPW-1:0] man_y0,   // uppermost Mandelbrot coordinate
  input  wire signed [ FPW-1:0] man_xs,   // Mandelbrot x step
  input  wire signed [ FPW-1:0] man_ys,   // Mandelbrot y step
  // output bus
  input  wire                   out_rdy,  // output ready to recieve (ack)
  output wire                   out_vld,  // output valid
  output wire        [ FPW-1:0] x,        // Mandelbrot x coordinate output
  output wire        [ FPW-1:0] y,        // Mandelbrot y coordinate output
  output wire        [  AW-1:0] adr       // Mandelbrot address output
);


//// fixed point params ////
localparam FP_S = 1;
localparam FP_I = 4;
localparam FP_F = FPW - FP_S - FP_I;


//// mandelbrot params ////

/*
// default
wire signed [54-1:0] man_x0 = 54'h3bd55555555556;
wire signed [54-1:0] man_y0 = 54'h3e000000000000;
wire signed [54-1:0] man_xs = 54'h0001b4e81b4e81;
wire signed [54-1:0] man_ys = 54'h0001b4e81b4e81;
*/

/*
// interesting point 1
wire signed [54-1:0] man_x0 = 54'h3fe8d62cccbd45;
wire signed [54-1:0] man_y0 = 54'h01f93ff3a4c1af;
wire signed [54-1:0] man_xs = 54'h000000000502c3;
wire signed [54-1:0] man_ys = 54'h000000000502c3;
*/


//// screen x/y counters /////
reg          [CW-1:0] cnt_x;
reg          [CW-1:0] cnt_y;
reg          [AW-1:0] cnt_adr;
reg                   cnt_en;
reg  signed [FPW-1:0] man_x;
reg  signed [FPW-1:0] man_y;
reg         [ CW-1:0] hres_r;
reg         [ CW-1:0] vres_r;


always @ (posedge clk, posedge rst) begin
  if (rst) begin
    done    <= #1 1'b1;
    cnt_x   <= #1 'd0;
    cnt_y   <= #1 'd0;
    cnt_adr <= #1 'd0;
    cnt_en  <= #1 1'b0;
    man_x   <= #1 'd0;
    man_y   <= #1 'd0;
    hres_r  <= #1 'd0;
    vres_r  <= #1 'd0;
  end else if (clk_en) begin
    if (init && !cnt_en) begin
      done    <= #1 1'b0;
      cnt_x   <= #1 'd0;
      cnt_y   <= #1 'd0;
      cnt_adr <= #1 'd0;
      cnt_en  <= #1 1'b1;
      man_x   <= #1 man_x0;
      man_y   <= #1 man_y0;
      hres_r  <= #1 hres - 'd1;
      vres_r  <= #1 vres - 'd1;
    end else if (out_rdy && cnt_en) begin
      if (cnt_x == hres_r) begin
        if (cnt_y == vres_r) begin
          cnt_en  <= #1 1'b0;
          done    <= #1 1'b1;
        end else begin
          cnt_y   <= #1 cnt_y +'d1;
          cnt_adr <= #1 cnt_adr +'d1;
          man_y   <= #1 man_y + man_ys;
        end
        cnt_x <= #1 'd0;
        man_x <= #1 man_x0;
      end else begin
        cnt_x   <= #1 cnt_x + 'd1;
        cnt_adr <= #1 cnt_adr + 'd1;
        man_x   <= #1 man_x + man_xs;
      end
    end
  end
end

assign x       = man_x;
assign y       = man_y;
assign adr     = cnt_adr;
assign out_vld = cnt_en;


endmodule

