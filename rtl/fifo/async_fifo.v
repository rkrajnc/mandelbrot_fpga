/******************************************************************************/
/* async_fifo.v                                                               */
/* dual-clock async fifo with gray counters                                   */
/* http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf         */
/*                                                                            */
/* 2017, rok.krajnc@gmail.com                                                 */
/******************************************************************************/


module async_fifo #(
  parameter DW = 16,
  parameter FD = 32
)(
  // input
  input  wire           in_clk,
  input  wire           in_clk_en,
  input  wire           in_rst,
  input  wire           wr_en,
  input  wire [ DW-1:0] in,
  // output
  input  wire           out_clk,
  input  wire           out_clk_en,
  input  wire           out_rst,
  input  wire           rd_en,
  output wire [ DW-1:0] out,
  // status
  output reg            empty,
  output reg            full,
  output wire           half // TODO
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

// input
reg  [ FCW-1:0] in_rcnt1;
reg  [ FCW-1:0] in_rcnt2;
reg  [ FCW-1:0] wcnt_bin;
reg  [ FCW-1:0] wcnt_gray;
wire [ FCW-1:0] wcnt_bin_next;
wire [ FCW-1:0] wcnt_gray_next;
wire [ FPW-1:0] wp;

// output
reg  [ FCW-1:0] out_wcnt1;
reg  [ FCW-1:0] out_wcnt2;
reg  [ FCW-1:0] rcnt_gray;
reg  [ FCW-1:0] rcnt_bin;
wire [ FCW-1:0] rcnt_bin_next;
wire [ FCW-1:0] rcnt_gray_next;
wire [ FPW-1:0] rp;

// fifo memory
reg  [DW-1:0] mem [0:FD-1];


//// logic ////

// read gray counter sync to write clock domain
always @ (posedge in_clk, posedge in_rst) begin
  if (in_rst) begin
    in_rcnt1 <= #1 'd0;
    in_rcnt2 <= #1 'd0;
  end else if (in_clk_en) begin
    in_rcnt1 <= #1 rcnt_gray;
    in_rcnt2 <= #1 in_rcnt1;
  end
end

// write counters
assign wcnt_bin_next = wcnt_bin + (wr_en && !full);
assign wcnt_gray_next = {1'b0, wcnt_bin_next[FCW-1:1]} ^ wcnt_bin_next;

always @ (posedge in_clk, posedge in_rst) begin
  if (in_rst) begin
    wcnt_bin <= #1 'd0;
    wcnt_gray <= #1 'd0;
  end else if (in_clk_en) begin
    wcnt_bin <= #1 wcnt_bin_next;
    wcnt_gray <= #1 wcnt_gray_next;
  end
end

// write address
assign wp = wcnt_bin[FPW-1:0];

// full
always @ (posedge in_clk, posedge in_rst) begin
  if (in_rst)
    full <= #1 'd0;
  else if (in_clk_en)
    full <= #1 (wcnt_gray_next == {~in_rcnt2[FCW-1:FCW-2], in_rcnt2[FCW-3:0]});
end

// memory write
always @ (posedge in_clk) begin
  if (in_clk_en)
    if (wr_en && !full)
      mem[wp] <= #1 in;
end

// write gray counter sync to read clock domain
always @ (posedge out_clk, posedge out_rst) begin
  if (out_rst) begin
    out_wcnt1 <= #1 'd0;
    out_wcnt2 <= #1 'd0;
  end else if (out_clk_en) begin
    out_wcnt1 <= #1 wcnt_gray;
    out_wcnt2 <= #1 out_wcnt1;
  end
end

// read counters
assign rcnt_bin_next = rcnt_bin + (rd_en && !empty);
assign rcnt_gray_next = {1'b0, rcnt_bin_next[FCW-1:1]} ^ rcnt_bin_next;

always @ (posedge out_clk, posedge out_rst) begin
  if (out_rst) begin
    rcnt_bin <= #1 'd0;
    rcnt_gray <= #1 'd0;
  end else if (out_clk_en) begin
    rcnt_bin <= #1 rcnt_bin_next;
    rcnt_gray <= #1 rcnt_gray_next;
  end
end

// read address
assign rp = rcnt_bin[FPW-1:0];

// empty
always @ (posedge out_clk, posedge out_rst) begin
  if (out_rst)
    empty <= #1 'd1;
  else if (out_clk_en)
    empty <= #1 (rcnt_gray_next == out_wcnt2);
end

// memory read
assign out = mem[rp];


endmodule



/*
//
// Testbench
//
module async_fifo_tb();

parameter DW = 8;
parameter FD = 4;

integer i,j,k;
integer err = 0;

wire [DW-1:0] out;
wire full;
wire empty;
reg [DW-1:0] in;
reg wr_en, in_clk, in_rst;
reg rd_en, out_clk, out_rst;
reg in_clk_en = 1;
reg out_clk_en = 1;

// data buffers
reg [DW-1:0] dat_in[0:64-1];
reg [DW-1:0] dat_out[0:64-1];

// clock
initial begin
  in_clk = 1'b0;
  forever #11 in_clk = !in_clk;
end

initial begin
  out_clk = 1'b0;
  forever #13 out_clk = !out_clk;
end

// testbench
initial begin
  $display("ASYNC_FIFO_TB starting ...");
  for (i=0; i<64; i=i+1) dat_in[i] = i;//$urandom;

  fork
    // write block
    begin : in_blk
      wr_en = 1'b0;
      in_rst = 1'b1;
      repeat (2) @ (posedge in_clk); #1;
      in_rst = 1'b0;
      repeat (2) @ (posedge in_clk);
      for (j=0; j<32; j=j+1) begin
        in = dat_in[j];
        wr_en = 1'b1;
        @ (posedge in_clk); #1;
        if (full) begin
          wait (!full);
          @ (posedge in_clk); #1;
        end
      end
      wr_en = 1'b0;
      in = 'hx;
      @ (posedge in_clk); #1;
      for (j=32; j<64; j=j+1) begin
        in = dat_in[j];
        wr_en = 1'b1;
        @ (posedge in_clk) #1;
        if (full) begin
          wait (!full);
          @ (posedge in_clk); #1;
        end
        wr_en = 1'b0;
        in = 'hx;
        @ (posedge in_clk) #1;
      end
    end

    // read block
    begin : out_blk
      rd_en = 1'b0;
      out_rst = 1'b1;
      repeat (2) @ (posedge out_clk); #1;
      out_rst = 1'b0;
      repeat (2) @ (posedge out_clk); #1;
      repeat (6) @ (posedge out_clk); #1;
      for (k=0; k<16; k=k+1) begin
        rd_en = 1'b1;
        @ (posedge out_clk); #1;
        if (empty) begin
          wait (!empty);
          @ (posedge out_clk); #1;
        end
        dat_out[k] = out;
        rd_en = 1'b0;
        @ (posedge out_clk); #1;
      end
      rd_en = 1'b0;
      @ (posedge out_clk); #1;
      for (k=16; k<32; k=k+1) begin
        rd_en = 1'b1;
        @ (posedge out_clk); #1;
        if (empty) begin
          wait (!empty);
          @ (posedge out_clk); #1;
        end
        dat_out[k] = out;
      end
      rd_en = 1'b0;
      @ (posedge out_clk); #1;
      for (k=32; k<48; k=k+1) begin
        rd_en = 1'b1;
        @ (posedge out_clk); #1;
        if (empty) begin
          wait (!empty);
          @ (posedge out_clk); #1;
        end
        dat_out[k] = out;
        rd_en = 1'b0;
        @ (posedge out_clk); #1;
      end
      rd_en = 1'b0;
      @ (posedge out_clk); #1;
      for (k=48; k<64; k=k+1) begin
        rd_en = 1'b1;
        @ (posedge out_clk); #1;
        if (empty) begin
          wait (!empty);
          @ (posedge out_clk); #1;
        end
        dat_out[k] = out;
      end
      rd_en = 1'b0;
      @ (posedge out_clk); #1;
    end
  join
  repeat (10) @ (posedge in_clk); #1;

  // check
  for (i=0; i<64; i=i+1) if (dat_in[i] != dat_out[i]) begin
    $display("MISMATCH : in[%02d]  : %03d  out[%02d] : %03d", dat_in[i], i, dat_out[i], i);
    err = err + 1;
  end

  // finish
  $display("ASYNC_FIFO_TB finished ...");
  if (err) begin
    $display("TEST FAILED");
    $finish(-1);
  end else begin
    $display("TEST PASSED");
    $finish(0);
  end
end


// async_fifo
async_fifo #(
  .DW(DW),
  .FD(FD)
) dut (
  .in_clk     (in_clk),
  .in_clk_en  (1'b1),
  .in_rst     (in_rst),
  .wr_en      (wr_en),
  .in         (in),
  .out_clk    (out_clk),
  .out_clk_en (1'b1),
  .out_rst    (out_rst),
  .rd_en      (rd_en),
  .out        (out),
  .empty      (empty),
  .full       (full),
  .half       ()
);


// dump
integer d;
initial begin
  $dumpfile("out/wav/wav.fst");
  $dumpvars(0, async_fifo_tb);
  for (d = 0; d<FD; d=d+1) $dumpvars(0, dut.mem[d]);
end


endmodule
*/

