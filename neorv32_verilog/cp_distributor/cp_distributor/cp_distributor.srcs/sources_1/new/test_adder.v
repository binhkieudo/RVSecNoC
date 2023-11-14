`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2023 01:12:44 AM
// Design Name: 
// Module Name: test_adder
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


module test_adder(
        input  wire [8*32-1:0] in,
        output wire [31:0]     out     
    );
    
    reg [31:0] rout [0:7];
    integer i;
    always @(*) begin
        rout[0] = in[31:0];
        for (i = 1; i < 8; i = i + 1)
            rout[i] = rout[i-1] + in[(i+1)*32-1 -: 32];
    end
    
    assign out = rout[7];
    
endmodule
