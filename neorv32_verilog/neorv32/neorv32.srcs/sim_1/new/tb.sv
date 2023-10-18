`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2023 11:44:44 AM
// Design Name: 
// Module Name: tb
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


module tb(

    );
    
    reg i_clk = 1'b0;
    reg i_rstn = 1'b0;
    
    system_test udt(.*);
    
    always #1 i_clk = ~i_clk;
    
    initial begin
        #15 i_rstn = 1'b1;
        #1000 $stop;
    end
    
endmodule
