`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2023 09:06:49 PM
// Design Name: 
// Module Name: rv32_cpu_alu
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

module rv32_cpu_alu #(
    parameter XLEN                  = 32,
    parameter FAST_SHIFT            = 1,
    parameter FAST_MUL              = 1,
    parameter NCOPROC               = 5,
    parameter THREAD_COUNT          = 8,
    parameter CPU_EXTENSION_RISCV_M = 0,
    parameter CPU_EXTENSION_RISCV_Zmmul = 0
)
(
    // Control signals
    input  wire [THREAD_COUNT-1:0]          i_ctrl_alu_unsigned,     // is unsigned ALU operation
    input  wire [THREAD_COUNT*3-1:0]        i_ctrl_alu_op,           // ALU operation
    input  wire [THREAD_COUNT-1:0]          i_ctrl_pc_sel,           // 0:rs1, 1:pc
    input  wire [THREAD_COUNT-1:0]          i_ctrl_imm_sel,          // 0:rs2, 1:imm
    // Data input
    input  wire [THREAD_COUNT*XLEN-1:0]     i_rs1,                   // rf source 1
    input  wire [THREAD_COUNT*XLEN-1:0]     i_rs2,                   // rf source 2
    input  wire [THREAD_COUNT*XLEN-1:0]     i_pc,                    // program counter
    input  wire [THREAD_COUNT*XLEN-1:0]     i_imm,                   // immediate
    // Co-processor data input
//    input  wire [THREAD_COUNT-1:0]          ico_alu_unsigned,
//    input  wire [THREAD_COUNT*3-1:0]        ico_alu_op,
//    input  wire [THREAD_COUNT-1:0]          ico_sel,
//    input  wire [THREAD_COUNT*XLEN-1:0]     ico_src0,                
//    input  wire [THREAD_COUNT*XLEN-1:0]     ico_src1,                
    // Data output
    output wire [THREAD_COUNT-1:0]          o_cmp_eq,                // comparator equal result
    output wire [THREAD_COUNT-1:0]          o_cmp_lt,                // comparator less result
    output wire [THREAD_COUNT*XLEN-1:0]     o_res,                   // ALU result
    output wire [THREAD_COUNT*XLEN-1:0]     o_addr                  // address computation result
);

    localparam CP_MUL = 0;

    // Comparator
    wire [XLEN:0] cmp_rs1 [0:THREAD_COUNT-1]; 
    wire [XLEN:0] cmp_rs2 [0:THREAD_COUNT-1];

    // Operands
    wire [XLEN-1:0] opa [0:THREAD_COUNT-1]; // operand
    wire [XLEN-1:0] opb [0:THREAD_COUNT-1]; // operand
    wire [XLEN:0]   opa_x [0:THREAD_COUNT-1]; // extended operaand
    wire [XLEN:0]   opb_x [0:THREAD_COUNT-1]; // extended operaand
    
    // Intermediate results
    wire [XLEN:0]   addsub_res [0:THREAD_COUNT-1];
    wire [XLEN-1:0] alu_res [0:THREAD_COUNT-1];
    
    wire [XLEN-1:0] rs1 [THREAD_COUNT-1:0];
    wire [XLEN-1:0] rs2 [THREAD_COUNT-1:0];
    wire            ctrl_alu_unsigned [THREAD_COUNT-1:0];
    wire [2:0]      ctrl_alu_op       [THREAD_COUNT-1:0];
    wire            ctrl_pc_sel       [THREAD_COUNT-1:0];
    wire            ctrl_imm_sel      [THREAD_COUNT-1:0];  
    
    genvar thread_idx;
    generate
        for (thread_idx = 0; thread_idx < THREAD_COUNT; thread_idx = thread_idx + 1) begin: gen_alu          
//            assign rs1[thread_idx] = ico_sel[thread_idx]? ico_src0[(thread_idx+1)*XLEN-1-:XLEN]: i_rs1[(thread_idx+1)*XLEN-1-:XLEN];
//            assign rs2[thread_idx] = ico_sel[thread_idx]? ico_src1[(thread_idx+1)*XLEN-1-:XLEN]: i_rs2[(thread_idx+1)*XLEN-1-:XLEN];
//            assign ctrl_alu_unsigned[thread_idx] = ico_sel[thread_idx]? ico_alu_unsigned[thread_idx]: i_ctrl_alu_unsigned[thread_idx];
//            assign ctrl_alu_op[thread_idx] = ico_sel[thread_idx]? ico_alu_op[(thread_idx+1)*3-1 -: 3]: i_ctrl_alu_op[(thread_idx+1)*3-1 -: 3];
//            assign ctrl_pc_sel[thread_idx] = !ico_sel[thread_idx] && i_ctrl_pc_sel[thread_idx];
//            assign ctrl_imm_sel[thread_idx] = !ico_sel[thread_idx] && i_ctrl_imm_sel[thread_idx];

            assign rs1[thread_idx] = i_rs1[(thread_idx+1)*XLEN-1-:XLEN];
            assign rs2[thread_idx] = i_rs2[(thread_idx+1)*XLEN-1-:XLEN];
            assign ctrl_alu_unsigned[thread_idx] = i_ctrl_alu_unsigned[thread_idx];
            assign ctrl_alu_op[thread_idx] = i_ctrl_alu_op[(thread_idx+1)*3-1 -: 3];
            assign ctrl_pc_sel[thread_idx] = i_ctrl_pc_sel[thread_idx];
            assign ctrl_imm_sel[thread_idx] = i_ctrl_imm_sel[thread_idx];
                        
            // Comparator Unit (for conditionl branches)
            assign cmp_rs1[thread_idx] = {rs1[thread_idx][XLEN-1] & !ctrl_alu_unsigned[thread_idx], rs1[thread_idx]}; // sign-extend
            assign cmp_rs2[thread_idx] = {rs2[thread_idx][XLEN-1] & !ctrl_alu_unsigned[thread_idx], rs2[thread_idx]}; // sign-extend
        
            // ALU input operand select
            assign opa[thread_idx] = ctrl_pc_sel[thread_idx]? i_pc[(thread_idx+1)*XLEN-1 -: 32]: rs1[thread_idx];
            assign opb[thread_idx] = ctrl_imm_sel[thread_idx]? i_imm[(thread_idx+1)*XLEN-1 -: 32]: rs2[thread_idx];
        
            // Add/Sub Core sign extend
            assign opa_x[thread_idx] = {rs1[thread_idx][XLEN-1] & !ctrl_alu_unsigned[thread_idx], opa[thread_idx]};
            assign opb_x[thread_idx] = {rs2[thread_idx][XLEN-1] & !ctrl_alu_unsigned[thread_idx], opb[thread_idx]}; 
        
            assign addsub_res[thread_idx] = opa_x[thread_idx] + (ctrl_alu_op[0]? opb_x[thread_idx]: -opb_x[thread_idx]);
            
            assign alu_res[thread_idx] = (ctrl_alu_op[thread_idx] == `ALU_OP_XOR) ? rs1[thread_idx] ^ opb[thread_idx]:
                                         (ctrl_alu_op[thread_idx] == `ALU_OP_OR)  ? rs1[thread_idx] | opb[thread_idx]:
                                         (ctrl_alu_op[thread_idx] == `ALU_OP_AND) ? rs1[thread_idx] & opb[thread_idx]:
                                         (ctrl_alu_op[thread_idx] == `ALU_OP_MOVB)? opb[thread_idx]:
                                         (ctrl_alu_op[thread_idx] == `ALU_OP_SLT) ? {31'd0, addsub_res[thread_idx][XLEN]}: 
                                                                                    addsub_res[thread_idx][XLEN-1:0];
            assign o_cmp_eq[thread_idx] = rs1[thread_idx] == rs2[thread_idx];
            assign o_cmp_lt[thread_idx] = (cmp_rs1[thread_idx][XLEN] ^ cmp_rs2[thread_idx][XLEN])? (cmp_rs1[thread_idx][XLEN] && ~cmp_rs2[thread_idx][XLEN]): 
                                          (rs1[thread_idx] < rs2[thread_idx]);        
            assign o_res[(thread_idx+1)*XLEN-1 -: 32] = alu_res[thread_idx];
            assign o_addr[(thread_idx+1)*XLEN-1 -: 32]     = addsub_res[thread_idx][XLEN-1:0];   
        end
    endgenerate
  
  
endmodule