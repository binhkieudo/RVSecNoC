`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 01:43:45 PM
// Design Name: 
// Module Name: shifter
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


module shifter #(
    parameter XLEN = 32,
    parameter METHOD = "FPGA"
)(
    // Global control    
    input  wire             i_clk, // global clock, rising edge
    // Control signals
    input  wire             i_cpu_trap,
    input  wire             i_shift_right, // shift left operation
    input  wire             i_shift_arth, // shift logical (only for shift right)
    input  wire             i_start, // start operation
    // Data input
    input  wire [XLEN-1:0]  i_rs1, // rf source 1
    input  wire [4:0]       i_shamt, // shift amount
    // Results and status
    output wire [XLEN-1:0]  o_res, // result
    output wire             o_valid // output valid
);
    
    reg [XLEN-1:0]  ro_res;
    reg             ro_valid;
    
    generate
        if (METHOD == "FPGA") begin    
            always @(posedge i_clk) begin
                ro_res   <= !i_shift_right? i_rs1 << i_shamt: 
                            i_shift_arth  ? i_rs1 >>> i_shamt: 
                                           i_rs1 >> i_shamt;
                ro_valid <= i_start;
            end
        end
        if (METHOD == "BARREL") begin
            reg [XLEN-1:0] bs_level [0:5];
            reg [XLEN-1:0] bs_result;
            reg [XLEN-1:0] rv_result; // reverse result
              
            integer i;
            always @(*) begin
                // input layer: convert left shifts to right shifts by reversing
                if (i_shift_right)
                    bs_level[5] = i_rs1;
                else
                    for (i = 0; i < XLEN; i = i + 1) begin
                        bs_level[5][i] = i_rs1[XLEN-i-1];
                        rv_result[i]   = bs_result[XLEN-1-i];
                    end
                // Shifter
                if (i_shamt[4]) begin
                    bs_level[4][XLEN-1:16] = {16{bs_level[5][XLEN-1] & i_shift_arth}};
                    bs_level[4][15:0] = bs_level[5][XLEN-1:16];
                end
                else bs_level[4] = bs_level[5];
        
                if (i_shamt[3]) begin
                    bs_level[3][XLEN-1:24] = {8{bs_level[4][XLEN-1] & i_shift_arth}};
                    bs_level[3][23:0] = bs_level[4][XLEN-1:8];
                end
                else bs_level[3] = bs_level[4];
        
                if (i_shamt[2]) begin
                    bs_level[2][XLEN-1:28] = {4{bs_level[3][XLEN-1] & i_shift_arth}};
                    bs_level[2][27:0] = bs_level[3][XLEN-1:4];
                end
                else bs_level[2] = bs_level[3];
        
                if (i_shamt[1]) begin
                    bs_level[1][XLEN-1: 30] = {2{bs_level[2][XLEN-1] & i_shift_arth}};
                    bs_level[1][29:0] = bs_level[2][XLEN-1:2];
                end
                else bs_level[1] = bs_level[2];
        
                if (i_shamt[0]) begin
                    bs_level[0][XLEN-1] = bs_level[1] & i_shift_arth;
                    bs_level[0][30:0] = bs_level[1][XLEN-1:1];
                end
                else bs_level[0] = bs_level[1];
            end
        
            always @(*) begin
                bs_result = bs_level[0];
            end
            
            always @(posedge i_clk) begin
                ro_res   <= i_shift_right? bs_result: rv_result;
                ro_valid <= i_start; 
            end          
        end
        if (METHOD == "SERIAL") begin
            wire done;
        
            reg r_busy;
            reg [4:0] r_cnt;
            reg [XLEN-1:0] ro_res;
        
            assign done = r_cnt == 5'd1;
            
            always @(posedge i_clk) begin
                // Busy flag
                if (i_start) r_busy <= 1'b1;
                else if (done || i_cpu_trap) r_busy <= 1'b0;
                    
                // Shift process
                if (i_start) begin
                    r_cnt <= i_shamt;
                    ro_res <= i_rs1;
                end
                else if (|r_cnt) begin
                    r_cnt <= r_cnt - 5'd1;
                
                    if (i_shift_right)
                        ro_res <= {ro_res[XLEN-1] & i_shift_arth, ro_res[XLEN-1:1]};
                    else
                        ro_res <= {ro_res[XLEN-2:0], 1'b0};
                end
            end
            
            always @(*)
               ro_valid = r_busy && done;             
        end
    endgenerate
    
    assign o_res = ro_res;
    assign o_valid = ro_valid;
    
endmodule
