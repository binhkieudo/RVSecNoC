`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2023 02:54:39 AM
// Design Name: 
// Module Name: rv32_fastalu
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

(* use_dsp = "yes" *)
module rv32_fastalu(
        input        i_clk,
        input [29:0] a,
        input [17:0] b,
        input [47:0] c,
        input [24:0] d,
        input        cin,
        input [3:0]  addsub,
        input [3:0]  opcode,
        input [1:0]  x_sel,
        input [1:0]  y_sel,
        input [1:0]  z_sel,
        input [4:0]  shift_amount,
        output [47:0] out
    );
    
    parameter OP_ADD  = 3'b000,
              OP_SUB  = 3'b001,
              OP_AND  = 3'b010,
              OP_OR   = 3'b011,
              OP_XOR  = 3'b100;
              
    reg [29:0] a_reg; 
    reg [17:0] b_reg;
    reg [47:0] c_reg;
    reg [32:0] m_reg;
    reg [47:0] p_reg;
    
    reg [1:0] rx_sel;
    
    reg        r_cin;
    
    always @(*) begin
        a_reg = a;
        b_reg = b;
        c_reg = c;
        
        p_reg = {a_reg, b_reg} + c_reg >> 7;
       
    end
    
//    always @(posedge i_clk) begin
//        a_reg <= a;
//        b_reg <= b;
//        c_reg <= c;
        
////        m_reg <= a_reg[24:0] * b_reg;
//        p_reg <= {a_reg, b_reg} + c_reg;
//    end
    
    assign out = p_reg;
    
endmodule
