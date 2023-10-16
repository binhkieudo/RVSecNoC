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


module rv32_cpu #(
    parameter XLEN = 32
)
(
        // Global control
        input  wire             i_clk,
        input  wire             i_rstn,
        // Control signals
        output wire             o_sleep, // cpu is in sleep mode when set
        output wire             o_debug, // cpu is in debug mode when set
        output wire             o_ifence, // instruction fence
        output wire             o_dfence, // data fence
        // Interrupts
        input  wire             i_msi, // risc-v machine software interrupt
        input  wire             i_mei, // risc-v machine external interrupt
        input  wire             i_mti, // risc-v machine timer interrupt
        input  wire [15:0]      i_firq, // custom fast interrupts
        input  wire             i_dbi, // risc-v debug halt request interrupt
        // Instruction bus interface
        output wire [XLEN-1:0]  o_ibus_req_addr,
        output wire [XLEN-1:0]  o_ibus_req_data,
        output wire [3:0]       o_ibus_req_ben,
        output wire             o_ibus_req_we,
        output wire             o_ibus_req_re,
        output wire             o_ibus_req_src,
        output wire             o_ibus_req_priv,
        output wire             o_ibus_req_rvso, 
        input  wire [XLEN-1:0]  i_ibus_resp_data,
        input  wire             i_ibus_resp_ack,
        input  wire             i_ibus_resp_err,
        // Data bus interface
        output wire [XLEN-1:0]  o_dbus_req_addr,
        output wire [XLEN-1:0]  o_dbus_req_data,
        output wire [3:0]       o_dbus_req_ben,
        output wire             o_dbus_req_we,
        output wire             o_dbus_req_re,
        output wire             o_dbus_req_src,
        output wire             o_dbus_req_priv,
        output wire             o_dbus_req_rvso,
        input  wire [XLEN-1:0]  i_ibus_resp_data,
        input  wire             i_ibus_resp_ack,
        input  wire             i_ibus_resp_err
    );
    
    // Local signals
    wire        ctrl_rf_wb_en;      // write back enable
    wire [4:0]  ctrl_rf_rs1;        // source register 1 address
    wire [4:0]  ctrl_rf_rs2;        // source register 2 address
    wire [4:0]  ctrl_rf_rs3;        // source register 3 address
    wire [4:0]  ctrl_rf_rd;         // destination register address
    wire [1:0]  ctrl_rf_mux;        // input source select
    wire        ctrl_rf_zero_we;    // allow/force write access to x0
    wire [2:0]  ctrl_alu_op;        // ALU operation select
    wire        ctrl_alu_opa_mux;   // operand A select (0=rs1, 1=PC)
    wire        ctrl_alu_opb_mux;   // operand B select (0=rs2, 1=IMM)
    wire        ctrl_alu_unsigned;  // is unsigned ALU operation
    wire [4:0]  ctrl_alu_cp_trig;   // co-processor trigger (one-hot)
    wire        ctrl_lsu_req_rd;    // trigger memory read request
    wire        ctrl_lsu_req_wr;    // trigger memory write request
    wire        ctrl_lsu_rw;        // 0: read access, 1: write access
    wire        ctrl_lsu_mo_we;     // memory address and data output register write enable
    wire        ctrl_lsu_fence;     // fence operation
    wire        ctrl_lsu_fencei;    // fence.i operation
    wire        ctrl_lsu_priv;      // effective privilege level for load/store
    wire [2:0]  ctrl_ir_funct3;     // funct3 bit field
    wire [11:0] ctrl_ir_funct12;    // funct12 bit field
    wire [6:0]  ctrl_ir_opcode;     // opcode bit field
    wire        ctrl_cpu_priv;      // effective privilege mode
    wire        ctrl_cpu_sleep;     // set when CPU is in sleep mode
    wire        ctrl_cpu_trap;      // set when CPU is entering trap exec
    wire        ctrl_cpu_debug;     // set when CPU is in debug mode

    wire [XLEN-1:0] imm;
    wire [XLEN-1:0] rs1;
    wire [XLEN-1:0] rs2;
    wire [XLEN-1:0] rs3;
    wire [XLEN-1:0] rs4;
    wire [XLEN-1:0] alu_res;
    wire [XLEN-1:0] alu_addr;
    wire            alu_cmp_eq;
    wire            alu_cmp_lt;
    wire [XLEN-1:0] mem_rdata;
    wire            cp_done;
    wire            lsu_wait;
    wire [XLEN-1:0] csr_rdata;
    wire [XLEN-1:0] mar;
    wire            ma_load;
    wire            ma_store;
    wire            be_load;
    wire            be_store;
    wire [XLEN-1:0] fetch_pc;
    wire [XLEN-1:0] curr_pc;
    wire [XLEN-1:0] next_pc;
    wire            pmp_ex_fault;
    wire            pmp_rd_fault;
    wire            pmp_wr_fault;

    // External CSR interface
    wire            xcsr_we:
    wire [11:0]     xcsr_addr
    wire [XLEN-1:0] xcsr_wdata;
    wire [XLEN-1:0] xcsr_rdata_pmp;
    wire [XLEN-1:0] xcsr_rdata_alu;
    wire [XLEN-1:0] xcsr_rdata_res;

    rv32_cpu_control controller (
        // Global control
        .i_clk               (i_clk             ),
        .i_rstn              (i_rstn            ),
        // Output control signals
        //-- Register file
        .o_ctrl_rf_wb_en     (ctrl_rf_wb_en     ),    // write back enable
        .o_ctrl_rf_rs1       (ctrl_rf_rs1       ),      // source register 1 address
        .o_ctrl_rf_rs2       (ctrl_rf_rs2       ),      // source register 2 address
        .o_ctrl_rf_rs3       (ctrl_rf_rs3       ),      // source register 3 address
        .o_ctrl_rf_rd        (ctrl_rf_rd        ),       // destination register address
        .o_ctrl_rf_mux       (ctrl_rf_mux       ),      // input source select
        .o_ctrl_rf_zero_we   (ctrl_rf_zero_we   ),  // allow/force write access to x0
        //-- ALU
        .o_ctrl_alu_op       (ctrl_alu_op       ),      // ALU operation select
        .o_ctrl_alu_opa_mux  (ctrl_alu_opa_mux  ), // operand A select (0=rs1, 1=PC)
        .o_ctrl_alu_opb_mux  (ctrl_alu_opb_mux  ), // operand B select (0=rs2, 1=IMM)
        .o_ctrl_alu_unsigned (ctrl_alu_unsigned ),// is unsigned ALU operation
        .o_ctrl_alu_cp_trig  (ctrl_alu_cp_trig  ), // co-processor trigger (one-hot)
        //-- load/store unit
        .o_ctrl_lsu_req_rd   (ctrl_lsu_req_rd   ),  // trigger memory read request
        .o_ctrl_lsu_req_wr   (ctrl_lsu_req_wr   ),  // trigger memory write request
        .o_ctrl_lsu_rw       (ctrl_lsu_rw       ),      // 0: read access, 1: write access
        .o_ctrl_lsu_mo_we    (ctrl_lsu_mo_we    ),   // memory address and data output register write enable
        .o_ctrl_lsu_fence    (ctrl_lsu_fence    ),   // fence operation
        .o_ctrl_lsu_fencei   (ctrl_lsu_fencei   ),  // fence.i operation
        .o_ctrl_lsu_priv     (ctrl_lsu_priv     ),    // effective privilege level for load/store
        //-- Instruction
        .o_ctrl_ir_funct3    (ctrl_ir_funct3    ),   // funct3 bit field
        .o_ctrl_ir_funct12   (ctrl_ir_funct12   ),  // funct12 bit field
        .o_ctrl_ir_opcode    (ctrl_ir_opcode    ),   // opcode bit field
        //-- CPU status
        .o_ctrl_cpu_priv     (ctrl_cpu_priv     ),    // effective privilege mode
        .o_ctrl_cpu_sleep    (ctrl_cpu_sleep    ),   // set when CPU is in sleep mode
        .o_ctrl_cpu_trap     (ctrl_cpu_trap     ),    // set when CPU is entering trap exec
        .o_ctrl_cpu_debug    (ctrl_cpu_debug    ),   // set when CPU is in debug mode
        // Instruction fetch
        .o_bus_req_addr      (o_ibus_req_addr   ), // access address
        .o_bus_req_data      (o_ibus_req_data   ), // write data
        .o_bus_req_ben       (o_ibus_req_ben    ), // byte enable
        .o_bus_req_we        (o_ibus_req_we     ), // write request
        .o_bus_req_re        (o_ibus_req_re     ), // read request
        .o_bus_req_src       (o_ibus_req_src    ), // access source (1=instruction fetch, 0=data access)
        .o_bus_req_priv      (o_ibus_req_priv   ), // set if privileged (machine-mode) access
        .o_bus_req_rvso      (o_ibus_req_rvso   ), // set if reservation set operation (atomic LR/SC)
        .i_bus_rsp_data      (i_ibus_resp_data  ), // read data
        .i_bus_rsp_ack       (i_ibus_resp_ack   ), // access acknowledge
        .i_bus_rsp_err       (i_ibus_resp_err   ), // access error
        // Status input
        .i_pmp_fault         (pmp_ex_fault      ), // instruction fetch pmp fault
        .i_alu_cp_done       (cp_done           ), // ALU coprocessor done
        .i_lsu_wait          (lsu_wait          ), // wait for data bus
        .i_cmp_eq            (alu_cmp_eq        ), // comparator equal
        .i_cmp_lt            (alu_cmp_lt        ), // comparator less than
        // Data input
        .i_alu_addr          (alu_addr          ), // ALU address result,
        .i_rs1               (rs1               ), // rf source 1
        // Data output
        .o_imm               (imm               ), // immediate
        .o_fetch_pc          (fetch_pc          ), // instruction fetch
        .o_curr_pc           (curr_pc           ), // current pc
        .o_next_pc           (next_pc           ), // next pc
        .o_csr_rdata         (csr_rdata         ), // csr read data
        // External CSR interface
        .o_xcsr_we           (xcsr_we           ), // write enable
        .o_xcsr_addr         (xcsr_addr         ), // address
        .o_xcsr_wdata        (xcsr_wdata        ), // write data
        .i_xcsr_rdata        (xcsr_rdata_res    ), // read data
        // Interrupt
        .i_db_halt_req       (i_dbi             ), // debug mode (halt) request
        .i_msi               (i_msi             ), // machine software interrupt
        .i_mei               (i_mei             ), // machine external interrupt
        .i_mti               (i_mti             ), // machine timer interrupt
        .i_firq              (i_firq            ), // fast interrupt
        // Bus access exception
        .i_mar               (mar               ), // memory address register
        .i_ma_load           (ma_load           ), // misaligned load data address
        .i_ma_store          (ma_store          ), // misaligned store data address
        .i_be_load           (be_load           ), // bus error on load data access
        .i_be_store          (be_store          )  // bus error store data access   
    );
    
    // external CSR read-back
    assign xcsr_rdata_res = xcsr_rdata_pmp | xcsr_rdata_alu;

    // CPU state
    assign o_sleep = ctrl_cpu_sleep;
    assign o_debug = ctrl_cpu_debug;

    // Instruction/Data fe3nce
    assign o_ifence = ctrl_lsu_fencei;
    assign o_dfence = ctrl_lsu_fence;

    rv32_cpu_regfile #(
        .RF_LATCH   (0),      
        .RS3_EN     (0), // enable 3rd read port
        .RS4_EN     (0)  // enable 4th read port
    ) regfile (
    // Global control signals
        .i_clk          (i_clk           ),
        // Register file interface
        .i_ctrl_wb_sel  (ctrl_rf_mux     ), // write back data select
        .i_ctrl_wb_en   (ctrl_rf_wb_en   ), // write back enable
        .i_alu          (alu_res         ), // ALU results
        .i_mem          (mem_rdata       ), // Memory results
        .i_csr          (csr_rdata       ), // CSR results,
        .i_npc          (next_pc         ),  // next pc
        .i_ir_funct3    (ctrl_ir_funct3  ),
        .i_ir_funct12   (ctrl_ir_funct12 ),
        .i_rf_rd        (ctrl_rf_rd      ), // destination address
        .i_rf_rs1       (ctrl_rf_rs1     ), // rs1 address
        .i_rf_rs2       (ctrl_rf_rs2     ), // rs2 address
        .i_rf_rs3       (ctrl_rf_rs3     ), // rs3 address
        .o_rs1          (rs1             ), // rs1
        .o_rs2          (rs2             ), // rs2
        .o_rs3          (rs3             ), // rs3
        .o_rs4          (rs4             )  // rs4
    );

    rv32_cpu_alu #(
        .FAST_SHIFT                (1),
        .FAST_MUL                  (1),
        .CPU_EXTENSION_RISCV_M     (1),
        .CPU_EXTENSION_RISCV_Zmmul (0)
    ) alu (
        // Global control
        .i_clk                  (i_clk                  ), // global clock, rising edge
        .i_rstn                 (i_rstn                 ), // global reset, active low, async
        // Control signals
        .i_ctrl_trap            (ctrl_cpu_trap          ),
        .i_ctrl_alu_unsigned    (ctrl_alu_unsigned      )    , // is unsigned ALU operation
        .i_ctrl_alu_op          (ctrl_alu_op            ),       // ALU operation
        .i_ctrl_alu_shift_right (ctrl_ir_funct3[1]      ),    // 0:shift left, 1: shift right
        .i_ctrl_alu_shift_arth  (ctrl_ir_funct12[10]    ),  // 0: shift logical, 1: shift arithmetic
        .i_ctrl_ir_funct3       (ctrl_ir_funct3         ),
        .i_ctrl_cp_en           (ctrl_alu_cp_trig       ), // active co processor signals
        .i_ctrl_pc_sel          (ctrl_alu_opa_mux       ),       // 0:rs1, 1:pc
        .i_ctrl_imm_sel         (ctrl_alu_opb_mux       ),      // 0:rs2, 1:imm
        // CSR interface
        .i_csr_we               (xcsr_we                ), // csr write enable
        .i_csr_addr             (xcsr_addr              ), // csr address
        .i_csr_wdata            (xcsr_wdata             ), // csr write data
        .o_csr_rdata            (xcsr_rdata_alu         ), // csr read data
        // Data input
        .i_rs1                  (rs1                    ),    // rf source 1
        .i_rs2                  (rs2                    ),    // rf source 2
        .i_rs3                  (rs3                    ),    // rf source 3
        .i_rs4                  (rs4                    ),    // rf source 4
        .i_pc                   (curr_pc                ),     // program counter
        .i_imm                  (imm                    ),    // immediate
        // Data output
        .o_cmp_eq               (alu_cmp_eq             ),  // comparator equal result
        .o_cmp_lt               (alu_cmp_lt             ),  // comparator less result
        .o_res                  (alu_res                ),   // ALU result
        .o_addr                 (alu_addr               ),  // address computation result
        // Status
        .o_cp_done              (cp_done                ) // co-processor operation done
    );
    
    
    rv32_cpu_lsu #(
        .AMO_LRSC(1)
    ) lsu (
    // Global control
        .i_clk              (i_clk              ),
        .i_rstn             (i_rstn             ),
        // Control signals
        .i_ir_func3         (ctrl_ir_funct3     ),
        .i_ir_opcode        (ctrl_ir_opcode     ),
        .i_ctrl_cpu_trap    (ctrl_cpu_trap      ),
        .i_ctrl_lsu_mo_we   (ctrl_lsu_mo_we     ), // memory address and data output register write enable
        .i_ctrl_lsu_priv    (ctrl_lsu_priv      ), // effective privilege level for load/store
        .i_ctrl_lsu_req_rd  (ctrl_lsu_req_rd    ), // memory read request
        .i_ctrl_lsu_req_wr  (ctrl_lsu_req_wr    ), // memory write request
        // Data access interface
        .i_addr             (alu_addr           ), // address access
        .i_wdata            (rs2                ), // write data
        .o_rdata            (mem_rdata          ), // read data
        .o_mar              (mar                ), // current memory address register
        .o_wait             (lsu_wait           ), // wait for access to complete
        .o_ma_load          (ma_load            ), // missaligned load data address
        .o_ma_store         (ma_store           ), // missaligned store data access
        .o_be_load          (be_load            ), // bus error on load data access
        .o_be_store         (be_store           ), // bus error on store data access
        .i_pmp_r_fault      (pmp_rd_fault       ), // PMP read fault
        .i_pmp_w_fault      (pmp_wr_fault       ), // PMP write fault
        // Data bus
        .o_bus_req_addr     (o_dbus_req_addr    ), // access address
        .o_bus_req_data     (o_dbus_req_data    ), // write data
        .o_bus_req_ben      (o_dbus_req_ben     ),  // byte enable
        .o_bus_req_we       (o_dbus_req_we      ),   // write request
        .o_bus_req_re       (o_dbus_req_re      ),   // read request
        .o_bus_req_src      (o_dbus_req_src     ),  // access source (1=instruction fetch, 0=data access)
        .o_bus_req_priv     (o_dbus_req_priv    ), // set if privileged (machine-mode) access
        .o_bus_req_rvso     (o_dbus_req_rvso    ), // set if reservation set operation (atomic LR/SC)
        .i_bus_rsp_data     (i_ibus_resp_data   ), // read data
        .i_bus_rsp_ack      (i_ibus_resp_ack    ),  // access acknowledge
        .i_bus_rsp_err      (i_ibus_resp_err    )   // access error
    );
    
endmodule
