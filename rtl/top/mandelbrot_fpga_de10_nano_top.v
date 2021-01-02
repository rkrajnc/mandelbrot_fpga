
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module mandelbrot_fpga_de10_nano(
  //////////// CLOCK //////////
  input                   FPGA_CLK1_50,
  input                   FPGA_CLK2_50,
  input                   FPGA_CLK3_50,
  //////////// HDMI //////////
  inout                   HDMI_I2C_SCL,
  inout                   HDMI_I2C_SDA,
  inout                   HDMI_I2S,
  inout                   HDMI_LRCLK,
  inout                   HDMI_MCLK,
  inout                   HDMI_SCLK,
  output                  HDMI_TX_CLK,
  output                  HDMI_TX_DE,
  output        [23:0]    HDMI_TX_D,
  output                  HDMI_TX_HS,
  output                  HDMI_TX_VS,
  input                   HDMI_TX_INT,
  //////////// KEY //////////
  input          [1:0]    KEY,
  //////////// LED //////////
  output         [7:0]    LED,
  //////////// SW //////////
  input          [3:0]    SW
);


//// PLLs reset ////
wire pll_rst;
assign pll_rst = !KEY[0];


//// system clock ////
localparam MAN_CLK = 200000000;
localparam SYS_CLK = 50000000;
localparam AUD_CLK = 1534526;

wire man_clk_en = 1'b1;
wire man_clk;
wire sys_clk_en = 1'b1;
wire sys_clk;
wire aud_clk_en = 1'b1;
wire aud_clk;
wire sys_pll_locked;

sys_pll sys_clock (
  .refclk     (FPGA_CLK1_50),   // refclk.clk
  .rst        (pll_rst),        // reset.reset
  .outclk_0   (man_clk),        // outclk0.clk
  .outclk_1   (sys_clk),        // outclk1.clk
  .outclk_2   (aud_clk),        // outclk2.clk
  .locked     (sys_pll_locked)  // locked.export
);


//// video clock ////
//localparam VGA_CLK = 25175644;
localparam VGA_CLK = 40000000;

wire vga_clk_en = 1'b1;
wire vga_clk;
wire vga_pll_locked;

vga_pll vga_clock (
  .refclk     (FPGA_CLK2_50),   // refclk.clk
  .rst        (pll_rst),        // reset.reset
  .outclk_0   (vga_clk),        // outclk0.clk
  .locked     (vga_pll_locked)  // locked.export
);


//// reset ////
localparam NCK = 4;
localparam RCV = 255;

wire            man_rst;
wire            sys_rst;
wire            aud_rst;
wire            vga_rst;

reset #(
  .NCK    (NCK),  // number of input clocks and reset outputs, min 1
  .RCV    (RCV)   // counter max value, min 1
) sys_reset (
  .clk      ({vga_clk,         aud_clk,         sys_clk,         man_clk}),
  .rst_in   (!vga_pll_locked || !sys_pll_locked),
  .rst_out  ({vga_rst,         aud_rst,         sys_rst,         man_rst})
);


//// blinky ////
localparam BLINKY_CLK = 1;

wire blinky_out;

blinky #(
  .SYS_CLK    (SYS_CLK),    // system clock in Hz
  .BLINKY_CLK (BLINKY_CLK)  // blinky clock in Hz
) blinky (
  .clk      (sys_clk),
  .clk_en   (sys_clk_en),
  .rst      (sys_rst),
  .out      (blinky_out)
);

assign LED[0] = blinky_out;


//// HDMI audio ////
localparam DISABLE_AUDIO = 1;

AUDIO_IF hdmi_audio (
  .clk      (aud_clk),
  .reset_n  (!aud_rst),
  .enable   (!DISABLE_AUDIO),
  .sclk     (HDMI_SCLK),
  .lrclk    (HDMI_LRCLK),
  .i2s      (HDMI_I2S)
);


//// HDMI config ////
I2C_HDMI_Config hdmi_config (
  .iCLK         (sys_clk),
  .iRST_N       (!sys_rst),
  .I2C_SCLK     (HDMI_I2C_SCL),
  .I2C_SDAT     (HDMI_I2C_SDA),
  .HDMI_TX_INT  (HDMI_TX_INT)
);


//// mandelbrot_fpga_top module ////
localparam VW = 8; // video components data width

wire vga_hsync;
wire vga_vsync;
wire vga_vld;
wire [8-1:0] vga_r;
wire [8-1:0] vga_g;
wire [8-1:0] vga_b;

mandelbrot_fpga_top mandelbrot_fpga_top (
  .man_clk      (man_clk    ),
  .man_clk_en   (man_clk_en ),
  .man_rst      (man_rst    ),
  .sys_clk      (sys_clk    ),
  .sys_clk_en   (sys_clk_en ),
  .sys_rst      (sys_rst    ),
  .vga_clk      (vga_clk    ),
  .vga_clk_en   (vga_clk_en ),
  .vga_rst      (vga_rst    ),
  .vga_hsync    (vga_hsync  ),
  .vga_vsync    (vga_vsync  ),
  .vga_vld      (vga_vld    ),
  .vga_r        (vga_r      ),
  .vga_g        (vga_g      ),
  .vga_b        (vga_b      )
);

assign HDMI_TX_CLK  = vga_clk;
assign HDMI_TX_DE   = vga_vld;
assign HDMI_TX_D    = {vga_r, vga_g, vga_b};
assign HDMI_TX_HS   = vga_hsync;
assign HDMI_TX_VS   = vga_vsync;


//// assign unused outputs ////
assign LED[7:3] = 'd0;


endmodule

