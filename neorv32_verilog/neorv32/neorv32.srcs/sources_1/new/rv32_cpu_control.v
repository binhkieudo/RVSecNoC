`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2023 01:05:25 PM
// Design Name: 
// Module Name: rv32_cpu_control
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


`include "rv32_package.vh"

module rv32_cpu_control #(
    parameter XLEN                          = 32,
    parameter HART_ID                       = 0,  // hardware thread ID (HART)
    parameter VENDOR_ID                     = 0,  // vendor's JEDEC ID
    parameter CPU_BOOT_ADR                  = 0,  // cpu boot address
    parameter HW_VERSION                    = 32'h01080906,
    parameter CPU_DEBUG_PARK_ADDR           = 0,  // cpu debug mode parking loop entry address
    parameter CPU_DEBUG_EXC_ADDR            = 0,  // cpu debug mode exception entry address
    parameter INSTR_BUFFER_DEPTH            = 4,  // instruction prefetch buffer depth
    // Extensions
    parameter CPU_EXTENSION_RISCV_A         = 1,  // Atomic
    parameter CPU_EXTENSION_RISCV_C         = 1,  // Compress
    parameter CPU_EXTENSION_RISCV_M         = 1,  // Mul/div
    parameter CPU_EXTENSION_RISCV_U         = 0,  // User mode
    parameter CPU_EXTENSION_RISCV_F         = 0,  // Single-precision
    parameter CPU_EXTENSION_RISCV_D         = 0,  // Double-precision
    parameter CPU_EXTENSION_RISCV_Zicntr    = 0,  // Base counter
    parameter CPU_EXTENSION_RISCV_Zifencei  = 1,  // Insctruction sync
    parameter CPU_EXTENSION_RISCV_Zmmul     = 1,  // Only mul (override by M extension)
    parameter CPU_EXTENSION_RISCV_Zxcfu     = 1,  // Custrom instruction
    parameter CPU_EXTENSION_RISCV_Sdext     = 1,  // External debug
    parameter CPU_EXTENSION_RISCV_Sdtrig    = 1,  // Trigger module 
    // Tuning Options
    parameter FAST_MUL_EN                   = 1,  // 1=dsp, 0=double&add
    parameter FAST_SHIFT_EN                 = 1,  // 1=barrel, 0=serial
    // Physical memory protection (PMP)
    parameter PMP_EN                        = 1,  // Enable physical memory protection
    // Hardware Performance Monitors (HPM)
    parameter HPM_NUM_CNTS                  = 0,  // Number of hardware performance counter (max 13)
    parameter HPM_CNT_WIDTH                 = 64  // Size of HPM counters
)
(

    // Global control
    input wire              i_clk,
    input wire              i_rstn,
    // Output control signals
    //-- Register file
    output wire             o_ctrl_rf_wb_en,    // write back enable
    output wire [4:0]       o_ctrl_rf_rs1,      // source register 1 address
    output wire [4:0]       o_ctrl_rf_rs2,      // source register 2 address
    output wire [4:0]       o_ctrl_rf_rs3,      // source register 3 address
    output wire [4:0]       o_ctrl_rf_rd,       // destination register address
    output wire [1:0]       o_ctrl_rf_mux,      // input source select
    output wire             o_ctrl_rf_zero_we,  // allow/force write access to x0
    //-- ALU
    output wire [2:0]       o_ctrl_alu_op,      // ALU operation select
    output wire             o_ctrl_alu_opa_mux, // operand A select (0=rs1, 1=PC)
    output wire             o_ctrl_alu_opb_mux, // operand B select (0=rs2, 1=IMM)
    output wire             o_ctrl_alu_unsigned,// is unsigned ALU operation
    output wire [4:0]       o_ctrl_alu_cp_trig, // co-processor trigger (one-hot)
    //-- load/store unit
    output wire             o_ctrl_lsu_req_rd,  // trigger memory read request
    output wire             o_ctrl_lsu_req_wr,  // trigger memory write request
    output wire             o_ctrl_lsu_rw,      // 0: read access, 1: write access
    output wire             o_ctrl_lsu_mo_we,   // memory address and data output register write enable
    output wire             o_ctrl_lsu_fence,   // fence operation
    output wire             o_ctrl_lsu_fencei,  // fence.i operation
    output wire             o_ctrl_lsu_priv,    // effective privilege level for load/store
    //-- Instruction
    output wire [2:0]       o_ctrl_ir_funct3,   // funct3 bit field
    output wire [11:0]      o_ctrl_ir_funct12,  // funct12 bit field
    output wire [6:0]       o_ctrl_ir_opcode,   // opcode bit field
    //-- CPU status
    output wire             o_ctrl_cpu_priv,    // effective privilege mode
    output wire             o_ctrl_cpu_sleep,   // set when CPU is in sleep mode
    output wire             o_ctrl_cpu_trap,    // set when CPU is entering trap exec
    output wire             o_ctrl_cpu_debug,   // set when CPU is in debug mode
    
    // Instruction fetch
    output wire [XLEN-1:0]  o_bus_req_addr, // access address
    output wire  [XLEN-1:0] o_bus_req_data, // write data
    output wire  [3:0]      o_bus_req_ben,  // byte enable
    output wire             o_bus_req_we,   // write request
    output wire             o_bus_req_re,   // read request
    output wire             o_bus_req_src,  // access source (1=instruction fetch, 0=data access)
    output wire             o_bus_req_priv, // set if privileged (machine-mode) access
    output wire              o_bus_req_rvso, // set if reservation set operation (atomic LR/SC)
    input wire  [XLEN-1:0]  i_bus_rsp_data, // read data
    input wire              i_bus_rsp_ack,  // access acknowledge
    input wire              i_bus_rsp_err,  // access error
    // Status input
    input wire              i_pmp_fault,     // instruction fetch pmp fault
    input wire              i_alu_cp_done,   // ALU coprocessor done
    input wire              i_lsu_wait,      // wait for data bus
    input wire              i_cmp_eq,        // comparator equal
    input wire              i_cmp_lt,        // comparator less than
    // Data input
    input wire  [XLEN-1:0]  i_alu_addr,      // ALU address result,
    input wire  [XLEN-1:0]  i_rs1,           // rf source 1
    // Data output
    output wire [XLEN-1:0]  o_imm,           // immediate
    output wire [XLEN-1:0]  o_fetch_pc,      // instruction fetch
    output wire [XLEN-1:0]  o_curr_pc,       // current pc
    output wire [XLEN-1:0]  o_next_pc,       // next pc
    output wire [XLEN-1:0]  o_csr_rdata,     // csr read data
    // External CSR interface
    output wire             o_xcsr_we,       // write enable
    output wire [11:0]      o_xcsr_addr,     // address
    output wire [XLEN-1:0]  o_xcsr_wdata,    // write data
    input  wire [XLEN-1:0]  i_xcsr_rdata,    // read data
    // Interrupt
    input  wire             i_db_halt_req,   // debug mode (halt) request
    input  wire             i_msi,           // machine software interrupt
    input  wire             i_mei,           // machine external interrupt
    input  wire             i_mti,           // machine timer interrupt
    input  wire [15:0]      i_firq,          // fast interrupt
    // Bus access exception
    input  wire [XLEN-1:0]  i_mar,           // memory address register
    input  wire             i_ma_load,       // misaligned load data address
    input  wire             i_ma_store,      // misaligned store data address
    input  wire             i_be_load,       // bus error on load data access
    input  wire             i_be_store       // bus error store data access   
);

    // Intermediate reg
    reg [XLEN-1:0]  ro_imm;

    // Instruction prefetch buffer (FIFO)
    localparam IPB_DATA_WIDTH = 2 + 16; // {bus_error, align_error, 16-bit instruciton}

    wire [1:0]                ibp_free;         // free entry
    wire [IPB_DATA_WIDTH-1:0] ipb_rdata [0:1];  // read data
    wire [1:0]                ibp_avail;        // data available
    wire [IPB_DATA_WIDTH-1:0] ipb_wdata [0:1];  // write data
    wire [1:0]                ipb_we;           // write enable
    wire [1:0]                ipb_re;           // read enable

    // Instruction issue (is)
    reg               is_align;
    reg               is_align_set;
    reg               is_align_clr;
    reg  [(3+32)-1:0] is_data; // 3-bit status + 32-bit instruction
    reg  [1:0]        is_valid; // data word is valid
    wire              is_ack;
    wire [15:0]       is_ci_i16;
    wire [31:0]       is_ci_i32;

    // Instruction fetch
    localparam IF_RESTART = 2'b00,
              IF_REQUEST = 2'b01,
              IF_PENDING = 2'b10;

    reg [1:0]       if_state;
    reg             if_restart;
    reg             if_unaligned;    
    reg [XLEN-1:2]  if_pc;
    wire            if_reset;
    wire            if_resp;    // bus response
    wire            if_a_err;   // alignment error

    // Instruction decode (id)
    reg        id_is_alr; // is atomic load reserve
    reg        id_is_asc; // is atomic store condition
    reg        id_is_fop; // is floating point instruction
    reg        id_is_mul; // is multiplication instruction
    reg        id_is_div; // is division instruction
    wire [6:0] id_opcode;
    wire       id_rs1_zero; // rs1 is zero
    wire       id_rd_zero;  // rd is zero

    // Instruction execution (ie)
    localparam IE_DISPATCH       = 4'b0000,
              IE_TRAP_ENTER     = 4'b0001,
              IE_TRAP_EXIT      = 4'b0010,
              IE_TRAP_EXECUTE   = 4'b0011,
              IE_FENCE          = 4'b0100,
              IE_SLEEP          = 4'b0101,
              IE_EXECUTE        = 4'b0110,
              IE_ALU_WAIT       = 4'b0111,
              IE_BRANCH         = 4'b1000,
              IE_BRANCHED       = 4'b1001,
              IE_SYSTEM         = 4'b1010,
              IE_MEM_REQ        = 4'b1011,
              IE_MEM_WAIT       = 4'b1100;
    
    reg  [3:0]      ie_state; 
    reg  [3:0]      ie_next; 
    reg  [31:0]     ie_ir; 
    reg             ie_is_ci; // current instruction is decompressed or not
    reg  [XLEN-1:0] ie_pc;
    reg             ie_pc_we;      // pc update enable
    reg  [XLEN-1:0] ie_next_pc;    // next PC
    reg             ie_branched; // increment to get next PC
    wire            ie_branch_taken;
    wire [XLEN-1:0] ie_next_pc_inc; // increment to get next PC
    wire            ie_pc_mux_sel; // source select for PC update

    // Trap controller (trap_ctrl)
    reg  [10:0]     trap_ctrl_exc_buf;       // synchronous exception buffer (one bit per exception)
    wire            trap_ctrl_exc_fire;      // set if there is a valid source in the exception buffer
    reg  [20:0]     trap_ctrl_irq_pnd;       // pending interrupt
    reg  [20:0]     trap_ctrl_irq_buf;       // asynchronous exception/interrupt buffer (one bit per interrupt source)
    wire             trap_ctrl_irq_fire;      // set if an interrupt is actually kicking in
    reg  [6:0]      trap_ctrl_cause;         // trap ID for mcause CSR & debug-mode entry identifier 
    wire [XLEN-1:0] trap_ctrl_epc;           // exception program counter
    reg             trap_ctrl_env_pending;   // start of trap environment if pending
    wire            trap_ctrl_env_enter;     // enter trap environment
    wire            trap_ctrl_env_exit;      // leave trap environment
    reg             trap_ctrl_wakeup;        // wakeup from sleep due to an enabled pending IRQ
    reg             trap_ctrl_instr_be;      // instruction fetch bus error
    reg             trap_ctrl_instr_ma;      // instruction fetch misaligned address
    wire            trap_ctrl_instr_il;      // illegal instruction
    reg             trap_ctrl_env_call;      // ecall instruction
    reg             trap_ctrl_break_point;   // ebreak instruction

    // CPU control signals
    reg             ctrl_rf_wb_en;    // write back enable
    reg [4:0]       ctrl_rf_rs1;      // source register 1 address
    reg [4:0]       ctrl_rf_rs2;      // source register 2 address
    reg [4:0]       ctrl_rf_rs3;      // source register 3 address
    reg [4:0]       ctrl_rf_rd;       // destination register address
    reg [1:0]       ctrl_rf_mux;      // input source select
    reg             ctrl_rf_zero_we;  // allow/force write access to x0

    reg [2:0]       ctrl_alu_op;      // ALU operation select
    reg             ctrl_alu_opa_mux; // operand A select (0=rs1; 1=PC)
    reg             ctrl_alu_opb_mux; // operand B select (0=rs2; 1=IMM)
    reg             ctrl_alu_unsigned;// is unsigned ALU operation
    reg [4:0]       ctrl_alu_cp_trig; // co-processor trigger (one-hot)

    reg             ctrl_lsu_req_rd;  // trigger memory read request
    reg             ctrl_lsu_req_wr;  // trigger memory write request
    reg             ctrl_lsu_rw;      // 0: read access; 1: write access
    // reg             ctrl_lsu_mo_we;   // memory address and data output register write enable
    reg             ctrl_lsu_fence;   // fence operation
    reg             ctrl_lsu_fencei;  // fence.i operation
    // reg             ctrl_lsu_priv;    // effective privilege level for load/store

    // reg [2:0]       ctrl_ir_funct3;   // funct3 bit field
    // reg [11:0]      ctrl_ir_funct12;  // funct12 bit field
    // reg [6:0]       ctrl_ir_opcode;   // opcode bit field

    // reg             ctrl_cpu_priv;    // effective privilege mode
    // reg             ctrl_cpu_sleep;   // set when CPU is in sleep mode
    // reg             ctrl_cpu_trap;    // set when CPU is entering trap exec
    // reg             ctrl_cpu_debug;   // set when CPU is in debug mode

    // Instruction monitor (monitor): raise exception if multi-cycle operation times out (default = 512-cycle)
    reg [9:0]       monitor_cnt;
    wire [9:0]      monitor_cnt_add;
    wire            monitor_exc;

    // hardware trigger module
    wire            hw_trigger_fire;

    // Control and status register (CSR)
    wire [11:0]      csr_addr;               // csr address
    wire [11:0]      csr_raddr;              // simplified csr read address
    wire [XLEN-1:0]  csr_wdata;              // csr write
    reg [XLEN-1:0]   csr_rdata;              // read data  
    reg              csr_we;                 // csr write enable
    reg              csr_re;                 // csr read enable

    reg             csr_mstatus_mie;        // machine-mode IRQ enable
    reg             csr_mstatus_mpie;       // previous machine-mode IRQ enable
    reg             csr_mstatus_mpp;        // machine previous privilege mode
    reg             csr_mstatus_mprv;       // effective privilege level for machine-mode load/stores
    reg             csr_mstatus_tw;         // do not allow user mode to execute WFI instruction when set
    reg             csr_mie_msi;            // machine software interrupt enable
    reg             csr_mie_mei;            // machine external interrupt enable
    reg             csr_mie_mti;            // machine timer interrupt enable
    reg [15:0]      csr_mie_firq;           // fast interrupt enable
    reg [15:0]      csr_mip_firq_nclr;      // clear pending FIRQ (active-low)
    reg             csr_privilege;          // current privilege mode
    wire            csr_privilege_eff;      // current *effective* privilege mode
    reg [XLEN-1:0]  csr_mepc;               // machine exception PC
    reg [5:0]       csr_mcause;             // machine trap cause
    reg [XLEN-1:0]  csr_mtvec;              // machine trap-handler base address
    reg [XLEN-1:0]  csr_mtval;              // machine bad address or instruction
    reg [XLEN-1:0]  csr_mtinst;             // machine trap instruction
    reg [XLEN-1:0]  csr_mscratch;           // machine scratch register
    reg             csr_mcounteren;         // machine counter access enable (from user-mode)
    reg [15:0]      csr_mcountinhibit;      // inhibit counter auto-increment
    reg             csr_mcyclecfg_minh;     // inhibit cycle counter when in machine-mode
    reg             csr_mcyclecfg_uinh;     // inhibit cycle counter when in user-mode
    reg             csr_minstretcfg_minh;   // inhibit instret counter when in machine-mode
    reg             csr_minstretcfg_uinh;   // inhibit instret counter when in user-mode
    reg             csr_dcsr_ebreakm;       // behavior of ebreak instruction in m-mode
    reg             csr_dcsr_ebreaku;       // behavior of ebreak instruction in u-mode
    reg             csr_dcsr_step;          // single-step mode
    reg             csr_dcsr_prv;           // current privilege level when entering debug mode
    reg [2:0]       csr_dcsr_cause;         // why was debug mode entered
    wire [XLEN-1:0] csr_dcsr_rd;            // debug mode control and status register
    reg [XLEN-1:0]  csr_dpc;                // mode program counter
    reg [XLEN-1:0]  csr_dscratch0;          // debug mode scratch register 0
    reg             csr_tdata1_exe;         // enable (match) trigger
    reg             csr_tdata1_action;      // enter debug mode / ebreak exception when trigger fires
    reg             csr_tdata1_dmode;       // set to ignore tdata* CSR access from machine-mode
    wire [XLEN-1:0] csr_tdata1_rd;          // trigger register read-back
    reg [XLEN-1:0]  csr_tdata2;             // address-match register

    // CSR access/privilege/read-write check
    reg             csr_reg_valid;          // CSR implemented at all
    reg             csr_rw_valid;           // valid r/w access rights
    reg             csr_priv_valid;         // valid access privilege

    // CSR read-back data
    reg [XLEN-1:0]  tcsr_rdata;
    wire [XLEN-1:0] xcsr_rdata;


    // Debug module controller (dbg)
    reg             dbg_running;            // CPU is in debug mode
    reg             dbg_ext_halt_req;       // external halt request buffer
    wire            dbg_trig_hw;            // hardware trigger
    wire            dbg_trig_break;         // ebreak instruction trigger
    wire            dbg_trig_halt;          // external request trigger
    wire            dbg_trig_step;          // single-stepping mode trigger


    // Illegal instruction check
    wire         illegal_cmd;

    // Instruction extract
    wire [6:0]   ir_opcode;
    wire [4:0]   ir_rd;
    wire [4:0]   ir_rs1;
    wire [4:0]   ir_rs2;
    wire [4:0]   ir_rs3;
    wire [2:0]   ir_funct3;
    wire [4:0]   ir_funct5;
    wire [6:0]   ir_funct7;
    wire [11:0]  ir_funct12;
    wire [11:0]  ir_imm12;
    wire [19:0]  ir_imm20;


//=================================================================================================================
// Instruction extract
//================================================================================================================= 
    assign  ir_opcode   = ie_ir[6:0];
    assign  ir_rd       = ie_ir[11:7];
    assign  ir_rs1      = ie_ir[19:15];
    assign  ir_rs2      = ie_ir[24:20];
    assign  ir_rs3      = ie_ir[31:27];
    assign  ir_funct3   = ie_ir[14:12];
    assign  ir_funct5   = ie_ir[31:27];
    assign  ir_funct7   = ie_ir[31:25];
    assign  ir_funct12  = ie_ir[31:20];
    assign  ir_imm12    = ie_ir[31:20];
    assign  ir_imm20    = ie_ir[31:12];

    assign  illegal_cmd = 1'b0;
//=================================================================================================================
// Instruction Fetch (always fetch 32-bit-aligned 32-bit chunks of data)
//================================================================================================================= 
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            if_state        <= IF_RESTART;
            if_restart      <= 1'b1; // set to reset IPB
            if_unaligned    <= 1'b0; // always start at aligned address after reset
            if_pc           <= {XLEN{1'b0}};
        end
        else begin
            if (if_state == IF_RESTART) if_restart <= 1'b0;
            else if_restart <= if_restart || if_reset;

            case (if_state)
                IF_RESTART: begin // set new fetch start address
                    if_pc        <= ie_pc[XLEN-1:2]; // initialize with logical PC, word aligned
                    if_unaligned <= ie_pc[1];
                    if_state     <= IF_REQUEST;
                end
                IF_REQUEST: begin // request new 32-bit-aligned instruction word
                    if (ibp_free == 2'b11) if_state <= IF_PENDING;
                end
                IF_PENDING: begin // wait for bus response and write instruction data to prefetch buffer
                    if (if_resp) begin // wait for bus response
                        if_pc <= if_pc + 1'b1;
                        if_unaligned <= 1'b0;

                        if (if_restart || if_reset) // restart request (fast) due to branch
                            if_state <= IF_RESTART;
                        else
                            if_state <= IF_REQUEST;
                    end
                end
                default: if_state <= IF_RESTART;
            endcase
        end
    end

    // PC output for instruction fetch
    assign o_bus_req_addr   = {if_pc, 2'b00};
    assign o_fetch_pc       = {if_pc, 2'b00};

    // Instruction fetch (read) request if IPB not full
    assign o_bus_req_re     = (if_state == IF_REQUEST) && (ibp_free == 2'b11);

    // Unaligned access error (no alignment exceptions possible when using C-extension)
    assign if_a_err = if_unaligned && (CPU_EXTENSION_RISCV_C == 0);

    // Instruction bus response
    // PMP and alignment errors will keep pending until the triggered bus access request retires
    assign if_reset = (ie_state == IE_TRAP_EXECUTE) || ((ie_state == IE_BRANCH) && (ir_opcode[2] || ie_branch_taken));
    assign if_resp = i_bus_rsp_ack || i_bus_rsp_err;

    // IPB instruction data and status
    assign ipb_wdata[0] = {i_bus_rsp_err || i_pmp_fault, if_a_err, i_bus_rsp_data[15:0]};
    assign ipb_wdata[1] = {i_bus_rsp_err || i_pmp_fault, if_a_err, i_bus_rsp_data[31:16]};

    // IPB write enable
    assign ipb_we[0] = (if_state == IF_PENDING) && if_resp &&
                       (!if_unaligned || (CPU_EXTENSION_RISCV_C == 0));
    assign ipb_we[1] = (if_state == IF_PENDING) && if_resp;

    // Bus access type
    assign o_bus_req_priv = 1'b0;
    assign o_bus_req_data = {XLEN{1'b0}}; // read only
    assign o_bus_req_ben  = 4'b0000; // read only
    assign o_bus_req_we   = 1'b0; // read only
    assign o_bus_req_src  = 1'b1; // instruction fetch
    assign o_bus_req_rvso = 1'b0; // cannot be a reservation set operation

///=================================================================================================================
// Instruction Prefetch Buffer (FIFO)
//=================================================================================================================
    ip_fifo #(
        .FIFO_DEPTH (INSTR_BUFFER_DEPTH ), // number of fifo entries; has to be a power of two; min 1
        .FIFO_WIDTH (IPB_DATA_WIDTH     ), // size of data elements in fifo
        .FIFO_RSYNC (0                  ), // 0 = async read; 1 = sync read
        .FIFO_SAFE  (0                  )  // 1 = allow read/write only if entry available  -- -------------------------------------------------------------------------------------------
    ) prefetch_buffer0 
    (
        // Global control
        .i_clk      ( i_clk        ),   // global clock, rising edge
        .i_rstn     ( i_rstn       ),  // global reset, low-active, async
        // Control signal
        .i_clear    ( if_restart   ), // sync reset, high-active
        .o_half     (              ),  // FIFO is half full
        // Write port
        .i_wdata    ( ipb_wdata[0] ), // write data
        .i_we       ( ipb_we[0]    ),    // write enable
        .o_free     ( ibp_free[0]  ),  // at least one entry is free when set
        // Read port
        .i_re       ( ipb_re[0]    ),    // read enable
        .o_rdata    ( ipb_rdata[0] ), // read data
        .o_avail    ( ibp_avail[0] )  // data available when set
    );

    ip_fifo #(
        .FIFO_DEPTH (INSTR_BUFFER_DEPTH ), // number of fifo entries; has to be a power of two; min 1
        .FIFO_WIDTH (IPB_DATA_WIDTH     ), // size of data elements in fifo
        .FIFO_RSYNC (0                  ), // 0 = async read; 1 = sync read
        .FIFO_SAFE  (0                  )  // 1 = allow read/write only if entry available
    ) prefetch_buffer1 
    (
        // Global control
        .i_clk      ( i_clk        ),   // global clock, rising edge
        .i_rstn     ( i_rstn       ),  // global reset, low-active, async
        // Control signal
        .i_clear    ( if_restart   ), // sync reset, high-active
        .o_half     (              ),  // FIFO is half full
        // Write port
        .i_wdata    ( ipb_wdata[1] ), // write data
        .i_we       ( ipb_we[1]    ),    // write enable
        .o_free     ( ibp_free[1]  ),  // at least one entry is free when set
        // Read port
        .i_re       ( ipb_re[1]    ),    // read enable
        .o_rdata    ( ipb_rdata[1] ), // read data
        .o_avail    ( ibp_avail[1] )  // data available when set
    );

    assign ipb_re[0] = is_valid[0] && is_ack;
    assign ipb_re[1] = is_valid[1] && is_ack;

//=================================================================================================================
// Instruction Issue (decompress 16-bit instructions and assemble a 32-bit instruction word)
//=================================================================================================================

    // Compressed Instruction decode
    generate
        if (CPU_EXTENSION_RISCV_C == 1) begin: gen_decompressor
            rv32_cpu_decompressor #(
                .FPU_ENABLE ((CPU_EXTENSION_RISCV_F == 1) || (CPU_EXTENSION_RISCV_D == 1))
            ) rv32_cpu_decompressor_inst (
                .i_instr16  (is_ci_i16), // compressed instruction
                .o_instr32  (is_ci_i32)  // decompressed instruction
            );

            always @(posedge i_clk) begin
                if (if_restart) 
                    is_align <=  ie_pc[1]; // branch to unaligned address?
                else if (is_ack)
                    is_align <= (is_align && !is_align_clr) || is_align_set; // "RS" flip-flop
            end

            always @(*) begin
                is_align_set = 1'b0;
                is_align_clr = 1'b0;
                is_valid     = 2'b00;
                // Start with LOW half-word --
                if (!is_align) begin
                    if (ipb_rdata[0][1:0] != 2'b11) begin // compressed
                        is_align_set = ibp_avail[0]; // start of next instruction word is NOT 32-bit-aligned
                        is_valid[0]  = ibp_avail[0];
                        is_data      = {ipb_rdata[0][17:16], 1'b1, is_ci_i32};
                    end
                    else begin // aligned uncompressed; use IPB(0) status flags only
                        is_valid     = {2{ibp_avail[1] && ibp_avail[0]}};
                        is_data      = {ipb_rdata[0][17:16], 1'b0, ipb_rdata[1][15:0], ipb_rdata[0][15:0]};
                    end
                end
                else begin
                    if (ipb_rdata[1][1:0] != 2'b11) begin // compressed
                        is_align_clr = ibp_avail[1]; // start of next instruction word is 32-bit-aligned again
                        is_valid[1]  = ibp_avail[1];
                        is_data      = {ipb_rdata[1][17:16], 1'b1, is_ci_i32};
                    end
                    else begin // aligned uncompressed; use IPB(0) status flags only
                        is_valid     = {2{ibp_avail[1] && ibp_avail[0]}};
                        is_data      = {ipb_rdata[0][17:16], 1'b0, ipb_rdata[0][15:0], ipb_rdata[1][15:0]};
                    end
                end
            end
        end
        else begin: gen_ncompress
            assign is_ci_i32 = 32'd0;

            always @(*) begin
                is_align_clr = 1'b0;
                is_valid = {2{ibp_avail[0]}};
                is_data  = {ipb_rdata[0][17:16], 1'b0, ipb_rdata[1][15:0], ipb_rdata[0][15:0]};
            end
        end
    endgenerate 

    assign is_ack    = (ie_state == IE_DISPATCH) &&
                       (is_valid[0] || is_valid[1]) &&
                       (!trap_ctrl_env_pending && !trap_ctrl_exc_fire);

    assign is_ci_i16 = is_align? ipb_rdata[1][15:0]: ipb_rdata[0][15:0];


//=================================================================================================================
// Instruction Execution
//=================================================================================================================
    // Immediate Generator
    always @(posedge i_clk) begin
        case (id_opcode)
            `OP_STORE: begin // S-immediate: store
                ro_imm[31:11]   <= {21{ie_ir[31]}}; // sign extend
                ro_imm[10:5]    <= ie_ir[30:25];
                ro_imm[4:0]     <= ie_ir[11:7];
            end
            `OP_BRANCH: begin // B-immediate: conditional branch
                ro_imm[31:12]   <= {20{ie_ir[31]}}; // sign extend
                ro_imm[11]      <= ie_ir[7];
                ro_imm[10:5]    <= ie_ir[30:25];
                ro_imm[4:1]     <= ie_ir[11:8];
                ro_imm[0]       <= 1'b0;
            end
            `OP_LUI: begin // U-immediate: lui, auipc
                ro_imm[31:12]   <= ie_ir[31:12];
                ro_imm[11:0]    <= 12'h000;
            end
            `OP_AUIPC: begin // U-immediate: lui, auipc
                ro_imm[31:12]   <= ie_ir[31:12];
                ro_imm[11:0]    <= 12'h000;
            end
            `OP_JAL: begin // J-immediate: unconditional jump
                ro_imm[31:20]   <= {12{ie_ir[31]}}; // sign extend
                ro_imm[19:12]   <= ie_ir[19:12];
                ro_imm[11]      <= ie_ir[20];
                ro_imm[10:1]    <= ie_ir[30:21];
                ro_imm[0]       <= 1'b0;
            end
            default: begin
                if ((id_opcode == `OP_AMO) && (CPU_EXTENSION_RISCV_A == 1))
                    ro_imm <= 32'd0;
                else begin
                    ro_imm[31:11]   <= {21{ie_ir[31]}}; // sign extension
                    ro_imm[10:1]    <= ie_ir[30:21];
                    ro_imm[0]       <= ie_ir[20];
                end
            end
        endcase
    end

    assign o_imm = ro_imm;



    // Execute FSM
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) ie_state <= IE_BRANCH;
        else ie_state <= ie_next;
    end

    always @(*) begin
        case (ie_state)
            IE_DISPATCH:
                if (is_valid[0] || is_valid[1]) begin // new instruction word available
                    if (trap_ctrl_env_pending || trap_ctrl_exc_fire) // pending trap
                        ie_next = IE_TRAP_ENTER;
                    else // normal execution
                        ie_next = IE_EXECUTE;
                end
                else ie_next = IE_DISPATCH;
            IE_TRAP_ENTER: // Enter trap environment and get trap vector
                if (trap_ctrl_env_pending)
                    ie_next = IE_TRAP_EXECUTE;
                else
                    ie_next = IE_TRAP_ENTER;
            IE_TRAP_EXIT: // Return from trap environment and get xEPC
                ie_next = IE_TRAP_EXECUTE;
            IE_TRAP_EXECUTE:
                ie_next = IE_BRANCHED;
            IE_FENCE: // memory fence
                if (trap_ctrl_exc_buf[`EXC_ILLEGAL]) // abort if illegal instruction
                    ie_next = IE_DISPATCH;
                else if ((ir_funct3 == `FUNCT3_FENCEI) && (CPU_EXTENSION_RISCV_Zifencei == 1))
                    ie_next = IE_TRAP_EXECUTE; // used to flush instruction prefetch buffer
                else
                    ie_next = IE_DISPATCH;
            IE_SLEEP:
                if (dbg_running || csr_dcsr_step || trap_ctrl_wakeup)
                    ie_next = IE_DISPATCH;
                else
                    ie_next = IE_SLEEP;
            IE_EXECUTE: // Decode and execute instruction (control has to be here for exactly 1 cycle in any case!)
                case (id_opcode)
                    `OP_ALU:
                        if ((id_is_mul || id_is_div) && ir_opcode[5] && (FAST_MUL_EN == 0)) // MUL/DIV
                            ie_next = IE_ALU_WAIT;
                        else if ((FAST_SHIFT_EN == 0) && ((ir_funct3 == `FUNCT3_SLL) || (ir_funct3 == `FUNCT3_SR))) // SLL/SRL
                            ie_next = IE_ALU_WAIT;
                        else ie_next = IE_DISPATCH;
                    `OP_ALUI:
                        if ((id_is_mul || id_is_div) && ir_opcode[5] && (FAST_MUL_EN == 0)) // MUL/DIV
                            ie_next = IE_ALU_WAIT;
                        else if ((FAST_SHIFT_EN == 0) && ((ir_funct3 == `FUNCT3_SLL) || (ir_funct3 == `FUNCT3_SR))) // SLL/SRL
                            ie_next = IE_ALU_WAIT;
                        else ie_next = IE_DISPATCH;
                    `OP_LUI     : ie_next = IE_DISPATCH;
                    `OP_AUIPC   : ie_next = IE_DISPATCH;
                    `OP_STORE   : ie_next = IE_MEM_REQ; 
                    `OP_LOAD    : ie_next = IE_MEM_REQ;
                    `OP_AMO     : ie_next = IE_MEM_REQ;
                    `OP_BRANCH  : ie_next = IE_BRANCH;
                    `OP_JAL     : ie_next = IE_BRANCH;
                    `OP_JALR    : ie_next = IE_BRANCH;
                    `OP_FENCE   : ie_next = IE_FENCE;
                    `OP_FOP     :
                        if ((CPU_EXTENSION_RISCV_F == 1) || (CPU_EXTENSION_RISCV_D == 1)) // Floating point extension
                            ie_next = IE_ALU_WAIT;
                        else
                            ie_next = IE_DISPATCH;
                    `OP_CUST0   : ie_next = IE_ALU_WAIT;
                    `OP_CUST1   : ie_next = IE_ALU_WAIT;
                    `OP_CUST2   : ie_next = IE_ALU_WAIT;
                    `OP_CUST3   : ie_next = IE_ALU_WAIT;
                    default     : ie_next = IE_SYSTEM;    
                endcase
            IE_ALU_WAIT:    
                    if (i_alu_cp_done || trap_ctrl_exc_buf[`EXC_ILLEGAL])
                        ie_next = IE_DISPATCH;
                    else
                        ie_next = IE_ALU_WAIT;
            IE_BRANCH:
                    if (ir_opcode[2] || ie_branch_taken) // JAL[R] or taken branch
                        ie_next = IE_BRANCHED;
                    else
                        ie_next = IE_DISPATCH;
            IE_BRANCHED: ie_next = IE_DISPATCH;

            IE_MEM_REQ: // trigger memory request
                if (trap_ctrl_exc_buf[`EXC_ILLEGAL]) // abort if illegal instruction
                    ie_next = IE_DISPATCH;
                else
                    ie_next = IE_MEM_WAIT;
            IE_MEM_WAIT: // wait for bus transaction to finish
                if (trap_ctrl_exc_buf[`EXC_LACCESS] || trap_ctrl_exc_buf[`EXC_SACCESS] ||   // bus access error
                    trap_ctrl_exc_buf[`EXC_LALIGN]  || trap_ctrl_exc_buf[`EXC_SALIGN])      // alignment error
                    ie_next = IE_DISPATCH;
                else if (i_lsu_wait) // bus sysytem has completed the transaction
                    ie_next = IE_DISPATCH;
                else
                    ie_next = IE_MEM_WAIT; // wait until the memory access completed
            default: // SYSTEM - system environment operation; no effect if illegal instruction
                if ((ir_funct3 == `FUNCT3_ENV) && !trap_ctrl_exc_buf[`EXC_ILLEGAL]) begin // environemnt and illegal
                    if ((ir_funct12 == `FUNCT12_MRET) || (ir_funct12 == `FUNCT12_DRET))
                        ie_next = IE_TRAP_EXIT;
                    else
                        ie_next = IE_SLEEP; // wfi/sleep
                end
                else ie_next = IE_DISPATCH;
        endcase
    end



    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            ie_branched <= 1'b0;
            ie_ir       <= 32'd0;
            ie_is_ci    <= 1'b0;
            ie_pc       <= {CPU_BOOT_ADR[XLEN-1:2], 2'b00};
            ie_next_pc <= 32'd0;  
        end
        else begin
            // ie_branched
            if (ie_state == IE_EXECUTE) 
                ie_branched <= 1'b0; // clear branch flipflop
            else if (ie_state == IE_BRANCHED) 
                ie_branched <= 1'b1; // actual branch
            else
                ie_branched <= ie_branched;

            // ie_ir
            if ((ie_state == IE_DISPATCH) && (is_valid[0] || is_valid[1]) 
                && !trap_ctrl_env_pending && !trap_ctrl_exc_fire)
                ie_ir <= is_data;

            // ie_is_ci
            if ((ie_state == IE_DISPATCH) && (is_valid[0] || is_valid[1]) 
                && !trap_ctrl_env_pending && !trap_ctrl_exc_fire)
                ie_is_ci <= is_data[32];
            
            // PC update
            if(ie_pc_we) begin
                ie_pc <= ie_pc_mux_sel? {i_alu_addr[XLEN-1:1], 1'b0}: // jump/take-branch
                                        {ie_next_pc[XLEN-1:1], 1'b0}; // next (linear) instruction address
            end

            // Next PC
            case (ie_state)
                IE_TRAP_ENTER:
                    if ((CPU_EXTENSION_RISCV_Sdext == 1) && trap_ctrl_cause[5]) // trap cause: debug mode (re-)entry
                        ie_next_pc <= CPU_DEBUG_PARK_ADDR; // debug mode enter; start at "parking loop" <normal_entry>
                    else if ((CPU_EXTENSION_RISCV_Sdext == 1) && dbg_running) // any other trap INSIDE debug mode
                        ie_next_pc <= CPU_DEBUG_EXC_ADDR; // debug mode enter: start at "parking loop" <exception_entry>
                    else // normal start of trap
                        if ((csr_mtvec[1:0] == 2'b01) && trap_ctrl_cause[6]) // vectored mode + interrupt
                            ie_next_pc <= {csr_mtvec[XLEN-1:7], trap_ctrl_cause[4:0], 2'b00}; // pc = mtvec + 4 * mcause
                        else
                            ie_next_pc <= {csr_mtvec[XLEN-1:2], 2'b00};
                IE_TRAP_EXIT:
                    if ((CPU_EXTENSION_RISCV_Sdext == 1) && dbg_running) // -- debug mode exit
                        ie_next_pc <= {csr_dpc[XLEN-1:1], 1'b0};
                    else // normal end of trap
                        ie_next_pc <= {csr_mepc[XLEN-1:1], 1'b0};
                IE_EXECUTE:
                    ie_next_pc <= ie_pc + ie_next_pc_inc;  // next linear PC
                IE_BRANCHED:
                    ie_next_pc <= {ie_pc[XLEN-1:0], 1'b0}; // get updated PC
                default: ie_next_pc <= ie_next_pc;
            endcase 
        end
    end

    always @(*) begin
        case (ie_state)
            IE_DISPATCH:
                if (is_valid[0] || is_valid[1]) begin // new instruction word available
                    if (trap_ctrl_env_pending || trap_ctrl_exc_fire) // pending trap
                        ie_pc_we = 1'b0;
                    else // normal execution
                        ie_pc_we = !ie_branched;
                end
                else ie_pc_we = 1'b0;    
            IE_TRAP_EXECUTE: ie_pc_we = 1'b1;
            IE_BRANCH: ie_pc_we = !trap_ctrl_exc_buf[`EXC_ILLEGAL]; // update PC with branch DST; will be overridden in DISPATCH if branch not taken
            default: ie_pc_we = 1'b0;
        endcase
    end



    assign ie_pc_mux_sel = (ie_state == IE_BRANCH); // PC <= alu.add = branch/jump destination

    // PC increment for next linear instruction (+2 for compressed instr., +4 otherwise) --
    assign ie_next_pc_inc[XLEN-1:4] = {28{1'b0}};
    assign ie_next_pc_inc[3:0]      = (ie_is_ci && (CPU_EXTENSION_RISCV_C == 1))? 4'd2: 4'd4;

    // Branch Condition Check (eq: beq / bne, lt: blt(u) / bge(u))
    assign ie_branch_taken = ir_funct3[0] ^ (!ir_funct3[2]? i_cmp_eq: i_cmp_lt); 

    // PC output
    assign o_curr_pc = {ie_pc[XLEN-1:1], 1'b0};
    assign o_next_pc = {ie_next_pc[XLEN-1:1], 1'b0}; 

//=================================================================================================================
// Instruction Decode
//=================================================================================================================
    always @(*) begin
        // Atomic LR/SC
        if ((CPU_EXTENSION_RISCV_A == 1) && (ir_funct3 == 3'b010) && (ir_funct7[6:3] == 4'b0001)) begin
            id_is_alr = !ir_funct7[2]; // LR.W
            id_is_asc = ir_funct7[2]; // SC.W
        end
        else begin
            id_is_alr = 1'b0;
            id_is_asc = 1'b0;
        end
        // Floating point operations (single/double)
        if ((CPU_EXTENSION_RISCV_F == 1) || (CPU_EXTENSION_RISCV_D == 1))
            id_is_fop = ((ir_funct7[1:0] == `FLOAT_SINGLE) || (ir_funct7[1:0] == `FLOAT_DOUBLE)) &&
                        ((ir_funct7[6:3] == 4'b0000)  || // FADD.S / FSUB.S
                        (ir_funct7[6:2] == 5'b00010) || // FMUL.S
                        ((ir_funct7[6:2] == 5'b11100) && (ir_funct3 == 3'b001))  || // FCLASS.S
                        ((ir_funct7[6:2] == 5'b00100) && (ir_funct3[2] == 1'b0)) || // FSGNJ[N/X].s
                        ((ir_funct7[6:2] == 5'b00101) && (ir_funct3[2:1] == 2'b00)) || // FMIN.S / FMAX.S
                        ((ir_funct7[6:2] == 5'b10100) && (ir_funct3[2] == 1'b0)) || // FEQ.S / FLT.S / FLE.S
                        ((ir_funct7[6:2] == 5'b11010) && (ir_funct12[4:1] == 4'b0000)));// FCVT.S.W*csr_rdata

        // Multiplication/Division
        if ((CPU_EXTENSION_RISCV_M == 1) || (CPU_EXTENSION_RISCV_Zmmul == 1)) begin
            id_is_mul = (ir_funct7 == 7'b0000001) && (ir_funct3[2] == 1'b0);
        
            if (CPU_EXTENSION_RISCV_M == 1)
                id_is_div = (ir_funct7 == 7'b0000001) && (ir_funct3[2] == 1'b1);
            else
                id_is_div = 1'b0;
        end
        else begin
            id_is_mul = 1'b0;
            id_is_div = 1'b0;
        end
    end

    assign id_opcode    = {ir_opcode[6:2], 2'b11};
    assign id_rs1_zero  = ir_rs1 == 5'b00000;
    assign id_rd_zero   = ir_rd  == 5'b00000;

//=================================================================================================================
// Trap controller
//=================================================================================================================
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            trap_ctrl_exc_buf <= 11'd0;
            trap_ctrl_irq_pnd <= 21'd0;
            trap_ctrl_irq_buf <= 21'd0;
            trap_ctrl_env_pending <= 1'b0;
            trap_ctrl_wakeup <= 1'b0;
        end
        else begin
            // Exception Buffer -----------------------------------------------------
            // If several exception sources trigger at once, all the requests will
            // stay active until the trap environment is started. Only the exception
            // with highest priority will be used to update the MCAUSE CSR. All
            // remaining ones will be discarded.
            // ----------------------------------------------------------------------
            
            // Misaligned load/store/instruction address --
            trap_ctrl_exc_buf[`EXC_LALIGN] <= (trap_ctrl_exc_buf[`EXC_LALIGN] || i_ma_load)  && !trap_ctrl_env_enter;
            trap_ctrl_exc_buf[`EXC_SALIGN] <= (trap_ctrl_exc_buf[`EXC_SALIGN] || i_ma_store) && !trap_ctrl_env_enter;
            trap_ctrl_exc_buf[`EXC_IALIGN] <= (trap_ctrl_exc_buf[`EXC_IALIGN] || trap_ctrl_instr_ma) && !trap_ctrl_env_enter;

            // load/store/instruction bus access fault
            trap_ctrl_exc_buf[`EXC_LACCESS] <= (trap_ctrl_exc_buf[`EXC_LACCESS] || i_be_load)  && !trap_ctrl_env_enter;
            trap_ctrl_exc_buf[`EXC_SACCESS] <= (trap_ctrl_exc_buf[`EXC_SACCESS] || i_be_store) && !trap_ctrl_env_enter;
            trap_ctrl_exc_buf[`EXC_IACCESS] <= (trap_ctrl_exc_buf[`EXC_IACCESS] || trap_ctrl_instr_be) && !trap_ctrl_env_enter;

            // illegal instruction & environment call
            trap_ctrl_exc_buf[`EXC_ECALL] <= (trap_ctrl_exc_buf[`EXC_ECALL]     || trap_ctrl_env_call)  && !trap_ctrl_env_enter;
            trap_ctrl_exc_buf[`EXC_ILLEGAL] <= (trap_ctrl_exc_buf[`EXC_ILLEGAL] || trap_ctrl_instr_il)  && !trap_ctrl_env_enter;

            // break point
            if (CPU_EXTENSION_RISCV_Sdext == 1) begin
                trap_ctrl_exc_buf[`EXC_EBREAK] <= !trap_ctrl_env_enter &&
                                                ( trap_ctrl_exc_buf[`EXC_EBREAK] ||
                                                (hw_trigger_fire && !csr_tdata1_action) || // trigger module fires and enter-debug is disabled
                                                (trap_ctrl_break_point &&  csr_privilege && !csr_dcsr_ebreakm && !dbg_running) || // enter M-mode handler on ebreak in M-mode  
                                                (trap_ctrl_break_point && !csr_privilege && !csr_dcsr_ebreakm && !dbg_running));  // enter M-mode handler on ebreak in U-mode
            end
            else begin
                trap_ctrl_exc_buf[`EXC_EBREAK] <= (trap_ctrl_exc_buf[`EXC_EBREAK] || trap_ctrl_break_point || hw_trigger_fire) && !trap_ctrl_env_enter;
            end

            // Debug-mode entry  
            if (CPU_EXTENSION_RISCV_Sdext == 1) begin
                trap_ctrl_exc_buf[`EXC_DB_BREAK] <= (trap_ctrl_exc_buf[`EXC_DB_BREAK]  || dbg_trig_break) && !trap_ctrl_env_enter;
                trap_ctrl_exc_buf[`EXC_DB_HW]    <= (trap_ctrl_exc_buf[`EXC_DB_HW]     || dbg_trig_hw   ) && !trap_ctrl_env_enter;
            end
            else begin
                trap_ctrl_exc_buf[`EXC_DB_BREAK] <= 1'b0;
                trap_ctrl_exc_buf[`EXC_DB_HW]    <= 1'b0;
            end
            // Once triggered the fast interrupt requests stay active until
            // explicitly cleared via the MIP CSR. The RISC-V standard interrupts
            // have to stay high until cleared by a platform-specific mechanism.
            // ----------------------------------------------------------------------
            
            // RISC-V machine interrupts --
            trap_ctrl_irq_pnd[`IRQ_MSI] <= i_msi;
            trap_ctrl_irq_pnd[`IRQ_MEI] <= i_mei;
            trap_ctrl_irq_pnd[`IRQ_MTI] <= i_mti;

            // Fast interrupts
            trap_ctrl_irq_pnd[`IRQ_FIRQ0] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ0] && csr_mip_firq_nclr[0]) || i_firq[0];
            trap_ctrl_irq_pnd[`IRQ_FIRQ1] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ1] && csr_mip_firq_nclr[1]) || i_firq[1];
            trap_ctrl_irq_pnd[`IRQ_FIRQ2] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ2] && csr_mip_firq_nclr[2]) || i_firq[2];
            trap_ctrl_irq_pnd[`IRQ_FIRQ3] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ3] && csr_mip_firq_nclr[3]) || i_firq[3];
            trap_ctrl_irq_pnd[`IRQ_FIRQ4] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ4] && csr_mip_firq_nclr[4]) || i_firq[4];
            trap_ctrl_irq_pnd[`IRQ_FIRQ5] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ5] && csr_mip_firq_nclr[5]) || i_firq[5];
            trap_ctrl_irq_pnd[`IRQ_FIRQ6] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ6] && csr_mip_firq_nclr[6]) || i_firq[6];
            trap_ctrl_irq_pnd[`IRQ_FIRQ7] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ7] && csr_mip_firq_nclr[7]) || i_firq[7];
            trap_ctrl_irq_pnd[`IRQ_FIRQ8] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ8] && csr_mip_firq_nclr[8]) || i_firq[8];
            trap_ctrl_irq_pnd[`IRQ_FIRQ9] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ9] && csr_mip_firq_nclr[9]) || i_firq[9];
            trap_ctrl_irq_pnd[`IRQ_FIRQ10] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ10] && csr_mip_firq_nclr[10]) || i_firq[10];
            trap_ctrl_irq_pnd[`IRQ_FIRQ11] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ11] && csr_mip_firq_nclr[11]) || i_firq[11];
            trap_ctrl_irq_pnd[`IRQ_FIRQ12] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ12] && csr_mip_firq_nclr[12]) || i_firq[12];
            trap_ctrl_irq_pnd[`IRQ_FIRQ13] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ13] && csr_mip_firq_nclr[13]) || i_firq[13];
            trap_ctrl_irq_pnd[`IRQ_FIRQ14] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ14] && csr_mip_firq_nclr[14]) || i_firq[14];
            trap_ctrl_irq_pnd[`IRQ_FIRQ15] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ15] && csr_mip_firq_nclr[15]) || i_firq[15];

            // Debug mode entry
            trap_ctrl_irq_pnd[`IRQ_DB_HALT] <= 1'b0;
            trap_ctrl_irq_pnd[`IRQ_DB_STEP] <= 1'b0;

            // Interrupt Masking Buffer ---------------------------------------------
            // Masking of interrupt request lines. Furthermore, this buffer ensures
            // that an *active* interrupt request line *stays* active (even if
            // disabled via MIE) if the trap environment is *currently* starting.
            // ----------------------------------------------------------------------

            // RISC-V machine interrupts --
            trap_ctrl_irq_buf[`IRQ_MSI] <= (trap_ctrl_irq_pnd[`IRQ_MSI] && csr_mie_msi) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_MSI]);
            trap_ctrl_irq_buf[`IRQ_MEI] <= (trap_ctrl_irq_pnd[`IRQ_MEI] && csr_mie_mei) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_MEI]);
            trap_ctrl_irq_buf[`IRQ_MTI] <= (trap_ctrl_irq_pnd[`IRQ_MTI] && csr_mie_mti) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_MTI]);

            // Fast interrupts
            trap_ctrl_irq_buf[`IRQ_FIRQ0] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ0] && csr_mie_firq[0]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ0]);
            trap_ctrl_irq_buf[`IRQ_FIRQ1] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ1] && csr_mie_firq[1]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ1]);
            trap_ctrl_irq_buf[`IRQ_FIRQ2] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ2] && csr_mie_firq[2]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ2]);
            trap_ctrl_irq_buf[`IRQ_FIRQ3] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ3] && csr_mie_firq[3]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ3]);
            trap_ctrl_irq_buf[`IRQ_FIRQ4] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ4] && csr_mie_firq[4]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ4]);
            trap_ctrl_irq_buf[`IRQ_FIRQ5] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ5] && csr_mie_firq[5]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ5]);
            trap_ctrl_irq_buf[`IRQ_FIRQ6] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ6] && csr_mie_firq[6]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ6]);
            trap_ctrl_irq_buf[`IRQ_FIRQ7] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ7] && csr_mie_firq[7]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ7]);
            trap_ctrl_irq_buf[`IRQ_FIRQ8] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ8] && csr_mie_firq[8]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ8]);
            trap_ctrl_irq_buf[`IRQ_FIRQ9] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ9] && csr_mie_firq[9]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ9]);
            trap_ctrl_irq_buf[`IRQ_FIRQ10] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ10] && csr_mie_firq[10]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ10]);
            trap_ctrl_irq_buf[`IRQ_FIRQ11] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ11] && csr_mie_firq[11]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ11]);
            trap_ctrl_irq_buf[`IRQ_FIRQ12] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ12] && csr_mie_firq[12]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ12]);
            trap_ctrl_irq_buf[`IRQ_FIRQ13] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ13] && csr_mie_firq[13]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ13]);
            trap_ctrl_irq_buf[`IRQ_FIRQ14] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ14] && csr_mie_firq[14]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ14]);
            trap_ctrl_irq_buf[`IRQ_FIRQ15] <= (trap_ctrl_irq_pnd[`IRQ_FIRQ15] && csr_mie_firq[15]) || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_FIRQ15]);            

            // Debug mode entry
            if (CPU_EXTENSION_RISCV_Sdext == 1) begin
                trap_ctrl_irq_buf[`IRQ_DB_HALT] <= dbg_trig_halt || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_DB_HALT]);
                trap_ctrl_irq_buf[`IRQ_DB_STEP] <= dbg_trig_step || (trap_ctrl_env_pending && trap_ctrl_irq_buf[`IRQ_DB_STEP]);
            end
            else begin
                trap_ctrl_irq_buf[`IRQ_DB_HALT] <= 1'b0;
                trap_ctrl_irq_buf[`IRQ_DB_STEP] <= 1'b0;
            end

            // Trap environment pending
            if (trap_ctrl_env_pending) trap_ctrl_env_pending <= !trap_ctrl_env_enter; // start of trap environment acknowledged by execute engine
            else trap_ctrl_env_pending <= trap_ctrl_exc_fire || (trap_ctrl_irq_fire && (ie_state == IE_EXECUTE));

            // Trap wake up
            trap_ctrl_wakeup <= |trap_ctrl_irq_buf;
        end
    end

    always @(posedge i_clk) begin
        // Standard RISC-V exceptions
        if (trap_ctrl_exc_buf[`EXC_IALIGN])         trap_ctrl_cause <= `TRAP_IMA; // instruction address misaligned
        else if (trap_ctrl_exc_buf[`EXC_IACCESS])   trap_ctrl_cause <= `TRAP_IAF; // instruction access fault
        else if (trap_ctrl_exc_buf[`EXC_ILLEGAL])   trap_ctrl_cause <= `TRAP_IIL; // illegal instruction
        else if (trap_ctrl_exc_buf[`EXC_ECALL])     trap_ctrl_cause <= {`TRAP_ENV, csr_privilege, csr_privilege}; // environment call (U/M)
        else if (trap_ctrl_exc_buf[`EXC_EBREAK])    trap_ctrl_cause <= `TRAP_BRK; // breakpoint
        else if (trap_ctrl_exc_buf[`EXC_SALIGN])    trap_ctrl_cause <= `TRAP_SMA; // store address misaligned
        else if (trap_ctrl_exc_buf[`EXC_LALIGN])    trap_ctrl_cause <= `TRAP_LMA; // load address misaligned
        else if (trap_ctrl_exc_buf[`EXC_SACCESS])   trap_ctrl_cause <= `TRAP_SAF; // store access fault
        else if (trap_ctrl_exc_buf[`EXC_LACCESS])   trap_ctrl_cause <= `TRAP_LAF; // load access fault
        // Standard RISC-V debug mode exceptions and interrupts
        else if (trap_ctrl_irq_buf[`IRQ_DB_HALT])   trap_ctrl_cause <= `TRAP_DB_HALT;   // external halt request (async)
        else if (trap_ctrl_exc_buf[`EXC_DB_HW])     trap_ctrl_cause <= `TRAP_DB_TRIG;   // hardware trigger (sync)
        else if (trap_ctrl_exc_buf[`EXC_DB_BREAK])  trap_ctrl_cause <= `TRAP_DB_BREAK;  // break instruction (sync)
        else if (trap_ctrl_irq_buf[`IRQ_DB_STEP])   trap_ctrl_cause <= `TRAP_DB_STEP;   // single stepping (async)
        // Fast interrupt
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ0])     trap_ctrl_cause <= `TRAP_FIRQ0;     // fast interrupt channel 0
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ1])     trap_ctrl_cause <= `TRAP_FIRQ1;     // fast interrupt channel 1
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ2])     trap_ctrl_cause <= `TRAP_FIRQ2;     // fast interrupt channel 2
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ3])     trap_ctrl_cause <= `TRAP_FIRQ3;     // fast interrupt channel 3
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ4])     trap_ctrl_cause <= `TRAP_FIRQ4;     // fast interrupt channel 4
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ5])     trap_ctrl_cause <= `TRAP_FIRQ5;     // fast interrupt channel 5
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ6])     trap_ctrl_cause <= `TRAP_FIRQ6;     // fast interrupt channel 6
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ7])     trap_ctrl_cause <= `TRAP_FIRQ7;     // fast interrupt channel 7
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ8])     trap_ctrl_cause <= `TRAP_FIRQ8;     // fast interrupt channel 8
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ9])     trap_ctrl_cause <= `TRAP_FIRQ9;     // fast interrupt channel 9
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ10])    trap_ctrl_cause <= `TRAP_FIRQ10;    // fast interrupt channel 10
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ11])    trap_ctrl_cause <= `TRAP_FIRQ11;    // fast interrupt channel 11
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ12])    trap_ctrl_cause <= `TRAP_FIRQ12;    // fast interrupt channel 12
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ13])    trap_ctrl_cause <= `TRAP_FIRQ13;    // fast interrupt channel 13
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ14])    trap_ctrl_cause <= `TRAP_FIRQ14;    // fast interrupt channel 14
        else if (trap_ctrl_irq_buf[`IRQ_FIRQ15])    trap_ctrl_cause <= `TRAP_FIRQ15;    // fast interrupt channel 15
        // Standard RISC-V interrupts
        else if (trap_ctrl_irq_buf[`IRQ_MEI])       trap_ctrl_cause <= `TRAP_MEI;       // machine external interrupt (MEI)
        else if (trap_ctrl_irq_buf[`IRQ_MSI])       trap_ctrl_cause <= `TRAP_MSI;       // machine software interrupt (MSI)
        else if (trap_ctrl_irq_buf[`IRQ_MTI])       trap_ctrl_cause <= `TRAP_MTI;       // machine timer interrupt (MTI)
        else                                        trap_ctrl_cause <= `TRAP_MTI;       // don't care
    end

    always @(*) begin
        if ((ie_state == IE_DISPATCH) && |is_valid && !trap_ctrl_env_pending && !trap_ctrl_exc_fire) begin
            trap_ctrl_instr_be = is_data[34];
            trap_ctrl_instr_ma = is_data[33];
        end
        else begin
            trap_ctrl_instr_be = 1'b0;
            trap_ctrl_instr_ma = 1'b0;
        end

        if ((ie_state == IE_SYSTEM) && (ir_funct3 == `FUNCT3_ENV) && !trap_ctrl_exc_buf[`EXC_ILLEGAL]) begin
            trap_ctrl_env_call      = (ir_funct12 == `FUNCT12_ECALL);
            trap_ctrl_break_point   = (ir_funct12 == `FUNCT12_EBREAK);
        end
        else begin
            trap_ctrl_env_call      = 1'b0;
            trap_ctrl_break_point   = 1'b0;
        end
    end

    // Any exception?
    assign trap_ctrl_exc_fire = |trap_ctrl_exc_buf;

    // Any interrupt?
    assign trap_ctrl_irq_fire = ( |trap_ctrl_irq_buf && // pending IRQ
                                  (csr_mstatus_mie || (csr_privilege == `PRIV_MODE_U)) && // take IRQ when in M-mode and MIE=1 OR when in U-mode
                                  (!dbg_running && !csr_dcsr_step) // no IRQs when in debug-mode or during debug single-stepping
                                ) || 
                                trap_ctrl_irq_buf[`IRQ_DB_STEP] ||
                                trap_ctrl_irq_buf[`IRQ_DB_HALT];

    // exception program counter (for updating xPC CSR) --
    assign trap_ctrl_epc = trap_ctrl_cause[6]? ie_next_pc: ie_pc;

    // Trap enter
    assign trap_ctrl_env_enter = (ie_state == IE_TRAP_ENTER);
    assign trap_ctrl_env_exit  = (ie_state == IE_TRAP_EXIT);

    // Illegal Operation Check
    assign trap_ctrl_instr_il = ((ie_state == IE_EXECUTE) || (ie_state == IE_ALU_WAIT)) && // check in execution states only
                                (monitor_exc || illegal_cmd || (ir_opcode[1:0] != 2'b11));


//=================================================================================================================
// Main controller
//=================================================================================================================
    // Register file controller ===================================================================================
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            ctrl_rf_wb_en   <= 1'b0;
            ctrl_rf_mux     <= 2'b00;
            ctrl_rf_zero_we <= 1'b0;
        end
        else begin
            // ctrl_rf_wb_en
            case (ie_state)
                IE_EXECUTE: begin
                    if ((id_opcode == `OP_ALU) || (id_opcode == `OP_ALUI)) begin
                        if ((id_is_mul && (FAST_MUL_EN == 0)) || id_is_div ||
                             ((ir_funct3 == `FUNCT3_SLL) && (FAST_SHIFT_EN == 0)) ||
                             ((ir_funct3 == `FUNCT3_SR ) && (FAST_SHIFT_EN == 0)))
                             ctrl_rf_wb_en <= 1'b0;
                        else ctrl_rf_wb_en <= 1'b1; // valid RF write-back
                    end
                    else if ((id_opcode == `OP_LUI) || (id_opcode == `OP_AUIPC))
                        ctrl_rf_wb_en <= 1'b1; // valid RF write-back
                    else
                        ctrl_rf_wb_en <= 1'b0;
                end
                IE_ALU_WAIT: // valid RF write-back (won't happen in case of an illegal instruction)
                    ctrl_rf_wb_en <= i_alu_cp_done || trap_ctrl_exc_buf[`EXC_ILLEGAL];
                IE_BRANCH:
                    ctrl_rf_wb_en <= ir_opcode[2]; // save return address if link operation
                IE_MEM_WAIT: // atomic operation or normal load
                    if ((CPU_EXTENSION_RISCV_A == 1) && (id_opcode[2] == 1'b1) || (ir_opcode[5] == 1'b0)) 
                        ctrl_rf_wb_en <= !i_lsu_wait;
                    else
                        ctrl_rf_wb_en <= 1'b0;
                IE_SYSTEM:
                    ctrl_rf_wb_en <= (ir_funct3 != `FUNCT3_ENV) || trap_ctrl_exc_buf[`EXC_ILLEGAL];
                default:
                    ctrl_rf_wb_en <= 1'b0;    
            endcase

            // ctrl_rf_mux
            if (ie_state == IE_BRANCH)        ctrl_rf_mux <= `RF_MUX_NPC; // return address = next PC
            else if (ie_state == IE_BRANCHED) ctrl_rf_mux <= `RF_MUX_CSR; // this will return 0 since csr.re_nxt has not been set 
            else if (ie_state == IE_MEM_WAIT) ctrl_rf_mux <= `RF_MUX_MEM; // RF input = memory read data
            else if (ie_state == IE_SYSTEM)   ctrl_rf_mux <= `RF_MUX_CSR; // CSR read data
            else ctrl_rf_mux <= `RF_MUX_ALU;

            // ctrl_rf_zero_we (not implemented yet)
            ctrl_rf_zero_we <= 1'b0;
        end
    end

    assign o_ctrl_rf_wb_en   = ctrl_rf_wb_en && !trap_ctrl_exc_buf[`EXC_ILLEGAL];
    assign o_ctrl_rf_rs1     = ir_rs1;
    assign o_ctrl_rf_rs2     = ir_rs2;
    assign o_ctrl_rf_rs3     = ir_rs3;
    assign o_ctrl_rf_rd      = ir_rd;
    assign o_ctrl_rf_mux     = ctrl_rf_mux;
    assign o_ctrl_rf_zero_we = ctrl_rf_zero_we;

    // ALU controller ================================================================================================
    always @(posedge i_clk, negedge i_rstn) begin 
        if (!i_rstn) begin
            ctrl_alu_op       <= `ALU_OP_ADD;
            ctrl_alu_opa_mux  <= 1'b0;
            ctrl_alu_opb_mux  <= 1'b0;
            ctrl_alu_unsigned <= 1'b0;
            ctrl_alu_cp_trig  <= 5'b00000;
        end
        else begin
            // ctrl_alu_op
            if (ie_state == IE_EXECUTE) begin
                if ((ir_opcode == `OP_ALU) || (ir_opcode == `OP_ALUI)) begin
                    case (ir_funct3)
                        `FUNCT3_SUBADD  : ctrl_alu_op <= (ir_opcode[5] && ir_funct7[5])? `ALU_OP_SUB: `ALU_OP_ADD;
                        `FUNCT3_SLT     : ctrl_alu_op <= `ALU_OP_SLT;
                        `FUNCT3_SLTU    : ctrl_alu_op <= `ALU_OP_SLT;
                        `FUNCT3_XOR     : ctrl_alu_op <= `ALU_OP_XOR;
                        `FUNCT3_OR      : ctrl_alu_op <= `ALU_OP_OR;
                        default         : ctrl_alu_op <= `ALU_OP_AND;                                
                    endcase
                end
                else if ((ir_opcode == `OP_LUI) || (ir_opcode == `OP_AUIPC))
                    ctrl_alu_op <= (ir_opcode[5] == 1'b1)? `ALU_OP_MOVB: `ALU_OP_ADD;
            end
            else if (ie_state == IE_ALU_WAIT) ctrl_alu_op <= `ALU_OP_CP;
            else ctrl_alu_op <= `ALU_OP_ADD;

            // ctrl_alu_opa_mux
            ctrl_alu_opa_mux <= (id_opcode == `OP_AUIPC)  || (id_opcode == `OP_JAL)   || (id_opcode == `OP_BRANCH);

            ctrl_alu_opb_mux <= (id_opcode == `OP_ALUI)   || (id_opcode == `OP_LUI)   || (id_opcode == `OP_AUIPC) ||
                                (id_opcode == `OP_LOAD)   || (id_opcode == `OP_STORE) || (id_opcode == `OP_AMO)   ||
                                (id_opcode == `OP_BRANCH) || (id_opcode == `OP_JAL)   || (id_opcode == `OP_JALR);

            // ctrl_alu_unsigned ir_op[4] == 1 --> ALU ops (SLTIU, SLTU), otherwise branches (BLTU, BGEU)
            ctrl_alu_unsigned <= ir_opcode[4]? ir_funct3[0]: ir_funct3[1];

            // Co-preocessor trigger (one-hot)
            if (ie_state == IE_EXECUTE) begin
                if ((id_opcode == `OP_ALU) || (id_opcode == `OP_ALUI)) begin
                    ctrl_alu_cp_trig[`CP_SEL_SHIFT] <= (ir_funct3 == `FUNCT3_SLL) || (ir_funct3 == `FUNCT3_SR);
                    ctrl_alu_cp_trig[`CP_SEL_MUL]   <= id_is_mul;
                    ctrl_alu_cp_trig[`CP_SEL_DIV]   <= id_is_div;
                    ctrl_alu_cp_trig[`CP_SEL_FPU]   <= 1'b0;
                    ctrl_alu_cp_trig[`CP_SEL_CFU]   <= 1'b0;
                end
                else if (id_opcode == `OP_FOP) begin
                    ctrl_alu_cp_trig[`CP_SEL_SHIFT] <= 1'b0;
                    ctrl_alu_cp_trig[`CP_SEL_MUL]   <= 1'b0;
                    ctrl_alu_cp_trig[`CP_SEL_DIV]   <= 1'b0;
                    ctrl_alu_cp_trig[`CP_SEL_FPU]   <= 1'b1;
                    ctrl_alu_cp_trig[`CP_SEL_CFU]   <= 1'b0;                    
                end
                else if ((id_opcode == `OP_CUST0) || 
                         (id_opcode == `OP_CUST1) || 
                         (id_opcode == `OP_CUST2) || 
                         (id_opcode == `OP_CUST3)) begin
                    ctrl_alu_cp_trig[`CP_SEL_SHIFT] <= 1'b0;
                    ctrl_alu_cp_trig[`CP_SEL_MUL]   <= 1'b0;
                    ctrl_alu_cp_trig[`CP_SEL_DIV]   <= 1'b0;
                    ctrl_alu_cp_trig[`CP_SEL_FPU]   <= 1'b0;
                    ctrl_alu_cp_trig[`CP_SEL_CFU]   <= 1'b1;                              
                end
                else ctrl_alu_cp_trig <= 5'b00000;
            end
            else begin
                ctrl_alu_cp_trig <= 5'b00000;
            end
        end
    end

    assign o_ctrl_alu_op = ctrl_alu_op;
    assign o_ctrl_alu_opa_mux = ctrl_alu_opa_mux;
    assign o_ctrl_alu_opb_mux = ctrl_alu_opb_mux;
    assign o_ctrl_alu_unsigned = ctrl_alu_unsigned;
    assign o_ctrl_alu_cp_trig = ctrl_alu_cp_trig;

    // Load/Store unit controller =============================================================================
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            ctrl_lsu_req_rd <= 1'b0;
            ctrl_lsu_req_wr <= 1'b0;
            ctrl_lsu_rw     <= 1'b0;
            ctrl_lsu_fence  <= 1'b0;
            ctrl_lsu_fencei <= 1'b0;
        end
        else begin
            ctrl_lsu_req_rd <= (ie_state == IE_MEM_REQ) && !ctrl_lsu_rw && !trap_ctrl_exc_buf[`EXC_ILLEGAL];
            ctrl_lsu_req_wr <= (ie_state == IE_MEM_REQ) &&  ctrl_lsu_rw && !trap_ctrl_exc_buf[`EXC_ILLEGAL];
        
            if ((CPU_EXTENSION_RISCV_A == 1) && (id_opcode[2] == 1'b1)) // lr/sc
                ctrl_lsu_rw <= ir_funct7[2];
            else
                ctrl_lsu_rw <= ie_ir[5];

            if (ie_state == IE_FENCE) begin
                ctrl_lsu_fence  <= !trap_ctrl_exc_buf[`EXC_ILLEGAL] && (ir_funct3 == `FUNCT3_FENCE);
                ctrl_lsu_fencei <= !trap_ctrl_exc_buf[`EXC_ILLEGAL] && (ir_funct3 == `FUNCT3_FENCEI) && (CPU_EXTENSION_RISCV_Zifencei == 1);
            end
            else begin
                ctrl_lsu_fence  <= 1'b0;
                ctrl_lsu_fencei <= 1'b0;                
            end
        end
    end

    assign o_ctrl_lsu_req_rd = ctrl_lsu_req_rd;
    assign o_ctrl_lsu_req_wr = ctrl_lsu_req_wr;
    assign o_ctrl_lsu_rw     = ctrl_lsu_rw;
    assign o_ctrl_lsu_mo_we  = (ie_state == IE_MEM_REQ); // write memory output registers (data & address)
    assign o_ctrl_lsu_fence  = ctrl_lsu_fence;
    assign o_ctrl_lsu_fencei = ctrl_lsu_fencei;
    assign o_ctrl_lsu_priv   = csr_mstatus_mprv? csr_mstatus_mpp: csr_privilege_eff; // effective privilege level for loads/stores in M-mode

    // Functional fields extrac =============================================================================
    assign o_ctrl_ir_opcode  = ir_opcode;
    assign o_ctrl_ir_funct12 = ir_funct12;
    assign o_ctrl_ir_funct3  = ir_funct3;

    assign o_ctrl_cpu_priv   = csr_privilege_eff;
    assign o_ctrl_cpu_sleep  = (ie_state == IE_SLEEP);
    assign o_ctrl_cpu_trap   = trap_ctrl_env_enter;
    assign o_ctrl_cpu_debug  = dbg_running;

    // Monitor controller ===================================================================================
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn)
            monitor_cnt <= 10'd0;
        else
            monitor_cnt <= monitor_cnt_add + 1'b1;
    end

    // timeout counter (allow mapping of entire logic into the LUTs in front of the carry-chain) --
    assign monitor_cnt_add = (ie_state == IE_ALU_WAIT)? monitor_cnt: 10'd0;

    // raise illegal instruction exception if a multi-cycle instruction takes longer than a bound amount of time
    assign monitor_exc = monitor_cnt[9];

    // Hardware Trigger Module (Part of the On-Chip Debugger) ================================================
    
    // trigger to enter debug-mode: instruction address match (fire AFTER execution) --
    assign hw_trigger_fire = (CPU_EXTENSION_RISCV_Sdtrig == 1) &&
                              csr_tdata1_exe &&
                             (csr_tdata2[XLEN-1:1] == ie_pc[XLEN-1:1]) &&
                             (ie_state == IE_EXECUTE);

    // CSR controller ===================================================================================


    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            csr_we <= 1'b0;
            csr_re <= 1'b0;
            csr_rdata <= {XLEN{1'b0}};
        end
        else begin
            // CSRRW/CSRRWI:  always write CSR, CSRR(S/C)(I): write CSR if rs1/imm5 is NOT zero
            if (ie_state == IE_SYSTEM)
                csr_we <= (ir_funct3 == `FUNCT3_CSRRW) || (ir_funct3 == `FUNCT3_CSRRWI) || (id_rs1_zero == 1'b0);
            else csr_we <= 1'b0;

            // Environment/CSR operation or ILLEGAL opcode
            if (ie_state == IE_EXECUTE)
                csr_re <= (id_opcode != `OP_ALU) && (id_opcode != `OP_ALUI) &&
                          (id_opcode != `OP_LUI) && (id_opcode != `OP_AUIPC) &&
                          (id_opcode != `OP_LOAD) && (id_opcode != `OP_STORE) && (id_opcode != `OP_AMO) &&
                          (id_opcode != `OP_BRANCH) && (id_opcode != `OP_JAL) && (id_opcode != `OP_JALR) &&
                          (id_opcode != `OP_FENCE) && (id_opcode != `OP_FOP) && 
                          (id_opcode != `OP_CUST0) && (id_opcode != `OP_CUST1) &&
                          (id_opcode != `OP_CUST2) && (id_opcode != `OP_CUST3);
            else csr_re <= 1'b0;

            // CSR read data
            if (csr_re) csr_rdata <= tcsr_rdata | xcsr_rdata;
        end
    end

    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            csr_mstatus_mie     <= 1'b0;
            csr_mstatus_mpie    <= 1'b0;
            csr_mstatus_mpp     <= 1'b0;
            csr_mstatus_mprv    <= 1'b0;
            csr_mstatus_tw      <= 1'b0;
            csr_mie_msi         <= 1'b0;
            csr_mie_mei         <= 1'b0;
            csr_mie_mti         <= 1'b0;
            csr_mie_firq        <= 16'd0;
            csr_mip_firq_nclr   <= 16'd0;
            csr_privilege       <= 1'b0;
            csr_mepc            <= {XLEN{1'b0}};
            csr_mcause          <= 6'd0;
            csr_mtvec           <= {XLEN{1'b0}};
            csr_mtval           <= {XLEN{1'b0}};
            csr_mtinst          <= {XLEN{1'b0}};
            csr_mscratch        <= {XLEN{1'b0}};
            csr_mcounteren      <= 1'b0;
            csr_mcountinhibit   <= 16'd0;
            csr_mcyclecfg_minh  <= 1'b0;
            csr_mcyclecfg_uinh  <= 1'b0;
            csr_minstretcfg_minh  <= 1'b0;
            csr_minstretcfg_uinh  <= 1'b0;
            csr_dcsr_ebreakm    <= 1'b0;
            csr_dcsr_ebreaku    <= 1'b0;
            csr_dcsr_step       <= 1'b0;
            csr_dcsr_prv        <= 1'b0;
            csr_dcsr_cause      <= 3'b000;
            csr_dpc             <= {XLEN{1'b0}};
            csr_dscratch0       <= {XLEN{1'b0}};
            csr_tdata1_exe      <= 1'b0;
            csr_tdata1_action   <= 1'b0;
            csr_tdata1_dmode    <= 1'b0;
            csr_tdata2          <= {XLEN{1'b0}};
        end
        else begin
            if (csr_we) begin
                case (csr_addr)
                    // Machine trap setup
                    `CSR_MSTATUS: begin
                        csr_mstatus_mie  <= csr_wdata[3];
                        csr_mstatus_mpie <= csr_wdata[7];
                        if (CPU_EXTENSION_RISCV_U == 1) begin
                            csr_mstatus_mpp  <= csr_wdata[11] | csr_wdata[12];
                            csr_mstatus_mprv <= csr_wdata[17];
                            csr_mstatus_tw   <= csr_wdata[21];
                        end
                    end
                    `CSR_MIE: begin
                        csr_mie_msi  <= csr_wdata[3];
                        csr_mie_mti  <= csr_wdata[7];
                        csr_mie_mei  <= csr_wdata[11];
                        csr_mie_firq <= csr_wdata[31:16];
                    end
                    `CSR_MTVEC: begin
                        if (csr_wdata[1:0] == 2'b01) csr_mtvec <= {csr_wdata[XLEN-1:7], 5'b00000, 2'b01}; // mtvec.MODE=1 (vectored)
                        else csr_mtvec <= {csr_wdata[XLEN-1:2], 2'b00};           // mtvec.MODE=0 (direct)                       
                    end
                    `CSR_MCOUNTEREN:
                        if (CPU_EXTENSION_RISCV_U == 1) begin
                            if ((CPU_EXTENSION_RISCV_Zicntr == 1))
                                csr_mcounteren <= |csr_wdata[15 : 3] || csr_wdata[2] || csr_wdata[0]; // hpms, instret, cycle
                            else if (CPU_EXTENSION_RISCV_Zicntr == 1) 
                                csr_mcounteren <= csr_wdata[2] || csr_wdata[0]; // instret, cycle
                        end
                
                    // Machine trap handling
                    `CSR_MSCRATCH:  csr_mscratch <= csr_wdata;
                    `CSR_MEPC    :  csr_mepc <= csr_wdata;
                    `CSR_MCAUSE  :  csr_mcause <= csr_wdata[31] & csr_wdata[4:0]; // type (exception/interrupt) & identifier
                    `CSR_MIP     :  csr_mip_firq_nclr <= csr_wdata[31:16];        // set low to clear according bit (FIRQs only)

                    // Machine counter setup
                    `CSR_MCOUNTINHIBIT: begin
                        if (CPU_EXTENSION_RISCV_Zicntr == 1) begin
                            csr_mcountinhibit[0] <= csr_wdata[0];
                            csr_mcountinhibit[2] <= csr_wdata[2];                            
                        end                      
                    end
                    `CSR_MCYCLECFGH: begin // machine cycle counter privilege mode filtering
                        if ((CPU_EXTENSION_RISCV_Zicntr == 1) && (CPU_EXTENSION_RISCV_U == 1)) begin
                            csr_mcyclecfg_minh <= csr_wdata[30];
                            csr_mcyclecfg_uinh <= csr_wdata[28];
                        end
                        else begin
                            csr_mcyclecfg_minh <= 1'b0;
                            csr_mcyclecfg_uinh <= 1'b0;
                        end
                    end
                    `CSR_MINSTRETCFG: begin
                        if ((CPU_EXTENSION_RISCV_Zicntr == 1) && (CPU_EXTENSION_RISCV_U == 1)) begin
                         csr_minstretcfg_minh <= csr_wdata[30];
                         csr_minstretcfg_uinh <= csr_wdata[28]; 
                        end
                        else begin
                         csr_minstretcfg_minh <= 1'b0;
                         csr_minstretcfg_uinh <= 1'b0;                         
                        end                       
                    end

                    // Debug mode CSRs
                    `CSR_DCSR : // debug mode control and status register
                        if (CPU_EXTENSION_RISCV_Sdext == 1) begin
                            csr_dcsr_ebreakm <= csr_wdata[15];
                            csr_dcsr_step    <= csr_wdata[2];
                            if (CPU_EXTENSION_RISCV_U == 1) begin
                                csr_dcsr_ebreaku <= csr_wdata[12];
                                csr_dcsr_prv     <= csr_wdata[1] || csr_wdata[0]; // everything /= U will fall back to M
                            end
                        end

                    `CSR_DPC : // debug mode program counter
                        if (CPU_EXTENSION_RISCV_Sdext == 1) begin
                            csr_dpc <= {csr_wdata[XLEN-1:1] & 1'b0};
                        end

                    `CSR_DSCRATCH0 : // debug mode scratch register 0
                        if (CPU_EXTENSION_RISCV_Sdext == 1) begin
                            csr_dscratch0 <= csr_wdata;
                        end

                    // trigger module CSRs
                    `CSR_TDATA1: // match control
                        if (CPU_EXTENSION_RISCV_Sdtrig == 1) begin
                            csr_tdata1_exe    <= csr_wdata[2];
                            csr_tdata1_action <= csr_wdata[12];
                            csr_tdata1_dmode  <= csr_wdata[27];
                        end

                    `CSR_TDATA2 : // address compare
                        if (CPU_EXTENSION_RISCV_Sdtrig == 1) begin
                            csr_tdata2 <= {csr_wdata[XLEN-1:1], 1'b0};
                        end    
                endcase
            end
            // ********************************************************************************
            // Hardware CSR access: TRAP ENTER
            // ********************************************************************************            
            else if (trap_ctrl_env_enter) begin
                // NORMAL trap entry - no CSR update when in debug-mode! //
                if ((CPU_EXTENSION_RISCV_Sdext == 0) || ((trap_ctrl_cause[5] == 1'b0) && (dbg_running == 1'b0))) begin
                    csr_mcause <= {trap_ctrl_cause[6], trap_ctrl_cause[4:0]}; // trap type & identifier
                    csr_mepc   <= {trap_ctrl_epc[XLEN-1:1], 1'b0}; // trap PC
                    // trap value
                    if ((trap_ctrl_cause[6] == 1'b0) && (trap_ctrl_cause[4:2] == 3'b001)) // load/store misaligned/fault
                        csr_mtval <= i_mar; // faulting data access address
                    else csr_mtval <= {XLEN{1'b0}}; // everything else including all interrupts    
                
                    // trap instruction //
                    if (trap_ctrl_cause[6] == 1'b0) begin // exception
                        csr_mtinst <= ie_ir;
                        if ((ie_is_ci == 1'b1) && (CPU_EXTENSION_RISCV_C == 1))
                            csr_mtinst[1] <= 1'b0; // RISC-V priv_ spec: clear bit 1 if compressed instruction
                    end
                    else csr_mtinst <= {XLEN{1'b0}}; // interrupt
                    
                    // update privilege level and interrupt-enable stack //
                    csr_privilege    <= `PRIV_MODE_M; // execute trap in machine mode
                    csr_mstatus_mie  <= 1'b0; // disable interrupts
                    csr_mstatus_mpie <= csr_mstatus_mie; // backup previous mie state
                    csr_mstatus_mpp  <= csr_privilege; // backup previous privilege mode
                end

                // DEBUG MODE entry - no CSR update when already in debug-mode!
                if ((CPU_EXTENSION_RISCV_Sdext == 1) && (trap_ctrl_cause[5] == 1'b1) && (dbg_running == 1'b0)) begin
                    // trap cause
                    csr_dcsr_cause <= trap_ctrl_cause[2:0]; // why did we enter debug mode?
                    // current privilege mode when debug mode was entered
                    csr_dcsr_prv   <= csr_privilege;
                    // trap PC 
                    csr_dpc        <= {trap_ctrl_epc[XLEN-1:1], 1'b0};
                end                
            end
            // ********************************************************************************
            // Hardware CSR access: TRAP EXIT
            // ********************************************************************************
            else if (trap_ctrl_env_exit) begin
                if ((CPU_EXTENSION_RISCV_Sdext == 1) && dbg_running) begin // return from debug mode
                    if (CPU_EXTENSION_RISCV_U == 1) begin
                        csr_privilege <= csr_dcsr_prv;
                        if (csr_dcsr_prv != `PRIV_MODE_M)
                        csr_mstatus_mprv <= 1'b0; // clear if return to priv_ mode less than M
                    end
                end
                else begin // return from normal trap
                    if (CPU_EXTENSION_RISCV_U == 1) begin
                        csr_privilege   <= csr_mstatus_mpp; // restore previous privilege mode
                        csr_mstatus_mpp <= `PRIV_MODE_U; // set to least-privileged mode that is supported
                        if (csr_mstatus_mpp != `PRIV_MODE_M)
                            csr_mstatus_mprv <= 1'b0; // clear if return to priv_ mode less than M
                    end
                    csr_mstatus_mie  <= csr_mstatus_mpie; // restore machine-mode IRQ enable flag
                    csr_mstatus_mpie <= 1'b1;
                end                
            end

            // ********************************************************************************
            // Override - hardwire/terminate unimplemented registers/bits
            // ********************************************************************************

            // hardwired bits
            csr_mcountinhibit[1] <= 1'b0; // time[h] not implemented

            // no base counters
            if (CPU_EXTENSION_RISCV_Zicntr == 0)
                csr_mcountinhibit[2:0] <= 3'b000;

            csr_mcountinhibit[15:3] <= 13'd0;

            csr_mcounteren <= 1'b0;

            // no user mode --
            if (CPU_EXTENSION_RISCV_U == 0) begin
                csr_privilege        <= `PRIV_MODE_M;
                csr_mstatus_mpp      <= `PRIV_MODE_M;
                csr_mstatus_mprv     <= 1'b0;
                csr_mstatus_tw       <= 1'b0;
                csr_dcsr_ebreaku     <= 1'b0;
                csr_dcsr_prv         <= 1'b0;
                csr_mcounteren       <= 1'b0;
            end

            // no debug mode --
            if (CPU_EXTENSION_RISCV_Sdext == 0) begin
                csr_dcsr_ebreakm <= 1'b0;
                csr_dcsr_step    <= 1'b0;
                csr_dcsr_ebreaku <= 1'b0;
                csr_dcsr_prv     <= `PRIV_MODE_M;
                csr_dcsr_cause   <= 3'b000;
                csr_dpc          <= {XLEN{1'b0}};
                csr_dscratch0    <= {XLEN{1'b0}};
            end

            // no trigger module --
            if (CPU_EXTENSION_RISCV_Sdtrig == 0) begin
                csr_tdata1_exe    <= 1'b0;
                csr_tdata1_action <= 1'b0;
                csr_tdata1_dmode  <= 1'b0;
                csr_tdata2        <= {XLEN{1'b0}};
            end
        end
    end

    // CSR Read Access -----------------------------
    always @(*) begin
        tcsr_rdata = {XLEN{1'b0}}; 

        case (csr_raddr)
            // machine trap setup --
            `CSR_MSTATUS: begin // machine status register - low word
                tcsr_rdata[3]     = csr_mstatus_mie;
                tcsr_rdata[7]     = csr_mstatus_mpie;
                tcsr_rdata[12:11] = {2{csr_mstatus_mpp}};
                tcsr_rdata[17]    = csr_mstatus_mprv;
                tcsr_rdata[21]    = csr_mstatus_tw && (CPU_EXTENSION_RISCV_U == 1);
            end
            // when csr_mstatush_c => tcsr_rdata <= (others => '0'); -- machine status register - hardwired to zero
            `CSR_MISA: begin // ISA and extensions
                tcsr_rdata[0]     =  (CPU_EXTENSION_RISCV_A == 1); // A CPU extension
                tcsr_rdata[1]     =  1'b0; // B CPU extension
                tcsr_rdata[2]     =  (CPU_EXTENSION_RISCV_C == 1); // C CPU extension
                tcsr_rdata[4]     =  1'b0; // E CPU extension
                tcsr_rdata[8]     =  1'b1; // I CPU extension (if not E)
                tcsr_rdata[12]    =  (CPU_EXTENSION_RISCV_M == 1); // M CPU extension
                tcsr_rdata[20]    =  (CPU_EXTENSION_RISCV_U == 1); // U CPU extension
                tcsr_rdata[23]    =  1'b1;                         // X CPU extension (non-standard extensions / NEORV32-specific)
                tcsr_rdata[31:30] =  2'b01; // MXL = 32
            end
            `CSR_MIE: begin // machine interrupt-enable register
                tcsr_rdata[3]     = csr_mie_msi;
                tcsr_rdata[7]     = csr_mie_mti;
                tcsr_rdata[11]    = csr_mie_mei;
                tcsr_rdata[31:16] = csr_mie_firq;
            end
            `CSR_MTVEC: // machine trap-handler base address
                tcsr_rdata        = csr_mtvec;
            `CSR_MCOUNTEREN: // machine counter enable register
                if (CPU_EXTENSION_RISCV_U == 1)
                    if (CPU_EXTENSION_RISCV_Zicntr == 1) begin
                        tcsr_rdata[0] = csr_mcounteren; // cycle
                        tcsr_rdata[2] = csr_mcounteren; // instret
                    end

            // machine trap handling --
            `CSR_MSCRATCH: // machine scratch register
                tcsr_rdata = csr_mscratch;
            `CSR_MEPC: // machine exception program counter
                tcsr_rdata = {csr_mepc[XLEN-1:1], 1'b0};
            `CSR_MCAUSE: begin // machine trap cause
                tcsr_rdata[31]  = csr_mcause[5];
                tcsr_rdata[4:0] = csr_mcause[4:0];
            end
            `CSR_MTVAL: // machine trap value
                tcsr_rdata = csr_mtval;
            `CSR_MIP: begin // machine interrupt pending
                tcsr_rdata[3]     = trap_ctrl_irq_pnd[`IRQ_MSI];
                tcsr_rdata[7]     = trap_ctrl_irq_pnd[`IRQ_MTI];
                tcsr_rdata[11]    = trap_ctrl_irq_pnd[`IRQ_MEI];
                tcsr_rdata[31:16] = trap_ctrl_irq_pnd[`IRQ_FIRQ15:`IRQ_FIRQ0];
            end
            `CSR_MTINST: // machine trap instruction
                tcsr_rdata        = csr_mtinst;
            `CSR_MCOUNTINHIBIT: // machine counter-inhibit register
                if (CPU_EXTENSION_RISCV_Zicntr == 1) begin
                    tcsr_rdata[0] = csr_mcountinhibit[0]; // [m]cycle[h]
                    tcsr_rdata[2] = csr_mcountinhibit[2]; // [m]instret[h]
                end
            // if (CPU_EXTENSION_RISCV_Zihpm == 1) and (hpm_num_c > 0) begin
            // for i in 3 to (hpm_num_c+3)-1 loop
            //     tcsr_rdata(i) <= csr.mcountinhibit(i); // [m]hpmcounter*[h]
            // end

            // when csr_mcyclecfg_c   => tcsr_rdata <= (others => '0'); -- hardwired to zero
            // when csr_minstretcfg_c => tcsr_rdata <= (others => '0'); -- hardwired to zero

            `CSR_MCYCLECFGH: // machine cycle counter privilege mode filtering
                if (CPU_EXTENSION_RISCV_Zicntr == 1) begin
                    tcsr_rdata[30] = csr_mcyclecfg_minh;
                    tcsr_rdata[28] = csr_mcyclecfg_uinh;
                end

            `CSR_MINSTRETCFG: // machine instret counter privilege mode filtering
                if (CPU_EXTENSION_RISCV_Zicntr == 1) begin
                    tcsr_rdata[30] = csr_minstretcfg_minh;
                    tcsr_rdata[28] = csr_minstretcfg_uinh;
                end

            // machine information registers --
            // --------------------------------------------------------------------
            `CSR_MVENDORID: tcsr_rdata       = VENDOR_ID;    // vendor's JEDEC ID
            `CSR_MARCHID:   tcsr_rdata[4:0]  = 5'b10011;     // architecture ID - official RISC-V open-source arch ID
            `CSR_MIMPID:    tcsr_rdata       = HW_VERSION;   // implementation ID -- NEORV32 hardware version
            `CSR_MHARTID:   tcsr_rdata       = HART_ID;      // hardware thread ID
            //`CSR_MCONFIGPTR: tcsr_rdata <= (others => '0'); -- machine configuration pointer register - hardwired to zero

            // debug mode CSRs --
            // --------------------------------------------------------------------
            `CSR_DCSR:      tcsr_rdata = (CPU_EXTENSION_RISCV_Sdext == 1)? csr_dcsr_rd: 32'd0;   // debug mode control and status
            `CSR_DPC:       tcsr_rdata = (CPU_EXTENSION_RISCV_Sdext == 1)? csr_dpc: 32'd0;       // debug mode program counter
            `CSR_DSCRATCH0: tcsr_rdata = (CPU_EXTENSION_RISCV_Sdext == 1)? csr_dscratch0: 32'd0; // debug mode scratch register 0

            // trigger module CSRs --
            // --------------------------------------------------------------------
            `CSR_TDATA1:   tcsr_rdata = (CPU_EXTENSION_RISCV_Sdtrig == 1)? csr_tdata1_rd: 32'd0;   // match control
            `CSR_TDATA2:   tcsr_rdata = (CPU_EXTENSION_RISCV_Sdtrig == 1)? csr_tdata2: 32'd0;      // address-compare
            `CSR_TINFO:    tcsr_rdata = (CPU_EXTENSION_RISCV_Sdtrig == 1)? 32'h4: 32'd0;           // address-match trigger only
            // when csr_tselect_c  => if (CPU_EXTENSION_RISCV_Sdtrig) then tcsr_rdata <= (others => '0'); end if; -- hardwired to zero = only 1 trigger available
            // when csr_tdata3_c   => if (CPU_EXTENSION_RISCV_Sdtrig) then tcsr_rdata <= (others => '0'); end if; -- hardwired to zero
            // when csr_tcontrol_c => if (CPU_EXTENSION_RISCV_Sdtrig) then tcsr_rdata <= (others => '0'); end if; -- hardwired to zero

            // NEORV32-specific (RISC-V "custom") read-only CSRs --
            // --------------------------------------------------------------------
            // machine extended ISA extensions information --
            `CSR_MXISA: begin
                // extended ISA (sub-)extensions --
                tcsr_rdata[0] = 1'b1;                                // Zicsr: CSR access (always enabled)
                tcsr_rdata[1] = (CPU_EXTENSION_RISCV_Zifencei == 1); // Zifencei: instruction stream sync.
                tcsr_rdata[2] = (CPU_EXTENSION_RISCV_Zmmul == 1);    // Zmmul: mul/div
                tcsr_rdata[3] = (CPU_EXTENSION_RISCV_Zxcfu == 1);    // Zxcfu: custom RISC-V instructions
                tcsr_rdata[4] = (CPU_EXTENSION_RISCV_U == 1);        // Smcntrpmf: counter privilege mode filtering (enabled if U implemented)
                tcsr_rdata[5] = 1'b0;    // Zfinx: FPU using x registers
                tcsr_rdata[6] = 1'b0;                                // reserved
                tcsr_rdata[7] = (CPU_EXTENSION_RISCV_Zicntr == 1);   // Zicntr: base counters
                tcsr_rdata[8] = (PMP_EN == 1);                       // PMP: physical memory protection (Smpmp)
                tcsr_rdata[9] = 1'b0;    // Zihpm: hardware performance monitors
                tcsr_rdata[10] = (CPU_EXTENSION_RISCV_Sdext == 1);   // Sdext: RISC-V (external) debug mode
                tcsr_rdata[11] = (CPU_EXTENSION_RISCV_Sdtrig == 1);  // Sdtrig: trigger module
                // tuning options --
                tcsr_rdata[30] = (FAST_MUL_EN == 1);                 // DSP-based multiplication (M extensions only)
                tcsr_rdata[31] = (FAST_SHIFT_EN == 1);               // parallel logic for shifts (barrel shifters)
            end
            default: tcsr_rdata = 32'd0;
        endcase
    end

    wire [XLEN-1:0] tmp_v = ir_funct3[2]? {27'd0, ie_ir[19:15]}: i_rs1;

    // ****************************************************************************************************************************
    // CPU Debug Mode (Part of the On-Chip Debugger)
    // ****************************************************************************************************************************
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            dbg_ext_halt_req <= 1'b0;
            dbg_running      <= 1'b0;
        end
        else begin
            if (CPU_EXTENSION_RISCV_Sdext == 1) begin
                dbg_ext_halt_req <= i_db_halt_req; // external halt request (from Debug Module)
                if (!dbg_running) begin// debug mode OFFLINE - waiting for entry event
                    if (trap_ctrl_env_enter && trap_ctrl_cause[5]) dbg_running <= 1'b1;
                end
                else if (trap_ctrl_env_exit) dbg_running <= 1'b0;
            end
            else begin
                dbg_ext_halt_req <= 1'b0;
                dbg_running      <= 1'b0;
            end
        end
    end

    assign dbg_trig_hw    = hw_trigger_fire && !dbg_running && csr_tdata1_action && csr_tdata1_dmode; // enter debug mode by HW trigger module request (only valid if dmode = 1)
    assign dbg_trig_break = trap_ctrl_break_point && ( dbg_running ||   // re-enter debug mode
                            ( csr_privilege && csr_dcsr_ebreakm)   ||   // enabled goto-debug-mode in machine mode on "ebreak"
                            (!csr_privilege && csr_dcsr_ebreaku));      // enabled goto-debug-mode in user mode on "ebreak"
    assign dbg_trig_halt  = dbg_ext_halt_req && !dbg_running; // external halt request (if not halted already)
    assign dbg_trig_step  = csr_dcsr_step    && !dbg_running; // single-step mode (trigger when NOT CURRENTLY in debug mode) 

    assign csr_addr  = ir_imm12;
    assign csr_raddr = {csr_addr[11:0], csr_addr[8], csr_addr[8], csr_addr[7:0]}; 
    assign csr_wdata = (ir_funct3 == 2'b10)? csr_rdata | tmp_v:
                       (ir_funct3 == 2'b11)? csr_rdata & (~tmp_v): tmp_v;

    // effective privilege mode is MACHINE when in debug mode
    assign csr_privilege_eff = dbg_running? 1'b1: csr_privilege;

    // Debug Control and Status Register (dcsr) - Read-Back
    assign csr_dcsr_rd[31:28]   = 4'b0100; // xdebugver: external debug support compatible to spec. version 1.0
    assign csr_dcsr_rd[27:16]   = 12'd0; // reserved
    assign csr_dcsr_rd[15]      = csr_dcsr_ebreakm; // ebreakm: what happens on ebreak in m-mode? (normal trap OR debug-enter)
    assign csr_dcsr_rd[14]      = 1'b0; // ebreakh: hypervisor mode not implemented
    assign csr_dcsr_rd[13]      = 1'b0; // ebreaks: supervisor mode not implemented
    assign csr_dcsr_rd[12]      = csr_dcsr_ebreaku && (CPU_EXTENSION_RISCV_U == 1); // ebreaku: what happens on ebreak in u-mode? (normal trap OR debug-enter)
    assign csr_dcsr_rd[11]      = 1'b0; // stepie: interrupts are disabled during single-stepping
    assign csr_dcsr_rd[10]      = 1'b1; // stopcount: standard counters and HPMs are stopped when in debug mode
    assign csr_dcsr_rd[9]       = 1'b0; // stoptime: timers increment as usual
    assign csr_dcsr_rd[8:6]     = csr_dcsr_cause; // debug mode entry cause
    assign csr_dcsr_rd[5]       = 1'b0; // reserved
    assign csr_dcsr_rd[4]       = 1'b1; // mprven: mstatus.mprv is also evaluated in debug mode
    assign csr_dcsr_rd[3]       = 1'b0; // nmip: no pending non-maskable interrupt
    assign csr_dcsr_rd[2]       = csr_dcsr_step; // step: single-step mode
    assign csr_dcsr_rd[1:0]     = {2{csr_dcsr_prv}};

    // Match Control CSR (mcontrol @ tdata1) - Read-Back
    assign csr_tdata1_rd[31:28] = 4'b0010;                      // type: address(/data) match trigger
    assign csr_tdata1_rd[27]    = csr_tdata1_dmode;             // dmode: set to ignore machine-mode access to tdata* CSRs
    assign csr_tdata1_rd[26:21] = 6'b000000;                    // maskmax: only exact values
    assign csr_tdata1_rd[20]    = 1'b0;                         // hit: feature not implemented
    assign csr_tdata1_rd[19]    = 1'b0;                         // select: fire on address match
    assign csr_tdata1_rd[18]    = 1'b1;                         // timing: trigger AFTER executing the programmed instruction address
    assign csr_tdata1_rd[17:16] = 2'b00;                        // sizelo: match against an access of any size
    assign csr_tdata1_rd[15:12] = {3'b000, csr_tdata1_action};  // action = 1: enter debug mode on trigger, action = 0: ebreak exception on trigger
    assign csr_tdata1_rd[11]    = 1'b0;                         // chain: chaining not supported - there is only one trigger
    assign csr_tdata1_rd[10:7]  = 4'b0000;                      // match: only full-address-match
    assign csr_tdata1_rd[6]     = 1'b1;                         // m: trigger always enabled when in machine mode
    assign csr_tdata1_rd[5]     = 1'b0;                         // h: hypervisor mode not supported
    assign csr_tdata1_rd[4]     = 1'b0;                         // s: supervisor mode not supported
    assign csr_tdata1_rd[3]     = (CPU_EXTENSION_RISCV_U == 1)? 1'b1: 1'b0; // u: trigger always enabled when in user mode
    assign csr_tdata1_rd[2]     = csr_tdata1_exe;               // execute: enable trigger
    assign csr_tdata1_rd[1]     = 1'b0;                         // store: store address or data matching not supported
    assign csr_tdata1_rd[0]     = 1'b0;                         // load: load address or data matching not supported    

    assign o_csr_rdata = csr_rdata;
    
    // External CSR Interface  
    assign o_xcsr_we    = csr_we;
    assign o_xcsr_addr  = csr_addr;
    assign o_xcsr_wdata = csr_wdata;
    assign xcsr_rdata = i_xcsr_rdata;
    
endmodule
