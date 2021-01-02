// ram_generic_dp.v
// A generic dual-port memory, single clock
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


module ram_generic_dp #(
  parameter MI = "",              // memory initialization file
  parameter DW = 8,               // data width
  parameter MD = 1024,            // memory depth
  parameter AW = $clog2(MD)       // address width
)(
  // system
  input  wire           a_clk,    // clock
  input  wire           a_clk_en  // clock enable
  // port a
  input  wire           a_we,     // write enable
  input  wire [ AW-1:0] a_adr,    // write address
  input  wire [ DW-1:0] a_dat_w,  // write data
  output reg  [ DW-1:0] a_dat_r,  // read data
  // port b
  input  wire           b_we,     // write enable
  input  wire [ AW-1:0] b_adr,    // write address
  input  wire [ DW-1:0] b_dat_w,  // write data
  output reg  [ DW-1:0] b_dat_r   // read data

);


//// memory ////
reg [DW-1:0] mem [0:MD-1];


//// memory initialization ////
initial begin
  if (MI == "") begin : MEM_FILL_BLK
/*    integer i;
    for (i=0; i<MD; i=i+1) mem[i] = i; */
  end else begin : MEM_LOAD_BLK
    $readmemh(MI, mem);
  end
end


//// port a ////
always @ (posedge clk_w) begin
  if (clk_en && a_we) mem[a_adr] <= #1 a_dat_w;
  a_dat_r <= #1 ram[a_adr];
end

//// port b ////
always @ (posedge clk_w) begin
  if (clk_en && b_we) mem[b_adr] <= #1 b_dat_w;
  b_dat_r <= #1 ram[b_adr];
end


endmodule

