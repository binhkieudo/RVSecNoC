module ip_fifo #(
    parameter FIFO_DEPTH    = 128, // number of fifo entries; has to be a power of two; min 1
    parameter FIFO_LOGDEPTH = $clog2(FIFO_DEPTH),
    parameter FIFO_WIDTH    = 32,  // size of data elements in fifo
    parameter FIFO_RSYNC    = 1,   // 0 = async read; 1 = sync read
    parameter FIFO_SAFE     = 1    // 1 = allow read/write only if entry available
)
(
    // Global control
    input  wire                  i_clk,   // global clock, rising edge
    input  wire                  i_rstn,  // global reset, low-active, async
    // Control signal
    input  wire                  i_clear, // sync reset, high-active
    output reg                   o_half,  // FIFO is half full
    // Write port
    input  wire [FIFO_WIDTH-1:0] i_wdata, // write data
    input  wire                  i_we,    // write enable
    output reg                   o_free,  // at least one entry is free when set
    // Read port
    input  wire                  i_re,    // read enable
    output reg [FIFO_WIDTH-1:0]  o_rdata, // read data
    output reg                   o_avail  // data available when set
);

    reg [FIFO_WIDTH-1:0] data [0:FIFO_DEPTH-1];
    reg [FIFO_WIDTH-1:0] dbuf; // when only 1 entry

    reg [FIFO_LOGDEPTH:0] w_pnt; // write pointer
    reg [FIFO_LOGDEPTH:0] r_pnt; // read pointer
    
    wire we; // write enable
    wire re; // read enable
    wire match;
    wire empty;
    wire full;
    wire half;
    wire free;
    wire avail;

    wire [FIFO_LOGDEPTH:0] diff;

    // Access control
    assign re = (FIFO_SAFE == 1)? (i_re && avail): i_re;
    assign we = (FIFO_SAFE == 1)? (i_we && free): i_we;

    // FIFO pointer
    always @(posedge i_clk, negedge i_rstn) begin
        if (!i_rstn) begin
            w_pnt <= {1'b0, {FIFO_LOGDEPTH{1'b0}}};
            r_pnt <= {1'b0, {FIFO_LOGDEPTH{1'b0}}};
        end
        else begin
            if (i_clear) w_pnt <= {1'b0, {FIFO_LOGDEPTH{1'b0}}};
            else if (we) w_pnt <= w_pnt + 1'b1;

            if (i_clear) r_pnt <= {1'b0, {FIFO_LOGDEPTH{1'b0}}};
            else if (re) r_pnt <= r_pnt + 1'b1;
        end
    end

    // FIFO status
    generate
        if (FIFO_DEPTH > 1) begin: gen_fifo_status
            assign match = r_pnt[FIFO_LOGDEPTH-1:0] == w_pnt[FIFO_LOGDEPTH-1:0];
            assign full  = (r_pnt[FIFO_LOGDEPTH] != w_pnt[FIFO_LOGDEPTH]) && match;
            assign empty = (r_pnt[FIFO_LOGDEPTH] == w_pnt[FIFO_LOGDEPTH]) && match;
            assign diff  = w_pnt - r_pnt;
            assign half  = diff[FIFO_LOGDEPTH-1] || full; 
        end
        else begin: gen_buf_status
            assign match = r_pnt[0] == w_pnt[0];
            assign full  = !match;
            assign empty = match;
            assign diff  = 2'b00;
            assign half  = full;
        end

        assign free  = !full;
        assign avail = !empty;

        if (FIFO_RSYNC == 0) begin: gen_async_stats
            always @(*) begin
                o_free  = free;
                o_avail = avail;
                o_half  = half;
            end
        end
        else begin: gen_sync_stats
            always @(posedge i_clk, negedge i_rstn) begin
                if (!i_rstn) begin
                    o_free  <= 1'b0;
                    o_avail <= 1'b0;
                    o_half  <= 1'b0;                    
                end
                else begin
                    o_free  <= free;
                    o_avail <= avail;
                    o_half  <= half;                      
                end
            end
        end
    endgenerate

    // FIFO access
    generate
        if (FIFO_DEPTH > 1) begin: gen_fifo_access
            // Write
            always @(posedge i_clk)
                if (we) data[w_pnt[FIFO_LOGDEPTH-1:0]] <= i_wdata;

            // Read
            if (FIFO_RSYNC == 1) begin: gen_sync_read
                always @(posedge i_clk)
                    o_rdata <= data[r_pnt[FIFO_LOGDEPTH-1:0]];
            end
            else begin: gen_async_read
                always @(*)
                    o_rdata = data[r_pnt[FIFO_LOGDEPTH-1:0]];
            end
        end
        else begin: gen_buf_access
             // Write
            always @(posedge i_clk)
                if (we) dbuf <= i_wdata;

            // Read
            if (FIFO_RSYNC == 1) begin: gen_sync_read
                always @(posedge i_clk)
                    o_rdata <= dbuf;
            end
            else begin: gen_async_read
                always @(*)
                    o_rdata = dbuf;
            end           
        end
    endgenerate

endmodule
