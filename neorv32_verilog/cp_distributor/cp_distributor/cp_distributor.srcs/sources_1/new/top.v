`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2023 03:05:29 AM
// Design Name: 
// Module Name: top
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


module top(
        input i_clk
    );
    
    parameter XLEN         = 32;
    parameter THREAD       = 4;
    parameter CHANNEL      = 2;
    parameter LOG2_CHANNEL = 1;
    
    // Thread control
    wire [THREAD-1:0]        i_cpu_cpen;
    wire [THREAD-1:0]        i_cpu_trap;
    wire [THREAD*3-1:0]      i_cpu_op;
    wire [THREAD*5-1:0]      i_cpu_exop;
    wire [THREAD*XLEN-1:0]   i_cpu_rs1;
    wire [THREAD*XLEN-1:0]   i_cpu_rs2;
    // Channel control
    wire [CHANNEL*THREAD-1:0]o_cp_req;
    wire [CHANNEL-1:0]       o_cp_en;
    wire [CHANNEL-1:0]       o_cp_trap;
    wire [CHANNEL*3-1:0]     o_cp_op;
    wire [CHANNEL*5-1:0]     o_cp_exop;
    wire [CHANNEL*XLEN-1:0]  o_cp_rs1;
    wire [CHANNEL*XLEN-1:0]  o_cp_rs2;
    wire [CHANNEL-1:0]       i_cp_busy;
    
    rv32_cp_arbtr u0(
        i_clk,
        i_cpu_cpen,
        i_cpu_trap,
        i_cpu_op,
        i_cpu_exop,
        i_cpu_rs1,
        i_cpu_rs2,
        o_cp_req,
        o_cp_en,
        o_cp_trap,
        o_cp_op,
        o_cp_exop,
        o_cp_rs1,
        o_cp_rs2,
        i_cp_busy
    );
    
    vio_0 vio_0(
        .clk        (i_clk ),
        .probe_in0  (o_cp_req ),
        .probe_in1  (o_cp_en ),
        .probe_in2  (o_cp_trap ),
        .probe_in3  (o_cp_op ),
        .probe_in4  (o_cp_exop ),
        .probe_in5  (o_cp_rs1 ),
        .probe_in6  (o_cp_rs2 ),
        .probe_out0 (i_cpu_cpen ),
        .probe_out1 (i_cpu_trap ),
        .probe_out2 (i_cpu_op ),
        .probe_out3 (i_cpu_exop ),
        .probe_out4 (i_cpu_rs1 ),
        .probe_out5 (i_cpu_rs2 ),
        .probe_out6 (i_cp_busy )
    );    
    
endmodule
