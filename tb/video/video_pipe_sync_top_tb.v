// video_pipe_sync_top_tb.sv
// testbnech for the video pipeline
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


`timescale 1ns/10ps
`default_nettype none


module video_pipe_sync_top_tb();


//// clock ////
localparam CLK_HPER = 10;
reg clk;

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


//// testbench ////
reg en = 0;

initial begin
  $display("TB : starting");
  wait(!rst);

  repeat(10) @ (posedge clk); #1;

  en = 1'b1;

  repeat(640*2 + 100) @ (posedge clk); #1;

  // done
  repeat(10) @ (posedge clk); #1;
  $display("TB : done");
  $finish(0);
end


//// DUT ////

video_pipe_sync_top #(
  .CW  (8),  // color component width
  .MAW (19), // memory address width
  .MDW (8)   // memory data width
) DUT (
  .clk            (clk),    // video clock
  .clk_en         (1'b1),   // video clock enable
  .rst            (rst),    // video clock reset
  .en             (en),     // enable video pipe
  .border_en      (1'b0),   // enable drawing of border
  .console_en     (1'b0),   // enable textual console
  .vram_clk_w     (1'b0),   // video memory write clock
  .vram_clk_en_w  (1'b0),   // video memory clock enable
  .vram_we        (1'b0),   // video memory write enable
  .vram_adr_w     (19'b0),  // video memory write address
  .vram_dat_w     (8'b0),   // video memory write data
  .vid_active     (),       // video active (not blanked)
  .vid_hsync      (),       // video horizontal sync
  .vid_vsync      (),       // video vertical sync
  .vid_r          (),       // video red component
  .vid_g          (),       // video green component
  .vid_b          ()        // video blue component
);


/*
module video_pipe_sync_top #(
  parameter CW  = 8,  // color component width
  parameter MAW = 19, // memory address width
  parameter MDW = 8   // memory data width
)(
  // system
  input  logic            clk,            // video clock
  input  logic            clk_en,         // video clock enable
  input  logic            rst,            // video clock reset
  // control
  input  logic            en,             // enable video pipe
  input  logic            border_en,      // enable drawing of border
  input  logic            console_en,     // enable textual console
  // video ram write interface
  input  logic            vram_clk_w,     // video memory write clock
  input  logic            vram_clk_en_w,  // video memory clock enable
  input  logic            vram_we,        // video memory write enable
  input  logic [ MAW-1:0] vram_adr_w,     // video memory write address
  input  logic [ MDW-1:0] vram_dat_w,     // video memory write data
  // video output
  output logic            vid_active,     // video active (not blanked)
  output logic            vid_hsync,      // video horizontal sync
  output logic            vid_vsync,      // video vertical sync
  output logic [  CW-1:0] vid_r,          // video red component
  output logic [  CW-1:0] vid_g,          // video green component
  output logic [  CW-1:0] vid_b           // video blue component
);
*/


//// dump variables ////
initial begin
  $dumpfile("out.fst");
  $dumpvars(0, video_pipe_sync_top_tb);
end


endmodule

