`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2023 12:11:38 AM
// Design Name: 
// Module Name: rv32_cpu_cp_shifter_barrel
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


module rv32_cpu_cp_shifter_barrel #(
    parameter XLEN = 32
)(
    // Global control    
    input  wire             i_clk, // global clock, rising edge
    input  wire             i_rstn, // global reset, active low, async
    // Control signals
    input  wire             i_cpu_trap, // set when CPU is entering trap exec
    input  wire             i_shift_right, // shift left operation
    input  wire             i_shift_arth, // shift logical (only for shift right)
    input  wire             i_start, // start operation
    // Data input
    input  wire [XLEN-1:0]  i_rs1, // rf source 1
    input  wire [4:0]       i_shamt, // shift amount
    // Results and status
    output wire [XLEN-1:0]  o_res, // result
    output wire             o_valid // output valid
);

    reg [XLEN-1:0] bs_level [0:5];
    reg [XLEN-1:0] bs_result;
    reg [XLEN-1:0] rv_result; // reverse result
    
    integer i;
    always @(*) begin
        // input layer: convert left shifts to right shifts by reversing
        if (i_shift_right)
            bs_level[5] = i_rs1;
        else
            for (i = 0; i < XLEN; i = i + 1) begin
                bs_level[5][i] = i_rs1[XLEN-i-1];
                rv_result[i]   = bs_result[XLEN-1-i];
            end
        // Shifter
        if (i_shamt[4]) begin
            bs_level[4][XLEN-1:16] = {16{bs_level[5][XLEN-1] & i_shift_arth}};
            bs_level[4][15:0] = bs_level[5][XLEN-1:16];
        end
        else bs_level[4] = bs_level[5];

        if (i_shamt[3]) begin
            bs_level[3][XLEN-1:24] = {8{bs_level[4][XLEN-1] & i_shift_arth}};
            bs_level[3][23:0] = bs_level[4][XLEN-1:8];
        end
        else bs_level[3] = bs_level[4];

        if (i_shamt[2]) begin
            bs_level[2][XLEN-1:28] = {4{bs_level[3][XLEN-1] & i_shift_arth}};
            bs_level[2][27:0] = bs_level[3][XLEN-1:4];
        end
        else bs_level[2] = bs_level[3];

        if (i_shamt[1]) begin
            bs_level[1][XLEN-1: 30] = {2{bs_level[2][XLEN-1] & i_shift_arth}};
            bs_level[1][29:0] = bs_level[2][XLEN-1:2];
        end
        else bs_level[1] = bs_level[2];

        if (i_shamt[0]) begin
            bs_level[0][XLEN-1] = bs_level[1] & i_shift_arth;
            bs_level[0][30:0] = bs_level[1][XLEN-1:1];
        end
        else bs_level[0] = bs_level[1];
    end

    always @(*) begin
        bs_result = bs_level[0];
    end

    assign o_res = i_shift_right? bs_result: rv_result;
    assign o_valid = i_start;

endmodule

