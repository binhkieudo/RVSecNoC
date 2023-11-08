`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2023 12:39:14 PM
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


module top #(
    parameter XLEN         = 32,
    parameter THREAD_COUNT = 8,
    parameter CHANNEL      = 4,
    parameter LOG2_CHANNEL = 2,
    parameter BANK_DEPTH   = 1024,
    parameter LOG2_DEPTH   = 10    
)
(
         // Global control
        input  wire i_clk,
        input  wire i_rstn,
        // Control signals
        input  wire [THREAD_COUNT*3-1:0]     i_funct3,
        // CPU request -- Write
        input  wire [THREAD_COUNT*XLEN-1:0]  i_wadr,
        input  wire [THREAD_COUNT-1:0]       i_we,
        input  wire [THREAD_COUNT*XLEN-1:0]  i_wdata,
        output wire [THREAD_COUNT-1:0]       o_wack,
        // CPU request -- Read
        input  wire [THREAD_COUNT*XLEN-1:0]  i_radr,
        input  wire [THREAD_COUNT-1:0]       i_re,
        output wire [THREAD_COUNT*XLEN-1:0]  o_rdata,
        output wire [THREAD_COUNT-1:0]       o_rack       
);

    wire [CHANNEL*XLEN-1:0] lsu_mem_wadr;
    wire [CHANNEL-1:0]      lsu_mem_we;
    wire [CHANNEL*4-1:0]    lsu_mem_ben;
    wire [CHANNEL*XLEN-1:0] lsu_mem_wdata;
    wire [CHANNEL*XLEN-1:0] lsu_mem_radr;
    wire [CHANNEL-1:0]      lsu_mem_re;
    
    wire [CHANNEL-1:0]      dmem_mem_wack;
    wire [CHANNEL*XLEN-1:0] dmem_mem_rdata;
    wire [CHANNEL-1:0]      dmem_mem_rack; 
       
    rv32_lsu2 #(
        .XLEN           (XLEN         ),
        .THREAD_COUNT   (THREAD_COUNT ),
        .CHANNEL        (CHANNEL      ),
        .LOG2_CHANNEL   (LOG2_CHANNEL ),
        .BANK_DEPTH     (BANK_DEPTH   ),
        .LOG2_DEPTH     (LOG2_DEPTH   )
    )
    lsu_inst0 (
        // Global control
        .i_clk      (i_clk          ),
        .i_rstn     (i_rstn         ),
        // Control signals
        .i_funct3   (i_funct3       ),
        // CPU request -- Write
        .i_wadr     (i_wadr         ),
        .i_we       (i_we           ),
        .i_wdata    (i_wdata        ),
        .o_wack     (o_wack         ),
        // CPU request -- Write
        .i_radr     (i_radr         ),
        .i_re       (i_re           ),
        .o_rdata    (o_rdata        ),
        .o_rack     (o_rack         ),
        // Memory interface -- Write
        .o_mem_wadr (lsu_mem_wadr   ),
        .o_mem_we   (lsu_mem_we     ),
        .o_mem_ben  (lsu_mem_ben    ),
        .o_mem_wdata(lsu_mem_wdata  ),
        .i_mem_wack (dmem_mem_wack  ),
        // Memory interface -- Read
        .o_mem_radr (lsu_mem_radr   ),
        .o_mem_re   (lsu_mem_re     ),
        .i_mem_rdata(dmem_mem_rdata ),
        .i_mem_rack (dmem_mem_rack  )
    );

    rv32_dmem #(
        .XLEN         (XLEN         ),
        .CHANNEL      (CHANNEL      ),
        .LOG2_CHANNEL (LOG2_CHANNEL ),
        .BANK_DEPTH   (BANK_DEPTH   ),
        .LOG2_DEPTH   (LOG2_DEPTH   )
    ) 
    dmem_inst0 (
        // Global control
        .i_clk       (i_clk         ),
        .i_rstn      (i_rstn        ),
        // Write interface
        .i_mem_wadr  (lsu_mem_wadr  ),
        .i_mem_we    (lsu_mem_we    ),
        .i_mem_ben   (lsu_mem_ben   ),
        .i_mem_wdata (lsu_mem_wdata ),
        .o_mem_wack  (dmem_mem_wack ),
        // Read interface
        .i_mem_radr  (lsu_mem_radr  ),
        .i_mem_re    (lsu_mem_re    ),
        .o_mem_rdata (dmem_mem_rdata),
        .o_mem_rack  (dmem_mem_rack )
    );
    
endmodule
