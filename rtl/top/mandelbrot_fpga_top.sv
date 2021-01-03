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
localparam VHR      = 800;              // video horizontal resolution
localparam VVR      = 600;              // video vertical resolution
localparam CW       = 12;               // pixel counters width
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
localparam FPW      = 2*27;             // width of fixed-point numbers
localparam MFD      = 16;               // mandelbrot fifo depth

// video fifo
localparam VFD      = 32;               // video fifo depth
localparam FDW      = IMAW+IMDW;        // fifo data width


//// control ////
wire            man_init; // Mandebrot engine start
wire            man_done; // Mandelbrot engine done
wire [ FPW-1:0] man_x0;   // leftmost Mandelbrot coordinate
wire [ FPW-1:0] man_y0;   // uppermost Mandelbrot coordinate
wire [ FPW-1:0] man_xs;   // Mandelbrot x step
wire [ FPW-1:0] man_ys;   // Mandelbrot y step

ctrl_top #(
  .MI ("../../roms/ctrl_boot.hex"),
  .FPW  (FPW)
) ctrl_top (
  .clk        (sys_clk  ),
  .rst        (sys_rst  ),
  .man_init   (man_init ),
  .man_done   (man_done ),
  .man_x0     (man_x0   ),
  .man_y0     (man_y0   ),
  .man_xs     (man_xs   ),
  .man_ys     (man_ys   )
);


//// mandelbrot engine ////
reg  [   2-1:0] man_init_r;
wire            man_out_vld;
wire            man_out_rdy;
wire [ MIW-1:0] niter;
wire [IMAW-1:0] adr_o;

always @ (posedge man_clk, posedge man_rst) begin
  if (man_rst)
    man_init_r <= #1 2'b00;
  else if (man_clk_en)
    man_init_r <= #1 {man_init_r[0], man_init};
end

mandelbrot_top #(
  .FPW      (FPW      ),  // bitwidth of fixed-point numbers
  .MAXITERS (MAXITERS ),  // max number of iterations
  .IW       (MIW      ),  // width of iteration vars
  .AW       (IMAW     ),  // address width
  .CW       (CW       ),  // screen counter width
  .FD       (MFD      )   // fifo depth
) mandelbrot_top (
  .clk      (man_clk      ),  // clock
  .clk_en   (man_clk_en   ),  // clock enable
  .rst      (man_rst      ),  // reset
  .init     (man_init_r[1]),  // enable mandelbrot calculation (posedge sensitive!)
  .done     (man_done     ),  // mandelbrot engine done
  .man_x0   (man_x0       ),  // leftmost Mandelbrot coordinate
  .man_y0   (man_y0       ),  // uppermost Mandelbrot coordinate
  .man_xs   (man_xs       ),  // Mandelbrot x step
  .man_ys   (man_ys       ),  // Mandelbrot y step
  .out_vld  (man_out_vld  ),  // output valid
  .out_rdy  (man_out_rdy  ),  // output ready to receive (ack)
  .out_dat  (niter        ),  // number of iterations
  .out_adr  (adr_o        )   // mandelbrot coordinate address output
);


//// video async fifo ////
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

async_fifo #(
  .DW   (FDW),  // fifo width
  .FD   (VFD)   // fifo depth
) video_fifo (
  .in_clk       (man_clk    ),
  .in_clk_en    (man_clk_en ),
  .in_rst       (man_rst    ),
  .wr_en        (fifo_wr_en ),
  .in           (fifo_in    ),
  .out_clk      (vga_clk    ),
  .out_clk_en   (vga_clk_en ),
  .out_rst      (vga_rst    ),
  .rd_en        (fifo_rd_en ),
  .out          (fifo_out   ),
  .empty        (fifo_empty ),
  .full         (fifo_full  ),
  .half         ()
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
  .CCW      (CCW  ),  // color component width
  .HCW      (CW   ),  // horizontal counter width
  .VCW      (CW   ),  // vertical counter width
  .H_ACTIVE (VHR  ),  // horizontal resolution
  .V_ACTIVE (VVR  ),  // vertical resolution
  .TW       (TW   ),  // console text width in characters
  .TH       (TH   ),  // console text height in characters
  .CMAW     (CMAW ),  // console memory address width
  .CMDW     (CMDW ),  // console memory data width
  .IMAW     (IMAW ),  // index memory address width
  .IMDW     (IMDW ),  // index memory data width
  .CFR      (CFR  ),  // console text foreground color red value
  .CFG      (CFG  ),  // console text foreground color green value
  .CFB      (CFB  )   // console text foreground color blue value
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

