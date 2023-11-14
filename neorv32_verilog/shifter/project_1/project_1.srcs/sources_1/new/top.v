`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 01:59:15 PM
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
        input wire i_clk
    );
    
    parameter XLEN = 32;
    
    // Control signals
    wire             i_shift_right; // shift left operation
    wire             i_shift_arth; // shift logical (only for shift right)
    wire             i_start; // start operation
    // Data input
    wire [XLEN-1:0]  i_rs1; // rf source 1
    wire [4:0]       i_shamt; // shift amount
    // Results and status
    wire [XLEN-1:0]  o_res; // result
    wire             o_valid; // output valid
    
    shifter #( 
        .XLEN   (XLEN),
        .METHOD ("FPGA")
    )
    u0 (
        .i_clk          (i_clk          ),
        .i_shift_right  (i_shift_right  ),
        .i_shift_arth   (i_shift_arth   ),
        .i_start        (i_start        ),
        .i_rs1          (i_rs1          ),
        .i_shamt        (i_shamt        ),
        .o_res          (o_res          ),
        .o_valid        (o_valid        )
    );
    
    vio_0 vio_0(
        .clk        (i_clk          ),
        .probe_in0  (o_res          ),
        .probe_in1  (o_valid        ),
        .probe_out0 (i_shift_right  ),
        .probe_out1 (i_shift_arth   ),
        .probe_out2 (i_start        ),
        .probe_out3 (i_rs1          ),
        .probe_out4 (i_shamt        )
    );
    
endmodule
