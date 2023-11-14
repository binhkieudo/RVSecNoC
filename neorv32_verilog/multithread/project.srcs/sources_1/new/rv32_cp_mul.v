`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 03:06:00 PM
// Design Name: 
// Module Name: rv32_cp_mul
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


module rv32_cp_mul#(
    parameter XLEN         = 32,
    parameter THREAD_COUNT = 8
)(
    // Global control    
    input  wire                     i_clk, // global clock, rising edge
    // Control signals
    input  wire [THREAD_COUNT-1:0]  i_req_thread,
    input  wire                     i_cpu_trap,
    input  wire [2:0]               i_cpu_op,       // operation
    input  wire [4:0]               i_cpu_exop,     // extra opration
    // Data input
    input  wire [XLEN-1:0]          i_rs1, // rf source 1
    input  wire [XLEN-1:0]          i_rs2, // shift amount
    // Results and status
    output wire [XLEN-1:0]          o_res, // result
    output wire                     o_busy,
    output wire [THREAD_COUNT-1:0]  o_valid // output valid
);

    localparam MUL_OP    = 3'b000,
               MULH_OP   = 3'b001,
               MULHSU_OP = 3'b010,
               MULHU_OP  = 3'b011;
               
    reg [XLEN:0] dsp_x;
    reg [XLEN:0] dsp_y;
    reg [2*XLEN+1:0] dsp_z;
    reg [2*XLEN-1:0] ro_prod;

    reg [XLEN-1:0]         ro_res;
    reg [THREAD_COUNT-1:0] ro_valid;
    
    wire rs1_is_signed = (i_cpu_op == MULH_OP) || (i_cpu_op == MULHSU_OP);
    wire rs2_is_signed = (i_cpu_op == MULH_OP);
    
    always @(*) begin
        dsp_x = {i_rs1[XLEN-1] & rs1_is_signed, i_rs1};
        dsp_y = {i_rs2[XLEN-1] & rs2_is_signed, i_rs2};    
        dsp_z = dsp_x * dsp_y;
        
        ro_prod = dsp_z[2*XLEN-1:0];
    end
    
    always @(posedge i_clk) begin
        ro_res   <= (|i_cpu_op[1:0])? ro_prod[2*XLEN-1-:XLEN]: ro_prod[XLEN-1-:XLEN];
        ro_valid <= i_req_thread;
    end
    
    assign o_res   = ro_res;
    assign o_busy  = 1'b0;
    assign o_valid = ro_valid;
    
endmodule
