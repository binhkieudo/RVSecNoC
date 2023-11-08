`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2023 12:02:35 PM
// Design Name: 
// Module Name: rv32_lsu
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


module rv32_lsu #(
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
        // CPU request
        input  wire [THREAD_COUNT*XLEN-1:0]  i_wadr,
        input  wire [THREAD_COUNT-1:0]       i_we,
        input  wire [THREAD_COUNT*XLEN-1:0]  i_wdata,
        output wire [THREAD_COUNT-1:0]       o_wack,
        input  wire [THREAD_COUNT*XLEN-1:0]  i_radr,
        input  wire [THREAD_COUNT-1:0]       i_re,
        output wire [THREAD_COUNT*XLEN-1:0]  o_rdata,
        output wire [THREAD_COUNT-1:0]       o_rack,
        // Memory interface
        output wire [CHANNEL*XLEN-1:0]       o_mem_wadr,
        output wire [CHANNEL-1:0]            o_mem_we,
        output wire [CHANNEL*4-1:0]          o_mem_ben,
        output wire [CHANNEL*XLEN-1:0]       o_mem_wdata,
        input  wire [CHANNEL-1:0]            i_mem_wack,
        output wire [CHANNEL*XLEN-1:0]       o_mem_radr,
        output wire [CHANNEL-1:0]            o_mem_re,
        input  wire [CHANNEL*XLEN-1:0]       i_mem_rdata,
        input  wire [CHANNEL-1:0]            i_mem_rack
    );
    
//==============================================================
// Channel controller
//==============================================================    
    genvar channel_idx;
    generate 
        for (channel_idx = 0; channel_idx < CHANNEL; channel_idx = channel_idx + 1) begin: channel
            reg [XLEN-1:0]       r_sel_wadr;
            reg [XLEN-1:0]       r_sel_radr;
            reg [XLEN-1:0]       r_wdata;
            reg                  r_we;
            reg                  r_re;
            reg [3:0]            r_ben;
            
            integer i;
            always @(*) begin
                r_sel_radr = i_radr[XLEN-1:0];
                r_sel_wadr = i_wadr[XLEN-1:0];
                r_wdata   = i_wdata[XLEN-1:0];
                r_we      = 1'b0;
                r_re      = 1'b0;
                r_ben     = 4'b0000;
                
                for (i = THREAD_COUNT-1; i >= 0; i = i - 1)
                    if ((i_we[i] || i_re[i]) && (i_wadr[i*XLEN+LOG2_DEPTH+LOG2_CHANNEL-1-:LOG2_CHANNEL] == channel_idx[LOG2_CHANNEL-1:0])) begin
                        case (i_funct3[(i+1)*3-2 -: 2])
                            2'b00: begin // byte
                                r_wdata   = {4{i_wdata[i*XLEN+8-1 -: 8]}};
                                r_ben     = {i_wadr[i*XLEN+2-1-:2] == 2'b11, 
                                             i_wadr[i*XLEN+2-1-:2] == 2'b10,
                                             i_wadr[i*XLEN+2-1-:2] == 2'b01,
                                             i_wadr[i*XLEN+2-1-:2] == 2'b00};
                            end
                            2'b01: begin // half-word
                                r_wdata   = {2{i_wdata[i*XLEN+16-1 -: 16]}};
                                r_ben     = { i_wadr[i*XLEN+2-1], 
                                              i_wadr[i*XLEN+2-1],
                                             !i_wadr[i*XLEN+2-1],
                                             !i_wadr[i*XLEN+2-1]};                            
                            end
                            default: begin // word
                                r_wdata   = i_wdata[(i+1)*XLEN-1 -: XLEN];
                                r_ben     = 4'b1111;
                            end
                        endcase
                        r_sel_wadr = i_wadr[(i+1)*XLEN-1-:XLEN];
                        r_sel_radr = i_radr[(i+1)*XLEN-1-:XLEN];
                        r_we       = i_we[i]; 
                        r_re       = i_re[i];
                    end
            end
               
            assign o_mem_radr[(channel_idx+1)*XLEN-1-:XLEN] = r_sel_radr;
            assign o_mem_wadr[(channel_idx+1)*XLEN-1-:XLEN] = r_sel_wadr;
            assign o_mem_wdata[(channel_idx+1)*XLEN-1-:XLEN] = r_wdata;
            assign o_mem_we[channel_idx] = r_we;
            assign o_mem_re[channel_idx] = r_re;
            assign o_mem_ben[(channel_idx+1)*4-1-:4] = r_ben;
        end
    endgenerate

//==============================================================
// Thread controller
//==============================================================
    genvar thread_idx;
    generate
        for (thread_idx = 0; thread_idx < THREAD_COUNT; thread_idx = thread_idx + 1) begin: thread
            wire [XLEN-1:0]         req_radr;
            wire [LOG2_CHANNEL-1:0] req_rchannel;
            wire [XLEN-1:0]         req_wadr;
            wire [LOG2_CHANNEL-1:0] req_wchannel;
               
            wire [2:0]      funct3;
            
            reg             r_rdreq_pend; // read request pending
            reg             r_wrreq_pend; // read request pending
            
            wire [XLEN-1:0] resp_data;
            wire            r_rdresp_ack;
            wire            r_wrresp_ack;
            reg  [XLEN-1:0] r_resp_data;
              
            wire            sign_bit;
            wire            sign_extend;
            
            assign req_radr     = i_radr[(thread_idx+1)*XLEN-1 -: XLEN];
            assign req_rchannel = i_radr[thread_idx*XLEN+LOG2_DEPTH+LOG2_CHANNEL-1 -: LOG2_CHANNEL];
            assign req_wadr     = i_wadr[(thread_idx+1)*XLEN-1 -: XLEN];
            assign req_wchannel = i_wadr[thread_idx*XLEN+LOG2_DEPTH+LOG2_CHANNEL-1 -: LOG2_CHANNEL];            
           
            assign funct3      = i_funct3[(thread_idx+1)*3-1 -: 3];
            assign resp_data   = i_mem_rdata[(req_rchannel+1)*XLEN-1-:XLEN];
            
            assign sign_bit    = (req_radr[1:0] == 2'b00)? (funct3[0]? resp_data[15]: resp_data[7]):
                                 (req_radr[1:0] == 2'b01)? resp_data[15]:
                                 (req_radr[1:0] == 2'b10)? (funct3[0]? resp_data[31]: resp_data[23]):
                                                           resp_data[31];
            assign sign_extend = !funct3[2] && sign_bit;
            
            assign r_rdresp_ack = i_mem_rack[req_rchannel] && r_rdreq_pend;
            assign r_wrresp_ack = i_mem_wack[req_wchannel] && r_wrreq_pend;
            
            always @(posedge i_clk) begin // pending state
                if (!i_rstn) r_rdreq_pend <= 1'b0;
                else if (i_re[thread_idx] && o_mem_re[req_rchannel] && (o_mem_radr == req_radr)) 
                    r_rdreq_pend <= 1'b1;
                else r_rdreq_pend <= 1'b0;
                    
                if (!i_rstn) r_wrreq_pend <= 1'b0;
                else if (i_we[thread_idx] && o_mem_we[req_wchannel] && (o_mem_wadr == req_wadr))
                    r_wrreq_pend <= 1'b1;
                else r_wrreq_pend <= 1'b0;    
            end
            
            always @(*) begin // sign extend
                case (funct3[1:0])
                    2'b00: begin // byte
                        r_resp_data[7:0] = (req_radr[1:0] == 2'b00)? resp_data[7:0]:
                                           (req_radr[1:0] == 2'b01)? resp_data[15:8]:
                                           (req_radr[1:0] == 2'b10)? resp_data[23:16]:
                                                                    resp_data[31:24];
                        r_resp_data[31:8] = {24{sign_extend}};
                    end
                    2'b01: begin // half-word
                        r_resp_data[15:0] = req_radr[1]? resp_data[31:16]: resp_data[15:0];
                        r_resp_data[31:16] = {16{sign_extend}}; 
                    end
                    default: // word
                        r_resp_data = resp_data;
                endcase
            end
            
            assign o_rdata[(thread_idx+1)*XLEN-1-:XLEN] = r_resp_data;
            assign o_rack[thread_idx] = r_rdresp_ack;
            assign o_wack[thread_idx] = r_wrresp_ack;
        end
    endgenerate
    
endmodule
