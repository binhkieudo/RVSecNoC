vlib work
vlib activehdl

vlib activehdl/xil_defaultlib

vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../cp_distributor.gen/sources_1/ip/vio_0/hdl/verilog" "+incdir+../../../../cp_distributor.gen/sources_1/ip/vio_0/hdl" \
"../../../../cp_distributor.gen/sources_1/ip/vio_0/sim/vio_0.v" \


vlog -work xil_defaultlib \
"glbl.v"
