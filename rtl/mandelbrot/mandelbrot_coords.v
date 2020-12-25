// mandelbrot_coors.v
// 2020, rok.krajnc@gmail.com


module mandelbrot_coords #(
  parameter VMINX = 0,      // screen min x coordinate
  parameter VMAXX = 640-1,  // screen max x coordinate
  parameter VMINY = 0,      // screen min y coordinate
  parameter VMAXY = 480-1,  // screen max y coordinate
  parameter CW    = 12,     // screen counter width
  parameter AW    = 12,     // address width
  parameter FPW   = 27      // fixed point size
)(
  input  wire clk,
  input  wire clk_en,
  input  wire rst,
  input  wire init,
  input  wire out_rdy,
  output wire out_vld,
  output wire [FPW-1:0] x,
  output wire [FPW-1:0] y,
  output wire [ AW-1:0] adr
);


//// fixed point params ////
localparam FP_S = 1;
localparam FP_I = 4;
localparam FP_F = FPW - FP_S - FP_I;


//// mandelbrot params ////
localparam real FP_VAL        = 2**FP_F; // TODO OMG Quartus, why do you need to calculate this separately??
localparam real MAN_DEF_X0_F  = -2.5;
localparam real MAN_DEF_X1_F  = 1.0;
localparam real MAN_DEF_Y0_F  = -1.0;
localparam real MAN_DEF_Y1_F  = 1.0;
localparam real MAN_DEF_Z_F   = 1.0;
localparam real MAN_DEF_XS_F  = 1.0*(MAN_DEF_X1_F - MAN_DEF_X0_F)/(VMAXX+1.0);
localparam real MAN_DEF_YS_F  = 1.0*(MAN_DEF_Y1_F - MAN_DEF_Y0_F)/(VMAXY+1.0);
localparam      MAN_DEF_X0    = MAN_DEF_X0_F * FP_VAL;
localparam      MAN_DEF_Y0    = MAN_DEF_Y0_F * FP_VAL;
localparam      MAN_DEF_XS    = MAN_DEF_XS_F * FP_VAL;
localparam      MAN_DEF_YS    = MAN_DEF_YS_F * FP_VAL;

// debug printout
initial begin
  $display("MAN_DEF_X0_F = %f", MAN_DEF_X0_F);
  $display("MAN_DEF_X1_F = %f", MAN_DEF_X1_F);
  $display("MAN_DEF_Y0_F = %f", MAN_DEF_Y0_F);
  $display("MAN_DEF_Y1_F = %f", MAN_DEF_Y1_F);
  $display("MAN_DEF_Z_F  = %f", MAN_DEF_Z_F);
  $display("MAN_DEF_XS_F = %f", MAN_DEF_XS_F);
  $display("MAN_DEF_YS_F = %f", MAN_DEF_YS_F);
  $display("MAN_DEF_X0   = %d", MAN_DEF_X0);
  $display("MAN_DEF_Y0   = %d", MAN_DEF_Y0);
  $display("MAN_DEF_XS   = %d", MAN_DEF_XS);
  $display("MAN_DEF_YS   = %d", MAN_DEF_YS);
end


//// screen x/y counters /////
reg  [CW-1:0] cnt_x;
reg  [CW-1:0] cnt_y;
reg  [AW-1:0] cnt_adr;
reg           cnt_en;

wire signed [FPW-1:0] inc_x;
wire signed [FPW-1:0] inc_y;
reg  signed [FPW-1:0] man_x;
reg  signed [FPW-1:0] man_y;

assign inc_x = MAN_DEF_XS;
assign inc_y = MAN_DEF_YS;

always @ (posedge clk, posedge rst) begin
  if (rst) begin
    cnt_x   <= #1 VMINX;
    cnt_y   <= #1 VMINY;
    cnt_adr <= #1 'd0;
    cnt_en  <= #1 1'b1;
    man_x   <= #1 MAN_DEF_X0;
    man_y   <= #1 MAN_DEF_Y0;
  end else if (clk_en) begin
    if (init) begin
      cnt_x   <= #1 VMINX;
      cnt_y   <= #1 VMINY;
      cnt_adr <= #1 'd0;
      cnt_en  <= #1 1'b1;
      man_x   <= #1 MAN_DEF_X0;
      man_y   <= #1 MAN_DEF_Y0;
    end else if (out_rdy && cnt_en) begin
      if (cnt_x == VMAXX) begin
        if (cnt_y == VMAXY) begin
          cnt_en  <= #1 1'b0;
        end else begin
          cnt_y   <= #1 cnt_y +'d1;
          cnt_adr <= #1 cnt_adr +'d1;
          man_y   <= #1 man_y + inc_y;
          $display("Mandelbrot: processing line %d", man_y);
        end
        cnt_x <= #1 VMINX;
        man_x <= #1 MAN_DEF_X0;
      end else begin
        cnt_x   <= #1 cnt_x + 'd1;
        cnt_adr <= #1 cnt_adr + 'd1;
        man_x   <= #1 man_x + inc_x;
      end
    end
  end
end

assign x       = man_x;
assign y       = man_y;
assign adr     = cnt_adr;
assign out_vld = cnt_en;


/*
//// multiplier ////
reg  signed [  FP_SIZE-1:0] mul_a;
reg  signed [  FP_SIZE-1:0] mul_b;
wire signed [2*FP_SIZE-1:0] mul;
reg  signed [2*FP_SIZE-1:0] mul_r;
wire signed [  FP_SIZE-1:0] mul_out;

assign mul = mul_a * mul_b;

always @ (posedge clk) mul_r <= #1 mul;

assign mul_out = mul_r[2*FP_SIZE-1-FP_S-FP_I:FP_SIZE-FP_S-FP_I];


//// fp coordinates ////
localparam  [FP_SIZE-1:0] F_MAX_Z = {1'b0, 4'b0010, {FP_F{1'b0}}}; // s4.XX, 2.0
localparam  [FP_SIZE-1:0] F_MIN_Z = {1'b0, 4'b0000, {(FP_F-2){1'b0}}, 2'b10}; // s4.XX, 0.0000000...
localparam  [FP_SIZE-1:0] F_IN_Z  = {1'b0, 4'b0000, 1'b1, {(FP_F-1){1'b0}}}; // s4.XX, 0.5
localparam  [FP_SIZE-1:0] F_OUT_Z = {1'b0, 4'b0010, {FP_F{1'b0}}}; // s4.XX, 2.0
localparam  [FP_SIZE-1:0] F_MIN_X = {1'b1, 4'b1111, {FP_F{1'b0}}}; // s4.XX, -1.0
localparam  [FP_SIZE-1:0] F_MAX_X = {1'b0, 4'b0001, {FP_F{1'b0}}}; // s4.XX,  1.0
localparam  [FP_SIZE-1:0] F_MIN_Y = {1'b1, 4'b1111, {FP_F{1'b0}}}; // s4.XX, -1.0
localparam  [FP_SIZE-1:0] F_MAX_Y = {1'b0, 4'b0001, {FP_F{1'b0}}}; // s4.XX,  1.0
localparam  [FP_SIZE-1:0] F_CTR_X = {1'b0, 4'b0000, {FP_F{1'b0}}}; // s4.XX,  0.0
localparam  [FP_SIZE-1:0] F_CTR_Y = {1'b0, 4'b0001, {FP_F{1'b0}}}; // s4.XX,  0.0

reg  signed [FP_SIZE-1:0] fp_zoom; // s4.XX
reg  signed [FP_SIZE-1:0] fp_px, fp_py; // s4.XX
reg  signed [FP_SIZE-1:0] fp_cx, fp_cy; // s4.XX
reg  signed [FP_SIZE-1:0] fp_min_x, fp_max_x, fp_min_y, fp_max_y; // s4.XX
reg                       done;

localparam  [      4-1:0] ST_INIT = 4'h0,
                          ST_L0   = 4'h1,
                          ST_L1   = 4'h2,
                          ST_L2   = 4'h3,
                          ST_L3   = 4'h4,
                          ST_L4   = 4'h5,
                          ST_L5   = 4'h6,
                          ST_P0   = 4'h7,
                          ST_P1   = 4'h8,
                          ST_P2   = 4'h9,
                          ST_P3   = 4'ha,
                          ST_P4   = 4'hb;

reg         [      4-1:0] state;

always @ (posedge clk, posedge rst) begin
  if (rst) begin
    fp_px   <= #1 'd0;
    fp_py   <= #1 'd0;
    fp_zoom <= #1 F_MAX_Z;
    cnt_en  <= #1 1'b0;
    done    <= #1 1'b0;
    state   <= #1 ST_INIT;
  end else begin
    cnt_en <= #1 1'b0;
    done   <= #1 1'b0;
    case (state)
      ST_INIT : begin
        if (init) state <= #1 ST_L0;
      end
      ST_L0 : begin
        // setup minx
        mul_a    <= #1 F_MIN_X;
        mul_b    <= #1 fp_zoom;
        state    <= #1 ST_L1;
      end
      ST_L1 : begin
        // setup maxx, mul minx
        mul_a    <= #1 F_MAX_X;
        mul_b    <= #1 fp_zoom;
        state    <= #1 ST_L2;
      end
      ST_L2 : begin
        // setup miny, mul maxx, read minx
        fp_min_x <= #1 fp_px + mul_out;
        mul_a    <= #1 F_MIN_Y;
        mul_b    <= #1 fp_zoom;
        state    <= #1 ST_L3;
      end
      ST_L3 : begin
        // setup maxy, mul miny, read maxx
        fp_max_x <= #1 fp_px + mul_out;
        mul_a    <= #1 F_MAX_Y;
        mul_b    <= #1 fp_zoom;
        state    <= #1 ST_L4;
      end
      ST_L4 : begin
        // mul maxy, read miny
        fp_min_y <= #1 fp_py + mul_out;
        state    <= #1 ST_L5;
      end
      ST_L5 : begin
        // read maxy
        fp_max_y <= #1 fp_py + mul_out;
        state    <= #1 ST_P0;
      end
      ST_P0 : begin
        // setup px
        mul_a    <= #1 {1'b0, 4'b0000, cnt_x, {(FP_F-S_CW){1'b0}}};
        mul_b    <= #1 fp_max_x - fp_min_x;
        state    <= #1 ST_P1;
      end
      ST_P1 : begin
        // setup py, mul px
        mul_a    <= #1 {1'b0, 4'b0000, cnt_y, {(FP_F-S_CW){1'b0}}};
        mul_b    <= #1 fp_max_y - fp_min_y;
        state    <= #1 ST_P2;
      end
      ST_P2 : begin
        // mul py, read px, increment counters
        cnt_en   <= #1 1'b1;
        fp_cx    <= #1 mul_out + fp_min_x;
        state    <= #1 ST_P3;
      end
      ST_P3 : begin
        // read py
        fp_cy    <= #1 mul_out + fp_min_y;
        if (rdy) begin
          done   <= #1 1'b1;
          state <= #1 ST_P0;
        end
      end
    endcase
  end
end


//// assign outputs ////
assign pr = fp_cx;
assign pi = fp_cy;
assign out_vld = done;
*/


endmodule

