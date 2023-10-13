######################################################################
#
# File name : tb_fifo_simulate.do
# Created on: Wed Oct 11 14:24:28 JST 2023
#
# Auto generated by Vivado for 'behavioral' simulation
#
######################################################################
vsim -lib xil_defaultlib tb_fifo_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {tb_fifo_wave.do}

view wave
view structure
view signals

log -r /*

do {tb_fifo.udo}

run 1000ns