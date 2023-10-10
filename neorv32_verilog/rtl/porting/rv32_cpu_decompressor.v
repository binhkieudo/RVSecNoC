module rv32_cpu_decompressor #(
    parameter FPU_ENABLE = 1
)
(
    input  wire [15:0] i_instr16, // compressed instruction
    output wire [31:0] o_instr32
);

    localparam  OP_ALUI  = 7'b0010011,
                OP_LOAD  = 7'b0000011,
                OP_STORE = 7'b0100011;

    localparam  FUNCT3_SUBADD = 3'b000,
                FUNCT3_LW = 3'b010,
                FUNCT3_SW = 3'b010;

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
                
            end
            default: begin // Stack-Pointer-Based Loads and Stores, Control Transfer Instructions

            end
        endcase
    end

endmodule
