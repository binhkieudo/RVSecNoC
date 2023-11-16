`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2023 10:50:54 PM
// Design Name: 
// Module Name: rv32_icache
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


module rv32_icache #(
    parameter XLEN    = 32,
    parameter DEPTH   = 1024,
    parameter CHANNEL = 8
)
(
    // Global control
    input  wire i_clk,
    input  wire i_rstn,
    // MEM interface
    input  wire [CHANNEL*XLEN-1:0] i_bus_req_addr, // access address
    input  wire [CHANNEL-1:0]      i_bus_req_re,   // read request
    output wire [CHANNEL*XLEN-1:0] o_bus_rsp_data, // read data
    output wire [CHANNEL-1:0]      o_bus_rsp_ack,  // access acknowledge
    // MEM write interface
    input  wire [CHANNEL*XLEN-1:0] i_bus_waddr, // access address
    input  wire [CHANNEL-1:0]      i_bus_we,   // read request
    input  wire [CHANNEL*XLEN-1:0] i_bus_wdata // access address
);

    genvar channel_idx;
    generate
        for (channel_idx = 0; channel_idx < CHANNEL; channel_idx = channel_idx + 1) begin: thread
            reg [XLEN-1:0] bank [0:DEPTH-1];
            
            integer i;
            initial begin
               bank[0] = 32'h00000433; // add s0, zero, zero
               for (i = 1; i < 1024; i = i + 1) begin
                  bank[i] = 32'h00140413; // addi s0, s0, 1  
               end
            end
            
            reg [XLEN-1:0] rdata;
            reg            r_ack;
            
            wire [$clog2(DEPTH)-1:0] raddr = i_bus_req_addr[(channel_idx+1)*XLEN-1 -: 32];
            wire [$clog2(DEPTH)-1:0] waddr = i_bus_waddr[(channel_idx+1)*XLEN-1 -: 32];
            
            always @(posedge i_clk) begin
                if (i_bus_we[channel_idx]) 
                    bank[waddr] <= i_bus_wdata[(channel_idx+1)*XLEN - 1 -: XLEN];
            
                rdata <= bank[raddr];
                r_ack <= i_bus_req_re[channel_idx];
            end 
            
            assign o_bus_rsp_data[(channel_idx+1)*XLEN - 1 -: XLEN] = rdata;
            assign o_bus_rsp_ack[channel_idx] = r_ack;
        end
    endgenerate

endmodule
