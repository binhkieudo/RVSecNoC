`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2023 11:33:17 AM
// Design Name: 
// Module Name: tb_mul
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


module tb_mul(

    );
    
    parameter XLEN = 32;
    
    // Global control
    reg              i_clk;
    reg              i_rstn;
    // Control signals
    reg              i_start = 0;
    reg [2:0]        i_mul_op = 3'b001; 
    // Input data
    reg [XLEN-1:0]   i_rs1 = 23;
    reg [XLEN-1:0]   i_rs2 = 32;
    // Output data
    wire [2*XLEN-1:0] o_prod;
    
    rv32_cpu_cp_mul_dsp udt (.*);
    
    initial begin
        #5 i_start = 1;
        #5 i_start = 0;
        #1 i_rs1 = 10;
         i_rs2 = 20;
        #5 i_start = 1;
        #100 $stop;
    end
    
endmodule
