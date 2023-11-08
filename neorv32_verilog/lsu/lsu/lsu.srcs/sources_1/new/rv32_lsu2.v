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
    output reg  [THREAD_COUNT-1:0]       o_wack,
    // CPU request -- Write
    input  wire [THREAD_COUNT*XLEN-1:0]  i_radr,
    input  wire [THREAD_COUNT-1:0]       i_re,
    output reg  [THREAD_COUNT*XLEN-1:0]  o_rdata,
    output reg  [THREAD_COUNT-1:0]       o_rack,
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
    reg [XLEN-1:0]          r_sel_wadr  [0:CHANNEL-1];
    reg [THREAD_COUNT-1:0]  r_we        [0:CHANNEL-1];
    reg [XLEN-1:0]          r_wdata     [0:CHANNEL-1];
    reg [3:0]               r_ben       [0:CHANNEL-1];
    reg [XLEN-1:0]          r_sel_radr  [0:CHANNEL-1];
    reg [THREAD_COUNT-1:0]  r_re        [0:CHANNEL-1];

    reg [THREAD_COUNT*XLEN-1:0] r1_wdata     [0:CHANNEL-1];
    reg [THREAD_COUNT*4-1:0]    r1_ben       [0:CHANNEL-1];
    // Remap
    reg [XLEN*THREAD_COUNT-1:0] r2_wdata     [0:CHANNEL-1];
    reg [4*THREAD_COUNT-1:0]    r2_ben       [0:CHANNEL-1];
            
    integer cidx, tidx;
    integer cnt32, cnt32_t, cnt4, cnt4_t;
    always @(*) begin
        // Channel   
        for (cidx = 0; cidx < CHANNEL; cidx = cidx + 1) begin
            for (tidx = 0; tidx < THREAD_COUNT; tidx = tidx + 1) begin
                // Write control signals
                if (i_we[tidx] && (i_wadr[tidx*XLEN+LOG2_DEPTH+LOG2_CHANNEL-1-:LOG2_CHANNEL] == cidx[LOG2_CHANNEL-1:0]))
                    r_we[cidx][tidx] = 1'b1;
                else r_we[cidx][tidx] = 1'b0;
                
                r_sel_wadr[cidx] = i_wadr[XLEN-1:0];
                if (r_we[cidx][tidx]) r_sel_wadr[cidx] = i_wadr[(tidx+1)*XLEN-1-:XLEN];
                
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
                
//                r_wdata[cidx]   = r_wdata[cidx] | r1_wdata[cidx][(tidx+1)*XLEN-1-:XLEN];
//                r_ben[cidx]     = r_ben[cidx] | r1_ben[cidx][(tidx+1)*4-1-:4];
                
                for (cnt32 = 0; cnt32 < XLEN; cnt32 = cnt32 + 1) begin
                    for (cnt32_t = 0; cnt32_t < THREAD_COUNT; cnt32_t = cnt32_t + 1)
                        r2_wdata[cidx][cnt32*THREAD_COUNT+cnt32_t] = r1_wdata[cidx][cnt32_t*XLEN+cnt32];
                    r_wdata[cidx][cnt32] = |r2_wdata[cidx][(cnt32+1)*THREAD_COUNT-1-:THREAD_COUNT];
                        
                end
                        
                for (cnt4 = 0; cnt4 < 4; cnt4 = cnt4 + 1) begin
                    for (cnt4_t = 0; cnt4_t < THREAD_COUNT; cnt4_t = cnt4_t + 1)
                        r2_ben[cidx][cnt4*THREAD_COUNT+cnt4_t] = r1_wdata[cidx][cnt4_t*XLEN+cnt4];
                    r_ben[cidx][cnt4] = |r2_ben[cidx][(cnt4+1)*THREAD_COUNT-1-:THREAD_COUNT]; 
                end
                
                // Read control signals            
                if (i_re[tidx] && (i_radr[tidx*XLEN+LOG2_DEPTH+LOG2_CHANNEL-1-:LOG2_CHANNEL] == cidx[LOG2_CHANNEL-1:0]))
                    r_re[cidx][tidx] = 1'b1;
                else r_re[cidx][tidx] = 1'b0;
                
                r_sel_radr[cidx] = i_radr[XLEN-1:0];
                if (r_re[cidx][tidx]) r_sel_radr[cidx] = i_radr[(tidx+1)*XLEN-1-:XLEN];
                                               
            end // end for tidx
        end // end for cidx           
    end
    
    integer cidx_0;
    always @(posedge i_clk) begin
        for (cidx_0 = 0; cidx_0 < CHANNEL; cidx_0 = cidx_0 + 1) begin
            o_mem_wadr[(cidx_0+1)*XLEN-1-:XLEN]  <= r_sel_wadr[cidx_0];
            o_mem_we[cidx_0]                     <= |r_we[cidx_0];
            o_mem_ben[(cidx_0+1)*4-1-:4]         <= r_ben[cidx_0];
            o_mem_wdata[(cidx_0+1)*XLEN-1-:XLEN] <= r_wdata[cidx_0];
            
            o_mem_radr[(cidx_0+1)*XLEN-1-:XLEN]  <= r_sel_radr[cidx_0];
            o_mem_re[cidx_0]                     <= |r_re[cidx_0];
        end
    end
    
//==============================================================
// Thread controller
//==============================================================
    reg [LOG2_CHANNEL-1:0]  req_rchannel [THREAD_COUNT-1:0];
    reg [LOG2_CHANNEL-1:0]  req_wchannel [THREAD_COUNT-1:0];
    reg [XLEN-1:0]          req_radr     [THREAD_COUNT-1:0];
    reg [XLEN-1:0]          req_wadr     [THREAD_COUNT-1:0];
    reg                     r_re0        [THREAD_COUNT-1:0];
    reg                     r_we0        [THREAD_COUNT-1:0];
    reg [2:0]               funct3       [THREAD_COUNT-1:0];
    reg                     r_rdreq_pend [THREAD_COUNT-1:0]; // read request pending
    reg                     r_wrreq_pend [THREAD_COUNT-1:0]; // read request pending
    reg  [XLEN-1:0]         r_resp_data  [THREAD_COUNT-1:0];
    reg                     r_rdresp_ack [THREAD_COUNT-1:0];
    reg                     r_wrresp_ack [THREAD_COUNT-1:0];
    
    reg             radr_eq      [THREAD_COUNT-1:0]; 
    reg             wadr_eq      [THREAD_COUNT-1:0];       
    reg  [XLEN-1:0] resp_data    [THREAD_COUNT-1:0];
    reg             sign_bit     [THREAD_COUNT-1:0];
    reg             sign_extend  [THREAD_COUNT-1:0];
    reg  [XLEN-1:0] ro_resp_data [THREAD_COUNT-1:0];  
    
    integer tidx_0;
    always @(posedge i_clk) begin
        for (tidx_0 = 0; tidx_0 < THREAD_COUNT; tidx_0 = tidx_0 + 1) begin
            if (!i_rstn) begin
                req_rchannel[tidx_0] <= {LOG2_CHANNEL{1'b0}};
                req_wchannel[tidx_0] <= {LOG2_CHANNEL{1'b0}};
            end
            else begin
                req_rchannel[tidx_0] <= i_radr[tidx_0*XLEN+LOG2_DEPTH+LOG2_CHANNEL-1-:LOG2_CHANNEL];
                req_wchannel[tidx_0] <= i_wadr[tidx_0*XLEN+LOG2_DEPTH+LOG2_CHANNEL-1-:LOG2_CHANNEL];
            end
            
            req_radr[tidx_0]  <= i_radr[(tidx_0+1)*32-1 -: 32];
            req_wadr[tidx_0]  <= i_wadr[(tidx_0+1)*32-1 -: 32];
            
            r_re0[tidx_0] <= i_re[tidx_0];
            r_we0[tidx_0] <= i_we[tidx_0];
            
            funct3[tidx_0]    <= i_funct3[(tidx_0+1)*3-1 -: 3];
            
            if (!i_rstn) begin
                r_rdreq_pend[tidx_0] <= 1'b0;
                r_wrreq_pend[tidx_0] <= 1'b0;
            end
            else begin
                r_rdreq_pend[tidx_0] <= r_re0[tidx_0] && o_mem_re[req_rchannel[tidx_0]] && radr_eq[tidx_0];
                r_wrreq_pend[tidx_0] <= r_we0[tidx_0] && o_mem_we[req_wchannel[tidx_0]] && wadr_eq[tidx_0];  
            end
            
            r_resp_data[tidx_0] <= i_mem_rdata[(req_rchannel[tidx_0]+1)*XLEN-1-:XLEN];
            r_rdresp_ack[tidx_0] <= i_mem_rack[req_rchannel[tidx_0]] && r_rdreq_pend[tidx_0];
            r_wrresp_ack[tidx_0] <= i_mem_wack[req_wchannel[tidx_0]] && r_wrreq_pend[tidx_0];        
        end
    end
    
    integer tidx_1;
    always @(*) begin
        for (tidx_1 = 0; tidx_1 < THREAD_COUNT; tidx_1 = tidx_1 + 1) begin
            radr_eq[tidx_1] = o_mem_radr[(req_rchannel[tidx_1]+1)*XLEN-1-:XLEN]==req_radr[tidx_1];
            wadr_eq[tidx_1] = o_mem_wadr[(req_rchannel[tidx_1]+1)*XLEN-1-:XLEN]==req_wadr[tidx_1];
        
            resp_data[tidx_1] = i_mem_rdata[(req_rchannel[tidx_1]+1)*XLEN-1-:XLEN];

            
            sign_bit[tidx_1] = (req_radr[tidx_1][1:0] == 2'b00)? (funct3[tidx_1][0]? resp_data[tidx_1][15]: resp_data[tidx_1][7]):
                               (req_radr[tidx_1][1:0] == 2'b01)? resp_data[tidx_1][15]:
                               (req_radr[tidx_1][1:0] == 2'b10)? (funct3[tidx_1][0]? resp_data[tidx_1][31]: resp_data[tidx_1][23]):
                                                                 resp_data[tidx_1][31];
            sign_extend[tidx_1] = !funct3[tidx_1][2] && sign_bit[tidx_1];
            
            case (funct3[tidx_1][1:0])
                2'b00: begin // byte
                    ro_resp_data[tidx_1][7:0] = (req_radr[tidx_1][1:0] == 2'b00)? r_resp_data[tidx_1][7:0]:
                                                (req_radr[tidx_1][1:0] == 2'b01)? r_resp_data[tidx_1][15:8]:
                                                (req_radr[tidx_1][1:0] == 2'b10)? r_resp_data[tidx_1][23:16]:
                                                                          r_resp_data[tidx_1][31:24];
                    ro_resp_data[tidx_1][31:8] = {24{sign_extend[tidx_1]}};
                end
                2'b01: begin // half-word
                    ro_resp_data[tidx_1][15:0] = req_radr[tidx_1][1]? r_resp_data[tidx_1][31:16]: r_resp_data[tidx_1][15:0];
                    ro_resp_data[tidx_1][31:16] = {16{sign_extend[tidx_1]}}; 
                end
                default: // word
                    ro_resp_data[tidx_1] = r_resp_data[tidx_1];
            endcase
            
            o_rdata[(tidx_1+1)*XLEN-1-:XLEN] = ro_resp_data[tidx_1];
            o_rack[tidx_1] = r_rdresp_ack[tidx_1];
            o_wack[tidx_1] = r_wrresp_ack[tidx_1];                                                       
        end
    end
    
endmodule
