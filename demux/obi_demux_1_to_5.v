`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name: obi_demux_1_to_5
// Author: Peter Herrmann
//
// Description: This OBI (Open Bus Interface) demux accepts a single OBI master 
//              device to multiple OBI slave devices. It only supports a single 
//              outstanding read transaction at a time, meaning pipelined reads
//              are not supported.
//
//              It has been fully verified in actual crossbar systems.
//
//////////////////////////////////////////////////////////////////////////////////

module obi_demux_1_to_5 #(
        parameter PORT1_BASE_ADDR = 32'h00001000,
        parameter PORT1_END_ADDR  = 32'h00001FFF,
        parameter PORT2_BASE_ADDR = 32'h80000000,
        parameter PORT2_END_ADDR  = 32'h8000FFFF,
        parameter PORT3_BASE_ADDR = 32'h20000000,
        parameter PORT3_END_ADDR  = 32'h3FFFFFFF,
        parameter PORT4_BASE_ADDR = 32'h10000000,
        parameter PORT4_END_ADDR  = 32'h10001FFF,
        parameter PORT5_BASE_ADDR = 32'h30000000, // New port base address
        parameter PORT5_END_ADDR  = 32'h30001FFF  // New port end address
)
(
    input               clk_i,
    input               rst_ni,

    // Controller (Master) OBI interface
    input               ctrl_req_i,
    output reg          ctrl_gnt_o,
    input        [31:0] ctrl_addr_i,
    input               ctrl_we_i,
    input        [3:0]  ctrl_be_i,
    input        [31:0] ctrl_wdata_i,
    output reg          ctrl_rvalid_o,
    output reg   [31:0] ctrl_rdata_o,

    // Port 1 (Slave) OBI interface
    output reg          port1_req_o,
    input               port1_gnt_i,
    output wire  [31:0] port1_addr_o,
    output wire         port1_we_o,
    output wire  [3:0]  port1_be_o,
    output wire  [31:0] port1_wdata_o,
    input               port1_rvalid_i,
    input        [31:0] port1_rdata_i,

    // Port 2 (Slave) OBI interface
    output reg          port2_req_o,
    input               port2_gnt_i,
    output wire  [31:0] port2_addr_o,
    output wire         port2_we_o,
    output wire  [3:0]  port2_be_o,
    output wire  [31:0] port2_wdata_o,
    input               port2_rvalid_i,
    input        [31:0] port2_rdata_i,

    // Port 3 (Slave) OBI interface
    output reg          port3_req_o,
    input               port3_gnt_i,
    output wire  [31:0] port3_addr_o,
    output wire         port3_we_o,
    output wire  [3:0]  port3_be_o,
    output wire  [31:0] port3_wdata_o,
    input               port3_rvalid_i,
    input        [31:0] port3_rdata_i,

    // Port 4 (Slave) OBI interface
    output reg          port4_req_o,
    input               port4_gnt_i,
    output wire  [31:0] port4_addr_o,
    output wire         port4_we_o,
    output wire  [3:0]  port4_be_o,
    output wire  [31:0] port4_wdata_o,
    input               port4_rvalid_i,
    input        [31:0] port4_rdata_i,

    // Port 5 (Slave) OBI interface
    output reg          port5_req_o,
    input               port5_gnt_i,
    output wire  [31:0] port5_addr_o,
    output wire         port5_we_o,
    output wire  [3:0]  port5_be_o,
    output wire  [31:0] port5_wdata_o,
    input               port5_rvalid_i,
    input        [31:0] port5_rdata_i,

    output wire         illegal_access_o
);

    // Address and Response routing mux selections (0 = no route selected!)
    reg[3:0] addr_sel, resp_sel;

    /////////////////////
    // Address Decoder //
    /////////////////////

    // Generate address select signal based on input address
    /* verilator lint_off UNSIGNED */
    /* verilator lint_off CMPCONST */
    always @(*) begin
        if ((ctrl_addr_i >= PORT1_BASE_ADDR) && (ctrl_addr_i <= PORT1_END_ADDR))
            addr_sel = 1;
        else if ((ctrl_addr_i >= PORT2_BASE_ADDR) && (ctrl_addr_i <= PORT2_END_ADDR))
            addr_sel = 2;
        else if ((ctrl_addr_i >= PORT3_BASE_ADDR) && (ctrl_addr_i <= PORT3_END_ADDR))
            addr_sel = 3;
        else if ((ctrl_addr_i >= PORT4_BASE_ADDR) && (ctrl_addr_i <= PORT4_END_ADDR))
            addr_sel = 4;
        else if ((ctrl_addr_i >= PORT5_BASE_ADDR) && (ctrl_addr_i <= PORT5_END_ADDR)) // For Port 5
            addr_sel = 5;
        else
            addr_sel = 0;
    end
    /* verilator lint_on CMPCONST */
    /* verilator lint_on UNSIGNED */

    ///////////////////////////
    // Address Phase Routing //
    ///////////////////////////

    always @(*) begin
        // Multiplex portx_gnt_i to ctrl_gnt_o
        case (addr_sel)
            1: ctrl_gnt_o = port1_gnt_i;
            2: ctrl_gnt_o = port2_gnt_i;
            3: ctrl_gnt_o = port3_gnt_i;
            4: ctrl_gnt_o = port4_gnt_i;
            5: ctrl_gnt_o = port5_gnt_i; // For Port 5
            default: ctrl_gnt_o = 1; // DEADBEEF response
        endcase
    end

    always @(*) begin
        // Demultiplex ctrl_req_i to portx_req_o
        port1_req_o = (addr_sel == 1) ? ctrl_req_i : 1'b0;
        port2_req_o = (addr_sel == 2) ? ctrl_req_i : 1'b0;
        port3_req_o = (addr_sel == 3) ? ctrl_req_i : 1'b0;
        port4_req_o = (addr_sel == 4) ? ctrl_req_i : 1'b0;
        port5_req_o = (addr_sel == 5) ? ctrl_req_i : 1'b0; // For Port 5
    end

    // Assign ctrl signals to all portx outputs
    assign port1_addr_o  = ctrl_addr_i;
    assign port1_we_o    = ctrl_we_i;
    assign port1_be_o    = ctrl_be_i;
    assign port1_wdata_o = ctrl_wdata_i;

    assign port2_addr_o  = ctrl_addr_i;
    assign port2_we_o    = ctrl_we_i;
    assign port2_be_o    = ctrl_be_i;
    assign port2_wdata_o = ctrl_wdata_i;

    assign port3_addr_o  = ctrl_addr_i;
    assign port3_we_o    = ctrl_we_i;
    assign port3_be_o    = ctrl_be_i;
    assign port3_wdata_o = ctrl_wdata_i;

    assign port4_addr_o  = ctrl_addr_i;
    assign port4_we_o    = ctrl_we_i;
    assign port4_be_o    = ctrl_be_i;
    assign port4_wdata_o = ctrl_wdata_i;

    assign port5_addr_o  = ctrl_addr_i; // For Port 5
    assign port5_we_o    = ctrl_we_i;   // For Port 5
    assign port5_be_o    = ctrl_be_i;   // For Port 5
    assign port5_wdata_o = ctrl_wdata_i; // For Port 5

    ////////////////////////////
    // Response Phase Routing //
    ////////////////////////////

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            resp_sel <= 4'b0000;
        else if (ctrl_req_i && ctrl_gnt_o)
            resp_sel <= addr_sel;
        else if (!port1_req_o && port1_rvalid_i)
            resp_sel <= 4'b0000;
        else if (!port2_req_o && port2_rvalid_i)
            resp_sel <= 4'b0000;
        else if (!port3_req_o && port3_rvalid_i)
            resp_sel <= 4'b0000;
        else if (!port4_req_o && port4_rvalid_i)
            resp_sel <= 4'b0000;
        else if (!port5_req_o && port5_rvalid_i) // For Port 5
            resp_sel <= 4'b0000;
    end

    always @(*) begin
        // Multiplex portx_rvalid_i to ctrl_rvalid_o
        case (resp_sel)
            1: ctrl_rvalid_o = port1_rvalid_i;
            2: ctrl_rvalid_o = port2_rvalid_i;
            3: ctrl_rvalid_o = port3_rvalid_i;
            4: ctrl_rvalid_o = port4_rvalid_i;
            5: ctrl_rvalid_o = port5_rvalid_i; // For Port 5
            default: ctrl_rvalid_o = 1'b0;
        endcase
    end

    always @(*) begin
        // Multiplex portx_rdata_i to ctrl_rdata_o
        case (resp_sel)
            1: ctrl_rdata_o = port1_rdata_i;
            2: ctrl_rdata_o = port2_rdata_i;
            3: ctrl_rdata_o = port3_rdata_i;
            4: ctrl_rdata_o = port4_rdata_i;
            5: ctrl_rdata_o = port5_rdata_i; // For Port 5
            default: ctrl_rdata_o = 32'hDEADBEEF; // DEADBEEF response
        endcase
    end

    assign illegal_access_o = (ctrl_req_i && !ctrl_gnt_o);

endmodule
