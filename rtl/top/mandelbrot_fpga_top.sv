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


//// video pipe ////
video_pipe_sync_top #(
  .CW  (8),  // color component width
  .MAW (19), // memory address width
  .MDW (8)   // memory data width
) video_pipe (
  .clk            (vga_clk),            // video clock
  .clk_en         (vga_rst),         // video clock enable
  .rst            (vga_rst),            // video clock reset
  .en             (1'b1),             // enable video pipe
  .border_en      (1'b1),      // enable drawing of border
  .console_en     (1'b0),     // enable textual console
  .vram_clk_w     (1'b0),     // video memory write clock
  .vram_clk_en_w  (1'b0),  // video memory clock enable
  .vram_we        (1'b0),        // video memory write enable
  .vram_adr_w     (19'b0),     // video memory write address
  .vram_dat_w     (8'b0),     // video memory write data
  .vid_active     (vga_vld),     // video active (not blanked)
  .vid_hsync      (vga_hsync),      // video horizontal sync
  .vid_vsync      (vga_vsync),      // video vertical sync
  .vid_r          (vga_r),          // video red component
  .vid_g          (vga_g),          // video green component
  .vid_b          (vga_b)           // video blue component
);


endmodule

