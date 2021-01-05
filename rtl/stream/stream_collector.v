// stream_collector.v
// collector for multiple stream sources, priority encoded
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


module stream_collector #(
  parameter NS = 2,   // number of sources
  parameter DW = 32   // data width
)(
  // system
  input  wire             clk,      // clock
  input  wire             clk_en,   // clock enable
  input  wire             rst,      // reset
  // input
  input  wire [   NS-1:0] in_vld,   // input valid
  output wire [   NS-1:0] in_rdy,   // input ack
  input  wire [NS-1:0][DW-1:0] in_dat,   // input data
  // output
  output wire             out_vld,  // output valid
  input  wire             out_rdy,  // output ack
  output wire    [DW-1:0] out_dat   // output data
);


//// one-hot source select, priority encoded ////
wire [NS-1:0] ss;

assign ss[0] = in_vld[0];
genvar s;
generate for (s=1; s<NS; s=s+1) begin : SS_GEN_BLK
  assign ss[s] = in_vld[s] && ~|in_vld[s-1:0];
end endgenerate


////
localparam NSLOG = $clog2(NS);

wire  [NSLOG-1:0] ss_a;

genvar i,j;
generate
  for (j=0; j<NSLOG; j=j+1) begin : SS_MASK_OL
    wire [NS-1:0] ss_msk;
    for (i=0; i<NS; i=i+1) begin : SS_MASK_IL
      assign ss_msk[i] = i[j];
    end
    assign ss_a[j] = |(ss & ss_msk);
  end
endgenerate


//// handle ////
wire          or_in_vld;
wire          or_in_rdy;
wire [DW-1:0] or_in_dat;

assign or_in_vld = |in_vld;
assign or_in_dat = in_dat[ss_a];
assign in_rdy = {NS{or_in_rdy}} & ss;


//// output stream reg ////
stream_reg #(
  .DW   (DW) // data width
) str_reg (
  .clk      (clk        ),  // clock
  .clk_en   (clk_en     ),  // clock enable
  .rst      (rst        ),  // reset
  .in_vld   (or_in_vld  ),  // input valid
  .in_rdy   (or_in_rdy  ),  // input ack
  .in_dat   (or_in_dat  ),  // input data
  .out_vld  (out_vld    ),  // output valid
  .out_rdy  (out_rdy    ),  // output ack
  .out_dat  (out_dat    )   // output data
);


endmodule

