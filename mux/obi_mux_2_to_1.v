`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name: obi_mux_2_to_1
// Author: Peter Herrmann
//
// Description: A 2-to-1 OBI (Open Bus Interface) mux
//
//              The MUX accepts at most 1 outstanding transaction at a time, so
//              Multiple reads can not be performed concurrently.
//
//              The MUX has 2 masters connected to a single slave. The primary
//              Master gets priority over the secondary master, meaning if the 
//              primary master and the secondary master are in the address phase,
//              only the primary can advance to the response phase of a read 
//              transaction or close a write transaction.
// 
//////////////////////////////////////////////////////////////////////////////////


module obi_mux_2_to_1 (
        input               clk_i,
        input               rst_ni,

        // Primary OBI interface
        input               pri_req_i,
        output wire         pri_gnt_o,
        input        [31:0] pri_addr_i,
        input               pri_we_i,
        input        [3:0]  pri_be_i,
        input        [31:0] pri_wdata_i,
        output wire         pri_rvalid_o,
        output wire  [31:0] pri_rdata_o,

        // Secondary OBI interface
        input               sec_req_i,
        output wire         sec_gnt_o,
        input        [31:0] sec_addr_i,
        input               sec_we_i,
        input        [3:0]  sec_be_i,
        input        [31:0] sec_wdata_i,
        output wire         sec_rvalid_o,
        output wire  [31:0] sec_rdata_o,

        // Shared OBI interface (slave)
        output wire         shr_req_o,
        input               shr_gnt_i,
        output wire  [31:0] shr_addr_o,
        output wire         shr_we_o,
        output wire  [3:0]  shr_be_o,
        output wire  [31:0] shr_wdata_o,
        input               shr_rvalid_i,
        input        [31:0] shr_rdata_i
);

  ///////////////////////////
  // Address Phase Routing //
  ///////////////////////////

  wire pri_accepted, sec_accepted;
  wire sec_posession, gnt_masked, available;

  assign sec_posession = ~pri_req_i;
  assign available     = shr_rvalid_i || !(pri_read_outstanding || sec_read_outstanding) ;
  assign gnt_masked    = shr_gnt_i && available;
  assign pri_accepted  = pri_req_i && pri_gnt_o && !pri_we_i;
  assign sec_accepted  = sec_req_i && sec_gnt_o && !sec_we_i;

  // gnt demux
  assign sec_gnt_o = (sec_posession ? gnt_masked : 0);
  assign pri_gnt_o = (sec_posession ? 0 : gnt_masked);
  
  // address signal mux
  assign shr_req_o   = sec_posession ? sec_req_i   : pri_req_i ;
  assign shr_addr_o  = sec_posession ? sec_addr_i  : pri_addr_i ;
  assign shr_we_o    = sec_posession ? sec_we_i    : pri_we_i ;
  assign shr_be_o    = sec_posession ? sec_be_i    : pri_be_i ;
  assign shr_wdata_o = sec_posession ? sec_wdata_i : pri_wdata_i ;

  ////////////////////////////
  // Response Phase Routing //
  ////////////////////////////

  reg pri_read_outstanding, sec_read_outstanding;

  // response signal demux
  assign sec_rvalid_o = sec_read_outstanding ? shr_rvalid_i : 0;
  assign sec_rdata_o  = sec_read_outstanding ? shr_rdata_i  : 0;
  assign pri_rvalid_o = pri_read_outstanding ? shr_rvalid_i : 0;
  assign pri_rdata_o  = pri_read_outstanding ? shr_rdata_i  : 0;

  // Response tracker
  always @(posedge clk_i) begin
    if (!rst_ni) begin
        pri_read_outstanding <= 0;
        sec_read_outstanding <= 0;
    end else if (available) begin
        pri_read_outstanding <= pri_accepted;
        sec_read_outstanding <= sec_accepted;
    end
  end

endmodule // obi_mux_2_to_1
