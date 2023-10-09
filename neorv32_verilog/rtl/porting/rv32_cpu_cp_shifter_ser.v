module rv32_cpu_cp_shifter_ser #(
    parameter XLEN = 32
)
(
    // Global control    
    input wire i_clk, // global clock, rising edge
    input wire i_rstn, // global reset, active low, async
    // Control signals
    input wire i_cpu_trap, // set when CPU is entering trap exec
    input wire i_shift_right, // shift left operation
    input wire i_shift_arth, // shift logical (only for shift right)
    input wire i_start, // start operation
    // Data input
    input wire [XLEN-1:0] i_rs1, // rf source 1
    input wire [4:0] i_shamt, // shift amount
    // Results and status
    output wire [XLEN-1:0] o_res, // result
    output wire o_valid // output valid
);

    wire done;

    reg r_busy;
    reg [4:0] r_cnt;
    reg [XLEN-1:0] ro_res;

    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            r_busy <= 1'b0;
            r_cnt <= 1'b0;
            ro_res <= {XLEN{1'b0}};
        end
        else begin
            // Busy flag
            if (i_start)
                r_busy <= 1'b1;
            else if (done || i_cpu_trap)
                r_busy <= 1'b0;
            
            // Shift process
            if (i_start) begin
                r_cnt <= i_shamt;
                ro_res <= i_rs1;
            end
            else if (|r_cnt) begin
                r_cnt <= r_cnt - 5'd1;
                if (i_shift_right)
                    ro_res <= {ro_res[XLEN-1] & i_shift_arth, ro_res[XLEN-1:1]};
                else
                    ro_res <= {ro_res[XLEN-2:0], 1'b0};
            end
        end
    end

    assign done = r_cnt == 5'd1;
    assign o_valid = r_busy && done;
    assign o_res = ro_res;

endmodule