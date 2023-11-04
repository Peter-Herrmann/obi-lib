`timescale 1ns/1ps
///////////////////////////////////////////////////////////////////////////////
//
// Module Name: obi_cdc_fast_primary
// Author: Peter Herrmann
//
// Description: This Open Bus Interface (OBI) clock domain crossing (CDC)
//              supports a single operation at a time with no pipelining. 
//              It only works for scenarios where the primary controller's
//              clock domain is as fast or faster than the secondary device's
//              clock domain.
//
// SPDX-License-Identifier: Apache-2.0
//
///////////////////////////////////////////////////////////////////////////////

module obi_cdc_fast_primary (
    input               rst_ni,

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
    output wire         secondary_req_o,
    input               secondary_gnt_i,
    output wire  [31:0] secondary_addr_o,
    output wire         secondary_we_o,
    output wire  [3:0]  secondary_be_o,
    output wire  [31:0] secondary_wdata_o,
    input               secondary_rvalid_i,
    input        [31:0] secondary_rdata_i
);
    
    reg gnt_in_flight,
        req_ff1, req_ff2,
        rvalid_ff1, 
        gnt_ack, gnt_ack_ff1, gnt_ack_ff2, gnt_ack_ff3,
        gnt_ff1, gnt_ff2, gnt_ff3,
        rst_n_ctrl_ff1, rst_n_ctrl_ff2,
        rst_n_secondary_ff1, rst_n_secondary_ff2;

    /////////////////////////
    // Transaction Tracker //
    /////////////////////////

    /* This module must account for the latency between a transaction being
       acccepted by the secondary bus and the primary bus receiving a grant. */

    /* verilator lint_off SYNCASYNCNET */
    /* The above warning is intended to protect agains mixing sync and
       async reset signals, as a coding style. gnt_in_flight is not used in
       this way, so the warning is inappropriate. */

    always @(posedge secondary_clk_i) begin
        if ((gnt_ack_ff2 && !gnt_ack_ff3) || !rst_n_secondary_ff2)
            gnt_in_flight <= 'b0;
        else if (req_ff2 && secondary_gnt_i && !gnt_in_flight)
            gnt_in_flight <= 'b1;
    end

    always @(posedge ctrl_clk_i or negedge gnt_in_flight) begin
        if(!gnt_in_flight)
            gnt_ack <= 'b0;
        else if(!rst_n_ctrl_ff2)
            gnt_ack <= 'b0;
        else if(gnt_ff2 && !gnt_ff3)
            gnt_ack <= 'b1;
    end

    /* verilator lint_on SYNCASYNCNET */

    always @(posedge secondary_clk_i) begin
        if (!rst_n_secondary_ff2) begin
            gnt_ack_ff1 <= 'b0;
            gnt_ack_ff2 <= 'b0;
            gnt_ack_ff3 <= 'b0;
        end else begin
            gnt_ack_ff3 <= gnt_ack_ff2;
            gnt_ack_ff2 <= gnt_ack_ff1;
            gnt_ack_ff1 <= gnt_ack;
        end
    end

    ///////////////////////////
    // Secondary bus outputs //
    ///////////////////////////

    assign secondary_addr_o  = ctrl_addr_i;
    assign secondary_we_o    = ctrl_we_i;
    assign secondary_be_o    = ctrl_be_i;
    assign secondary_wdata_o = ctrl_wdata_i;
    assign secondary_req_o   = req_ff2 && !gnt_in_flight;

    always @(posedge secondary_clk_i) begin
        if (!rst_n_secondary_ff2) begin
            req_ff2 <= 'b0;
            req_ff1 <= 'b0;
        end else begin
            req_ff2 <= req_ff1;
            req_ff1 <= ctrl_req_i; 
        end
    end

    /////////////////////////
    // Primary bus outputs //
    /////////////////////////

    assign ctrl_gnt_o = gnt_ff2 && !gnt_ff3;

    always @(posedge ctrl_rvalid_o) begin
        if (!rst_n_ctrl_ff2) begin
            ctrl_rdata_o <= 32'hDEAD_BEEF;
        end else begin
            ctrl_rdata_o <= secondary_rdata_i;
        end
    end

    always @(posedge ctrl_clk_i) begin
        if (!rst_n_ctrl_ff2) begin
            gnt_ff3       <= 'b0;
            gnt_ff2       <= 'b0;
            gnt_ff1       <= 'b0;
            ctrl_rvalid_o <= 'b0;
            rvalid_ff1    <= 'b0;
        end else begin
            gnt_ff3       <= gnt_ff2;
            gnt_ff2       <= gnt_ff1;
            gnt_ff1       <= gnt_in_flight;
            ctrl_rvalid_o <= rvalid_ff1;
            rvalid_ff1    <= secondary_rvalid_i;
        end
    end

    /////////////////////////
    // Reset Synchronizers //
    /////////////////////////

    always @(posedge ctrl_clk_i) begin
        if (!rst_ni) begin
            rst_n_ctrl_ff2 <= 'b0;
            rst_n_ctrl_ff1 <= 'b0;
        end else begin
            rst_n_ctrl_ff2 <= rst_n_ctrl_ff1;
            rst_n_ctrl_ff1 <= 'b1;
        end
    end

    always @(posedge secondary_clk_i) begin
        if (!rst_ni) begin
            rst_n_secondary_ff2 <= 'b0;
            rst_n_secondary_ff1 <= 'b0;
        end else begin
            rst_n_secondary_ff2 <= rst_n_secondary_ff1;
            rst_n_secondary_ff1 <= 'b1;
        end
    end

endmodule
