`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 11:49:20 PM
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
    
    parameter XLEN         = 32;
    parameter THREAD       = 8;
    parameter CHANNEL      = 8;
    parameter LOG2_CHANNEL = 3;
    
    // Global control
    reg i_clk = 1'b0;
    // Thread control
    reg [THREAD-1:0]      i_cpu_cpen;
    reg [THREAD-1:0]      i_cpu_trap;
    reg [THREAD*3-1:0]    i_cpu_op;
    reg [THREAD*5-1:0]    i_cpu_exop;
    reg [THREAD*XLEN-1:0] i_cpu_rs1;
    reg [THREAD*XLEN-1:0] i_cpu_rs2;
    // Channel control
    wire [CHANNEL*THREAD-1:0]o_cp_req;
    wire [CHANNEL-1:0]     o_cp_en;
    wire [CHANNEL-1:0]     o_cp_trap;
    wire [CHANNEL*3-1:0]   o_cp_op;
    wire [CHANNEL*5-1:0]   o_cp_exop;
    wire [CHANNEL*XLEN-1:0] o_cp_rs1;
    wire [CHANNEL*XLEN-1:0] o_cp_rs2;
    reg [CHANNEL-1:0]     i_cp_busy;    
    
    rv32_cp_arbtr udt (.*);
    
    always #5 i_clk = ~i_clk;
    
    initial begin
        i_cpu_cpen = 8'b1111_1111;
        i_cpu_trap = 8'b0000_0000;
        i_cpu_op   = {3'b111, 3'b110, 3'b101, 3'b100, 3'b011, 3'b010, 3'b001, 3'b000};
        i_cpu_exop = {5'b11100, 5'b11000, 5'b10100, 5'b10000, 5'b01100, 5'b01000, 5'b00100, 5'b00000};
        i_cpu_rs1  = {32'd18, 32'd17, 32'd16, 32'd15, 32'd14, 32'd13, 32'd12, 32'd11};
        i_cpu_rs2  = {32'd28, 32'd27, 32'd26, 32'd25, 32'd24, 32'd23, 32'd22, 32'd21};
        i_cp_busy  = 4'b0000;
        #20;
        i_cpu_cpen = 8'b1111_0000;
        i_cpu_trap = 8'b0000_0000;
        i_cpu_op   = {3'b111, 3'b110, 3'b101, 3'b100, 3'b011, 3'b010, 3'b001, 3'b000};
        i_cpu_exop = {5'b11100, 5'b11000, 5'b10100, 5'b10000, 5'b01100, 5'b01000, 5'b00100, 5'b00000};
        i_cpu_rs1  = {32'd18, 32'd17, 32'd16, 32'd15, 32'd14, 32'd13, 32'd12, 32'd11};
        i_cpu_rs2  = {32'd28, 32'd27, 32'd26, 32'd25, 32'd24, 32'd23, 32'd22, 32'd21};
        i_cp_busy  = 4'b0000;
        #20;
        i_cpu_cpen = 8'b0101_0101;
        i_cpu_trap = 8'b0000_0000;
        i_cpu_op   = {3'b111, 3'b110, 3'b101, 3'b100, 3'b011, 3'b010, 3'b001, 3'b000};
        i_cpu_exop = {5'b11100, 5'b11000, 5'b10100, 5'b10000, 5'b01100, 5'b01000, 5'b00100, 5'b00000};
        i_cpu_rs1  = {32'd18, 32'd17, 32'd16, 32'd15, 32'd14, 32'd13, 32'd12, 32'd11};
        i_cpu_rs2  = {32'd28, 32'd27, 32'd26, 32'd25, 32'd24, 32'd23, 32'd22, 32'd21};
        i_cp_busy  = 4'b0000;
        #20;
        i_cpu_cpen = 8'b0100_0101;
        i_cpu_trap = 8'b0000_0000;
        i_cpu_op   = {3'b111, 3'b110, 3'b101, 3'b100, 3'b011, 3'b010, 3'b001, 3'b000};
        i_cpu_exop = {5'b11100, 5'b11000, 5'b10100, 5'b10000, 5'b01100, 5'b01000, 5'b00100, 5'b00000};
        i_cpu_rs1  = {32'd18, 32'd17, 32'd16, 32'd15, 32'd14, 32'd13, 32'd12, 32'd11};
        i_cpu_rs2  = {32'd28, 32'd27, 32'd26, 32'd25, 32'd24, 32'd23, 32'd22, 32'd21};
        i_cp_busy  = 4'b0000;     
        #20;
        i_cpu_cpen = 8'b0101_0101;
        i_cpu_trap = 8'b0000_0000;
        i_cpu_op   = {3'b111, 3'b110, 3'b101, 3'b100, 3'b011, 3'b010, 3'b001, 3'b000};
        i_cpu_exop = {5'b11100, 5'b11000, 5'b10100, 5'b10000, 5'b01100, 5'b01000, 5'b00100, 5'b00000};
        i_cpu_rs1  = {32'd18, 32'd17, 32'd16, 32'd15, 32'd14, 32'd13, 32'd12, 32'd11};
        i_cpu_rs2  = {32'd28, 32'd27, 32'd26, 32'd25, 32'd24, 32'd23, 32'd22, 32'd21};
        i_cp_busy  = 4'b0001;    
        #100 $stop;
    end
    
endmodule
