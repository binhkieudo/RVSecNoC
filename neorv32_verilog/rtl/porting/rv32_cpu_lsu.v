module rv32_cpu_lsu #(
    parameter XLEN      = 32,
    parameter AMO_LRSC  = 1
)
(
    // Global control
    input wire i_clk,
    input wire i_rstn,
    // Control signals
    input wire [2:0] i_ir_func3,
    input wire [6:0] i_ir_opcode,
    input wire       i_ctrl_cpu_trap,
    input wire       i_ctrl_lsu_mo_we, // memory address and data output register write enable
    input wire       i_ctrl_lsu_priv,  // effective privilege level for load/store
    input wire       i_ctrl_lsu_req_rd, // memory read request
    input wire       i_ctrl_lsu_req_wr, // memory write request
    // Data access interface
    input wire [XLEN-1:0] i_addr, // address access
    input wire [XLEN-1:0] i_wdata, // write data
    output reg [XLEN-1:0] o_rdata, // read data
    output wire [XLEN-1:0] o_mar, // current memory address register
    output wire o_wait, // wait for access to complete
    output wire o_ma_load, // missaligned load data address
    output wire o_ma_store, // missaligned store data access
    output wire o_be_load, // bus error on load data access
    output wire o_be_store, // bus error on store data access
    input wire i_pmp_r_fault, // PMP read fault
    input wire i_pmp_w_fault, // PMP write fault
    // Data bus
    output wire [XLEN-1:0] o_bus_req_addr, // access address
    output reg [XLEN-1:0]  o_bus_req_data, // write data
    output reg [3:0]       o_bus_req_ben,  // byte enable
    output wire            o_bus_req_we,   // write request
    output wire            o_bus_req_re,   // read request
    output wire            o_bus_req_src,  // access source (1=instruction fetch, 0=data access)
    output reg             o_bus_req_priv, // set if privileged (machine-mode) access
    output reg             o_bus_req_rvso, // set if reservation set operation (atomic LR/SC)
    input wire  [XLEN-1:0] i_bus_rsp_data, // read data
    input wire             i_bus_rsp_ack,  // access acknowledge
    input wire             i_bus_tsp_err   // access error
);

    localparam OP_AMO = 7'b0101111; // atomic memory access

    reg arbiter_pend_rd; // pending bus read access
    reg arbiter_pend_wr; // pending bus write accesss
    reg arbiter_bus_err; // bus access error

    reg [XLEN-1:0] mar; // data memory address register
    reg missaligned; // misaligned address

    wire sign_bit;
    wire sign_extend;

    // Access address
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            mar <= {XLEN{1'b0}};
            misaligned <= 1'b0;
        end
        else begin
            mar <= i_addr;
            case (i_ir_func3[1:0])
                2'b00: misaligned <= 1'b0;
                2'b01: misaligned <= i_addr[0]; // half word
                2'b10: misaligned <= i_addr[1] or i_addr[0]; // word
                default: misaligned <= 1'b0;
            endcase 
        end
    end

    // Address output
    assign o_bus_req_addr   = mar;
    assign o_mar            = mar; // for MTVAL

    // Access type
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            o_bus_req_priv <= 1'b0;
            o_bus_req_rvso <= 1'b0;
        end    
        else begin
            if (i_ctrl_lsu_mo_we) begin
                // Privilege level
                o_bus_req_priv <= i_ctrl_lsu_priv;
                // Reservation set opration
                if (AMO_LRSC == 1)
                    o_bus_req_rvso <= i_ir_opcode[2] == OP_AMO[2];
                else
                    o_bus_req_rvso <= 1'b0;
            end
        end
    end

    // Source identifier
    assign o_bus_req_src = 1'b0; // data access

    // Write data: Alignment and Byte enable
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            o_bus_req_data <= {XLEN{1'b0}};
            o_bus_req_ben  <= 4'b0000;
        end
        else begin
            if (i_ctrl_lsu_mo_we) begin
                case (i_ir_func3[1:0])
                    2'b00: begin // byte
                        o_bus_req_data <= {4{i_wdata[7:0]}};
                        o_bus_req_ben  <= { i_addr[1:0] == 2'b11,
                                            i_addr[1:0] == 2'b10,
                                            i_addr[1:0] == 2'b01,
                                            i_addr[1:0] == 2'b00};   
                    end
                    2'b01: begin // halft word
                        o_bus_req_data <= {2{i_wdata[15:0]}};
                        o_bus_req_ben  <= {i_addr[1], i_addr[1], !i_addr[1], !i_addr[1]};
                    end
                    default: begin
                        o_bus_req_data <= i_wdata;
                        o_bus_req_ben  <= 4'b1111;
                    end
                endcase
            end
        end
    end

    assign sign_bit     = (mar[1:0] == 2'b01)? i_bus_rsp_data[15]:
                          (mar[1:0] == 2'b10)? (i_ir_func3[0]? i_bus_rsp_data[31]: i_bus_rsp_data[23]):
                          (mar[1:0] == 2'b11)? i_bus_rsp_data[31]:
                                               (i_ir_func3[0]? i_bus_rsp_data[15]: i_bus_rsp_data[7]); 
    assign sign_extend  = !i_ir_func3[2] && sign_bit;

    // Read data: Alignment and Sign-Extension
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            o_rdata <= {XLEN{1'b0}};
        end
        else begin
            if ((arbiter_pend_rd) || ((AMO_LRSC == 1) && arbiter_pend_wr)) begin
                case (i_ir_func3[1:0])
                    2'b00: begin // byte
                        o_rdata[7:0] <= (mar[1:0] == 2'b01)? i_bus_rsp_data[15:8]:
                                        (mar[1:0] == 2'b10)? i_bus_rsp_data[23:16]:
                                        (mar[1:0] == 2'b11)? i_bus_rsp_data[31:24]:
                                                             i_bus_rsp_data[7:0];
                        o_rdata[XLEN-1:8] <= {24{sign_extend}};
                    end
                    2'b01: begin // half word
                        o_rdata[15:0] <= mar[1]? i_bus_rsp_data[31:16]? i_bus_rsp_data[15:0];
                        o_rdata[XLEN-1:16] <= {16{sign_extend}};
                    end
                    default: // word
                        o_rdata <= i_bus_rsp_data;
                endcase
            end
        end
    end

    // Access Arbiter
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            arbiter_bus_err <= 1'b0;
            arbiter_pend_rd <= 1'b0;
            arbiter_pend_wr <= 1'b0;
        end
        else begin
            arbiter_bus_err <= i_bus_tsp_err && (arbiter_pend_rd || arbiter_pend_wr); // bus error during access
            if (!arbiter_pend_rd && !arbiter_pend_wr) begin
                arbiter_pend_rd <= i_ctrl_lsu_req_rd;
                arbiter_pend_wr <= i_ctrl_lsu_req_wr;
            end
            else if (i_bus_rsp_ack || i_ctrl_cpu_trap) begin
                arbiter_pend_rd <= 1'b0;
                arbiter_pend_wr <= 1'b0;
            end
        end
    end

    // Wait for bus response
    assign o_wait = !i_bus_rsp_ack;

    // Output data access/alignment errors to control unit
    assign o_ma_load = arbiter_pend_rd && misaligned;
    assign o_be_load = arbiter_pend_rd && (arbiter_bus_err || i_pmp_r_fault);
    assign o_ma_store = arbiter_pend_wr && misaligned;
    assign o_be_store = arbiter_pend_wr && (arbiter_bus_err || i_pmp_w_fault);

endmodule
