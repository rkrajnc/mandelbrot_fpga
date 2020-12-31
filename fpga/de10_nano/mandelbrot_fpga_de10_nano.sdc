
# time information
set_time_format -unit ns -decimal_places 3

# create clocks
create_clock -period "50.0 MHz" [get_ports FPGA_CLK1_50]
create_clock -period "50.0 MHz" [get_ports FPGA_CLK2_50]
create_clock -period "50.0 MHz" [get_ports FPGA_CLK3_50]

# pll clocks
derive_pll_clocks

# generated clocks

# clock uncertainty
derive_clock_uncertainty

# named clocks
set vga_clk "vga_clock|vga_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk"
set man_clk "sys_clock|sys_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk"
set sys_clk "sys_clock|sys_pll_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk"
set aud_clk "sys_clock|sys_pll_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk"

# clock groups
set_clock_groups -asynchronous -group [get_clocks {vga_clock|vga_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -group [get_clocks {sys_clock|sys_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk sys_clock|sys_pll_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk sys_clock|sys_pll_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}]

# CDC for async fifo
set_net_delay -from [get_registers {mandelbrot_fpga_top:mandelbrot_fpga_top|async_fifo:mandelbrot_fifo|rcnt_gray[*]}] -to [get_registers {mandelbrot_fpga_top:mandelbrot_fpga_top|async_fifo:mandelbrot_fifo|in_rcnt2[*]}] -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
set_net_delay -from [get_registers {mandelbrot_fpga_top:mandelbrot_fpga_top|async_fifo:mandelbrot_fifo|wcnt_gray[*]}] -to [get_registers {mandelbrot_fpga_top:mandelbrot_fpga_top|async_fifo:mandelbrot_fifo|out_wcnt2[*]}] -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
set_max_skew -from [get_keepers {mandelbrot_fpga_top:mandelbrot_fpga_top|async_fifo:mandelbrot_fifo|rcnt_gray[*]}] -to [get_keepers {mandelbrot_fpga_top:mandelbrot_fpga_top|async_fifo:mandelbrot_fifo|in_rcnt2[*]}] -get_skew_value_from_clock_period min_clock_period -skew_value_multiplier 0.8
set_max_skew -from [get_keepers {mandelbrot_fpga_top:mandelbrot_fpga_top|async_fifo:mandelbrot_fifo|wcnt_gray[*]}] -to [get_keepers {mandelbrot_fpga_top:mandelbrot_fpga_top|async_fifo:mandelbrot_fifo|out_wcnt2[*]}] -get_skew_value_from_clock_period min_clock_period -skew_value_multiplier 0.8

# JTAG
set jtag_ports [get_ports -nowarn {altera_reserved_tck}]
if {[get_collection_size $jtag_ports] == 1} {
  create_clock -name tck -period 40.000 [get_ports {altera_reserved_tck}]
  set_clock_groups -exclusive -group altera_reserved_tck
  set_output_delay -clock tck 3             [get_ports altera_reserved_tdo]
  set_input_delay  -clock tck -clock_fall 3 [get_ports altera_reserved_tdi]
  set_input_delay  -clock tck -clock_fall 3 [get_ports altera_reserved_tms]
  #set_false_path -from *                               -to [get_ports altera_reserved_tdo]
  #set_false_path -from [get_ports altera_reserved_tms] -to *
  #set_false_path -from [get_ports altera_reserved_tdi] -to *
}
