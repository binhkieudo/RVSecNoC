module rv32_cpu_alu #(
    parameter XLEN                  = 32,
    parameter FAST_SHIFT            = 1,
    paraemter FAST_MUL              = 1,
    parameter CPU_EXTENSION_RISCV_M = 0,
    parameter CPU_EXTENSION_RISCV_Zmmul = 0
)
(
    // Global control
    input wire i_clk, // global clock, rising edge
    input wire i_rstn, // global reset, active low, async
    // Control signals
    input wire i_ctrl_trap,
    input wire i_ctrl_alu_unsigned, // is unsigned ALU operation
    input wire [2:0] i_ctrl_alu_op,       // ALU operation
    input wire i_ctrl_alu_shift_right,    // 0:shift left, 1: shift right
    input wire i_ctrl_alu_shift_arth,  // 0: shift logical, 1: shift arithmetic
    input wire i_ctrl_ir_funct3,
    input wire [4:0] i_ctrl_cp_en, // active co processor signals
    input wire i_ctrl_pc_sel,       // 0:rs1, 1:pc
    input wire i_ctrl_imm_sel,      // 0:rs2, 1:imm
    // CSR interface
    input wire i_csr_we, // csr write enable
    input wire [11:0] i_csr_addr, // csr address
    input wire [XLEN-1:0] i_csr_wdata, // csr write data
    output wire [XLEN-1:0] o_csr_rdata, // csr read data
    // Data input
    input wire [XLEN-1:0] i_rs1,    // rf source 1
    input wire [XLEN-1:0] i_rs2,    // rf source 2
    input wire [XLEN-1:0] i_rs3,    // rf source 3
    input wire [XLEN-1:0] i_rs4,    // rf source 4
    input wire [XLEN-1:0] i_pc,     // program counter
    input wire [XLEN-1:0] i_imm,    // immediate
    // Data output
    output wire o_cmp_eq,  // comparator equal result
    output wire o_cmp_lt,  // comparator less result
    output wire [XLEN-1:0] o_res,   // ALU result
    output wire [XLEN-1:0] o_addr,  // address computation result
    // Status
    output wire o_cp_done // co-processor operation done
);

    localparam ALU_OP_ADD  = 3'b000, // A + B
               ALU_OP_SUB  = 3'b001, // A - B
               ALU_OP_CP   = 3'b010, // Co-proc
               ALU_OP_SLT  = 3'b011, // A < B
               ALU_OP_MOVB = 3'b100, // A = B
               ALU_OP_XOR  = 3'b101, // A ^ B 
               ALU_OP_OR   = 3'b110, // A | B
               ALU_OP_AND  = 3'b111; // A & B

    // Comparator
    wire [XLEN:0] cmp_rs1; 
    wire [XLEN:0] cmp_rs2;
    wire [1:0]      cmp; // comparator status

    // Operands
    wire [XLEN-1:0] opa, opb; // operand
    wire [XLEN:0]   opa_x, opb_x; // extended operaand

    // Intermediate results
    wire [XLEN:0]   addsub_res;
    wire [XLEN-1:0] cp_res;

    // Co-processor interface
    wire [XLEN-1:0] cp_result [0:4];
    wire [4:0] cp_start;
    wire [4:0] cp_valid;

    // CSR read-backs
    wire [31:0] csr_rdata_fpu;
    wire [31:0] csr_rdata_cfu;

    // Comparator Unit (for conditionl branches)
    assign cmp_rs1 = {i_rs1[XLEN-1] & !i_ctrl_alu_unsigned, i_rs1}; // sign-extend
    assign cmp_rs2 = {i_rs2[XLEN-1] & !i_ctrl_alu_unsigned, i_rs2}; // sign-extend

    assign o_cmp_eq = cmp_rs1 == cmp_rs2;
    assign o_cmp_lt = (cmp_rs1[XLEN] ^ cmp_rs2[XLEN])? (cmp_rs1[XLEN] && ~cmp_rs2[XLEN]): (i_rs1 < i_rs2);
    
    // ALU input operand select
    assign opa = i_ctrl_pc_sel? i_pc: i_rs1;
    assign opb = i_ctrl_imm_sel? i_imm: i_rs2;

    // Add/Sub Core
    assign opa_x = {opa[XLEN-1] & !i_ctrl_alu_unsigned, opa};
    assign opb_x = {opb[XLEN-1] & !i_ctrl_alu_unsigned, opb}; 

    assign addsub_res = opa_x + ((i_ctrl_alu_op[0])? opb_x: -opb_x);
    assign o_addr     = addsub_res[XLEN-1:0];

    // AlU output select
    assign o_res      = (i_ctrl_alu_op == ALU_OP_CP)? cp_res:
                        (i_ctrl_alu_op == ALU_OP_SLT)? {31'd0, addsub_res[XLEN]}:
                        (i_ctrl_alu_op == ALU_OP_MOVB)? opb:
                        (i_ctrl_alu_op == ALU_OP_XOR)? i_rs1 ^ opb:
                        (i_ctrl_alu_op == ALU_OP_OR)? i_rs1 | opb:
                        (i_ctrl_alu_op == ALU_OP_AND)? i_rs1 & opb: addsub_res[XLEN-1:0];

//====================================================
//  ALU Co-Processors
//  Co-proc 0: Shift unit
//  Co-proc 1: Mul unit (M/Zmmul extension)
//  Co-proc 2: Div unit (M extension)
//====================================================
    assign cp_start = i_ctrl_cp_en;
    assign o_cp_done = |cp_valid;
    assign cp_res = cp_valid[0]? cp_result[0]:
                       cp_valid[1]? cp_result[1]:
                       cp_valid[2]? cp_result[2]: 32'd0;

    // Co-proc 0: Shift unit
    generate
        if (FAST_SHIFT == 1) begin: gen_fast_shift
            rv32_cpu_cp_shifter_barrel cp_shifter (
                .i_clk (i_clk),
                .i_rstn (i_rstn),
                .i_cpu_trap (i_ctrl_trap),
                .i_shift_right (i_ctrl_alu_shift_right),
                .i_shift_arth (i_ctrl_alu_shift_arth),
                .i_start (cp_start[0]),
                .i_rs1 (i_rs1),
                .i_shamt(opb[XLEN-1:0]),
                .o_res(cp_result[0]),
                .o_valid(cp_valid[0])
            );
        end
        else begin: gen_serial_shift
            rv32_cpu_cp_shifter_ser cp_shifter (
                .i_clk (i_clk),
                .i_rstn (i_rstn),
                .i_cpu_trap (i_ctrl_trap),
                .i_shift_right (i_ctrl_alu_shift_right),
                .i_shift_arth (i_ctrl_alu_shift_arth),
                .i_start (cp_start[0]),
                .i_rs1 (i_rs1),
                .i_shamt(opb[XLEN-1:0]),
                .o_res(cp_result[0]),
                .o_valid(cp_valid[0])
            );          
        end
    endgenerate

    // Co-proc 1: Mul unit (M/Zmmul extension)
    generate
        if ((CPU_EXTENSION_RISCV_M == 1) || (CPU_EXTENSION_RISCV_Zmmul == 1)) begin: gen_mul
            if (FAST_MUL == 1) begin: gen_dsp_mul
                rv32_cpu_cp_mul_dsp mul_unit (
                    .i_clk     (i_clk),
                    .i_rstn    (i_rstn),
                    .i_start   (cp_start[1]),
                    .i_mul_op  (i_ctrl_ir_funct3), 
                    .i_rs1     (i_rs1),
                    .i_rs2     (i_rs2),
                    .o_prod    (cp_result[1]),
                    .o_valid   (cp_valid[1])
                );
            end
            else begin: gen_serial_mul
                rv32_cpu_cp_mul_ser mul_unit (
                    .i_clk     (i_clk),
                    .i_rstn    (i_rstn),
                    .i_start   (cp_start[1]),
                    .i_cpu_trap(i_ctrl_trap),
                    .i_mul_op  (i_ctrl_ir_funct3), 
                    .i_rs1     (i_rs1),
                    .i_rs2     (i_rs2),
                    .o_prod    (cp_result[1]),
                    .o_valid   (cp_valid[1])
                );                
            end
        end
        else begin
            assign cp_valid[1] = 1'b0;
            assign cp_result[1] = 32'd0;
        end
    endgenerate

    // Co-proc 2: Div unit (M extension)
    generate
        if (CPU_EXTENSION_RISCV_M == 1) begin: gen_serial_div
        rv32_cpu_cp_div_ser div_unit (
            // Global control
            .i_clk      (i_clk ),
            .i_rstn     (i_rstn ),
            // Control signals
            .i_start    (cp_start[2] ),
            .i_cpu_trap (i_ctrl_trap ),
            .i_div_op   (i_ctrl_ir_funct3 ),
            // Input data
            .i_rs1      (i_rs1 ),
            .i_rs2      (i_rs2 ),
            // Output data
            .o_res      (cp_result[2] ),
            .o_valid    (cp_valid[2] )
        );
        end
    endgenerate   

endmodule
