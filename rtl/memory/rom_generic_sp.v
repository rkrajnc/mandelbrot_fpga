// rom_generic_sp.v
// A generic single-port ROM
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


module rom_generic_sp #(
  parameter MI = "",              // memory initialization file, loaded with $readmemh
  parameter DW = 8,               // data width
  parameter MD = 1024,            // memory depth
  parameter AW = $clog2(MD)       // address width
)(
  // system
  input  wire           clk,      // clock
  input  wire           clk_en,   // clock enable
  // memory port
  input  wire           rd,       // read enable
  input  wire [ AW-1:0] adr,      // read address
  output wire [ DW-1:0] dat_r     // read data
);


//// memory ////
reg [DW-1:0] mem [0:MD-1];


//// load memory data ////
initial begin
  if (MI != "") $readmemh(MI, mem);
end


//// memory read ////
reg  [DW-1:0] mem_dat_r;

always @ (posedge clk, posedge rst) begin
  if (clk_en && rd)
    mem_dat_r <= #1 mem[adr];
end


//// output ////
assign dat_r = mem_dat_r;


endmodule

