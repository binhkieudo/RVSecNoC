module rv32_cpu_control #(
    parameter XLEN                          = 32,
    parameter HART_ID                       = 0,  // hardware thread ID (HART)
    parameter VENDOR_ID                     = 0,  // vendor's JEDEC ID
    parameter CPU_BOOT_ADR                  = 0,  // cpu boot address
    parameter CPU_DEBUG_PARK_ADDR           = 0,  // cpu debug mode parking loop entry address
    parameter CPU_DEBUG_EXC_ADDR            = 0,  // cpu debug mode exception entry address
    // Extensions
    parameter CPU_EXTENSION_RISCV_A         = 1,  // Atomic
    parameter CPU_EXTENSION_RISCV_C         = 1,  // Compress
    parameter CPU_EXTENSION_RISCV_M         = 0,  // Mul/div
    parameter CPU_EXTENSION_RISCV_U         = 0,  // User mode
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
    input wire i_clk,
    input wire i_rstn,
    // Output control signals
    // Instruction fetch
    output wire [XLEN-1:0] o_bus_req_addr, // access address
    output reg  [XLEN-1:0] o_bus_req_data, // write data
    output reg  [3:0]      o_bus_req_ben,  // byte enable
    output wire            o_bus_req_we,   // write request
    output wire            o_bus_req_re,   // read request
    output wire            o_bus_req_src,  // access source (1=instruction fetch, 0=data access)
    output reg             o_bus_req_priv, // set if privileged (machine-mode) access
    output reg             o_bus_req_rvso, // set if reservation set operation (atomic LR/SC)
    input wire  [XLEN-1:0] i_bus_rsp_data, // read data
    input wire             i_bus_rsp_ack,  // access acknowledge
    input wire             i_bus_rsp_err,  // access error
    // Status input
    input wire             i_pmp_fault,     // instruction fetch pmp fault
    input wire             i_alu_cp_done,   // ALU coprocessor done
    input wire             i_lsu_wait,      // wait for data bus
    input wire             i_cmp,           // comparator status
    // Data input
    input wire  [XLEN-1:0] i_alu_addr,      // ALU address result,
    input wire  [XLEN-1:0] i_rs1,           // rf source 1
    // Data output
    output wire [XLEN-1:0] o_imm,           // immediate
    output wire [XLEN-1:0] o_fetch_pc,      // instruction fetch
    output wire [XLEN-1:0] o_curr_pc,       // current pc
    output wire [XLEN-1:0] o_next_pc,       // next pc
    output wire [XLEN-1:0] o_csr_rdata,     // csr read data
    // External CSR interface
    output wire            o_xcsr_we,       // write enable
    output wire [11:0]     o_xcsr_addr,     // address
    output wire [XLEN-1:0] o_xcsr_wdata,    // write data
    input  wire [XLEN-1:0] o_xcsr_rdata,    // read data
    // Interrupt
    input  wire            i_db_halt_req,   // debug mode (halt) request
    input  wire            i_msi,           // machine software interrupt
    input  wire            i_mei,           // machine external interrupt
    input  wire            i_mti,           // machine timer interrupt
    input  wire            i_firq,          // fast interrupt
    // Bus access exception
    input  wire [XLEN-1:0] i_mar,           // memory address register
    input  wire            i_ma_load,       // misaligned load data address
    input  wire            i_ma_store,      // misaligned store data address
    input  wire            i_be_load,       // bus error on load data access
    input  wire            i_be_store       // bus error store data access   
)

    // Instruction fetch
    reg [1:0] if_state, if_next;
    reg             if_restart;
    reg             if_unaligned;    
    reg [XLEN-1:2]  if_pc;
    reg             if_reset;
    reg             if_resp;    // bus response
    reg             if_a_err;   // alignment error

    // Instruction prefetch buffer (FIFO)
    reg [(2+16)-1:0] ipb_wdata [0:1]; // {bus_error, align_error, 16-bit instruciton}
    reg [1:0]        ipb_we; // write enable
    reg [1:0]        ibp_free; // free entry
    reg [(2+16)-1:0] ipb_rdata [0:1]; // read data
    reg [1:0]        ipb_re;
    reg [1:0]        ibp_avail; // data available

    // Instruction issue (is)
    

endmodule
