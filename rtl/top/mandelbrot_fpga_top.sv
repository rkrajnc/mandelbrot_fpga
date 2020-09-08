// mandelbrot_fpga_top.v
// top-level mandelbrot module
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


module mandelbrot_fpga_top #(
  parameter VW = 8
)(
  // system
  input  wire man_clk,
  input  wire man_clk_en,
  input  wire man_rst,
  input  wire sys_clk,
  input  wire sys_clk_en,
  input  wire sys_rst,
  input  wire vga_clk,
  input  wire vga_clk_en,
  input  wire vga_rst,
  // video output
  output wire vga_hsync,
  output wire vga_vsync,
  output wire vga_vld,
  output wire [ VW-1:0] vga_r,
  output wire [ VW-1:0] vga_g,
  output wire [ VW-1:0] vga_b
);


//// video sync generator ////
localparam HCW        = 12;       // horizontal counter width
localparam VCW        = 12;       // vertical counter width
localparam F_CNT      = 60;       // number of frames in a second
localparam H_POL      = 1;        // horizontal sync polarity (0=positive, 1=negative)
localparam H_SYNC     = 96;       // sync pulse width in pixels
localparam H_BACK     = 45+3;     // back porch width in pixels + added 3 pixels for active 'border'
localparam H_ACTIVE   = 640;      // active time width in pixels, actual width is 646px with border
localparam H_FRONT    = 13+3;     // front porch width in pixels + added 3 pixels for active 'border'
localparam H_WHOLE    = 800;      // whole line width in pixels
localparam V_POL      = 1;        // vertical sync polarity ((0=positive, 1=negative)
localparam V_SYNC     = 2;        // sync pulse width in lines
localparam V_BACK     = 31+2;     // back porch width in lines + added 2 lines for active 'border'
localparam V_ACTIVE   = 480;      // active time width in lines, acutal width is 484px with border
localparam V_FRONT    = 8+2;      // front porch width in lines + added 2 lines for active 'border'
localparam V_WHOLE    = 525;      // whole frame width in lines

wire           vga_en   = 'd1;
wire [HCW-1:0] h_match  = 'd0;
wire [VCW-1:0] v_match  = 'd0;

wire [HCW-1:0] h_cnt;         // horizontal counter
wire [VCW-1:0] v_cnt;         // vertical counter
wire           cnt_match;     // position match
wire           active;        // active output (otherwise border)
wire           blank;         // blank output (otherwise active)
wire           a_start;       // active start (x==0 && y==0)
wire           a_end;         // active end ((x==H_ACTIVE-1 && y==V_ACTIVE-1)
wire [  7-1:0] f_cnt;         // frame counter (resets for every second)
wire           h_sync;        // horizontal sync signal
wire           v_sync;        // vertical sync signal

video_sync_gen #(
  .HCW        (HCW        ),  // horizontal counter width
  .VCW        (VCW        ),  // vertical counter width
  .F_CNT      (F_CNT      ),  // number of frames in a second
  .H_POL      (H_POL      ),  // horizontal sync polarity (0=positive, 1=negative)
  .H_SYNC     (H_SYNC     ),  // sync pulse width in pixels
  .H_BACK     (H_BACK     ),  // back porch width in pixels + added 3 pixels for active 'border'
  .H_ACTIVE   (H_ACTIVE   ),  // active time width in pixels, actual width is 646px with border
  .H_FRONT    (H_FRONT    ),  // front porch width in pixels + added 3 pixels for active 'border'
  .H_WHOLE    (H_WHOLE    ),  // whole line width in pixels
  .V_POL      (V_POL      ),  // vertical sync polarity ((0=positive, 1=negative)
  .V_SYNC     (V_SYNC     ),  // sync pulse width in lines
  .V_BACK     (V_BACK     ),  // back porch width in lines + added 2 lines for active 'border'
  .V_ACTIVE   (V_ACTIVE   ),  // active time width in lines, acutal width is 484px with border
  .V_FRONT    (V_FRONT    ),  // front porch width in lines + added 2 lines for active 'border'
  .V_WHOLE    (V_WHOLE    )   // whole frame width in lines
) video_sync_gen (
  .clk        (vga_clk    ),  // clock
  .clk_en     (vga_clk_en ),  // clock enable
  .rst        (vga_rst    ),  // reset
  .en         (vga_en     ),  // enable counters
  .h_match    (h_match    ),  // horizontal counter match compare value
  .v_match    (v_match    ),  // vertical counter match compare value
  .h_cnt      (h_cnt      ),  // horizontal counter
  .v_cnt      (v_cnt      ),  // vertical counter
  .cnt_match  (cnt_match  ),  // position match
  .active     (active     ),  // active output (otherwise border)
  .blank      (blank      ),  // blank output (otherwise active)
  .a_start    (a_start    ),  // active start (x==0 && y==0)
  .a_end      (a_end      ),  // active end ((x==H_ACTIVE-1 && y==V_ACTIVE-1)
  .f_cnt      (f_cnt      ),  // frame counter (resets for every second)
  .h_sync     (h_sync     ),  // horizontal sync signal
  .v_sync     (v_sync     )   // vertical sync signal
);


//// generate border image ////
wire line_top;
wire line_middle;
wire line_bottom;
wire line_left;
wire line_center;
wire line_right;
wire lines;

assign line_top     = v_cnt == 'd0;
assign line_middle  = v_cnt == V_ACTIVE/2;
assign line_bottom  = v_cnt == V_ACTIVE-1;
assign line_left    = h_cnt == 'd0;
assign line_center  = h_cnt == H_ACTIVE/2;
assign line_right   = h_cnt == H_ACTIVE-1;
assign lines = line_top || line_middle || line_bottom || line_left || line_center || line_right;


//// assign outputs ////
assign vga_hsync  = h_sync;
assign vga_vsync  = v_sync;
assign vga_vld    = active;
assign vga_r      = lines ? 8'hff : 8'h00;
assign vga_g      = lines ? 8'hff : 8'h00;
assign vga_b      = lines ? 8'hff : 8'h00;


endmodule

