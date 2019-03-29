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
//
/**
@class dma_logic
@author      Jose Fernando Zazo Rollon (josefernando.zazo@naudit.es)
@date        20/04/2015
@brief Top level design containing  the PCIe DMA core
*/

`timescale  1ns/1ns
/*
NOTATION: some compromises have been adopted.
INPUTS/OUTPUTS   to the module are expressed in capital letters.
INPUTS CONSTANTS to the module are expressed in capital letters.
STATES of a FMS  are expressed in capital letters.
Other values are in lower letters.
A register will be written as name_of_register"_r" (except registers associated to states)
A signal will be written as   name_of_register"_s"
Every constante will be preceded by "c_"name_of_the_constant
*/

// We cant use $clog2 to initialize vectors to 0, so we define the discrete ceil of the log2
`define CLOG2(x) \
(x <= 2) ? 1 : \
(x <= 4) ? 2 : \
(x <= 8) ? 3 : \
(x <= 16) ? 4 : \
(x <= 32) ? 5 : \
(x <= 64) ? 6 : \
(x <= 128) ? 7 : \
(x <= 256) ? 8 : \
(x <= 512) ? 9 : \
(x <= 1024) ? 10 : \
(x <= 2048) ? 11 : 12

module dma_logic #(
  parameter C_BUS_DATA_WIDTH         = 256     ,
  parameter                                           C_BUS_KEEP_WIDTH = (C_BUS_DATA_WIDTH/32),
  parameter                                           C_AXI_KEEP_WIDTH = (C_BUS_DATA_WIDTH/8),
  parameter C_ADDR_WIDTH             = 16      , //At least 10 (Offset 200)
  parameter C_DATA_WIDTH             = 64      ,
  parameter C_ENGINE_TABLE_OFFSET    = 32'h200 ,
  parameter C_OFFSET_BETWEEN_ENGINES = 16'h2000,
  parameter C_NUM_ENGINES            = 2       ,
  parameter C_WINDOW_SIZE            = 4       , // Number of parallel memory read requests. Must be a value between 1 and 2**9-1
  parameter C_LOG2_MAX_PAYLOAD       = 8       , // 2**C_LOG2_MAX_PAYLOAD in bytes
  parameter C_LOG2_MAX_READ_REQUEST  = 12        // 2**C_LOG2_MAX_READ_REQUEST in bytes
) (
  input  wire                                          CLK                ,
  input  wire                                          RST_N              ,
  ////////////
  //  PCIe Interface: 2 AXI-Stream (requester side)
  ////////////
  output wire [                  C_BUS_DATA_WIDTH-1:0] M_AXIS_RQ_TDATA    ,
  output wire [                                  59:0] M_AXIS_RQ_TUSER    ,
  output wire                                          M_AXIS_RQ_TLAST    ,
  output wire [                  C_BUS_KEEP_WIDTH-1:0] M_AXIS_RQ_TKEEP    ,
  output wire                                          M_AXIS_RQ_TVALID   ,
  input  wire [                                   3:0] M_AXIS_RQ_TREADY   ,
  input  wire [                  C_BUS_DATA_WIDTH-1:0] S_AXIS_RC_TDATA    ,
  input  wire [                                  74:0] S_AXIS_RC_TUSER    ,
  input  wire                                          S_AXIS_RC_TLAST    ,
  input  wire [                  C_BUS_KEEP_WIDTH-1:0] S_AXIS_RC_TKEEP    ,
  input  wire                                          S_AXIS_RC_TVALID   ,
  output wire [                                  21:0] S_AXIS_RC_TREADY   ,
  ////////////
  //  User Interface: 2 AXI-Stream. Every engine will have associate a  C_BUS_DATA_WIDTH
  //  AXI-Stream in each direction.
  ////////////
  output wire [                 (C_NUM_ENGINES/2)-1:0] S2C_TVALID         ,
  input  wire [                 (C_NUM_ENGINES/2)-1:0] S2C_TREADY         ,
  output wire [C_BUS_DATA_WIDTH*(C_NUM_ENGINES/2)-1:0] S2C_TDATA          ,
  output wire [                 (C_NUM_ENGINES/2)-1:0] S2C_TLAST          ,
  output wire [C_AXI_KEEP_WIDTH*(C_NUM_ENGINES/2)-1:0] S2C_TKEEP          ,
  output wire [                 (C_NUM_ENGINES/2)-1:0] C2S_TREADY         ,
  input  wire [C_BUS_DATA_WIDTH*(C_NUM_ENGINES/2)-1:0] C2S_TDATA          ,
  input  wire [                 (C_NUM_ENGINES/2)-1:0] C2S_TLAST          ,
  input  wire [                 (C_NUM_ENGINES/2)-1:0] C2S_TVALID         ,
  input  wire [C_AXI_KEEP_WIDTH*(C_NUM_ENGINES/2)-1:0] C2S_TKEEP          ,
  ////////////
  //  Memory Interface: Master interface, transferences from the CPU.
  ////////////
  input  wire                                          S_MEM_IFACE_EN     ,
  input  wire [                      C_ADDR_WIDTH-1:0] S_MEM_IFACE_ADDR   ,
  output wire [                      C_DATA_WIDTH-1:0] S_MEM_IFACE_DOUT   ,
  input  wire [                      C_DATA_WIDTH-1:0] S_MEM_IFACE_DIN    ,
  input  wire [                    C_DATA_WIDTH/8-1:0] S_MEM_IFACE_WE     ,
  output wire                                          S_MEM_IFACE_ACK    ,
  //
  output wire [                     C_NUM_ENGINES-1:0] IRQ                ,
  output wire                                          OPERATION_IN_COURSE
);


  wire [$clog2(C_NUM_ENGINES)-1:0] active_engine_s        ;
  wire [                      7:0] status_byte_s          ;
  wire [                      7:0] control_byte_s         ;
  wire [                     63:0] addr_at_descriptor_s   ;
  wire [                     63:0] size_at_descriptor_s   ;
  wire [                     63:0] timeout_at_descriptor_s;

  reg  [63:0] byte_count_r   ;
  wire [63:0] byte_count_rc_s;
  wire [63:0] byte_count_rq_s;

  wire [C_DATA_WIDTH-1:0] s_mem_iface_dout_dma_reg_s;
  wire                    s_mem_iface_ack_dma_reg_s ;

  reg                      user_reset_r               ;
  wire                     dma_reset_n                ;
  wire [C_NUM_ENGINES-1:0] irq_s                      ;
  wire                     hw_request_transference_s  ;
  wire [             63:0] hw_new_size_at_descriptor_s;

wire valid_info_s;
  assign dma_reset_n = RST_N & (!user_reset_r);
  wire [C_NUM_ENGINES/2-1:0] c2s_fifo_tvalid_s                     ;

  wire engine_valid_s;
  dma_engine_manager #(
    .C_ADDR_WIDTH            (C_ADDR_WIDTH            ),
    .C_DATA_WIDTH            (C_DATA_WIDTH            ),
    .C_ENGINE_TABLE_OFFSET   (C_ENGINE_TABLE_OFFSET   ),
    .C_OFFSET_BETWEEN_ENGINES(C_OFFSET_BETWEEN_ENGINES),
    .C_NUM_ENGINES           (C_NUM_ENGINES           )
  ) dma_engine_manager_i (
    .CLK                      (CLK                        ),
    .RST_N                    (dma_reset_n                ),

    .S_MEM_IFACE_EN           (S_MEM_IFACE_EN             ),
    .S_MEM_IFACE_ADDR         (S_MEM_IFACE_ADDR           ),
    .S_MEM_IFACE_DOUT         (s_mem_iface_dout_dma_reg_s ),
    .S_MEM_IFACE_DIN          (S_MEM_IFACE_DIN            ),
    .S_MEM_IFACE_WE           (S_MEM_IFACE_WE             ),
    .S_MEM_IFACE_ACK          (s_mem_iface_ack_dma_reg_s  ),

    .ACTIVE_ENGINE            (active_engine_s            ),
    .ENGINE_VALID             (engine_valid_s             ),
    .STATUS_BYTE              (status_byte_s              ),
    .CONTROL_BYTE             (control_byte_s             ),
    .BYTE_COUNT               (byte_count_r               ),
    .DESCRIPTOR_ADDR          (addr_at_descriptor_s       ),
    .DESCRIPTOR_SIZE          (size_at_descriptor_s       ),
    .DESCRIPTOR_MAX_TIMEOUT   (timeout_at_descriptor_s    ),
    .HW_REQUEST_TRANSFERENCE  (hw_request_transference_s  ),
    .HW_NEW_SIZE_AT_DESCRIPTOR(hw_new_size_at_descriptor_s),

    .IRQ                      (irq_s                      ),
    .OPERATION_IN_COURSE      (OPERATION_IN_COURSE        ),
    .C2S_TVALID               (c2s_fifo_tvalid_s|valid_info_s)
  );



  /*
  This process will check for the next engine. It is a balanced implementation
  where every engine has the same priority. A selected engine can operate with
  memory write requests or memory read requests. Multiple directions are not
  supported by this implementation
  */
  wire [1:0] capabilities;
  assign capabilities = status_byte_s[6:5];

  always @(negedge dma_reset_n or posedge CLK) begin
    if (!dma_reset_n) begin
      byte_count_r <= 64'b0;
    end else begin
      byte_count_r <= capabilities[0] ? byte_count_rq_s : byte_count_rc_s;
    end
  end




  wire [              255:0] c2s_fifo_tdata_s [C_NUM_ENGINES/2-1:0];
  wire [               31:0] c2s_fifo_tkeep_s [C_NUM_ENGINES/2-1:0];
  wire [C_NUM_ENGINES/2-1:0] c2s_fifo_tready_s                     ;
  wire [C_NUM_ENGINES/2-1:0] c2s_fifo_tlast_s                      ;

  wire [255:0] current_c2s_fifo_tdata_s ;
  wire [ 31:0] current_c2s_fifo_tkeep_s ;
  wire         current_c2s_fifo_tready_s;
  wire         current_c2s_fifo_tlast_s ;
  wire         current_c2s_fifo_tvalid_s;




  assign current_c2s_fifo_tdata_s  = c2s_fifo_tdata_s[(active_engine_s>>1)];
  assign current_c2s_fifo_tkeep_s  = c2s_fifo_tkeep_s[(active_engine_s>>1)];
  assign current_c2s_fifo_tlast_s  = c2s_fifo_tlast_s[(active_engine_s>>1)];
  assign current_c2s_fifo_tvalid_s = c2s_fifo_tvalid_s[(active_engine_s>>1)];


  wire   [(C_NUM_ENGINES/2)-1:0] c2s_tready_s   ;
  reg    [(C_NUM_ENGINES/2)-1:0] c2s_tready_r   ;
  reg    [(C_NUM_ENGINES/2)-1:0] is_fifo_ready_r;
  genvar                         j              ;
  for(j=0; j<C_NUM_ENGINES/2;j=j+1) begin
    assign c2s_fifo_tready_s[j] = j==(active_engine_s>>1) && (engine_valid_s & current_c2s_fifo_tready_s);


    always @(negedge dma_reset_n or posedge CLK) begin
      if (!dma_reset_n) begin
        c2s_tready_r[j]    <= 1'b0;
        is_fifo_ready_r[j] <= 1'b0;
      end else begin
        c2s_tready_r[j]    <= c2s_tready_s[j];
        is_fifo_ready_r[j] <= c2s_tready_r[j];
      end
    end

    user_fifo c2s_fifo_i (
      .s_aclk       (CLK                                                     ),
      .s_aresetn    (dma_reset_n                                             ),
      .s_axis_tvalid(C2S_TVALID[j] & is_fifo_ready_r[j]                      ),
      .s_axis_tready(c2s_tready_s[j]                                         ),
      .s_axis_tdata (C2S_TDATA[(j+1)*C_BUS_DATA_WIDTH-1:(j)*C_BUS_DATA_WIDTH]),
      .s_axis_tkeep (C2S_TKEEP[(j+1)*C_AXI_KEEP_WIDTH-1:j*C_AXI_KEEP_WIDTH]  ),
      .s_axis_tlast (C2S_TLAST[j]                                            ),
      .m_axis_tvalid(c2s_fifo_tvalid_s[j]                                    ),
      .m_axis_tready(c2s_fifo_tready_s[j]                                    ),
      .m_axis_tdata (c2s_fifo_tdata_s[j]                                     ),
      .m_axis_tkeep (c2s_fifo_tkeep_s[j]                                     ),
      .m_axis_tlast (c2s_fifo_tlast_s[j]                                     )
    );

    assign C2S_TREADY[j] = c2s_tready_s[j] & is_fifo_ready_r[j];
  end




  wire [   C_WINDOW_SIZE-1:0] busy_tags_s     ;
  wire [   C_WINDOW_SIZE-1:0] error_tags_s    ;
  wire [   C_WINDOW_SIZE-1:0] completed_tags_s;
  wire [C_WINDOW_SIZE*11-1:0] size_tags_s     ;
  wire [    C_DATA_WIDTH-1:0] debug_c2s_s     ;

  // Manage the RQ interface
  dma_rq_logic #(
    .C_BUS_DATA_WIDTH       (C_BUS_DATA_WIDTH       ),
    .C_BUS_KEEP_WIDTH       (C_BUS_KEEP_WIDTH       ),
    .C_AXI_KEEP_WIDTH       (C_AXI_KEEP_WIDTH       ),
    .C_NUM_ENGINES          (C_NUM_ENGINES          ),
    .C_WINDOW_SIZE          (C_WINDOW_SIZE          ),
    .C_LOG2_MAX_PAYLOAD     (C_LOG2_MAX_PAYLOAD     ),
    .C_LOG2_MAX_READ_REQUEST(C_LOG2_MAX_READ_REQUEST)
  ) dma_rq_logic_i (
    .CLK                      (CLK                        ),
    .RST_N                    (dma_reset_n                ),

    ////////////
    //  PCIe Interface: 1 AXI-Stream (requester side)
    ////////////
    .M_AXIS_RQ_TDATA          (M_AXIS_RQ_TDATA            ),
    .M_AXIS_RQ_TUSER          (M_AXIS_RQ_TUSER            ),
    .M_AXIS_RQ_TLAST          (M_AXIS_RQ_TLAST            ),
    .M_AXIS_RQ_TKEEP          (M_AXIS_RQ_TKEEP            ),
    .M_AXIS_RQ_TVALID         (M_AXIS_RQ_TVALID           ),
    .M_AXIS_RQ_TREADY         (M_AXIS_RQ_TREADY           ),


    ////////////
    //  c2s fifo interface: 1 AXI-Stream (data to be transferred in memory write requests)
    ////////////
    .C2S_FIFO_TREADY          (current_c2s_fifo_tready_s  ),
    .C2S_FIFO_TDATA           (current_c2s_fifo_tdata_s   ),
    .C2S_FIFO_TLAST           (current_c2s_fifo_tlast_s   ),
    .C2S_FIFO_TVALID          (current_c2s_fifo_tvalid_s  ),
    .C2S_FIFO_TKEEP           (current_c2s_fifo_tkeep_s   ),
    ////////////
    //  Descriptor interface: Interface with the necessary data to complete a memory read/write request.
    ////////////
    .ENGINE_VALID             (engine_valid_s             ),
    .STATUS_BYTE              (status_byte_s              ),
    .CONTROL_BYTE             (control_byte_s             ),
    .BYTE_COUNT               (byte_count_rc_s            ),
    .SIZE_AT_DESCRIPTOR       (size_at_descriptor_s       ),
    .ADDR_AT_DESCRIPTOR       (addr_at_descriptor_s       ),
    .DESCRIPTOR_MAX_TIMEOUT   (timeout_at_descriptor_s    ),
    .HW_REQUEST_TRANSFERENCE  (hw_request_transference_s  ),
    .HW_NEW_SIZE_AT_DESCRIPTOR(hw_new_size_at_descriptor_s),

    .BUSY_TAGS                (busy_tags_s                ),
    .SIZE_TAGS                (size_tags_s                ),
    .ERROR_TAGS               (error_tags_s               ),
    .COMPLETED_TAGS           (completed_tags_s           ),
    .DEBUG                    (debug_c2s_s                )
  );

  wire [C_BUS_KEEP_WIDTH-1:0] s2c_fifo_tkeep_s         [C_NUM_ENGINES/2-1:0];
  wire [C_BUS_DATA_WIDTH-1:0] s2c_fifo_tdata_s         [C_NUM_ENGINES/2-1:0];
  wire [ C_NUM_ENGINES/2-1:0] s2c_fifo_tvalid_s                             ;
  wire [ C_NUM_ENGINES/2-1:0] s2c_fifo_tready_s                             ;
  wire [ C_NUM_ENGINES/2-1:0] s2c_fifo_tlast_s                              ;
  wire [C_AXI_KEEP_WIDTH-1:0] s2c_fifo_tkeep_expanded_s[C_NUM_ENGINES/2-1:0]; // s2c_fifo_tkeep_s is expressed in 32 bit words. However, the fifo expect the tkeep signal indicates persistence

  wire [C_DATA_WIDTH-1:0] debug_s2c_s;

  // Manage the RC interface
  wire [C_BUS_KEEP_WIDTH-1:0] current_s2c_fifo_tkeep_s ;
  wire [C_BUS_DATA_WIDTH-1:0] current_s2c_fifo_tdata_s ;
  wire                        current_s2c_fifo_tvalid_s;
  wire                        current_s2c_fifo_tready_s;
  wire                        current_s2c_fifo_tlast_s ;

  assign current_s2c_fifo_tready_s = s2c_fifo_tready_s[(active_engine_s>>1)];


  dma_rc_logic #(
    .C_BUS_DATA_WIDTH       (C_BUS_DATA_WIDTH       ),
    .C_BUS_KEEP_WIDTH       (C_BUS_KEEP_WIDTH       ),
    .C_NUM_ENGINES          (C_NUM_ENGINES          ),
    .C_WINDOW_SIZE          (C_WINDOW_SIZE          ),
    .C_LOG2_MAX_PAYLOAD     (C_LOG2_MAX_PAYLOAD     ),
    .C_LOG2_MAX_READ_REQUEST(C_LOG2_MAX_READ_REQUEST)
  ) dma_rc_logic_i (
    .CLK             (CLK                      ),
    .RST_N           (dma_reset_n              ),

    ////////////
    //  PCIe Interface: 1 AXI-Stream (requester side)
    ////////////
    .S_AXIS_RC_TDATA (S_AXIS_RC_TDATA          ),
    .S_AXIS_RC_TUSER (S_AXIS_RC_TUSER          ),
    .S_AXIS_RC_TLAST (S_AXIS_RC_TLAST          ),
    .S_AXIS_RC_TKEEP (S_AXIS_RC_TKEEP          ),
    .S_AXIS_RC_TVALID(S_AXIS_RC_TVALID         ),
    .S_AXIS_RC_TREADY(S_AXIS_RC_TREADY         ),


    ////////////
    //  s2c fifo interface: 1 AXI-Stream
    ////////////
    .S2C_FIFO_TVALID (current_s2c_fifo_tvalid_s),
    .S2C_FIFO_TREADY (current_s2c_fifo_tready_s), // S2C engines are the odd ones.
    .S2C_FIFO_TDATA  (current_s2c_fifo_tdata_s ),
    .S2C_FIFO_TLAST  (current_s2c_fifo_tlast_s ),
    .S2C_FIFO_TKEEP  (current_s2c_fifo_tkeep_s ),



    ////////////
    // Descriptor interface: Interface with the necessary data to complete a memory read/write request.
    // Data is generated from dma_c2s_logic
    ////////////
    .BYTE_COUNT      (byte_count_rq_s          ),
    .BUSY_TAGS       (busy_tags_s              ),
    .SIZE_TAGS       (size_tags_s              ),
    .ERROR_TAGS      (error_tags_s             ),
    .COMPLETED_TAGS  (completed_tags_s         ),
    .DEBUG           (debug_s2c_s              )
  );



  wire [C_AXI_KEEP_WIDTH-1:0] s2c_tkeep_s     [C_NUM_ENGINES/2-1:0];
  reg  [C_AXI_KEEP_WIDTH-1:0] s2c_tkeep_last_r[C_NUM_ENGINES/2-1:0]; // Strobe of the last packet




  for(j=0; j<C_NUM_ENGINES/2;j=j+1) begin
    assign s2c_fifo_tkeep_s[j] = j==(active_engine_s>>1) ? current_s2c_fifo_tkeep_s : 0;
    assign s2c_fifo_tdata_s[j]          = j==(active_engine_s>>1) ? current_s2c_fifo_tdata_s : 0;
    assign s2c_fifo_tvalid_s[j]         = j==(active_engine_s>>1) ? current_s2c_fifo_tvalid_s : 0;
    assign s2c_fifo_tlast_s[j]          = j==(active_engine_s>>1) ? current_s2c_fifo_tlast_s : 0;
    assign s2c_fifo_tkeep_expanded_s[j] = j==(active_engine_s>>1) ? { {4{s2c_fifo_tkeep_s[j][7]}},{4{s2c_fifo_tkeep_s[j][6]}},{4{s2c_fifo_tkeep_s[j][5]}},{4{s2c_fifo_tkeep_s[j][4]}},
      {4{s2c_fifo_tkeep_s[j][3]}}, {4{s2c_fifo_tkeep_s[j][2]}},{4{s2c_fifo_tkeep_s[j][1]}},{4{s2c_fifo_tkeep_s[j][0]}} } : 0;
    user_fifo s2c_fifo_i (
      .s_aclk                                        (CLK),
      .s_aresetn                                     (dma_reset_n),
      .s_axis_tvalid                                 (s2c_fifo_tvalid_s[j]),
      .s_axis_tready                                 (s2c_fifo_tready_s[j]),
      .s_axis_tdata                                  (s2c_fifo_tdata_s[j]),
      .s_axis_tkeep                                  (s2c_fifo_tkeep_expanded_s[j]),
      .s_axis_tlast                                  (s2c_fifo_tlast_s[j]),
      .m_axis_tvalid                                 (S2C_TVALID[j]),
      .m_axis_tready                                 (S2C_TREADY[j]),
      .m_axis_tdata                                  (S2C_TDATA[j*C_BUS_DATA_WIDTH +: C_BUS_DATA_WIDTH]),
      .m_axis_tkeep                                  (s2c_tkeep_s[j]),
      .m_axis_tlast                                  (S2C_TLAST[j])
    );

    always @(negedge dma_reset_n or posedge CLK) begin
      if(!dma_reset_n) begin
        s2c_tkeep_last_r[j] <= {C_AXI_KEEP_WIDTH{1'b0}};
      end else begin
        case(size_at_descriptor_s[$clog2(C_AXI_KEEP_WIDTH)-1:0])
          32'h1   : s2c_tkeep_last_r[j] <= 32'h00000001;
          32'h2   : s2c_tkeep_last_r[j] <= 32'h00000003;
          32'h3   : s2c_tkeep_last_r[j] <= 32'h00000007;
          32'h4   : s2c_tkeep_last_r[j] <= 32'h0000000f;
          32'h5   : s2c_tkeep_last_r[j] <= 32'h0000001f;
          32'h6   : s2c_tkeep_last_r[j] <= 32'h0000003f;
          32'h7   : s2c_tkeep_last_r[j] <= 32'h0000007f;
          32'h8   : s2c_tkeep_last_r[j] <= 32'h000000ff;
          32'h9   : s2c_tkeep_last_r[j] <= 32'h000001ff;
          32'ha   : s2c_tkeep_last_r[j] <= 32'h000003ff;
          32'hb   : s2c_tkeep_last_r[j] <= 32'h000007ff;
          32'hc   : s2c_tkeep_last_r[j] <= 32'h00000fff;
          32'hd   : s2c_tkeep_last_r[j] <= 32'h00001fff;
          32'he   : s2c_tkeep_last_r[j] <= 32'h00003fff;
          32'hf   : s2c_tkeep_last_r[j] <= 32'h00007fff;
          32'h10  : s2c_tkeep_last_r[j] <= 32'h0000ffff;
          32'h11  : s2c_tkeep_last_r[j] <= 32'h0001ffff;
          32'h12  : s2c_tkeep_last_r[j] <= 32'h0003ffff;
          32'h13  : s2c_tkeep_last_r[j] <= 32'h0007ffff;
          32'h14  : s2c_tkeep_last_r[j] <= 32'h000fffff;
          32'h15  : s2c_tkeep_last_r[j] <= 32'h001fffff;
          32'h16  : s2c_tkeep_last_r[j] <= 32'h003fffff;
          32'h17  : s2c_tkeep_last_r[j] <= 32'h007fffff;
          32'h18  : s2c_tkeep_last_r[j] <= 32'h00ffffff;
          32'h19  : s2c_tkeep_last_r[j] <= 32'h01ffffff;
          32'h1a  : s2c_tkeep_last_r[j] <= 32'h03ffffff;
          32'h1b  : s2c_tkeep_last_r[j] <= 32'h07ffffff;
          32'h1c  : s2c_tkeep_last_r[j] <= 32'h0fffffff;
          32'h1d  : s2c_tkeep_last_r[j] <= 32'h1fffffff;
          32'h1e  : s2c_tkeep_last_r[j] <= 32'h3fffffff;
          32'h1f  : s2c_tkeep_last_r[j] <= 32'h7fffffff;
          default : s2c_tkeep_last_r[j] <= 32'hffffffff;
        endcase
      end
    end
    assign S2C_TKEEP[(j+1)*C_AXI_KEEP_WIDTH-1:j*C_AXI_KEEP_WIDTH] = S2C_TLAST[j] ? s2c_tkeep_last_r[j] : 32'hffffffff;
  end


////



  reg  [C_DATA_WIDTH-1:0] s_mem_iface_dout_ctrl_r       ;
  reg                     s_mem_iface_ack_ctrl_r        ;
  reg                     s_mem_iface_ctrl_r            ;
  wire [             2:0] max_payload_common_block_s    ;
  wire [             2:0] max_readrequest_common_block_s;
  reg                     global_irq_r                  ;

  assign max_payload_common_block_s     = C_LOG2_MAX_PAYLOAD-7;
  assign max_readrequest_common_block_s = C_LOG2_MAX_READ_REQUEST-7;

  always @(negedge dma_reset_n or posedge CLK) begin
    if (!dma_reset_n) begin
      s_mem_iface_ctrl_r      <= 1'b0;
      s_mem_iface_dout_ctrl_r <= 0;
      s_mem_iface_ack_ctrl_r  <= 1'b0;
    end else begin
      s_mem_iface_ack_ctrl_r <= S_MEM_IFACE_EN;
      if(S_MEM_IFACE_EN) begin
        case(S_MEM_IFACE_ADDR)
          C_ENGINE_TABLE_OFFSET + C_NUM_ENGINES*C_OFFSET_BETWEEN_ENGINES: begin
            //                        1         1              3                          3
            s_mem_iface_dout_ctrl_r <= { {64-8{1'b0}}, 1'b0, global_irq_r,max_readrequest_common_block_s, max_payload_common_block_s};
            s_mem_iface_ack_ctrl_r  <= 1'b1;
          end
          /*
          C_ENGINE_TABLE_OFFSET + C_NUM_ENGINES*C_OFFSET_BETWEEN_ENGINES+1: begin
          s_mem_iface_dout_ctrl_r <= debug_c2s_s;
          s_mem_iface_ack_ctrl_r  <= 1'b1;
          end
          C_ENGINE_TABLE_OFFSET + C_NUM_ENGINES*C_OFFSET_BETWEEN_ENGINES+2: begin
          s_mem_iface_dout_ctrl_r <= debug_s2c_s;
          s_mem_iface_ack_ctrl_r  <= 1'b1;
          end
          */
          default : begin
            s_mem_iface_ack_ctrl_r <= 1'b0;
          end
        endcase
      end
    end
  end
  always @(negedge dma_reset_n or posedge CLK) begin
    if (!dma_reset_n) begin
      user_reset_r <= 1'b0;
      global_irq_r <= 1'b0;
    end else begin
      if(S_MEM_IFACE_EN  && S_MEM_IFACE_WE) begin
        case(S_MEM_IFACE_ADDR)
          C_ENGINE_TABLE_OFFSET + C_NUM_ENGINES*C_OFFSET_BETWEEN_ENGINES : begin
            if(S_MEM_IFACE_WE[0]) begin
              global_irq_r <= S_MEM_IFACE_DIN[6];
              user_reset_r <= S_MEM_IFACE_DIN[7];
            end
          end
          default : begin
            user_reset_r <= 1'b0;
          end
        endcase
      end
    end
  end

  assign S_MEM_IFACE_DOUT = s_mem_iface_ack_ctrl_r ? s_mem_iface_dout_ctrl_r : s_mem_iface_dout_dma_reg_s;
  assign S_MEM_IFACE_ACK  = s_mem_iface_ack_ctrl_r ? s_mem_iface_ack_ctrl_r : s_mem_iface_ack_dma_reg_s;
  assign IRQ              = global_irq_r ? irq_s : 0;

endmodule
