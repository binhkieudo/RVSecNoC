`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2023 11:21:03 AM
// Design Name: 
// Module Name: rv32_cpu_cp_mul_dsp
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

module rv32_cpu_cp_mul_dsp #(
    parameter XLEN = 32,
    parameter PIPELINE = 0
)
(
    // Global control
    input  wire              i_clk,
    input  wire              i_rstn,
    // Control signals
    input  wire              i_start,
    input  wire [2:0]        i_mul_op, 
    // Input data
    input  wire [XLEN-1:0]   i_rs1,
    input  wire [XLEN-1:0]   i_rs2,
    // Output data
    output wire [XLEN-1:0]   o_prod,
    output wire              o_valid
);

    localparam MUL_OP    = 3'b000,
               MULH_OP   = 3'b001,
               MULHSU_OP = 3'b010,
               MULHU_OP  = 3'b011;

    reg [XLEN:0] dsp_x;
    reg [XLEN:0] dsp_y;
    wire [2*XLEN+1:0] dsp_z;
    reg [2*XLEN-1:0] ro_prod;

    wire rs1_is_signed = (i_mul_op == MULH_OP) || (i_mul_op == MULHSU_OP);
    wire rs2_is_signed = (i_mul_op == MULH_OP);
    
    generate
        if (PIPELINE == 1) begin
            always @(posedge i_clk) begin: gen_seq
                if (i_start) begin
                    dsp_x <= {i_rs1[XLEN-1] & rs1_is_signed, i_rs1};
                    dsp_y <= {i_rs2[XLEN-1] & rs2_is_signed, i_rs2};
                end
                ro_prod <= dsp_z[2*XLEN-1:0];
            end
        end
        else begin
            always @(*) begin: gen_seq
                dsp_x = {i_rs1[XLEN-1] & rs1_is_signed, i_rs1};
                dsp_y = {i_rs2[XLEN-1] & rs2_is_signed, i_rs2};    
            end
            
            always @(*) ro_prod = dsp_z[2*XLEN-1:0];
        end
    endgenerate

    assign dsp_z = dsp_x * dsp_y;

    assign o_valid = i_start;
    assign o_prod = (|i_mul_op[1:0])? ro_prod[63:32]: ro_prod[31:0];

endmodule
