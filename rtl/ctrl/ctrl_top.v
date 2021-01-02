// ctrl_top.v
// top-level control module
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


module ctrl_top #(
  parameter MI  = "",   // memory initialization file
  parameter FPW = 2*27  // fixed-point width
)(
  // system
  input  wire           clk,
  input  wire           rst,
  // registers
  output wire           man_init,
  input  wire           man_done,
  output wire [FPW-1:0] man_x0,
  output wire [FPW-1:0] man_y0,
  output wire [FPW-1:0] man_xs,
  output wire [FPW-1:0] man_ys
);


//// local parameters ////
localparam MAW = 14;
localparam SAW = 13;
localparam QSW = 4;
localparam QDW = 32;


//// ctrl bus ////
// cpu bus
wire           dcpu_cs;
wire           dcpu_we;
wire [QSW-1:0] dcpu_sel;
wire [MAW-1:0] dcpu_adr;
wire [QDW-1:0] dcpu_dat_w;
wire [QDW-1:0] dcpu_dat_r;
wire           dcpu_ack;
wire           dcpu_err;
wire           icpu_cs;
wire           icpu_we;
wire [QSW-1:0] icpu_sel;
wire [MAW-1:0] icpu_adr;
wire [QDW-1:0] icpu_dat_w;
wire [QDW-1:0] icpu_dat_r;
wire           icpu_ack;
wire           icpu_err;
// ram bus
wire           ram_cs;
wire           ram_we;
wire [QSW-1:0] ram_sel;
wire [SAW-1:0] ram_adr;
wire [QDW-1:0] ram_dat_w;
wire [QDW-1:0] ram_dat_r;
wire           ram_ack;
wire           ram_err;
// regs bus
wire           regs_cs;
wire           regs_we;
wire [QSW-1:0] regs_sel;
wire [SAW-1:0] regs_adr;
wire [QDW-1:0] regs_dat_w;
wire [QDW-1:0] regs_dat_r;
wire           regs_ack;
wire           regs_err;

ctrl_bus #(
  .MAW  (MAW),                // master address width
  .SAW  (SAW),                // slave address width
  .QDW  (QDW),                // data width
  .QSW  (QSW)                 // select width
) bus (
  // system
  .clk        (clk        ),
  .rst        (rst        ),
  // master 0 (dcpu)
  .m0_adr     (dcpu_adr   ),
  .m0_cs      (dcpu_cs    ),
  .m0_we      (dcpu_we    ),
  .m0_sel     (dcpu_sel   ),
  .m0_dat_w   (dcpu_dat_w ),
  .m0_dat_r   (dcpu_dat_r ),
  .m0_ack     (dcpu_ack   ),
  .m0_err     (dcpu_err   ),
  // slave 0 (ram)
  .s0_adr     (ram_adr    ),
  .s0_cs      (ram_cs     ),
  .s0_we      (ram_we     ),
  .s0_sel     (ram_sel    ),
  .s0_dat_w   (ram_dat_w  ),
  .s0_dat_r   (ram_dat_r  ),
  .s0_ack     (ram_ack    ),
  .s0_err     (ram_err    ),
  // slave 1 (regs)
  .s1_adr     (regs_adr   ),
  .s1_cs      (regs_cs    ),
  .s1_we      (regs_we    ),
  .s1_sel     (regs_sel   ),
  .s1_dat_w   (regs_dat_w ),
  .s1_dat_r   (regs_dat_r ),
  .s1_ack     (regs_ack   ),
  .s1_err     (regs_err   )
);


//// or1200 cpu ////
or1200_top_wrapper #(
  .AW   (MAW)
) cpu (
  // system
  .clk        (clk        ),
  .rst        (rst        ),
  // data bus
  .dcpu_adr   (dcpu_adr   ),
  .dcpu_cs    (dcpu_cs    ),
  .dcpu_we    (dcpu_we    ),
  .dcpu_sel   (dcpu_sel   ),
  .dcpu_dat_w (dcpu_dat_w ),
  .dcpu_dat_r (dcpu_dat_r ),
  .dcpu_ack   (dcpu_ack   ),
  // instruction bus
  .icpu_adr   (icpu_adr   ),
  .icpu_cs    (icpu_cs    ),
  .icpu_we    (icpu_we    ),
  .icpu_sel   (icpu_sel   ),
  .icpu_dat_w (icpu_dat_w ),
  .icpu_dat_r (icpu_dat_r ),
  .icpu_ack   (icpu_ack   )
);


//// regs ////
ctrl_regs #(
  .QAW  (SAW),
  .QDW  (QDW),
  .QSW  (QSW),
  .FPW  (FPW)
) regs (
  .clk      (clk        ),
  .rst      (rst        ),
  .adr      (regs_adr   ),
  .cs       (regs_cs    ),
  .we       (regs_we    ),
  .sel      (regs_sel   ),
  .dat_w    (regs_dat_w ),
  .dat_r    (regs_dat_r ),
  .ack      (regs_ack   ),
  .err      (regs_err   ),
  .man_done (man_done   ),
  .man_init (man_init   ),
  .man_x0   (man_x0     ),
  .man_y0   (man_y0     ),
  .man_xs   (man_xs     ),
  .man_ys   (man_ys     )
);


//// ram ////
localparam MD = 2048;

`ifdef SOC_SIM

wire clk_en = 1'b1;

ram_generic_dp_bs #(
  .MI   (MI   ),  // memory initialization file
  .DW   (QDW  ),  // data width
  .SW   (QSW  ),  // byte select width
  .MD   (MD   ),  // memory depth
  .AW   (SAW-2)   // address width
) ram (
  .clk      (clk              ),  // clock
  .clk_en   (clk_en           ),  // clock enable
  .a_we     (icpu_we          ),  // write enable
  .a_adr    (icpu_adr[SAW-1:2]),  // write address
  .a_sel    (icpu_sel         ),  // byte select
  .a_dat_w  (icpu_dat_w       ),  // write data
  .a_dat_r  (icpu_dat_r       ),  // read data
  .b_we     (ram_we           ),  // write enable
  .b_adr    (ram_adr[SAW-1:2] ),  // write address
  .b_sel    (ram_sel          ),  // byte select
  .b_dat_w  (ram_dat_w        ),  // write data
  .b_dat_r  (ram_dat_r        )   // read data
);

`else

cyclonev_ram_2kx32_dp_bs ram (
	.clock      (clk              ),
	.wren_a     (icpu_we          ),
	.address_a  (icpu_adr[SAW-1:2]),
	.byteena_a  (icpu_sel         ),
	.data_a     (icpu_dat_w       ),
	.q_a        (icpu_dat_r       ),
	.wren_b     (ram_we           ),
	.address_b  (ram_adr[SAW-1:2] ),
	.byteena_b  (ram_sel          ),
	.data_b     (ram_dat_w        ),
	.q_b        (ram_dat_r        )
);

`endif


assign icpu_ack = 1'b1;
assign ram_ack  = 1'b1;
assign ram_err  = 1'b0;


endmodule

