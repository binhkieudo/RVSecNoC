`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2023 12:23:49 AM
// Design Name: 
// Module Name: tb_shift_barrel
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


module tb_shift_barrel(

    );
    
    parameter XLEN = 32;
    
    // Global control    
    reg i_clk = 1'b0; // global clock; rising edge
    reg i_rstn = 1'b1; // global reset; active low; async
    // Control signals
    reg i_cpu_trap = 1'b0; // set when CPU is entering trap exec
    reg i_shift_right; // shift left operation
    reg i_shift_logical; // shift logical (only for shift right)
    reg i_start = 1'b1; // start operation
    // Data input
    reg [XLEN-1:0] i_rs1; // rf source 1
    reg [4:0] i_shamt; // shift amount
    // Results and status
    wire [XLEN-1:0] o_res; // result
    wire o_valid; // valid
    
    rv32_cpu_cp_shifter_barrel udt(.*);
    
    always #1 i_clk = ~i_clk;
    
    initial begin
        i_rs1 = 32;
        i_shamt = 2;
        i_shift_right = 0;
        i_shift_logical = 0;
        #10
        i_rs1 = 50;
        i_shamt = 3;
        i_shift_right = 0;
        i_shift_logical = 0;
        #10
        i_rs1 = -50;
        i_shamt = 3;
        i_shift_right = 0;
        i_shift_logical = 0;
        #10
        i_rs1 = -50;
        i_shamt = 3;
        i_shift_right = 1;
        i_shift_logical = 0;
        #10
        i_rs1 = -50;
        i_shamt = 3;
        i_shift_right = 1;
        i_shift_logical = 1;             
        #100 $stop;
    end
    
endmodule
