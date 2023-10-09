`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2023 01:50:13 PM
// Design Name: 
// Module Name: tb_div_ser
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


module tb_div_ser(

    );
    
    parameter XLEN = 32;
    
    // Global control
    reg              i_clk = 1'b0;
    reg              i_rstn = 1'b0;
    // Control signals
    reg              i_start = 0;
    reg              i_cpu_trap = 0;
    reg [2:0]        i_div_op = 3'b110; 
    // Input data
    reg [XLEN-1:0]   i_rs1 = 2005;
    reg [XLEN-1:0]   i_rs2 = 50;
    // Output data
    wire [2*XLEN-1:0] o_res;
    wire              o_valid;
    
    rv32_cpu_cp_div_ser udt (.*);
    
    always #5 i_clk = ~i_clk;
    
    initial begin
        #10 i_rstn = 1'b1;
        #5 i_start = 1;
        #10 i_start = 0;
        #1000 $stop;
    end
    
endmodule
