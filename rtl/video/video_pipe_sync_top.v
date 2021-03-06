// video_pipe_sync_top.v
// synchronous video pipeline
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


module video_pipe_sync_top #(
  parameter CCW       = 8,    // color component width
  parameter HCW       = 12,   // horizontal counter width
  parameter VCW       = 12,   // vertical counter width
  parameter H_ACTIVE  = 800,  // horizontal resolution
  parameter V_ACTIVE  = 600,  // vertical resolution
  parameter TW        = 80,   // console text width in characters
  parameter TH        = 2,    // console text height in characters
  parameter CMAW      = 8,    // console memory address width
  parameter CMDW      = 8,    // console memory data width
  parameter IMAW      = 19,   // index memory address width
  parameter IMDW      = 8,    // index memory data width
  parameter CFR       = 200,  // console text foreground color red value
  parameter CFG       = 200,  // console text foreground color green value
  parameter CFB       = 200   // console text foreground color blue value
)(
  // system
  input  wire             clk,            // video clock
  input  wire             clk_en,         // video clock enable
  input  wire             rst,            // video clock reset
  // control
  input  wire             en,             // enable video pipe
  input  wire             border_en,      // enable drawing of border
  input  wire             console_en,     // enable textual console
  input  wire [    3-1:0] fader,          // video fader (0=no fade, 7=max fade)
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
localparam F_CNT      = 60;   // number of frames in a second


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
//wire            cfg_h_pol     = 'd1;    // horizontal sync polarity (0=positive, 1=negative)
//wire [ HCW-1:0] cfg_h_sync    = 'd96;   // sync pulse width in pixels
//wire [ HCW-1:0] cfg_h_active  = 'd640;  // active time width in pixels, actual width is 646px with border
//wire [ HCW-1:0] cfg_h_front   = 'd16;   // front porch width in pixels + added 3 pixels for active 'border'
//wire [ HCW-1:0] cfg_h_whole   = 'd800;  // whole line width in pixels
//wire            cfg_v_pol     = 'd1;    // vertical sync polarity ((0=positive, 1=negative)
//wire [ VCW-1:0] cfg_v_sync    = 'd2;    // sync pulse width in lines
//wire [ VCW-1:0] cfg_v_active  = 'd480;  // active time width in lines, acutal width is 484px with border
//wire [ VCW-1:0] cfg_v_front   = 'd10;   // front porch width in lines + added 2 lines for active 'border'
//wire [ VCW-1:0] cfg_v_whole   = 'd525;  // whole frame width in lines
wire            cfg_h_pol     = 'd0;      // horizontal sync polarity (0=positive, 1=negative)
wire [ HCW-1:0] cfg_h_sync    = 'd128;    // sync pulse width in pixels
wire [ HCW-1:0] cfg_h_active  = 'd800;    // active time width in pixels, actual width is 646px with border
wire [ HCW-1:0] cfg_h_front   = 'd40;     // front porch width in pixels + added 3 pixels for active 'border'
wire [ HCW-1:0] cfg_h_whole   = 'd1056;   // whole line width in pixels
wire            cfg_v_pol     = 'd0;      // vertical sync polarity ((0=positive, 1=negative)
wire [ VCW-1:0] cfg_v_sync    = 'd4;      // sync pulse width in lines
wire [ VCW-1:0] cfg_v_active  = 'd600;    // active time width in lines, acutal width is 484px with border
wire [ VCW-1:0] cfg_v_front   = 'd1;      // front porch width in lines + added 2 lines for active 'border'
wire [ VCW-1:0] cfg_v_whole   = 'd628;    // whole frame width in lines



video_sync_gen #(
  .HCW        (HCW      ),  // horizontal counter width
  .VCW        (VCW      ),  // vertical counter width
  .F_CNT      (F_CNT    )   // number of frames in a second
) video_sync_gen (
  .clk          (clk          ),  // clock
  .clk_en       (clk_en       ),  // clock enable
  .rst          (rst          ),  // reset
  .en           (en           ),  // enable counters
  .h_match      (h_match      ),  // horizontal counter match compare value
  .v_match      (v_match      ),  // vertical counter match compare value
  .cfg_h_pol    (cfg_h_pol    ),  // horizontal sync polarity (0=positive, 1=negative)
  .cfg_h_sync   (cfg_h_sync   ),  // sync pulse width in pixels
  .cfg_h_active (cfg_h_active ),  // active time width in pixels, actual width is 646px with border
  .cfg_h_front  (cfg_h_front  ),  // front porch width in pixels + added 3 pixels for active 'border'
  .cfg_h_whole  (cfg_h_whole  ),  // whole line width in pixels
  .cfg_v_pol    (cfg_v_pol    ),  // vertical sync polarity ((0=positive, 1=negative)
  .cfg_v_sync   (cfg_v_sync   ),  // sync pulse width in lines
  .cfg_v_active (cfg_v_active ),  // active time width in lines, acutal width is 484px with border
  .cfg_v_front  (cfg_v_front  ),  // front porch width in lines + added 2 lines for active 'border'
  .cfg_v_whole  (cfg_v_whole  ),  // whole frame width in lines
  .h_cnt        (h_cnt        ),  // horizontal counter
  .v_cnt        (v_cnt        ),  // vertical counter
  .cnt_match    (             ),  // position match
  .active       (active       ),  // active output (otherwise border)
  .blank        (blank        ),  // blank output (otherwise active)
  .a_start      (a_start      ),  // active start (x==0 && y==0)
  .a_end        (a_end        ),  // active end ((x==H_ACTIVE-1 && y==V_ACTIVE-1)
  .f_cnt        (             ),  // frame counter (resets for every second)
  .h_sync       (hsync        ),  // horizontal sync signal
  .v_sync       (vsync        )   // vertical sync signal
);


//// video sync signals delay ////
localparam VD = 7; // amount of video pipe stages
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
localparam IRAM_MI = "";//"../../roms/vid_ram.hex";
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


//// fader ////
reg  [ CCW-1:0] vid_fader_r;
reg  [ CCW-1:0] vid_fader_g;
reg  [ CCW-1:0] vid_fader_b;
reg  [   3-1:0] fader_r0;
reg  [   3-1:0] fader_r1;

always @ (posedge clk) begin
  if (clk_en) begin
    fader_r0 <= #1 fader;
    fader_r1 <= #1 fader_r0;
  end
end

always @ (posedge clk) begin
  if (clk_en) begin
    case(fader_r1)
      'h0 : begin
        vid_fader_r <= #1 vid_mixer_r;
        vid_fader_g <= #1 vid_mixer_g;
        vid_fader_b <= #1 vid_mixer_b;
      end
      'h1 : begin
        vid_fader_r <= #1 {1'h0, vid_mixer_r[CCW-1:1]};
        vid_fader_g <= #1 {1'h0, vid_mixer_g[CCW-1:1]};
        vid_fader_b <= #1 {1'h0, vid_mixer_b[CCW-1:1]};
      end
      'h2 : begin
        vid_fader_r <= #1 {2'h0, vid_mixer_r[CCW-1:2]};
        vid_fader_g <= #1 {2'h0, vid_mixer_g[CCW-1:2]};
        vid_fader_b <= #1 {2'h0, vid_mixer_b[CCW-1:2]};
      end
      'h3 : begin
        vid_fader_r <= #1 {3'h0, vid_mixer_r[CCW-1:3]};
        vid_fader_g <= #1 {3'h0, vid_mixer_g[CCW-1:3]};
        vid_fader_b <= #1 {3'h0, vid_mixer_b[CCW-1:3]};
      end
      'h4 : begin
        vid_fader_r <= #1 {4'h0, vid_mixer_r[CCW-1:4]};
        vid_fader_g <= #1 {4'h0, vid_mixer_g[CCW-1:4]};
        vid_fader_b <= #1 {4'h0, vid_mixer_b[CCW-1:4]};
      end
      'h5 : begin
        vid_fader_r <= #1 {5'h0, vid_mixer_r[CCW-1:5]};
        vid_fader_g <= #1 {5'h0, vid_mixer_g[CCW-1:5]};
        vid_fader_b <= #1 {5'h0, vid_mixer_b[CCW-1:5]};
      end
      'h6 : begin
        vid_fader_r <= #1 {6'h0, vid_mixer_r[CCW-1:6]};
        vid_fader_g <= #1 {6'h0, vid_mixer_g[CCW-1:6]};
        vid_fader_b <= #1 {6'h0, vid_mixer_b[CCW-1:6]};
      end
      'h7 : begin
        vid_fader_r <= #1 {7'h0, vid_mixer_r[CCW-1:7]};
        vid_fader_g <= #1 {7'h0, vid_mixer_g[CCW-1:7]};
        vid_fader_b <= #1 {7'h0, vid_mixer_b[CCW-1:7]};
      end
    endcase
  end
end


//// output ////
assign vid_active = active_d[6];
assign vid_hsync  = hsync_d[6];
assign vid_vsync  = vsync_d[6];
assign vid_r      = vid_fader_r;
assign vid_g      = vid_fader_g;
assign vid_b      = vid_fader_b;


endmodule

