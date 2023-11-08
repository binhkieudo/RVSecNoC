#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2022.2 (64-bit)
#
# Filename    : simulate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for simulating the design by launching the simulator
#
# Generated by Vivado on Mon Nov 06 19:02:53 JST 2023
# SW Build 3671981 on Fri Oct 14 04:59:54 MDT 2022
#
# IP Build 3669848 on Fri Oct 14 08:30:02 MDT 2022
#
# usage: simulate.sh
#
# ****************************************************************************
set -Eeuo pipefail
# simulate design
echo "xsim tb_behav -key {Behavioral:sim_1:Functional:tb} -tclbatch tb.tcl -view /home/binhkieudo/Workspace/RVSecNoC/neorv32_verilog/multithread/lsu/lsu/tb_behav.wcfg -log simulate.log"
xsim tb_behav -key {Behavioral:sim_1:Functional:tb} -tclbatch tb.tcl -view /home/binhkieudo/Workspace/RVSecNoC/neorv32_verilog/multithread/lsu/lsu/tb_behav.wcfg -log simulate.log

