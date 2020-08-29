// ram_generic_tp.v
// 2020, Rok Krajnc <rok.krajnc@gmail.com>
// A generic two-port memory


module ram_generic_tp #(
  parameter READ_REGISTERED = 1,  // when true, read port has an additional register
  parameter DW = 8,               // data width
  parameter MD = 1024,            // memory depth
  parameter AW = $clog2(MD)       // address width
)(
  // write side
  input  wire           clk_w,    // write clock
  input  wire           we,       // write enable
  input  wire [ AW-1:0] adr_w,    // write address
  input  wire [ DW-1:0] dat_w,    // write data
  // read side
  input  wire           clk_r,    // read clock
  input  wire           rd,       // read enable
  input  wire [ AW-1:0] adr_r,    // read address
  output wire [ DW-1:0] dat_r     // read data
);


//// memory ////
reg [DW-1:0] mem [0:MD-1];


//// memory write ////
always @ (posedge clk_w) begin
  if (we) mem[adr_w] <= #1 dat_w;
end


//// memory read ////
reg  [DW-1:0] mem_dat_r;
always @ (posedge clk_r) begin
  if (rd) mem_dat_r <= #1 mem[adr_r];
end


//// output register ////
generate if (READ_REGISTERED) begin : BLK_OUTPUT_REG
  reg [DW-1:0] mem_dat_r_d;
  always @ (posedge clk_r) begin
    mem_dat_r_d <= #1 mem_dat_r;
  end

  assign dat_r = mem_dat_r_d;
end else begin : BLK_NO_OUTPUT_REG
  assign dat_r = mem_dat_r;
end endgenerate


endmodule

