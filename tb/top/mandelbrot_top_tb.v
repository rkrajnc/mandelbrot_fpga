// mandelbrot_top_tb.sv
// testbench for the top mandelbrot module
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


`timescale 1ns/10ps
`default_nettype none


module mandelbrot_top_tb();


//// local parameters ////
localparam CLK_HPER = 10;               // clock half-period
localparam WIDTH    = 640;              // image width
localparam HEIGHT   = 480;              // image height
localparam NPIXELS  = WIDTH*HEIGHT;     // number of active pixels
localparam CCW      = 8;                // color component width


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
      DUT.video_pipe.video_index_ram.mem[y*WIDTH+x] = x+y+100;
    end
  end

  // wait for reset
  $display("TB : waiting for reset ...");
  wait(!rst);
  repeat(10) @ (posedge clk); #1;

  // wait for endf of mandelbrot calc
  wait(!DUT.mandelbrot_coords.cnt_en);
  repeat(10) @ (posedge clk); #1;

  // enable video pipe and frame grabber
  $display("TB : Enabling video pipe & frame grabber ...");
  video_frame_writter.enable_writter();
  en = 1'b1;

  // wait for frame end
  $display("TB : Waiting for end of video frame ...");
  wait(pixel_counter == WIDTH*HEIGHT);

  // wait for another frame
  repeat (10) @ (posedge clk); #1;
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

mandelbrot_fpga_top #(
  .VW (CCW)
) DUT (
  .man_clk      (clk),
  .man_clk_en   (clk_en),
  .man_rst      (rst),
  .sys_clk      (clk),
  .sys_clk_en   (clk_en),
  .sys_rst      (rst),
  .vga_clk      (clk),
  .vga_clk_en   (clk_en),
  .vga_rst      (rst),
  .vga_hsync    (vid_hsync),
  .vga_vsync    (vid_vsync),
  .vga_vld      (vid_active),
  .vga_r        (vid_r),
  .vga_g        (vid_g),
  .vga_b        (vid_b)
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
      $dumpvars(0, mandelbrot_top_tb);
      //$dumpvars(SRC_CLK_PERIOD, clock_frequency_check_tb);
    end
  `endif
`endif


endmodule

