`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2023 04:18:51 PM
// Design Name: 
// Module Name: rv32_dmem
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


module rv32_dmem #(
    parameter XLEN         = 32,
    parameter CHANNEL      = 4,
    parameter LOG2_CHANNEL = 2,
    parameter BANK_DEPTH   = 1024,
    parameter LOG2_DEPTH   = 10                 
)
(
    // Global control
    input  wire i_clk,
    input  wire i_rstn,
    // Write interface
    input  wire [CHANNEL*XLEN-1:0] i_mem_wadr,
    input  wire [CHANNEL-1:0]      i_mem_we,
    input  wire [CHANNEL*4-1:0]    i_mem_ben,
    input  wire [CHANNEL*XLEN-1:0] i_mem_wdata,
    output wire [CHANNEL-1:0]      o_mem_wack,
    // Read interface
    input  wire [CHANNEL*XLEN-1:0] i_mem_radr,
    input  wire [CHANNEL-1:0]      i_mem_re,
    output wire [CHANNEL*XLEN-1:0] o_mem_rdata,
    output wire [CHANNEL-1:0]      o_mem_rack        
);

    localparam ADR_LSB   = LOG2_DEPTH - 2;
    localparam TAG_WIDTH = XLEN - LOG2_DEPTH;
    
    genvar channel_idx;
    generate
        for (channel_idx = 0; channel_idx < CHANNEL; channel_idx = channel_idx + 1) begin: channel
            wire [XLEN-1:0]       mem_draw  = i_mem_wadr[(channel_idx+1)*XLEN-1-:XLEN];
            wire [ADR_LSB-1:0]    mem_wadr  = mem_draw[LOG2_DEPTH-1:2];
            wire [XLEN-LOG2_DEPTH-1:0] mem_tag = mem_draw[XLEN-1-:TAG_WIDTH];
            wire                  mem_we    = i_mem_we[channel_idx];
            wire [3:0]            mem_ben   = i_mem_ben[(channel_idx+1)*4-1-:4];
            wire [XLEN-1:0]       mem_wdata = i_mem_wdata[(channel_idx+1)*XLEN-1-:XLEN];
            reg                   ro_mem_wack;
            
            wire [ADR_LSB-1:0]    mem_radr  = i_mem_radr[(channel_idx+1)*LOG2_DEPTH-1-:ADR_LSB];
            wire                  mem_re    = i_mem_re[channel_idx];
            reg  [7:0]            ro_mem_rdata [3:0];
            reg                   ro_mem_rack;
            
            reg [7:0] bank_0 [BANK_DEPTH/4-1:0];
            reg [7:0] bank_1 [BANK_DEPTH/4-1:0];
            reg [7:0] bank_2 [BANK_DEPTH/4-1:0];
            reg [7:0] bank_3 [BANK_DEPTH/4-1:0];
            
//            reg [7:0] data_forward [3:0];
//            reg [3:0] byte_forward;
            

            
            always @(posedge i_clk) begin
                if (mem_we && mem_ben[0]) bank_0[mem_wadr] <= mem_wdata[7:0];
                if (mem_we && mem_ben[1]) bank_1[mem_wadr] <= mem_wdata[15:8];
                if (mem_we && mem_ben[2]) bank_2[mem_wadr] <= mem_wdata[23:16];
                if (mem_we && mem_ben[3]) bank_3[mem_wadr] <= mem_wdata[31:24];
            end
            
            always @(posedge i_clk) begin                
                ro_mem_rdata[0] <= bank_0[mem_radr];
                ro_mem_rdata[1] <= bank_1[mem_radr];
                ro_mem_rdata[2] <= bank_2[mem_radr];
                ro_mem_rdata[3] <= bank_3[mem_radr];
            end
                        
            always @(posedge i_clk, negedge i_rstn) begin
                if (!i_rstn) begin
                    ro_mem_rack <= 1'b0;
                    ro_mem_wack <= 1'b0;
//                    byte_forward <= 4'b0000;               
                end
                else begin
                    ro_mem_rack <= mem_re;
                    ro_mem_wack <= mem_we;
//                    byte_forward[0] <= (mem_wadr == mem_radr) && (mem_we && mem_re) && mem_ben[0];
//                    byte_forward[1] <= (mem_wadr == mem_radr) && (mem_we && mem_re) && mem_ben[1];
//                    byte_forward[2] <= (mem_wadr == mem_radr) && (mem_we && mem_re) && mem_ben[2];
//                    byte_forward[3] <= (mem_wadr == mem_radr) && (mem_we && mem_re) && mem_ben[3];
//                    data_forward[0] <= mem_wdata[7:0];
//                    data_forward[1] <= mem_wdata[15:8];
//                    data_forward[2] <= mem_wdata[23:16];
//                    data_forward[3] <= mem_wdata[31:24];                   
                end  
            end
            
            assign o_mem_wack[channel_idx] = ro_mem_wack;
//            assign o_mem_rdata[(channel_idx+1)*XLEN-1-:XLEN] = {byte_forward[3]? data_forward[3]: ro_mem_rdata[3], 
//                                                                byte_forward[2]? data_forward[2]: ro_mem_rdata[2],
//                                                                byte_forward[1]? data_forward[1]: ro_mem_rdata[1],
            assign o_mem_rdata[(channel_idx+1)*XLEN-1-:XLEN] = {ro_mem_rdata[3], ro_mem_rdata[2], ro_mem_rdata[1], ro_mem_rdata[0]};
            assign o_mem_rack[channel_idx] = ro_mem_rack;
        end
    endgenerate

endmodule
