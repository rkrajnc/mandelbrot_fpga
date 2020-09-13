// video_sync_gen.v
// generates video sync signals and counters
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


module video_sync_gen #(
  parameter HCW         = 12,       // horizontal counter width
  parameter VCW         = 12,       // vertical counter width
  parameter F_CNT       = 60,       // number of frames in a second
  parameter H_POL       = 1,        // horizontal sync polarity (0=positive, 1=negative)
  parameter H_SYNC      = 96,       // sync pulse width in pixels
  parameter H_BACK      = 45+3,     // back porch width in pixels + added 3 pixels for active 'border'
  parameter H_ACTIVE    = 640,      // active time width in pixels, actual width is 646px with border
  parameter H_FRONT     = 13+3,     // front porch width in pixels + added 3 pixels for active 'border'
  parameter H_WHOLE     = 800,      // whole line width in pixels
  parameter V_POL       = 1,        // vertical sync polarity ((0=positive, 1=negative)
  parameter V_SYNC      = 2,        // sync pulse width in lines
  parameter V_BACK      = 31+2,     // back porch width in lines + added 2 lines for active 'border'
  parameter V_ACTIVE    = 480,      // active time width in lines, acutal width is 484px with border
  parameter V_FRONT     = 8+2,      // front porch width in lines + added 2 lines for active 'border'
  parameter V_WHOLE     = 525       // whole frame width in lines
)(
  // system
  input  wire           clk,        // clock
  input  wire           clk_en,     // clock enable
  input  wire           rst,        // reset
  // config inputs
  input  wire           en,         // enable counters
  input  wire [HCW-1:0] h_match,    // horizontal counter match compare value
  input  wire [VCW-1:0] v_match,    // vertical counter match compare value
  // pixel counters
  output reg  [HCW-1:0] h_cnt,      // horizontal counter
  output reg  [VCW-1:0] v_cnt,      // vertical counter
  // status
  output reg            cnt_match,  // position match
  output reg            active,     // active output (otherwise border)
  output reg            blank,      // blank output (otherwise active)
  output reg            a_start,    // active start (x==0 && y==0)
  output reg            a_end,      // active end ((x==H_ACTIVE-1 && y==V_ACTIVE-1)
  output reg  [  7-1:0] f_cnt,      // frame counter (resets for every second)
  // VGA outputs
  output reg            h_sync,     // horizontal sync signal
  output reg            v_sync      // vertical sync signal
);


//// horizontal counter ////
reg [HCW-1:0] h_cnt_r;

always @ (posedge clk, posedge rst) begin
  if (rst)
    h_cnt_r <= #1 'd0;
  else if (clk_en) begin
    if (!en)
      h_cnt_r <= #1 'd0;
    else if (h_cnt_r == (H_WHOLE-1))
      h_cnt_r <= #1 'd0;
    else
      h_cnt_r <= #1 h_cnt_r + {{(HCW-1){1'b0}}, 1'b1};
  end
end

always @ (posedge clk) begin
  if (clk_en) h_cnt <= #1 h_cnt_r;
end


//// vertical counter ////
reg [VCW-1:0] v_cnt_r;

always @ (posedge clk, posedge rst) begin
  if (rst)
    v_cnt_r <= #1 'd0;
  else if (clk_en) begin
    if (!en)
      v_cnt_r <= #1 'd0;
    else if ((v_cnt_r == (V_WHOLE-1)) && (h_cnt_r == (H_WHOLE-1)))
      v_cnt_r <= #1 'd0;
    else if (h_cnt_r == (H_WHOLE-1))
      v_cnt_r <= #1 v_cnt_r + {{(VCW-1){1'b0}}, 1'b1};
  end
end

always @ (posedge clk) begin
  if (clk_en) v_cnt <= #1 v_cnt_r;
end


//// count match register ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    cnt_match <= #1 1'b0;
  else if (clk_en)
    cnt_match <= #1 (h_cnt_r == h_match) && (v_cnt_r == v_match);
end


//// active & blank registers ////
always @ (posedge clk, posedge rst) begin
  if (rst) begin
    active <= #1 1'b0;
    blank  <= #1 1'b0;
  end else if (clk_en) begin
    active <= #1   (h_cnt_r < H_ACTIVE) && (v_cnt_r < V_ACTIVE) && en;
    blank  <= #1 !((h_cnt_r < H_ACTIVE) && (v_cnt_r < V_ACTIVE)) || !en;
  end
end


//// active start/end ////
always @ (posedge clk, posedge rst) begin
  if (rst) begin
    a_start = #1 1'b0;
    a_end   = #1 1'b0;
  end else if (clk_en) begin
    a_start = #1 (h_cnt_r == 'd0) && (v_cnt_r == 'd0) && en;
    a_end   = #1 (h_cnt_r == (H_ACTIVE-1)) && (v_cnt_r == (V_ACTIVE-1));
  end
end


//// frame counter ////
always @ (posedge clk, posedge rst) begin
  if (rst) begin
    f_cnt <= #1 {7{1'b0}};
  end else if (clk_en) begin
    if (!en)
      f_cnt <= #1 {7{1'b0}};
    else if (f_cnt == (F_CNT-1))
      f_cnt <= #1 {7{1'b0}};
    else if ((v_cnt_r == 'd0) && (h_cnt_r == 'd0) && en)
      f_cnt <= #1 f_cnt + 'd1;
  end
end


//// sync signals ////
always @ (posedge clk, posedge rst) begin
  if (rst) begin
    h_sync <= #1 1'b0;
    v_sync <= #1 1'b0;
  end else if (clk_en) begin
    h_sync <= #1 (en && (h_cnt_r >= (H_ACTIVE+H_FRONT)) && (h_cnt_r < (H_ACTIVE+H_FRONT+H_SYNC))) ^ H_POL;
    v_sync <= #1 (en && (v_cnt_r >= (V_ACTIVE+V_FRONT)) && (v_cnt_r < (V_ACTIVE+V_FRONT+V_SYNC))) ^ V_POL;
  end
end


endmodule

