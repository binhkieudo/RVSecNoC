`ifndef _rv32_package_vh_
`define _rv32_package_vh_

/****************************************************************************************************************************
    RISC-V ISA Opcodes
****************************************************************************************************************************/
//-- alu --
  `define OP_ALUI    7'b0010011 // ALU operation with immediate
  `define OP_ALU     7'b0110011 // ALU operation
  `define OP_LUI     7'b0110111 // load upper immediate
  `define OP_AUIPC   7'b0010111 // add upper immediate to PC
//-- control flow --
  `define OP_JAL     7'b1101111 // jump and link
  `define OP_JALR    7'b1100111 // jump and link with register
  `define OP_BRANCH  7'b1100011 // branch
//-- memory access --
  `define OP_LOAD    7'b0000011 // load
  `define OP_STORE   7'b0100011 // store
  `define OP_AMO     7'b0101111 // atomic memory access
  `define OP_FENCE   7'b0001111 // fence / fence.i
//-- system/csr --
  `define OP_SYSTEM  7'b1110011 // system/csr access
//-- floating point operations --
  `define OP_FOP     7'b1010011 // dual/single operand instruction
//-- official custom RISC-V opcodes - free for custom instructions --
  `define OP_CUST0   7'b0001011 // custom-0
  `define OP_CUST1   7'b0101011 // custom-1
  `define OP_CUST2   7'b1011011 // custom-2
  `define OP_CUST3   7'b1111011 // custom-3

/****************************************************************************************************************************
    RISC-V Funt3
****************************************************************************************************************************/
  // control flow //
  `define FUNCT3_BEQ    3'b000 // branch if equal
  `define FUNCT3_BNE    3'b001 // branch if not equal
  `define FUNCT3_BLT    3'b100 // branch if less than
  `define FUNCT3_BGE    3'b101 // branch if greater than or equal
  `define FUNCT3_BLTU   3'b110 // branch if less than (unsigned)
  `define FUNCT3_BGEU   3'b111 // branch if greater than or equal (unsigned)
  // memory access //
  `define FUNCT3_LB     3'b000 // load byte (signed)
  `define FUNCT3_LH     3'b001 // load half word (signed)
  `define FUNCT3_LW     3'b010 // load word (signed)
  `define FUNCT3_LBU    3'b100 // load byte (unsigned)
  `define FUNCT3_LHU    3'b101 // load half word (unsigned)
  `define FUNCT3_LWU    3'b110 // load word (unsigned)
  `define FUNCT3_SB     3'b000 // store byte
  `define FUNCT3_SH     3'b001 // store half word
  `define FUNCT3_SW     3'b010 // store word
  // alu //
  `define FUNCT3_SUBADD 3'b000 // sub/add via funct7
  `define FUNCT3_SLL    3'b001 // shift logical left
  `define FUNCT3_SLT    3'b010 // set on less
  `define FUNCT3_SLTU   3'b011 // set on less unsigned
  `define FUNCT3_XOR    3'b100 // xor
  `define FUNCT3_SR     3'b101 // shift right via funct7
  `define FUNCT3_OR     3'b110 // or
  `define FUNCT3_AND    3'b111 // and
  // system/csr //
  `define FUNCT3_ENV    3'b000 // ecall, ebreak, mret, wfi, ...
  `define FUNCT3_CSRRW  3'b001 // csr r/w
  `define FUNCT3_CSRRS  3'b010 // csr read & set
  `define FUNCT3_CSRRC  3'b011 // csr read & clear
  `define FUNCT3_CSRIL  3'b100 // undefined/illegal csr command
  `define FUNCT3_CSRRWI 3'b101 // csr r/w immediate
  `define FUNCT3_CSRRSI 3'b110 // csr read & set immediate
  `define FUNCT3_CSRRCI 3'b111 // csr read & clear immediate
  // fence //
  `define FUNCT3_FENCE  3'b000 // fence - order IO/memory access
  `define FUNCT3_FENCEI 3'b001 // fence.i - instruction stream sync

/****************************************************************************************************************************
    RISC-V Funct12
****************************************************************************************************************************/
  `define FUNCT12_ECALL  12'h000 // ecall
  `define FUNCT12_EBREAK 12'h001 // ebreak
  `define FUNCT12_WFI    12'h105 // wfi
  `define FUNCT12_MRET   12'h302 // mret
  `define FUNCT12_DRET   12'h7b2 // dret

`endif