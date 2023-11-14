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
        input [7:0] i_we,
        input [3:0] i_busy,
        output [15:0] o_sel_channel,
        output [7:0]  o_sel_we
    );
    
    reg [1:0] sel_channel [7:0];
    reg [3:0] sel_we      [7:0];
    reg [3:0] r_busy      [7:0];
    
    always @(*) begin
        sel_channel[0] = 2'b00;
        r_busy[0] = i_busy;
        if (!i_busy[3]) begin
            sel_channel[0] = 2'b11;
            r_busy[0] = i_busy | 4'b1000;
        end
        if (!i_busy[2]) begin
            sel_channel[0] = 2'b10;
            r_busy[0] = i_busy | 4'b0100;
        end
        if (!i_busy[1]) begin
            sel_channel[0] = 2'b01;
            r_busy[0] = i_busy | 4'b0010;
        end
        if (!i_busy[0]) begin
            sel_channel[0] = 2'b00;
            r_busy[0] = i_busy | 4'b0001;
        end  
        sel_we[0] = i_we[0] && !(&i_busy);
         
        sel_channel[1] = sel_channel[0] + sel_we[0][0];
        sel_we[1]      = {3'b000, i_we[1] && !r_busy[0][sel_channel[1]]};
        r_busy[1]      = r_busy[0] | (sel_we[1] << sel_channel[1]);
        
        sel_channel[2] = sel_channel[1] + sel_we[1][0];
        sel_we[2]      = {3'b000, i_we[2] && !r_busy[1][sel_channel[2]]};
        r_busy[2]      = r_busy[1] | (sel_we[2] << sel_channel[2]);
        
        sel_channel[3] = sel_channel[2] + sel_we[2][0];
        sel_we[3]      = {3'b000, i_we[3] && !r_busy[2][sel_channel[3]]};
        r_busy[3]      = r_busy[2] | (sel_we[3] << sel_channel[3]);
        
        sel_channel[4] = sel_channel[3] + sel_we[3][0];
        sel_we[4]      = {3'b000, i_we[4] && !r_busy[3][sel_channel[4]]};
        r_busy[4]      = r_busy[3] | (sel_we[4] << sel_channel[4]);
        
        sel_channel[5] = sel_channel[4] + sel_we[4][0];
        sel_we[5]      = {3'b000, i_we[5] && !r_busy[4][sel_channel[5]]};
        r_busy[5]      = r_busy[4] | (sel_we[5] << sel_channel[5]);
        
        sel_channel[6] = sel_channel[5] + sel_we[5][0];
        sel_we[6]      = {3'b000, i_we[6] && !r_busy[5][sel_channel[6]]};
        r_busy[6]      = r_busy[5] | (sel_we[6] << sel_channel[6]);
        
        sel_channel[7] = sel_channel[6] + sel_we[6][0];   
        sel_we[7]      = {3'b000, i_we[7] && !r_busy[6][sel_channel[7]]};
        r_busy[7]      = r_busy[6] | (sel_we[7] << sel_channel[7]);        
    end
    
    assign o_sel_we = {sel_we[7][0],
                       sel_we[6][0],
                       sel_we[5][0],
                       sel_we[4][0],
                       sel_we[3][0],
                       sel_we[2][0],
                       sel_we[1][0],
                       sel_we[0][0]};
    assign o_sel_channel[15:14] = sel_channel[7];
    assign o_sel_channel[13:12] = sel_channel[6];
    assign o_sel_channel[11:10] = sel_channel[5];
    assign o_sel_channel[9:8] = sel_channel[4];
    assign o_sel_channel[7:6] = sel_channel[3];
    assign o_sel_channel[5:4] = sel_channel[2];
    assign o_sel_channel[3:2] = sel_channel[1];
    assign o_sel_channel[1:0] = sel_channel[0];
    
    
endmodule
