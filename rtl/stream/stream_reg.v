// stream_reg.v
// register for stream
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


module stream_reg #(
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
  output wire           out_vld,  // output valid
  input  wire           out_rdy,  // output ack
  output reg  [ DW-1:0] out_dat   // output data
);


//// input / output transfers
wire in_trn;
wire out_trn;

assign in_trn  = in_vld && in_rdy;
assign out_trn = out_vld && out_rdy;


//// full marker ////
reg full;

always @ ( posedge clk, posedge rst) begin
  if (rst) begin
    full    <= #1 1'b0;
  end else if (clk_en) begin
    if (in_trn)
      full <= #1 1'b1;
    else if (out_trn)
      full <= #1 1'b0;
  end
end


//// data reg ////
always @ (posedge clk) begin
  if (clk_en) begin
    if (in_trn) begin
      out_dat <= #1 in_dat;
    end
  end
end


//// assign stream outputs
assign in_rdy  = !full;
assign out_vld = full;


endmodule

