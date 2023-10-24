`timescale 1ns/1ps

module obi_cdc_fast_primary (
    // Controller (Primary) OBI interface
    input               ctrl_clk_i,
    input               ctrl_req_i,
    output wire         ctrl_gnt_o,
    input        [31:0] ctrl_addr_i,
    input               ctrl_we_i,
    input        [3:0]  ctrl_be_i,
    input        [31:0] ctrl_wdata_i,
    output reg          ctrl_rvalid_o,
    output wire  [31:0] ctrl_rdata_o,

    // Peripheral (Secondary) OBI interface
    input               secondary_clk_i,
    output reg          secondary_req_o,
    input               secondary_gnt_i,
    output wire  [31:0] secondary_addr_o,
    output wire         secondary_we_o,
    output wire  [3:0]  secondary_be_o,
    output wire  [31:0] secondary_wdata_o,
    input               secondary_rvalid_i,
    input        [31:0] secondary_rdata_i
);
    
    reg req_ff1, rvalid_ff1, gnt_ff1, gnt_ff2, gnt_ff3;

    /////////////////////////
    // Transaction Tracker //
    /////////////////////////

    /* This module must account for the latency between a transaction being
       acccepted by the secondary bus and the primary bus receiving a grant.
       To avoid duplicate transactions, secondary_req_o must be blocked for
       the round trip time for a grant to return to the controller (3 fast clk)
       and for the updated req signal to propagate (2 slow clk)  */

    // ...

    ///////////////////////////
    // Secondary bus outputs //
    ///////////////////////////

    assign secondary_addr_o  = ctrl_addr_i;
    assign secondary_we_o    = ctrl_we_i;
    assign secondary_be_o    = ctrl_be_i;
    assign secondary_wdata_o = ctrl_wdata_i;

    always @(posedge secondary_clk_i) begin
        secondary_req_o <= req_ff1;
        req_ff1 <= ctrl_req_i;
    end

    /////////////////////////
    // Primary bus outputs //
    /////////////////////////

    assign ctrl_rdata_o = secondary_rdata_i;
    assign ctrl_gnt_o = gnt_ff3 && !gnt_ff2;

    always @(posedge ctrl_clk_i) begin
        gnt_ff3 <= gnt_ff2;
        gnt_ff2 <= gnt_ff1;
        gnt_ff1 <= secondary_gnt_i;

        ctrl_rvalid_o <= rvalid_ff1;
        rvalid_ff1 <= secondary_rvalid_i;
    end

endmodule
