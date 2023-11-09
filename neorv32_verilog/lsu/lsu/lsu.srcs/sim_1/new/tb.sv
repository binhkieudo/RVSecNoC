`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2023 12:55:11 PM
// Design Name: 
// Module Name: tb
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


module tb(

    );
    
    parameter XLEN         = 32;
    parameter THREAD_COUNT = 8;
    parameter CHANNEL      = 4;
    parameter LOG2_CHANNEL = 2;
    parameter BANK_DEPTH   = 1024;
    parameter LOG2_DEPTH   = 10;
    
    

    // Global control
    reg i_clk = 1'b0;
    reg i_rstn = 1'b0;
    // Control signals
    reg  [THREAD_COUNT*3-1:0]     i_funct3 = 'b0;
    // CPU request -- Write
    reg  [THREAD_COUNT*XLEN-1:0]  i_wadr   = 'b0;
    reg  [THREAD_COUNT-1:0]       i_we     = 'b0;
    reg  [THREAD_COUNT*XLEN-1:0]  i_wdata  = 'b0;
    wire [THREAD_COUNT-1:0]       o_wack;
    // CPU request -- Read
    reg  [THREAD_COUNT*XLEN-1:0]  i_radr    = 'b0;
    reg  [THREAD_COUNT-1:0]       i_re      = 'b0;
    wire [THREAD_COUNT*XLEN-1:0]  o_rdata;
    wire [THREAD_COUNT-1:0]       o_rack;  
    
    top udt(.*);
    
    always #5 i_clk = ~i_clk;
    
    parameter test_case = 5;
    
    integer i;
    initial begin
        #15 i_rstn = 1'b1;
        
        if ((test_case == 0) || (test_case == 99)) begin // A thread write to memory, read after one cycle
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {8{32'd0}};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_001a};
            // CPU request -- Read
            i_radr   = {8{32'd0}};
            i_re     = 8'b0000_0000;
            #10 i_we     = 8'b0000_0000;
		i_re	 = 8'b0000_0001;
	    #10 i_re	 = 8'b0000_0000;
	    #10;
        end
    	if ((test_case == 1) || (test_case == 99)) begin // A thread write multiple data than read
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_001a};
            // CPU request -- Read
            i_radr   = {8{32'd0}};
            i_re     = 8'b0000_0000;
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd4};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_001b};
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd8};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_001c};
             #10;
             i_we     = 8'b0000_0000;
             i_radr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd8};
             i_re     = 8'b0000_0001;
             #10 i_radr = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd4};
             #10 i_radr = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
             #10 i_re     = 8'b0000_0000;                  		
	   end
	    if ((test_case == 2) || (test_case == 99)) begin // A thread write multiple data than read parallel
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_001a};
            // CPU request -- Read
            i_radr   = {8{32'd0}};
            i_re     = 8'b0000_0000;
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd4};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_001b};
            i_radr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
            i_re     = 8'b0000_0001;            
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd8};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_001c};
            i_radr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd4};            
            #10;
            i_we     = 8'b0000_0000;
            i_radr = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd8};
            #10 i_re     = 8'b0000_0000;                  		
	    end
	    if ((test_case == 3) || (test_case == 99)) begin // A thread write and read same address
            #10; // First phase, only write
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_001a};
            // CPU request -- Read
            i_radr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
            i_re     = 8'b0000_0000;
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd4};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_001b};
            i_radr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd4};
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd8};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_001c};
            i_radr = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd8};            
            #10;
            i_we     = 8'b0000_0000;
            i_re     = 8'b0000_0000;
            #10 // Second phase, write new and read
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_002a};
            // CPU request -- Read
            i_radr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
            i_re     = 8'b0000_0001;
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd4};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_002b};
            i_radr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd4};
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd8};
            i_we     = 8'b0000_0001;
            i_wdata  = {32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000,
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_0000, 
                        32'h0000_002c};
            i_radr = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd8};            
            #10;
            i_we     = 8'b0000_0000;
            i_radr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
            #10;
            i_radr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd4};
            #10;
            i_radr   = {32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd8};
            i_re     = 8'b0000_0000;    
                               		
	    end
        if ((test_case == 4) || (test_case == 99)) begin // Multiple thread write same time
            #10;
            i_funct3 = 24'hffffff;
            // CPU request -- Write
            i_wadr   = {32'd3076, 32'd2052, 32'd1028, 32'd4, 32'd3072, 32'd2048, 32'd1024, 32'd0};
            i_we     = 8'b1111_1111;
            i_wdata  = {32'h0000_0017, 
                        32'h0000_0016, 
                        32'h0000_0015, 
                        32'h0000_0014,
                        32'h0000_0013, 
                        32'h0000_0012, 
                        32'h0000_0011, 
                        32'h0000_0010};
            // CPU request -- Read
            i_radr   = {8{32'd0}};
            i_re     = 8'b0000_0000;
            #10;
            i_we     = 8'b0000_1111;
            i_radr   = {32'd3076, 32'd2052, 32'd1028, 32'd4, 32'd3072, 32'd2048, 32'd1024, 32'd0};
            i_re     = 8'b1111_0000;
            #10;   
            i_we     = 8'b0000_0000;   
            i_re     = 8'b0000_1111;
            #10;
            i_re     = 8'b0000_0000;
            #10;
            i_radr   = {8{32'd0}};
            i_re     = 8'b1111_1111;
            #10;
            i_re     = 8'b0000_0000;       
        end
        if ((test_case == 5) || (test_case == 99)) begin // Multiple thread write byte
            #10;
            i_funct3 = {3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000};
            // CPU request -- Write
            i_wadr   = {32'd1027, 32'd1026, 32'd1025, 32'd1024, 32'd3, 32'd2, 32'd1, 32'd0};
            i_we     = 8'b1111_1111;
            i_wdata  = {32'h0000_0017, 
                        32'h0000_0016, 
                        32'h0000_0015, 
                        32'h0000_0014,
                        32'h0000_0013, 
                        32'h0000_0012, 
                        32'h0000_0011, 
                        32'h0000_0010};
            i_radr   = {8{32'd0}};
            i_re     = 8'b0000_0000;
            #10;
            i_we     = 8'b0000_0000;
            #20;
            i_funct3 = {3'b001, 3'b001, 3'b001, 3'b001, 3'b001, 3'b001, 3'b001, 3'b001};
            i_wadr   = {32'd1030, 32'd1028, 32'd1026, 32'd1024, 32'd6, 32'd4, 32'd2, 32'd0};
            i_we     = 8'b1111_1111;
            i_wdata  = {32'h0000_8080, 
                        32'h0000_7070, 
                        32'h0000_6060, 
                        32'h0000_5050,
                        32'h0000_4040, 
                        32'h0000_3030, 
                        32'h0000_2020, 
                        32'h0000_1010};
            #10;
            i_we     = 8'b0011_0011; 
            #10; 
            i_we     = 8'b0000_0000;                                   
        end
        #1000 $stop;
    end
    
endmodule
