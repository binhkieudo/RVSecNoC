`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2023 11:21:49 PM
// Design Name: 
// Module Name: cpu_rv32_regfile
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

module rv32_cpu_regfile #(
    parameter XLEN         = 32,
    parameter THREAD_COUNT = 8,
    parameter RF_LATCH     = 0
) (
    // Global control signals
    input wire              i_clk,
    // Register file interface
    input wire  [THREAD_COUNT*2-1:0]    i_ctrl_wb_sel,  // write back data select
    input wire  [THREAD_COUNT-1:0]      i_ctrl_wb_en,   // write back enable
    input wire  [THREAD_COUNT-1:0]      i_ctrl_zero_we, // allow writting to $zero
    // Input data
    input wire  [XLEN-1:0]              i_mem,          // Memory results
    input wire  [THREAD_COUNT*XLEN-1:0] i_alu,          // ALU results
    input wire  [THREAD_COUNT*XLEN-1:0] i_csr,          // CSR results,
    input wire  [THREAD_COUNT*XLEN-1:0] i_npc,          // next pc
    // Regfile access
    input wire  [THREAD_COUNT*5-1:0]    i_rf_rd,        // destination address
    input wire  [THREAD_COUNT*5-1:0]    i_rf_rs1,       // rs1 address
    input wire  [THREAD_COUNT*5-1:0]    i_rf_rs2,       // rs2 address
    output wire [THREAD_COUNT*XLEN-1:0] o_rs1,          // rs1
    output wire [THREAD_COUNT*XLEN-1:0] o_rs2           // rs2
);

    wire [31:0] rf_wdata [THREAD_COUNT-1:0]; // write data
    wire [THREAD_COUNT-1:0] rf_we; // write enable
    wire [4:0] opa_addr [THREAD_COUNT-1:0]; // rs1/dst
    wire [4:0] opb_addr [THREAD_COUNT-1:0]; // rs2
    
    genvar thread_idx;
    generate
        for (thread_idx = 0; thread_idx < THREAD_COUNT; thread_idx = thread_idx + 1) begin: thread
            reg [XLEN-1:0] regfile [0:31];
        
            reg [XLEN-1:0] ro_rs1; // rs1
            reg [XLEN-1:0] ro_rs2; // rs2
    
            // Write back data select
            assign rf_wdata[thread_idx] = (i_ctrl_wb_sel[(thread_idx+1)*2-1 -: 2] == `RF_MEM)? i_mem:
                                          (i_ctrl_wb_sel[(thread_idx+1)*2-1 -: 2] == `RF_CSR)? i_csr[(thread_idx+1)*XLEN-1 -: 32]:
                                          (i_ctrl_wb_sel[(thread_idx+1)*2-1 -: 2] == `RF_NPC)? i_npc[(thread_idx+1)*XLEN-1 -: 32]: 
                                                                      i_alu[(thread_idx+1)*XLEN-1 -: 32];
        
            assign opa_addr[thread_idx] = i_ctrl_wb_en[thread_idx]? i_rf_rd[(thread_idx + 1)*5-1-:5]: 
                                                                    i_rf_rs1[(thread_idx + 1)*5-1-:5];
            assign opb_addr[thread_idx] = i_rf_rs2[(thread_idx + 1)*5-1-:5];
        
            assign rf_we[thread_idx] = i_ctrl_wb_en[thread_idx] && (i_ctrl_zero_we[thread_idx] || (i_rf_rd[(thread_idx + 1)*5-1-:5] != 5'b00000)); // do not allow writting to $zero;
        
                if (RF_LATCH == 1) begin: gen_rf_latch
                    always @(i_clk) begin
                        if (rf_we[thread_idx]) regfile[opa_addr[thread_idx]] = rf_wdata[thread_idx];
                        
                        ro_rs1 = regfile[opa_addr[thread_idx]];
                        ro_rs2 = regfile[opb_addr[thread_idx]];
                    end
                end
                else begin: gen_rf_ff
                    always @(posedge i_clk) begin
                        if (rf_we[thread_idx]) regfile[opa_addr[thread_idx]] <= rf_wdata[thread_idx];
                        
                        ro_rs1 <= regfile[opa_addr[thread_idx]];
                        ro_rs2 <= regfile[opb_addr[thread_idx]];
                    end
                end
            
            assign o_rs1[(thread_idx+1)*XLEN-1 -: 32] = ro_rs1;
            assign o_rs2[(thread_idx+1)*XLEN-1 -: 32] = ro_rs2;
        end
    endgenerate
    
endmodule
