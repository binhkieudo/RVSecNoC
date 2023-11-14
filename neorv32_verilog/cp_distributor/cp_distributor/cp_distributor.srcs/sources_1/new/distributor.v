`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 05:56:42 PM
// Design Name: 
// Module Name: distributor
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


module distributor(
        input i_clk,
        input i_rstn,
        input [7:0] i_we,
        output [7:0] o_we
    );
    
    genvar i;
    generate
        assign o_we[0] = i_we[0];
        for (i = 0; i < 8; i = i + 1) begin: gen
            assign o_we[i] = i_we[i] & !(|o_we[i-1:0]);
        end
    endgenerate
    
endmodule
