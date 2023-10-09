module rv32_cpu_cp_div_ser #(
    parameter XLEN = 32
)
(
    // Global control
    input  wire              i_clk,
    input  wire              i_rstn,
    // Control signals
    input  wire              i_start,
    input  wire              i_cpu_trap,
    input  wire [2:0]        i_div_op,
    // Input data
    input  wire [XLEN-1:0]   i_rs1,
    input  wire [XLEN-1:0]   i_rs2,
    // Output data
    output wire [XLEN-1:0]   o_res,
    output wire              o_valid
);

    localparam DIV_OP    = 3'b100,
               DIVU_OP   = 3'b101,
               REM_OP    = 3'b110,
               REMU_OP   = 3'b111;

    localparam S_IDLE = 2'b00,
               S_BUSY = 2'b01,
               S_DONE = 2'b10,
               S_READY = 2'b11;

    reg sign_mod;
    reg [XLEN-1:0] rs2_abs;
    wire [XLEN-1:0] res_u;
    wire [XLEN-1:0] res;

    reg [XLEN-1:0] remainder;
    reg [XLEN-1:0] quotient;
    wire [XLEN:0]   sub;

    reg [1:0] state, next;

    wire rs1_is_signed = (i_mul_op == DIV_OP) || (i_mul_op == REM_OP);
    wire rs2_is_signed = (i_mul_op == DIV_OP) || (i_mul_op == REM_OP);

    assign sub = {1'b0, remainder[30:0], quotient[31]} - {1'b0, rs2_abs};

    assign res_u = i_div_op[1]? remainder: quotient;
    assign res   = sign_mod? -res_u: res_u;

    always @(posedge i_clk, negedge i_rstn)
        if (!i_rstn) state <= S_IDLE;
        else state <= next;

    always @(*) begin
        case (state)
            S_IDLE: next = i_start? S_BUSY: S_IDLE;
            S_BUSY: next = (!(|r_cnt) || i_cpu_trap)? S_DONE: S_BUSY;
            S_DONE: next = S_READY;
            S_READY: next = S_IDLE;
            default: next = S_IDLE;
        endcase
    end

    always @(posedge i_clk, negedge i_rstn)
        if (!i_rstn) begin
            sign_mod <= 1'b0;
            rs2_abs  <= {XLEN{1'b0}};
        end
        else if ((state == S_IDLE) && i_start) begin
            sign_mod <= (i_div_op == DIV_OP)? (i_rs1[XLEN-1] ^ i_rs2[XLEN-1]) & (|i_rs2):
                       (i_div_op == REM_OP)?  i_rs1[XLEN-1]: 1'b0;

            rs2_abs <= (i_rs2[XLEN-1] && rs2_is_signed)? -i_rs2: i_rs2;
        end

    always @(posedge i_clk)
        if (state == S_IDLE) r_cnt <= 5'd30;
        else r_cnt <= r_cnt - 5'd1;

    always @(posedge i_clk) begin
        if ((state == S_IDLE) && i_start) begin
            quotient <= (i_rs1[XLEN-1] && rs1_is_signed)? -i_rs1: i_rs1;
            remainder <= {XLEN{1'b0}};
        end
        else if ((state == S_BUSY) || (state == S_DONE)) begin
            quotient <= {quotient[30:0], ~sub[32]};
            remainder <= !sub[32]? sub[31:0]? {remainder[30:0], quotient[31]};
        end
    end

    assign o_res = res;
    assign o_valid = state == S_READY;

endmodule