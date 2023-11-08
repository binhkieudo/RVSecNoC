`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2023 12:24:40 PM
// Design Name: 
// Module Name: rv32_lsu2
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


module rv32_lsu2 #(
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
    // CPU request -- Write
    input  wire [THREAD_COUNT*XLEN-1:0]  i_radr,
    input  wire [THREAD_COUNT-1:0]       i_re,
    output wire [THREAD_COUNT*XLEN-1:0]  o_rdata,
    output wire [THREAD_COUNT-1:0]       o_rack,
    // Memory interface -- Write
    output reg  [CHANNEL*XLEN-1:0]       o_mem_wadr,
    output reg  [CHANNEL-1:0]            o_mem_we,
    output reg  [CHANNEL*4-1:0]          o_mem_ben,
    output reg  [CHANNEL*XLEN-1:0]       o_mem_wdata,
    input  wire [CHANNEL-1:0]            i_mem_wack,
    // Memory interface -- Read
    output reg  [CHANNEL*XLEN-1:0]       o_mem_radr,
    output reg  [CHANNEL-1:0]            o_mem_re,
    input  wire [CHANNEL*XLEN-1:0]       i_mem_rdata,
    input  wire [CHANNEL-1:0]            i_mem_rack
);
    
//==============================================================
// Channel controller
//==============================================================    
    reg [XLEN-1:0]  r_sel_wadr  [0:CHANNEL-1];
    reg             r_we        [0:CHANNEL-1];
    reg [XLEN-1:0]  r_wdata     [0:CHANNEL-1];
    reg [3:0]       r_ben       [0:CHANNEL-1];
    reg [XLEN-1:0]  r_sel_radr  [0:CHANNEL-1];
    reg             r_re        [0:CHANNEL-1];
    
    reg [THREAD_COUNT*XLEN-1:0] r1_wdata     [0:CHANNEL-1];
    reg [THREAD_COUNT*4-1:0]    r1_ben       [0:CHANNEL-1];
        
    integer cidx, tidx;
    always @(*) begin
        // Channel   
        for (cidx = 0; cidx < CHANNEL; cidx = cidx + 1) begin
            r_wdata[cidx]   = 32'd0;
            r_ben[cidx]     = 4'b0000;
            
            for (tidx = 0; tidx < THREAD_COUNT; tidx = tidx + 1) begin
                if (i_we[tidx] && (i_wadr[tidx*XLEN+LOG2_DEPTH+LOG2_CHANNEL-1-:LOG2_CHANNEL] == cidx[LOG2_CHANNEL-1:0])) begin
                    r_sel_wadr[cidx] = i_wadr[(tidx+1)*XLEN-1-:XLEN];
                    r_we[cidx] = 1'b1;
                end
                
                if (i_we[tidx] && (i_wadr[(tidx+1)*XLEN-1-:XLEN] == r_sel_wadr[cidx])) begin
                    case (i_funct3[(tidx+1)*3-2-:2])
                        2'b00: begin // byte
                            r1_wdata[cidx][(tidx+1)*XLEN-1-:XLEN] = {{8{i_wadr[tidx*XLEN+2-1-:2] == 2'b11}} & i_wdata[tidx*XLEN+8-1 -: 8],
                                                                    {8{i_wadr[tidx*XLEN+2-1-:2] == 2'b10}} & i_wdata[tidx*XLEN+8-1 -: 8],
                                                                    {8{i_wadr[tidx*XLEN+2-1-:2] == 2'b01}} & i_wdata[tidx*XLEN+8-1 -: 8],
                                                                    {8{i_wadr[tidx*XLEN+2-1-:2] == 2'b00}} & i_wdata[tidx*XLEN+8-1 -: 8]};
                            r1_ben[cidx][(tidx+1)*4-1-:4] = {i_wadr[tidx*XLEN+2-1-:2] == 2'b11, 
                                                            i_wadr[tidx*XLEN+2-1-:2] == 2'b10,
                                                            i_wadr[tidx*XLEN+2-1-:2] == 2'b01,
                                                            i_wadr[tidx*XLEN+2-1-:2] == 2'b00}; 
                        end
                        2'b01: begin // half-word
                            r1_wdata[cidx][(tidx+1)*XLEN-1-:XLEN] = {{16{i_wadr[tidx*XLEN+2-1]}}  & i_wdata[tidx*XLEN+16-1 -: 16],
                                                                    {16{!i_wadr[tidx*XLEN+2-1]}} & i_wdata[tidx*XLEN+16-1 -: 16]};
                            r1_ben[cidx][(tidx+1)*4-1-:4] = { i_wadr[tidx*XLEN+2-1], 
                                                             i_wadr[tidx*XLEN+2-1],
                                                            !i_wadr[tidx*XLEN+2-1],
                                                            !i_wadr[tidx*XLEN+2-1]}; 
                        end
                        default: begin
                            r1_wdata[cidx][(tidx+1)*XLEN-1-:XLEN] = i_wdata[(tidx+1)*XLEN-1-:XLEN];
                            r1_ben[cidx][(tidx+1)*4-1-:4] = 4'b1111;
                        end
                    endcase
                end
                else begin
                    r1_wdata[cidx][(tidx+1)*XLEN-1-:XLEN] = 32'd0;
                    r1_ben[cidx][(tidx+1)*4-1-:4] = 4'b0000;
                end
                
                r_wdata[cidx]   = r_wdata[cidx] | r1_wdata[cidx][(tidx+1)*XLEN-1-:XLEN];
                r_ben[cidx]     = r_ben[cidx] | r1_ben[cidx][(tidx+1)*4-1-:4];
                
                if (i_re[tidx] && (i_radr[tidx*XLEN+LOG2_DEPTH+LOG2_CHANNEL-1-:LOG2_CHANNEL] == cidx[LOG2_CHANNEL-1:0])) begin
                    r_sel_radr[cidx] = i_radr[(tidx+1)*XLEN-1-:XLEN];
                    r_re[cidx] = 1'b1;
                end                
            end
        end
    end
    
    integer cidx_0;
    always @(posedge i_clk) begin
        for (cidx_0 = 0; cidx_0 < CHANNEL; cidx_0 = cidx_0 + 1) begin
            o_mem_wadr[(cidx_0+1)*XLEN-1-:XLEN] <= r_sel_wadr[cidx_0];
            o_mem_we[cidx_0]                    <= r_we[cidx_0];
            o_mem_ben[cidx_0]                   <= r_ben[cidx_0];
            o_mem_wdata                         <= r_wdata[cidx_0];
            
            o_mem_radr[(cidx_0+1)*XLEN-1-:XLEN] <= r_sel_radr[cidx_0];
            o_mem_re[cidx_0]                    <= r_re[cidx_0];
        end
    end
    
endmodule
