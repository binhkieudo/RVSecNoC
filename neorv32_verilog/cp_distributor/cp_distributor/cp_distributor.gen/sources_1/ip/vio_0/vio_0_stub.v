// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Wed Nov 15 03:28:01 2023
// Host        : binhkieudo-hotswap running 64-bit Ubuntu 20.04.6 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/binhkieudo/Workspace/RVSecNoC/neorv32_verilog/cp_distributor/cp_distributor/cp_distributor.gen/sources_1/ip/vio_0/vio_0_stub.v
// Design      : vio_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2022.2" *)
module vio_0(clk, probe_in0, probe_in1, probe_in2, probe_in3, 
  probe_in4, probe_in5, probe_in6, probe_out0, probe_out1, probe_out2, probe_out3, probe_out4, 
  probe_out5, probe_out6)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[7:0],probe_in1[1:0],probe_in2[1:0],probe_in3[5:0],probe_in4[9:0],probe_in5[63:0],probe_in6[63:0],probe_out0[3:0],probe_out1[3:0],probe_out2[11:0],probe_out3[19:0],probe_out4[127:0],probe_out5[127:0],probe_out6[1:0]" */;
  input clk;
  input [7:0]probe_in0;
  input [1:0]probe_in1;
  input [1:0]probe_in2;
  input [5:0]probe_in3;
  input [9:0]probe_in4;
  input [63:0]probe_in5;
  input [63:0]probe_in6;
  output [3:0]probe_out0;
  output [3:0]probe_out1;
  output [11:0]probe_out2;
  output [19:0]probe_out3;
  output [127:0]probe_out4;
  output [127:0]probe_out5;
  output [1:0]probe_out6;
endmodule
