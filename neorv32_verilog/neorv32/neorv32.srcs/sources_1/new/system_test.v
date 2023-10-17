`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2023 05:53:16 PM
// Design Name: 
// Module Name: system_test
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


module system_test(
        input wire i_clk,
        input wire i_rstn,
        input  wire [31:0] i_adr,
        output wire [31:0] o_rdata
    );
    
    localparam XLEN = 32;
    
    // Instruction bus interface
    wire [XLEN-1:0]  ibus_req_addr;
    wire [XLEN-1:0]  ibus_req_data;
    wire [3:0]       ibus_req_ben;
    wire             ibus_req_we;
    wire             ibus_req_re;
    wire             ibus_req_src;
    wire             ibus_req_priv;
    wire             ibus_req_rvso; 
    wire [XLEN-1:0]  ibus_resp_data;
    wire             ibus_resp_ack;
    wire             ibus_resp_err;
    // Data bus interface
    wire [XLEN-1:0]  dbus_req_addr;
    wire [XLEN-1:0]  dbus_req_data;
    wire [3:0]       dbus_req_ben;
    wire             dbus_req_we;
    wire             dbus_req_re;
    wire             dbus_req_src;
    wire             dbus_req_priv;
    wire             dbus_req_rvso;
    wire [XLEN-1:0]  dbus_resp_data;
    wire             dbus_resp_ack;
    wire             dbus_resp_err;
        
    rv32_cpu # (
        .CPU_EXTENSION_RISCV_A        (0),
        .CPU_EXTENSION_RISCV_C        (0),
        .CPU_EXTENSION_RISCV_M        (0),
        .CPU_EXTENSION_RISCV_U        (0),
        .CPU_EXTENSION_RISCV_F        (0),
        .CPU_EXTENSION_RISCV_D        (0),
        .CPU_EXTENSION_RISCV_Zicntr   (0),
        .CPU_EXTENSION_RISCV_Zifencei (0),
        .CPU_EXTENSION_RISCV_Zmmul    (1),
        .CPU_EXTENSION_RISCV_Zxcfu    (0),
        .CPU_EXTENSION_RISCV_Sdext    (0),
        .CPU_EXTENSION_RISCV_Sdtrig   (0),
        .FAST_MUL_EN                  (1),
        .FAST_SHIFT_EN                (1),
        .PMP_NUM_REGIONS              (0),
        .RS3_EN                       (0),
        .RS4_EN                       (0),
        .RF_LATCH                     (0)    
    ) cpu (
        // Global control
        .i_clk              (i_clk  ),
        .i_rstn             (i_rstn ),
        // Control signals
        .o_sleep            ( ), // cpu is in sleep mode when set
        .o_debug            ( ), // cpu is in debug mode when set
        .o_ifence           ( ), // instruction fence
        .o_dfence           ( ), // data fence
        // Interrupts
        .i_msi              (1'b0  ), // risc-v machine software interrupt
        .i_mei              (1'b0  ), // risc-v machine external interrupt
        .i_mti              (1'b0  ), // risc-v machine timer interrupt
        .i_firq             (16'd0 ), // custom fast interrupts
        .i_dbi              (1'b0  ), // risc-v debug halt request interrupt
        // Instruction bus interface
        .o_ibus_req_addr    (ibus_req_addr  ),
        .o_ibus_req_data    (ibus_req_data  ),
        .o_ibus_req_ben     (ibus_req_ben   ),
        .o_ibus_req_we      (ibus_req_we    ),
        .o_ibus_req_re      (ibus_req_re    ),
        .o_ibus_req_src     (ibus_req_src   ),
        .o_ibus_req_priv    (ibus_req_priv  ),
        .o_ibus_req_rvso    (ibus_req_rvso  ), 
        .i_ibus_resp_data   (ibus_resp_data ),
        .i_ibus_resp_ack    (ibus_resp_ack  ),
        .i_ibus_resp_err    (1'b0           ),
        // Data bus interface
        .o_dbus_req_addr    (dbus_req_addr  ),
        .o_dbus_req_data    (dbus_req_data  ),
        .o_dbus_req_ben     (dbus_req_ben   ),
        .o_dbus_req_we      (dbus_req_we    ),
        .o_dbus_req_re      (dbus_req_re    ),
        .o_dbus_req_src     (dbus_req_src   ),
        .o_dbus_req_priv    (dbus_req_priv  ),
        .o_dbus_req_rvso    (dbus_req_rvso  ),
        .i_dbus_resp_data   (dbus_resp_data ),
        .i_dbus_resp_ack    (dbus_resp_ack  ),
        .i_dbus_resp_err    (1'b0           )    
    );
    
    wb_ram # (
        .depth (8*1024)
    ) imem (
        .i_wb_clk  (i_clk           ),
        .i_wb_rstn (i_rstn          ),
        .i_wb_adr  (ibus_req_addr   ),
        .i_wb_dat  (ibus_req_data   ),
        .i_wb_sel  (ibus_req_ben    ),
        .i_wb_we   (1'b0            ),
        .i_wb_cyc  (ibus_req_re     ),
        .o_wb_rdt  (ibus_resp_data  ),
        .o_wb_ack  (ibus_resp_ack   )
    );
    
    wb_dpram # (
        .depth (8*1024)
    ) dmem (
        .i_wb_clk  (i_clk           ),
        .i_wb_rstn (i_rstn          ),
        .i_wb_adr  (dbus_req_addr   ),
        .i_wb_dat  (dbus_req_data   ),
        .i_wb_sel  (dbus_req_ben    ),
        .i_wb_we   (dbus_req_we     ),
        .i_wb_cyc  (dbus_req_re || dbus_req_we ),
        .o_wb_rdt  (dbus_resp_data  ),
        .o_wb_ack  (dbus_resp_ack   ),
        .i_adr     (i_adr           ),
        .o_rdata   (o_rdata         )
    );
    
endmodule
