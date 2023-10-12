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
    ALU Function Codes
****************************************************************************************************************************/
  `define ALU_OP_ADD  3'b000 // result <= A + B
  `define ALU_OP_SUB  3'b001 // result <= A - B
  `define ALU_OP_CP   3'b010 // result <= ALU co-processor
  `define ALU_OP_SLT  3'b011 // result <= A < B
  `define ALU_OP_MOVB 3'b100 // result <= B
  `define ALU_OP_XOR  3'b101 // result <= A xor B
  `define ALU_OP_OR   3'b110 // result <= A or B
  `define ALU_OP_AND  3'b111 // result <= A and B

/****************************************************************************************************************************
    CPU Co-Processor control
****************************************************************************************************************************/
  `define CP_SEL_SHIFT     0 // CP0: shift operations (base ISA)
  `define CP_SEL_MUL       1 // CP1: multiplication operations ('M/Zmul' extensions)
  `define CP_SEL_DIV       2 // CP2: division operations ('M')
  `define CP_SEL_FPU       3 // CP3: floating-point unit ('F/D' extension)
  `define CP_SEL_CFU       4 // CP4: custom instructions CFU ('Zxcfu' extension)

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

/****************************************************************************************************************************
  -- Register File Input Select -------------------------------------------------------------
****************************************************************************************************************************/
  `define RF_MUX_ALU 2'b00 // register file <= alu result
  `define RF_MUX_MEM 2'b01 // register file <= memory read data
  `define RF_MUX_CSR 2'b10 // register file <= CSR read data
  `define RF_MUX_NPC 2'b11 // register file <= next-PC (for branch-and-link)

/****************************************************************************************************************************
    RISC-V Floating-Point Stuff ------------------------------------------------------------
****************************************************************************************************************************/
  `define FLOAT_SINGLE 2'b00 // single-precision (32-bit)
  `define FLOAT_DOUBLE 2'b01 // double-precision (64-bit)

  /**************************************************************************************************************************
  -- CPU Trap System 
  **************************************************************************************************************************/
  // exception source bits --
  `define EXC_IACCESS    0 // instruction access fault        
  `define EXC_ILLEGAL    1 // illegal instruction             
  `define EXC_IALIGN     2 // instruction address misaligned  
  `define EXC_ECALL      3 // environment call                
  `define EXC_EBREAK     4 // breakpoint                      
  `define EXC_SALIGN     5 // store address misaligned        
  `define EXC_LALIGN     6 // load address misaligned         
  `define EXC_SACCESS    7 // store access fault              
  `define EXC_LACCESS    8 // load access fault               
  // for debug mode only --
  `define EXC_DB_BREAK   9 // enter debug mode via ebreak instruction ("sync EXCEPTION")  
  `define EXC_DB_HW     10 // enter debug mode via hw trigger ("sync EXCEPTION")          
  `define EXC_WIDTH     11 // length of this list in bits 
  // interrupt source bits --
  `define IRQ_MSI        0 // machine software interrupt  
  `define IRQ_MTI        1 // machine timer interrupt     
  `define IRQ_MEI        2 // machine external interrupt  
  `define IRQ_FIRQ0      3 // fast interrupt channel 0    
  `define IRQ_FIRQ1      4 // fast interrupt channel 1    
  `define IRQ_FIRQ2      5 // fast interrupt channel 2    
  `define IRQ_FIRQ3      6 // fast interrupt channel 3    
  `define IRQ_FIRQ4      7 // fast interrupt channel 4    
  `define IRQ_FIRQ5      8 // fast interrupt channel 5    
  `define IRQ_FIRQ6      9 // fast interrupt channel 6    
  `define IRQ_FIRQ7     10 // fast interrupt channel 7    
  `define IRQ_FIRQ8     11 // fast interrupt channel 8    
  `define IRQ_FIRQ9     12 // fast interrupt channel 9    
  `define IRQ_FIRQ10    13 // fast interrupt channel 10   
  `define IRQ_FIRQ11    14 // fast interrupt channel 11   
  `define IRQ_FIRQ12    15 // fast interrupt channel 12   
  `define IRQ_FIRQ13    16 // fast interrupt channel 13   
  `define IRQ_FIRQ14    17 // fast interrupt channel 14   
  `define IRQ_FIRQ15    18 // fast interrupt channel 15   
  // for debug mode only --
  `define IRQ_DB_HALT   19 // enter debug mode via external halt request ("async IRQ")
  `define IRQ_DB_STEP   20 // enter debug mode via single-stepping ("async IRQ")
  //
  `define IRQ_WIDTH     21 // length of this list in bits
  

  /**************************************************************************************************************************
  -- CPU Privilege Modes
  **************************************************************************************************************************/
  `define PRIV_MODE_M   1  // Machine mode
  `define PRIV_MODE_U   0  // User mode

  /**************************************************************************************************************************
  -- Trap ID Codes
  -- MSB:   1 = interrupt, 0 = sync. exception
  -- MSB-1: 1 = entry to debug mode, 0 = normal trapping
  -- RISC-V compliant synchronous exceptions --
  **************************************************************************************************************************/
  `define TRAP_IMA       {1'b0 ,1'b0 ,5'b00000} // 0: instruction misaligned
  `define TRAP_IAF       {1'b0 ,1'b0 ,5'b00001} // 1: instruction access fault
  `define TRAP_IIL       {1'b0 ,1'b0 ,5'b00010} // 2: illegal instruction
  `define TRAP_BRK       {1'b0 ,1'b0 ,5'b00011} // 3: breakpoint
  `define TRAP_LMA       {1'b0 ,1'b0 ,5'b00100} // 4: load address misaligned
  `define TRAP_LAF       {1'b0 ,1'b0 ,5'b00101} // 5: load access fault
  `define TRAP_SMA       {1'b0 ,1'b0 ,5'b00110} // 6: store address misaligned
  `define TRAP_SAF       {1'b0 ,1'b0 ,5'b00111} // 7: store access fault
  `define TRAP_ENV       {1'b0 ,1'b0 ,3'b010}   // environment call from u/s/h/m
  `define TRAP_ENVU      {1'b0 ,1'b0 ,5'b01000} // 8..11: environment call from u
  `define TRAP_ENVS      {1'b0 ,1'b0 ,5'b01001} // 8..11: environment call from s
  `define TRAP_ENVH      {1'b0 ,1'b0 ,5'b01010} // 8..11: environment call from h
  `define TRAP_ENVM      {1'b0 ,1'b0 ,5'b01011} // 8..11: environment call from m
  // RISC-V compliant asynchronous exceptions (interrupts) --
  `define TRAP_MSI       {1'b1 ,1'b0 ,5'b00011} // 3:  machine software interrupt
  `define TRAP_MTI       {1'b1 ,1'b0 ,5'b00111} // 7:  machine timer interrupt
  `define TRAP_MEI       {1'b1 ,1'b0 ,5'b01011} // 11: machine external interrupt
  // NEORV32-specific (RISC-V custom) asynchronous exceptions (interrupts) --
  `define TRAP_FIRQ0     {1'b1 ,1'b0 ,5'b10000} // 16: fast interrupt 0
  `define TRAP_FIRQ1     {1'b1 ,1'b0 ,5'b10001} // 17: fast interrupt 1
  `define TRAP_FIRQ2     {1'b1 ,1'b0 ,5'b10010} // 18: fast interrupt 2
  `define TRAP_FIRQ3     {1'b1 ,1'b0 ,5'b10011} // 19: fast interrupt 3
  `define TRAP_FIRQ4     {1'b1 ,1'b0 ,5'b10100} // 20: fast interrupt 4
  `define TRAP_FIRQ5     {1'b1 ,1'b0 ,5'b10101} // 21: fast interrupt 5
  `define TRAP_FIRQ6     {1'b1 ,1'b0 ,5'b10110} // 22: fast interrupt 6
  `define TRAP_FIRQ7     {1'b1 ,1'b0 ,5'b10111} // 23: fast interrupt 7
  `define TRAP_FIRQ8     {1'b1 ,1'b0 ,5'b11000} // 24: fast interrupt 8
  `define TRAP_FIRQ9     {1'b1 ,1'b0 ,5'b11001} // 25: fast interrupt 9
  `define TRAP_FIRQ10    {1'b1 ,1'b0 ,5'b11010} // 26: fast interrupt 10
  `define TRAP_FIRQ11    {1'b1 ,1'b0 ,5'b11011} // 27: fast interrupt 11
  `define TRAP_FIRQ12    {1'b1 ,1'b0 ,5'b11100} // 28: fast interrupt 12
  `define TRAP_FIRQ13    {1'b1 ,1'b0 ,5'b11101} // 29: fast interrupt 13
  `define TRAP_FIRQ14    {1'b1 ,1'b0 ,5'b11110} // 30: fast interrupt 14
  `define TRAP_FIRQ15    {1'b1 ,1'b0 ,5'b11111} // 31: fast interrupt 15
  // entering debug mode (sync./async. exceptions) --
  `define TRAP_DB_BREAK  {1'b0 ,1'b1 ,5'b00001} // 1: break instruction (sync)
  `define TRAP_DB_TRIG   {1'b0 ,1'b1 ,5'b00010} // 2: hardware trigger (sync)
  `define TRAP_DB_HALT   {1'b1 ,1'b1 ,5'b00011} // 3: external halt request (async)
  `define TRAP_DB_STEP   {1'b1 ,1'b1 ,5'b00100} // 4: single-stepping (async) 

`endif