`timescale 1ns/1ps
///////////////////////////////////////////////////////////////////////////////
//
// Module Name: wb_to_obi
// Author: Peter Herrmann
//
// Description: This Wishbone B4 to OBI (Open Bus Interface) accepts a
//              connection from a Wishbone master device, and drives an OBI
//              slave device.
//
//              Note that the wishbone clock input is missing. For this
//              connection to work, the wishbone bus must be operating in the
//              clock domain as the OBI device, so only a single clock input is
//              provided. Any clock domain crossings must be handled by the 
//              user.
//
///////////////////////////////////////////////////////////////////////////////

module wb_to_obi (
    input               clk_i,
    // Wishbone bus from master
    input               wb_rst_i,  // Active high!
    input               wbs_stb_i,
    input               wbs_cyc_i, // Not Used in OBI
    input               wbs_we_i, 
    input [3:0]         wbs_sel_i,
    input [31:0]        wbs_dat_i,
    input [31:0]        wbs_adr_i,
    output wire         wbs_ack_o,
    output wire  [31:0] wbs_dat_o,

    // OBI Port to Slave
    output wire         req_o,    
    input               gnt_i,   
    output wire  [31:0] addr_o,    
    output wire         we_o,       
    output wire  [3:0]  be_o,     
    output wire  [31:0] wdata_o,  
    input               rvalid_i,
    input [31:0]        rdata_i   
    );

    reg read_outstanding, write_completed; 
    wire read_accepted_a, write_accepted_a;
    assign read_accepted_a  = (req_o && gnt_i) && !wbs_we_i;
    assign write_accepted_a = (req_o && gnt_i) && wbs_we_i;

    // Read transaction tracker
    always @(posedge clk_i) begin
        if (wb_rst_i)
            read_outstanding <= 'b0;
        else begin
            if (read_outstanding && (rvalid_i && !read_accepted_a))
                read_outstanding <= 'b0;
            if (!read_outstanding && read_accepted_a)
                read_outstanding <= 'b0;
        end
    end
        
    // Write completion tracker
    always @(posedge clk_i) begin
        write_completed <= write_accepted_a;
    end

    // Address Signals
    assign req_o     = wbs_stb_i;
    assign addr_o    = wbs_adr_i;
    assign we_o      = wbs_we_i;
    assign be_o      = wbs_sel_i;
    assign wdata_o   = wbs_dat_i;

    // Response Signals
    assign wbs_dat_o = rdata_i;
    assign wbs_ack_o = write_completed || (read_outstanding && rvalid_i);

    `ifdef verilator
        wire _unused;
        assign _unused = wbs_cyc_i;
    `endif 

endmodule
