module rv32_cpu_cp_fpu #(
    parameter XLEN = 32
)

(
    // Global control
    input wire i_clk, // global clock, rising edge
    input wire i_rstn, // global reset, low-active, async
    // Control signals
    input wire i_start, // start operation
    // CSR interface
    input wire i_csr_we, // enable write csr
    input wire [11:0] i_csr_addr, // csr address
    input wire [XLEN-1:0] i_csr_wdata, // write data
    output wire [XLEN-1:0] o_csr_rdata, // read data
    // Input data
    input wire [1:0] i_cmp, // comparator status
    input wire [XLEN-1:0] i_rs1, // rf source 1
    input wire [XLEN-1:0] i_rs2, // rf source 2
    input wire [XLEN-1:0] i_rs3, // rf source 3
    // Result and status
    output wire [XLEN-1:0] o_res,
    output wire o_valid
);

    

endmodule
