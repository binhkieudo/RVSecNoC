// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Tue Nov 14 14:10:15 2023
// Host        : binhkieudo running 64-bit Ubuntu 20.04.6 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/binhkieudo/Workspace/RISC-V/RVSecNoC/neorv32_verilog/shifter/project_1/project_1.gen/sources_1/ip/vio_0/vio_0_stub.v
// Design      : vio_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2022.2" *)
module vio_0(clk, probe_in0, probe_in1, probe_out0, 
  probe_out1, probe_out2, probe_out3, probe_out4)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[31:0],probe_in1[0:0],probe_out0[0:0],probe_out1[0:0],probe_out2[0:0],probe_out3[31:0],probe_out4[4:0]" */;
  input clk;
  input [31:0]probe_in0;
  input [0:0]probe_in1;
  output [0:0]probe_out0;
  output [0:0]probe_out1;
  output [0:0]probe_out2;
  output [31:0]probe_out3;
  output [4:0]probe_out4;
endmodule
