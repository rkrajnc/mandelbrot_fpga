// video_pipe_sync_top.v
// synchronous video pipeline
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


module video_pipe_sync_top #(
  parameter CW  = 8,  // color component width
  parameter MAW = 19, // memory address width
  parameter MDW = 8   // memory data width
)(
  // system
  input  wire           clk,            // video clock
  input  wire           clk_en,         // video clock enable
  input  wire           rst,            // video clock reset
  // control
  input  wire           en,             // enable video pipe
  input  wire           border_en,      // enable drawing of border
  input  wire           console_en,     // enable textual console
  // video ram write interface
  input  wire           vram_clk_w,     // video memory write clock
  input  wire           vram_clk_en_w,  // video memory clock enable
  input  wire           vram_we,        // video memory write enable
  input  wire [MAW-1:0] vram_adr_w,     // video memory write address
  input  wire [MDW-1:0] vram_dat_w,     // video memory write data
  // video output
  output wire           vid_active,     // video active (not blanked)
  output wire           vid_hsync,      // video horizontal sync
  output wire           vid_vsync,      // video vertical sync
  output wire [ CW-1:0] vid_r,          // video red component
  output wire [ CW-1:0] vid_g,          // video green component
  output wire [ CW-1:0] vid_b           // video blue component
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
wire [ HCW-1:0] h_match  = 'd0;
wire [ VCW-1:0] v_match  = 'd0;
wire [ HCW-1:0] h_cnt;
wire [ HCW-1:0] v_cnt;
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


//// video ram read ////
wire            vram_rd;    // video ram read enable
reg  [ MAW-1:0] vram_adr_r; // video ram read address
wire [ MDW-1:0] vram_dat_r; // video ram read data

assign vram_rd = active;

always @ (posedge clk, posedge rst) begin
  if (rst) begin
    vram_adr_r <= #1 {MAW{1'b0}};
  end else if (clk_en) begin
    if (a_end || !en)
      vram_adr_r <= #1 {MAW{1'b0}};
    else if (active && en)
     vram_adr_r <= #1 vram_adr_r + { {(MAW-1){1'b0}}, 1'b1 };
  end
end


//// video index ram ////
localparam MD = H_WHOLE*V_WHOLE;  // memory depth

reg                 vram_active [0:1];
reg                 vram_hsync  [0:1];
reg                 vram_vsync  [0:1];
reg  [     HCW-1:0] vram_h_cnt  [0:1];
reg  [     VCW-1:0] vram_v_cnt  [0:1];

ram_generic_tp #(
  .MI               (""),   // memory initialization file
  .READ_REGISTERED  (1),    // when true, read port has an additional register
  .DW               (MDW),  // data width
  .MD               (MD),   // memory depth
  .AW               (MAW)   // address width
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

always @ (posedge clk) begin
  if (clk_en) begin
    vram_active[0] <= #1 active;
    vram_active[1] <= #1 vram_active[0];
    vram_hsync[0]  <= #1 hsync;
    vram_hsync[1]  <= #1 vram_hsync[0];
    vram_vsync[0]  <= #1 vsync;
    vram_vsync[1]  <= #1 vram_vsync[0];
    vram_h_cnt[0]  <= #1 h_cnt;
    vram_h_cnt[1]  <= #1 vram_h_cnt[0];
    vram_v_cnt[0]  <= #1 v_cnt;
    vram_v_cnt[1]  <= #1 vram_v_cnt[0];
  end
end


//// indexed color lookup ////
localparam CLUT_MI = "../../rtl/memory/mandelbrot_clut_8.hex"; // CLUT memory initialization file
localparam CLUT_DW = 3*CW;            // CLUT data width
localparam CLUT_MD = 1<<MDW;          // CLUT memory depth
localparam CLUT_AW = $clog2(CLUT_MD); // CLUT address width

wire [     MDW-1:0] clut_adr;
wire [ CLUT_DW-1:0] clut_dat_r;
wire [      CW-1:0] clut_r;
wire [      CW-1:0] clut_g;
wire [      CW-1:0] clut_b;
reg                 clut_active;
reg                 clut_hsync;
reg                 clut_vsync;
reg  [     HCW-1:0] clut_h_cnt;
reg  [     VCW-1:0] clut_v_cnt;

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

always @ (posedge clk) begin
  if (clk_en) begin
    clut_active <= #1 vram_active[1];
    clut_hsync  <= #1 vram_hsync[1];
    clut_vsync  <= #1 vram_vsync[1];
    clut_h_cnt  <= #1 vram_h_cnt[1];
    clut_v_cnt  <= #1 vram_v_cnt[1];
  end
end


//// border ////
wire          line_top;
wire          line_middle;
wire          line_bottom;
wire          line_left;
wire          line_center;
wire          line_right;
wire          lines;
reg  [CW-1:0] lines_r;
reg  [CW-1:0] lines_g;
reg  [CW-1:0] lines_b;
reg           lines_active;
reg           lines_hsync;
reg           lines_vsync;

assign line_top     = clut_v_cnt == 'd0;
assign line_middle  = clut_v_cnt == V_ACTIVE/2;
assign line_bottom  = clut_v_cnt == V_ACTIVE-1;
assign line_left    = clut_h_cnt == 'd0;
assign line_center  = clut_h_cnt == H_ACTIVE/2;
assign line_right   = clut_h_cnt == H_ACTIVE-1;
assign lines = line_top || line_middle || line_bottom || line_left || line_center || line_right;

always @ (posedge clk) begin
  if (clk_en) begin
    lines_r       <= #1 clut_active ? (border_en && lines ? {CW{1'b1}} : clut_dat_r[3*CW-1:2*CW]) : {CW{1'b0}};
    lines_g       <= #1 clut_active ? (border_en && lines ? {CW{1'b1}} : clut_dat_r[2*CW-1:1*CW]) : {CW{1'b0}};
    lines_b       <= #1 clut_active ? (border_en && lines ? {CW{1'b1}} : clut_dat_r[1*CW-1:0*CW]) : {CW{1'b0}};
    lines_active  <= #1 clut_active;
    lines_hsync   <= #1 clut_hsync;
    lines_vsync   <= #1 clut_vsync;
  end
end


//// output ////
assign vid_active = lines_active;
assign vid_hsync  = lines_hsync;
assign vid_vsync  = lines_vsync;
assign vid_r      = lines_r;
assign vid_g      = lines_g;
assign vid_b      = lines_b;


endmodule

