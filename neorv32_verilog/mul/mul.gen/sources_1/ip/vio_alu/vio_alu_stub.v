// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Sun Nov 12 12:40:50 2023
// Host        : binhkieudo-hotswap running 64-bit Ubuntu 20.04.6 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/binhkieudo/Workspace/RISC-V/RVSecNoC/neorv32_verilog/mul/mul.gen/sources_1/ip/vio_alu/vio_alu_stub.v
// Design      : vio_alu
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2022.2" *)
module vio_alu(clk, probe_in0, probe_out0, probe_out1, 
  probe_out2)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[32:0],probe_out0[15:0],probe_out1[15:0],probe_out2[15:0]" */;
  input clk;
  input [32:0]probe_in0;
  output [15:0]probe_out0;
  output [15:0]probe_out1;
  output [15:0]probe_out2;
endmodule
