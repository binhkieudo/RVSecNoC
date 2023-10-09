`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2023 06:09:46 PM
// Design Name: 
// Module Name: rv32_cpu_regfile
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


module rv32_cpu_regfile #(
    parameter XLEN = 32,
    parameter RVE = 1, // E extension
    parameter RF_LATCH = 0,      
    parameter RS3_EN = 1, // enable 3rd read port
    parameter RS4_EN = 1  // enable 4th read port
) (
    // Global control signals
    input i_clk,
    // Register file interface
    input [1:0] i_ctrl_wb_sel, // write back data select
    input i_ctrl_wb_en, // write back enable
    input i_alu, // ALU results
    input i_mem, // Memory results
    input i_csr, // CSR results,
    input i_npc,  // next pc
    input [2:0] i_ir_funct3,
    input [11:0] i_ir_funct12,
    input [4:0] i_rf_rd, // destination address
    input [4:0] i_rf_rs1, // rs1 address
    input [4:0] i_rf_rs2, // rs1 address
    input [4:0] i_rf_rs3, // rs1 address
    output reg [XLEN-1:0] o_rs1, // rs1
    output reg [XLEN-1:0] o_rs2, // rs2
    output reg [XLEN-1:0] o_rs3, // rs3
    output reg [XLEN-1:0] o_rs4  // rs4
);

    localparam REGFILE_DEPTH = RVE? 16: 32;
    localparam REGFILE_BITS = RVE? 4: 5;

    localparam RF_ALU = 2'b00, // select ALU
               RF_MEM = 2'b01, // select memory
               RF_CSR = 2'b10, // select control status register 
               RF_NPC = 2'b11; // select next pc

    reg [XLEN-1:0] regfile [0:REGFILE_DEPTH-1];

    wire [31:0] rf_wdata; // write data
    wire rf_we; // write enable
    wire [4:0] opa_addr; // rs1/dst
    wire [4:0] opb_addr; // rs2
    wire [4:0] opc_addr; // rs3
    wire [4:0] opd_addr; // rs4

    // Write back data select
    assign rf_wdata = (i_ctrl_wb_sel == RF_MEM)? i_mem:
                      (i_ctrl_wb_sel == RF_CSR)? i_csr:
                      (i_ctrl_wb_sel == RF_NPC)? i_npc: i_alu;

    assign opa_addr = i_ctrl_wb_en? i_rf_rd: i_rf_rs2;
    assign opb_addr = i_rf_rs2;
    assign opc_addr = i_rf_rs3;
    assign opd_addr = {i_ir_funct12[6:5], i_ir_funct3}; 

    assign rf_we = i_ctrl_wb_en && (i_rf_rd != 5'b00000); // do not allow writting to $zero;

    generate
        if (RF_LATCH == 1) begin: gen_rf_latch
            always @(i_clk) begin
                if (rf_we) regfile[opa_addr] = rf_wdata;
                o_rs1 = regfile[opa_addr];
                o_rs2 = regfile[opb_addr];

                if (RS3_EN == 1) o_rs3 = regfile[opc_addr];
                else o_rs3 = 0;
                if (RS4_EN == 1) o_rs4 = regfile[opd_addr];
                else o_rs4 = 0;
            end
        end
        else begin: gen_rf_ff
            always @(posedge i_clk) begin
                if (rf_we) regfile[opa_addr] <= rf_wdata;
                o_rs1 <= regfile[opa_addr];
                o_rs2 <= regfile[opb_addr];

                if (RS3_EN == 1) o_rs3 <= regfile[opc_addr];
                else o_rs3 <= 0;
                if (RS4_EN == 1) o_rs4 <= regfile[opd_addr];
                else o_rs4 <= 0;
            end
        end
    endgenerate
    
endmodule