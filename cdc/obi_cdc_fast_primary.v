`timescale 1ns/1ps

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
        gnt_ff1, gnt_ff2, gnt_ff3;

    /////////////////////////
    // Transaction Tracker //
    /////////////////////////

    /* This module must account for the latency between a transaction being
       acccepted by the secondary bus and the primary bus receiving a grant. */

    /* [x] While a transaction's grant is in flight, mask the req output.

       [x] A transaction's grant starts when the req and gnt bits are high 
           at the secondary port and no gnt is in flight, send a grant pulse.

       [x] The receipt of a grant by the controller port must be pulse 
           synchronized.

       [x] Grant pulses sent by the secondary port must be separated by at least
           one clock cycle to enable edge detection on the pulse synchronizer.

       [x] When the primary receives a grant pulse, it asserts gnt_ack until 
           gnt_in_flight is de-asserted. 

       [x] The receipt of a grant acknowledgement by the secondary port must be
           pulse synchronized.

       [x] A transaction's grant is completed when the secondary port receives
           acknowledgement that the grant was received. 

       [x] The delay between the controller port receiving a grant and the 
           controller port receiving a grant ack must be at least as long as
           the pipeline delay of the req signal. */

    always @(posedge secondary_clk_i) begin
        if ((gnt_ack_ff3 && !gnt_ack_ff2) || !rst_ni)
            gnt_in_flight <= '0;
        else if (req_ff2 && secondary_gnt_i && !gnt_in_flight)
            gnt_in_flight <= '1;
    end

    always @(posedge ctrl_clk_i or negedge gnt_in_flight) begin
        if(!rst_ni || !gnt_in_flight)
            gnt_ack <= '0;
        else if(gnt_ff3 && !gnt_ff2)
            gnt_ack <= '1;
    end

    always @(posedge secondary_clk_i) begin
        if (!rst_ni) begin
            gnt_ack_ff1 <= '0;
            gnt_ack_ff2 <= '0;
            gnt_ack_ff3 <= '0;
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
        if (!rst_ni) begin
            req_ff2 <= '0;
            req_ff1 <= '0;
        end else begin
            req_ff2 <= req_ff1;
            req_ff1 <= ctrl_req_i; 
        end
    end

    /////////////////////////
    // Primary bus outputs //
    /////////////////////////

    assign ctrl_rdata_o = secondary_rdata_i;
    assign ctrl_gnt_o = gnt_ff3 && !gnt_ff2;

    always @(posedge ctrl_clk_i) begin
        if (!rst_ni) begin
            gnt_ff3       <= '0;
            gnt_ff2       <= '0;
            gnt_ff1       <= '0;
            ctrl_rvalid_o <= '0;
            rvalid_ff1    <= '0;
        end else begin
            gnt_ff3       <= gnt_ff2;
            gnt_ff2       <= gnt_ff1;
            gnt_ff1       <= gnt_in_flight;

            ctrl_rvalid_o <= rvalid_ff1;
            rvalid_ff1    <= secondary_rvalid_i;
        end

    end

endmodule
