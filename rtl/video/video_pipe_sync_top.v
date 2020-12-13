// video_pipe_sync_top.v
// synchronous video pipeline
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


module video_pipe_sync_top #(
  parameter CCW   = 8,    // color component width
  parameter TW    = 80,   // console text width in characters
  parameter TH    = 2,    // console text height in characters
  parameter CMAW  = 8,    // console memory address width
  parameter CMDW  = 8,    // console memory data width
  parameter IMAW  = 19,   // index memory address width
  parameter IMDW  = 8,    // index memory data width
  parameter CFR   = 200,  // console text foreground color red value
  parameter CFG   = 200,  // console text foreground color green value
  parameter CFB   = 200   // console text foreground color blue value
)(
  // system
  input  wire             clk,            // video clock
  input  wire             clk_en,         // video clock enable
  input  wire             rst,            // video clock reset
  // control
  input  wire             en,             // enable video pipe
  input  wire             border_en,      // enable drawing of border
  input  wire             console_en,     // enable textual console
  // video ram write interface
  input  wire             vram_clk_w,     // video memory write clock
  input  wire             vram_clk_en_w,  // video memory clock enable
  input  wire             vram_we,        // video memory write enable
  input  wire [ IMAW-1:0] vram_adr_w,     // video memory write address
  input  wire [ IMDW-1:0] vram_dat_w,     // video memory write data
  // console ram write interface
  input  wire             con_clk_w,      // console memory write clock
  input  wire             con_clk_en_w,   // console memory clock enable
  input  wire             con_we,         // console memory write enable
  input  wire [ CMAW-1:0] con_adr_w,      // console memory write address
  input  wire [ CMDW-1:0] con_dat_w,      // console memory write data
  // video output
  output wire             vid_active,     // video active (not blanked)
  output wire             vid_hsync,      // video horizontal sync
  output wire             vid_vsync,      // video vertical sync
  output wire [  CCW-1:0] vid_r,          // video red component
  output wire [  CCW-1:0] vid_g,          // video green component
  output wire [  CCW-1:0] vid_b           // video blue component
);


//// local parameters ////
localparam HCW        = 12;   // horizontal counter width
localparam VCW        = 12;   // vertical counter width
localparam F_CNT      = 60;   // number of frames in a second
localparam H_POL      = 1;    // horizontal sync polarity (0=positive, 1=negative)
localparam H_SYNC     = 96;   // sync pulse width in pixels
localparam H_BACK     = 45+3; // back porch width in pixels + added 3 pixels for active 'border'
localparam H_ACTIVE   = 640;  // active time width in pixels, actual width is 646px with border
localparam H_FRONT    = 13+3; // front porch width in pixels + added 3 pixels for active 'border'
localparam H_WHOLE    = 800;  // whole line width in pixels
localparam V_POL      = 1;    // vertical sync polarity ((0=positive, 1=negative)
localparam V_SYNC     = 2;    // sync pulse width in lines
localparam V_BACK     = 31+2; // back porch width in lines + added 2 lines for active 'border'
localparam V_ACTIVE   = 480;  // active time width in lines, acutal width is 484px with border
localparam V_FRONT    = 8+2;  // front porch width in lines + added 2 lines for active 'border'
localparam V_WHOLE    = 525;  // whole frame width in lines


//// video sync generator ////
wire [ HCW-1:0] h_match = 'd0;
wire [ VCW-1:0] v_match = 'd0;
wire [ HCW-1:0] h_cnt;
wire [ VCW-1:0] v_cnt;
wire            active;
wire            blank;
wire            a_start;
wire            a_end;
wire            hsync;
wire            vsync;

video_sync_gen #(
  .HCW        (HCW      ),  // horizontal counter width
  .VCW        (VCW      ),  // vertical counter width
  .F_CNT      (F_CNT    ),  // number of frames in a second
  .H_POL      (H_POL    ),  // horizontal sync polarity (0=positive, 1=negative)
  .H_SYNC     (H_SYNC   ),  // sync pulse width in pixels
  .H_BACK     (H_BACK   ),  // back porch width in pixels + added 3 pixels for active 'border'
  .H_ACTIVE   (H_ACTIVE ),  // active time width in pixels, actual width is 646px with border
  .H_FRONT    (H_FRONT  ),  // front porch width in pixels + added 3 pixels for active 'border'
  .H_WHOLE    (H_WHOLE  ),  // whole line width in pixels
  .V_POL      (V_POL    ),  // vertical sync polarity ((0=positive, 1=negative)
  .V_SYNC     (V_SYNC   ),  // sync pulse width in lines
  .V_BACK     (V_BACK   ),  // back porch width in lines + added 2 lines for active 'border'
  .V_ACTIVE   (V_ACTIVE ),  // active time width in lines, acutal width is 484px with border
  .V_FRONT    (V_FRONT  ),  // front porch width in lines + added 2 lines for active 'border'
  .V_WHOLE    (V_WHOLE  )   // whole frame width in lines
) video_sync_gen (
  .clk        (clk    ),  // clock
  .clk_en     (clk_en ),  // clock enable
  .rst        (rst    ),  // reset
  .en         (en     ),  // enable counters
  .h_match    (h_match),  // horizontal counter match compare value
  .v_match    (v_match),  // vertical counter match compare value
  .h_cnt      (h_cnt  ),  // horizontal counter
  .v_cnt      (v_cnt  ),  // vertical counter
  .cnt_match  (       ),  // position match
  .active     (active ),  // active output (otherwise border)
  .blank      (blank  ),  // blank output (otherwise active)
  .a_start    (a_start),  // active start (x==0 && y==0)
  .a_end      (a_end  ),  // active end ((x==H_ACTIVE-1 && y==V_ACTIVE-1)
  .f_cnt      (       ),  // frame counter (resets for every second)
  .h_sync     (hsync  ),  // horizontal sync signal
  .v_sync     (vsync  )   // vertical sync signal
);


//// video sync signals delay ////
localparam VD = 6; // amount of video pipe stages
reg  [     HCW-1:0] h_cnt_d   [0:VD-1];
reg  [     VCW-1:0] v_cnt_d   [0:VD-1];
reg                 active_d  [0:VD-1];
reg                 blank_d   [0:VD-1];
reg                 a_start_d [0:VD-1];
reg                 a_end_d   [0:VD-1];
reg                 hsync_d   [0:VD-1];
reg                 vsync_d   [0:VD-1];

always @ (*) begin
  h_cnt_d[0]    = h_cnt;
  v_cnt_d[0]    = v_cnt;
  active_d[0]   = active;
  blank_d[0]    = blank;
  a_start_d[0]  = a_start;
  a_end_d[0]    = a_end;
  hsync_d[0]    = hsync;
  vsync_d[0]    = vsync;
end

genvar i;
generate for (i=1; i<VD; i=i+1) begin : SYNC_PIPE_BLK
  always @ (posedge clk) begin
    if (clk_en) begin
      h_cnt_d[i]    <= #1 h_cnt_d[i-1];
      v_cnt_d[i]    <= #1 v_cnt_d[i-1];
      active_d[i]   <= #1 active_d[i-1];
      blank_d[i]    <= #1 blank_d[i-1];
      a_start_d[i]  <= #1 a_start_d[i-1];
      a_end_d[i]    <= #1 a_end_d[i-1];
      hsync_d[i]    <= #1 hsync_d[i-1];
      vsync_d[i]    <= #1 vsync_d[i-1];
    end
  end
end endgenerate


//// video text console ////
// input sync signals start from clk 0
// video text console has a latency of 4 clks
wire con_active;
wire con_pixel;

video_text_console #(
  .TW   (TW   ),  // console text width in characters
  .TH   (TH   ),  // console text height in characters
  .MAW  (CMAW ),  // console memory address width
  .MDW  (CMDW ),  // console memory data width
  .HCW  (HCW  ),  // horizontal counter width
  .VCW  (VCW  )   // vertical counter width
) video_text_console (
  .clk          (clk          ),  // video clock
  .clk_en       (clk_en       ),  // video clock enable
  .rst          (rst          ),  // video clock reset
  .en           (console_en   ),  // enable console
  .con_clk_w    (con_clk_w    ),  // console memory write clock
  .con_clk_en_w (con_clk_en_w ),  // console memory clock enable
  .con_we       (con_we       ),  // console memory write enable
  .con_adr_w    (con_adr_w    ),  // console memory write address
  .con_dat_w    (con_dat_w    ),  // console memory write data
  .a_end        (a_end_d[0]   ),  // video sync active end
  .h_cnt        (h_cnt_d[0]   ),  // horizontal counter
  .v_cnt        (v_cnt_d[0]   ),  // vertical counter
  .con_active   (con_active   ),  // video sync counters are in console area
  .con_pixel    (con_pixel    )   // current console pixel is foreground (font) when 1, background when 0
);


//// video ram read ////
// input sync signals start from clk 0, latency is 1
wire            vram_rd;    // video ram read enable
reg  [IMAW-1:0] vram_adr_r; // video ram read address
wire [IMDW-1:0] vram_dat_r; // video ram read data

assign vram_rd = active_d[0];

always @ (posedge clk, posedge rst) begin
  if (rst) begin
    vram_adr_r <= #1 {IMAW{1'b0}};
  end else if (clk_en) begin
    if (a_end_d[0] || !en)
      vram_adr_r <= #1 {IMAW{1'b0}};
    else if (active_d[0] && en)
     vram_adr_r <= #1 vram_adr_r + { {(IMAW-1){1'b0}}, 1'b1 };
  end
end


//// video index ram ////
// input sync signals start from clk 1, latency is 2
localparam IRAM_MI = "";//"../../rtl/memory/vid_ram.hex";
localparam IMD = H_ACTIVE*V_ACTIVE;  // memory depth

ram_generic_tp #(
  .MI               (IRAM_MI),  // memory initialization file
  .READ_REGISTERED  (1),        // when true, read port has an additional register
  .DW               (IMDW),     // data width
  .MD               (IMD),      // memory depth
  .AW               (IMAW)      // address width
) video_index_ram (
  .clk_w    (vram_clk_w   ),  // write clock
  .clk_en_w (vram_clk_en_w),  // write clock enable
  .we       (vram_we      ),  // write enable
  .adr_w    (vram_adr_w   ),  // write address
  .dat_w    (vram_dat_w   ),  // write data
  .clk_r    (clk          ),  // read clock
  .clk_en_r (clk_en       ),  // read clock enable
  .rd       (vram_rd      ),  // read enable
  .adr_r    (vram_adr_r   ),  // read address
  .dat_r    (vram_dat_r   )   // read data
);


//// indexed color lookup ////
// input sync signals start from clk 3, latency is 1
localparam CLUT_MI = "../../roms/mandelbrot_clut_8.hex"; // CLUT memory initialization file
localparam CLUT_DW = 3*CCW;           // CLUT data width
localparam CLUT_MD = 1<<IMDW;         // CLUT memory depth
localparam CLUT_AW = $clog2(CLUT_MD); // CLUT address width

wire [    IMDW-1:0] clut_adr;
wire [ CLUT_DW-1:0] clut_dat_r;
wire [     CCW-1:0] clut_r;
wire [     CCW-1:0] clut_g;
wire [     CCW-1:0] clut_b;

assign clut_adr = vram_dat_r;

rom_generic_sp #(
  .MI (CLUT_MI),  // memory initialization file
  .DW (CLUT_DW),  // data width
  .MD (CLUT_MD),  // memory depth
  .AW (CLUT_AW)   // address width
) video_clut_rom (
  .clk    (clk        ), // clock
  .clk_en (clk_en     ), // clock enable
  .rd     (en         ), // read enable
  .adr    (clut_adr   ), // read address
  .dat_r  (clut_dat_r )  // read data
);


//// border ////
wire  border_line_top;
wire  border_line_middle;
wire  border_line_bottom;
wire  border_line_left;
wire  border_line_center;
wire  border_line_right;
reg   border_lines;

assign border_line_top     = v_cnt_d[3] == 'd0;
assign border_line_middle  = v_cnt_d[3] == V_ACTIVE/2;
assign border_line_bottom  = v_cnt_d[3] == V_ACTIVE-1;
assign border_line_left    = h_cnt_d[3] == 'd0;
assign border_line_center  = h_cnt_d[3] == H_ACTIVE/2;
assign border_line_right   = h_cnt_d[3] == H_ACTIVE-1;

always @ (posedge clk) begin
  if (clk_en) begin
    border_lines <= #1 (border_line_top || border_line_middle || border_line_bottom || border_line_left || border_line_center || border_line_right);
  end
end


//// mixer ////
reg  [ CCW-1:0] vid_mixer_r;
reg  [ CCW-1:0] vid_mixer_g;
reg  [ CCW-1:0] vid_mixer_b;

always @ (posedge clk) begin
  if (clk_en) begin
    if (border_en && border_lines) begin
      // border lines take priority over everything
      vid_mixer_r <= #1 {CCW{1'b1}};
      vid_mixer_g <= #1 {CCW{1'b1}};
      vid_mixer_b <= #1 {CCW{1'b1}};
    end else if (console_en && con_active) begin
      // we are in console area, display foreground unchanged, background is darkened video
      vid_mixer_r <= #1 con_pixel ? CFR[CCW-1:0] : {2'b0, clut_dat_r[3*CCW-1:2*CCW+2]}; // 23:17
      vid_mixer_g <= #1 con_pixel ? CFG[CCW-1:0] : {2'b0, clut_dat_r[2*CCW-1:1*CCW+2]}; // 15:9
      vid_mixer_b <= #1 con_pixel ? CFB[CCW-1:0] : {2'b0, clut_dat_r[1*CCW-1:0*CCW+2]}; // 7:1
    end else begin
      // normal video
      vid_mixer_r <= #1 clut_dat_r[3*CCW-1:2*CCW];
      vid_mixer_g <= #1 clut_dat_r[2*CCW-1:1*CCW];
      vid_mixer_b <= #1 clut_dat_r[1*CCW-1:0*CCW];
    end
  end
end


//// output ////
assign vid_active = active_d[5];
assign vid_hsync  = hsync_d[5];
assign vid_vsync  = vsync_d[5];
assign vid_r      = vid_mixer_r;
assign vid_g      = vid_mixer_g;
assign vid_b      = vid_mixer_b;


endmodule

