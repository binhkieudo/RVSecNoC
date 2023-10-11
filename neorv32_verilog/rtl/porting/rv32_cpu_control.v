`include "rv32_package.vh"

module rv32_cpu_control #(
    parameter XLEN                          = 32,
    parameter HART_ID                       = 0,  // hardware thread ID (HART)
    parameter VENDOR_ID                     = 0,  // vendor's JEDEC ID
    parameter CPU_BOOT_ADR                  = 0,  // cpu boot address
    parameter CPU_DEBUG_PARK_ADDR           = 0,  // cpu debug mode parking loop entry address
    parameter CPU_DEBUG_EXC_ADDR            = 0,  // cpu debug mode exception entry address
    parameter INSTR_BUFFER_DEPTH            = 4,  // instruction prefetch buffer depth
    // Extensions
    parameter CPU_EXTENSION_RISCV_A         = 1,  // Atomic
    parameter CPU_EXTENSION_RISCV_C         = 1,  // Compress
    parameter CPU_EXTENSION_RISCV_M         = 0,  // Mul/div
    parameter CPU_EXTENSION_RISCV_U         = 0,  // User mode
    parameter CPU_EXTENSION_RISCV_F         = 0,  // Single-precision
    parameter CPU_EXTENSION_RISCV_D         = 0,  // Double-precision
    parameter CPU_EXTENSION_RISCV_Zicntr    = 1,  // Base counter
    parameter CPU_EXTENSION_RISCV_Zihpm     = 1,  // Hardware performance monitor
    parameter CPU_EXTENSION_RISCV_Zifencei  = 1,  // Insctruction sync
    parameter CPU_EXTENSION_RISCV_Zmmul     = 1,  // Only mul (override by M extension)
    parameter CPU_EXTENSION_RISCV_Zxcfu     = 0,  // Custrom instruction
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
    output reg  [XLEN-1:0]  o_bus_req_data, // write data
    output reg  [3:0]       o_bus_req_ben,  // byte enable
    output wire             o_bus_req_we,   // write request
    output wire             o_bus_req_re,   // read request
    output wire             o_bus_req_src,  // access source (1=instruction fetch, 0=data access)
    output reg              o_bus_req_priv, // set if privileged (machine-mode) access
    output reg              o_bus_req_rvso, // set if reservation set operation (atomic LR/SC)
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
    input  wire [XLEN-1:0]  o_xcsr_rdata,    // read data
    // Interrupt
    input  wire             i_db_halt_req,   // debug mode (halt) request
    input  wire             i_msi,           // machine software interrupt
    input  wire             i_mei,           // machine external interrupt
    input  wire             i_mti,           // machine timer interrupt
    input  wire             i_firq,          // fast interrupt
    // Bus access exception
    input  wire [XLEN-1:0]  i_mar,           // memory address register
    input  wire             i_ma_load,       // misaligned load data address
    input  wire             i_ma_store,      // misaligned store data address
    input  wire             i_be_load,       // bus error on load data access
    input  wire             i_be_store       // bus error store data access   
)

  //CPU Trap System ------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- exception source bits --
  constant exc_iaccess_c  : natural :=  0; -- instruction access fault
  constant exc_illegal_c  : natural :=  1; -- illegal instruction
  constant exc_ialign_c   : natural :=  2; -- instruction address misaligned
  constant exc_ecall_c    : natural :=  3; -- environment call
  constant exc_ebreak_c   : natural :=  4; -- breakpoint
  constant exc_salign_c   : natural :=  5; -- store address misaligned
  constant exc_lalign_c   : natural :=  6; -- load address misaligned
  constant exc_saccess_c  : natural :=  7; -- store access fault
  constant exc_laccess_c  : natural :=  8; -- load access fault
  -- for debug mode only --
  constant exc_db_break_c : natural :=  9; -- enter debug mode via ebreak instruction ("sync EXCEPTION")
  constant exc_db_hw_c    : natural := 10; -- enter debug mode via hw trigger ("sync EXCEPTION")

    // Intermediate reg
    reg [XLEN-1:0]  ro_imm;

    // Instruction prefetch buffer (FIFO)
    parameter IPB_DATA_WIDTH = 2 + 16; // {bus_error, align_error, 16-bit instruciton}
    wire [IPB_DATA_WIDTH-1:0] ipb_wdata [0:1];  // write data
    wire [1:0]                ipb_we;           // write enable
    reg  [1:0]                ibp_free;         // free entry
    reg  [IPB_DATA_WIDTH-1:0] ipb_rdata [0:1];  // read data
    wire [1:0]                ipb_re;           // read enable
    reg  [1:0]                ibp_avail;        // data available

    // Instruction issue (is)
    reg               is_align;
    reg               is_align_set;
    reg               is_align_clr;
    wire [15:0]       is_ci_i16;
    wire [31:0]       is_ci_i32;
    reg  [(3+32)-1:0] is_data; // 3-bit status + 32-bit instruction
    reg  [1:0]        is_valid; // data word is valid
    reg               is_ack;

    // Instruction fetch
    parameter IF_RESTART = 2'b00,
              IF_REQUEST = 2'b01,
              IF_PENDING = 2'b10;

    reg [1:0] if_state, if_next, if_prev;
    reg             if_restart;
    reg             if_unaligned;    
    reg [XLEN-1:2]  if_pc;
    reg             if_reset;
    wire            if_resp;    // bus response
    wire            if_a_err;   // alignment error

    // Instruction decode (id)
    reg [6:0]  id_opcode;
    reg        id_is_alr; // is atomic load reserve
    reg        id_is_asc; // is atomic store condition
    reg        id_is_fop; // is floating point instruction
    reg        id_is_mul; // is multiplication instruction
    reg        id_is_div; // is division instruction
    reg        id_rs1_zero; // rs1 is zero
    reg        id_rd_zero;  // rd is zero

    // Instruction execution (ie)
    parameter IE_DISPATCH       = 4'b0000,
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
    // reg [3:0]      ie_prev; 
    // reg [3:0]      ie_prev2;
    reg  [31:0]     ie_ir; 
    // reg [31:0]     ie_ir_next;
    reg             ie_is_ci; // current instruction is decompressed or not
    // reg             ie_is_ci_next;
    wire            ie_branch_taken;
    reg  [XLEN-1:0] ie_pc;
    wire            ie_pc_mux_sel; // source select for PC update
    reg             ie_pc_we;      // pc update enable
    reg  [XLEN-1:0] ie_next_pc;    // next PC
    wire [XLEN-1:0] ie_next_pc_inc; // increment to get next PC
    reg             ie_branched; // increment to get next PC
    // reg            ie_branched_next; 

    // Instruction monitor (monitor): raise exception if multi-cycle operation times out (default = 512-cycle)
    reg [9:0]      monitor_cnt;
    reg [9:0]      monitor_cnt_add;
    reg            monitor_exc;

    // Trap controller (trap_ctrl)
    reg [10:0]     trap_ctrl_exc_buf;       // synchronous exception buffer (one bit per exception)
    reg            trap_ctrl_exc_fire;      // set if there is a valid source in the exception buffer
    reg [20:0]     trap_ctrl_irq_pnd;       // pending interrupt
    reg [20:0]     trap_ctrl_irq_buf;       // asynchronous exception/interrupt buffer (one bit per interrupt source)
    reg            trap_ctrl_irq_fire;      // set if an interrupt is actually kicking in
    reg [6:0]      trap_ctrl_cause;         // trap ID for mcause CSR & debug-mode entry identifier 
    reg [XLEN-1:0] trap_ctrl_epc;           // exception program counter
    reg            trap_ctrl_env_pending;   // start of trap environment if pending
    reg            trap_ctrl_env_enter;     // enter trap environment
    reg            trap_ctrl_env_exit;      // leave trap environment
    reg            trap_ctrl_wakeup;        // wakeup from sleep due to an enabled pending IRQ
    reg            trap_ctrl_instr_be;      // instruction fetch bus error
    reg            trap_ctrl_instr_ma;      // instruction fetch misaligned address
    reg            trap_ctrl_instr_il;      // illegal instruction
    reg            trap_ctrl_env_call;      // ecall instruction
    reg            trap_ctrl_break_point;   // ebreak instruction

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
    reg             ctrl_lsu_mo_we;   // memory address and data output register write enable
    reg             ctrl_lsu_fence;   // fence operation
    reg             ctrl_lsu_fencei;  // fence.i operation
    reg             ctrl_lsu_priv;    // effective privilege level for load/store
    reg [2:0]       ctrl_ir_funct3;   // funct3 bit field
    reg [11:0]      ctrl_ir_funct12;  // funct12 bit field
    reg [6:0]       ctrl_ir_opcode;   // opcode bit field
    reg             ctrl_cpu_priv;    // effective privilege mode
    reg             ctrl_cpu_sleep;   // set when CPU is in sleep mode
    reg             ctrl_cpu_trap;    // set when CPU is entering trap exec
    reg             ctrl_cpu_debug;   // set when CPU is in debug mode

    reg             ctrl_next_rf_wb_en;    // write back enable
    reg [4:0]       ctrl_next_rf_rs1;      // source register 1 address
    reg [4:0]       ctrl_next_rf_rs2;      // source register 2 address
    reg [4:0]       ctrl_next_rf_rs3;      // source register 3 address
    reg [4:0]       ctrl_next_rf_rd;       // destination register address
    reg [1:0]       ctrl_next_rf_mux;      // input source select
    reg             ctrl_next_rf_zero_we;  // allow/force write access to x0
    reg [2:0]       ctrl_next_alu_op;      // ALU operation select
    reg             ctrl_next_alu_opa_mux; // operand A select (0=rs1; 1=PC)
    reg             ctrl_next_alu_opb_mux; // operand B select (0=rs2; 1=IMM)
    reg             ctrl_next_alu_unsigned;// is unsigned ALU operation
    reg [4:0]       ctrl_next_alu_cp_trig; // co-processor trigger (one-hot)
    reg             ctrl_next_lsu_req_rd;  // trigger memory read request
    reg             ctrl_next_lsu_req_wr;  // trigger memory write request
    reg             ctrl_next_lsu_rw;      // 0: read access; 1: write access
    reg             ctrl_next_lsu_mo_we;   // memory address and data output register write enable
    reg             ctrl_next_lsu_fence;   // fence operation
    reg             ctrl_next_lsu_fencei;  // fence.i operation
    reg             ctrl_next_lsu_priv;    // effective privilege level for load/store
    reg [2:0]       ctrl_next_ir_funct3;   // funct3 bit field
    reg [11:0]      ctrl_next_ir_funct12;  // funct12 bit field
    reg [6:0]       ctrl_next_ir_opcode;   // opcode bit field
    reg             ctrl_next_cpu_priv;    // effective privilege mode
    reg             ctrl_next_cpu_sleep;   // set when CPU is in sleep mode
    reg             ctrl_next_cpu_trap;    // set when CPU is entering trap exec
    reg             ctrl_next_cpu_debug;   // set when CPU is in debug mode

    // Control and status register (CSR)
    reg [11:0]      csr_addr;               // csr address
    reg [11:0]      csr_raddr;              // simplified csr read address
    reg             csr_we;                 // csr write enable
    reg             csr_we_nxt;             // csr write enable
    reg             csr_re;                 // csr read enable
    reg             csr_re_nxt;             // csr read enable
    reg [XLEN-1:0]  csr_wdata;              // csr write
    reg [XLEN-1:0]  csr_rdata;              // read data
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
    reg             csr_privilege_eff;      // current *effective* privilege mode
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
    reg [XLEN-1:0]  csr_dcsr_rd;            // debug mode control and status register
    reg [XLEN-1:0]  csr_dpc;                // mode program counter
    reg [XLEN-1:0]  csr_dscratch0;          // debug mode scratch register 0
    reg             csr_tdata1_exe;         // enable (match) trigger
    reg             csr_tdata1_action;      // enter debug mode / ebreak exception when trigger fires
    reg             csr_tdata1_dmode;       // set to ignore tdata* CSR access from machine-mode
    reg [XLEN-1:0]  csr_tdata1_rd;          // trigger register read-back
    reg [XLEN-1:0]  csr_tdata2;             // address-match register

    // Debug module controller (dbg)
    reg             dbg_running;            // CPU is in debug mode
    reg             dbg_trig_hw;            // hardware trigger
    reg             dbg_trig_break;         // ebreak instruction trigger
    reg             dbg_trig_halt;          // external request trigger
    reg             dbg_trig_step;          // single-stepping mode trigger
    reg             dbg_ext_halt_req;       // external halt request buffer

    // Illegal instruction check
    reg             illegal_cmd;

    // CSR access/privilege/read-write check
    reg             csr_reg_valid;          // CSR implemented at all
    reg             csr_rw_valid;           // valid r/w access rights
    reg             csr_priv_valid;         // valid access privilege

    // CSR read-back data
    reg [XLEN-1:0]  csr_rdata;
    reg [XLEN-1:0]  xcsr_rdata;

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
    assign o_bus_req_re     = (if_state == IF_REQUEST) && (ipb.free == 2'b11);

    // Unaligned access error (no alignment exceptions possible when using C-extension)
    assign if_a_err = if_unaligned && (CPU_EXTENSION_RISCV_C == 0);

    // Instruction bus response
    // PMP and alignment errors will keep pending until the triggered bus access request retires
    assign if_resp = i_bus_rsp_ack || i_bus_rsp_err;

    // IPB instruction data and status
    assign ipb_wdata[0] = {i_bus_rsp_err || i_pmp_fault, if_a_err, i_bus_rsp_data[15:0]};
    assign ipb_wdata[1] = {i_bus_rsp_err || i_pmp_fault, if_a_err, i_bus_rsp_data[31:16]};

    // IPB write enable
    assign ipb_we[0] = (if_state == IF_PENDING) && if_resp &&
                       (!if_unaligned || (CPU_EXTENSION_RISCV_C == 0));
    assign ipb_we[1] = (if_state == IF_PENDING) && if_resp;

    // Bus access type
    assign o_bus_req_priv = ctrl_cpu_priv;
    assign o_bus_req_data = {XLEN{1'b0}}; // read only
    assign o_bus_req_ben  = 4'b0000; // read only
    assign o_bus_req_we   = 1'b0; // read only
    assign o_bus_req_src  = 1'b1; // instruction fetch
    assign o_bus_req_rvso = 1'b0; // cannot be a reservation set operation

///=================================================================================================================
// Instruction Prefetch Buffer (FIFO)
//=================================================================================================================
    ip_fifo prefetch_buffer0 #(
        .FIFO_DEPTH (INSTR_BUFFER_DEPTH ), // number of fifo entries; has to be a power of two; min 1
        .FIFO_WIDTH (IPB_DATA_WIDTH     ), // size of data elements in fifo
        .FIFO_RSYNC (0                  ), // 0 = async read; 1 = sync read
        .FIFO_SAFE  (0                  )  // 1 = allow read/write only if entry available
    ) 
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
        .o_avail    ( ipb[0]       )  // data available when set
    );

    ip_fifo prefetch_buffer1 #(
        .FIFO_DEPTH (INSTR_BUFFER_DEPTH ), // number of fifo entries; has to be a power of two; min 1
        .FIFO_WIDTH (IPB_DATA_WIDTH     ), // size of data elements in fifo
        .FIFO_RSYNC (0                  ), // 0 = async read; 1 = sync read
        .FIFO_SAFE  (0                  )  // 1 = allow read/write only if entry available
    ) 
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
        .o_avail    ( ipb[1]       )  // data available when set
    );

//=================================================================================================================
// Instruction Issue (decompress 16-bit instructions and assemble a 32-bit instruction word)
//=================================================================================================================
    
    // Compressed Instruction decode
    generate
        if (CPU_EXTENSION_RISCV_C == 1) begin: gen_decompressor
            rv32_cpu_decompressor #(
                .FPU_ENABLE = (CPU_EXTENSION_RISCV_F == 1) || (CPU_EXTENSION_RISCV_D == 1)
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

    assign is_ci_i16 = is_align? ipb_rdata[1][15:0]: ipb_rdata[0][15:0];
    assign ipb_re[0] = is_valid[0] && is_ack;
    assign ipb_re[1] = is_valid[1] && is_ack;

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

    // Branch Condition Check (eq: beq / bne, lt: blt(u) / bge(u))
    assign ie_branch_taken = ir_funct3[0] ^ (!ir_funct3[2]? i_cmp_eq: i_cmp_lt); 

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
                    default:    : ie_next = IE_SYSTEM;    
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
                    trap_ctrl_exc_buf['EXC_LALIGN]  || trap_ctrl_exc_buf[`EXC_SALIGN])      // alignment error
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

    // PC output
    assign o_curr_pc = {ie_pc[XLEN-1:1], 1'b0};
    assign o_next_pc = {ie_next_pc[XLEN-1:1], 1'b0}; 

endmodule
