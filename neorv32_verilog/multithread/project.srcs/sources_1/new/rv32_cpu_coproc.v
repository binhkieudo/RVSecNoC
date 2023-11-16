`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 01:41:22 PM
// Design Name: 
// Module Name: rv32_cpu_coproc
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


module rv32_cpu_coproc #(
    parameter XLEN = 32,
    parameter THREAD_COUNT  = 8, // number of input thread
    parameter TYPE_COUNT    = 3, // number of co-processor types
    parameter SHIFT_COUNT   = 8, // number of shifter
    parameter MULT_COUNT    = 4, // number of multiplier
    parameter DIVIDER_COUNT = 8, // number of divider
    parameter EXT_MUL       = 1,
    parameter EXT_ZMMUL     = 1
)
(
    // Global control
    input  wire i_clk,
    input  wire i_rstn,
    // CPU interface
    output wire [THREAD_COUNT*XLEN-1:0]       o_cpu_res,
    output wire [THREAD_COUNT-1:0]            o_cpu_vld,
    input  wire [THREAD_COUNT*TYPE_COUNT-1:0] i_cpu_en,
    input  wire                               i_cpu_trap,
    input  wire [THREAD_COUNT*3-1:0]          i_cpu_op,
    input  wire [THREAD_COUNT*5-1:0]          i_cpu_exop,
    // Register interface
    input  wire [THREAD_COUNT*XLEN-1:0]       i_rs1,
    input  wire [THREAD_COUNT*XLEN-1:0]       i_rs2
);

    localparam SHIFT_SEL = 0,
               MULT_SEL  = 1,
               DIV_SEL   = 2;  
    
    reg [THREAD_COUNT*XLEN-1:0] ro_cpu_res;
    reg [THREAD_COUNT-1:0]      ro_cpu_vld;  
    
    // Shifter bus
    reg  [THREAD_COUNT-1:0]             shifter_en;
    wire [SHIFT_COUNT*THREAD_COUNT-1:0] shifter_ireq;
    wire [SHIFT_COUNT*3-1:0]            shifter_iop;
    wire [SHIFT_COUNT*XLEN-1:0]         shifter_irs1;
    wire [SHIFT_COUNT*XLEN-1:0]         shifter_irs2;
    wire [SHIFT_COUNT*XLEN-1:0]         shifter_ores;
    wire [SHIFT_COUNT-1:0]              shifter_obusy;
    wire [SHIFT_COUNT*THREAD_COUNT-1:0] shifter_ovalid;
    wire [THREAD_COUNT*XLEN-1:0]        shifter_ocpu_res;
    wire [THREAD_COUNT-1:0]             shifter_ocpu_vld;
    
    // Multiplier split bus
    reg  [THREAD_COUNT-1:0]              mult_en;
    wire [MULT_COUNT*THREAD_COUNT/2-1:0] mult_ireq;
    wire [MULT_COUNT*3-1:0]              mult_iop;
    wire [MULT_COUNT*XLEN-1:0]           mult_irs1;
    wire [MULT_COUNT*XLEN-1:0]           mult_irs2;
    wire [MULT_COUNT*XLEN-1:0]           mult_ores;
    wire [MULT_COUNT-1:0]                mult_obusy;
    wire [MULT_COUNT*THREAD_COUNT/2-1:0] mult_ovalid;
    wire [THREAD_COUNT*XLEN-1:0]         mult_ocpu_res;
    wire [THREAD_COUNT-1:0]              mult_ocpu_vld;  
    
     // Divider split bus
    reg  [THREAD_COUNT-1:0]                 div_en;
    wire [DIVIDER_COUNT*THREAD_COUNT/2-1:0] div_ireq;
    wire [DIVIDER_COUNT*3-1:0]              div_iop;
    wire [DIVIDER_COUNT*XLEN-1:0]           div_irs1;
    wire [DIVIDER_COUNT*XLEN-1:0]           div_irs2;
    wire [DIVIDER_COUNT*XLEN-1:0]           div_ores;
    wire [DIVIDER_COUNT-1:0]                div_obusy;
    wire [DIVIDER_COUNT*THREAD_COUNT/2-1:0] div_ovalid;
    wire [THREAD_COUNT*XLEN-1:0]            div_ocpu_res;
    wire [THREAD_COUNT-1:0]                 div_ocpu_vld; 
       
    integer t_idx;
    always @(*) begin
        for (t_idx = 0; t_idx < SHIFT_COUNT; t_idx = t_idx + 1) begin: thread
            shifter_en[t_idx] = i_cpu_en[(t_idx+1)*TYPE_COUNT-1-:TYPE_COUNT] == SHIFT_SEL;
            mult_en[t_idx] = i_cpu_en[(t_idx+1)*TYPE_COUNT-1-:TYPE_COUNT] == MULT_SEL;
            div_en[t_idx] = i_cpu_en[(t_idx+1)*TYPE_COUNT-1-:TYPE_COUNT] == DIV_SEL;
            
            // Select output
            if (i_cpu_en[(t_idx+1)*TYPE_COUNT-1-:TYPE_COUNT] == MULT_SEL) begin
                if ((EXT_ZMMUL == 1) || (EXT_MUL == 1)) begin
                    ro_cpu_res[(t_idx+1)*XLEN-1-:XLEN] = mult_ocpu_res[(t_idx+1)*XLEN-1-:XLEN];
                    ro_cpu_vld[t_idx] = mult_ocpu_vld[t_idx];
                end
                else begin
                    ro_cpu_res[(t_idx+1)*XLEN-1-:XLEN] = {XLEN{1'b0}};
                    ro_cpu_vld[t_idx]                  = 1'b0;
                end
            end
            else if (i_cpu_en[(t_idx+1)*TYPE_COUNT-1-:TYPE_COUNT] == DIV_SEL) begin
                if (EXT_MUL == 1) begin
                    ro_cpu_res[(t_idx+1)*XLEN-1-:XLEN] = div_ocpu_res[(t_idx+1)*XLEN-1-:XLEN];
                    ro_cpu_vld[t_idx] = div_ocpu_vld[t_idx];
                end
                else begin
                    ro_cpu_res[(t_idx+1)*XLEN-1-:XLEN] = {XLEN{1'b0}};
                    ro_cpu_vld[t_idx]                  = 1'b0;
                end
            end            
            else begin
                ro_cpu_res[(t_idx+1)*XLEN-1-:XLEN] = shifter_ocpu_res[(t_idx+1)*XLEN-1-:XLEN];
                ro_cpu_vld[t_idx] = shifter_ocpu_vld[t_idx];
            end
        end
    end
    
// ============================================================================    
// Co-processor 1: Shifter 
// ============================================================================ 
    rv32_cp_arbtr #(
        .XLEN           (XLEN                ),
        .THREAD         (THREAD_COUNT        ),
        .CHANNEL        (SHIFT_COUNT         ),
        .LOG2_CHANNEL   ($clog2(SHIFT_COUNT) ),
        .PIPELINE       (1                   )
    ) shifter_arbtr (
        .i_clk      (i_clk ),
        // Thread control
        .o_cpu_res  (shifter_ocpu_res   ),
        .o_cpu_vld  (shifter_ocpu_vld   ),
        .i_cpu_cpen (shifter_en         ),
        .i_cpu_trap (                   ),
        .i_cpu_op   (i_cpu_op           ),
        .i_cpu_exop (                   ),
        .i_cpu_rs1  (i_rs1              ),
        .i_cpu_rs2  (i_rs2              ),
        // Channel control
        .o_cp_req   (shifter_ireq       ),
        .o_cp_en    (                   ),
        .o_cp_trap  (                   ),
        .o_cp_op    (shifter_iop        ),
        .o_cp_exop  (                   ),
        .o_cp_rs1   (shifter_irs1       ),
        .o_cp_rs2   (shifter_irs2       ),
        .i_cp_res   (shifter_ores       ),
        .i_cp_busy  (shifter_obusy      ),
        .i_cp_valid (shifter_ovalid     )
    );
    
    rv32_cp_shifter #(
        .XLEN           (XLEN           ),
        .THREAD_COUNT   (THREAD_COUNT   ),
        .METHOD         ("FPGA"         ) // "FPGA" / "ASIC"
    ) shifter [SHIFT_COUNT-1:0] (
        .i_clk          (i_clk          ),
        // Control signals
        .i_req_thread   (shifter_ireq   ),
        .i_cpu_op       (shifter_iop    ),
        // Data input
        .i_rs1          (shifter_irs1   ),
        .i_rs2          (shifter_irs2   ),
        // Results and status
        .o_res          (shifter_ores   ),
        .o_busy         (shifter_obusy  ),
        .o_valid        (shifter_ovalid )
    );
    
// ============================================================================    
// Co-processor 2: Multiplier 
// ============================================================================
    rv32_cp_arbtr #(
        .XLEN           (XLEN                ),
        .THREAD         (THREAD_COUNT/2      ),
        .CHANNEL        (MULT_COUNT/2        ),
        .LOG2_CHANNEL   ($clog2(MULT_COUNT)-1)
    ) mult_arbtr[1:0] (
        .i_clk      (i_clk           ),
        // Thread control
        .o_cpu_res  (mult_ocpu_res   ),
        .o_cpu_vld  (mult_ocpu_vld   ),
        .i_cpu_cpen (mult_en         ),
        .i_cpu_trap (                ),
        .i_cpu_op   (i_cpu_op        ),
        .i_cpu_exop (                ),
        .i_cpu_rs1  (i_rs1           ),
        .i_cpu_rs2  (i_rs2           ),
        // Channel control
        .o_cp_req   (mult_ireq       ),
        .o_cp_en    (                ),
        .o_cp_trap  (                ),
        .o_cp_op    (mult_iop        ),
        .o_cp_exop  (                ),
        .o_cp_rs1   (mult_irs1       ),
        .o_cp_rs2   (mult_irs2       ),
        .i_cp_res   (mult_ores       ),
        .i_cp_busy  (mult_obusy      ),
        .i_cp_valid (mult_ovalid     )
    );
    
    rv32_cp_mul #(
        .XLEN           (XLEN           ),
        .THREAD_COUNT   (THREAD_COUNT/2 )
    ) multiplier[MULT_COUNT-1:0] (
        .i_clk          (i_clk       ),
        // Control signals
        .i_req_thread   (mult_ireq   ),
        .i_cpu_op       (mult_iop    ),
        // Data input
        .i_rs1          (mult_irs1   ),
        .i_rs2          (mult_irs2   ),
        // Results and status
        .o_res          (mult_ores   ),
        .o_busy         (mult_obusy  ),
        .o_valid        (mult_ovalid )
    );    

// ============================================================================    
// Co-processor 2: Divider
// ============================================================================
    rv32_cp_arbtr #(
        .XLEN           (XLEN                   ),
        .THREAD         (THREAD_COUNT/2         ),
        .CHANNEL        (DIVIDER_COUNT/2        ),
        .LOG2_CHANNEL   ($clog2(DIVIDER_COUNT)-1),
        .PIPELINE       (0)
    ) div_arbtr[1:0] (
        .i_clk      (i_clk          ),
        // Thread control
        .o_cpu_res  (div_ocpu_res   ),
        .o_cpu_vld  (div_ocpu_vld   ),
        .i_cpu_cpen (div_en         ),
        .i_cpu_trap (               ),
        .i_cpu_op   (i_cpu_op       ),
        .i_cpu_exop (               ),
        .i_cpu_rs1  (i_rs1          ),
        .i_cpu_rs2  (i_rs2          ),
        // Channel control
        .o_cp_req   (div_ireq       ),
        .o_cp_en    (               ),
        .o_cp_trap  (               ),
        .o_cp_op    (div_iop        ),
        .o_cp_exop  (               ),
        .o_cp_rs1   (div_irs1       ),
        .o_cp_rs2   (div_irs2       ),
        .i_cp_res   (div_ores       ),
        .i_cp_busy  (div_obusy      ),
        .i_cp_valid (div_ovalid     )
    );
    
    rv32_cp_div #(
        .XLEN           (XLEN           ),
        .THREAD_COUNT   (THREAD_COUNT/2 )
    ) divider [DIVIDER_COUNT-1:0] (
        .i_clk          (i_clk      ),
        .i_rstn         (i_rstn     ),
        // Control signals
        .i_req_thread   (div_ireq   ),
        .i_cpu_op       (div_iop    ),
        // Data input
        .i_rs1          (div_irs1   ),
        .i_rs2          (div_irs2   ),
        // Results and status
        .o_res          (div_ores   ),
        .o_busy         (div_obusy  ),
        .o_valid        (div_ovalid )
    );    

    assign o_cpu_res = ro_cpu_res;
    assign o_cpu_vld = ro_cpu_vld;
    
endmodule
