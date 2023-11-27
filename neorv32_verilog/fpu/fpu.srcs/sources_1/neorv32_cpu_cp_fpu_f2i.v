module neorv32_cpu_cp_fpu_f2i (
    input  wire i_clk,
    input  wire i_rstn,
    input  wire i_start,
    input  wire i_abort,
    input  wire [2:0] i_rmode,
    input  wire       i_funct,
    // Input
    input  wire i_sign,
    input  wire i_exponent,
    input  wire i_matissa,
    input  wire i_class,
    // Output
    output wire [31:0] o_result,
    output wire [4:0]  o_flags,
    output wire        o_done
)

    parameter S_IDLE         = 0
            S_PREPARE_F2I    = 1,
            S_NORMALIZE_BUSY = 2,
            S_ROUND          = 3,
            S_FINALIZE       = 4;

    reg [2:0]  ctrl_state;
    reg        ctrl_unsign;
    reg        ctrl_sign;
    reg [7:0]  ctrl_count;
    reg [9:0]  ctrl_class;
    reg        ctrl_rounded;
    reg        ctrl_over;
    reg        ctrl_under;
    reg [31:0] ctrl_result_tmp;
    reg [31:0] ctrl_result;

    reg [31:0] sreg_int;
    reg [22:0] sreg_mant;
    reg        sreg_ext_g;
    reg        sreg_ext_r;
    reg        sreg_ext_s;

    reg        round_en;
    reg        round_sub;
    reg [32:0] round_out;

    always @(posedge i_clk) begin
        if (!i_rstn) begin
            ctrl_state <= S_IDLE;
            ctrl_count <= 8'd0;
            ctrl_sign  <= 1'b0;
            ctrl_class <= 10'd0;
            ctrl_rounded <= 1'b0;
            ctrl_over   <= 1'b0;
            ctrl_under  <= 1'b0;
            ctrl_unsign <= 1'b0;
            ctrl_result <= 32'd0;
            ctrl_result_tmp <= 32'd0;
            sreg_int        <= 32'd0;
            sreg_mant       <= 23'd0;
            sreg_ext_s      <= 1'b0;
            o_done          <= 1'b0;
        end
        else begin
            
        end
    end

endmodule
