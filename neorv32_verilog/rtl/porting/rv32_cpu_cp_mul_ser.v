`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2023 12:41:56 PM
// Design Name: 
// Module Name: rv32_cpu_cp_mul_ser
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


module rv32_cpu_cp_mul_ser#(
    parameter XLEN = 32,
    parameter PIPELINE = 0
)
(
    // Global control
    input  wire              i_clk,
    input  wire              i_rstn,
    // Control signals
    input  wire              i_start,
    input  wire              i_cpu_trap,
    input  wire [2:0]        i_mul_op,
    // Input data
    input  wire [XLEN-1:0]   i_rs1,
    input  wire [XLEN-1:0]   i_rs2,
    // Output data
    output wire [XLEN-1:0]   o_prod,
    output wire              o_valid
);

    localparam MUL_OP    = 3'b000,
               MULH_OP   = 3'b001,
               MULHSU_OP = 3'b010,
               MULHU_OP  = 3'b011;

    localparam S_IDLE = 2'b00,
               S_BUSY = 2'b01,
               S_DONE = 2'b10,
               S_READY = 2'b11;

    reg [2*XLEN-1:0] ro_prod;
    reg [XLEN:0]     r_add;
    reg [4:0] r_cnt;

    reg [1:0] state, next;

    wire rs1_is_signed = (i_mul_op == MULH_OP) || (i_mul_op == MULHSU_OP);
    wire rs2_is_signed = (i_mul_op == MULH_OP);

    wire p_sext = ro_prod[2*XLEN-1] & rs2_is_signed;

    always @(posedge i_clk, negedge i_rstn)
        if (!i_rstn) state <= S_IDLE;
        else state <= next;

    always @(*) begin
        case (state)
            S_IDLE: next = i_start? S_BUSY: S_IDLE;
            S_BUSY: next = (!(|r_cnt) || i_cpu_trap)? S_DONE: S_BUSY;
            S_DONE: next = S_READY;
            S_READY: next = S_IDLE;
            default: next = S_IDLE;
        endcase
    end

    always @(posedge i_clk)
        if (state == S_IDLE) r_cnt <= 5'd30;
        else r_cnt <= r_cnt - 5'd1;

    always @(posedge i_clk)
        if (state == S_IDLE && i_start) begin
            ro_prod[63:32]  <= 32'd0;
            ro_prod[31:0]   <= i_rs1;
        end    
        else if ((state == S_BUSY) || (state == S_DONE)) begin
            ro_prod[63:31]  <= r_add[32:0];
            ro_prod[30:0]   <= ro_prod[31:1];
        end

    always @(*)
        if (ro_prod[0] == 1'b1) begin
            if ((state == S_DONE) && rs1_is_signed)
                r_add = {p_sext, ro_prod[63:32]} - {i_rs2[XLEN-1] & rs2_is_signed, i_rs2};
            else
                r_add = {p_sext, ro_prod[63:32]} + {i_rs2[XLEN-1] & rs2_is_signed, i_rs2};
        end
        else
            r_add = {p_sext, ro_prod[63:32]};

    assign o_prod = (|i_mul_op[1:0])? ro_prod[63:32]: ro_prod[31:0];
    assign o_valid = state == S_READY;
    
endmodule

