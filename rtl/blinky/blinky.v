// blinky.v
// Simple LED blinker
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


module blinky #(
  parameter SYS_CLK     = 50000000, // system clock in Hz
  parameter BLINKY_CLK  = 1         // blinky clock in Hz
)(
  input  wire clk,                  // clock
  input  wire clk_en,               // clock enable
  input  wire rst,                  // reset
  output wire out                   // blinky output
);


//// local parameters ////
localparam real SYS_CLK_F = SYS_CLK;
localparam real BLINKY_CLK_F = BLINKY_CLK;
localparam real BLINKY_CNT_F = SYS_CLK_F / BLINKY_CLK_F;
localparam integer BLINKY_CNT = BLINKY_CNT_F;
localparam integer BW = $clog2(BLINKY_CNT);


//// blinky counter and register ////
reg  [BW-1:0] blinky_cnt;
reg           blinky_r;

always @ (posedge clk, posedge rst) begin
  if (rst) begin
    blinky_cnt <= #1 {BW{1'b0}};
    blinky_r   <= #1 1'b0;
  end else begin
    blinky_cnt <= #1 (blinky_cnt == BLINKY_CNT) ? {BW{1'b0}} : blinky_cnt + { {(BW-1){1'b0}}, 1'b1 };
    blinky_r   <= #1 ~|blinky_cnt ? ~blinky_r : blinky_r;
  end
end


//// outputs ////
assign out = blinky_r;


endmodule

