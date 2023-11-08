`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2023 02:49:14 AM
// Design Name: 
// Module Name: vtop
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


module vtop(
        input i_clk
    );
    
    parameter XLEN         = 32;
    parameter THREAD_COUNT = 8;
    parameter CHANNEL      = 4;
    parameter LOG2_CHANNEL = 2;
    parameter BANK_DEPTH   = 1024;
    parameter LOG2_DEPTH   = 10;
    
    // Global control
    wire i_rstn;
    // Control signals
    wire [THREAD_COUNT*3-1:0]     i_funct3; // 21
    // CPU request -- Write
    wire [THREAD_COUNT*XLEN-1:0]  i_wadr;   // 256
    wire [THREAD_COUNT-1:0]       i_we;     // 8
    wire [THREAD_COUNT*XLEN-1:0]  i_wdata;  // 256
    wire [THREAD_COUNT-1:0]       o_wack;   // 8
    // CPU request -- Read
    wire [THREAD_COUNT*XLEN-1:0]  i_radr;   // 256
    wire [THREAD_COUNT-1:0]       i_re;     // 8
    wire [THREAD_COUNT*XLEN-1:0]  o_rdata;  // 256
    wire [THREAD_COUNT-1:0]       o_rack;   // 8
            
    top u0 (
        .i_clk      (i_clk      ),
        .i_rstn     (i_rstn     ),
        .i_funct3   (i_funct3   ),
        .i_wadr     (i_wadr     ),
        .i_we       (i_we       ),
        .i_wdata    (i_wdata    ),
        .o_wack     (o_wack     ),
        .i_radr     (i_radr     ),
        .i_re       (i_re       ),
        .o_rdata    (o_rdata    ),
        .o_rack     (o_rack     )
    ); 
    
    vio_0 vio_0(
        .clk        (i_clk      ),
        .probe_in0  (o_wack     ),
        .probe_in1  (o_rdata    ),
        .probe_in2  (o_rack     ),
        .probe_out0 (i_rstn     ),
        .probe_out1 (i_funct3   ),
        .probe_out2 (i_wadr     ),
        .probe_out3 (i_we       ),
        .probe_out4 (i_wdata    ),
        .probe_out5 (i_radr     ),
        .probe_out6 (i_re       )
    );
    
endmodule
