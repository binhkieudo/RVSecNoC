`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2023 03:55:42 PM
// Design Name: 
// Module Name: tb_fifo
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


module tb_fifo(

    );
    
    parameter FIFO_WIDTH = 32;
    
    // Global control
    reg                   i_clk     = 1'b0;   // global clock; rising edge
    reg                   i_rstn    = 1'b0;  // global reset; low-active; async
    // Control signal
    reg                   i_clear   = 1'b0; // sync reset; high-active
    wire                  o_half;  // FIFO is half full
    // Write port
    reg [FIFO_WIDTH-1:0]  i_wdata   = 32'd0; // write data
    reg                   i_we      = 1'b0;    // write enable
    wire                  o_free;  // at least one entry is free when set
    // Read port
    reg                   i_re      = 1'b0;    // read enable
    wire [FIFO_WIDTH-1:0] o_rdata; // read data
    wire                  o_avail;  // data available when set
    
    ip_fifo udt(.*);
    
    always #5 i_clk = ~i_clk;
    
    integer i;
    initial begin
        #10 i_rstn = 1'b1;
        #10 i_we = 1'b1;
        i_wdata = 32'd1;
        for (i = 2; i < 32; i = i + 1)
            #10 i_wdata = i;
        #10 i_wdata = 32;
        i_re = 1;
        #10 i_wdata = 33;
        #10 i_we = 1'b0;
        #1000 $stop;
    end
    
endmodule
