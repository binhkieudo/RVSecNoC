`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2023 12:55:59 AM
// Design Name: 
// Module Name: rv32_cpu_decompressor
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


module rv32_cpu_decompressor #(
    parameter FPU_ENABLE = 1
)
(
    input  wire [15:0] i_instr16, // compressed instruction
    output wire [31:0] o_instr32
);

    localparam  OP_SYSTEM = 7'b1110011,
                OP_LOAD   = 7'b0000011,
                OP_LUI    = 7'b0110111,
                OP_BRANCH = 7'b1100011,
                OP_JAL    = 7'b1101111,
                OP_JALR   = 7'b1100111,
                OP_ALU    = 7'b0110011,
                OP_ALUI   = 7'b0010011,
                OP_STORE  = 7'b0100011;

    localparam  FUNCT3_LW     = 3'b010,
                FUNCT3_SLL    = 3'b001,
                FUNCT3_BEQ    = 3'b000,
                FUNCT3_BNE    = 3'b001,
                FUNCT3_XOR    = 3'b100,
                FUNCT3_OR     = 3'b110,
                FUNCT3_AND    = 3'b111,
                FUNCT3_SR     = 3'b101,  
                FUNCT3_SUBADD = 3'b000,
                FUNCT3_SW     = 3'b010;

    localparam  FUNCT12_EBREAK = 12'h001;

    // Compressed instrunction
    wire [1:0] ci_opcode;
    wire [2:0] ci_rd_3;
    wire [4:0] ci_rd_5;
    wire [2:0] ci_rs1_3;
    wire [4:0] ci_rs1_5;
    wire [2:0] ci_rs2_3;
    wire [2:0] ci_rs2_5;
    wire [2:0] ci_funct3;
    
    // Immediate
    wire [20:0] imm20;
    wire [12:0] imm12;

    // Intermediate
    reg         illegal;
    reg [31:0]  decoded;

    // Mapping
    assign ci_opcode    = i_instr16[1:0];
    assign ci_rd_3      = i_instr16[4:2];
    assign ci_rd_5      = i_instr16[11:7];
    assign ci_rs1_3     = i_instr16[9:7];
    assign ci_rs1_5     = i_instr16[11:7];
    assign ci_rs2_3     = i_instr16[4:2];
    assign ci_rs2_5     = i_instr16[6:2];
    assign ci_funct3    = i_instr16[15:13];

    // 22-bit sign-extended immediate for J/JAL --
    assign imm20[0] = 1'b0;
    assign imm20[1] = i_instr16[3];
    assign imm20[2] = i_instr16[4];
    assign imm20[3] = i_instr16[5];
    assign imm20[4] = i_instr16[11];
    assign imm20[5] = i_instr16[2];
    assign imm20[6] = i_instr16[7];
    assign imm20[7] = i_instr16[6];
    assign imm20[8] = i_instr16[9];
    assign imm20[9] = i_instr16[10];
    assign imm20[10] = i_instr16[8];
    assign imm20[20:11] = {10{i_instr16[12]}};

    // 12-bit sign-extended immediate for branches
    assign imm12[0] = 1'b0;
    assign imm12[1] = i_instr16[3];
    assign imm12[2] = i_instr16[4];
    assign imm12[3] = i_instr16[10];
    assign imm12[4] = i_instr16[11];
    assign imm12[5] = i_instr16[2];
    assign imm12[6] = i_instr16[5];
    assign imm12[7] = i_instr16[6];
    assign imm12[12:8] = {5{i_instr16[12]}};

    // Compressed Instruction Decoder
    always @(*) begin
        decoded = 32'd0;
        illegal = 1'b0;
        
        case (ci_opcode)
            2'b00: begin // Register-Based Loads and Stores
                case (ci_funct3[2:1])
                    2'b01: begin // C.LW / C.FLW
                        decoded[6:0]    = OP_LOAD;
                        decoded[11:7]   = {2'b01, ci_rd_3};
                        decoded[14:12]  = FUNCT3_LW;
                        decoded[19:15]  = {2'b01, ci_rs1_3};
                        decoded[21:20]  = 2'b00;
                        decoded[22]     = i_instr16[6];
                        decoded[23]     = i_instr16[10];
                        decoded[24]     = i_instr16[11];
                        decoded[25]     = i_instr16[12];
                        decoded[26]     = i_instr16[5];
                        decoded[31:27]  = 5'b00000;       
                        illegal         = ci_funct3[0] && (FPU_ENABLE == 0); // C.FLW 
                    end
                    2'b11: begin // C.SW // C.FSW
                        decoded[6:0]    = OP_STORE;
                        decoded[8:7]    = 2'b00;
                        decoded[9]      = i_instr16[6];
                        decoded[10]     = i_instr16[10];
                        decoded[11]     = i_instr16[11];
                        decoded[14:12]  = FUNCT3_SW;
                        decoded[19:15]  = {2'b01, ci_rs1_3};
                        decoded[24:20]  = {2'b01, ci_rs2_3};
                        decoded[25]     = i_instr16[12];
                        decoded[26]     = i_instr16[5];
                        decoded[31:27]  = 5'b00000;
                        illegal         = ci_funct3[0] && (FPU_ENABLE == 0); // C.FSW 
                    end
                    default: begin
                        decoded[6:0]    = OP_ALUI;
                        decoded[11:7]   = {2'b01, ci_rd_3};
                        decoded[14:12]  = FUNCT3_SUBADD;
                        decoded[19:15]  = 5'b00010; // stack pointer
                        decoded[21:20]  = 2'b00;
                        decoded[22]     = i_instr16[6];
                        decoded[23]     = i_instr16[5];
                        decoded[25:24]  = i_instr16[12:11];
                        decoded[29:26]  = i_instr16[10:7];
                        decoded[31:30]  = 2'b00; // zero extended
                        illegal         = (i_instr16[12:5] == 8'h00) ||
                                          (ci_funct3 == 3'b001)      ||
                                          (ci_funct3 == 3'b100)      ||
                                          (ci_funct3 == 3'b101);
                    end
                endcase
            end
            2'b01: begin // Control Transfer Instructions, Integer Constant-Generation Instructions
                case (ci_funct3[1:0])
                    2'b00:  begin
                        if (ci_funct3[2]) begin // 100 C.SRLI, C.SRAI, C.ANDI, C.SUB, C.XOR, C.OR, C.AND, reserved
                            case (i_instr16[11:10])
                                2'b10: begin // C.ANDI
                                    decoded[6:0]   = OP_ALUI;
                                    decoded[11:7]  = {2'b01, ci_rs1_3};
                                    decoded[14:12] = FUNCT3_AND;
                                    decoded[19:15] = {2'b01, ci_rs1_3};
                                    decoded[24:20] = i_instr16[6:2];
                                    decoded[31:25] = {7{i_instr16[12]}};
                                    
                                end
                                2'b11: begin // register-register operation
                                    decoded[6:0]   = OP_ALU;
                                    decoded[11:7]  = {2'b01, ci_rs1_3};
                                    decoded[14:12] = (i_instr16[6:5] == 2'b00)? FUNCT3_SUBADD:
                                                     (i_instr16[6:5] == 2'b01)? FUNCT3_XOR:
                                                     (i_instr16[6:5] == 2'b10)? FUNCT3_OR: FUNCT3_AND;
                                    decoded[19:15] = {2'b01, ci_rs1_3};
                                    decoded[24:20] = {2'b01, ci_rs2_3};
                                    decoded[31:25] = {1'b0, i_instr16[6:5] == 2'b00, 5'b00000};
                                end
                                default: begin // C.SRLI, C.SRAI
                                    decoded[6:0]   = OP_ALUI;
                                    decoded[11:7]  = {2'b01, ci_rs1_3};
                                    decoded[14:12] = FUNCT3_SR;
                                    decoded[19:15] = {2'b01, ci_rs1_3};
                                    decoded[24:20] = i_instr16[6:2];
                                    decoded[31:25] = {1'b0, i_instr16[10], 5'b00000};
                                end
                            endcase
                        end
                        else begin              // 000 C.NOP (rd=0) / C.ADDI
                            decoded[6:0]   = OP_ALUI;
                            decoded[11:7]  = ci_rd_5;
                            decoded[14:12] = FUNCT3_SUBADD;
                            decoded[19:15] = ci_rs1_5;
                            decoded[24:20] = i_instr16[6:2];
                            decoded[31:25] = {7{i_instr16[12]}}; // sign extend
                        end
                        illegal = ci_funct3[2] && i_instr16[12] && !i_instr16[11];
                    end
                    2'b01: begin // C.J, C.JAL
                        decoded[6:0]   = OP_JAL;
                        decoded[11:7]  = {4'b0000, !ci_funct3[2]};
                        decoded[19:12] = imm20[19:12];
                        decoded[20]    = imm20[11];
                        decoded[30:21] = imm20[10:1];
                        decoded[31]    = imm20[20];
                        illegal        = 1'b0;
                    end
                    2'b10: begin // C.LI / C.BEQ
                        if (ci_funct3[2]) begin // C.BEQ
                            decoded[6:0]    = OP_BRANCH;
                            decoded[7]      = imm12[11];
                            decoded[11:8]   = imm12[4:1];
                            decoded[14:12]  = FUNCT3_BEQ;
                            decoded[19:15]  = {2'b01, ci_rs1_3};
                            decoded[24:20]  = 5'b00000;
                            decoded[30:25]  = imm12[10:5];
                            decoded[31]     = imm12[12];
                        end
                        else begin // C.LI
                            decoded[6:0]    = OP_ALUI;
                            decoded[11:7]   = ci_rd_5;
                            decoded[14:12]  = FUNCT3_SUBADD;
                            decoded[19:15]  = 5'b00000;
                            decoded[24:20]  = i_instr16[6:2];
                            decoded[31:25]  = {7{i_instr16[12]}};
                        end
                        illegal = 1'b0;
                    end
                    default: begin // 11 C.LUI / C.ADDI16SP / C.BNEZ
                        if (ci_funct3[2]) begin // C.BNEZ
                            decoded[6:0]    = OP_BRANCH;
                            decoded[7]      = imm12[11];
                            decoded[11:8]   = imm12[4:1];
                            decoded[14:12]  = FUNCT3_BNE;
                            decoded[19:15]  = {2'b01, ci_rs1_3};
                            decoded[24:20]  = 5'b00000;
                            decoded[30:25]  = imm12[10:5];
                            decoded[31]     = imm12[12];
                            illegal = 0;                        
                        end
                        else begin // C.LUI / C.ADDI16SP
                            if (ci_rd_5 == 5'b00010) begin // C.ADDI16SP
                                decoded[6:0]   = OP_ALUI;
                                decoded[11:7]  = ci_rd_5;
                                decoded[14:12] = FUNCT3_SUBADD;
                                decoded[19:15] = 5'b00010;
                                decoded[23:20] = 4'b0000;
                                decoded[24]    = i_instr16[6];
                                decoded[25]    = i_instr16[2];
                                decoded[26]    = i_instr16[5];
                                decoded[27]    = i_instr16[3];
                                decoded[28]    = i_instr16[4];
                                decoded[31:29] = {3{i_instr16[12]}};
                            end
                            else begin // C.LUI
                                decoded[6:0]   = OP_LUI;
                                decoded[11:7]  = ci_rd_5;
                                decoded[16:12] = i_instr16[6:2];
                                decoded[31:17] = {14{i_instr16[12]}};
                            end
                            illegal = (i_instr16[6:2] == 5'b00000) && !i_instr16[12]; // reserved if nzimm = 0
                        end
                    end
                endcase        
            end
            default: begin // Stack-Pointer-Based Loads and Stores, Control Transfer Instructions
                case (ci_funct3[2:1])
                    2'b00: begin // C.SLLI
                        decoded[6:0]    = OP_ALUI;
                        decoded[11:7]   = ci_rs1_5;
                        decoded[14:12]  = FUNCT3_SLL;
                        decoded[19:15]  = ci_rs1_5;
                        decoded[24:20]  = i_instr16[6:2];
                        decoded[31:25]  = 7'b0000000;
                        illegal         = i_instr16[12] ||  // nzuimm[5] = 1 -> RV32 custom
                                          ci_funct3[0];     // 001 C.FLDSP / C.LQSP
                    end
                    2'b01: begin // C.LWSP / C.FLWSP (integer and float are identical as the FPU implements the Zfinx ISA extension)
                        decoded[6:0]    = OP_LOAD;
                        decoded[11:7]   = ci_rd_5;
                        decoded[14:12]  = FUNCT3_LW;
                        decoded[19:15]  = 5'b00010;
                        decoded[21:20]  = 2'b00;
                        decoded[24:22]  = i_instr16[6:4];
                        decoded[25]     = i_instr16[12];
                        decoded[27:26]  = i_instr16[3:2];
                        decoded[31:28]  = 4'b0000;
                        illegal         = ci_funct3[0] && (FPU_ENABLE == 0); // C.FLWSP
                    end
                    2'b11: begin // C.SWSP / C.FSWSP (integer and float are identical as the FPU implements the Zfinx ISA extension)
                        decoded[6:0]    = OP_STORE;
                        decoded[8:7]    = 2'b00;
                        decoded[11:9]   = i_instr16[11:9];
                        decoded[14:12]  = FUNCT3_SW;
                        decoded[19:15]  = 5'b00010;
                        decoded[24:20]  = ci_rs2_5;
                        decoded[25]     = i_instr16[12];
                        decoded[27:26]  = i_instr16[8:7];
                        decoded[31:28]  = 4'b0000;
                        illegal         = ci_funct3[0] && (FPU_ENABLE == 0); // C.FSWSP
                    end
                    default: begin // C.JR, C.JALR, C.MV, C.EBREAK, C.ADD; others: undefined
                        if (!i_instr16[12]) begin // C.JR, C.MV
                            if (i_instr16[6:2] == 5'b00000) begin // C.JR
                                decoded[6:0] = OP_JALR;
                                decoded[11:7] = 5'b00000;
                                decoded[19:15] = ci_rs1_5;
                                decoded[31:20] = {12{1'b0}};
                            end
                            else begin // C.MV
                                decoded[6:0]    = OP_ALU;
                                decoded[11:7]   = ci_rd_5;
                                decoded[14:12]  = 3'b000;
                                decoded[19:15]  = 5'b00000;
                                decoded[24:20]  = ci_rs2_5;
                                decoded[31:25]  = 7'b0000000;
                            end
                        end
                        else begin // C.EBREAK, C.JALR, C.ADD
                            if (|i_instr16[6:2]) begin // C.ADD
                                decoded[6:0]    = OP_ALU;
                                decoded[11:7]   = ci_rd_5;
                                decoded[14:12]  = 3'b000;
                                decoded[19:15]  = ci_rd_5;
                                decoded[24:20]  = ci_rs2_5;
                                decoded[31:25]  = 7'b0000000;
                            end
                            else if (|i_instr16[11:7]) begin // C.JALR
                                decoded[6:0]    = OP_JALR;
                                decoded[11:7]   = 5'b00001;
                                decoded[14:12]  = 3'b000;
                                decoded[19:15]  = ci_rs1_5;
                                decoded[31:20]  = 12'h000;
                            end
                            else begin // C.EBREAK
                                decoded[6:0]    = OP_SYSTEM;
                                decoded[19:7]   = 13'd0;
                                decoded[31:20]  = FUNCT12_EBREAK;
                            end
                        end
                        illegal = ci_funct3[0]; // 101 C.FSDSP / C.SQSP
                    end
                endcase
            end
        endcase
    end

    // output original 16-bit instruction word if illegal instruction
    assign o_instr32 = illegal? {16'h0000, i_instr16}: decoded;

endmodule
