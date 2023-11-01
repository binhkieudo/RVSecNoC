`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2023 01:54:24 PM
// Design Name: 
// Module Name: ibus_abitrator
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


module ibus_abitrator#(
    parameter XLEN = 32,
    parameter THREAD_COUNT = 8,
    parameter CHANNEL = 4
)
(
    input  wire i_clk,
    input  wire i_rstn,
    // Request
    input  wire [THREAD_COUNT*XLEN-1:0] i_bus_req_addr,
    input  wire [THREAD_COUNT-1:0]      i_bus_req_re,
    // Response
    output wire [THREAD_COUNT*XLEN-1:0] o_bus_rsp_data,
    output wire [THREAD_COUNT-1:0]      o_bus_rsp_ack,
    // To ICACHE
    output wire [CHANNEL*XLEN - 1 : 0]  o_imem_adr,
    input  wire [CHANNEL*XLEN - 1 : 0]  i_imem_instr
);

endmodule
