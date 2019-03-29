//
// Copyright (c) 2015 University of Cambridge
// All rights reserved.
//
// This software was developed by
// Stanford University and the University of Cambridge Computer Laboratory
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
// as part of the DARPA MRC research programme.
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more
// contributor license agreements.  See the NOTICE file distributed with this
// work for additional information regarding copyright ownership.  NetFPGA
// licenses this file to you under the NetFPGA Hardware-Software License,
// Version 1.0 (the "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at:
//
//   http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//
//////////////////////////////////////////////////////////////////////////////////
// Company:  Uni Cambridge
// Engineer: Y. Audzevich
//
// Module Name: nf_naudit_dma
// Description: PCIe DMA controller instantiation and PCIe tie-offs.
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

// TX is meant to be from the host to the card

module tx_naudit_axi #(
    parameter M_AXIS_TDATA_WIDTH = 256,
    parameter M_AXIS_TUSER_WIDTH = 128,
    parameter C_PREAM_VALUE 	= 16'hCAFE
)(
    // Misc
    input wire                          CLK,
    input wire                          RST,
    // AXIS-Slave
    input  wire  [M_AXIS_TDATA_WIDTH-1:0]       s_axis_tdata,
    input  wire  [M_AXIS_TDATA_WIDTH/8-1:0]     s_axis_tkeep,
    input  wire                                 s_axis_tvalid,
    input  wire                                 s_axis_tlast,
    output wire                                 s_axis_tready,

    // AXI-Master
    output reg [(M_AXIS_TDATA_WIDTH-1):0]       m_axis_tdata,
    output reg [((M_AXIS_TDATA_WIDTH/8)-1):0]   m_axis_tkeep,
    output reg [M_AXIS_TUSER_WIDTH-1:0]         m_axis_tuser,
    output reg                                  m_axis_tvalid,
    output reg                                  m_axis_tlast,
    input wire                                  m_axis_tready
);


function integer log2;
input integer number;
begin
    log2=0;
    while(2**log2<number) begin
        log2=log2+1;
    end
end
endfunction


localparam AXIS_FIRST   = 1;
localparam AXIS_PKT     = 2;
localparam AXIS_ADD_EOP = 4;
localparam NUM_STATES   = 3;

reg [NUM_STATES-1:0]                state,state_next;

reg  [(M_AXIS_TDATA_WIDTH/2)-1:0]   tdata_remainder,tdata_remainder_next;
reg  [(M_AXIS_TDATA_WIDTH/16)-1:0]  tkeep_remainder,tkeep_remainder_next;
reg  [M_AXIS_TUSER_WIDTH-1:0]       tuser,tuser_next;
wire [M_AXIS_TUSER_WIDTH-1:0]       tuser_w;
wire [15:0]                         pkt_len;

wire    [M_AXIS_TDATA_WIDTH-1:0]    tdata_fifo;
wire    [(M_AXIS_TDATA_WIDTH/8)-1:0]tkeep_fifo;
wire                                tlast_fifo;

wire                                tx_fifo_nearly_full;
wire                                tx_fifo_empty;
reg                                 tx_fifo_rd_en;



fallthrough_small_fifo #(
    .WIDTH (M_AXIS_TDATA_WIDTH+M_AXIS_TDATA_WIDTH/8+1),
    .MAX_DEPTH_BITS   (3)
)
    tx_s2c_fifo(
        .clk         (CLK),
        .reset       (RST),
        .din         ({s_axis_tdata,s_axis_tkeep,s_axis_tlast}),
        .wr_en       (s_axis_tvalid&~tx_fifo_nearly_full),
        .rd_en       (tx_fifo_rd_en),
        .dout        ({tdata_fifo,tkeep_fifo,tlast_fifo}),
        .nearly_full (tx_fifo_nearly_full),
        .empty       (tx_fifo_empty),
        .full        (),
        .prog_full   ());


assign pkt_len      = tdata_fifo[32+:16]-4;
// we re-assemble the tuser according to the metadata the driver
// suppose to insert on top of the packet
// check line 110 of "rx_axi_naudit.v" for metadata format
assign tuser_w      = {32'h0,tdata_fifo[127:64],tdata_fifo[31:24],tdata_fifo[7:0],pkt_len};
assign s_axis_tready= !tx_fifo_nearly_full;

always @(posedge CLK) begin
    if (RST) begin
        state               <= AXIS_FIRST;
        tdata_remainder     <= 0;
        tkeep_remainder     <= 0;
        tuser               <= 0;
    end
    else begin
        state               <= state_next;
        tdata_remainder     <= tdata_remainder_next;
        tkeep_remainder     <= tkeep_remainder_next;
        tuser_next          <= tuser;
    end
end



always @(*) begin
    m_axis_tvalid           = 0;
    m_axis_tdata            = tdata_fifo;
    m_axis_tkeep            = tkeep_fifo;
    m_axis_tlast            = tlast_fifo;
    m_axis_tuser            = 0;
    tx_fifo_rd_en           = 0;
    tuser_next              = tuser;
    tdata_remainder_next    = tdata_remainder;
    tkeep_remainder_next    = tkeep_remainder;
    state_next              = state;

    case(state)

    AXIS_FIRST : begin
        if(!tx_fifo_empty) begin
            tdata_remainder_next= tdata_fifo[255:128];
            tuser_next          = tuser_w;
            tx_fifo_rd_en       = 1;
            state_next          = AXIS_PKT;
        end
    end


    AXIS_PKT : begin
        if(!tx_fifo_empty) begin
            m_axis_tdata = {tdata_fifo[127:0],tdata_remainder};
            tdata_remainder_next = tdata_fifo[255:128];
            m_axis_tuser = tuser;
            m_axis_tvalid= 1;
            if(m_axis_tready) begin
                tx_fifo_rd_en   = 1;
                if(tlast_fifo) begin
                    if(tkeep_fifo[16]) begin
                        m_axis_tlast        = 0;
                        m_axis_tkeep        = 32'hffffffff;
                        tkeep_remainder_next= tkeep_fifo[31:16];
                        state_next          = AXIS_ADD_EOP;
                    end
                    else begin
                        m_axis_tkeep        = {tkeep_fifo[15:0],16'hffff};
                        state_next          = AXIS_FIRST;
                    end
                end
            end
        end
    end


    AXIS_ADD_EOP: begin
        m_axis_tdata    = {128'h0,tdata_remainder};
        m_axis_tkeep    = {16'h0,tkeep_remainder};
        m_axis_tvalid   = 1;
        m_axis_tlast    = 1;
        m_axis_tuser    = tuser;
        if(m_axis_tready)
            state_next  = AXIS_FIRST;
    end

    endcase
end
endmodule
