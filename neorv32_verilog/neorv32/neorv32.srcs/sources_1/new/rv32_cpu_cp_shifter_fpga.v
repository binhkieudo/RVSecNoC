`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2023 12:44:00 AM
// Design Name: 
// Module Name: rv32_cpu_cp_shifter_fpga
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


module rv32_cpu_cp_shifter_fpga#(
    parameter XLEN = 32
)
(
    // Global control    
    input  wire             i_clk, // global clock, rising edge
    input  wire             i_rstn, // global reset, active low, async
    // Control signals
    input  wire             i_cpu_trap, // set when CPU is entering trap exec
    input  wire             i_shift_right, // shift left operation
    input  wire             i_shift_logical, // shift logical (only for shift right)
    input  wire             i_start, // start operation
    // Data input
    input  wire [XLEN-1:0]  i_rs1, // rf source 1
    input  wire [4:0]       i_shamt, // shift amount
    // Results and status
    output wire [XLEN-1:0]  o_res, // result
    output wire             o_valid // output valid
);

    assign o_res = i_shift_right? (i_shift_logical? i_rs1 >>> i_shamt: i_rs1 >> i_shamt): i_rs1 << i_shamt;
    assign o_valid = i_start;

endmodule
