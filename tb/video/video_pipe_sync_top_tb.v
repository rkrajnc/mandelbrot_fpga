// video_pipe_sync_top_tb.sv
// testbnech for the video pipeline
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


`timescale 1ns/10ps
`default_nettype none


module video_pipe_sync_top_tb();


//// local parameters ////
localparam CLK_HPER = 10;   // clock half-period
localparam WIDTH    = 640;  // image width
localparam HEIGHT   = 480;  // image height
localparam CCW      = 8;    // color component width
localparam MAW      = 19;   // memory address width
localparam MDW      = 8;    // memory data width


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
  integer x;
  integer y;

  $display("TB : starting");

  // fill video index ram
  for (y=0; y<HEIGHT; y=y+1) begin
    for(x=0; x<WIDTH; x=x+1) begin
      DUT.video_index_ram.mem[y*WIDTH+x] = y;
    end
  end
  //for (i=0; i<256; i=i+1) DUT.video_clut_rom.mem[i] = i;

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
wire [8-1:0] vid_r;
wire [8-1:0] vid_g;
wire [8-1:0] vid_b;

video_pipe_sync_top #(
  .CCW (CCW),  // color component width
  .MAW (MAW), // memory address width
  .MDW (MDW)  // memory data width
) DUT (
  .clk            (clk        ),  // video clock
  .clk_en         (clk_en     ),  // video clock enable
  .rst            (rst        ),  // video clock reset
  .en             (en         ),  // enable video pipe
  .border_en      (1'b0       ),  // enable drawing of border
  .console_en     (1'b1       ),  // enable textual console
  .vram_clk_w     (1'b0       ),  // video memory write clock
  .vram_clk_en_w  (1'b0       ),  // video memory clock enable
  .vram_we        (1'b0       ),  // video memory write enable
  .vram_adr_w     (19'b0      ),  // video memory write address
  .vram_dat_w     (8'b0       ),  // video memory write data
  .vid_active     (vid_active ),  // video active (not blanked)
  .vid_hsync      (vid_hsync  ),  // video horizontal sync
  .vid_vsync      (vid_vsync  ),  // video vertical sync
  .vid_r          (vid_r      ),  // video red component
  .vid_g          (vid_g      ),  // video green component
  .vid_b          (vid_b      )   // video blue component
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

