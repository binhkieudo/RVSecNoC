// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Wed Nov 15 03:11:34 2023
// Host        : binhkieudo-hotswap running 64-bit Ubuntu 20.04.6 LTS
// Command     : write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ vio_0_stub.v
// Design      : vio_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2022.2" *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(clk, probe_in0, probe_in1, probe_in2, probe_in3, 
  probe_in4, probe_in5, probe_in6, probe_out0, probe_out1, probe_out2, probe_out3, probe_out4, 
  probe_out5, probe_out6)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[31:0],probe_in1[3:0],probe_in2[3:0],probe_in3[11:0],probe_in4[19:0],probe_in5[127:0],probe_in6[127:0],probe_out0[7:0],probe_out1[7:0],probe_out2[23:0],probe_out3[39:0],probe_out4[255:0],probe_out5[255:0],probe_out6[3:0]" */;
  input clk;
  input [31:0]probe_in0;
  input [3:0]probe_in1;
  input [3:0]probe_in2;
  input [11:0]probe_in3;
  input [19:0]probe_in4;
  input [127:0]probe_in5;
  input [127:0]probe_in6;
  output [7:0]probe_out0;
  output [7:0]probe_out1;
  output [23:0]probe_out2;
  output [39:0]probe_out3;
  output [255:0]probe_out4;
  output [255:0]probe_out5;
  output [3:0]probe_out6;
endmodule
