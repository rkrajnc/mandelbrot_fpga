// video_frame_writter.v
// captures video frames and saves them to a file
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


module video_frame_writter #(
  parameter FILENAME  = "frame_",
  parameter WIDTH     = 640,
  parameter HEIGHT    = 480,
  parameter CCW       = 8
)(
  // system
  input  wire           vid_clk,
  input  wire           vid_clk_en,
  input  wire           vid_rst,
  // video input
  input  wire           vid_active,
  input  wire [CCW-1:0] vid_r,
  input  wire [CCW-1:0] vid_g,
  input  wire [CCW-1:0] vid_b
);


//// enable ////
reg en=0;

task enable_writter;
begin
  en = 1;
end
endtask

task disable_writter;
begin
  en = 0;
end
endtask


//// file operations ////
integer fp = 0;
integer frame_counter = 0;
reg [128*8-1:0] filename = {128{8'b0}};
reg header_written = 0;

task increment_frame_counter;
begin
  frame_counter = frame_counter + 1;
end
endtask

task close_file;
begin
  if (fp) $fclose(fp);
  fp = 0;
  header_written = 0;
end
endtask

task open_file;
begin
  close_file();
  $sformat(filename, "%s_%03d.ppm", FILENAME, frame_counter);
  fp = $fopen(filename, "wb");
  header_written = 0;
end
endtask

task write_ppm_header;
begin
  if (!fp) open_file();
  $fwrite(fp, "P3\n%d %d\n%d\n", WIDTH, HEIGHT, 1<<CCW);
  header_written = 1;
end
endtask

task write_pixel;
  input [CCW-1:0] r;
  input [CCW-1:0] g;
  input [CCW-1:0] b;
begin
  $fwrite(fp, "%d %d %d\n", r, g, b);
end
endtask


//// grabber ////
integer pixel_counter;

always @ (posedge vid_clk, posedge vid_rst) begin
  if (vid_rst) begin
    pixel_counter = 0;
    header_written = 1'b0;
  end else if (vid_clk_en) begin
    if (en && vid_active && pixel_counter < WIDTH*HEIGHT) begin
      if (!header_written) write_ppm_header();
      write_pixel(vid_r, vid_g, vid_b);
      pixel_counter = pixel_counter + 1;
    end else if (pixel_counter == WIDTH*HEIGHT) begin
      pixel_counter = 0;
      close_file();
      frame_counter = frame_counter + 1;
    end
  end
end


endmodule

