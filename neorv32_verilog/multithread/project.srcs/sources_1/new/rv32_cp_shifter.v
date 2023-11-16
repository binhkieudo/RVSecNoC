`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 03:04:38 PM
// Design Name: 
// Module Name: rv32_cp_shifter
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

module rv32_cp_shifter #(
    parameter XLEN         = 32,
    parameter THREAD_COUNT = 8,
    parameter METHOD       = "FPGA"
)(
    // Global control    
    input  wire                     i_clk, // global clock, rising edge
    // Control signals
    input  wire [THREAD_COUNT-1:0]  i_req_thread,
    input  wire [2:0]               i_cpu_op,       // operation
    // Data input
    input  wire [XLEN-1:0]          i_rs1, // rf source 1
    input  wire [XLEN-1:0]          i_rs2, // shift amount
    // Results and status
    output wire [XLEN-1:0]          o_res, // result
    output wire                     o_busy,
    output wire [THREAD_COUNT-1:0]  o_valid // output valid
);
    
    reg [XLEN-1:0]          ro_res;
    reg [THREAD_COUNT-1:0]  ro_valid;
    
    wire [4:0] shamt = i_rs2[4:0];
    wire       shift_right = (i_cpu_op == `SHIFT_RA) || (i_cpu_op == `SHIFT_RL);
    wire       shift_left  = i_cpu_op == `SHIFT_LL;
    wire       shift_arth  = i_cpu_op == `SHIFT_RA;
    
    generate
        if (METHOD == "FPGA") begin    
            always @(posedge i_clk) begin
                ro_res   <= (i_cpu_op == `SHIFT_LL)? i_rs1 <<  shamt: 
                            (i_cpu_op == `SHIFT_RA)? i_rs1 >>> shamt: 
                                                     i_rs1 >>  shamt;
                ro_valid <= i_req_thread;
            end
        end
        if (METHOD == "ASIC") begin
            reg [XLEN-1:0] bs_level [0:5];
            reg [XLEN-1:0] bs_result;
            reg [XLEN-1:0] rv_result; // reverse result
              
            integer i;
            always @(*) begin
                // input layer: convert left shifts to right shifts by reversing
                if (shift_right)
                    bs_level[5] = i_rs1;
                else
                    for (i = 0; i < XLEN; i = i + 1) begin
                        bs_level[5][i] = i_rs1[XLEN-i-1];
                        rv_result[i]   = bs_result[XLEN-1-i];
                    end
                // Shifter
                if (shamt[4]) begin
                    bs_level[4][XLEN-1:16] = {16{bs_level[5][XLEN-1] & shift_arth}};
                    bs_level[4][15:0] = bs_level[5][XLEN-1:16];
                end
                else bs_level[4] = bs_level[5];
        
                if (shamt[3]) begin
                    bs_level[3][XLEN-1:24] = {8{bs_level[4][XLEN-1] & shift_arth}};
                    bs_level[3][23:0] = bs_level[4][XLEN-1:8];
                end
                else bs_level[3] = bs_level[4];
        
                if (shamt[2]) begin
                    bs_level[2][XLEN-1:28] = {4{bs_level[3][XLEN-1] & shift_arth}};
                    bs_level[2][27:0] = bs_level[3][XLEN-1:4];
                end
                else bs_level[2] = bs_level[3];
        
                if (shamt[1]) begin
                    bs_level[1][XLEN-1: 30] = {2{bs_level[2][XLEN-1] & shift_arth}};
                    bs_level[1][29:0] = bs_level[2][XLEN-1:2];
                end
                else bs_level[1] = bs_level[2];
        
                if (shamt[0]) begin
                    bs_level[0][XLEN-1] = bs_level[1] & shift_arth;
                    bs_level[0][30:0] = bs_level[1][XLEN-1:1];
                end
                else bs_level[0] = bs_level[1];
            end
        
            always @(*) begin
                bs_result = bs_level[0];
            end
            
            always @(posedge i_clk) begin
                ro_res   <= shift_right? bs_result: rv_result;
                ro_valid <= i_req_thread; 
            end          
        end
    endgenerate
    
    
    assign o_res    = ro_res & {XLEN{ro_valid}};
    assign o_busy   = 1'b0;
    assign o_valid  = ro_valid;
    
endmodule
