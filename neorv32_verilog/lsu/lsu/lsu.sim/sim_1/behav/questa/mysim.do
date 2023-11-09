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

add wave -divider -height 30 "CHANNEL"
add wave -group channel_0 -radix binary -color white sim:/tb/udt/lsu_inst0/i_clk
add wave -group channel_0 -radix binary -color white sim:/tb/udt/lsu_inst0/i_rstn

add wave -group channel_0 -group ctrl -radix unsigned   -color yellow sim:/tb/udt/lsu_inst0/o_mem_radr[31:0]
add wave -group channel_0 -group ctrl -radix binary     -color yellow sim:/tb/udt/lsu_inst0/o_mem_re[0]
add wave -group channel_0 -group ctrl -radix unsigned   -color yellow sim:/tb/udt/lsu_inst0/r_sel_radr[0]
add wave -group channel_0 -group ctrl -radix binary     -color yellow sim:/tb/udt/lsu_inst0/r_re[0]
add wave -group channel_0 -group ctrl -radix unsigned   -color white sim:/tb/udt/lsu_inst0/o_mem_wadr[31:0]
add wave -group channel_0 -group ctrl -radix binary     -color white sim:/tb/udt/lsu_inst0/o_mem_we[0]
add wave -group channel_0 -group ctrl -radix binary     -color white sim:/tb/udt/lsu_inst0/o_mem_ben[3:0]
add wave -group channel_0 -group ctrl -radix hex        -color white sim:/tb/udt/lsu_inst0/o_mem_wdata[31:0]
add wave -group channel_0 -group ctrl -radix unsigned   -color white sim:/tb/udt/lsu_inst0/r_sel_wadr[0]
add wave -group channel_0 -group ctrl -radix binary     -color white sim:/tb/udt/lsu_inst0/r_we[0]
add wave -group channel_0 -group ctrl -radix hex        -color white sim:/tb/udt/lsu_inst0/r_wdata[0]
add wave -group channel_0 -group ctrl -radix binary     -color white sim:/tb/udt/lsu_inst0/r_ben[0]

add wave -divider -height 30 "MEMORY"
add wave -group memory -color white -radix binary sim:/tb/udt/dcache_inst0/i_clk

add wave -group memory -group channel_0 -color yellow -radix unsigned  sim:/tb/udt/dcache_inst0/mem_waddr[0]
add wave -group memory -group channel_0 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/mem_we[0]
add wave -group memory -group channel_0 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/mem_ben[0]
add wave -group memory -group channel_0 -color yellow -radix hex       sim:/tb/udt/dcache_inst0/mem_wdata[0]
add wave -group memory -group channel_0 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/o_mem_wack[0]
add wave -group memory -group channel_0 -color cyan -radix unsigned   sim:/tb/udt/dcache_inst0/mem_raddr[0]
add wave -group memory -group channel_0 -color cyan -radix binary     sim:/tb/udt/dcache_inst0/mem_re[0]
add wave -group memory -group channel_0 -color cyan -radix hex        sim:/tb/udt/dcache_inst0/o_mem_rdata[31:0]
add wave -group memory -group channel_0 -color cyan -radix binary     sim:/tb/udt/dcache_inst0/o_mem_rack[0]
add wave -group memory -group channel_0 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[0]/bank_3
add wave -group memory -group channel_0 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[0]/bank_2
add wave -group memory -group channel_0 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[0]/bank_1
add wave -group memory -group channel_0 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[0]/bank_0

add wave -group memory -group channel_1 -color yellow -radix unsigned  sim:/tb/udt/dcache_inst0/mem_waddr[1]
add wave -group memory -group channel_1 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/mem_we[1]
add wave -group memory -group channel_1 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/mem_ben[1]
add wave -group memory -group channel_1 -color yellow -radix hex       sim:/tb/udt/dcache_inst0/mem_wdata[1]
add wave -group memory -group channel_1 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/o_mem_wack[]
add wave -group memory -group channel_1 -color cyan -radix unsigned   sim:/tb/udt/dcache_inst0/mem_raddr[1]
add wave -group memory -group channel_1 -color cyan -radix binary     sim:/tb/udt/dcache_inst0/mem_re[1]
add wave -group memory -group channel_1 -color cyan -radix hex        sim:/tb/udt/dcache_inst0/o_mem_rdata[63:32]
add wave -group memory -group channel_1 -color cyan -radix binary     sim:/tb/udt/dcache_inst0/o_mem_rack[1]
add wave -group memory -group channel_1 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[1]/bank_3
add wave -group memory -group channel_1 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[1]/bank_2
add wave -group memory -group channel_1 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[1]/bank_1
add wave -group memory -group channel_1 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[1]/bank_0

add wave -group memory -group channel_2 -color yellow -radix unsigned  sim:/tb/udt/dcache_inst0/mem_waddr[2]
add wave -group memory -group channel_2 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/mem_we[2]
add wave -group memory -group channel_2 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/mem_ben[2]
add wave -group memory -group channel_2 -color yellow -radix hex       sim:/tb/udt/dcache_inst0/mem_wdata[2]
add wave -group memory -group channel_2 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/o_mem_wack[2]
add wave -group memory -group channel_2 -color cyan -radix unsigned   sim:/tb/udt/dcache_inst0/mem_raddr[2]
add wave -group memory -group channel_2 -color cyan -radix binary     sim:/tb/udt/dcache_inst0/mem_re[2]
add wave -group memory -group channel_2 -color cyan -radix hex        sim:/tb/udt/dcache_inst0/o_mem_rdata[95:64]
add wave -group memory -group channel_2 -color cyan -radix binary     sim:/tb/udt/dcache_inst0/o_mem_rack[2]
add wave -group memory -group channel_2 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[2]/bank_3
add wave -group memory -group channel_2 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[2]/bank_2
add wave -group memory -group channel_2 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[2]/bank_1
add wave -group memory -group channel_2 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[2]/bank_0

add wave -group memory -group channel_3 -color yellow -radix unsigned  sim:/tb/udt/dcache_inst0/mem_waddr[3]
add wave -group memory -group channel_3 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/mem_we[3]
add wave -group memory -group channel_3 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/mem_ben[3]
add wave -group memory -group channel_3 -color yellow -radix hex       sim:/tb/udt/dcache_inst0/mem_wdata[3]
add wave -group memory -group channel_3 -color yellow -radix binary    sim:/tb/udt/dcache_inst0/o_mem_wack[3]
add wave -group memory -group channel_3 -color cyan -radix unsigned   sim:/tb/udt/dcache_inst0/mem_raddr[3]
add wave -group memory -group channel_3 -color cyan -radix binary     sim:/tb/udt/dcache_inst0/mem_re[3]
add wave -group memory -group channel_3 -color cyan -radix hex        sim:/tb/udt/dcache_inst0/o_mem_rdata[127:96]
add wave -group memory -group channel_3 -color cyan -radix binary     sim:/tb/udt/dcache_inst0/o_mem_rack[3]
add wave -group memory -group channel_3 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[3]/bank_3
add wave -group memory -group channel_3 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[3]/bank_2
add wave -group memory -group channel_3 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[3]/bank_1
add wave -group memory -group channel_3 -color white -radix hex sim:/tb/udt/dcache_inst0/dmem_inst[3]/bank_0

view wave
view structure
view signals

run -all
