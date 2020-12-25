/********************************************/
/* sync_fifo.v                              */
/* simple single-clock fifo                 */
/*                                          */
/* 2011, rok.krajnc@gmail.com               */
/********************************************/


module sync_fifo #(
  parameter FD    = 16,         // fifo depth
  parameter DW    = 32          // data width
)(
  // system
  input  wire           clk,    // clock
  input  wire           clk_en, // clock enable
  input  wire           rst,    // reset
  input  wire           en,     // enable (if !en, reset fifo)
  // fifo input / output
  input  wire [ DW-1:0] in,     // write data
  output wire [ DW-1:0] out,    // read data
  // fifo control
  input  wire           wr_en,  // fifo write enable
  input  wire           rd_en,  // fifo read enable
  // fifo status
  output wire           full,   // fifo full
  output wire           empty,  // fifo empty
  output wire           half    // fifo is less than half full
);


//// log function ////
function integer clog2; 
  input integer value; 
begin 
  value = value-1; 
  for (clog2=0; value>0; clog2=clog2+1) value = value>>1; 
end 
endfunction 


//// local parameters ////
localparam FCW = clog2(FD) + 1;
localparam FPW = clog2(FD);


//// local signals ////
// fifo counter
reg  [FCW-1:0] cnt;

// fifo write & read pointers
reg  [FPW-1:0] wp, rp;

// fifo memory
(* ramstyle = "logic" *) reg  [ DW-1:0] mem [0:FD-1];


//// logic ////

// FIFO write pointer
always @ (posedge clk or posedge rst) begin
  if (rst)
    wp <= #1 1'b0;
  else if (clk_en) begin
    if (wr_en && !full)
      wp <= #1 wp + 1'b1;
  end
end

// FIFO write
always @ (posedge clk) begin
  if (clk_en) begin
    if (wr_en && !full) mem[wp] <= #1 in;
  end
end

// FIFO counter
always @ (posedge clk or posedge rst) begin
  if (rst)
    cnt <= #1 'd0;
  // read & no write
  else if (clk_en) begin
    if (rd_en && !wr_en && (cnt != 'd0))
      cnt <= #1 cnt - 'd1;
    // write & no read
    else if (wr_en && !rd_en && (cnt != FD))
      cnt <= #1 cnt + 'd1;
  end
end

// FIFO full & empty
assign full  = (cnt == (FD));
assign empty = (cnt == 'd0);
assign half  = (cnt <= (FD/2));

// FIFO read pointer
always @ (posedge clk or posedge rst) begin
  if (rst)
    rp <= #1 1'b0;
  else if (clk_en) begin
    if (rd_en && !empty)
      rp <= #1 rp + 1'b1;
  end
end

// FIFO read
assign out = mem[rp];


endmodule

