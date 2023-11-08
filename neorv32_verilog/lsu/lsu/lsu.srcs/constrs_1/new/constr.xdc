set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS18 } [get_ports { i_clk }];
create_clock -add -name sys_clk_pin -period 4.00 -waveform {0 2} [get_ports { i_clk }];