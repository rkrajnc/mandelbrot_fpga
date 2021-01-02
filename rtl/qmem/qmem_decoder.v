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
// qmem_decoder.v                                                             //
// QMEM bus decoder allows a master to access multiple slaves                 //
// the ss input is external (usually address-based) one-hot slave encoder     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


module qmem_decoder #(
  parameter QAW = 32,                     // address width
  parameter QDW = 32,                     // data width
  parameter QSW = QDW/8,                  // byte select width
  parameter SN  = 2                       // number of slaves
)(
  // system
  input  wire                   clk,      // clock
  input  wire                   rst,      // reset
  // slave port (masters connect here)
  input  wire                   qm_cs,    // chip-select
  input  wire                   qm_we,    // write enable
  input  wire         [QSW-1:0] qm_sel,   // byte select
  input  wire         [QAW-1:0] qm_adr,   // address
  input  wire         [QDW-1:0] qm_dat_w, // write data
  output wire         [QDW-1:0] qm_dat_r, // read data
  output wire                   qm_ack,   // acknowledge
  output wire                   qm_err,   // error
  // master port (slaves connect here)
  output wire [SN-1:0]          qs_cs,    // chip-select
  output wire [SN-1:0]          qs_we,    // write enable
  output wire [SN-1:0][QSW-1:0] qs_sel,   // byte select
  output wire [SN-1:0][QAW-1:0] qs_adr,   // address
  output wire [SN-1:0][QDW-1:0] qs_dat_w, // write data
  input  wire [SN-1:0][QDW-1:0] qs_dat_r, // read data
  input  wire [SN-1:0]          qs_ack,   // acknowledge
  input  wire [SN-1:0]          qs_err,   // error
  // one hot slave select signal
  input  wire [SN-1:0]          ss        // selected slave
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


//// slave select encoder & one-hot to address decoder ////
localparam SNLOG = clogb2(SN);
genvar i,j;
wire [SNLOG-1:0] ss_a;
reg  [SNLOG-1:0] ss_r;

generate
  for (j=0; j<SNLOG; j=j+1) begin : SS_MASK_OL
    wire [SN-1:0] ss_msk;
    for (i=0; i<SN; i=i+1) begin : SS_MASK_IL
      assign ss_msk[i] = i[j];
    end
    assign ss_a[j] = |(ss & ss_msk);
  end
endgenerate

always @ (posedge clk, posedge rst) begin
  if (rst)                                      ss_r <= #1 0;
  else if (qm_cs & (qm_ack | qm_err) & ~qm_we)  ss_r <= #1 ss_a;
end


//// master port assigns ////
assign qs_cs    = ss & {SN{qm_cs}};
assign qs_we    =      {SN{qm_we}};
assign qs_sel   =      {SN{qm_sel}};
assign qs_adr   =      {SN{qm_adr}};
assign qs_dat_w =      {SN{qm_dat_w}};


//// slave port assigns ////
assign qm_dat_r = qs_dat_r  [ss_r];
assign qm_ack   = qs_ack    [ss_a];
assign qm_err   = qs_err    [ss_a];


endmodule

