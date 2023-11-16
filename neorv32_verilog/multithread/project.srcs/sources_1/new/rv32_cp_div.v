`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2023 04:52:42 PM
// Design Name: 
// Module Name: rv32_cp_div
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


module rv32_cp_div #(
    parameter XLEN         = 32,
    parameter THREAD_COUNT = 8
)(
    // Global control    
    input  wire                     i_clk, // global clock, rising edge
    input  wire                     i_rstn,
    // Control signals
    input  wire [THREAD_COUNT-1:0]  i_req_thread,                    
    input  wire [2:0]               i_cpu_op,       // operation
    // Data input
    input  wire [XLEN-1:0]          i_rs1, // rf source 1
    input  wire [XLEN-1:0]          i_rs2, // shift amount
    // Results and status
    output wire [XLEN-1:0]          o_res, // result
    output wire                     o_busy,
    output wire [THREAD_COUNT-1:0]  o_valid // output valid
);

    localparam DIV_OP    = 3'b100,
               DIVU_OP   = 3'b101,
               REM_OP    = 3'b110,
               REMU_OP   = 3'b111;

    localparam S_IDLE = 2'b00,
               S_BUSY = 2'b01,
               S_DONE = 2'b10,
               S_READY = 2'b11;

    reg  [THREAD_COUNT-1:0] r_req_thread;
    
    reg             sign_mod;
    reg  [XLEN-1:0] rs2_abs;
    wire [XLEN-1:0] res_u;
    wire [XLEN-1:0] res;

    reg [XLEN-1:0] remainder;
    reg [XLEN-1:0] quotient;
    wire [XLEN:0]   sub;

    reg [1:0] state, next;
    reg [4:0] r_cnt;

    wire rs1_is_signed = (i_cpu_op == DIV_OP) || (i_cpu_op == REM_OP);
    wire rs2_is_signed = (i_cpu_op == DIV_OP) || (i_cpu_op == REM_OP);
    
    wire i_start = |i_req_thread;
    
    assign sub = {1'b0, remainder[30:0], quotient[31]} - {1'b0, rs2_abs};

    assign res_u = i_cpu_op[1]? remainder: quotient;
    assign res   = sign_mod? -res_u: res_u;

    always @(posedge i_clk)
        if (!i_rstn) state <= S_IDLE;
        else state <= next;

    always @(*) begin
        case (state)
            S_IDLE: next = i_start? S_BUSY: S_IDLE;
            S_BUSY: next = !(|r_cnt)? S_DONE: S_BUSY;
            S_DONE: next = S_READY;
            S_READY: next = S_IDLE;
            default: next = S_IDLE;
        endcase
    end

    always @(posedge i_clk)
        if (!i_rstn) begin
            sign_mod <= 1'b0;
            rs2_abs  <= {XLEN{1'b0}};
            r_req_thread <= {THREAD_COUNT{1'b0}};
        end
        else if ((state == S_IDLE) && i_start) begin
            sign_mod <= (i_cpu_op == DIV_OP)? (i_rs1[XLEN-1] ^ i_rs2[XLEN-1]) & (|i_rs2):
                        (i_cpu_op == REM_OP)?  i_rs1[XLEN-1]: 1'b0;

            rs2_abs <= (i_rs2[XLEN-1] && rs2_is_signed)? -i_rs2: i_rs2;
            
            if (state == S_IDLE) begin
                if (i_start) r_req_thread <= i_req_thread;
                else r_req_thread <= {THREAD_COUNT{1'b0}};
            end
        end

    always @(posedge i_clk)
        if (state == S_IDLE) r_cnt <= 5'd30;
        else r_cnt <= r_cnt - 5'd1;

    always @(posedge i_clk) begin
        if ((state == S_IDLE) && i_start) begin
            quotient <= (i_rs1[XLEN-1] && rs1_is_signed)? -i_rs1: i_rs1;
            remainder <= {XLEN{1'b0}};
        end
        else if ((state == S_BUSY) || (state == S_DONE)) begin
            quotient <= {quotient[30:0], ~sub[32]};
            remainder <= !sub[32]? sub[31:0]: {remainder[30:0], quotient[31]};
        end
    end

    assign o_res   = res;
    assign o_busy  = state != S_READY;
    assign o_valid = r_req_thread & {THREAD_COUNT{state == S_READY}};

endmodule
