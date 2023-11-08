// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Thu Nov  9 02:58:34 2023
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
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(clk, probe_in0, probe_in1, probe_in2, probe_out0, 
  probe_out1, probe_out2, probe_out3, probe_out4, probe_out5, probe_out6)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[7:0],probe_in1[255:0],probe_in2[7:0],probe_out0[0:0],probe_out1[20:0],probe_out2[255:0],probe_out3[7:0],probe_out4[255:0],probe_out5[255:0],probe_out6[7:0]" */;
  input clk;
  input [7:0]probe_in0;
  input [255:0]probe_in1;
  input [7:0]probe_in2;
  output [0:0]probe_out0;
  output [20:0]probe_out1;
  output [255:0]probe_out2;
  output [7:0]probe_out3;
  output [255:0]probe_out4;
  output [255:0]probe_out5;
  output [7:0]probe_out6;
endmodule
