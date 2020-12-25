// mandelbrot_calc.v
// mandelbrot calculation pipeline
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


module mandelbrot_calc #(
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


//// local parameters ////
localparam FP_S = 1;                  // fixed-point sign bit
localparam FP_I = 4;                  // fixed-point integer bits
localparam FP_F = FPW - FP_S - FP_I;  // fixed-point fractional bits 


//// flow control ////
reg busy;
wire check;

always @ (posedge clk, posedge rst) begin
  if (rst) begin
    in_rdy  <= #1 1'b1;
    out_vld <= #1 1'b0;
    busy    <= #1 1'b0;
  end else if (clk_en) begin
    if (in_vld && in_rdy) begin
      in_rdy  <= #1 1'b0;
      busy    <= #1 1'b1;
    end else if (check && !out_vld && busy) begin
      out_vld <= #1 1'b1;
      busy    <= #1 1'b0;
    end else if (check && out_vld && out_rdy) begin
      in_rdy  <= #1 1'b1;
      out_vld <= #1 1'b0;
    end
  end
end


//// mandelbrot calculation ////
reg  signed [  FPW-1:0] x_man_r, y_man_r;
wire signed [  FPW-1:0] x_comb, y_comb;
reg  signed [  FPW-1:0] x, y;
wire signed [2*FPW-1:0] xx_mul_comb, yy_mul_comb, xy_mul_comb;
wire signed [  FPW-1:0] xx_comb, yy_comb, xy2_comb;
reg  signed [  FPW-1:0] xx, yy, xy2;
wire signed [  FPW-1:0] limit;
reg         [ IW+1-1:0] niters;
wire                    niters_check;
wire                    limit_check;
//wire                    check;


assign xx_mul_comb  = x*x;
assign yy_mul_comb  = y*y;
assign xy_mul_comb  = x*y;
assign xx_comb      = xx_mul_comb[2*FPW-1-FP_S-FP_I:FPW-FP_S-FP_I];
assign yy_comb      = yy_mul_comb[2*FPW-1-FP_S-FP_I:FPW-FP_S-FP_I];
assign xy2_comb     = {xy_mul_comb[2*FPW-2-FP_S-FP_I:FPW-FP_S-FP_I], 1'b0};
assign limit        = {1'h0, 4'h4, {FP_F{1'h0}}}; // 4.0
assign niters_check = niters[IW+1-1:1] >= (MAXITERS-1);
assign limit_check  = (xx + yy) > limit;
assign check        = niters_check || limit_check;
assign x_comb       = xx - yy + x_man_r;
assign y_comb       = xy2 + y_man_r;

always @ (posedge clk) begin
  if (clk_en) begin
    if (in_vld && in_rdy) begin
      adr_o   <= #1 adr_i;
      x_man_r <= #1 x_man;
      y_man_r <= #1 y_man;
      x       <= #1 'd0;
      y       <= #1 'd0;
      xx      <= #1 'd0;
      yy      <= #1 'd0;
      xy2     <= #1 'd0;
      niters  <= #1 'd0;
    end else if(!check) begin
      x       <= #1 x_comb;
      y       <= #1 y_comb;
      xx      <= #1 xx_comb;
      yy      <= #1 yy_comb;
      xy2     <= #1 xy2_comb;
      niters  <= #1 niters + 'd1;
    end
  end
end

assign niter = niters[IW+1-1:1];


endmodule


/*
133   // calculate the Mandelbrot set
134   // iterate over all image rows
135   #pragma omp parallel for ordered schedule(dynamic)
136   for (uint32_t img_y=0; img_y<img_h; img_y++) {
137     // convert y image coordinate to Mandelbrot coordinate
138     double man_y = (double)(img_y)/(double)img_h*(man_y1-man_y0) + man_y0;
139     // iterate over all image columns
140     for (uint32_t img_x=0; img_x<img_w; img_x++) {
141       // convert x image coordinate to Mandelbrot coordinate
142       double man_x = (double)(img_x)/(double)img_w*(man_x1-man_x0) + man_x0;
143       // initialize Zn to 0 + i0
144       double zn_x = 0.0;
145       double zn_y = 0.0;
146       // initialize niterations to 0
147       uint32_t niterations = 0;
148       // initialize temporary variables
149       double x2 = 0.0;
150       double y2 = 0.0;
151       while (x2 + y2 <= 4.0 && niterations < niter-1) {
152         zn_y = 2*zn_x*zn_y + man_y;
153         zn_x = x2 - y2 + man_x;
154         x2   = zn_x*zn_x;
155         y2   = zn_y*zn_y;
156         niterations++;
157       }
158       // save number of iterations to iterations array
159       iterations[img_y*img_w+img_x] = niterations;
160     }
161   }
*/
/*
1. xy2 = 2*x*y | xx = x*x | yy = y*y
2. xx + yy <= 4 ? | x = xx - yy + man_x | y = xy2 + man_y

       0       1       2       3
    ___|---|___|---|___|---|___|---|___|---|___|---|___|---|___|---|___|---|___|---|___|---|___|---|___|---|___|---|___|---|__

x      0_0     1_0     0_1
y      0_0     1_0     0_1
xx     0       0_0     1_0
yy     0       0_0     1_0
xy     0       0_0     1_0
cmp    0       0       0_0



2. 2*zn_x*zn_y | zn_x*zn_x | zn_y*zn_y
3. zn_y = 2*zn_x*zn_y + man_y | zn_x = x*x - y*y + man_x


always @ (posedge clk) begin
  if (init) begin
    zn_x    <= #1 'd0;
    zn_y    <= #1 'd0;
    niters  <= #1 'd0;
    x2      <= #1 'd0;
    y2      <= #1 'd0;
  end else if (clk_en) begin
    
  end
end
*/

