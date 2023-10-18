`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2023 05:13:27 PM
// Design Name: 
// Module Name: wb_ram
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


module wb_ram #(
    parameter depth = 256, // in bytes
    parameter aw    = $clog2(depth)
)
   (input wire 		   i_wb_clk,
    input wire 		   i_wb_rstn,
    input wire [31:0]  i_wb_adr,
    input wire [31:0]  i_wb_dat,
    input wire [3:0]   i_wb_sel,
    input wire 		   i_wb_we,
    input wire 		   i_wb_cyc,
    output reg [31:0]  o_wb_rdt,
    output reg 		   o_wb_ack
);

   wire [3:0] 		we = {4{i_wb_we & i_wb_cyc}} & i_wb_sel;

   reg [31:0] 		mem [0:depth/4-1];

   wire [aw-3:0] 	addr = i_wb_adr[aw-1:2];
   
   
   integer i;
   initial begin
    for (i = 0; i < depth/4; i = i + 1)
        mem[i] = 32'd0; 
    mem[0] = 32'h00628433; // add x8, x5, x6
    mem[1] = 32'h008384b3; // add x9, x7, x8
    mem[2] = 32'h00628433; // add x8, x5, x6
    mem[3] = 32'h008384b3; // add x9, x7, x8
    mem[4] = 32'h008384b3; // add x9, x7, x8
    mem[5] = 32'h00628433; // add x8, x5, x6
    mem[6] = 32'h008384b3; // add x9, x7, x8
    mem[7] = 32'h00628433; // add x8, x5, x6
   end
   

   always @(posedge i_wb_clk)
     if (!i_wb_rstn)
       o_wb_ack <= 1'b0;
     else
       o_wb_ack <= i_wb_cyc;

   always @(posedge i_wb_clk) begin
      if (we[0]) mem[addr][7:0]   <= i_wb_dat[7:0];
      if (we[1]) mem[addr][15:8]  <= i_wb_dat[15:8];
      if (we[2]) mem[addr][23:16] <= i_wb_dat[23:16];
      if (we[3]) mem[addr][31:24] <= i_wb_dat[31:24];
      
      o_wb_rdt <= mem[addr];
   end

endmodule
