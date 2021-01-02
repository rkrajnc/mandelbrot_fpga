// ram_generic_dp_bs.v
// A generic dual-port memory with byte selects, single clock
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


module ram_generic_dp_bs #(
  parameter MI = "",              // memory initialization file
  parameter DW = 8,               // data width
  parameter SW = DW/8,            // byte select width
  parameter MD = 1024,            // memory depth
  parameter AW = $clog2(MD)       // address width
)(
  // system
  input  wire           clk,      // clock
  input  wire           clk_en,   // clock enable
  // port a
  input  wire           a_we,     // write enable
  input  wire [ AW-1:0] a_adr,    // write address
  input  wire [ SW-1:0] a_sel,    // byte select
  input  wire [ DW-1:0] a_dat_w,  // write data
  output reg  [ DW-1:0] a_dat_r,  // read data
  // port b
  input  wire           b_we,     // write enable
  input  wire [ AW-1:0] b_adr,    // write address
  input  wire [ SW-1:0] b_sel,    // byte select
  input  wire [ DW-1:0] b_dat_w,  // write data
  output reg  [ DW-1:0] b_dat_r   // read data
);


//// memory ////
reg [DW-1:0] mem [0:MD-1];


//// memory initialization ////
initial begin
  if (MI != "") begin : MEM_READ_BLK
    $readmemh(MI, mem);
  end
end


//// port a ////
integer a;
integer b;
always @ (posedge clk) begin
  if (clk_en) begin
    for (a=0; a<SW; a=a+1) begin
      if (a_we && a_sel[a]) mem[a_adr][a*8 +: 8] <= #1 a_dat_w[a*8 +: 8];
    end
    for (b=0; b<SW; b=b+1) begin
      if (b_we && b_sel[b]) mem[b_adr][b*8 +: 8] <= #1 b_dat_w[b*8 +: 8];
    end
    a_dat_r <= #1 mem[a_adr];
    b_dat_r <= #1 mem[b_adr];
  end
end


endmodule

