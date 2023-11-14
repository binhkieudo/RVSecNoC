`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 01:41:22 PM
// Design Name: 
// Module Name: rv32_cpu_coproc
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


module rv32_cpu_coproc #(
    parameter XLEN = 32,
    parameter THREAD_COUNT = 8, // number of input thread
    parameter TYPE_COUNT   = 2, // number of co-processor types
    parameter SHIFT_COUNT  = 4, // number of shifter
    parameter MULT_COUNT   = 4  // number of multiplier
)
(
    // Global control
    input  wire i_clk,
    input  wire i_rstn,
    // CPU interface
    output wire [THREAD_COUNT*XLEN-1:0]       o_cpu_res,
    output wire [THREAD_COUNT-1:0]            o_cpu_resvld,
    input  wire [THREAD_COUNT*TYPE_COUNT-1:0] i_cpu_en,
    input  wire                               i_cpu_trap,
    input  wire [THREAD_COUNT*3-1:0]          i_cpu_op,
    input  wire [THREAD_COUNT*5-1:0]          i_cpu_exop,
    // Register interface
    input  wire [THREAD_COUNT*XLEN-1:0]       i_rs1,
    input  wire [THREAD_COUNT*XLEN-1:0]       i_rs2
);

    localparam SHIFT_SEL_BIT = 0,
               MULT_SEL_BIT  = 1;  
      
    wire [XLEN-1:0]         shifter_result [SHIFT_COUNT-1:0];
    wire                    shifter_busy   [SHIFT_COUNT-1:0];
    wire [THREAD_COUNT-1:0] shifter_valid  [SHIFT_COUNT-1:0];
    wire [THREAD_COUNT-1:0] shifter_sel;
    
    genvar shifter_idx;
    generate
        for (shifter_idx = 0; shifter_idx < SHIFT_COUNT; shifter_idx = shifter_idx + 1) begin: shifter
            
            rv32_cp_shifter #(
                .XLEN         (XLEN),
                .THREAD_COUNT (THREAD_COUNT),
                .METHOD       ("FPGA")
            )
            inst (
                .i_clk        (i_clk ),
                // Control signals
                .i_req_thread ( ),
                .i_cpu_op     ( ),
                // Data input
                .i_rs1        ( ),
                .i_rs2        ( ),
                // Results and status
                .o_res        (shifter_result[shifter_idx] ),
                .o_busy       (shifter_busy[shifter_idx]),
                .o_valid      (shifter_valid[shifter_idx] )
            );
        end
    endgenerate
    
    
endmodule
