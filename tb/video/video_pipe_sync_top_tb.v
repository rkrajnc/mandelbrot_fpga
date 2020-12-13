// video_pipe_sync_top_tb.sv
// testbnech for the video pipeline
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


`timescale 1ns/10ps
`default_nettype none


module video_pipe_sync_top_tb();


//// local parameters ////
localparam CLK_HPER = 10;               // clock half-period
localparam WIDTH    = 640;              // image width
localparam HEIGHT   = 480;              // image height
localparam NPIXELS  = WIDTH*HEIGHT;     // number of active pixels
localparam CCW      = 8;                // color component width
localparam IMAW     = $clog2(NPIXELS);  // memory address width
localparam IMDW     = 8;                // memory data width
localparam TW       = 80;               // console text width in characters
localparam TH       = 2;                // console text height in characters
localparam NCHARS   = TW*TH;            // number of characters in console
localparam CMAW     = $clog2(NCHARS);   // console memory address width
localparam CMDW     = 8;                // console memory data width

localparam CONSOLE_EN = 1'b1;
localparam BORDER_EN  = 1'b0;


//// clock ////
reg clk;
reg clk_en = 1'b1;

initial begin
  clk = 0;
  forever #CLK_HPER clk = !clk;
end


//// reset ////
reg rst;

initial begin
  rst = 1;
  repeat (10) @ (posedge clk); #1;
  rst = 0;
end


//// pixel counter ////
integer pixel_counter;

always @ (posedge clk, posedge rst) begin
  if (rst) begin
    pixel_counter = 0;
  end else if (clk_en) begin
    if (vid_active) pixel_counter = pixel_counter+1;
    else if (pixel_counter == WIDTH*HEIGHT) pixel_counter = 0;
  end
end


//// testbench ////
reg en = 0;

initial begin
  integer i;
  integer x;
  integer y;

  $display("TB : starting");

  // fill video index ram
  for (y=0; y<HEIGHT; y=y+1) begin
    for (x=0; x<WIDTH; x=x+1) begin
      DUT.video_index_ram.mem[y*WIDTH+x] = x+y+100;
    end
  end

  // fill console ram
  i = 0;
  for (y=0; y<TH; y=y+1) begin
    for (x=0; x<TW; x=x+1) begin
      DUT.video_text_console.console_text_ram.mem[i] = "a" + i;
      i = i+1;
    end
  end

  // wait for reset
  $display("TB : waiting for reset ...");
  wait(!rst);
  repeat(10) @ (posedge clk); #1;

  // enable video pipe and frame grabber
  $display("TB : Enabling video pipe & frame grabber ...");
  video_frame_writter.enable_writter();
  en = 1'b1;

  // wait for frame end
  $display("TB : Waiting for end of video frame ...");
  wait(pixel_counter == WIDTH*HEIGHT);

  // done
  repeat(10) @ (posedge clk); #1;
  $display("TB : done");
  $finish(0);
end


//// DUT ////
wire vid_active;
wire vid_hsync;
wire vid_vsync;
wire [CCW-1:0] vid_r;
wire [CCW-1:0] vid_g;
wire [CCW-1:0] vid_b;

video_pipe_sync_top #(
  .CCW  (CCW  ),  // color component width
  .TW   (TW   ),  // console text width in characters
  .TH   (TH   ),  // console text height in characters
  .CMAW (CMAW ),  // console memory address width
  .CMDW (CMDW ),  // console memory data width
  .IMAW (IMAW ), // memory address width
  .IMDW (IMDW )  // memory data width
) DUT (
  .clk            (clk          ),  // video clock
  .clk_en         (clk_en       ),  // video clock enable
  .rst            (rst          ),  // video clock reset
  .en             (en           ),  // enable video pipe
  .border_en      (BORDER_EN    ),  // enable drawing of border
  .console_en     (CONSOLE_EN   ),  // enable textual console
  .vram_clk_w     (1'b0         ),  // video memory write clock
  .vram_clk_en_w  (1'b0         ),  // video memory clock enable
  .vram_we        (1'b0         ),  // video memory write enable
  .vram_adr_w     ({IMAW{1'b0}} ),  // video memory write address
  .vram_dat_w     ({IMDW{1'b0}} ),  // video memory write data
  .con_clk_w      (1'b0         ),  // video memory write clock
  .con_clk_en_w   (1'b0         ),  // video memory clock enable
  .con_we         (1'b0         ),  // video memory write enable
  .con_adr_w      ({CMAW{1'b0}} ),  // video memory write address
  .con_dat_w      ({CMDW{1'b0}} ),  // video memory write data
  .vid_active     (vid_active   ),  // video active (not blanked)
  .vid_hsync      (vid_hsync    ),  // video horizontal sync
  .vid_vsync      (vid_vsync    ),  // video vertical sync
  .vid_r          (vid_r        ),  // video red component
  .vid_g          (vid_g        ),  // video green component
  .vid_b          (vid_b        )   // video blue component
);


//// frame writter ////
video_frame_writter #(
  .FILENAME ("frame_"),
  .WIDTH    (WIDTH),
  .HEIGHT   (HEIGHT),
  .CCW      (CCW)
) video_frame_writter (
 .vid_clk     (clk        ),
 .vid_clk_en  (clk_en     ),
 .vid_rst     (rst        ),
 .vid_active  (vid_active ),
 .vid_r       (vid_r      ),
 .vid_g       (vid_g      ),
 .vid_b       (vid_b      )
);


//// dump variables for icarus ////
`ifdef SIM_ICARUS
  `ifdef SIM_WAVES
    initial begin
      $dumpfile(`WAV_FILE);
      $dumpvars(0, video_pipe_sync_top_tb);
      //$dumpvars(SRC_CLK_PERIOD, clock_frequency_check_tb);
    end
  `endif
`endif


endmodule

