`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2023 10:45:17 PM
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

    parameter XLEN = 32;
    
//    // Global control
//    wire              i_rstn;
//    // Control signals
//    wire              i_start;
//    wire [2:0]        i_mul_op; 
//    // Input data
//    wire [XLEN-1:0]   i_rs1;
//    wire [XLEN-1:0]   i_rs2;
//    // Output data
//    wire [XLEN-1:0]   o_prod;
//    wire              o_valid;
    
//    rv32_mul u0 (
//        .i_clk    (i_clk   ),
//        .i_rstn   (i_rstn  ),
//        .i_start  (i_start ),
//        .i_mul_op (i_mul_op),
//        .i_rs1    (i_rs1   ),
//        .i_rs2    (i_rs2   ),
//        .o_prod   (o_prod  ),
//        .o_valid  (o_valid )
//    );

//    vio_0 vio_0(
//        .clk        (i_clk    ),
//        .probe_in0  (o_prod   ),
//        .probe_in1  (o_valid  ),
//        .probe_out0 (i_rstn   ),
//        .probe_out1 (i_start  ),
//        .probe_out2 (i_mul_op ),
//        .probe_out3 (i_rs1    ),
//        .probe_out4 (i_rs2    )
//    );
        
    wire [15:0] a, c, d;
    wire [32:0] out;
    
    dynpreaddmultadd u0 (
        .clk (i_clk),
        .a   (a),  
        .c   (c),
        .d   (d),
        .dynpreaddmultadd_out (out)
    );
    
    vio_alu vio_alu(
        .clk (i_clk ),
        .probe_in0  (out ),
        .probe_out0 (a ),
        .probe_out1 (c ),
        .probe_out2 (d )
    );


endmodule
