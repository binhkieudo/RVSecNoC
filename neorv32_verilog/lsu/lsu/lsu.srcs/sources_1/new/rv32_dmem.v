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
    parameter BANK_DEPTH   = 1024,
    parameter LOG2_DEPTH   = 10                 
)
(
    // Global control
    input  wire i_clk,
    // Write interface
    input  wire [LOG2_DEPTH-1:0]   i_mem_wadr,
    input  wire                    i_mem_we,
    input  wire [3:0]              i_mem_ben,
    input  wire [XLEN-1:0]         i_mem_wdata,
    // Read interface
    input  wire [LOG2_DEPTH-1:0]   i_mem_radr,
    output wire [XLEN-1:0]         o_mem_rdata   
);
            
    reg [7:0] bank_0 [BANK_DEPTH-1:0];
    reg [7:0] bank_1 [BANK_DEPTH-1:0];
    reg [7:0] bank_2 [BANK_DEPTH-1:0];
    reg [7:0] bank_3 [BANK_DEPTH-1:0];
    
    reg [7:0] ro_mem_rdata [0:3];
                       
    always @(posedge i_clk) begin
        if (i_mem_we && i_mem_ben[0]) bank_0[i_mem_wadr] <= i_mem_wdata[7:0];
        if (i_mem_we && i_mem_ben[1]) bank_1[i_mem_wadr] <= i_mem_wdata[15:8];
        if (i_mem_we && i_mem_ben[2]) bank_2[i_mem_wadr] <= i_mem_wdata[23:16];
        if (i_mem_we && i_mem_ben[3]) bank_3[i_mem_wadr] <= i_mem_wdata[31:24];
    end
            
    always @(posedge i_clk) begin                
        ro_mem_rdata[0] <= bank_0[i_mem_radr];
        ro_mem_rdata[1] <= bank_1[i_mem_radr];
        ro_mem_rdata[2] <= bank_2[i_mem_radr];
        ro_mem_rdata[3] <= bank_3[i_mem_radr];
    end
                        
    assign o_mem_rdata[XLEN-1-:XLEN] = {ro_mem_rdata[3], ro_mem_rdata[2], ro_mem_rdata[1], ro_mem_rdata[0]};

endmodule
