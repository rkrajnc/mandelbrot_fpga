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


//// parameters ////
// video
localparam NCOLORS  = 256;              // number of colors
localparam CCW      = $clog2(NCOLORS);  // color component width
localparam VHR      = 640;              // video horizontal resolution
localparam VVR      = 480;              // video vertical resolution
localparam NPIXELS  = VHR*VVR;          // number of pixels

// console
localparam TW       = 80;               // console text width
localparam TH       = 2;                // console text height
localparam NCHARS   = TW*TH;            // number of characters in console
localparam CMAW     = $clog2(NCHARS);   // console address width
localparam CMDW     = 8;                // console data width
localparam CFR      = 8'd200;           // console text foreground color red value
localparam CFG      = 8'd200;           // console text foreground color green value
localparam CFB      = 8'd200;           // console text foreground color blue value

// index memory
localparam IMAW     = $clog2(NPIXELS);  // video index memory address width
localparam IMDW     = 8;                // video index memory data width

// mandelbrot
localparam MAXITERS = 256;              // max number of iterations
localparam MIW      = $clog2(MAXITERS); // width of iteration vars
localparam FPW      = 1*27;             // width of fixed-point numbers

// fifo
localparam FD       = 4;                // fifo depth
localparam FDW      = IMAW+IMDW;        // fifo data width


//// mandelbrot engine ////
wire man_init;
wire man_coord_rdy;
wire man_coord_vld;
wire [FPW-1:0] man_x;
wire [FPW-1:0] man_y;
wire [IMAW-1:0] man_adr;

assign man_init = 1'b0;

mandelbrot_coords #(
  .VMINX  (0    ),  // screen min x coordinate
  .VMAXX  (VHR-1),  // screen max x coordinate
  .VMINY  (0    ),  // screen min y coordinate
  .VMAXY  (VVR-1),  // screen max y coordinate
  .CW     (12   ),  // screen counter width
  .AW     (IMAW ),  // address width
  .FPW    (FPW  )   // fixed point size
) mandelbrot_coords (
  .clk      (vga_clk      ),
  .clk_en   (vga_clk_en   ),
  .rst      (vga_rst      ),
  .init     (man_init     ),
  .out_rdy  (man_coord_rdy),
  .out_vld  (man_coord_vld),
  .x        (man_x        ),
  .y        (man_y        ),
  .adr      (man_adr      )
);


wire man_out_vld;
wire man_out_rdy;
wire [MIW-1:0] niter;
wire [IMAW-1:0] adr_o;

mandelbrot_calc #(
  .MAXITERS (MAXITERS), // max number of iterations
  .IW       (MIW),      // width of iteration vars
  .FPW      (FPW),      // bitwidth of fixed-point numbers
  .AW       (IMAW)      // address width
) mandelbrot_calc (
  .clk      (vga_clk      ),      // clock
  .clk_en   (vga_clk_en   ),   // clock enable
  .rst      (vga_rst      ),      // reset
  .in_vld   (man_coord_vld),   // input valid
  .in_rdy   (man_coord_rdy),   // input ack
  .x_man    (man_x        ),    // mandelbrot x coordinate
  .y_man    (man_y        ),    // mandelbrot y cooridnate
  .adr_i    (man_adr      ),    // mandelbrot coordinate address input
  .out_vld  (man_out_vld  ),  // output valid
  .out_rdy  (man_out_rdy  ),  // output ack
  .niter    (niter        ),    // number of iterations
  .adr_o    (adr_o        )     // mandelbrot coordinate address output
);


//// results async fifo ////
// TODO - mandelbrot engine is on man_clk, need async fifo here!

wire fifo_en;
wire [FDW-1:0] fifo_in;
wire [FDW-1:0] fifo_out;
wire fifo_wr_en;
wire fifo_rd_en;
wire fifo_full;
wire fifo_empty;

assign fifo_en      = 1'b1;
assign fifo_in      = {adr_o, niter};
assign fifo_wr_en   = man_out_vld && !fifo_full;
assign man_out_rdy  = !fifo_full;
assign fifo_rd_en   = !fifo_empty;

sync_fifo #(
  .FD   (FD),   // fifo depth
  .DW   (FDW)   // data width
) mandelbrot_fifo (
  .clk      (vga_clk     ), // clock
  .clk_en   (vga_clk_en  ), // clock enable
  .rst      (vga_rst     ), // reset
  .en       (fifo_en     ), // enable (if !en, reset fifo)
  .in       (fifo_in     ), // write data
  .out      (fifo_out    ), // read data
  .wr_en    (fifo_wr_en  ), // fifo write enable
  .rd_en    (fifo_rd_en  ), // fifo read enable
  .full     (fifo_full   ), // fifo full
  .empty    (fifo_empty  ), // fifo empty
  .half     (            )  // fifo is less than half full
);


//// video pipe ////
wire            vid_en;
wire            vid_border_en;
wire            vid_console_en;
wire            vram_we;
wire [IMAW-1:0] vram_adr_w;
wire [IMDW-1:0] vram_dat_w;

assign vid_en         = 1'b1;
assign vid_border_en  = 1'b0;
assign vid_console_en = 1'b0;
assign vram_we        = !fifo_empty;
assign vram_adr_w     = fifo_out[IMAW+IMDW-1:IMDW];
assign vram_dat_w     = fifo_out[IMDW-1:0];

video_pipe_sync_top #(
  .CCW      (CCW ), // color component width
  .TW       (TW  ), // console text width in characters
  .TH       (TH  ), // console text height in characters
  .CMAW     (CMAW), // console memory address width
  .CMDW     (CMDW), // console memory data width
  .IMAW     (IMAW), // index memory address width
  .IMDW     (IMDW), // index memory data width
  .CFR      (CFR ), // console text foreground color red value
  .CFG      (CFG ), // console text foreground color green value
  .CFB      (CFB )  // console text foreground color blue value
) video_pipe (
  .clk            (vga_clk        ),  // video clock
  .clk_en         (vga_clk_en     ),  // video clock enable
  .rst            (vga_rst        ),  // video clock reset
  .en             (vid_en         ),  // enable video pipe
  .border_en      (vid_border_en  ),  // enable drawing of border
  .console_en     (vid_console_en ),  // enable textual console
  .vram_clk_w     (vga_clk        ),  // video memory write clock
  .vram_clk_en_w  (vga_clk_en     ),  // video memory clock enable
  .vram_we        (vram_we        ),  // video memory write enable
  .vram_adr_w     (vram_adr_w     ),  // video memory write address
  .vram_dat_w     (vram_dat_w     ),  // video memory write data
  .con_clk_w      (1'b0           ),  // console memory write clock
  .con_clk_en_w   (1'b0           ),  // console memory clock enable
  .con_we         (1'b0           ),  // console memory write enable
  .con_adr_w      ({CMAW{1'bx}}   ),  // console memory write address
  .con_dat_w      ({CMDW{1'bx}}   ),  // console memory write data
  .vid_active     (vga_vld        ),  // video active (not blanked)
  .vid_hsync      (vga_hsync      ),  // video horizontal sync
  .vid_vsync      (vga_vsync      ),  // video vertical sync
  .vid_r          (vga_r          ),  // video red component
  .vid_g          (vga_g          ),  // video green component
  .vid_b          (vga_b          )   // video blue component
);


endmodule

