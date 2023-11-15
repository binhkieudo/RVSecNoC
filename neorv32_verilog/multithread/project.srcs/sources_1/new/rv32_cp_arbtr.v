`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2023 05:22:08 PM
// Design Name: 
// Module Name: rv32_cp_arbtr
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


module rv32_cp_arbtr#(
    parameter XLEN         = 32,
    parameter THREAD       = 4,
    parameter CHANNEL      = 2,
    parameter LOG2_CHANNEL = 1
)
(
    // Global control
    input  wire i_clk,
    // Thread control
    input  wire [THREAD-1:0]        i_cpu_cpen,
    input  wire [THREAD-1:0]        i_cpu_trap,
    input  wire [THREAD*3-1:0]      i_cpu_op,
    input  wire [THREAD*5-1:0]      i_cpu_exop,
    input  wire [THREAD*XLEN-1:0]   i_cpu_rs1,
    input  wire [THREAD*XLEN-1:0]   i_cpu_rs2,
    // Channel control
    output wire [CHANNEL*THREAD-1:0]o_cp_req,
    output wire [CHANNEL-1:0]       o_cp_en,
    output wire [CHANNEL-1:0]       o_cp_trap,
    output wire [CHANNEL*3-1:0]     o_cp_op,
    output wire [CHANNEL*5-1:0]     o_cp_exop,
    output wire [CHANNEL*XLEN-1:0]  o_cp_rs1,
    output wire [CHANNEL*XLEN-1:0]  o_cp_rs2,
    input  wire [CHANNEL-1:0]       i_cp_busy
);

    reg [LOG2_CHANNEL-1:0] sel_channel [THREAD-1:0];
    reg [CHANNEL-1:0]      sel_we      [THREAD-1:0];
    reg [CHANNEL-1:0]      sel_busy    [THREAD-1:0]; 
    
    reg [THREAD-1:0]      r1_cp_req  [CHANNEL-1:0];
    reg                   r1_cp_en   [CHANNEL-1:0][THREAD-1:0];
    reg                   r1_cp_trap [CHANNEL-1:0][THREAD-1:0];
    reg [2:0]             r1_cp_op   [CHANNEL-1:0][THREAD-1:0];
    reg [4:0]             r1_cp_exop [CHANNEL-1:0][THREAD-1:0];
    reg [XLEN-1:0]        r1_cp_rs1  [CHANNEL-1:0][THREAD-1:0];
    reg [XLEN-1:0]        r1_cp_rs2  [CHANNEL-1:0][THREAD-1:0];
   
    reg                   r2_cp_en   [CHANNEL-1:0][THREAD-1:0];
    reg                   r2_cp_trap [CHANNEL-1:0][THREAD-1:0];
    reg [2:0]             r2_cp_op   [CHANNEL-1:0][THREAD-1:0];
    reg [4:0]             r2_cp_exop [CHANNEL-1:0][THREAD-1:0];
    reg [XLEN-1:0]        r2_cp_rs1  [CHANNEL-1:0][THREAD-1:0];
    reg [XLEN-1:0]        r2_cp_rs2  [CHANNEL-1:0][THREAD-1:0];
        
    reg [CHANNEL*THREAD-1:0]    ro_cp_req;
    reg [CHANNEL-1:0]           ro_cp_en;
    reg [CHANNEL-1:0]           ro_cp_trap;
    reg [CHANNEL*3-1:0]         ro_cp_op;
    reg [CHANNEL*5-1:0]         ro_cp_exop;
    reg [CHANNEL*XLEN-1:0]      ro_cp_rs1;
    reg [CHANNEL*XLEN-1:0]      ro_cp_rs2;
        
    generate
        if (CHANNEL >= THREAD) begin: forward
            integer c_idx;
            always @(*) begin
                ro_cp_req   = 'b0;
                ro_cp_en    = 'b0;
                ro_cp_trap  = 'b0;
                ro_cp_op    = 'b0;
                ro_cp_exop  = 'b0;
                ro_cp_rs1   = 'b0;
                ro_cp_rs2   = 'b0;
                
                
                ro_cp_en[CHANNEL-1:0]      = i_cpu_cpen;
                ro_cp_trap[CHANNEL-1:0]    = i_cpu_trap;
                ro_cp_op[CHANNEL*3-1:0]    = i_cpu_op;
                ro_cp_exop[CHANNEL*5-1:0]  = i_cpu_exop;
                ro_cp_rs1[THREAD*XLEN-1:0] = i_cpu_rs1;
                ro_cp_rs2[THREAD*XLEN-1:0] = i_cpu_rs2;
                
                for (c_idx = 0; c_idx < CHANNEL; c_idx = c_idx + 1)
                    ro_cp_req[(c_idx+1)*THREAD-1-:THREAD] = 2**c_idx;
            end
        end
        else begin: arbitrator
            integer t_idx, c_idx;
            always @(*) begin
                sel_channel[0]  = {LOG2_CHANNEL{1'b0}};
                sel_we[0]       = i_cpu_cpen[0] && !(&i_cp_busy);
                sel_busy[0]     = i_cp_busy;
                for (c_idx = CHANNEL-1; c_idx >= 0; c_idx = c_idx - 1) begin
                    if (!i_cp_busy[c_idx] && i_cpu_cpen[0]) begin
                        sel_channel[0]  = c_idx[LOG2_CHANNEL-1:0];
                        sel_busy[0]     = i_cp_busy | (2**c_idx);
                    end
                end
                
                for (t_idx = 1; t_idx < THREAD; t_idx = t_idx + 1) begin
                    sel_channel[t_idx] = sel_channel[t_idx-1] + sel_we[t_idx-1][0];
                    sel_we[t_idx] = {{(CHANNEL-1){1'b0}}, i_cpu_cpen[t_idx] && !sel_busy[t_idx-1][sel_channel[t_idx]]};
                    sel_busy[t_idx] = sel_busy[t_idx-1] | (sel_we[t_idx] << sel_channel[t_idx]);
                end
            end
            
            integer t_idx0, t_idx1, c_idx_0;
            always @(*) begin
                for (c_idx_0 = 0; c_idx_0 < CHANNEL; c_idx_0 = c_idx_0 + 1) begin
                    for (t_idx0 = 0; t_idx0 < THREAD; t_idx0 = t_idx0 + 1) begin
                        r1_cp_en[c_idx_0][t_idx0]   = i_cpu_cpen[t_idx0]                  & (sel_we[t_idx0] && (sel_channel[t_idx0] == c_idx_0));
                        r1_cp_trap[c_idx_0][t_idx0] = i_cpu_trap[t_idx0]                  & (sel_we[t_idx0] && (sel_channel[t_idx0] == c_idx_0));
                        r1_cp_op[c_idx_0][t_idx0]   = i_cpu_op[(t_idx0+1)*3-1-:3]         & {3{sel_we[t_idx0] && (sel_channel[t_idx0] == c_idx_0)}};
                        r1_cp_exop[c_idx_0][t_idx0] = i_cpu_exop[(t_idx0+1)*5-1-:5]       & {5{sel_we[t_idx0] && (sel_channel[t_idx0] == c_idx_0)}};
                        r1_cp_rs1[c_idx_0][t_idx0]  = i_cpu_rs1[(t_idx0+1)*XLEN-1-:XLEN]  & {32{sel_we[t_idx0] && (sel_channel[t_idx0] == c_idx_0)}};
                        r1_cp_rs2[c_idx_0][t_idx0]  = i_cpu_rs2[(t_idx0+1)*XLEN-1-:XLEN]  & {32{sel_we[t_idx0] && (sel_channel[t_idx0] == c_idx_0)}};
                        
                        r1_cp_req[c_idx_0][t_idx0] = sel_we[t_idx0] && (sel_channel[t_idx0] == c_idx_0);
                    end
                    
                    r2_cp_en[c_idx_0][0]   = r1_cp_en[c_idx_0][0];
                    r2_cp_trap[c_idx_0][0] = r1_cp_trap[c_idx_0][0];
                    r2_cp_op[c_idx_0][0]   = r1_cp_op[c_idx_0][0];
                    r2_cp_exop[c_idx_0][0] = r1_cp_exop[c_idx_0][0];
                    r2_cp_rs1[c_idx_0][0]  = r1_cp_rs1[c_idx_0][0];
                    r2_cp_rs2[c_idx_0][0]  = r1_cp_rs2[c_idx_0][0];
                                            
                    for (t_idx1 = 1; t_idx1 < THREAD; t_idx1 = t_idx1 + 1) begin
                        r2_cp_en[c_idx_0][t_idx1]   = r2_cp_en[c_idx_0][t_idx1-1]   | r1_cp_en[c_idx_0][t_idx1];
                        r2_cp_trap[c_idx_0][t_idx1] = r2_cp_trap[c_idx_0][t_idx1-1] | r1_cp_trap[c_idx_0][t_idx1];
                        r2_cp_op[c_idx_0][t_idx1]   = r2_cp_op[c_idx_0][t_idx1-1]   | r1_cp_op[c_idx_0][t_idx1];
                        r2_cp_exop[c_idx_0][t_idx1] = r2_cp_exop[c_idx_0][t_idx1-1] | r1_cp_exop[c_idx_0][t_idx1];
                        r2_cp_rs1[c_idx_0][t_idx1]  = r2_cp_rs1[c_idx_0][t_idx1-1]  | r1_cp_rs1[c_idx_0][t_idx1];
                        r2_cp_rs2[c_idx_0][t_idx1]  = r2_cp_rs2[c_idx_0][t_idx1-1]  | r1_cp_rs2[c_idx_0][t_idx1];                        
                    end
                end
            end
            
            integer c_idx_1;
            always @(posedge i_clk) begin
                for (c_idx_1 = 0; c_idx_1 < CHANNEL; c_idx_1 = c_idx_1 + 1) begin
                    ro_cp_req[(c_idx_1+1)*THREAD-1-:THREAD] <= r1_cp_req[c_idx_1];
                    ro_cp_en[c_idx_1]                   <= r2_cp_en[c_idx_1][THREAD-1];
                    ro_cp_trap[c_idx_1]                 <= r2_cp_trap[c_idx_1][THREAD-1];
                    ro_cp_op[(c_idx_1+1)*3-1-:3]        <= r2_cp_op[c_idx_1][THREAD-1];
                    ro_cp_exop[(c_idx_1+1)*5-1-:5]      <= r2_cp_exop[c_idx_1][THREAD-1];
                    ro_cp_rs1[(c_idx_1+1)*XLEN-1-:XLEN] <= r2_cp_rs1[c_idx_1][THREAD-1];
                    ro_cp_rs2[(c_idx_1+1)*XLEN-1-:XLEN] <= r2_cp_rs2[c_idx_1][THREAD-1];
                end
            end
        end
    endgenerate
    
    assign o_cp_req  = ro_cp_req;
    assign o_cp_en   = ro_cp_en;
    assign o_cp_trap = ro_cp_trap;
    assign o_cp_op   = ro_cp_op;
    assign o_cp_exop = ro_cp_exop;
    assign o_cp_rs1  = ro_cp_rs1;
    assign o_cp_rs2  = ro_cp_rs2;
    
endmodule
