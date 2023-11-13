vlib work
vlib activehdl

vlib activehdl/xil_defaultlib

vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../mul.gen/sources_1/ip/vio_alu/hdl/verilog" "+incdir+../../../../mul.gen/sources_1/ip/vio_alu/hdl" \
"../../../../mul.gen/sources_1/ip/vio_alu/sim/vio_alu.v" \


vlog -work xil_defaultlib \
"glbl.v"

