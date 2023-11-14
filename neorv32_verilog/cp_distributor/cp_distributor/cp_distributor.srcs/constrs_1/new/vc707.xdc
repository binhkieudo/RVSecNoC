set_property -dict { PACKAGE_PIN E19    IOSTANDARD LVCMOS33 } [get_ports { i_clk }]; #IO_L12P_T1_MRCC_35 Sch=gclk[100]
create_clock -add -name sys_clk_pin -period 5.00 -waveform {0 2.5} [get_ports { i_clk }];