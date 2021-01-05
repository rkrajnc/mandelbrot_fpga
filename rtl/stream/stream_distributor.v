// stream_distributor.v
// distributor for multiple stream sinks, priority encoded
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


module stream_distributor #(
  parameter NS = 2,   // number of sinks
  parameter DW = 32   // data width
)(
  // system
  input  wire           clk,      // clock
  input  wire           clk_en,   // clock enable
  input  wire           rst,      // reset
  // input
  input  wire           in_vld,   // input valid
  output wire           in_rdy,   // input ack
  input  wire [ DW-1:0] in_dat,   // input data
  // output
  output wire [ NS-1:0] out_vld,  // output valid
  input  wire [ NS-1:0] out_rdy,  // output ack
  output wire [ DW-1:0] out_dat   // output data
);


//// input stream reg ////
wire          ir_out_vld;
wire          ir_out_rdy;

stream_reg #(
  .DW   (DW) // data width
) str_reg (
  .clk      (clk        ),  // clock
  .clk_en   (clk_en     ),  // clock enable
  .rst      (rst        ),  // reset
  .in_vld   (in_vld     ),  // input valid
  .in_rdy   (in_rdy     ),  // input ack
  .in_dat   (in_dat     ),  // input data
  .out_vld  (ir_out_vld ),  // output valid
  .out_rdy  (ir_out_rdy ),  // output ack
  .out_dat  (out_dat    )   // output data
);


//// one-hot sink select, priority encoded ////
wire [NS-1:0] ss;

assign ss[0] = out_rdy[0];
genvar s;
generate for (s=1; s<NS; s=s+1) begin : SS_GEN_BLK
  assign ss[s] = out_rdy[s] && ~|out_rdy[s-1:0];
end endgenerate


//// handle out_rdy & out_vld ////
assign ir_out_rdy = |out_rdy;
assign out_vld    = {NS{ir_out_vld}} & ss;


endmodule

