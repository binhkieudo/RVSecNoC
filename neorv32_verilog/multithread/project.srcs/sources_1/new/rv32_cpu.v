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
    parameter IMEM_CHANNEL = 8
)
(
    // Global control
    input  wire              i_clk,
    input  wire              i_rstn
);
    

//===========================================================
// Controller
//===========================================================    
    //-- Register file
    wire [THREAD_COUNT-1:0]      ctrl_rf_wb_en;    // write back enable
    wire [THREAD_COUNT*5-1:0]    ctrl_rf_rs1;      // source register 1 address
    wire [THREAD_COUNT*5-1:0]    ctrl_rf_rs2;      // source register 2 address
    wire [THREAD_COUNT*5-1:0]    ctrl_rf_rd;       // destination register address
    wire [THREAD_COUNT*2-1:0]    ctrl_rf_mux;      // input source select
    wire [THREAD_COUNT-1:0]      ctrl_rf_zero_we;  // allow/force write access to x0
       
    //-- ALU
    wire [THREAD_COUNT*3-1:0]    ctrl_alu_op;       // ALU operation select
    wire [THREAD_COUNT-1:0]      ctrl_alu_opa_mux;  // operand A select (0=rs1, 1=PC)
    wire [THREAD_COUNT-1:0]      ctrl_alu_opb_mux;  // operand B select (0=rs2, 1=IMM)
    wire [THREAD_COUNT-1:0]      ctrl_alu_unsigned; // is unsigned ALU operation
    
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
// Ibus
//===========================================================  
    wire [THREAD_COUNT*XLEN-1:0] ibus_req_addr; // access address
    wire [THREAD_COUNT-1:0]      ibus_req_re;   // read request
    wire [THREAD_COUNT*XLEN-1:0] ibus_resp_data; // access address
    wire [THREAD_COUNT-1:0]      ibus_resp_ack;   // read request
        
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
        // Instruction
        .o_ctrl_ir_funct3       (ctrl_ir_funct3   ),
        .o_ctrl_ir_funct12      (ctrl_ir_funct12  ),
        .o_ctrl_ir_opcode       (ctrl_ir_opcode   ),
        // Instruction fetch        
        .o_bus_req_addr         (ibus_req_addr  ),
        .o_bus_req_re           (ibus_req_re    ),
        .i_bus_rsp_data         (ibus_resp_data  ),
        .i_bus_rsp_ack          (ibus_resp_ack   ),
        // Data output
        .o_imm                  (ctrl_imm         ),
        .o_pc                   (ctrl_pc          )
    );
    
    rv32_cpu_regfile regfile(
        .i_clk          (i_clk           ),
        // RF conotrol
        .i_ctrl_wb_sel  (ctrl_rf_mux     ),
        .i_ctrl_wb_en   (ctrl_rf_wb_en   ),
        .i_ctrl_zero_we (ctrl_rf_zero_we ),
        // Input data
        .i_mem          ('b0             ),
        .i_alu          (alu_res         ),
        .i_csr          ('b0             ),
        .i_npc          (alu_addr        ),
        // Regfile access
        .i_rf_rd        (ctrl_rf_rd      ),
        .i_rf_rs1       (ctrl_rf_rs1     ),
        .i_rf_rs2       (ctrl_rf_rs2     ),
        .o_rs1          (rf_rs1          ),
        .o_rs2          (rf_rs2          )
    );
    
    rv32_cpu_alu alu(
        // Global control
        .i_clk               (i_clk             ),
        .i_rstn              (i_rstn            ),
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
    
    // MEM write interface
    wire [IMEM_CHANNEL*XLEN-1:0] i_bus_waddr; // access address
    wire [IMEM_CHANNEL-1:0]      i_bus_we;    // read request
    wire [IMEM_CHANNEL*XLEN-1:0] i_bus_wdata; // access address
    
    vio_0 vio(
        .clk        (i_clk       ),
        .probe_in0  (alu_res     ),    
        .probe_out0 (i_bus_waddr ),
        .probe_out1 (i_bus_we    ),
        .probe_out2 (i_bus_wdata )
    );

    rv32_imem imem(
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
    
endmodule
