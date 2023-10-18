# Compile
do {tb_compile.do}

# Elaborate
do {tb_elaborate.do}

# Simulate
vsim -lib xil_defaultlib tb_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

restart -force -nowave
vsim -t 1ns
config wave -signalnamewidth 2

radix define IF_STATE {
    2'b00 "IF_RESTART",
    2'b01 "IF_REQUEST",
    2'b10 "IF_PENDING",
    -defaut hex
}

radix define IE_STATE {
    4'd0 "IE_DISPATCH",
    4'd1 "IE_TRAP_ENTER",
    4'd2 "IE_TRAP_EXIT",
    4'd3 "IE_TRAP_EXECUTE",
    4'd4 "IE_FENCE",
    4'd5 "IE_SLEEP",
    4'd6 "IE_EXECUTE",
    4'd7 "IE_ALU_WAIT",
    4'd8 "IE_BRANCH",
    4'd9 "IE_BRANCHED",
    4'd10 "IE_SYSTEM",
    4'd11 "IE_MEM_REQ",
    4'd12 "IE_MEM_WAIT",
    -defaut hex
}

#add wave -divider -height 30 "SYSTEM"
#add wave -group system -color white -divider -height 30 "INPUT"
#add wave -group system -color white -radix unsigned sim:/tb/
#add wave -group system -color white -radix hex      sim:/tb/
#add wave -group system -color white -radix bin      sim:/tb/

#=============== System =======================================
add wave -group system -color white -radix binary sim:/tb/i_clk
add wave -group system -color white -radix binary sim:/tb/i_rstn

add wave -group cpu -group imem -radix unsigned sim:/tb/udt/ibus_req_addr
add wave -group cpu -group imem -radix hex sim:/tb/udt/ibus_req_data
add wave -group cpu -group imem -radix binary sim:/tb/udt/ibus_req_ben
add wave -group cpu -group imem -radix binary sim:/tb/udt/ibus_req_we
add wave -group cpu -group imem -radix binary sim:/tb/udt/ibus_req_re
add wave -group cpu -group imem -radix binary sim:/tb/udt/ibus_req_src
add wave -group cpu -group imem -radix binary sim:/tb/udt/ibus_req_priv
add wave -group cpu -group imem -radix binary sim:/tb/udt/ibus_req_rvso
add wave -group cpu -group imem -radix hex sim:/tb/udt/ibus_resp_data
add wave -group cpu -group imem -radix binary sim:/tb/udt/ibus_resp_ack
add wave -group cpu -group imem -radix binary sim:/tb/udt/ibus_resp_err

add wave -group cpu -group dmem -radix unsigned sim:/tb/udt/ibus_req_addr
add wave -group cpu -group dmem -radix hex sim:/tb/udt/ibus_req_data
add wave -group cpu -group dmem -radix binary sim:/tb/udt/ibus_req_ben
add wave -group cpu -group dmem -radix binary sim:/tb/udt/ibus_req_we
add wave -group cpu -group dmem -radix binary sim:/tb/udt/ibus_req_re
add wave -group cpu -group dmem -radix binary sim:/tb/udt/ibus_req_src
add wave -group cpu -group dmem -radix binary sim:/tb/udt/ibus_req_priv
add wave -group cpu -group dmem -radix binary sim:/tb/udt/ibus_req_rvso
add wave -group cpu -group dmem -radix hex sim:/tb/udt/ibus_resp_data
add wave -group cpu -group dmem -radix binary sim:/tb/udt/ibus_resp_ack
add wave -group cpu -group dmem -radix binary sim:/tb/udt/ibus_resp_err

#=============== Controller =======================================
add wave -group cpu -group controller -color white -radix binary   sim:/tb/udt/cpu/controller/i_clk

add wave -group cpu -group controller -group io  -group imem -color magenta -radix unsigned   sim:/tb/udt/cpu/controller/o_bus_req_addr
add wave -group cpu -group controller -group io  -group imem -color magenta -radix hex   sim:/tb/udt/cpu/controller/o_bus_req_data
add wave -group cpu -group controller -group io  -group imem -color magenta -radix binary   sim:/tb/udt/cpu/controller/o_bus_req_ben
add wave -group cpu -group controller -group io  -group imem -color magenta -radix binary   sim:/tb/udt/cpu/controller/o_bus_req_we
add wave -group cpu -group controller -group io  -group imem -color magenta -radix binary   sim:/tb/udt/cpu/controller/o_bus_req_re
add wave -group cpu -group controller -group io  -group imem -color magenta -radix binary   sim:/tb/udt/cpu/controller/o_bus_req_src
add wave -group cpu -group controller -group io  -group imem -color magenta -radix binary   sim:/tb/udt/cpu/controller/o_bus_req_priv
add wave -group cpu -group controller -group io  -group imem -color magenta -radix binary   sim:/tb/udt/cpu/controller/o_bus_req_rvso
add wave -group cpu -group controller -group io  -group imem -color magenta -radix hex      sim:/tb/udt/cpu/controller/i_bus_rsp_data
add wave -group cpu -group controller -group io  -group imem -color magenta -radix binary   sim:/tb/udt/cpu/controller/i_bus_rsp_ack
add wave -group cpu -group controller -group io  -group imem -color magenta -radix binary   sim:/tb/udt/cpu/controller/i_bus_rsp_err
add wave -group cpu -group controller -group io  -group imem -color magenta -radix IF_STATE sim:/tb/udt/cpu/controller/if_state
add wave -group cpu -group controller -group io  -group imem -color magenta -radix hex      sim:/tb/udt/cpu/controller/ie_ir
add wave -group cpu -group controller -group io  -group imem -color magenta -radix binary   sim:/tb/udt/cpu/controller/is_valid
add wave -group cpu -group controller -group io  -group imem -color magenta -radix binary   sim:/tb/udt/cpu/controller/is_ack

add wave -group cpu -group controller -group io -group rf -radix binary   sim:/tb/udt/cpu/controller/o_ctrl_rf_wb_en
add wave -group cpu -group controller -group io -group rf -radix unsigned sim:/tb/udt/cpu/controller/o_ctrl_rf_rs1
add wave -group cpu -group controller -group io -group rf -radix unsigned sim:/tb/udt/cpu/controller/o_ctrl_rf_rs2
add wave -group cpu -group controller -group io -group rf -radix unsigned sim:/tb/udt/cpu/controller/o_ctrl_rf_rs3
add wave -group cpu -group controller -group io -group rf -radix unsigned sim:/tb/udt/cpu/controller/o_ctrl_rf_rd
add wave -group cpu -group controller -group io -group rf -radix binary   sim:/tb/udt/cpu/controller/o_ctrl_rf_mux
add wave -group cpu -group controller -group io -group rf -radix binary   sim:/tb/udt/cpu/controller/o_ctrl_rf_zero_we

add wave -group cpu -group controller -group io -group alu -radix binary -color white sim:/tb/udt/cpu/controller/o_ctrl_alu_op
add wave -group cpu -group controller -group io -group alu -radix binary -color white sim:/tb/udt/cpu/controller/o_ctrl_alu_opa_mux
add wave -group cpu -group controller -group io -group alu -radix binary -color white sim:/tb/udt/cpu/controller/o_ctrl_alu_opb_mux
add wave -group cpu -group controller -group io -group alu -radix binary -color white sim:/tb/udt/cpu/controller/o_ctrl_alu_unsigned
add wave -group cpu -group controller -group io -group alu -radix binary -color white sim:/tb/udt/cpu/controller/o_ctrl_alu_cp_trig

add wave -group cpu -group controller -group io -group lsu -radix binary -color yellow sim:/tb/udt/cpu/controller/o_ctrl_lsu_req_rd
add wave -group cpu -group controller -group io -group lsu -radix binary -color yellow sim:/tb/udt/cpu/controller/o_ctrl_lsu_req_wr
add wave -group cpu -group controller -group io -group lsu -radix binary -color yellow sim:/tb/udt/cpu/controller/o_ctrl_lsu_rw
add wave -group cpu -group controller -group io -group lsu -radix binary -color yellow sim:/tb/udt/cpu/controller/o_ctrl_lsu_mo_we
add wave -group cpu -group controller -group io -group lsu -radix binary -color yellow sim:/tb/udt/cpu/controller/o_ctrl_lsu_fence
add wave -group cpu -group controller -group io -group lsu -radix binary -color yellow sim:/tb/udt/cpu/controller/o_ctrl_lsu_fencei
add wave -group cpu -group controller -group io -group lsu -radix binary -color yellow sim:/tb/udt/cpu/controller/o_ctrl_lsu_priv

add wave -group cpu -group controller -group io -group funct -radix binary -color cyan sim:/tb/udt/cpu/controller/o_ctrl_ir_funct3
add wave -group cpu -group controller -group io -group funct -radix binary -color cyan sim:/tb/udt/cpu/controller/o_ctrl_ir_funct12
add wave -group cpu -group controller -group io -group funct -radix binary -color cyan sim:/tb/udt/cpu/controller/o_ctrl_ir_opcode

add wave -group cpu -group controller -group io -group state -radix binary -color green sim:/tb/udt/cpu/controller/o_ctrl_cpu_priv
add wave -group cpu -group controller -group io -group state -radix binary -color green sim:/tb/udt/cpu/controller/o_ctrl_cpu_sleep
add wave -group cpu -group controller -group io -group state -radix binary -color green sim:/tb/udt/cpu/controller/o_ctrl_cpu_trap
add wave -group cpu -group controller -group io -group state -radix binary -color green sim:/tb/udt/cpu/controller/o_ctrl_cpu_debug

add wave -group cpu -group controller -group io -group other -radix binary -color lime sim:/tb/udt/cpu/controller/i_pmp_fault
add wave -group cpu -group controller -group io -group other -radix binary -color lime sim:/tb/udt/cpu/controller/i_alu_cp_done
add wave -group cpu -group controller -group io -group other -radix binary -color lime sim:/tb/udt/cpu/controller/i_lsu_wait
add wave -group cpu -group controller -group io -group other -radix binary -color lime sim:/tb/udt/cpu/controller/i_cmp_eq
add wave -group cpu -group controller -group io -group other -radix binary -color lime sim:/tb/udt/cpu/controller/i_cmp_lt
add wave -group cpu -group controller -group io -group other -radix binary -color lime sim:/tb/udt/cpu/controller/i_mar
add wave -group cpu -group controller -group io -group other -radix binary -color lime sim:/tb/udt/cpu/controller/i_ma_load
add wave -group cpu -group controller -group io -group other -radix binary -color lime sim:/tb/udt/cpu/controller/i_ma_store
add wave -group cpu -group controller -group io -group other -radix binary -color lime sim:/tb/udt/cpu/controller/i_be_load
add wave -group cpu -group controller -group io -group other -radix binary -color lime sim:/tb/udt/cpu/controller/i_be_store

add wave -group cpu -group controller -group io -group pc -radix unsigned -color green sim:/tb/udt/cpu/controller/i_alu_addr
add wave -group cpu -group controller -group io -group pc -radix hex      -color green sim:/tb/udt/cpu/controller/i_rs1
add wave -group cpu -group controller -group io -group pc -radix hex      -color green sim:/tb/udt/cpu/controller/o_imm
add wave -group cpu -group controller -group io -group pc -radix unsigned -color green sim:/tb/udt/cpu/controller/o_fetch_pc
add wave -group cpu -group controller -group io -group pc -radix unsigned -color green sim:/tb/udt/cpu/controller/o_curr_pc
add wave -group cpu -group controller -group io -group pc -radix unsigned -color green sim:/tb/udt/cpu/controller/o_next_pc
add wave -group cpu -group controller -group io -group pc -radix hex      -color green sim:/tb/udt/cpu/controller/o_csr_rdata

add wave -group cpu -group controller -group io -group xcsr -radix binary   -color lime sim:/tb/udt/cpu/controller/o_xcsr_we
add wave -group cpu -group controller -group io -group xcsr -radix unsigned -color lime sim:/tb/udt/cpu/controller/o_xcsr_addr
add wave -group cpu -group controller -group io -group xcsr -radix hex      -color lime sim:/tb/udt/cpu/controller/o_xcsr_wdata
add wave -group cpu -group controller -group io -group xcsr -radix hex      -color lime sim:/tb/udt/cpu/controller/i_xcsr_rdata

add wave -group cpu -group controller -group io -group int -radix binary -color green sim:/tb/udt/cpu/controller/i_db_halt_req
add wave -group cpu -group controller -group io -group int -radix binary -color green sim:/tb/udt/cpu/controller/i_msi
add wave -group cpu -group controller -group io -group int -radix binary -color green sim:/tb/udt/cpu/controller/i_mei
add wave -group cpu -group controller -group io -group int -radix binary -color green sim:/tb/udt/cpu/controller/i_mti
add wave -group cpu -group controller -group io -group int -radix binary -color green sim:/tb/udt/cpu/controller/i_firq

add wave -group cpu -group controller -group ie -radix IE_STATE -color white sim:/tb/udt/cpu/controller/ie_state

#======================================== Prefetch buffer ============================================================
add wave -group cpu -group buffer_0 -radix binary -color white sim:/tb/udt/cpu/controller/i_clk
add wave -group cpu -group buffer_0 -radix binary -color white sim:/tb/udt/cpu/controller/if_restart
add wave -group cpu -group buffer_0 -radix hex    -color white sim:/tb/udt/cpu/controller/ipb_wdata[0]
add wave -group cpu -group buffer_0 -radix binary -color white sim:/tb/udt/cpu/controller/ipb_we[0]
add wave -group cpu -group buffer_0 -radix binary -color white sim:/tb/udt/cpu/controller/ibp_free[0]
add wave -group cpu -group buffer_0 -radix binary -color white sim:/tb/udt/cpu/controller/ipb_re[0]
add wave -group cpu -group buffer_0 -radix hex    -color white sim:/tb/udt/cpu/controller/ipb_rdata[0]
add wave -group cpu -group buffer_0 -radix binary -color white sim:/tb/udt/cpu/controller/ibp_avail[0]
add wave -group cpu -group buffer_0 -radix hex    -color magenta sim:/tb/udt/cpu/controller/prefetch_buffer0/data

add wave -group cpu -group buffer_1 -radix binary -color yellow sim:/tb/udt/cpu/controller/i_clk
add wave -group cpu -group buffer_1 -radix binary -color yellow sim:/tb/udt/cpu/controller/if_restart
add wave -group cpu -group buffer_1 -radix hex    -color yellow sim:/tb/udt/cpu/controller/ipb_wdata[1]
add wave -group cpu -group buffer_1 -radix binary -color yellow sim:/tb/udt/cpu/controller/ipb_we[1]
add wave -group cpu -group buffer_1 -radix binary -color yellow sim:/tb/udt/cpu/controller/ibp_free[1]
add wave -group cpu -group buffer_1 -radix binary -color yellow sim:/tb/udt/cpu/controller/ipb_re[1]
add wave -group cpu -group buffer_1 -radix hex    -color yellow sim:/tb/udt/cpu/controller/ipb_rdata[1]
add wave -group cpu -group buffer_1 -radix binary -color yellow sim:/tb/udt/cpu/controller/ibp_avail[1]
add wave -group cpu -group buffer_1 -radix hex    -color magenta sim:/tb/udt/cpu/controller/prefetch_buffer1/data

view wave
view structure
view signals

run -all