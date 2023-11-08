# Compile
do {tb_compile.do}

# Elaborate
do {tb_elaborate.do}

# Simulate
vsim -debugDB -lib xil_defaultlib tb_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

restart -force -nowave
vsim -t 1ns
config wave -signalnamewidth 2

#add wave -divider -height 30 "SYSTEM"
#add wave -group system -color white -divider -height 30 "INPUT"
#add wave -group system -color white -radix unsigned sim:/tb/
#add wave -group system -color white -radix hex      sim:/tb/
#add wave -group system -color white -radix bin      sim:/tb/

add wave -divider -height 30 "THREAD"
add wave -group thread_0 -color white -radix binary sim:/tb/i_clk
add wave -group thread_0 -color white -radix binary sim:/tb/i_rstn
add wave -group thread_0 -group io -radix binary sim:/tb/i_funct3[2:0]
add wave -group thread_0 -group io -color white -radix unsigned sim:/tb/i_wadr[31:0]
add wave -group thread_0 -group io -color white -radix binary   sim:/tb/i_we[0]
add wave -group thread_0 -group io -color white -radix hex 	    sim:/tb/i_wdata[31:0]
add wave -group thread_0 -group io -color white -radix binary   sim:/tb/o_wack[0]
add wave -group thread_0 -group io -color magenta -radix unsigned   sim:/tb/i_radr[31:0]
add wave -group thread_0 -group io -color magenta -radix binary     sim:/tb/i_re[0]
add wave -group thread_0 -group io -color magenta -radix hex	    sim:/tb/o_rdata[31:0]
add wave -group thread_0 -group io -color magenta -radix binary     sim:/tb/o_rack[0]
add wave -group thread_0 -group io -color cyan -radix unsigned   sim:/tb/udt/lsu_inst0/o_mem_wadr[31:0]
add wave -group thread_0 -group io -color cyan -radix binary     sim:/tb/udt/lsu_inst0/o_mem_we[0]
add wave -group thread_0 -group io -color cyan -radix binary     sim:/tb/udt/lsu_inst0/o_mem_ben[3:0]
add wave -group thread_0 -group io -color cyan -radix hex        sim:/tb/udt/lsu_inst0/o_mem_wdata[31:0]
add wave -group thread_0 -group io -color cyan -radix unsigned   sim:/tb/udt/lsu_inst0/o_mem_radr[31:0]
add wave -group thread_0 -group io -color cyan -radix binary     sim:/tb/udt/lsu_inst0/o_mem_re[0]

add wave -group thread_0 -group ctrl -color white -radix binary sim:/tb/udt/lsu_inst0/thread[0]/wr_cmp
add wave -group thread_0 -group ctrl -color white -radix binary sim:/tb/udt/lsu_inst0/thread[0]/rd_cmp
add wave -group thread_0 -group ctrl -color white -radix binary sim:/tb/udt/lsu_inst0/thread[0]/funct3
add wave -group thread_0 -group ctrl -color white -radix hex    sim:/tb/udt/lsu_inst0/thread[0]/resp_data
add wave -group thread_0 -group ctrl -color white -radix binary sim:/tb/udt/lsu_inst0/thread[0]/sign_bit
add wave -group thread_0 -group ctrl -color white -radix binary sim:/tb/udt/lsu_inst0/thread[0]/sign_extend
add wave -group thread_0 -group ctrl -color yellow -radix unsigned sim:/tb/udt/lsu_inst0/thread[0]/req_radr
add wave -group thread_0 -group ctrl -color yellow -radix unsigned sim:/tb/udt/lsu_inst0/thread[0]/req_rchannel
add wave -group thread_0 -group ctrl -color yellow -radix binary   sim:/tb/udt/lsu_inst0/thread[0]/r_rdresp_ack
add wave -group thread_0 -group ctrl -color yellow -radix binary   sim:/tb/udt/lsu_inst0/thread[0]/r_rdreq_pend
add wave -group thread_0 -group ctrl -color cyan -radix unsigned sim:/tb/udt/lsu_inst0/thread[0]/req_wadr
add wave -group thread_0 -group ctrl -color cyan -radix unsigned sim:/tb/udt/lsu_inst0/thread[0]/req_wchannel
add wave -group thread_0 -group ctrl -color cyan -radix binary   sim:/tb/udt/lsu_inst0/thread[0]/r_wrresp_ack
add wave -group thread_0 -group ctrl -color cyan -radix binary   sim:/tb/udt/lsu_inst0/thread[0]/r_wrreq_pend

add wave -divider -height 30 "CHANNEL"
add wave -group channel_0 -radix binary -color white sim:/tb/udt/lsu_inst0/i_clk
add wave -group channel_0 -radix binary -color white sim:/tb/udt/lsu_inst0/i_rstn

add wave -group channel_0 -radix hex        sim:/tb/udt/lsu_inst0/channel[0]/r_wdata
add wave -group channel_0 -radix unsigned   sim:/tb/udt/lsu_inst0/channel[0]/r_sel_wadr
add wave -group channel_0 -radix binary     sim:/tb/udt/lsu_inst0/channel[0]/r_we
add wave -group channel_0 -radix binary     sim:/tb/udt/lsu_inst0/channel[0]/r_ben
add wave -group channel_0 -radix unsigned   -color cyan   sim:/tb/udt/lsu_inst0/channel[0]/r_sel_radr
add wave -group channel_0 -radix binary     -color cyan   sim:/tb/udt/lsu_inst0/channel[0]/r_re
add wave -group channel_0 -radix hex        -color yellow   sim:/tb/udt/lsu_inst0/channel[0]/r1_wdata
add wave -group channel_0 -radix binary     -color yellow   sim:/tb/udt/lsu_inst0/channel[0]/r1_ben
add wave -group channel_0 -radix hex        -color magenta sim:/tb/udt/lsu_inst0/channel[0]/r2_wdata
add wave -group channel_0 -radix binary     -color magenta sim:/tb/udt/lsu_inst0/channel[0]/r2_ben


add wave -divider -height 30 "MEMORY"
add wave -group memory -color white -radix binary sim:/tb/udt/dmem_inst0/i_clk

add wave -group memory -group channel_0 -color yellow -radix unsigned  sim:/tb/udt/dmem_inst0/i_mem_wadr[31:0]
add wave -group memory -group channel_0 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_we[0]
add wave -group memory -group channel_0 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_ben[3:0]
add wave -group memory -group channel_0 -color yellow -radix hex 	 sim:/tb/udt/dmem_inst0/i_mem_wdata[31:0]
add wave -group memory -group channel_0 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/o_mem_wack[0]
add wave -group memory -group channel_0 -color cyan  -radix unsigned  sim:/tb/udt/dmem_inst0/i_mem_radr[31:0]
add wave -group memory -group channel_0 -color cyan  -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_re[0]
add wave -group memory -group channel_0 -color cyan  -radix hex 	 sim:/tb/udt/dmem_inst0/o_mem_rdata[31:0]
add wave -group memory -group channel_0 -color cyan  -radix binary 	 sim:/tb/udt/dmem_inst0/o_mem_rack[0]
add wave -group memory -group channel_0 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[0]/bank_3
add wave -group memory -group channel_0 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[0]/bank_2
add wave -group memory -group channel_0 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[0]/bank_1
add wave -group memory -group channel_0 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[0]/bank_0

add wave -group memory -group channel_1 -color yellow -radix unsigned  sim:/tb/udt/dmem_inst0/i_mem_wadr[63:32]
add wave -group memory -group channel_1 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_we[1]
add wave -group memory -group channel_1 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_ben[7:4]
add wave -group memory -group channel_1 -color yellow -radix hex 	 sim:/tb/udt/dmem_inst0/i_mem_wdata[63:32]
add wave -group memory -group channel_1 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/o_mem_wack[1]
add wave -group memory -group channel_1 -color cyan  -radix unsigned  sim:/tb/udt/dmem_inst0/i_mem_radr[63:32]
add wave -group memory -group channel_1 -color cyan  -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_re[1]
add wave -group memory -group channel_1 -color cyan  -radix hex 	 sim:/tb/udt/dmem_inst0/o_mem_rdata[63:32]
add wave -group memory -group channel_1 -color cyan  -radix binary 	 sim:/tb/udt/dmem_inst0/o_mem_rack[1]
add wave -group memory -group channel_1 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[1]/bank_3
add wave -group memory -group channel_1 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[1]/bank_2
add wave -group memory -group channel_1 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[1]/bank_1
add wave -group memory -group channel_1 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[1]/bank_0

add wave -group memory -group channel_2 -color yellow -radix unsigned  sim:/tb/udt/dmem_inst0/i_mem_wadr[95:64]
add wave -group memory -group channel_2 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_we[2]
add wave -group memory -group channel_2 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_ben[11:8]
add wave -group memory -group channel_2 -color yellow -radix hex 	 sim:/tb/udt/dmem_inst0/i_mem_wdata[95:64]
add wave -group memory -group channel_2 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/o_mem_wack[2]
add wave -group memory -group channel_2 -color cyan  -radix unsigned  sim:/tb/udt/dmem_inst0/i_mem_radr[95:64]
add wave -group memory -group channel_2 -color cyan  -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_re[2]
add wave -group memory -group channel_2 -color cyan  -radix hex 	 sim:/tb/udt/dmem_inst0/o_mem_rdata[95:64]
add wave -group memory -group channel_2 -color cyan  -radix binary 	 sim:/tb/udt/dmem_inst0/o_mem_rack[2]
add wave -group memory -group channel_2 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[2]/bank_3
add wave -group memory -group channel_2 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[2]/bank_2
add wave -group memory -group channel_2 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[2]/bank_1
add wave -group memory -group channel_2 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[2]/bank_0

add wave -group memory -group channel_3 -color yellow -radix unsigned  sim:/tb/udt/dmem_inst0/i_mem_wadr[127:96]
add wave -group memory -group channel_3 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_we[3]
add wave -group memory -group channel_3 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_ben[15:12]
add wave -group memory -group channel_3 -color yellow -radix hex 	 sim:/tb/udt/dmem_inst0/i_mem_wdata[127:96]
add wave -group memory -group channel_3 -color yellow -radix binary 	 sim:/tb/udt/dmem_inst0/o_mem_wack[3]
add wave -group memory -group channel_3 -color cyan  -radix unsigned  sim:/tb/udt/dmem_inst0/i_mem_radr[127:96]
add wave -group memory -group channel_3 -color cyan  -radix binary 	 sim:/tb/udt/dmem_inst0/i_mem_re[3]
add wave -group memory -group channel_3 -color cyan  -radix hex 	 sim:/tb/udt/dmem_inst0/o_mem_rdata[127:96]
add wave -group memory -group channel_3 -color cyan  -radix binary 	 sim:/tb/udt/dmem_inst0/o_mem_rack[3]
add wave -group memory -group channel_3 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[3]/bank_3
add wave -group memory -group channel_3 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[3]/bank_2
add wave -group memory -group channel_3 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[3]/bank_1
add wave -group memory -group channel_3 -color blue  -radix hex 	 sim:/tb/udt/dmem_inst0/channel[3]/bank_0

view wave
view structure
view signals

run -all
