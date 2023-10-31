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
    parameter PMP_EN                        = 1  // Enable physical memory protection
)
(

    // Global control
    input wire              i_clk,
    input wire              i_rstn,
    // // Output control signals
    // //-- Register file
    // output wire             o_ctrl_rf_wb_en,    // write back enable
    // output wire [4:0]       o_ctrl_rf_rs1,      // source register 1 address
    // output wire [4:0]       o_ctrl_rf_rs2,      // source register 2 address
    // output wire [4:0]       o_ctrl_rf_rs3,      // source register 3 address
    // output wire [4:0]       o_ctrl_rf_rd,       // destination register address
    // output wire [1:0]       o_ctrl_rf_mux,      // input source select
    // output wire             o_ctrl_rf_zero_we,  // allow/force write access to x0
    // //-- ALU
    // output wire [2:0]       o_ctrl_alu_op,      // ALU operation select
    // output wire             o_ctrl_alu_opa_mux, // operand A select (0=rs1, 1=PC)
    // output wire             o_ctrl_alu_opb_mux, // operand B select (0=rs2, 1=IMM)
    // output wire             o_ctrl_alu_unsigned,// is unsigned ALU operation
    // output wire [4:0]       o_ctrl_alu_cp_trig, // co-processor trigger (one-hot)
    // //-- load/store unit
    // output wire             o_ctrl_lsu_req_rd,  // trigger memory read request
    // output wire             o_ctrl_lsu_req_wr,  // trigger memory write request
    // output wire             o_ctrl_lsu_rw,      // 0: read access, 1: write access
    // output wire             o_ctrl_lsu_mo_we,   // memory address and data output register write enable
    // output wire             o_ctrl_lsu_fence,   // fence operation
    // output wire             o_ctrl_lsu_fencei,  // fence.i operation
    // output wire             o_ctrl_lsu_priv,    // effective privilege level for load/store
    // //-- Instruction
    // output wire [2:0]       o_ctrl_ir_funct3,   // funct3 bit field
    // output wire [11:0]      o_ctrl_ir_funct12,  // funct12 bit field
    // output wire [6:0]       o_ctrl_ir_opcode,   // opcode bit field
    // //-- CPU status
    // output wire             o_ctrl_cpu_priv,    // effective privilege mode
    // output wire             o_ctrl_cpu_sleep,   // set when CPU is in sleep mode
    // output wire             o_ctrl_cpu_trap,    // set when CPU is entering trap exec
    // output wire             o_ctrl_cpu_debug,   // set when CPU is in debug mode
    
    // Instruction fetch
    output wire [XLEN-1:0]  o_bus_req_addr, // access address
    output wire  [XLEN-1:0] o_bus_req_data, // write data
    output wire  [3:0]      o_bus_req_ben,  // byte enable
    output wire             o_bus_req_we,   // write request
    output wire             o_bus_req_re,   // read request
    output wire             o_bus_req_src,  // access source (1=instruction fetch, 0=data access)
    output wire             o_bus_req_priv, // set if privileged (machine-mode) access
    output wire             o_bus_req_rvso, // set if reservation set operation (atomic LR/SC)
    input wire  [XLEN-1:0]  i_bus_rsp_data, // read data
    input wire              i_bus_rsp_ack,  // access acknowledge
    input wire              i_bus_rsp_err,  // access error
    // // Status input
    // input wire              i_pmp_fault,     // instruction fetch pmp fault
    // input wire              i_alu_cp_done,   // ALU coprocessor done
    // input wire              i_lsu_wait,      // wait for data bus
    // input wire              i_cmp_eq,        // comparator equal
    // input wire              i_cmp_lt,        // comparator less than
    // // Data input
    // input wire  [XLEN-1:0]  i_alu_addr,      // ALU address result,
    // input wire  [XLEN-1:0]  i_rs1,           // rf source 1
    // // Data output
    // output wire [XLEN-1:0]  o_imm,           // immediate
    // output wire [XLEN-1:0]  o_fetch_pc,      // instruction fetch
    // output wire [XLEN-1:0]  o_curr_pc,       // current pc
    // output wire [XLEN-1:0]  o_next_pc,       // next pc
    // output wire [XLEN-1:0]  o_csr_rdata,     // csr read data
    // // External CSR interface
    // output wire             o_xcsr_we,       // write enable
    // output wire [11:0]      o_xcsr_addr,     // address
    // output wire [XLEN-1:0]  o_xcsr_wdata,    // write data
    // input  wire [XLEN-1:0]  i_xcsr_rdata,    // read data
    // // Interrupt
    // input  wire             i_db_halt_req,   // debug mode (halt) request
    // input  wire             i_msi,           // machine software interrupt
    // input  wire             i_mei,           // machine external interrupt
    // input  wire             i_mti,           // machine timer interrupt
    // input  wire [15:0]      i_firq,          // fast interrupt
    // // Bus access exception
    // input  wire [XLEN-1:0]  i_mar,           // memory address register
    // input  wire             i_ma_load,       // misaligned load data address
    // input  wire             i_ma_store,      // misaligned store data address
    // input  wire             i_be_load,       // bus error on load data access
    // input  wire             i_be_store       // bus error store data access   
);

    localparam THREAD_NUM = 4;

    // Instruction prefetch buffer (FIFO)
    localparam IPB_DATA_WIDTH       = 2 + 16;   // {bus_error, align_error, 16-bit instruciton}
    localparam INSTR_BUFFER_DEPTH   = 8;        // instruction prefetch buffer depth

    wire [1:0]                ibp_free      [THREAD_NUM-1:0];  // free entry
    wire [IPB_DATA_WIDTH-1:0] ipb_rdata_0   [THREAD_NUM-1:0];  // read data
    wire [IPB_DATA_WIDTH-1:0] ipb_rdata_1   [THREAD_NUM-1:0];  // read data
    wire [1:0]                ibp_avail     [THREAD_NUM-1:0];  // data available
    wire [IPB_DATA_WIDTH-1:0] ipb_wdata_0   [THREAD_NUM-1:0];  // write data
    wire [IPB_DATA_WIDTH-1:0] ipb_wdata_1   [THREAD_NUM-1:0];  // write data
    wire [1:0]                ipb_we        [THREAD_NUM-1:0];  // write enable
    wire [1:0]                ipb_re        [THREAD_NUM-1:0];  // read enable

    // Instruction fetch
    localparam IF_RESTART = 3'b000,
              IF_PEND = 2'b001,
              IF_REQ0 = 3'b100,
              IF_REQ1 = 3'b101,
              IF_REQ2 = 3'b110,
              IF_REQ3 = 3'b111;
              
    reg [2:0]             if_state;
    reg [2:0]             if_nstate;
    // reg [2:0]             if_prevstate;
    reg                   if_restart;
    reg [THREAD_NUM-1:0]  if_unaligned;    
    reg [XLEN-1:0]        if_pc [THREAD_NUM-1:0];
    wire                  if_reset;
    wire                  if_resp;    // bus response
    wire                  if_a_err;   // alignment error
    wire [THREAD_NUM-1:0] if_avail;   // thread available

//=================================================================================================================
// Instruction Fetch (always fetch 32-bit-aligned 32-bit chunks of data)
//=================================================================================================================    
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) if_state <= IF_RESTART;
        else if_state <= if_nstate;
    end
    
    always @(*) begin
        case (if_state)
            IF_RESTART: if_nstate = IF_PEND;
            IF_PEND:    if_nstate = (&if_avail[0])? IF_REQ0:
                                    (&if_avail[1])? IF_REQ1:
                                    (&if_avail[2])? IF_REQ2:
                                    (&if_avail[3])? IF_REQ3: IF_PEND;
            IF_REQ0:    if_nstate = (&if_avail[1])? IF_REQ1:
                                    (&if_avail[2])? IF_REQ2:
                                    (&if_avail[3])? IF_REQ3:
                                    (&if_avail[0])? IF_REQ0: IF_PEND;
            IF_REQ1:    if_nstate = (&if_avail[2])? IF_REQ2:
                                    (&if_avail[3])? IF_REQ3:
                                    (&if_avail[0])? IF_REQ0:
                                    (&if_avail[1])? IF_REQ1: IF_PEND;
            IF_REQ2:    if_nstate = (&if_avail[3])? IF_REQ3:
                                    (&if_avail[0])? IF_REQ0:
                                    (&if_avail[1])? IF_REQ1:
                                    (&if_avail[2])? IF_REQ2: IF_PEND;
            IF_REQ3:    if_nstate = (&if_avail[0])? IF_REQ0:
                                    (&if_avail[1])? IF_REQ1:
                                    (&if_avail[2])? IF_REQ2:
                                    (&if_avail[3])? IF_REQ3: IF_PEND;
        endcase
    end

    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            if_restart <= 1'b1;
            if_pc[0] <= {32{1'b0}};
            if_pc[1] <= {32{1'b0}};
            if_pc[2] <= {32{1'b0}};
            if_pc[3] <= {32{1'b0}};
        end
        else begin
            if (if_state == IF_RESTART) if_restart <= 1'b0;
            else if_restart <= if_restart || if_reset;

            if (if_state == IF_RESTART) begin
                if_pc[0] <= 32'd0;
                if_pc[1] <= 32'd0;
                if_pc[2] <= 32'd0;
                if_pc[3] <= 32'd0;
            end
            else begin
                if (if_state == IF_REQ0) if_pc[0] <= if_pc[0] + 4;
                if (if_state == IF_REQ1) if_pc[1] <= if_pc[1] + 4;
                if (if_state == IF_REQ2) if_pc[2] <= if_pc[2] + 4;
                if (if_state == IF_REQ3) if_pc[3] <= if_pc[3] + 4;
            end
        end
    end

    assign if_avail[0] = &ibp_avail[0];
    assign if_avail[1] = &ibp_avail[1];
    assign if_avail[2] = &ibp_avail[2];
    assign if_avail[3] = &ibp_avail[3]; 

///================================================================================================================
// Instruction Prefetch Buffer (FIFO)
//=================================================================================================================
    ip_fifo #(
        .FIFO_DEPTH (INSTR_BUFFER_DEPTH ), // number of fifo entries; has to be a power of two; min 1
        .FIFO_WIDTH (IPB_DATA_WIDTH     ), // size of data elements in fifo
        .FIFO_RSYNC (0                  ), // 0 = async read; 1 = sync read
        .FIFO_SAFE  (0                  )  // 1 = allow read/write only if entry available  -- -------------------------------------------------------------------------------------------
    ) prefetch_buffer0[1:0] (
        // Global control
        .i_clk      ( i_clk        ),   // global clock, rising edge
        .i_rstn     ( i_rstn       ),  // global reset, low-active, async
        // Control signal
        .i_clear    ( if_restart   ), // sync reset, high-active
        .o_half     (              ),  // FIFO is half full
        // Write port
        .i_wdata    ( {ipb_wdata_1[0], ipb_wdata_0[0]} ), // write data
        .i_we       ( ipb_we[0]    ),    // write enable
        .o_free     ( ibp_free[0]  ),  // at least one entry is free when set
        // Read port
        .i_re       ( ipb_re[0]    ),    // read enable
        .o_rdata    ( {ipb_rdata_1[0], ipb_rdata_0[0]} ), // read data
        .o_avail    ( ibp_avail[0] )  // data available when set
    );

    ip_fifo #(
        .FIFO_DEPTH (INSTR_BUFFER_DEPTH ), // number of fifo entries; has to be a power of two; min 1
        .FIFO_WIDTH (IPB_DATA_WIDTH     ), // size of data elements in fifo
        .FIFO_RSYNC (0                  ), // 0 = async read; 1 = sync read
        .FIFO_SAFE  (0                  )  // 1 = allow read/write only if entry available  -- -------------------------------------------------------------------------------------------
    ) prefetch_buffer1[1:0] (
        // Global control
        .i_clk      ( i_clk        ),   // global clock, rising edge
        .i_rstn     ( i_rstn       ),  // global reset, low-active, async
        // Control signal
        .i_clear    ( if_restart   ), // sync reset, high-active
        .o_half     (              ),  // FIFO is half full
        // Write port
        .i_wdata    ( {ipb_wdata_1[1], ipb_wdata_0[1]} ), // write data
        .i_we       ( ipb_we[1]    ),    // write enable
        .o_free     ( ibp_free[1]  ),  // at least one entry is free when set
        // Read port
        .i_re       ( ipb_re[1]    ),    // read enable
        .o_rdata    ( {ipb_rdata_1[1], ipb_rdata_0[1]} ), // read data
        .o_avail    ( ibp_avail[1] )  // data available when set
    );

    ip_fifo #(
        .FIFO_DEPTH (INSTR_BUFFER_DEPTH ), // number of fifo entries; has to be a power of two; min 1
        .FIFO_WIDTH (IPB_DATA_WIDTH     ), // size of data elements in fifo
        .FIFO_RSYNC (0                  ), // 0 = async read; 1 = sync read
        .FIFO_SAFE  (0                  )  // 1 = allow read/write only if entry available  -- -------------------------------------------------------------------------------------------
    ) prefetch_buffer2[1:0] (
        // Global control
        .i_clk      ( i_clk        ),   // global clock, rising edge
        .i_rstn     ( i_rstn       ),  // global reset, low-active, async
        // Control signal
        .i_clear    ( if_restart   ), // sync reset, high-active
        .o_half     (              ),  // FIFO is half full
        // Write port
        .i_wdata    ( {ipb_wdata_1[2], ipb_wdata_0[2]} ), // write data
        .i_we       ( ipb_we[2]    ),    // write enable
        .o_free     ( ibp_free[2]  ),  // at least one entry is free when set
        // Read port
        .i_re       ( ipb_re[2]    ),    // read enable
        .o_rdata    ( {ipb_rdata_1[2], ipb_rdata_0[2]} ), // read data
        .o_avail    ( ibp_avail[2] )  // data available when set
    );

    ip_fifo #(
        .FIFO_DEPTH (INSTR_BUFFER_DEPTH ), // number of fifo entries; has to be a power of two; min 1
        .FIFO_WIDTH (IPB_DATA_WIDTH     ), // size of data elements in fifo
        .FIFO_RSYNC (0                  ), // 0 = async read; 1 = sync read
        .FIFO_SAFE  (0                  )  // 1 = allow read/write only if entry available  -- -------------------------------------------------------------------------------------------
    ) prefetch_buffer3[1:0] (
        // Global control
        .i_clk      ( i_clk        ),   // global clock, rising edge
        .i_rstn     ( i_rstn       ),  // global reset, low-active, async
        // Control signal
        .i_clear    ( if_restart   ), // sync reset, high-active
        .o_half     (              ),  // FIFO is half full
        // Write port
        .i_wdata    ( {ipb_wdata_1[3], ipb_wdata_0[3]} ), // write data
        .i_we       ( ipb_we[3]    ),    // write enable
        .o_free     ( ibp_free[3]  ),  // at least one entry is free when set
        // Read port
        .i_re       ( ipb_re[3]    ),    // read enable
        .o_rdata    ( {ipb_rdata_1[3], ipb_rdata_0[3]} ), // read data
        .o_avail    ( ibp_avail[3] )  // data available when set
    );

endmodule
