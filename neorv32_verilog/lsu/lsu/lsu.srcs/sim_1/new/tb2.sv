`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2023 03:51:37 PM
// Design Name: 
// Module Name: tb2
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


module tb2(

    );
    parameter XLEN         = 32;
    parameter THREAD_COUNT = 8;
    parameter CHANNEL      = 4;
    parameter LOG2_CHANNEL = 2;
    parameter BANK_DEPTH   = 1024;
    parameter LOG2_DEPTH   = 10;
    
    // Global control
    reg i_clk = 1'b1;
    reg i_rstn = 1'b0;
    
    // CPU interface
    reg [2:0]       i_funct3_7 = 3'b111;
    reg [XLEN-1:0]  i_adr7 = {19'd0, 3'b111, 10'd18};
    reg [XLEN-1:0]  i_wdata_7 = 32'd28;
    reg             i_we_7 = 1'b1;
    reg             i_re_7 = 1'b0;
    wire [XLEN-1:0] o_rdata_7;
    wire            o_ack_7;
    
    reg [2:0]       i_funct3_6 = 3'b111;
    reg [XLEN-1:0]  i_adr6 = {19'd0, 3'b111, 10'd17};
    reg [XLEN-1:0]  i_wdata_6 = 32'd27;
    reg             i_we_6 = 1'b1;
    reg             i_re_6 = 1'b0;
    wire [XLEN-1:0] o_rdata_6;
    wire            o_ack_6;
    
    reg [2:0]       i_funct3_5 = 3'b111;
    reg [XLEN-1:0]  i_adr5 = {19'd0, 3'b111, 10'd16};
    reg [XLEN-1:0]  i_wdata_5 = 32'd26;
    reg             i_we_5 = 1'b1;
    reg             i_re_5 = 1'b0;
    wire [XLEN-1:0] o_rdata_5;
    wire            o_ack_5;
    
    reg [2:0]       i_funct3_4 = 3'b111;
    reg [XLEN-1:0]  i_adr4 = {19'd0, 3'b111, 10'd15};
    reg [XLEN-1:0]  i_wdata_4 = 32'd25;
    reg             i_we_4 = 1'b1;
    reg             i_re_4 = 1'b0;
    wire [XLEN-1:0] o_rdata_4;
    wire            o_ack_4;
    
    reg [2:0]       i_funct3_3 = 3'b111;
    reg [XLEN-1:0]  i_adr3 = {19'd0, 3'b111, 10'd14};
    reg [XLEN-1:0]  i_wdata_3 = 32'd24;
    reg             i_we_3 = 1'b1;
    reg             i_re_3 = 1'b0;
    wire [XLEN-1:0] o_rdata_3;
    wire            o_ack_3;
    
    reg [2:0]       i_funct3_2 = 3'b111;
    reg [XLEN-1:0]  i_adr2 = {19'd0, 3'b111, 10'd13};
    reg [XLEN-1:0]  i_wdata_2 = 32'd23;
    reg             i_we_2 = 1'b1;
    reg             i_re_2 = 1'b0;
    wire [XLEN-1:0] o_rdata_2;
    wire            o_ack_2;
    
    reg [2:0]       i_funct3_1 = 3'b111;
    reg [XLEN-1:0]  i_adr1 = {19'd0, 3'b111, 10'd12};
    reg [XLEN-1:0]  i_wdata_1 = 32'd22;
    reg             i_we_1 = 1'b1;
    reg             i_re_1 = 1'b0;
    wire [XLEN-1:0] o_rdata_1;
    wire            o_ack_1;
    
    reg [2:0]       i_funct3_0 = 3'b111;
    reg [XLEN-1:0]  i_adr0 = {19'd0, 3'b111, 10'd11};
    reg [XLEN-1:0]  i_wdata_0 = 32'd21;
    reg             i_we_0 = 1'b1;
    reg             i_re_0 = 1'b0;
    wire [XLEN-1:0] o_rdata_0;
    wire            o_ack_0;
    
    // Memory interface
    wire [LOG2_DEPTH-1:0] o_mem_adr_3;
    wire [XLEN-1:0]       o_mem_wdata_3;
    wire                  o_mem_we_3;
    wire                  o_mem_re_3;
    wire [3:0]            o_mem_ben_3;
    reg  [XLEN-1:0]       i_mem_rdata_3 = 32'd104;
    reg                   i_mem_ack_3 = 1'b0;
    
    wire [LOG2_DEPTH-1:0] o_mem_adr_2;
    wire [XLEN-1:0]       o_mem_wdata_2;
    wire                  o_mem_we_2;
    wire                  o_mem_re_2;
    wire [3:0]            o_mem_ben_2;
    reg  [XLEN-1:0]       i_mem_rdata_2 = 32'd103;
    reg                   i_mem_ack_2 = 1'b0;
    
    wire [LOG2_DEPTH-1:0] o_mem_adr_1;
    wire [XLEN-1:0]       o_mem_wdata_1;
    wire                  o_mem_we_1;
    wire                  o_mem_re_1;
    wire [3:0]            o_mem_ben_1;
    reg  [XLEN-1:0]       i_mem_rdata_1 = 32'd102;
    reg                   i_mem_ack_1 = 1'b0;
    
    wire [LOG2_DEPTH-1:0] o_mem_adr_0;
    wire [XLEN-1:0]       o_mem_wdata_0;
    wire                  o_mem_we_0;
    wire                  o_mem_re_0;
    wire [3:0]            o_mem_ben_0;
    reg  [XLEN-1:0]       i_mem_rdata_0 = 32'd101;
    reg                   i_mem_ack_0 = 1'b1;
        
    rv32_lsu udt(
        i_clk,
        i_rstn,
        // Control signals
        {i_funct3_7, i_funct3_6, i_funct3_5, i_funct3_4, i_funct3_3, i_funct3_2, i_funct3_1, i_funct3_0},
        // CPU request
        {i_adr7, i_adr6, i_adr5, i_adr4, i_adr3, i_adr2, i_adr1, i_adr0},
        {i_wdata_7, i_wdata_6, i_wdata_5, i_wdata_4, i_wdata_3, i_wdata_2, i_wdata_1, i_wdata_0},
        {i_we_7, i_we_6, i_we_5, i_we_4, i_we_3, i_we_2, i_we_1, i_we_0},
        {i_re_7, i_re_6, i_re_5, i_re_4, i_re_3, i_re_2, i_re_1, i_re_0},
        {o_rdata_7, o_rdata_6, o_rdata_5, o_rdata_4, o_rdata_3, o_rdata_2, o_rdata_1, o_rdata_0},
        {o_ack_7, o_ack_6, o_ack_5, o_ack_4, o_ack_3, o_ack_2, o_ack_1, o_ack_0},
        // Memory interface
        {o_mem_adr_3, o_mem_adr_2, o_mem_adr_1, o_mem_adr_0},
        {o_mem_wdata_3, o_mem_wdata_2, o_mem_wdata_1, o_mem_wdata_0},
        {o_mem_we_3, o_mem_we_2, o_mem_we_1, o_mem_we_0},
        {o_mem_re_3, o_mem_re_2, o_mem_re_1, o_mem_re_0},
        {o_mem_ben_3, o_mem_ben_2, o_mem_ben_1, o_mem_ben_0},
        {i_mem_rdata_3, i_mem_rdata_2, i_mem_rdata_1, i_mem_rdata_0},
        {i_mem_ack_3, i_mem_ack_2, i_mem_ack_1, i_mem_ack_0}
    );
    
    always #5 i_clk = ~i_clk;
    
    initial begin
        #9 i_rstn = 1'b1;
        
        //================================================================
        // Test case 0 (simple write request in single channel
        //================================================================
        #10;
        // CPU interface ==============================
        i_funct3_7  = 3'b111;
        i_adr7      = {19'd0, 3'b111, 10'd18};
        i_wdata_7   = 32'd28;
        i_we_7      = 1'b1;
        i_re_7      = 1'b0;
        //=============================================
        i_funct3_6  = 3'b111;
        i_adr6      = {19'd0, 3'b111, 10'd17};
        i_wdata_6   = 32'd27;
        i_we_6      = 1'b1;
        i_re_6      = 1'b0;
        //=============================================
        i_funct3_5  = 3'b111;
        i_adr5      = {19'd0, 3'b111, 10'd16};
        i_wdata_5   = 32'd26;
        i_we_5      = 1'b1;
        i_re_5      = 1'b0;
        //=============================================
        i_funct3_4  = 3'b111;
        i_adr4      = {19'd0, 3'b111, 10'd15};
        i_wdata_4   = 32'd25;
        i_we_4      = 1'b1;
        i_re_4      = 1'b0;
        //=============================================
        i_funct3_3  = 3'b111;
        i_adr3      = {19'd0, 3'b111, 10'd14};
        i_wdata_3   = 32'd24;
        i_we_3      = 1'b1;
        i_re_3      = 1'b0;
        //=============================================
        i_funct3_2  = 3'b111;
        i_adr2      = {19'd0, 3'b111, 10'd13};
        i_wdata_2   = 32'd23;
        i_we_2      = 1'b1;
        i_re_2      = 1'b0;
        //=============================================
        i_funct3_1  = 3'b111;
        i_adr1      = {19'd0, 3'b111, 10'd12};
        i_wdata_1   = 32'd22;
        i_we_1      = 1'b1;
        i_re_1      = 1'b0;
        //=============================================
        i_funct3_0  = 3'b111;
        i_adr0      = {19'd0, 3'b111, 10'd11};
        i_wdata_0   = 32'd21;
        i_we_0      = 1'b1;
        i_re_0      = 1'b0;
        // Memory interface ============================
        i_mem_rdata_3   = 32'd104;
        i_mem_ack_3     = 1'b0;
        i_mem_rdata_2   = 32'd103;
        i_mem_ack_2     = 1'b0;
        i_mem_rdata_1   = 32'd102;
        i_mem_ack_1     = 1'b0;
        i_mem_rdata_0   = 32'd101;
        i_mem_ack_0     = 1'b0;
        #10 i_we_0 = 0;
        #10 i_we_1 = 0;
        #10 i_we_2 = 0;
        #10 i_we_3 = 0;
        #10 i_we_4 = 0;
        #10 i_we_5 = 0;
        #10 i_we_6 = 0;     
        #10 i_we_7 = 0;
        
        //================================================================
        // Test case 1 (Write request in multiple channels
        //================================================================ 
        #30;
        i_funct3_7  = 3'b111;
        i_adr7      = {19'd0, 3'b011, 10'd18};
        i_wdata_7   = 32'd28;
        i_we_7      = 1'b1;
        i_re_7      = 1'b0;
        //=============================================
        i_funct3_6  = 3'b111;
        i_adr6      = {19'd0, 3'b010, 10'd17};
        i_wdata_6   = 32'd27;
        i_we_6      = 1'b1;
        i_re_6      = 1'b0;
        //=============================================
        i_funct3_5  = 3'b111;
        i_adr5      = {19'd0, 3'b001, 10'd16};
        i_wdata_5   = 32'd26;
        i_we_5      = 1'b1;
        i_re_5      = 1'b0;
        //=============================================
        i_funct3_4  = 3'b111;
        i_adr4      = {19'd0, 3'b000, 10'd15};
        i_wdata_4   = 32'd25;
        i_we_4      = 1'b1;
        i_re_4      = 1'b0;
        //=============================================
        i_funct3_3  = 3'b111;
        i_adr3      = {19'd0, 3'b011, 10'd14};
        i_wdata_3   = 32'd24;
        i_we_3      = 1'b1;
        i_re_3      = 1'b0;
        //=============================================
        i_funct3_2  = 3'b111;
        i_adr2      = {19'd0, 3'b010, 10'd13};
        i_wdata_2   = 32'd23;
        i_we_2      = 1'b1;
        i_re_2      = 1'b0;
        //=============================================
        i_funct3_1  = 3'b111;
        i_adr1      = {19'd0, 3'b001, 10'd12};
        i_wdata_1   = 32'd22;
        i_we_1      = 1'b1;
        i_re_1      = 1'b0;
        //=============================================
        i_funct3_0  = 3'b111;
        i_adr0      = {19'd0, 3'b000, 10'd11};
        i_wdata_0   = 32'd21;
        i_we_0      = 1'b1;
        i_re_0      = 1'b0;
        #10;
        i_we_0 = 1'b0;
        i_we_1 = 1'b0;
        i_we_2 = 1'b0;
        i_we_3 = 1'b0;
        #10;
        i_we_4 = 1'b0;
        i_we_5 = 1'b0;
        i_we_6 = 1'b0;
        i_we_7 = 1'b0;
        
        //================================================================
        // Test case 3 (simple read request in single channel
        //================================================================
        #30;
        // CPU interface ==============================
        i_funct3_7  = 3'b111;
        i_adr7      = {19'd0, 3'b111, 10'd18};
        i_wdata_7   = 32'd28;
        i_we_7      = 1'b0;
        i_re_7      = 1'b1;
        //=============================================
        i_funct3_6  = 3'b111;
        i_adr6      = {19'd0, 3'b111, 10'd17};
        i_wdata_6   = 32'd27;
        i_we_6      = 1'b0;
        i_re_6      = 1'b1;
        //=============================================
        i_funct3_5  = 3'b111;
        i_adr5      = {19'd0, 3'b111, 10'd16};
        i_wdata_5   = 32'd26;
        i_we_5      = 1'b0;
        i_re_5      = 1'b1;
        //=============================================
        i_funct3_4  = 3'b111;
        i_adr4      = {19'd0, 3'b111, 10'd15};
        i_wdata_4   = 32'd25;
        i_we_4      = 1'b0;
        i_re_4      = 1'b1;
        //=============================================
        i_funct3_3  = 3'b111;
        i_adr3      = {19'd0, 3'b111, 10'd14};
        i_wdata_3   = 32'd24;
        i_we_3      = 1'b0;
        i_re_3      = 1'b1;
        //=============================================
        i_funct3_2  = 3'b111;
        i_adr2      = {19'd0, 3'b111, 10'd13};
        i_wdata_2   = 32'd23;
        i_we_2      = 1'b0;
        i_re_2      = 1'b1;
        //=============================================
        i_funct3_1  = 3'b111;
        i_adr1      = {19'd0, 3'b111, 10'd12};
        i_wdata_1   = 32'd22;
        i_we_1      = 1'b0;
        i_re_1      = 1'b1;
        //=============================================
        i_funct3_0  = 3'b111;
        i_adr0      = {19'd0, 3'b111, 10'd11};
        i_wdata_0   = 32'd21;
        i_we_0      = 1'b0;
        i_re_0      = 1'b1;
        // Memory interface ============================
        i_mem_rdata_3   = 32'd104;
        i_mem_ack_3     = 1'b0;
        i_mem_rdata_2   = 32'd103;
        i_mem_ack_2     = 1'b0;
        i_mem_rdata_1   = 32'd102;
        i_mem_ack_1     = 1'b0;
        i_mem_rdata_0   = 32'd101;
        i_mem_ack_0     = 1'b1;
        #10;
        i_mem_ack_0     = 1'b0;
        i_re_7 = 1'b0;
        i_re_6 = 1'b0;
        i_re_5 = 1'b0;
        i_re_4 = 1'b0;
        i_re_3 = 1'b0;
        i_re_2 = 1'b0;
        i_re_1 = 1'b0;
        i_re_0 = 1'b0;
        
        #30;
        // CPU interface ==============================
        i_funct3_7  = 3'b111;
        i_adr7      = {19'd0, 3'b111, 10'd18};
        i_wdata_7   = 32'd28;
        i_we_7      = 1'b0;
        i_re_7      = 1'b1;
        //=============================================
        i_funct3_6  = 3'b111;
        i_adr6      = {19'd0, 3'b111, 10'd17};
        i_wdata_6   = 32'd27;
        i_we_6      = 1'b0;
        i_re_6      = 1'b1;
        //=============================================
        i_funct3_5  = 3'b111;
        i_adr5      = {19'd0, 3'b111, 10'd16};
        i_wdata_5   = 32'd26;
        i_we_5      = 1'b0;
        i_re_5      = 1'b1;
        //=============================================
        i_funct3_4  = 3'b111;
        i_adr4      = {19'd0, 3'b111, 10'd15};
        i_wdata_4   = 32'd25;
        i_we_4      = 1'b0;
        i_re_4      = 1'b1;
        //=============================================
        i_funct3_3  = 3'b111;
        i_adr3      = {19'd0, 3'b111, 10'd14};
        i_wdata_3   = 32'd24;
        i_we_3      = 1'b0;
        i_re_3      = 1'b1;
        //=============================================
        i_funct3_2  = 3'b111;
        i_adr2      = {19'd0, 3'b111, 10'd13};
        i_wdata_2   = 32'd23;
        i_we_2      = 1'b0;
        i_re_2      = 1'b1;
        //=============================================
        i_funct3_1  = 3'b111;
        i_adr1      = {19'd0, 3'b111, 10'd12};
        i_wdata_1   = 32'd22;
        i_we_1      = 1'b0;
        i_re_1      = 1'b1;
        //=============================================
        i_funct3_0  = 3'b111;
        i_adr0      = {19'd0, 3'b111, 10'd11};
        i_wdata_0   = 32'd21;
        i_we_0      = 1'b0;
        i_re_0      = 1'b1;
        // Memory interface ============================
        i_mem_rdata_3   = 32'd104;
        i_mem_ack_3     = 1'b1;
        i_mem_rdata_2   = 32'd103;
        i_mem_ack_2     = 1'b0;
        i_mem_rdata_1   = 32'd102;
        i_mem_ack_1     = 1'b0;
        i_mem_rdata_0   = 32'd101;
        i_mem_ack_0     = 1'b0;
        #10;
        i_mem_ack_3     = 1'b0;
        i_re_7 = 1'b0;
        i_re_6 = 1'b0;
        i_re_5 = 1'b0;
        i_re_4 = 1'b0;
        i_re_3 = 1'b0;
        i_re_2 = 1'b0;
        i_re_1 = 1'b0;
        i_re_0 = 1'b0;

        //================================================================
        // Test case 4 (multiple read requests in single channel
        //================================================================
        #30;
        // CPU interface ==============================
        i_funct3_7  = 3'b111;
        i_adr7      = {19'd0, 3'b111, 10'd18};
        i_wdata_7   = 32'd28;
        i_we_7      = 1'b0;
        i_re_7      = 1'b1;
        //=============================================
        i_funct3_6  = 3'b111;
        i_adr6      = {19'd0, 3'b111, 10'd17};
        i_wdata_6   = 32'd27;
        i_we_6      = 1'b0;
        i_re_6      = 1'b1;
        //=============================================
        i_funct3_5  = 3'b111;
        i_adr5      = {19'd0, 3'b111, 10'd16};
        i_wdata_5   = 32'd26;
        i_we_5      = 1'b0;
        i_re_5      = 1'b1;
        //=============================================
        i_funct3_4  = 3'b111;
        i_adr4      = {19'd0, 3'b111, 10'd15};
        i_wdata_4   = 32'd25;
        i_we_4      = 1'b0;
        i_re_4      = 1'b1;
        //=============================================
        i_funct3_3  = 3'b111;
        i_adr3      = {19'd0, 3'b111, 10'd14};
        i_wdata_3   = 32'd24;
        i_we_3      = 1'b0;
        i_re_3      = 1'b1;
        //=============================================
        i_funct3_2  = 3'b111;
        i_adr2      = {19'd0, 3'b111, 10'd13};
        i_wdata_2   = 32'd23;
        i_we_2      = 1'b0;
        i_re_2      = 1'b1;
        //=============================================
        i_funct3_1  = 3'b111;
        i_adr1      = {19'd0, 3'b111, 10'd12};
        i_wdata_1   = 32'd22;
        i_we_1      = 1'b0;
        i_re_1      = 1'b1;
        //=============================================
        i_funct3_0  = 3'b111;
        i_adr0      = {19'd0, 3'b111, 10'd11};
        i_wdata_0   = 32'd21;
        i_we_0      = 1'b0;
        i_re_0      = 1'b1;
        // Memory interface ============================
        i_mem_rdata_3   = 32'd104;
        i_mem_ack_3     = 1'b1;
        i_mem_rdata_2   = 32'd103;
        i_mem_ack_2     = 1'b0;
        i_mem_rdata_1   = 32'd102;
        i_mem_ack_1     = 1'b0;
        i_mem_rdata_0   = 32'd101;
        i_mem_ack_0     = 1'b0;
        #10;
        i_mem_ack_3     = 1'b0;
        i_re_0 = 1'b0;
        #10 i_mem_ack_3 = 1'b1;
        i_mem_rdata_3   = 32'd210;
        #10 i_mem_ack_3 = 1'b0;
        i_re_1 = 1'b0;
        #10 i_mem_ack_3 = 1'b1;
        i_mem_rdata_3   = 32'd211;
        #10 i_mem_ack_3 = 1'b0;
        i_re_2 = 1'b0;
        #10 i_mem_ack_3 = 1'b1;
        i_mem_rdata_3   = 32'd212;
        #10 i_mem_ack_3 = 1'b0;
        i_re_3 = 1'b0;                
        #10 i_mem_ack_3 = 1'b1;
        i_mem_rdata_3   = 32'd213;
        #10 i_mem_ack_3 = 1'b0;
        i_re_4 = 1'b0;        
        #10 i_mem_ack_3 = 1'b1;
        i_mem_rdata_3   = 32'd214;
        #10 i_mem_ack_3 = 1'b0;
        i_re_5 = 1'b0;
        #10 i_mem_ack_3 = 1'b1;
        i_mem_rdata_3   = 32'd215;
        #10 i_mem_ack_3 = 1'b0;
        i_re_6 = 1'b0;        
        #10 i_mem_ack_3 = 1'b1;
        i_mem_rdata_3   = 32'd216;
        #10 i_mem_ack_3 = 1'b0;
        i_re_7 = 1'b0;              
                        
        //================================================================
        // Test case 5 (simple read request same address in single channel
        //================================================================
        #30;
        // CPU interface ==============================
        i_funct3_7  = 3'b111;
        i_adr7      = {19'd0, 3'b010, 10'd11};
        i_wdata_7   = 32'd28;
        i_we_7      = 1'b0;
        i_re_7      = 1'b1;
        //=============================================
        i_funct3_6  = 3'b111;
        i_adr6      = {19'd0, 3'b010, 10'd11};
        i_wdata_6   = 32'd27;
        i_we_6      = 1'b0;
        i_re_6      = 1'b1;
        //=============================================
        i_funct3_5  = 3'b111;
        i_adr5      = {19'd0, 3'b010, 10'd11};
        i_wdata_5   = 32'd26;
        i_we_5      = 1'b0;
        i_re_5      = 1'b1;
        //=============================================
        i_funct3_4  = 3'b111;
        i_adr4      = {19'd0, 3'b010, 10'd11};
        i_wdata_4   = 32'd25;
        i_we_4      = 1'b0;
        i_re_4      = 1'b1;
        //=============================================
        i_funct3_3  = 3'b111;
        i_adr3      = {19'd0, 3'b010, 10'd11};
        i_wdata_3   = 32'd24;
        i_we_3      = 1'b0;
        i_re_3      = 1'b1;
        //=============================================
        i_funct3_2  = 3'b111;
        i_adr2      = {19'd0, 3'b010, 10'd11};
        i_wdata_2   = 32'd23;
        i_we_2      = 1'b0;
        i_re_2      = 1'b1;
        //=============================================
        i_funct3_1  = 3'b111;
        i_adr1      = {19'd0, 3'b010, 10'd11};
        i_wdata_1   = 32'd22;
        i_we_1      = 1'b0;
        i_re_1      = 1'b1;
        //=============================================
        i_funct3_0  = 3'b111;
        i_adr0      = {19'd0, 3'b010, 10'd11};
        i_wdata_0   = 32'd21;
        i_we_0      = 1'b0;
        i_re_0      = 1'b1;
        // Memory interface ============================
        i_mem_rdata_3   = 32'd104;
        i_mem_ack_3     = 1'b0;
        i_mem_rdata_2   = 32'd103;
        i_mem_ack_2     = 1'b0;
        i_mem_rdata_1   = 32'd102;
        i_mem_ack_1     = 1'b0;
        i_mem_rdata_0   = 32'd101;
        i_mem_ack_0     = 1'b1;
        #10;
        i_mem_ack_0     = 1'b0;
        i_re_7 = 1'b0;
        i_re_6 = 1'b0;
        i_re_5 = 1'b0;
        i_re_4 = 1'b0;
        i_re_3 = 1'b0;
        i_re_2 = 1'b0;
        i_re_1 = 1'b0;
        i_re_0 = 1'b0;
        #30;
        // CPU interface ==============================
        i_funct3_7  = 3'b111;
        i_adr7      = {19'd0, 3'b010, 10'd11};
        i_wdata_7   = 32'd28;
        i_we_7      = 1'b0;
        i_re_7      = 1'b1;
        //=============================================
        i_funct3_6  = 3'b111;
        i_adr6      = {19'd0, 3'b010, 10'd11};
        i_wdata_6   = 32'd27;
        i_we_6      = 1'b0;
        i_re_6      = 1'b1;
        //=============================================
        i_funct3_5  = 3'b111;
        i_adr5      = {19'd0, 3'b010, 10'd11};
        i_wdata_5   = 32'd26;
        i_we_5      = 1'b0;
        i_re_5      = 1'b1;
        //=============================================
        i_funct3_4  = 3'b111;
        i_adr4      = {19'd0, 3'b010, 10'd11};
        i_wdata_4   = 32'd25;
        i_we_4      = 1'b0;
        i_re_4      = 1'b1;
        //=============================================
        i_funct3_3  = 3'b111;
        i_adr3      = {19'd0, 3'b010, 10'd11};
        i_wdata_3   = 32'd24;
        i_we_3      = 1'b0;
        i_re_3      = 1'b1;
        //=============================================
        i_funct3_2  = 3'b111;
        i_adr2      = {19'd0, 3'b010, 10'd11};
        i_wdata_2   = 32'd23;
        i_we_2      = 1'b0;
        i_re_2      = 1'b1;
        //=============================================
        i_funct3_1  = 3'b111;
        i_adr1      = {19'd0, 3'b010, 10'd11};
        i_wdata_1   = 32'd22;
        i_we_1      = 1'b0;
        i_re_1      = 1'b1;
        //=============================================
        i_funct3_0  = 3'b111;
        i_adr0      = {19'd0, 3'b010, 10'd11};
        i_wdata_0   = 32'd21;
        i_we_0      = 1'b0;
        i_re_0      = 1'b1;
        // Memory interface ============================
        i_mem_rdata_3   = 32'd104;
        i_mem_ack_3     = 1'b0;
        i_mem_rdata_2   = 32'd103;
        i_mem_ack_2     = 1'b1;
        i_mem_rdata_1   = 32'd102;
        i_mem_ack_1     = 1'b0;
        i_mem_rdata_0   = 32'd101;
        i_mem_ack_0     = 1'b0;
        #10;
        i_mem_ack_2     = 1'b0;
        i_re_7 = 1'b0;
        i_re_6 = 1'b0;
        i_re_5 = 1'b0;
        i_re_4 = 1'b0;
        i_re_3 = 1'b0;
        i_re_2 = 1'b0;
        i_re_1 = 1'b0;
        i_re_0 = 1'b0;

        //================================================================
        // Test case 6 multiple read in multiple channel
        //================================================================
        #30;
        // CPU interface ==============================
        i_funct3_7  = 3'b111;
        i_adr7      = {19'd0, 3'b011, 10'd18};
        i_wdata_7   = 32'd28;
        i_we_7      = 1'b0;
        i_re_7      = 1'b1;
        //=============================================
        i_funct3_6  = 3'b111;
        i_adr6      = {19'd0, 3'b010, 10'd17};
        i_wdata_6   = 32'd27;
        i_we_6      = 1'b0;
        i_re_6      = 1'b1;
        //=============================================
        i_funct3_5  = 3'b111;
        i_adr5      = {19'd0, 3'b001, 10'd16};
        i_wdata_5   = 32'd26;
        i_we_5      = 1'b0;
        i_re_5      = 1'b1;
        //=============================================
        i_funct3_4  = 3'b111;
        i_adr4      = {19'd0, 3'b000, 10'd15};
        i_wdata_4   = 32'd25;
        i_we_4      = 1'b0;
        i_re_4      = 1'b1;
        //=============================================
        i_funct3_3  = 3'b111;
        i_adr3      = {19'd0, 3'b011, 10'd14};
        i_wdata_3   = 32'd24;
        i_we_3      = 1'b0;
        i_re_3      = 1'b1;
        //=============================================
        i_funct3_2  = 3'b111;
        i_adr2      = {19'd0, 3'b010, 10'd13};
        i_wdata_2   = 32'd23;
        i_we_2      = 1'b0;
        i_re_2      = 1'b1;
        //=============================================
        i_funct3_1  = 3'b111;
        i_adr1      = {19'd0, 3'b001, 10'd12};
        i_wdata_1   = 32'd22;
        i_we_1      = 1'b0;
        i_re_1      = 1'b1;
        //=============================================
        i_funct3_0  = 3'b111;
        i_adr0      = {19'd0, 3'b000, 10'd11};
        i_wdata_0   = 32'd21;
        i_we_0      = 1'b0;
        i_re_0      = 1'b1;
        // Memory interface ============================
        #10;
        i_mem_rdata_3   = 32'd104;
        i_mem_rdata_2   = 32'd103;
        i_mem_rdata_1   = 32'd102;
        i_mem_rdata_0   = 32'd101;
        i_mem_ack_3     = 1'b1;
        i_mem_ack_2     = 1'b1;
        i_mem_ack_1     = 1'b1;
        i_mem_ack_0     = 1'b1;
        #10;
        i_mem_ack_0     = 1'b0;
        i_mem_ack_1     = 1'b0;
        i_mem_ack_2     = 1'b0;
        i_mem_ack_3     = 1'b0;
        i_re_3 = 1'b0;
        i_re_2 = 1'b0;
        i_re_1 = 1'b0;
        i_re_0 = 1'b0;
        #10;
        i_mem_rdata_3   = 32'd204;
        i_mem_rdata_2   = 32'd203;
        i_mem_rdata_1   = 32'd202;
        i_mem_rdata_0   = 32'd201;
        i_mem_ack_3     = 1'b1;
        i_mem_ack_2     = 1'b1;
        i_mem_ack_1     = 1'b1;
        i_mem_ack_0     = 1'b1;
        #10;
        i_mem_ack_0     = 1'b0;
        i_mem_ack_1     = 1'b0;
        i_mem_ack_2     = 1'b0;
        i_mem_ack_3     = 1'b0;        
        i_re_7 = 1'b0;
        i_re_6 = 1'b0;
        i_re_5 = 1'b0;
        i_re_4 = 1'b0;

        //================================================================
        // Test case 7 continuous read
        //================================================================
        #30;
        // CPU interface ==============================
        i_funct3_7  = 3'b111;
        i_adr7      = {19'd0, 3'b011, 10'd18};
        i_wdata_7   = 32'd28;
        i_we_7      = 1'b0;
        i_re_7      = 1'b0;
        //=============================================
        i_funct3_6  = 3'b111;
        i_adr6      = {19'd0, 3'b010, 10'd17};
        i_wdata_6   = 32'd27;
        i_we_6      = 1'b0;
        i_re_6      = 1'b0;
        //=============================================
        i_funct3_5  = 3'b111;
        i_adr5      = {19'd0, 3'b001, 10'd16};
        i_wdata_5   = 32'd26;
        i_we_5      = 1'b0;
        i_re_5      = 1'b0;
        //=============================================
        i_funct3_4  = 3'b111;
        i_adr4      = {19'd0, 3'b000, 10'd15};
        i_wdata_4   = 32'd25;
        i_we_4      = 1'b0;
        i_re_4      = 1'b0;
        //=============================================
        i_funct3_3  = 3'b111;
        i_adr3      = {19'd0, 3'b011, 10'd14};
        i_wdata_3   = 32'd24;
        i_we_3      = 1'b0;
        i_re_3      = 1'b0;
        //=============================================
        i_funct3_2  = 3'b111;
        i_adr2      = {19'd0, 3'b010, 10'd13};
        i_wdata_2   = 32'd23;
        i_we_2      = 1'b0;
        i_re_2      = 1'b0;
        //=============================================
        i_funct3_1  = 3'b111;
        i_adr1      = {19'd0, 3'b001, 10'd12};
        i_wdata_1   = 32'd22;
        i_we_1      = 1'b0;
        i_re_1      = 1'b0;
        //=============================================
        i_funct3_0  = 3'b111;
        i_adr0      = {19'd0, 3'b000, 10'd11};
        i_wdata_0   = 32'd21;
        i_we_0      = 1'b0;
        i_re_0      = 1'b1;
        // Memory interface ============================
        #10;
        i_mem_rdata_3   = 32'd104;
        i_mem_rdata_2   = 32'd103;
        i_mem_rdata_1   = 32'd102;
        i_mem_rdata_0   = 32'd101;
        i_mem_ack_3     = 1'b0;
        i_mem_ack_2     = 1'b0;
        i_mem_ack_1     = 1'b0;
        i_mem_ack_0     = 1'b1;
        i_adr0      = {19'd0, 3'b000, 10'd12};
        #10;
        i_mem_rdata_0   = 32'd102;
        i_mem_ack_3     = 1'b0;
        i_mem_ack_2     = 1'b0;
        i_mem_ack_1     = 1'b0;
        i_mem_ack_0     = 1'b1;
        i_adr0      = {19'd0, 3'b000, 10'd13}; 
        #10;
        i_mem_rdata_0   = 32'd103;
        i_mem_ack_3     = 1'b0;
        i_mem_ack_2     = 1'b0;
        i_mem_ack_1     = 1'b0;
        i_mem_ack_0     = 1'b1;
        i_adr0      = {19'd0, 3'b000, 10'd14};
        #10;
        i_mem_rdata_0   = 32'd104;
        i_mem_ack_3     = 1'b0;
        i_mem_ack_2     = 1'b0;
        i_mem_ack_1     = 1'b0;
        i_mem_ack_0     = 1'b1;
        i_adr0      = {19'd0, 3'b000, 10'd15};
        i_re_0          = 1'b0; 
        #10;
        i_mem_ack_0     = 1'b0;
                                                               
        #1000 $stop;
    end
    
endmodule
