`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2023 11:51:55 AM
// Design Name: 
// Module Name: rv32_dcache
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


module rv32_dcache#(
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

    localparam ADR_WIDTH = LOG2_DEPTH - 2;
    localparam TAG_WIDTH = XLEN - LOG2_DEPTH;
    
    reg [CHANNEL-1:0]      ro_mem_wack;
    reg [CHANNEL-1:0]      ro_mem_rack;
    
    reg [ADR_WIDTH-1:0] mem_waddr [CHANNEL-1:0];
    reg [TAG_WIDTH-1:0] mem_wtag  [CHANNEL-1:0];
    reg                 mem_we    [CHANNEL-1:0];
    reg [3:0]           mem_ben   [CHANNEL-1:0];
    reg [XLEN-1:0]      mem_wdata [CHANNEL-1:0];
    reg [ADR_WIDTH-1:0] mem_raddr [CHANNEL-1:0];
    reg [TAG_WIDTH-1:0] mem_rtag  [CHANNEL-1:0];
    reg                 mem_re    [CHANNEL-1:0];
    
    wire [XLEN-1:0]     mem_rdata [CHANNEL-1:0]; 

    reg [CHANNEL*ADR_WIDTH-1:0] rmem_waddr;
    reg [CHANNEL*ADR_WIDTH-1:0] rmem_raddr;
    
    rv32_dmem #(
        .XLEN         (XLEN         ),
        .BANK_DEPTH   (BANK_DEPTH/4 ),
        .LOG2_DEPTH   (ADR_WIDTH    )
    )
    dmem_inst [CHANNEL-1:0] (
        .i_clk       (i_clk       ),
        // Write interface
        .i_mem_wadr  (rmem_waddr  ),
        .i_mem_we    (i_mem_we    ),
        .i_mem_ben   (i_mem_ben   ),
        .i_mem_wdata (i_mem_wdata ),
        // Read interface
        .i_mem_radr  (rmem_raddr  ),
        .o_mem_rdata (o_mem_rdata )
    );
       
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            ro_mem_wack <= {CHANNEL{1'b0}};
            ro_mem_rack <= {CHANNEL{1'b0}};
        end
        else begin
            ro_mem_wack <= i_mem_we;
            ro_mem_rack <= i_mem_re;
        end
    end
   
    integer cidx;
    always @(*) begin
        for (cidx = 0; cidx < CHANNEL; cidx = cidx + 1) begin
            mem_waddr[cidx] = i_mem_wadr[cidx*XLEN+LOG2_DEPTH-1-:ADR_WIDTH];       
            mem_wtag[cidx]  = i_mem_wadr[(cidx+1)*XLEN-1-:TAG_WIDTH];
            mem_we[cidx]    = i_mem_we[cidx];
            mem_ben[cidx]   = i_mem_ben[(cidx+1)*4-1-:4];
            mem_wdata[cidx] = i_mem_wdata[(cidx+1)*XLEN-1-:XLEN];
            mem_raddr[cidx] = i_mem_radr[cidx*XLEN+LOG2_DEPTH-1-:ADR_WIDTH];
            mem_rtag[cidx]  = i_mem_radr[(cidx+1)*XLEN-1-:TAG_WIDTH];
            mem_re[cidx]    = i_mem_re[cidx];
            
            rmem_waddr[(cidx+1)*ADR_WIDTH-1-:ADR_WIDTH] = mem_waddr[cidx];
            rmem_raddr[(cidx+1)*ADR_WIDTH-1-:ADR_WIDTH] = mem_raddr[cidx];
        end
    end
    
    assign o_mem_wack  = ro_mem_wack;
    assign o_mem_rack  = ro_mem_rack;

endmodule
