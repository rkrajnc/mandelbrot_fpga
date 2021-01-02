////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Copyright 2010, Iztok Jeras (iztok.jeras@gmail.com)                        //
// Copyright 2016, Rok Krajnc (rok.krajnc@gmail.com)                          //
//                                                                            //
// This file is part of qSoC                                                  //
//                                                                            //
// qSoC is free software; you can redistribute it and/or modify               //
// it under the terms of the GNU General Public License as published by       //
// the Free Software Foundation; either version 3 of the License, or          //
// (at your option) any later version.                                        //
//                                                                            //
// Minimig is distributed in the hope that it will be useful,                 //
// but WITHOUT ANY WARRANTY; without even the implied warranty of             //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              //
// GNU General Public License for more details.                               //
//                                                                            //
// You should have received a copy of the GNU General Public License          //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// qmem_arbiter.v                                                             //
// QMEM bus arbiter allows multiple masters access to a single slave          //
// Masters priority decreases from the LSB to the MSB side                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


module qmem_arbiter #(
  parameter QAW = 32,                     // address width
  parameter QDW = 32,                     // data width
  parameter QSW = QDW/8,                  // byte select width
  parameter MN  = 2                       // number of masters
)(
  // system
  input  wire                   clk,      // clock
  input  wire                   rst,      // reset
  // slave port (masters connect here)
  input  wire [MN-1:0]          qm_cs,    // chip-select
  input  wire [MN-1:0]          qm_we,    // write enable
  input  wire [MN-1:0][QSW-1:0] qm_sel,   // byte select
  input  wire [MN-1:0][QAW-1:0] qm_adr,   // address
  input  wire [MN-1:0][QDW-1:0] qm_dat_w, // write data
  output wire [MN-1:0][QDW-1:0] qm_dat_r, // read data
  output wire [MN-1:0]          qm_ack,   // acknowledge
  output wire [MN-1:0]          qm_err,   // error
  // master port (slaves connect here)
  output wire                   qs_cs,    // chip-select
  output wire                   qs_we,    // write enable
  output wire         [QSW-1:0] qs_sel,   // byte select
  output wire         [QAW-1:0] qs_adr,   // address
  output wire         [QDW-1:0] qs_dat_w, // write data
  input  wire         [QDW-1:0] qs_dat_r, // read data
  input  wire                   qs_ack,   // acknowledge
  input  wire                   qs_err,   // error
  // one hot master status (bit MN is always 1'b0)
  output wire [MN-1:0]          ms        // selected master
);


//// log2 function ////
function integer clogb2;
  input [31:0] value;
  integer  i;
begin
  clogb2 = 0;
  for(i = 0; 2**i < value; i = i + 1) clogb2 = i + 1;
end
endfunction


//// master priority encoder & one-hot to address decoder ////
localparam MNLOG = clogb2(MN);
genvar i,j;
wire  [   MN-1:0] ms_tmp;
reg   [   MN-1:0] ms_reg;
wire  [MNLOG-1:0] ms_a;

assign ms_tmp[0] = qm_cs[0];
generate for (i=1; i<MN; i=i+1) begin : MS_TMP_L
  assign ms_tmp[i] = qm_cs[i] & ~|qm_cs[i-1:0];
end endgenerate

always @ (posedge clk, posedge rst) begin
  if (rst)                   ms_reg <= #1 0;
  else if (qs_ack | qs_err)  ms_reg <= #1 0;
  else if (!(|ms_reg))       ms_reg <= #1 ms_tmp;
end

assign ms = |ms_reg ? ms_reg : ms_tmp;

generate
  for (j=0; j<MNLOG; j=j+1) begin : MS_MASK_OL
    wire [MN-1:0] ms_msk;
    for (i=0; i<MN; i=i+1) begin : MS_MASK_IL
      assign ms_msk[i] = i[j];
    end
    assign ms_a[j] = |(ms & ms_msk);
  end
endgenerate


//// master port assigns ////
assign qs_cs    = qm_cs     [ms_a];
assign qs_we    = qm_we     [ms_a];
assign qs_sel   = qm_sel    [ms_a];
assign qs_adr   = qm_adr    [ms_a];
assign qs_dat_w = qm_dat_w  [ms_a];


//// slave port assigns ////
assign qm_dat_r =      {MN{qs_dat_r}};
assign qm_ack   = ms & {MN{qs_ack}};
assign qm_err   = ms & {MN{qs_err}};


endmodule

