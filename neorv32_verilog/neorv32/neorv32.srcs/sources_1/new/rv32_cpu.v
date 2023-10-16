`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2023 05:30:34 PM
// Design Name: 
// Module Name: rv32_cpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rv32_cpu(

    );
    
    rv32_cpu_control controller (
        // Global control
        .i_clk               ( ),
        .i_rstn              ( ),
        // Output control signals
        //-- Register file
        .o_ctrl_rf_wb_en     ( ),    // write back enable
        .o_ctrl_rf_rs1       ( ),      // source register 1 address
        .o_ctrl_rf_rs2       ( ),      // source register 2 address
        .o_ctrl_rf_rs3       ( ),      // source register 3 address
        .o_ctrl_rf_rd        ( ),       // destination register address
        .o_ctrl_rf_mux       ( ),      // input source select
        .o_ctrl_rf_zero_we   ( ),  // allow/force write access to x0
        //-- ALU
        .o_ctrl_alu_op       ( ),      // ALU operation select
        .o_ctrl_alu_opa_mux  ( ), // operand A select (0=rs1, 1=PC)
        .o_ctrl_alu_opb_mux  ( ), // operand B select (0=rs2, 1=IMM)
        .o_ctrl_alu_unsigned ( ),// is unsigned ALU operation
        .o_ctrl_alu_cp_trig  ( ), // co-processor trigger (one-hot)
        //-- load/store unit
        .o_ctrl_lsu_req_rd   ( ),  // trigger memory read request
        .o_ctrl_lsu_req_wr   ( ),  // trigger memory write request
        .o_ctrl_lsu_rw       ( ),      // 0: read access, 1: write access
        .o_ctrl_lsu_mo_we    ( ),   // memory address and data output register write enable
        .o_ctrl_lsu_fence    ( ),   // fence operation
        .o_ctrl_lsu_fencei   ( ),  // fence.i operation
        .o_ctrl_lsu_priv     ( ),    // effective privilege level for load/store
        //-- Instruction
        .o_ctrl_ir_funct3    ( ),   // funct3 bit field
        .o_ctrl_ir_funct12   ( ),  // funct12 bit field
        .o_ctrl_ir_opcode    ( ),   // opcode bit field
        //-- CPU status
        .o_ctrl_cpu_priv     ( ),    // effective privilege mode
        .o_ctrl_cpu_sleep    ( ),   // set when CPU is in sleep mode
        .o_ctrl_cpu_trap     ( ),    // set when CPU is entering trap exec
        .o_ctrl_cpu_debug    ( ),   // set when CPU is in debug mode
        
        // Instruction fetch
        .o_bus_req_addr      ( ), // access address
        .o_bus_req_data      ( ), // write data
        .o_bus_req_ben       ( ), // byte enable
        .o_bus_req_we        ( ), // write request
        .o_bus_req_re        ( ), // read request
        .o_bus_req_src       ( ), // access source (1=instruction fetch, 0=data access)
        .o_bus_req_priv      ( ), // set if privileged (machine-mode) access
        .o_bus_req_rvso      ( ), // set if reservation set operation (atomic LR/SC)
        .i_bus_rsp_data      ( ), // read data
        .i_bus_rsp_ack       ( ), // access acknowledge
        .i_bus_rsp_err       ( ), // access error
        // Status input
        .i_pmp_fault         ( ), // instruction fetch pmp fault
        .i_alu_cp_done       ( ), // ALU coprocessor done
        .i_lsu_wait          ( ), // wait for data bus
        .i_cmp_eq            ( ), // comparator equal
        .i_cmp_lt            ( ), // comparator less than
        // Data input
        .i_alu_addr          ( ), // ALU address result,
        .i_rs1               ( ), // rf source 1
        // Data output
        .o_imm               ( ), // immediate
        .o_fetch_pc          ( ), // instruction fetch
        .o_curr_pc           ( ), // current pc
        .o_next_pc           ( ), // next pc
        .o_csr_rdata         ( ), // csr read data
        // External CSR interface
        .o_xcsr_we           ( ), // write enable
        .o_xcsr_addr         ( ), // address
        .o_xcsr_wdata        ( ), // write data
        .i_xcsr_rdata        ( ), // read data
        // Interrupt
        .i_db_halt_req       ( ), // debug mode (halt) request
        .i_msi               ( ), // machine software interrupt
        .i_mei               ( ), // machine external interrupt
        .i_mti               ( ), // machine timer interrupt
        .i_firq              ( ), // fast interrupt
        // Bus access exception
        .i_mar               ( ), // memory address register
        .i_ma_load           ( ), // misaligned load data address
        .i_ma_store          ( ), // misaligned store data address
        .i_be_load           ( ), // bus error on load data access
        .i_be_store          ( )  // bus error store data access   
    );
    
    rv32_cpu_regfile #(
        .RF_LATCH   (0),      
        .RS3_EN     (0), // enable 3rd read port
        .RS4_EN     (0)  // enable 4th read port
    ) regfile (
    // Global control signals
        .i_clk          ( ),
        // Register file interface
        .i_ctrl_wb_sel  ( ), // write back data select
        .i_ctrl_wb_en   ( ), // write back enable
        .i_alu          ( ), // ALU results
        .i_mem          ( ), // Memory results
        .i_csr          ( ), // CSR results,
        .i_npc          ( ),  // next pc
        .i_ir_funct3    ( ),
        .i_ir_funct12   ( ),
        .i_rf_rd        ( ), // destination address
        .i_rf_rs1       ( ), // rs1 address
        .i_rf_rs2       ( ), // rs2 address
        .i_rf_rs3       ( ), // rs3 address
        .o_rs1          ( ), // rs1
        .o_rs2          ( ), // rs2
        .o_rs3          ( ), // rs3
        .o_rs4          ( )  // rs4
    );

    rv32_cpu_alu #(
        .FAST_SHIFT                (1),
        .FAST_MUL                  (1),
        .CPU_EXTENSION_RISCV_M     (1),
        .CPU_EXTENSION_RISCV_Zmmul (0)
    ) alu (
        // Global control
        .i_clk                  ( ), // global clock, rising edge
        .i_rstn                 ( ), // global reset, active low, async
        // Control signals
        .i_ctrl_trap            ( ),
        .i_ctrl_alu_unsigned    ( ), // is unsigned ALU operation
        .i_ctrl_alu_op          ( ),       // ALU operation
        .i_ctrl_alu_shift_right ( ),    // 0:shift left, 1: shift right
        .i_ctrl_alu_shift_arth  ( ),  // 0: shift logical, 1: shift arithmetic
        .i_ctrl_ir_funct3       ( ),
        .i_ctrl_alu_shamt       ( ),
        .i_ctrl_cp_en           ( ), // active co processor signals
        .i_ctrl_pc_sel          ( ),       // 0:rs1, 1:pc
        .i_ctrl_imm_sel         ( ),      // 0:rs2, 1:imm
        // CSR interface
        .i_csr_we               ( ), // csr write enable
        .i_csr_addr             ( ), // csr address
        .i_csr_wdata            ( ), // csr write data
        .o_csr_rdata            ( ), // csr read data
        // Data input
        .i_rs1                  ( ),    // rf source 1
        .i_rs2                  ( ),    // rf source 2
        .i_rs3                  ( ),    // rf source 3
        .i_rs4                  ( ),    // rf source 4
        .i_pc                   ( ),     // program counter
        .i_imm                  ( ),    // immediate
        // Data output
        .o_cmp_eq               ( ),  // comparator equal result
        .o_cmp_lt               ( ),  // comparator less result
        .o_res                  ( ),   // ALU result
        .o_addr                 ( ),  // address computation result
        // Status
        .o_cp_done              ( ) // co-processor operation done
    );
    
    
    rv32_cpu_lsu #(
        .AMO_LRSC(1)
    ) lsu (
    // Global control
        .i_clk              ( ),
        .i_rstn             ( ),
        // Control signals
        .i_ir_func3         ( ),
        .i_ir_opcode        ( ),
        .i_ctrl_cpu_trap    ( ),
        .i_ctrl_lsu_mo_we   ( ), // memory address and data output register write enable
        .i_ctrl_lsu_priv    ( ),  // effective privilege level for load/store
        .i_ctrl_lsu_req_rd  ( ), // memory read request
        .i_ctrl_lsu_req_wr  ( ), // memory write request
        // Data access interface
        .i_addr             ( ), // address access
        .i_wdata            ( ), // write data
        .o_rdata            ( ), // read data
        .o_mar              ( ), // current memory address register
        .o_wait             ( ), // wait for access to complete
        .o_ma_load          ( ), // missaligned load data address
        .o_ma_store         ( ), // missaligned store data access
        .o_be_load          ( ), // bus error on load data access
        .o_be_store         ( ), // bus error on store data access
        .i_pmp_r_fault      ( ), // PMP read fault
        .i_pmp_w_fault      ( ), // PMP write fault
        // Data bus
        .o_bus_req_addr     ( ), // access address
        .o_bus_req_data     ( ), // write data
        .o_bus_req_ben      ( ),  // byte enable
        .o_bus_req_we       ( ),   // write request
        .o_bus_req_re       ( ),   // read request
        .o_bus_req_src      ( ),  // access source (1=instruction fetch, 0=data access)
        .o_bus_req_priv     ( ), // set if privileged (machine-mode) access
        .o_bus_req_rvso     ( ), // set if reservation set operation (atomic LR/SC)
        .i_bus_rsp_data     ( ), // read data
        .i_bus_rsp_ack      ( ),  // access acknowledge
        .i_bus_rsp_err      ( )   // access error
    );
    
    

endmodule
