// ctrl_bus.v
// QMEM interconnect
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


//// slave address map ////
// 0 - (0x00000000 - 0x00001fff) adr[12] == 1'b0 - FPGA RAM (8k)
// 1 - (0x00002000 - 0x00002fff) adr[12] == 1'b1 - REGS (8k)


module ctrl_bus #(
  parameter MAW = 13,             // master address width
  parameter SAW = 12,             // slave address width
  parameter QDW = 32,             // data width
  parameter QSW = QDW/8           // select width
)(
  // system
  input  wire           clk,
  input  wire           rst,
  // master 0 (dcpu)
  input  wire [MAW-1:0] m0_adr,
  input  wire           m0_cs,
  input  wire           m0_we,
  input  wire [QSW-1:0] m0_sel,
  input  wire [QDW-1:0] m0_dat_w,
  output wire [QDW-1:0] m0_dat_r,
  output wire           m0_ack,
  output wire           m0_err,
  // slave 0 (ram)
  output wire [SAW-1:0] s0_adr,
  output wire           s0_cs,
  output wire           s0_we,
  output wire [QSW-1:0] s0_sel,
  output wire [QDW-1:0] s0_dat_w,
  input  wire [QDW-1:0] s0_dat_r,
  input  wire           s0_ack,
  input  wire           s0_err,
  // slave 1 (regs)
  output wire [SAW-1:0] s1_adr,
  output wire           s1_cs,
  output wire           s1_we,
  output wire [QSW-1:0] s1_sel,
  output wire [QDW-1:0] s1_dat_w,
  input  wire [QDW-1:0] s1_dat_r,
  input  wire           s1_ack,
  input  wire           s1_err
);


// no. of masters
localparam MN = 1;

// no. of slaves
localparam SN = 2;



//// MASTERS ////

////////////////////////////////////////
// Master 0 (dcpu)                    //
// connects to: s0 (fram)             //
//              s1 (regs)             //
////////////////////////////////////////
wire [MAW-1:0] m0_s0_adr   , m0_s1_adr   ;
wire           m0_s0_cs    , m0_s1_cs    ;
wire           m0_s0_we    , m0_s1_we    ;
wire [QSW-1:0] m0_s0_sel   , m0_s1_sel   ;
wire [QDW-1:0] m0_s0_dat_w , m0_s1_dat_w ;
wire [QDW-1:0] m0_s0_dat_r , m0_s1_dat_r ;
wire           m0_s0_ack   , m0_s1_ack   ;
wire           m0_s0_err   , m0_s1_err   ;

localparam M0_SN = 2;
wire [M0_SN-1:0] m0_ss;

assign m0_ss[0] = (m0_adr[13] == 1'b0);
assign m0_ss[1] = (m0_adr[13] == 1'b1);

// m0 decoder
qmem_decoder #(
  .QAW    (MAW),
  .QDW    (QDW),
  .QSW    (QSW),
  .SN     (M0_SN)
) m0_decoder (
  // system
  .clk      (clk),
  .rst      (rst),
  // slave port for requests from masters
  .qm_cs    (m0_cs),
  .qm_we    (m0_we),
  .qm_sel   (m0_sel),
  .qm_adr   (m0_adr),
  .qm_dat_w (m0_dat_w),
  .qm_dat_r (m0_dat_r),
  .qm_ack   (m0_ack),
  .qm_err   (m0_err),
  // master port for requests to a slave
  .qs_cs    ({m0_s1_cs   , m0_s0_cs   }),
  .qs_we    ({m0_s1_we   , m0_s0_we   }),
  .qs_sel   ({m0_s1_sel  , m0_s0_sel  }),
  .qs_adr   ({m0_s1_adr  , m0_s0_adr  }),
  .qs_dat_w ({m0_s1_dat_w, m0_s0_dat_w}),
  .qs_dat_r ({m0_s1_dat_r, m0_s0_dat_r}),
  .qs_ack   ({m0_s1_ack  , m0_s0_ack  }),
  .qs_err   ({m0_s1_err  , m0_s0_err  }),
  // one hot slave select signal
  .ss       (m0_ss)
);

 

//// SLAVES ////

////////////////////////////////////////
// Slave 0 (ram)                      //
// masters:     m0 (dcpu)             //
////////////////////////////////////////

assign s0_adr       = m0_s0_adr[SAW-1:0];
assign s0_cs        = m0_s0_cs;
assign s0_we        = m0_s0_we;
assign s0_sel       = m0_s0_sel;
assign s0_dat_w     = m0_s0_dat_w;
assign m0_s0_dat_r  = s0_dat_r;
assign m0_s0_ack    = s0_ack;
assign m0_s0_err    = s0_err;


////////////////////////////////////////
// Slave 1 (regs)                     //
// masters:     m0 (dcpu)             //
////////////////////////////////////////

assign s1_adr       = m0_s1_adr[SAW-1:0];
assign s1_cs        = m0_s1_cs;
assign s1_we        = m0_s1_we;
assign s1_sel       = m0_s1_sel;
assign s1_dat_w     = m0_s1_dat_w;
assign m0_s1_dat_r  = s1_dat_r;
assign m0_s1_ack    = s1_ack;
assign m0_s1_err    = s1_err;



endmodule

