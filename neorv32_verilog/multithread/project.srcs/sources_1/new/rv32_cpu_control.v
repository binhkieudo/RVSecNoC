`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2023 12:41:12 AM
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
    parameter THREAD_COUNT                  = 8,
    parameter HART_ID                       = 0,  // hardware thread ID (HART)
    parameter VENDOR_ID                     = 0,  // vendor's JEDEC ID
    parameter CPU_BOOT_ADR                  = 0,  // cpu boot address
    parameter HW_VERSION                    = 32'h01080906,
    parameter CPU_DEBUG_PARK_ADDR           = 0,  // cpu debug mode parking loop entry address
    parameter CPU_DEBUG_EXC_ADDR            = 0,  // cpu debug mode exception entry address
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
    // Output control signals
    //-- Register file
    output wire [THREAD_COUNT-1:0]      o_ctrl_rf_wb_en,    // write back enable
    output wire [THREAD_COUNT*5-1:0]    o_ctrl_rf_rs1,      // source register 1 address
    output wire [THREAD_COUNT*5-1:0]    o_ctrl_rf_rs2,      // source register 2 address
    output wire [THREAD_COUNT*5-1:0]    o_ctrl_rf_rd,       // destination register address
    output wire [THREAD_COUNT*2-1:0]    o_ctrl_rf_mux,      // input source select
    output wire [THREAD_COUNT-1:0]      o_ctrl_rf_zero_we,  // allow/force write access to x0
    //-- ALU
    output wire [THREAD_COUNT*3-1:0]    o_ctrl_alu_op,      // ALU operation select
    output wire [THREAD_COUNT-1:0]      o_ctrl_alu_opa_mux, // operand A select (0=rs1, 1=PC)
    output wire [THREAD_COUNT-1:0]      o_ctrl_alu_opb_mux, // operand B select (0=rs2, 1=IMM)
    output wire [THREAD_COUNT-1:0]      o_ctrl_alu_unsigned,// is unsigned ALU operation
    //-- Instruction
    output wire [THREAD_COUNT*3-1:0]    o_ctrl_ir_funct3,   // funct3 bit field
    output wire [THREAD_COUNT*12-1:0]   o_ctrl_ir_funct12,  // funct12 bit field
    output wire [THREAD_COUNT*7-1:0]    o_ctrl_ir_opcode,   // opcode bit field
    // Instruction fetch
    output wire [THREAD_COUNT*XLEN-1:0] o_bus_req_addr, // access address
    output wire [THREAD_COUNT-1:0]      o_bus_req_re,   // read request
    input  wire [THREAD_COUNT*XLEN-1:0] i_bus_rsp_data, // read data
    input  wire [THREAD_COUNT-1:0]      i_bus_rsp_ack,  // access acknowledge
    // Data output
    output wire [THREAD_COUNT*XLEN-1:0] o_imm,           // immediate
    output wire [THREAD_COUNT*XLEN-1:0] o_pc             // pc
);
    
    // Instruction fetch
    localparam IF_RESTART = 3'b000,
              IF_PEND = 3'b001,
              IF_REQ  = 3'b010;
              
    reg [2:0]       if_state     [THREAD_COUNT-1:0];
    reg [2:0]       if_nstate    [THREAD_COUNT-1:0];
    reg [2:0]       if_prevstate [THREAD_COUNT-1:0];
    reg             if_restart   [THREAD_COUNT-1:0];
//    reg             if_unaligned [THREAD_COUNT-1:0];    
    reg [XLEN-1:0]  if_pc        [THREAD_COUNT-1:0];
    wire [XLEN-1:0] if_instr     [THREAD_COUNT-1:0];
//    wire            if_reset;
//    wire            if_resp;    // bus response
//    wire            if_a_err;   // alignment error
//    wire            if_avail     [THREAD_COUNT-1:0];   // thread available

    // Instruction prefetch buffer (FIFO)
    localparam IPB_DATA_WIDTH       = 2 + 16;   // {bus_error, align_error, 16-bit instruciton}
    localparam INSTR_BUFFER_DEPTH   = 8;        // instruction prefetch buffer depth

    wire [1:0]                ibp_free      [THREAD_COUNT-1:0];  // free entry
    wire [IPB_DATA_WIDTH-1:0] ipb_rdata_0   [THREAD_COUNT-1:0];  // read data
    wire [IPB_DATA_WIDTH-1:0] ipb_rdata_1   [THREAD_COUNT-1:0];  // read data
    wire [1:0]                ibp_avail     [THREAD_COUNT-1:0];  // data available
    wire [IPB_DATA_WIDTH-1:0] ipb_wdata_0   [THREAD_COUNT-1:0];  // write data
    wire [IPB_DATA_WIDTH-1:0] ipb_wdata_1   [THREAD_COUNT-1:0];  // write data
    wire [1:0]                ipb_we        [THREAD_COUNT-1:0];  // write enable
    wire [1:0]                ipb_re        [THREAD_COUNT-1:0];  // read enable
    
    // Instruction extract
    wire [6:0]   ir_opcode  [THREAD_COUNT-1:0];
    wire [4:0]   ir_rd      [THREAD_COUNT-1:0];
    wire [4:0]   ir_rs1     [THREAD_COUNT-1:0];
    wire [4:0]   ir_rs2     [THREAD_COUNT-1:0];
    wire [2:0]   ir_funct3  [THREAD_COUNT-1:0];
    wire [4:0]   ir_funct5  [THREAD_COUNT-1:0];
    wire [6:0]   ir_funct7  [THREAD_COUNT-1:0];
    wire [11:0]  ir_funct12 [THREAD_COUNT-1:0];
    wire [11:0]  ir_imm12   [THREAD_COUNT-1:0];
    wire [19:0]  ir_imm20   [THREAD_COUNT-1:0];
    
    genvar thread_idx;
    generate
        for (thread_idx = 0; thread_idx < THREAD_COUNT; thread_idx = thread_idx + 1) begin: thread_gen
            reg [2:0] ro_ctrl_alu_op;       // ALU operation select
            reg       ro_ctrl_alu_opa_mux;  // operand A select (0=rs1, 1=PC)
            reg       ro_ctrl_alu_opb_mux;  // operand B select (0=rs2, 1=IMM)
            reg       ro_ctrl_alu_unsigned; // is unsigned ALU operation      
  
            always @(posedge i_clk) begin
                if (!i_rstn) if_state[thread_idx] <= IF_RESTART;
                else if_state[thread_idx] <= if_nstate[thread_idx];
                
                if_prevstate[thread_idx] <= if_state[thread_idx];
            end
            
            always @(*) begin
                case (if_state[thread_idx])
                    IF_RESTART  : if_nstate[thread_idx] = IF_PEND;
                    IF_PEND     : if_nstate[thread_idx] = &ibp_avail[thread_idx]? IF_REQ: IF_PEND; 
                    IF_REQ      : if_nstate[thread_idx] = &ibp_avail[thread_idx]? IF_REQ: IF_PEND; 
                    default     : if_nstate[thread_idx] = IF_PEND;
                endcase
            end
            
            // Instruction fetch ==========================================================
            always @(posedge i_clk) begin
                if (!i_rstn) if_pc[thread_idx] <= 32'd0;
                else if (if_state[thread_idx] == IF_REQ) if_pc[thread_idx] <= if_pc[thread_idx] + 1'b1;
            end
            
            assign o_bus_req_addr[(thread_idx+1)*32-1 -: 32] = {2'b00, if_pc[thread_idx][XLEN-1:2]};
            assign o_bus_req_re[thread_idx]   = &ibp_free[thread_idx];
            
            // Prefetch buffer ==========================================================
            ip_fifo #(
                .FIFO_DEPTH (INSTR_BUFFER_DEPTH ), // number of fifo entries; has to be a power of two; min 1
                .FIFO_WIDTH (IPB_DATA_WIDTH     ), // size of data elements in fifo
                .FIFO_RSYNC (0                  ), // 0 = async read; 1 = sync read
                .FIFO_SAFE  (0                  )  // 1 = allow read/write only if entry available        
            ) prefetch_bufferL (
                // Global control
                .i_clk      ( i_clk        ),   // global clock, rising edge
                .i_rstn     ( i_rstn       ),  // global reset, low-active, async
                // Control signal
                .i_clear    ( 1'b0         ),  // sync reset, high-active
                .o_half     (              ),  // FIFO is half full
                // Write port
                .i_wdata    ( ipb_wdata_0[thread_idx]    ), // write data
                .i_we       ( ipb_we[thread_idx][0]      ),    // write enable
                .o_free     ( ibp_free[thread_idx][0]    ),  // at least one entry is free when set
                // Read port
                .i_re       ( ipb_re[thread_idx][0]      ),    // read enable
                .o_rdata    ( ipb_rdata_0[thread_idx]    ), // read data
                .o_avail    ( ibp_avail[thread_idx][0]   )  // data available when set
            );

            ip_fifo #(
                .FIFO_DEPTH (INSTR_BUFFER_DEPTH ), // number of fifo entries; has to be a power of two; min 1
                .FIFO_WIDTH (IPB_DATA_WIDTH     ), // size of data elements in fifo
                .FIFO_RSYNC (0                  ), // 0 = async read; 1 = sync read
                .FIFO_SAFE  (0                  )  // 1 = allow read/write only if entry available        
            ) prefetch_bufferH (
                // Global control
                .i_clk      ( i_clk        ),   // global clock, rising edge
                .i_rstn     ( i_rstn       ),  // global reset, low-active, async
                // Control signal
                .i_clear    ( 1'b0         ),  // sync reset, high-active
                .o_half     (              ),  // FIFO is half full
                // Write port
                .i_wdata    ( ipb_wdata_1[thread_idx]    ), // write data
                .i_we       ( ipb_we[thread_idx][1]      ),    // write enable
                .o_free     ( ibp_free[thread_idx][1]    ),  // at least one entry is free when set
                // Read port
                .i_re       ( ipb_re[thread_idx][1]      ),    // read enable
                .o_rdata    ( ipb_rdata_1[thread_idx]    ), // read data
                .o_avail    ( ibp_avail[thread_idx][1]   )  // data available when set
            );
            
            assign ipb_re[thread_idx] = 2'b11;
            assign ipb_we[thread_idx] = {2{i_bus_rsp_ack[thread_idx]}};
            assign ipb_wdata_0[thread_idx] = {2'b00, i_bus_rsp_data[(thread_idx+1)*32-17 -: 16]}; 
            assign ipb_wdata_1[thread_idx] = {2'b00, i_bus_rsp_data[(thread_idx+1)*32-1 -: 16]}; 
            
            // Instruction extract
            assign if_instr[thread_idx] = {ipb_rdata_1[thread_idx][15:0], ipb_rdata_0[thread_idx][15:0]};
            assign ir_opcode[thread_idx]   = {if_instr[thread_idx][6:2], 2'b11};
            assign ir_rd[thread_idx]       = if_instr[thread_idx][11:7];
            assign ir_rs1[thread_idx]      = if_instr[thread_idx][19:15];
            assign ir_rs2[thread_idx]      = if_instr[thread_idx][24:20];
            assign ir_funct3[thread_idx]   = if_instr[thread_idx][14:12];
            assign ir_funct5[thread_idx]   = if_instr[thread_idx][31:27];
            assign ir_funct7[thread_idx]   = if_instr[thread_idx][31:25];
            assign ir_funct12[thread_idx]  = if_instr[thread_idx][31:20];
            assign ir_imm12[thread_idx]    = if_instr[thread_idx][31:20];
            assign ir_imm20[thread_idx]    = if_instr[thread_idx][31:12];
            
            // Register file controller 
            assign o_ctrl_rf_wb_en[thread_idx]            = 1'b1;
            assign o_ctrl_rf_rs1[(thread_idx+1)*5-1 -: 5] = ir_rs1[thread_idx];
            assign o_ctrl_rf_rs2[(thread_idx+1)*5-1 -: 5] = ir_rs2[thread_idx];
            assign o_ctrl_rf_rd[(thread_idx+1)*5-1 -: 5]  = ir_rd[thread_idx];
            assign o_ctrl_rf_mux[(thread_idx+1)*2-1 -: 2] = `RF_ALU;
            assign o_ctrl_rf_zero_we                      = {THREAD_COUNT{1'b0}};    
            
            //-- Instruction
            assign o_ctrl_ir_funct3[(thread_idx+1)*3-1 -: 3]    = ir_funct3[thread_idx];   // funct3 bit field
            assign o_ctrl_ir_funct12[(thread_idx+1)*12-1 -: 12] = ir_funct12[thread_idx];  // funct12 bit field
            assign o_ctrl_ir_opcode[(thread_idx+1)*7-1 -: 7]    = ir_opcode[thread_idx];   // opcode bit field
            
            // ALU control
//            reg [2:0] ro_ctrl_alu_op;       // ALU operation select
//            reg       ro_ctrl_alu_opa_mux;  // operand A select (0=rs1, 1=PC)
//            reg       ro_ctrl_alu_opb_mux;  // operand B select (0=rs2, 1=IMM)
//            reg       ro_ctrl_alu_unsigned; // is unsigned ALU operation             
            always @(posedge i_clk) begin
                if (!i_rstn) begin
                    ro_ctrl_alu_op       <= 3'b000;
                    ro_ctrl_alu_opa_mux  <= 1'b0;
                    ro_ctrl_alu_opb_mux  <= 1'b0;
                    ro_ctrl_alu_unsigned <= 1'b0;
                end
                else begin
                    if ((ir_opcode[thread_idx] == `OP_ALU) || (ir_opcode[thread_idx] == `OP_ALUI)) begin
                        case (ir_funct3[thread_idx])
                            `FUNCT3_SUBADD  : ro_ctrl_alu_op <= (ir_opcode[thread_idx][5] && ir_funct7[5])? `ALU_OP_SUB: `ALU_OP_ADD;
                            `FUNCT3_SLT     : ro_ctrl_alu_op <= `ALU_OP_SLT;
                            `FUNCT3_SLTU    : ro_ctrl_alu_op <= `ALU_OP_SLT;
                            `FUNCT3_XOR     : ro_ctrl_alu_op <= `ALU_OP_XOR;
                            `FUNCT3_OR      : ro_ctrl_alu_op <= `ALU_OP_OR;
                            default         : ro_ctrl_alu_op <= `ALU_OP_AND;                                
                        endcase
                    end
                    else if ((ir_opcode[thread_idx] == `OP_LUI) || (ir_opcode[thread_idx] == `OP_AUIPC))
                        ro_ctrl_alu_op <= (ir_opcode[thread_idx][5] == 1'b1)? `ALU_OP_MOVB: `ALU_OP_ADD;
                    
                    // ctrl_alu_opa_mux
                    ro_ctrl_alu_opa_mux <= (ir_opcode[thread_idx] == `OP_AUIPC)  || (ir_opcode[thread_idx] == `OP_JAL)   || (ir_opcode[thread_idx] == `OP_BRANCH);
    
                    ro_ctrl_alu_opb_mux <= (ir_opcode[thread_idx] == `OP_ALUI)   || (ir_opcode[thread_idx] == `OP_LUI)   || (ir_opcode[thread_idx] == `OP_AUIPC) ||
                                    (ir_opcode[thread_idx] == `OP_LOAD)   || (ir_opcode[thread_idx] == `OP_STORE) || (ir_opcode[thread_idx] == `OP_AMO)   ||
                                    (ir_opcode[thread_idx] == `OP_BRANCH) || (ir_opcode[thread_idx] == `OP_JAL)   || (ir_opcode[thread_idx] == `OP_JALR);
                    
                    
                    // ctrl_alu_unsigned ir_op[4] == 1 --> ALU ops (SLTIU, SLTU), otherwise branches (BLTU, BGEU)
                    ro_ctrl_alu_unsigned <= ir_opcode[thread_idx][4]? ir_funct3[thread_idx][0]: ir_funct3[thread_idx][1];
                end
            end
            
            assign o_ctrl_alu_op[(thread_idx+1)*3-1 -:3] = ro_ctrl_alu_op;
            assign o_ctrl_alu_opa_mux[thread_idx] = ro_ctrl_alu_opa_mux;
            assign o_ctrl_alu_opb_mux[thread_idx] = ro_ctrl_alu_opb_mux;
            assign o_ctrl_alu_unsigned[thread_idx] = ro_ctrl_alu_unsigned;
            
            // Other
            assign o_imm[(thread_idx+1)*32-1 -: 32] = {{12{ir_imm20[thread_idx][19]}}, ir_imm20[thread_idx]};
            assign o_pc[(thread_idx+1)*32-1 -: 32]  = if_pc[thread_idx];
        end
    endgenerate
    
endmodule
