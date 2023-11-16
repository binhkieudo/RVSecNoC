`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2023 02:33:03 PM
// Design Name: 
// Module Name: rv32_cpu
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


module rv32_cpu #(
    parameter XLEN = 32,
    parameter THREAD_COUNT = 8,
    parameter IMEM_CHANNEL = 8,
    parameter DMEM_CHANNEL = 4,
    parameter DMEM_DEPTH   = 1024,
    parameter COPROC_COUNT  = 3,
    parameter SHIFT_COUNT   = 8, // number of shifter
    parameter MULT_COUNT    = 4, // number of multiplier
    parameter DIVIDER_COUNT = 8, // number of divider
    parameter EXT_MUL       = 1,
    parameter EXT_ZMMUL     = 1
)
(
    // Global control
    input  wire              i_clk
    
);
    
    wire              i_rstn;
    
//===========================================================
// Controller
//===========================================================    
    //-- Register file
    wire [THREAD_COUNT-1:0]      ctrl_rf_wb_en;    // write back enable
    wire [THREAD_COUNT*5-1:0]    ctrl_rf_rs1;      // source register 1 address
    wire [THREAD_COUNT*5-1:0]    ctrl_rf_rs2;      // source register 2 address
    wire [THREAD_COUNT*5-1:0]    ctrl_rf_rd;       // destination register address
    wire [THREAD_COUNT*3-1:0]    ctrl_rf_mux;      // input source select
    wire [THREAD_COUNT-1:0]      ctrl_rf_zero_we;  // allow/force write access to x0
       
    //-- ALU
    wire [THREAD_COUNT*3-1:0]    ctrl_alu_op;       // ALU operation select
    wire [THREAD_COUNT-1:0]      ctrl_alu_opa_mux;  // operand A select (0=rs1, 1=PC)
    wire [THREAD_COUNT-1:0]      ctrl_alu_opb_mux;  // operand B select (0=rs2, 1=IMM)
    wire [THREAD_COUNT-1:0]      ctrl_alu_unsigned; // is unsigned ALU operation
    
    //-- Co-processor
    wire [THREAD_COUNT*COPROC_COUNT-1:0] ctrl_cp_en;
    wire [THREAD_COUNT-1:0]              ctrl_trap;
    wire [THREAD_COUNT*3-1:0]            ctrl_cp_op;
    wire [THREAD_COUNT*5-1:0]            ctrl_cp_exop;        
    //-- Instruction
    wire [THREAD_COUNT*3-1:0]    ctrl_ir_funct3;   // funct3 bit field
    wire [THREAD_COUNT*12-1:0]   ctrl_ir_funct12;  // funct12 bit field
    wire [THREAD_COUNT*7-1:0]    ctrl_ir_opcode;   // opcode bit field
    
    wire [THREAD_COUNT*XLEN-1:0] ctrl_imm;      // immediate
    wire [THREAD_COUNT*XLEN-1:0] ctrl_pc;       // pc

//===========================================================
// Register file
//===========================================================  
    wire [THREAD_COUNT*XLEN-1:0] rf_rs1;   // rs1
    wire [THREAD_COUNT*XLEN-1:0] rf_rs2;   // rs2
    
//===========================================================
// ALU
//===========================================================  
    wire [THREAD_COUNT-1:0]          alu_cmp_eq;   // comparator equal result
    wire [THREAD_COUNT-1:0]          alu_o_cmp_lt; // comparator less result
    wire [THREAD_COUNT*XLEN-1:0]     alu_res;      // ALU result
    wire [THREAD_COUNT*XLEN-1:0]     alu_addr;    

//===========================================================
// Coprocessor
//=========================================================== 
    wire [THREAD_COUNT*XLEN-1:0]     cp_res;
    wire [THREAD_COUNT-1:0]          cp_vld;    

//===========================================================
// Load/Store unit
//=========================================================== 
    wire [THREAD_COUNT-1:0]      lsu_wack;
    wire [THREAD_COUNT*XLEN-1:0] lsu_rdata;
    wire [THREAD_COUNT-1:0]      lsu_rack;  
    wire [DMEM_CHANNEL*XLEN-1:0] lsu_mem_wadr;
    wire [DMEM_CHANNEL-1:0]      lsu_mem_we;
    wire [DMEM_CHANNEL*4-1:0]    lsu_mem_ben;
    wire [DMEM_CHANNEL*XLEN-1:0] lsu_mem_wdata;
    wire [DMEM_CHANNEL*XLEN-1:0] lsu_mem_radr;
    wire [DMEM_CHANNEL-1:0]      lsu_mem_re;
    
//===========================================================
// IMEM
//===========================================================  
    wire [THREAD_COUNT*XLEN-1:0] ibus_req_addr; // access address
    wire [THREAD_COUNT-1:0]      ibus_req_re;   // read request
    wire [THREAD_COUNT*XLEN-1:0] ibus_resp_data; // access address
    wire [THREAD_COUNT-1:0]      ibus_resp_ack;   // read request

//===========================================================
// DMEM
//=========================================================== 
    wire [DMEM_CHANNEL-1:0]      dcache_wack;
    wire [DMEM_CHANNEL*XLEN-1:0] dcache_rdata;
    wire [DMEM_CHANNEL-1:0]      dcache_rack;
        

    wire [THREAD_COUNT*XLEN-1:0]  ctrl_wadr;
    wire [THREAD_COUNT-1:0]       ctrl_we;
    wire [THREAD_COUNT*XLEN-1:0]  ctrl_radr;
    wire [THREAD_COUNT-1:0]       ctrl_re;
//===========================================================
// Functional units
//=========================================================== 
    rv32_cpu_control controller(
        // Global control
        .i_clk                  (i_clk            ),
        .i_rstn                 (i_rstn           ),
        // RF
        .o_ctrl_rf_wb_en        (ctrl_rf_wb_en    ),
        .o_ctrl_rf_rs1          (ctrl_rf_rs1      ),
        .o_ctrl_rf_rs2          (ctrl_rf_rs2      ),
        .o_ctrl_rf_rd           (ctrl_rf_rd       ),
        .o_ctrl_rf_mux          (ctrl_rf_mux      ),
        .o_ctrl_rf_zero_we      (ctrl_rf_zero_we  ),
        // ALU
        .o_ctrl_alu_op          (ctrl_alu_op      ),
        .o_ctrl_alu_opa_mux     (ctrl_alu_opa_mux ),
        .o_ctrl_alu_opb_mux     (ctrl_alu_opb_mux ),
        .o_ctrl_alu_unsigned    (ctrl_alu_unsigned),
        // Co-processor
        .o_ctrl_cp_en           (ctrl_cp_en       ),
        .o_ctrl_trap            (ctrl_trap        ),
        .o_ctrl_cp_op           (ctrl_cp_op       ),
        .o_ctrl_cp_exop         (ctrl_cp_exop     ),
        .i_ctrl_cp_done         (cp_vld           ),
        // Instruction
        .o_ctrl_ir_funct3       (ctrl_ir_funct3   ),
        .o_ctrl_ir_funct12      (ctrl_ir_funct12  ),
        .o_ctrl_ir_opcode       (ctrl_ir_opcode   ),
        // Instruction fetch        
        .o_bus_req_addr         (ibus_req_addr    ),
        .o_bus_req_re           (ibus_req_re      ),
        .i_bus_rsp_data         (ibus_resp_data   ),
        .i_bus_rsp_ack          (ibus_resp_ack    ),
        // Load/Store unit
        .o_ctrl_wadr            (ctrl_wadr        ),
        .o_ctrl_we              (ctrl_we          ),
        .i_ctrl_wack            (lsu_wack         ),
        .o_ctrl_radr            (ctrl_radr        ),
        .o_ctrl_re              (ctrl_re          ),
        .i_ctrl_rack            (lsu_rack         ),
        // Data output
        .o_imm                  (ctrl_imm         ),
        .o_pc                   (ctrl_pc          ),
        .i_rs1                  (rf_rs1           )
    );
    
    rv32_cpu_regfile regfile(
        .i_clk            (i_clk           ),
        // RF conotrol
        .i_ctrl_mem_vld   (lsu_rack        ),  
        .i_ctrl_wb_sel    (ctrl_rf_mux     ),
        .i_ctrl_wb_en     (ctrl_rf_wb_en   ),
        .i_ctrl_zero_we   (ctrl_rf_zero_we ),
        .i_ctrl_cores_vld (cp_vld          ),
        // Input data
        .i_mem            (lsu_rdata       ),
        .i_alu            (alu_res         ),
        .i_csr            ('b0             ),
        .i_npc            (alu_addr        ),
        .i_cores          (cp_res          ),
        // Regfile access
        .i_rf_rd          (ctrl_rf_rd      ),
        .i_rf_rs1         (ctrl_rf_rs1     ),
        .i_rf_rs2         (ctrl_rf_rs2     ),
        .o_rs1            (rf_rs1          ),
        .o_rs2            (rf_rs2          )
    );
    
    rv32_cpu_alu alu(
        // Control signals
        .i_ctrl_alu_unsigned (ctrl_alu_unsigned ),   
        .i_ctrl_alu_op       (ctrl_alu_op       ),
        .i_ctrl_pc_sel       (ctrl_alu_opa_mux  ),
        .i_ctrl_imm_sel      (ctrl_alu_opb_mux  ),
        // Data ipnut
        .i_rs1               (rf_rs1            ),
        .i_rs2               (rf_rs2            ),
        .i_pc                (ctrl_pc           ),
        .i_imm               (ctrl_imm          ),
        // Data output
        .o_cmp_eq            (alu_cmp_eq        ),
        .o_cmp_lt            (alu_o_cmp_lt      ),
        .o_res               (alu_res           ),
        .o_addr              (alu_addr          )
    );
    
    // Co-processor
    rv32_cpu_coproc #(
        .XLEN           (XLEN           ),
        .THREAD_COUNT   (THREAD_COUNT   ),
        .TYPE_COUNT     (COPROC_COUNT   ),
        .SHIFT_COUNT    (SHIFT_COUNT    ),
        .MULT_COUNT     (MULT_COUNT     ),
        .DIVIDER_COUNT  (DIVIDER_COUNT  ),
        .EXT_MUL        (EXT_MUL        ),
        .EXT_ZMMUL      (EXT_ZMMUL      )
    ) coproc (
        .i_clk      (i_clk  ),
        .i_rstn     (i_rstn ),
        // CPU interface
        .o_cpu_res  (cp_res       ),
        .o_cpu_vld  (cp_vld       ),
        .i_cpu_en   (ctrl_cp_en   ),
        .i_cpu_trap (ctrl_trap    ),
        .i_cpu_op   (ctrl_cp_op   ),
        .i_cpu_exop (ctrl_cp_exop ),
        // Register interface
        .i_rs1      (rf_rs1       ),
        .i_rs2      (rf_rs2       )
    );
    

    
    // Load/Store unit
    rv32_lsu #(
        .XLEN         (XLEN                 ),
        .THREAD_COUNT (THREAD_COUNT         ),
        .CHANNEL      (DMEM_CHANNEL         ),
        .LOG2_CHANNEL ($clog2(DMEM_CHANNEL) ),
        .BANK_DEPTH   (DMEM_DEPTH           ),
        .LOG2_DEPTH   ($clog2(DMEM_DEPTH)   )    
    ) lsu (
        // Global control
        .i_clk       (i_clk         ),
        .i_rstn      (i_rstn        ),
        // Control signals
        .i_funct3    (ctrl_ir_funct3),
        // CPU request -- Write
        .i_wadr      (ctrl_wadr     ),
        .i_we        (ctrl_we       ),
        .i_wdata     (rf_rs2        ),
        .o_wack      (lsu_wack      ),
        // CPU request -- Read
        .i_radr      (ctrl_radr     ),
        .i_re        (ctrl_re       ),
        .o_rdata     (lsu_rdata     ),
        .o_rack      (lsu_rack      ),
        // Memory interface -- Write
        .o_mem_wadr  (lsu_mem_wadr  ),
        .o_mem_we    (lsu_mem_we    ),
        .o_mem_ben   (lsu_mem_ben   ),
        .o_mem_wdata (lsu_mem_wdata ),
        .i_mem_wack  (dcache_wack   ),
        // Memory interface -- Read
        .o_mem_radr  (lsu_mem_radr  ),
        .o_mem_re    (lsu_mem_re    ),
        .i_mem_rdata (dcache_rdata  ),
        .i_mem_rack  (dcache_rack   )
    );
    
    
    // MEM write interface
    wire [IMEM_CHANNEL*XLEN-1:0] i_bus_waddr; // access address
    wire [IMEM_CHANNEL-1:0]      i_bus_we;    // read request
    wire [IMEM_CHANNEL*XLEN-1:0] i_bus_wdata; // access address
    
    vio_0 vio(
        .clk        (i_clk       ),
        .probe_in0  (alu_res     ),    
        .probe_out0 (i_bus_waddr ),
        .probe_out1 (i_bus_we    ),
        .probe_out2 (i_bus_wdata ),
        .probe_out3 (i_rstn)
    );

    rv32_icache icache(
        .i_clk          (i_clk          ),
        .i_rstn         (i_rstn         ),
        // MEM interface
        .i_bus_req_addr (ibus_req_addr  ),
        .i_bus_req_re   (ibus_req_re    ),
        .o_bus_rsp_data (ibus_resp_data ),
        .o_bus_rsp_ack  (ibus_resp_ack  ),
        // MEM write interface
        .i_bus_waddr    (i_bus_waddr    ),
        .i_bus_we       (i_bus_we       ),
        .i_bus_wdata    (i_bus_wdata    )
    );
    
    rv32_dcache #(
        .XLEN           (XLEN                ),
        .CHANNEL        (DMEM_CHANNEL        ),
        .LOG2_CHANNEL   ($clog2(DMEM_CHANNEL)),
        .BANK_DEPTH     (DMEM_DEPTH          ),
        .LOG2_DEPTH     ($clog2(DMEM_DEPTH)  )
    ) dcache (
        // Global control
        .i_clk          (i_clk          ),
        .i_rstn         (i_rstn         ),
        // Write interface
        .i_mem_wadr     (lsu_mem_wadr   ),
        .i_mem_we       (lsu_mem_we     ),
        .i_mem_ben      (lsu_mem_ben    ),
        .i_mem_wdata    (lsu_mem_wdata  ),
        .o_mem_wack     (dcache_wack    ),
        // Read interface
        .i_mem_radr     (lsu_mem_radr   ),
        .i_mem_re       (lsu_mem_re     ),
        .o_mem_rdata    (dcache_rdata   ),
        .o_mem_rack     (dcache_rack    )
    );
    
endmodule
