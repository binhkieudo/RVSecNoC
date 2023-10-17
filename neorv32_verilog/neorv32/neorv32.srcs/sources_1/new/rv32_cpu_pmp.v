`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2023 12:36:13 PM
// Design Name: 
// Module Name: rv32_cpu_pmp
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
`include "rv32_package.vh"

module rv32_cpu_pmp # (
    parameter XLEN        = 32,
    parameter NUM_REGIONS = 16, // number of regions (0..16)
    parameter GRANULARITY = 16, // minimal region granularity in bytes, has to be a power of 2, min 4 bytes
    parameter LOG2GRAN    = 4  // log2(granularity)
)
(
    // GLobal control
    input  wire            i_clk,
    input  wire            i_rstn,
    // Control signals
    input  wire            i_ctrl_cpu_priv,
    input  wire            i_ctrl_lsu_priv,
    input  wire            i_ctrl_lsu_rw,
    input  wire            i_ctrl_cpu_debug,
    // CSR interface
    input  wire            i_csr_we,
    input  wire [11:0]     i_csr_addr,
    input  wire [XLEN-1:0] i_csr_wdata,
    output reg  [XLEN-1:0] o_csr_rdata,
    // Address input
    input  wire [XLEN-1:0] i_addr_if,
    input  wire [XLEN-1:0] i_addr_ls,
    // Faults        
    output reg             o_fault_ex,
    output reg             o_fault_rd,
    output reg             o_fault_wr
);
    
    // PMP configuration register bits
    localparam CFG_R  = 0,    // read permit
               CFG_W  = 1,    // write permit
               CFG_X  = 2,    // execute permit
               CFG_AL = 3,   // mode bit low
               CFG_AH = 4,   // mode bit high
               CFG_RL = 5,   // reserved
               CFG_RH = 6,   // reserved
               CFG_L  = 7;   // locked entry

    // PMP modes
    localparam MODE_OFF   = 2'b00,
               MODE_TOR   = 2'b01,
               MODE_NA4   = 2'b10,
               MODE_NAPOT = 2'b11;
               
    // PMP helpers
    localparam PMP_LSB = LOG2GRAN;
    localparam PMP_LSBMN1 = PMP_LSB - 1;
    localparam PMP_LSBMN2 = PMP_LSB - 2;
    localparam MASK_SIZE  = XLEN - PMP_LSB;
    
    // PMP CSRs
    reg  [3:0]      csr_we_cfg;
    reg  [15:0]     csr_we_addr;
    reg  [7:0]      csr_cfg     [0:NUM_REGIONS-1];
    reg  [XLEN-1:0] csr_addr    [0:NUM_REGIONS-1];
    wire [7:0]      cfg_rd      [0:15];
    wire [XLEN-1:0] cfg_rd32    [0:3];
    reg  [XLEN-1:0] addr_rd     [0:15];
    
    // PMP address extension to 34 bit
    wire [XLEN+1:0] xaddr [0:NUM_REGIONS-1];
    
    // Access permission check
    wire [XLEN-1:PMP_LSB]  addr_mask_napot [NUM_REGIONS-1:0];
    reg  [XLEN-1:PMP_LSB]  addr_mask       [NUM_REGIONS-1:0]; 
    
    wire [NUM_REGIONS-1:0] check_i_cmp_mm;
    wire [NUM_REGIONS-1:0] check_i_cmp_ge;
    wire [NUM_REGIONS-1:0] check_i_cmp_lt;
    wire [NUM_REGIONS-1:0] check_d_cmp_mm;
    wire [NUM_REGIONS-1:0] check_d_cmp_ge;
    wire [NUM_REGIONS-1:0] check_d_cmp_lt;
    reg  [NUM_REGIONS-1:0] check_i_match;
    reg  [NUM_REGIONS-1:0] check_d_match;
    reg  [NUM_REGIONS-1:0] check_perm_ex;
    reg  [NUM_REGIONS-1:0] check_perm_rw;
    wire [NUM_REGIONS  :0] check_fail_ex;
    wire [NUM_REGIONS  :0] check_fail_rw;
    
    // CSR Write Access 
    always @(*) begin
        // Configuration registers
        csr_we_cfg = 4'b0000;
        if (({i_csr_addr[11:2], 2'b00} == `CSR_PMPCFG0) && i_csr_we)
            csr_we_cfg[1:0] = 2'b01;
        
        // Address registers
        csr_we_addr = 16'd0;
        if (({i_csr_addr[11:4], 4'b0000} == `CSR_PMPADDR0) && i_csr_we)
            csr_we_addr[3:0] = 4'b0001; 
    end

    // PMP CSR registers
    genvar a;
    generate
        for (a = 0; a < NUM_REGIONS; a = a + 1) begin: csr_reg_gen
            always @(posedge i_clk, negedge i_rstn) begin
                if (!i_rstn) begin
                    csr_cfg[a]  <= 8'd0;
                    csr_addr[a] <= {XLEN{1'b0}};
                end
                else begin
                    // configuration
                    if ((csr_we_cfg[a/4]) && !csr_cfg[a][7]) begin // unlocked write access
                        csr_cfg[a][CFG_R] <= i_csr_wdata[(a%4)*8+0]; // R (read)
                        csr_cfg[a][CFG_W] <= i_csr_wdata[(a%4)*8+1]; // W (write)
                        csr_cfg[a][CFG_X] <= i_csr_wdata[(a%4)*8+2]; // X (execute)
                        if ((GRANULARITY > 4) && (i_csr_wdata[(a%4)*8+4 -: 2] == MODE_NA4))
                            csr_cfg[a][CFG_AH:CFG_AL] <= MODE_OFF;
                        else csr_cfg[a][CFG_AH:CFG_AL] <= i_csr_wdata[(a%4)*8+4 -: 2];
                        csr_cfg[a][CFG_RL]  <= 1'b0;
                        csr_cfg[a][CFG_RH]  <= 1'b0;
                        csr_cfg[a][CFG_L]   <= i_csr_wdata[(a%4)*8+7];
                    end
                    
                    // Address
                    if (csr_we_addr[a] && !csr_cfg[a][CFG_L]) begin // unlocked write access
                        if (a < NUM_REGIONS-1) begin
                            if (!csr_addr[a+1][CFG_L] || (csr_cfg[a+1][CFG_AH:CFG_AL] != MODE_TOR)) // cfg(i+1) not "LOCKED TOR"
                                csr_addr[a] <= {2'b00, i_csr_wdata[XLEN-3:0]};    
                        end
                        else csr_addr[a] <= {2'b00, i_csr_wdata[XLEN-3:0]};
                    end
                end
            end
        end
    endgenerate

    // CSR Read Access
    always @(*) begin
            if ({i_csr_addr[11:5], 5'b00000} == `CSR_PMPCFG0) begin // PMP CSR
                if (!i_csr_addr[4]) // PMP configuration CSR
                    o_csr_rdata = cfg_rd32[i_csr_addr[1:0]];
                else // PMP address CSR
                    o_csr_rdata = addr_rd[i_csr_addr[3:0]];
            end o_csr_rdata = {XLEN{1'b0}};
    end

    // CSR read-back
    genvar i, j;
    generate
        for (i = 0; i < NUM_REGIONS; i = i + 1) begin: csr_read_back_gen
           // Configuration
           assign cfg_rd[i] = csr_cfg[i];
           // Address
           always @(*) begin
             addr_rd[i] = 32'd0;
             addr_rd[i][XLEN-1:PMP_LSBMN2] = csr_addr[i][XLEN-1:PMP_LSBMN2];
             
             // bit G-1 reads as zero in TOR or OFF mode
             if (GRANULARITY == 8) begin
                if (csr_cfg[i][CFG_AH] == 1'b0) // TOR/OFF mode
                    addr_rd[i][PMP_LSBMN1:0] = {PMP_LSB{1'b0}};
             end
             else if (GRANULARITY > 8) begin
                // in NAPOT mode bits G-2:0 must read as one
                addr_rd[i][PMP_LSBMN2:0] = {PMP_LSBMN1{1'b1}};
                if (csr_cfg[i][CFG_AH] == 1'b0) // TOR/OFF mode
                    addr_rd[i][PMP_LSBMN1:0] = {PMP_LSB{1'b0}};
             end
           end 
        end
        
        for (j = NUM_REGIONS; j < 16; j = j + 1) begin: csr_read_back_rest_gen
            assign cfg_rd[j]  = 8'd0;
            always @(*) addr_rd[j] = 32'd0;
        end 
    endgenerate
    
    // pack configuration read-back
    assign cfg_rd32[0] = {cfg_rd[3], cfg_rd[2], cfg_rd[1], cfg_rd[0]};
    assign cfg_rd32[1] = {cfg_rd[7], cfg_rd[6], cfg_rd[5], cfg_rd[4]};
    assign cfg_rd32[2] = {cfg_rd[11], cfg_rd[10], cfg_rd[9], cfg_rd[8]};
    assign cfg_rd32[3] = {cfg_rd[15], cfg_rd[14], cfg_rd[13], cfg_rd[12]};
    
    // Access check logic
    genvar r, s;
    generate
        for (r = 0; r < NUM_REGIONS; r = r + 1) begin: region_gen
            // Extend region addresses to 34-bit
            assign xaddr[r] = {csr_addr[r], 2'b00};
            
            // Compute address masks for NAPOT mode
            assign addr_mask_napot[r][PMP_LSB] = 1'b0;
            for (s = PMP_LSB+1; s < XLEN; s = s + 1) begin: mask_gen
                assign addr_mask_napot[r][s] = addr_mask_napot[r][s-1] | !xaddr[r][s-1];
            end
            
            always @(posedge i_clk, negedge i_rstn) begin
                if (!i_rstn)
                    addr_mask[r] <= {MASK_SIZE{1'b0}};
                else begin
                    if (csr_cfg[r][CFG_AL]) // NAPOT
                        addr_mask[r] <= addr_mask_napot[r];
                    else // NA4
                        addr_mask[r] <= {MASK_SIZE{1'b1}};
                end
            end
            
            // Check region address mask
            // NA4 and NAPOT
            assign check_i_cmp_mm[r] = (i_addr_if[XLEN-1:PMP_LSB] & addr_mask[r]) == (xaddr[r][XLEN-1:PMP_LSB] & addr_mask[r]);
            assign check_d_cmp_mm[r] = (i_addr_ls[XLEN-1:PMP_LSB] & addr_mask[r]) == (xaddr[r][XLEN-1:PMP_LSB] & addr_mask[r]);
           
            // TOR region 0
            if (r == 0) begin // first entry: use ZERO as base and current entry as bound
                assign check_i_cmp_ge[r] = 1'b1; // address is always greater than or equal to zero
                assign check_i_cmp_lt[r] = 1'b0; // unused
                assign check_d_cmp_ge[r] = 1'b1; // address is always greater than or equal to zero
                assign check_d_cmp_lt[r] = 1'b0; // unused                
            end
            else begin // use previous entry as base and current entry as bound
                assign check_i_cmp_ge[r] = i_addr_if[XLEN-1:PMP_LSB] >= xaddr[r-1][XLEN-1:PMP_LSB];
                assign check_i_cmp_lt[r] = i_addr_if[XLEN-1:PMP_LSB] <  xaddr[r][XLEN-1:PMP_LSB];
                assign check_d_cmp_ge[r] = i_addr_ls[XLEN-1:PMP_LSB] >= xaddr[r-1][XLEN-1:PMP_LSB];
                assign check_d_cmp_lt[r] = i_addr_ls[XLEN-1:PMP_LSB] <  xaddr[r][XLEN-1:PMP_LSB];
            end
            
            // Check region match according to configured mode
            always @(*) begin
                case (csr_cfg[r][CFG_AH:CFG_AL])
                    MODE_OFF: begin // entry disabled
                        check_i_match[r] = 1'b0;
                        check_d_match[r] = 1'b0;                        
                    end
                    MODE_TOR: begin // top of region
                        if (r == (NUM_REGIONS-1)) begin //
                            check_i_match[r] = check_i_cmp_ge[r] & check_i_cmp_lt[r];
                            check_d_match[r] = check_d_cmp_ge[r] & check_d_cmp_lt[r];                             
                        end
                        else begin // this saves a LOT of comparators
                            check_i_match[r] = check_i_cmp_ge[r] & !check_i_cmp_ge[r+1];
                            check_d_match[r] = check_d_cmp_ge[r] & !check_d_cmp_ge[r+1];                          
                        end
                    end
                    default: begin // naturally-aligned region
                       check_i_match[r] = check_i_cmp_mm[r];
                       check_d_match[r] = check_d_cmp_mm[r]; 
                    end
                endcase
            end
           
            // Compute region permission
            always @(*) begin
                // Execute (X)
                if (i_ctrl_cpu_priv == `PRIV_MODE_M) // M mode: always allow if lock bit
                    check_perm_ex[r] = csr_cfg[r][CFG_X] | (!csr_cfg[r][CFG_L]);
                else
                    check_perm_ex[r] = csr_cfg[r][CFG_X];
                    
                // Read (R)
                if (~i_ctrl_lsu_rw) begin
                    if (i_ctrl_lsu_priv == `PRIV_MODE_M) // M mode: always allow if lock bit
                        check_perm_rw[r] <= csr_cfg[r][CFG_R] | (!csr_cfg[r][CFG_L]);
                    else // U mode: check actual permission
                        check_perm_rw[r] <= csr_cfg[r][CFG_R];
                end
                // Write (W)
                else begin
                    if (i_ctrl_lsu_priv == `PRIV_MODE_M) // M mode: always allow if lock bit
                        check_perm_rw[r] <= csr_cfg[r][CFG_W] | (!csr_cfg[r][CFG_L]);
                    else // U mode: check actual permission
                        check_perm_rw[r] <= csr_cfg[r][CFG_W];
                end
            end 
        end
    endgenerate
    
    // Check for access fault (using static prioritization)
    assign check_fail_ex[NUM_REGIONS] = i_ctrl_cpu_priv != `PRIV_MODE_M; // default (if not match): fault if not M-mode
    assign check_fail_rw[NUM_REGIONS] = i_ctrl_lsu_priv != `PRIV_MODE_M; // default (if not match): fault if not M-mode
    
    genvar z;
    generate
        for (z = 0; z < NUM_REGIONS; z = z + 1) begin: fault_check_gen
            assign check_fail_ex[z] =  check_i_match[z]? !check_perm_ex[z]: check_fail_ex[z+1];
            assign check_fail_rw[z] =  check_d_match[z]? !check_perm_rw[z]: check_fail_rw[z+1];
        end
    endgenerate
    
    // Final PMP access fault signals (ingore PMP rules when in debug mode)
    always @(posedge i_clk, negedge i_rstn) begin
            if (!i_rstn) begin
                o_fault_ex <= 1'b0;
                o_fault_rd <= 1'b0;
                o_fault_wr <= 1'b0;
            end
            else begin
                o_fault_ex <= !i_ctrl_cpu_debug && check_fail_ex[0];
                o_fault_rd <= !i_ctrl_cpu_debug && check_fail_rw[0] && !i_ctrl_lsu_rw;
                o_fault_wr <= !i_ctrl_cpu_debug && check_fail_rw[0] &&  i_ctrl_lsu_rw;
            end
    end 
    
endmodule
