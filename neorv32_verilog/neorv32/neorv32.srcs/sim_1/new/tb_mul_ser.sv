`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2023 12:46:12 PM
// Design Name: 
// Module Name: tb_mul_ser
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


module tb_mul_ser(

    );
    
    parameter XLEN = 32;
    
    // Global control
    reg              i_clk = 1'b0;
    reg              i_rstn = 1'b0;
    // Control signals
    reg              i_start = 0;
    reg              i_cpu_trap = 0;
    reg [2:0]        i_mul_op = 3'b001; 
    // Input data
    reg [XLEN-1:0]   i_rs1 = 23;
    reg [XLEN-1:0]   i_rs2 = 32;
    // Output data
    wire [2*XLEN-1:0] o_prod;
    wire              o_valid;
    
    rv32_cpu_cp_mul_ser udt (.*);
    
    always #5 i_clk = ~i_clk;
    
    initial begin
        #10 i_rstn = 1'b1;
        #5 i_start = 1;
        #10 i_start = 0;
        #1000 $stop;
    end
    
endmodule
