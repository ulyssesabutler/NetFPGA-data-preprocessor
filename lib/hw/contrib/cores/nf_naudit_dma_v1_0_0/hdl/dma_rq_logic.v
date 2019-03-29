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
@class dma_rq_logic
@author      Jose Fernando Zazo Rollon (josefernando.zazo@naudit.es)
@date        04/05/2015
@brief Design containing  the DMA requester interface
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
In this particular module
mem_wr_* references a memory write request signal
mem_rd_* references a memory read request signal
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

module dma_rq_logic #(
  parameter C_BUS_DATA_WIDTH        = 256,
  parameter                                           C_BUS_KEEP_WIDTH = (C_BUS_DATA_WIDTH/32),
  parameter                                           C_AXI_KEEP_WIDTH = (C_BUS_DATA_WIDTH/8),
  parameter C_NUM_ENGINES           = 2  ,
  parameter C_WINDOW_SIZE           = 16 ,
  parameter C_LOG2_MAX_PAYLOAD      = 8  , // 2**C_LOG2_MAX_PAYLOAD in bytes
  parameter C_LOG2_MAX_READ_REQUEST = 14   // 2**C_LOG2_MAX_READ_REQUEST in bytes
) (
  input  wire                        CLK                      ,
  input  wire                        RST_N                    ,
  ////////////
  //  PCIe Interface: 1 AXI-Stream (requester side)
  ////////////
  output wire [C_BUS_DATA_WIDTH-1:0] M_AXIS_RQ_TDATA          ,
  output wire [                59:0] M_AXIS_RQ_TUSER          ,
  output wire                        M_AXIS_RQ_TLAST          ,
  output wire [C_BUS_KEEP_WIDTH-1:0] M_AXIS_RQ_TKEEP          ,
  output wire                        M_AXIS_RQ_TVALID         ,
  input  wire [                 3:0] M_AXIS_RQ_TREADY         ,
  ////////////
  //  c2s fifo interface: 1 AXI-Stream (data to be transferred in memory write requests)
  ////////////
  output wire                        C2S_FIFO_TREADY          ,
  input  wire [C_BUS_DATA_WIDTH-1:0] C2S_FIFO_TDATA           ,
  input  wire                        C2S_FIFO_TLAST           ,
  input  wire                        C2S_FIFO_TVALID          ,
  input  wire [C_AXI_KEEP_WIDTH-1:0] C2S_FIFO_TKEEP           ,
  ////////////
  //  Descriptor interface: Interface with the necessary data to complete a memory read/write request.
  ////////////
  input  wire                        ENGINE_VALID             ,
  input  wire [                 7:0] STATUS_BYTE              ,
  output wire [                 7:0] CONTROL_BYTE             ,
  output reg  [                63:0] BYTE_COUNT               ,
  input  wire [                63:0] SIZE_AT_DESCRIPTOR       ,
  input  wire [                63:0] ADDR_AT_DESCRIPTOR       ,
  input  wire [                63:0] DESCRIPTOR_MAX_TIMEOUT   ,
  output wire                        HW_REQUEST_TRANSFERENCE  ,
  output wire [                63:0] HW_NEW_SIZE_AT_DESCRIPTOR,
  output wire [   C_WINDOW_SIZE-1:0] BUSY_TAGS                ,
  output wire [C_WINDOW_SIZE*11-1:0] SIZE_TAGS                , //Size associate to each tag
  input  wire [   C_WINDOW_SIZE-1:0] ERROR_TAGS               ,
  input  wire [   C_WINDOW_SIZE-1:0] COMPLETED_TAGS           ,
  output wire [                63:0] DEBUG,
output wire VALID_INFO
);
  // (https://www.pcisig.com/developers/main/training_materials/get_document?doc_id=00941b570381863f8cc97850d46c0597e919a34b)
  localparam c_req_attr = 3'b000; //ID based ordering, Relaxed ordering, No Snoop
  localparam c_req_tc   = 3'b000;



  ////////////
  //  c2s fifo management
  ////////////
  /*

  The data that is previously stored in a fifo (AXI Stream FIFO), is
  read and stored in a circular buffer. It simplifies the process of
  manage VALID and READY signals in the protocol.

  */
  wire [               255:0] c2s_fifo_tdata_s;
  wire [C_AXI_KEEP_WIDTH-1:0] c2s_fifo_tkeep_s;

  wire         c2s_fifo_tready_s      ;
  wire         c2s_fifo_tlast_s       ;
  wire         c2s_fifo_tvalid_s      ;
  reg  [127:0] c2s_buffer       [0:15];
  wire [  4:0] c2s_buf_occupancy      ;
  wire         c2s_buf_full           ;
  reg  [  4:0] c2s_buf_rd_ptr         ;
  reg  [  4:0] c2s_buf_wr_ptr         ;



  wire                        c2s_proc_tready_s;
  wire [C_BUS_DATA_WIDTH-1:0] c2s_proc_tdata_s ;
  wire                        c2s_proc_tlast_s ;
  wire                        c2s_proc_tvalid_s;
  wire [C_AXI_KEEP_WIDTH-1:0] c2s_proc_tkeep_s ;



  assign c2s_proc_tready_s = c2s_fifo_tready_s;
  assign c2s_fifo_tkeep_s  = c2s_proc_tkeep_s;

  assign c2s_fifo_tdata_s  = c2s_proc_tdata_s;
  assign c2s_fifo_tlast_s  = c2s_proc_tlast_s;
  assign c2s_fifo_tvalid_s = c2s_proc_tvalid_s;

  assign c2s_buf_occupancy = c2s_buf_wr_ptr - c2s_buf_rd_ptr;
  assign c2s_buf_full      = c2s_buf_occupancy[4];
  assign c2s_fifo_tready_s = (c2s_buf_occupancy <= 12) && ENGINE_VALID && !pause_engine_s;

  function [3:0] trunc(input [4:0] value);
    trunc = value[3:0];
  endfunction


  integer i;

  always @(negedge RST_N or posedge CLK) begin
    if (!RST_N) begin
      c2s_buf_wr_ptr <= 4'b0;
      for(i=0; i<16;i=i+1)
        c2s_buffer[i] <= 128'h0;
    end else begin
      if (c2s_fifo_tvalid_s && c2s_fifo_tready_s) begin
        c2s_buffer[trunc(c2s_buf_wr_ptr)]   <= c2s_fifo_tdata_s[127:0];
        c2s_buffer[trunc(c2s_buf_wr_ptr+1)] <= c2s_fifo_tdata_s[255:128];

        if(c2s_fifo_tkeep_s[C_AXI_KEEP_WIDTH/2]) begin // The two 64b words are valid
          c2s_buf_wr_ptr <= c2s_buf_wr_ptr + 2;
        end else begin                                 // just one word is valid
          c2s_buf_wr_ptr <= c2s_buf_wr_ptr + 1;
        end
      end
    end
  end



  ////////////
  //  End of C2S fifo management.
  ////////////

  reg [C_BUS_DATA_WIDTH-1:0] axis_rq_tdata_r ;
  reg                        axis_rq_tlast_r ;
  reg [C_BUS_KEEP_WIDTH-1:0] axis_rq_tkeep_r ;
  reg                        axis_rq_tvalid_r;
  reg [                 3:0] first_be_r      ;
  reg [                 3:0] last_be_r       ;



  wire [63:0] log2_max_words_tlp_s;
  wire [63:0] max_words_tlp_s     ;
  assign log2_max_words_tlp_s = C_LOG2_MAX_PAYLOAD-2; // "Words" refers to 4 byte
  assign max_words_tlp_s      = { {64-C_LOG2_MAX_PAYLOAD-1{1'b0}},1'b1, {C_LOG2_MAX_PAYLOAD-2{1'b0}} }; //(1<<(C_LOG2_MAX_PAYLOAD-2)); //32  bit words

  wire [63:0] log2_max_words_read_request_s;
  wire [63:0] max_words_read_request_s     ;
  assign log2_max_words_read_request_s = C_LOG2_MAX_READ_REQUEST-2; //32 (2**5) bit words
  assign max_words_read_request_s      = { {64-C_LOG2_MAX_READ_REQUEST-1{1'b0}},1'b1, {C_LOG2_MAX_READ_REQUEST-2{1'b0}} }; // (1<<(C_LOG2_MAX_READ_REQUEST-2)); //32 (2**5) bit words


  reg [15:0] state                              ;
  reg [15:0] wr_state                           ;
  reg [15:0] rd_state                           ;
  reg [31:0] mem_wr_current_tlp_r               ; //Current TLP.
  reg [31:0] mem_rd_current_tlp_r               ; //Current TLP.
  reg [63:0] mem_wr_total_words_r               ; //Total number of 4-bytes words to transfer
  reg [63:0] mem_rd_total_words_r               ; //Total number of 4-bytes words to transfer
  reg [63:0] mem_wr_remaining_words_r           ; // Total number of 4-bytes words in the current TLP
  reg [ 3:0] mem_wr_next_remainder_r            ;
  reg [63:0] mem_rd_remaining_words_r           ; // Total number of 4-bytes words in the current TLP
  reg [31:0] mem_wr_total_tlp_r                 ; // Total number of TLPs to communicate
  reg [63:0] mem_wr_last_tlp_words_r            ; // Words in the last TLP, the rest will have the maximum size
  reg [31:0] mem_rd_total_tlp_r                 ; // Total number of TLPs to communicate
  reg [63:0] mem_rd_last_tlp_words_r            ; // Words in the last TLP, the rest will have the maximum size
  reg [63:0] mem_wr_addr_pointed_by_descriptor_r; // Region communicated by the user in the descriptor
  reg [63:0] mem_rd_addr_pointed_by_descriptor_r; // Region communicated by the user in the descriptor
  reg [15:0] wr_state_pipe_r                    ; // Previous value of the state wr_state
  reg [15:0] rd_state_pipe_r; // Previous value of the state rd_state

  assign DEBUG = { mem_rd_current_tlp_r[15:0], state, wr_state, rd_state };

  // States of the FSMs.
  localparam IDLE       = 16'h0;
  localparam INIT_WRITE = 16'h1;
  localparam WRITE      = 16'h2;
  localparam INIT_READ  = 16'h3;
  localparam WAIT_READ  = 16'h4;
  localparam WAIT_RD_OP = 16'h5;
  localparam WAIT_WR_OP = 16'h6;




  //"Capabilities_s" indicates if the engine will generate memory write requests o memory read requests
  wire [1:0] capabilities_s;
  assign capabilities_s = STATUS_BYTE[6:5];

  wire pause_engine_s;
  reg  pause_engine_r;
  wire is_end_of_operation_s;
  assign is_end_of_operation_s = ((wr_state_pipe_r!=wr_state) && (wr_state==IDLE)) || (rd_state_pipe_r!=rd_state) && (rd_state==IDLE);
  assign pause_engine_s        = (is_end_of_operation_s && M_AXIS_RQ_TREADY==0) || pause_engine_r;

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      pause_engine_r <= 0;
    end else begin
      if(pause_engine_s && M_AXIS_RQ_TREADY==0) begin
        pause_engine_r <= 1'b1;
      end else begin
        pause_engine_r <= 1'b0;
      end
    end
  end
  assign CONTROL_BYTE = {2'h0, pause_engine_s, 1'b0, is_end_of_operation_s, 3'h0 }; // Waiting completer, Stop will coincide with tlast


  /*
  Main FSM where a selected engine is treated. There are three FSMs:
  a) IDLE, WAIT_RD_OP, WAIT_WR_OP:
  Just indicates which action is being taken.
  b) IDLE, INIT_WRITE, WRITE:
  In a memory write request:
  IDLE       -> Do nothing.
  INIT_WRITE -> Specify the TLP header and the first 128 bits of data
  WIRTE      -> The rest of the package
  c) INIT_READ, WAIT_READ:
  In a memory read request:
  IDLE       -> Do nothing.
  INIT_READ  -> Specify the TLP header if the tag is not busy. Repeat until all the request has been processed.
  WAIT_READ  -> Wait for all the TLPs of a memory read request.
  */

  reg [31:0] byte_en_r;
  reg        is_sop_r ;

  assign M_AXIS_RQ_TDATA  = axis_rq_tdata_r;
  assign M_AXIS_RQ_TUSER  = {52'h0, last_be_r, first_be_r};
  assign M_AXIS_RQ_TLAST  = axis_rq_tlast_r;
  assign M_AXIS_RQ_TKEEP  = axis_rq_tkeep_r;
  assign M_AXIS_RQ_TVALID = axis_rq_tvalid_r;




  reg [7:0] req_tag_r; // Current tag for a memory read request (for memory writes let the
  // EP to choose it automatically).
  reg  [C_WINDOW_SIZE-1:0] req_tag_oh_r                     ; // Same as req_tag_r but in one hot codification
  reg  [C_WINDOW_SIZE-1:0] current_tags_r                   ; // Number of asked tags (memory read) that hasnt been received yet.
  wire [              7:0] c2s_rq_tag_s                     ; // Number of asked tags (memory read) that hasnt been received yet.
  reg  [             10:0] size_tags_r   [C_WINDOW_SIZE-1:0]; // Number of expected dwords (for each tag)




  genvar j;
  // Verilog doesnt let us to communicate an array to the external world. We express it as a big vector.
  for(j=0; j<C_WINDOW_SIZE;j=j+1) begin
    assign SIZE_TAGS[11*(j+1)-1:11*j] = size_tags_r[j];
  end
  function [7:0] bit2pos(input [C_WINDOW_SIZE-1:0] oh);
    integer k;
    begin
      bit2pos = 0;
      for (k=0; k<C_WINDOW_SIZE; k=k+1) begin
        if (oh[k]) bit2pos = k;
      end
    end
  endfunction

  ////////
  // Logic that creates the Memory Write request TLPs (header and  data).
  // DATA and VALID signals are given value in this process
  reg [C_WINDOW_SIZE-1:0] pending_error_r;

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      pending_error_r <= 0;
    end else begin
      if(ERROR_TAGS) begin
        pending_error_r <= ERROR_TAGS;
      end else if (M_AXIS_RQ_TREADY) begin
        pending_error_r <= 0;
      end else begin
        pending_error_r <= pending_error_r;
      end
    end
  end

  wire last_word_at_tlp_s     ;
  wire last_two_words_at_tlp_s;
  wire one_word_at_buffer_s   ;
  wire two_words_at_buffer_s  ;

  assign last_word_at_tlp_s      = mem_wr_remaining_words_r <= 4;
  assign last_two_words_at_tlp_s = mem_wr_remaining_words_r <= 8;
  assign one_word_at_buffer_s    = c2s_buf_occupancy!=0;
  assign two_words_at_buffer_s   = c2s_buf_occupancy[4:1]!=0;

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      axis_rq_tvalid_r <= 1'b0;
      axis_rq_tdata_r  <= {C_BUS_DATA_WIDTH{1'b0}};
      c2s_buf_rd_ptr   <= 5'h0;
    end else begin
      case(state)
        WAIT_WR_OP : begin
          case(wr_state)
            INIT_WRITE : begin // A TLP of type memory write has to be requested.
              if(M_AXIS_RQ_TREADY) begin
                // we are not looking for the descriptor. Configure ir properly when the s2c is completed.

                axis_rq_tdata_r <= {c2s_buffer[trunc(c2s_buf_rd_ptr)], //128 bits data
                  //DW 3
                  1'b0,      //Force ECRC insertion 31 - 1 bit reserved          127
                  c_req_attr,//30-28 3 bits Attr          124-126
                  c_req_tc,  // 27-25 3- bits         121-123
                  1'b0,      // Use bus and req id from the EP          120
                  16'h0000,  //xcompleter_id_bus,    // 23-16 Completer Bus number - selected if Compl ID    = 1  104-119
                  //completer_id_dev_func, //15-8 Compl Dev / Func no - sel if Compl ID = 1
                  c2s_rq_tag_s,  //req_tag 7-0 Client Tag 96-103
                  //DW 2
                  16'h0000,  // 31-16 Bus number - 16 bits Requester ID 80-95
                  // (optional fields, the endpoints IDs will be used if no id is specified)
                  1'b0,      // poisoned request 1'b0,          // 15 Rsvd    79
                  4'b0001,   // memory WRITE request      75-78
                  mem_wr_remaining_words_r[10:0],  // 10-0 DWord Count 0 - IO Write completions -64-74
                  //DW 1-0
                  mem_wr_addr_pointed_by_descriptor_r[63:2], 2'b00};  //62 bit word address address + 2 bit Address type (0, untranslated)

                if(one_word_at_buffer_s) begin
                  c2s_buf_rd_ptr   <= c2s_buf_rd_ptr + 1;
                  axis_rq_tvalid_r <= 1'b1;
                end else begin
                  axis_rq_tvalid_r <= 1'b0;
                end
              end else begin
                axis_rq_tvalid_r <= axis_rq_tvalid_r;
                axis_rq_tdata_r  <= axis_rq_tdata_r;
              end
            end

            WRITE : begin // A TLP of type memory write has to be requested.
              if( M_AXIS_RQ_TREADY) begin // Wait for the "ACK" of the previous TLP
                if( one_word_at_buffer_s && last_word_at_tlp_s ) begin
                  axis_rq_tdata_r  <= {128'h0, c2s_buffer[trunc(c2s_buf_rd_ptr)]};
                  c2s_buf_rd_ptr   <= c2s_buf_rd_ptr + 1;
                  axis_rq_tvalid_r <= 1'b1;
                end else if( two_words_at_buffer_s ) begin
                  axis_rq_tdata_r  <= {c2s_buffer[trunc(c2s_buf_rd_ptr+1)], c2s_buffer[trunc(c2s_buf_rd_ptr)]};
                  c2s_buf_rd_ptr   <= c2s_buf_rd_ptr + 2;
                  axis_rq_tvalid_r <= 1'b1;
                end else begin
                  axis_rq_tvalid_r <= 1'b0;
                end
              end else begin
                axis_rq_tdata_r  <= axis_rq_tdata_r;
                axis_rq_tvalid_r <= axis_rq_tvalid_r;
              end
            end
            default : begin
              if(M_AXIS_RQ_TREADY) begin
                axis_rq_tvalid_r <= 1'b0;
                axis_rq_tdata_r  <= {C_BUS_DATA_WIDTH{1'b0}};
              end else begin
                axis_rq_tvalid_r <= axis_rq_tvalid_r;
                axis_rq_tdata_r  <= axis_rq_tdata_r;
              end
            end
          endcase
        end
        WAIT_RD_OP : begin
          case(rd_state)
            INIT_READ : begin
              if(M_AXIS_RQ_TREADY && pending_error_r) begin // There was an error an we have to order again a transference.
                // In this case the size is equal to max_words_read_request_s
                // The address has to be decremented. Get the integer from the Onehot Codification and substract the position of pending_error_r  to the one  provenient from req_tag_oh_r
                //DW 7-4
                axis_rq_tdata_r <= { 128'h0, //128 bits data
                  //DW 3
                  1'b0,      //31 - 1 bit reserved
                  c_req_attr, //30-28 3 bits Attr
                  c_req_tc,   // 27-25 3- bits
                  1'b0,      // 24 req_id enable
                  16'h0,  //xcompleter_id_bus,     -- 23-16 Completer Bus number - selected if Compl ID    = 1
                  //completer_id_dev_func, --15-8 Compl Dev / Func no - sel if Compl ID = 1
                  bit2pos(pending_error_r),  // 7-0 Client Tag
                  //DW 2
                  16'h0000, //req_rid,       -- 31-16 Requester ID - 16 bits
                  1'b0,      // poisoned request 1'b0,          -- 15 Rsvd
                  4'b0000,   // memory READ request
                  max_words_read_request_s[10:0],  // 10-0 DWord Count 0 - IO Write completions
                  //DW 1-0
                  bit2pos(pending_error_r)>=bit2pos(req_tag_oh_r) ?
                  mem_rd_addr_pointed_by_descriptor_r[63:2] - ((bit2pos(req_tag_oh_r)-bit2pos(pending_error_r)+C_WINDOW_SIZE)<<log2_max_words_read_request_s)
                  : mem_rd_addr_pointed_by_descriptor_r[63:2] - ((bit2pos(req_tag_oh_r)-bit2pos(pending_error_r))<<log2_max_words_read_request_s),2'b00 }; //62 bit word address address + 2 bit Address type (0, untranslated)

                axis_rq_tvalid_r <= 1'b1;
              end else if(M_AXIS_RQ_TREADY && !(req_tag_oh_r & current_tags_r)) begin
                //DW 7-4
                axis_rq_tdata_r <= { 128'h0, //128 bits data
                  //DW 3
                  1'b0,      //31 - 1 bit reserved
                  c_req_attr, //30-28 3 bits Attr
                  c_req_tc,   // 27-25 3- bits
                  1'b0,      // 24 req_id enable
                  16'h0,  //xcompleter_id_bus,     -- 23-16 Completer Bus number - selected if Compl ID    = 1
                  //completer_id_dev_func, --15-8 Compl Dev / Func no - sel if Compl ID = 1
                  req_tag_r,  // 7-0 Client Tag
                  //DW 2
                  16'h0000, //req_rid,       -- 31-16 Requester ID - 16 bits
                  1'b0,      // poisoned request 1'b0,          -- 15 Rsvd
                  4'b0000,   // memory READ request
                  mem_rd_remaining_words_r[10:0],  // 10-0 DWord Count 0 - IO Write completions
                  //DW 1-0
                  mem_rd_addr_pointed_by_descriptor_r[63:2],2'b00 }; //62 bit word address address + 2 bit Address type (0, untranslated)

                axis_rq_tvalid_r <= 1'b1;
              end else if(!M_AXIS_RQ_TREADY) begin
                axis_rq_tvalid_r <= axis_rq_tvalid_r;
                axis_rq_tdata_r  <= axis_rq_tdata_r;
              end else begin
                axis_rq_tvalid_r <= 1'b0;
              end
            end
            WAIT_READ : begin
              if(M_AXIS_RQ_TREADY && pending_error_r) begin // There was an error an we have to order again a transference.
                // In this case the size is equal to max_words_read_request_s
                // The address has to be decremented. Get the integer from the Onehot Codification and substract the position of pending_error_r  to the one  provenient from req_tag_oh_r
                //DW 7-4
                axis_rq_tdata_r <= { 128'h0, //128 bits data
                  //DW 3
                  1'b0,      //31 - 1 bit reserved
                  c_req_attr, //30-28 3 bits Attr
                  c_req_tc,   // 27-25 3- bits
                  1'b0,      // 24 req_id enable
                  16'h0,  //xcompleter_id_bus,     -- 23-16 Completer Bus number - selected if Compl ID    = 1
                  //completer_id_dev_func, --15-8 Compl Dev / Func no - sel if Compl ID = 1
                  bit2pos(pending_error_r),  // 7-0 Client Tag
                  //DW 2
                  16'h0000, //req_rid,       -- 31-16 Requester ID - 16 bits
                  1'b0,      // poisoned request 1'b0,          -- 15 Rsvd
                  4'b0000,   // memory READ request
                  (bit2pos(pending_error_r)==bit2pos(req_tag_oh_r)-1) ||
                  pending_error_r == (1<<(C_WINDOW_SIZE-1)) && req_tag_oh_r==1 ?
                  mem_rd_last_tlp_words_r[10:0]
                  : max_words_read_request_s[10:0],  // 10-0 DWord Count 0 - IO Write completions
                  //DW 1-0
                  bit2pos(pending_error_r)>=bit2pos(req_tag_oh_r) ?
                  mem_rd_addr_pointed_by_descriptor_r[63:2] - ((bit2pos(req_tag_oh_r)-bit2pos(pending_error_r)+C_WINDOW_SIZE)<<log2_max_words_read_request_s)
                  : mem_rd_addr_pointed_by_descriptor_r[63:2] - ((bit2pos(req_tag_oh_r)-bit2pos(pending_error_r))<<log2_max_words_read_request_s),2'b00 }; //62 bit word address address + 2 bit Address type (0, untranslated)

                axis_rq_tvalid_r <= 1'b1;
              end else if(M_AXIS_RQ_TREADY) begin
                axis_rq_tvalid_r <= 1'b0;
                axis_rq_tdata_r  <= {C_BUS_DATA_WIDTH{1'b0}};
              end else begin
                axis_rq_tvalid_r <= axis_rq_tvalid_r;
                axis_rq_tdata_r  <= axis_rq_tdata_r;
              end

            end
            default : begin
              if(M_AXIS_RQ_TREADY) begin
                axis_rq_tvalid_r <= 1'b0;
                axis_rq_tdata_r  <= {C_BUS_DATA_WIDTH{1'b0}};
              end else begin
                axis_rq_tvalid_r <= axis_rq_tvalid_r;
                axis_rq_tdata_r  <= axis_rq_tdata_r;
              end
            end
          endcase
        end
        default : begin
          if(M_AXIS_RQ_TREADY) begin
            axis_rq_tvalid_r <= 1'b0;
            axis_rq_tdata_r  <= {C_BUS_DATA_WIDTH{1'b0}};
          end else begin
            axis_rq_tvalid_r <= axis_rq_tvalid_r;
            axis_rq_tdata_r  <= axis_rq_tdata_r;
          end
        end
      endcase
    end
  end

  // Logic that counts the number of bytes transferred (memory write request).
  reg [63:0] previous_byte_transfer_r;
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      BYTE_COUNT <= 64'h0;
    end else begin
      if(M_AXIS_RQ_TREADY) begin
        BYTE_COUNT <= previous_byte_transfer_r;
      end else begin
        BYTE_COUNT <= BYTE_COUNT;
      end
    end
  end


  ////////
  // Logic that manages KEEP and LAST signals. Large and tedious but simple in logic.


  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      previous_byte_transfer_r <= 64'h0;
      axis_rq_tkeep_r          <= {C_BUS_KEEP_WIDTH{1'b0}};
      axis_rq_tlast_r          <= 1'b0;
      first_be_r               <= 4'h0;
      last_be_r                <= 4'h0;
    end else begin
      is_sop_r <= 1'b0;

      if(M_AXIS_RQ_TREADY && wr_state == INIT_WRITE) begin // A TLP of type memory write has to be requested.
        is_sop_r <= 1'b1;

        if( mem_wr_current_tlp_r >= mem_wr_total_tlp_r ) begin
          if(mem_wr_last_tlp_words_r > 1) begin
            first_be_r <= 4'hf;
            case(SIZE_AT_DESCRIPTOR[1:0])
              2'b01   : last_be_r   <= 4'h1;
              2'b10   : last_be_r   <= 4'h3;
              2'b11   : last_be_r   <= 4'h7;
              default : last_be_r   <= 4'hf;
            endcase
          end else begin
            last_be_r <= 4'h0;
            case(SIZE_AT_DESCRIPTOR[1:0])
              2'b01   : first_be_r   <= 4'h1;
              2'b10   : first_be_r   <= 4'h3;
              2'b11   : first_be_r   <= 4'h7;
              default : first_be_r   <= 4'hf;
            endcase
          end
        end else begin
          first_be_r <= 4'hf;
          last_be_r  <= 4'hf;
        end
        if( M_AXIS_RQ_TREADY && one_word_at_buffer_s ) begin
          if(last_word_at_tlp_s) begin
            axis_rq_tlast_r          <= 1'b1;
            previous_byte_transfer_r <= {mem_wr_remaining_words_r[58:0],5'h0}+128;

            axis_rq_tkeep_r <= mem_wr_next_remainder_r==0 ? 8'h0f :
              mem_wr_next_remainder_r == 1 ? 8'h1f :
              mem_wr_next_remainder_r == 2 ? 8'h3f :
              mem_wr_next_remainder_r == 3 ? 8'h7f : 8'hff;
          end else begin
            axis_rq_tkeep_r          <= 8'hff;
            previous_byte_transfer_r <= 64'd256;
            axis_rq_tlast_r          <= 1'b0;
          end
        end else if(M_AXIS_RQ_TREADY) begin
          axis_rq_tkeep_r          <= 8'h00;
          previous_byte_transfer_r <= 64'h0;
          axis_rq_tlast_r          <= 1'b0;
        end else begin
          axis_rq_tkeep_r          <= axis_rq_tkeep_r;
          previous_byte_transfer_r <= 64'h0;
          axis_rq_tlast_r          <= axis_rq_tlast_r;
        end
      end else if(M_AXIS_RQ_TREADY && wr_state == WRITE) begin // A TLP of type memory write has to be requested.
        if(M_AXIS_RQ_TREADY && (two_words_at_buffer_s || (one_word_at_buffer_s && last_word_at_tlp_s))) begin
          previous_byte_transfer_r <= 64'd256;
          axis_rq_tlast_r          <= last_two_words_at_tlp_s;
          previous_byte_transfer_r <= last_two_words_at_tlp_s ? {mem_wr_remaining_words_r[58:0],5'h0} :  64'd256; // Equivalence 1 word = 32B


          axis_rq_tkeep_r <= mem_wr_next_remainder_r==0 ? 8'h00 :
            mem_wr_next_remainder_r == 1 ? 8'h01 :
            mem_wr_next_remainder_r == 2 ? 8'h03 :
            mem_wr_next_remainder_r == 3 ? 8'h07 :
            mem_wr_next_remainder_r == 4 ? 8'h0f :
            mem_wr_next_remainder_r == 5 ? 8'h1f :
            mem_wr_next_remainder_r == 6 ? 8'h3f :
            mem_wr_next_remainder_r == 7 ? 8'h7f : 8'hff;
        end else begin
          previous_byte_transfer_r <= 64'h0;
          axis_rq_tlast_r          <= axis_rq_tlast_r;
        end

      end else if( M_AXIS_RQ_TREADY && (rd_state == INIT_READ || rd_state == WAIT_READ) ) begin
        axis_rq_tkeep_r <= 8'h0f;
        axis_rq_tlast_r <= 1'b1;

        if( mem_rd_current_tlp_r >= mem_rd_total_tlp_r ) begin
          if(mem_rd_last_tlp_words_r <= 1) begin
            first_be_r <= 4'hf;
            last_be_r  <= 4'h0; // First word and last are the same, so last_be = 0
          end else begin
            first_be_r <= 4'hf;
            last_be_r  <= 4'hf;
          end
        end else begin
          first_be_r <= 4'hf;
          last_be_r  <= 4'hf;
        end

      end else begin
        if(M_AXIS_RQ_TREADY) begin
          axis_rq_tkeep_r          <= 8'h0;
          previous_byte_transfer_r <= 64'd0;
          axis_rq_tlast_r          <= 1'b0;
        end else begin
          axis_rq_tkeep_r          <= axis_rq_tkeep_r;
          previous_byte_transfer_r <= previous_byte_transfer_r;
          axis_rq_tlast_r          <= axis_rq_tlast_r;
        end
      end
    end
  end


  ////////
  // Get the total numbers of words and the total numer of TLPs in a transition

  wire size_change_s;
  reg  size_change_r;

  always @(negedge RST_N or posedge CLK) begin
    if (!RST_N) begin
      mem_wr_total_tlp_r      <= 32'b0;
      mem_wr_total_words_r    <= 64'b0;
      mem_wr_last_tlp_words_r <= 64'h0;
    end else begin
      if(ENGINE_VALID && (wr_state == IDLE || size_change_r)) begin
        mem_wr_total_words_r <= SIZE_AT_DESCRIPTOR[1:0] == 0 ? SIZE_AT_DESCRIPTOR[63:2] : SIZE_AT_DESCRIPTOR[63:2] + 1;

        if(SIZE_AT_DESCRIPTOR[C_LOG2_MAX_PAYLOAD-1:0] > 0) begin // Get the modulus 2**(log2_max_words_tlp_s)
          mem_wr_total_tlp_r <= (SIZE_AT_DESCRIPTOR>>(log2_max_words_tlp_s+2))  + 1; // Express size at descriptor as 32 bit word.
          if(SIZE_AT_DESCRIPTOR[1:0] != 0) begin
            mem_wr_last_tlp_words_r <= ((SIZE_AT_DESCRIPTOR&{C_LOG2_MAX_PAYLOAD{1'b1}}) >> 2) + 1;
          end else begin
            mem_wr_last_tlp_words_r <= ((SIZE_AT_DESCRIPTOR&{C_LOG2_MAX_PAYLOAD{1'b1}}) >> 2) ;
          end
        end else begin
          mem_wr_total_tlp_r      <= SIZE_AT_DESCRIPTOR>>(log2_max_words_tlp_s+2);
          mem_wr_last_tlp_words_r <= max_words_tlp_s;
        end
      end else begin
        mem_wr_total_tlp_r      <= mem_wr_total_tlp_r;
        mem_wr_total_words_r    <= mem_wr_total_words_r;
        mem_wr_last_tlp_words_r <= mem_wr_last_tlp_words_r;
      end
    end
  end


  always @(negedge RST_N or posedge CLK) begin
    if (!RST_N) begin
      mem_rd_total_tlp_r      <= 32'b0;
      mem_rd_total_words_r    <= 64'b0;
      mem_rd_last_tlp_words_r <= 64'h0;
    end else begin
      if(ENGINE_VALID) begin
        mem_rd_total_words_r <= SIZE_AT_DESCRIPTOR[1:0] == 0 ? SIZE_AT_DESCRIPTOR[63:2] : SIZE_AT_DESCRIPTOR[63:2] + 1;

        if(SIZE_AT_DESCRIPTOR[C_LOG2_MAX_READ_REQUEST-1:0] > 0) begin // Get the modulus 2**(log2_max_words_read_request_s)
          mem_rd_total_tlp_r <= (SIZE_AT_DESCRIPTOR>>(log2_max_words_read_request_s+2))  + 1;
          if(SIZE_AT_DESCRIPTOR[1:0] != 0) begin
            mem_rd_last_tlp_words_r <= ((SIZE_AT_DESCRIPTOR&{C_LOG2_MAX_READ_REQUEST{1'b1}}) >> 2) + 1;
          end else begin
            mem_rd_last_tlp_words_r <= ((SIZE_AT_DESCRIPTOR&{C_LOG2_MAX_READ_REQUEST{1'b1}}) >> 2) ;
          end
        end else begin
          mem_rd_total_tlp_r      <= SIZE_AT_DESCRIPTOR>>(log2_max_words_read_request_s+2);  // Size at descriptor in 4-bytes word
          mem_rd_last_tlp_words_r <= max_words_read_request_s;
        end

      end else begin
        mem_rd_total_tlp_r      <= mem_rd_total_tlp_r;
        mem_rd_total_words_r    <= mem_rd_total_words_r;
        mem_rd_last_tlp_words_r <= mem_rd_last_tlp_words_r;
      end
    end
  end

  ////////
  // · Infer the number of words in the current TLP


  wire        propagate_change_s       ;
  reg         propagate_change_r       ;
  reg  [63:0] size_at_descriptor_pipe_r;
  assign size_change_s = size_at_descriptor_pipe_r!=SIZE_AT_DESCRIPTOR;
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      size_at_descriptor_pipe_r <= 64'b0;
      size_change_r             <= 1'b0;
      propagate_change_r        <= 1'b0;
    end else begin
      size_at_descriptor_pipe_r <= SIZE_AT_DESCRIPTOR;
      size_change_r             <= !one_word_at_buffer_s ? size_change_s|size_change_r : size_change_s;
      propagate_change_r        <= size_change_r;
    end
  end

  assign propagate_change_s = propagate_change_r;
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      mem_wr_remaining_words_r <= 64'h0;
      mem_wr_next_remainder_r  <= 64'h0;
    end else begin

      if(state == IDLE) begin
        if(ENGINE_VALID) begin
          if(SIZE_AT_DESCRIPTOR[1:0] == 0 ) begin // The modulus is 0: Check if we just send 1 packet
            mem_wr_remaining_words_r <= SIZE_AT_DESCRIPTOR[63:2] <= max_words_tlp_s ? SIZE_AT_DESCRIPTOR[63:2] : max_words_tlp_s;
            mem_wr_next_remainder_r  <= SIZE_AT_DESCRIPTOR[63:2] <= max_words_tlp_s ? SIZE_AT_DESCRIPTOR[63:2] : max_words_tlp_s;
          end else begin
            mem_wr_remaining_words_r <= SIZE_AT_DESCRIPTOR[63:2] <  max_words_tlp_s ? SIZE_AT_DESCRIPTOR[63:2] + 1 : max_words_tlp_s;
            mem_wr_next_remainder_r  <= SIZE_AT_DESCRIPTOR[63:2] <  max_words_tlp_s ? SIZE_AT_DESCRIPTOR[63:2] + 1 : max_words_tlp_s;
          end
        end else begin
          mem_wr_remaining_words_r <= 64'h0;
        end
      end else if( wr_state == INIT_WRITE ) begin
        if( M_AXIS_RQ_TREADY && !pause_engine_r && propagate_change_s && (mem_wr_current_tlp_r >= mem_wr_total_tlp_r) && one_word_at_buffer_s) begin // A change in the size was requested but there is no data yet
          mem_wr_remaining_words_r <= mem_wr_last_tlp_words_r - 4;
          mem_wr_next_remainder_r  <= mem_wr_last_tlp_words_r - 4;
        end else if( propagate_change_s && (mem_wr_current_tlp_r >= mem_wr_total_tlp_r)) begin // A change in the size was requested but there is no data yet
          mem_wr_remaining_words_r <= mem_wr_last_tlp_words_r;
          mem_wr_next_remainder_r  <= mem_wr_last_tlp_words_r;
        end else if( M_AXIS_RQ_TREADY && !pause_engine_r && one_word_at_buffer_s ) begin
          if(mem_wr_remaining_words_r > 4) begin
            mem_wr_remaining_words_r <= mem_wr_remaining_words_r - 4;
            mem_wr_next_remainder_r  <= mem_wr_next_remainder_r - 4;
          end else begin
            mem_wr_remaining_words_r <= mem_wr_current_tlp_r == mem_wr_total_tlp_r ? mem_wr_last_tlp_words_r : max_words_tlp_s;
            mem_wr_next_remainder_r  <= mem_wr_current_tlp_r == mem_wr_total_tlp_r ? mem_wr_last_tlp_words_r : max_words_tlp_s;
          end
        end
      end else begin // State == WRITE
        if(M_AXIS_RQ_TREADY && !pause_engine_r && one_word_at_buffer_s && last_word_at_tlp_s) begin
          if(mem_wr_current_tlp_r == mem_wr_total_tlp_r - 1) begin
            mem_wr_remaining_words_r <= mem_wr_last_tlp_words_r;
            mem_wr_next_remainder_r  <= mem_wr_last_tlp_words_r;
          end else begin
            mem_wr_remaining_words_r <= max_words_tlp_s;
            mem_wr_next_remainder_r  <= max_words_tlp_s;
          end
        end else if( M_AXIS_RQ_TREADY && !pause_engine_r && two_words_at_buffer_s ) begin
          if(mem_wr_remaining_words_r > 8) begin
            mem_wr_remaining_words_r <= mem_wr_remaining_words_r - 8;
            mem_wr_next_remainder_r  <= mem_wr_next_remainder_r - 8;
          end else begin
            if(mem_wr_current_tlp_r == mem_wr_total_tlp_r - 1) begin
              mem_wr_remaining_words_r <= mem_wr_last_tlp_words_r;
              mem_wr_next_remainder_r  <= mem_wr_last_tlp_words_r;
            end else begin
              mem_wr_remaining_words_r <= max_words_tlp_s;
              mem_wr_next_remainder_r  <= max_words_tlp_s;
            end
          end
        end
      end
    end
  end

  always @(negedge RST_N or posedge CLK) begin
    if (!RST_N) begin
      mem_rd_remaining_words_r <= 64'h0;
    end else begin
      if(state == IDLE && ENGINE_VALID) begin
        if(SIZE_AT_DESCRIPTOR[1:0] == 0 && SIZE_AT_DESCRIPTOR[63:2]  <=  max_words_read_request_s) begin // Get the modulus 2**(log2_max_words_read_request_s+2)
          mem_rd_remaining_words_r <= SIZE_AT_DESCRIPTOR[63:2];
        end else if((SIZE_AT_DESCRIPTOR[1:0] != 0) && SIZE_AT_DESCRIPTOR[63:2]  <  max_words_read_request_s) begin
          mem_rd_remaining_words_r <= SIZE_AT_DESCRIPTOR[63:2] + 1;
        end else begin
          mem_rd_remaining_words_r <= max_words_read_request_s;
        end

      end else begin

        if(rd_state == INIT_READ && M_AXIS_RQ_TREADY && ((!(req_tag_oh_r & current_tags_r)  && mem_rd_current_tlp_r >= mem_rd_total_tlp_r-1) || mem_rd_current_tlp_r >= mem_rd_total_tlp_r )) begin // Update Tag
          mem_rd_remaining_words_r <= mem_rd_last_tlp_words_r;
        end else begin
          mem_rd_remaining_words_r <= max_words_read_request_s;
        end
      end
    end
  end

  // JF: 30/03/2016. The code does not match exactly (check first condition)
  //  I suppose that everything should work, but I mantain this code here
  // just in case.
  /*
  always @(negedge RST_N or posedge CLK) begin
  if(!RST_N) begin
  mem_wr_addr_pointed_by_descriptor_r <= 64'b0;
  mem_wr_current_tlp_r                <= 32'h0;
  end else begin
  if (ENGINE_VALID && M_AXIS_RQ_TREADY && wr_state_pipe_r == IDLE) begin
  mem_wr_current_tlp_r                <= 32'h1;
  mem_wr_addr_pointed_by_descriptor_r <= ADDR_AT_DESCRIPTOR;
  end else if( (wr_state == INIT_WRITE) && (M_AXIS_RQ_TREADY && one_word_at_buffer_s) && (last_word_at_tlp_s)) begin
  mem_wr_current_tlp_r                <= mem_wr_current_tlp_r+1;
  mem_wr_addr_pointed_by_descriptor_r <= ADDR_AT_DESCRIPTOR + (mem_wr_current_tlp_r<<(log2_max_words_tlp_s+2));
  end else if( (wr_state == WRITE) && (M_AXIS_RQ_TREADY && two_words_at_buffer_s) && (last_two_words_at_tlp_s)) begin
  mem_wr_current_tlp_r                <= mem_wr_current_tlp_r+1;
  mem_wr_addr_pointed_by_descriptor_r <= ADDR_AT_DESCRIPTOR + (mem_wr_current_tlp_r<<(log2_max_words_tlp_s+2));
  end else if( (wr_state == WRITE) && (M_AXIS_RQ_TREADY && one_word_at_buffer_s) && (last_word_at_tlp_s)) begin
  mem_wr_current_tlp_r                <= mem_wr_current_tlp_r+1;
  mem_wr_addr_pointed_by_descriptor_r <= ADDR_AT_DESCRIPTOR + (mem_wr_current_tlp_r<<(log2_max_words_tlp_s+2));
  end else begin
  mem_wr_addr_pointed_by_descriptor_r <= mem_wr_addr_pointed_by_descriptor_r;
  mem_wr_current_tlp_r                <= mem_wr_current_tlp_r;
  end
  end
  end
  */

  /////////
  // Update the current TLP and memory offset
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      mem_wr_addr_pointed_by_descriptor_r <= 64'b0;
      mem_wr_current_tlp_r                <= 32'h0;
    end else begin
      case(wr_state)
        IDLE : begin
          //If we are starting a new operation (wr_state_pipe_r==IDLE), Restart the counter.
          if (ENGINE_VALID && M_AXIS_RQ_TREADY && !pause_engine_r && wr_state_pipe_r == IDLE) begin
            mem_wr_current_tlp_r                <= 32'h1;
            mem_wr_addr_pointed_by_descriptor_r <= ADDR_AT_DESCRIPTOR;
          end
        end
        INIT_WRITE : begin
          if(M_AXIS_RQ_TREADY) begin
            if((one_word_at_buffer_s) && (last_word_at_tlp_s)) begin
              mem_wr_current_tlp_r                <= mem_wr_current_tlp_r+1;
              mem_wr_addr_pointed_by_descriptor_r <= ADDR_AT_DESCRIPTOR + (mem_wr_current_tlp_r<<(log2_max_words_tlp_s+2));
            end
          end
        end
        WRITE : begin
          if(M_AXIS_RQ_TREADY) begin
            if((two_words_at_buffer_s && last_two_words_at_tlp_s) || (one_word_at_buffer_s && last_word_at_tlp_s)) begin
              mem_wr_current_tlp_r                <= mem_wr_current_tlp_r+1;
              mem_wr_addr_pointed_by_descriptor_r <= ADDR_AT_DESCRIPTOR + (mem_wr_current_tlp_r<<(log2_max_words_tlp_s+2));
            end
          end
        end
        default : begin
          mem_wr_addr_pointed_by_descriptor_r <= mem_wr_addr_pointed_by_descriptor_r;
          mem_wr_current_tlp_r                <= mem_wr_current_tlp_r;
        end

      endcase
    end
  end
  assign c2s_rq_tag_s = mem_wr_current_tlp_r-1;

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      mem_rd_addr_pointed_by_descriptor_r <= 64'b0;
      mem_rd_current_tlp_r                <= 32'h0;
    end else begin
      if (ENGINE_VALID && rd_state == IDLE && M_AXIS_RQ_TREADY && !pause_engine_r) begin
        mem_rd_current_tlp_r                <= 32'h1;
        mem_rd_addr_pointed_by_descriptor_r <= ADDR_AT_DESCRIPTOR;
      end else if( rd_state == INIT_READ && M_AXIS_RQ_TREADY && !(req_tag_oh_r & current_tags_r) ) begin
        mem_rd_current_tlp_r                <= mem_rd_current_tlp_r+1;
        mem_rd_addr_pointed_by_descriptor_r <= ADDR_AT_DESCRIPTOR + (mem_rd_current_tlp_r<<(log2_max_words_read_request_s+2));
      end else begin
        mem_rd_addr_pointed_by_descriptor_r <= mem_rd_addr_pointed_by_descriptor_r;
        mem_rd_current_tlp_r                <= mem_rd_current_tlp_r;
      end
    end
  end


  ////////
  // Update the current tag (memory read request)
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      req_tag_r    <= 8'h0;
      req_tag_oh_r <= {{C_WINDOW_SIZE{1'b0}}, 1'b1};
    end else begin
      if(rd_state == INIT_READ && M_AXIS_RQ_TREADY && !(req_tag_oh_r & current_tags_r)) begin // Update Tag
        if(req_tag_oh_r[C_WINDOW_SIZE-1]) begin        // Onehot codification.
          req_tag_oh_r <= {{C_WINDOW_SIZE{1'b0}}, 1'b1};
          req_tag_r    <= 8'h0;
        end else begin
          req_tag_oh_r <= req_tag_oh_r << 1;
          req_tag_r    <= req_tag_r + 1;
        end
      end else begin
        req_tag_r    <= req_tag_r;
        req_tag_oh_r <= req_tag_oh_r;
      end
    end
  end

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      current_tags_r <= 0;
      for(i=0; i<C_WINDOW_SIZE; i=i+1) begin
        size_tags_r[i] <= 0;
      end
    end else begin
      if(rd_state == INIT_READ && M_AXIS_RQ_TREADY && !(req_tag_oh_r & current_tags_r)) begin
        current_tags_r         <= (current_tags_r | req_tag_oh_r) & (~COMPLETED_TAGS); // Bitmask of active tags.
        size_tags_r[req_tag_r] <= mem_rd_remaining_words_r[10:0]; //How many bytes are we waiting?
      end else begin
        current_tags_r <= current_tags_r & (~COMPLETED_TAGS);
      end
    end
  end

  assign BUSY_TAGS = current_tags_r;



  ////////
  // Update the states of the FSMs
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      wr_state_pipe_r <= IDLE;
      rd_state_pipe_r <= IDLE;
    end else begin
      wr_state_pipe_r <= wr_state;
      rd_state_pipe_r <= rd_state;
    end
  end

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      state <= IDLE;
    end else begin
      case(state)
        IDLE : begin
          if(M_AXIS_RQ_TREADY) begin //Assure previous packets have been sent
            if( ENGINE_VALID && capabilities_s[0] && !pause_engine_r && (mem_wr_current_tlp_r <= mem_wr_total_tlp_r)) begin
              state <= WAIT_WR_OP;
            end else if( ENGINE_VALID && capabilities_s[1] && !pause_engine_r && (mem_rd_current_tlp_r <= mem_rd_total_tlp_r)) begin
              state <= WAIT_RD_OP;
            end else begin
              state <= IDLE;
            end
          end else begin
            state <= IDLE;
          end
        end
        WAIT_RD_OP : begin
          if(rd_state == IDLE) begin
            state <= IDLE;
          end else begin
            state <= WAIT_RD_OP;
          end
        end
        WAIT_WR_OP : begin
          if(wr_state == IDLE) begin
            state <= IDLE;
          end else begin
            state <= WAIT_WR_OP;
          end
        end
        default : begin
          state <= IDLE;
        end
      endcase
    end
  end

  ////////
  // FSM: memory write request
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      wr_state <= IDLE;
    end else begin
      case(wr_state)
        IDLE : begin
          if(M_AXIS_RQ_TREADY && ENGINE_VALID && capabilities_s[0] && !pause_engine_r && (mem_wr_current_tlp_r <= mem_wr_total_tlp_r)) begin  // C2S engine
            wr_state <= INIT_WRITE;
          end
        end
        INIT_WRITE : begin     // Write to the Completer the TLP header.
          if(M_AXIS_RQ_TREADY) begin
            if(mem_wr_total_tlp_r < mem_wr_current_tlp_r) begin // A hw update of the descriptor has been produced. Abort the operation.
              wr_state <= IDLE;
            end else if( !one_word_at_buffer_s ) begin // There is no data.
              wr_state <= INIT_WRITE;
            end else if(last_word_at_tlp_s) begin // We complete the transfer in one cycle
              if(mem_wr_total_tlp_r <= mem_wr_current_tlp_r) begin
                wr_state <= IDLE;
              end else begin
                wr_state = INIT_WRITE;
              end
            end else begin      //Else we have to send more packets
              wr_state <= WRITE;
            end
          end else begin
            wr_state <= INIT_WRITE;
          end
        end
        WRITE : begin          // Write to the Completer the rest of the information.
          if(M_AXIS_RQ_TREADY) begin
            if((last_word_at_tlp_s && one_word_at_buffer_s) || (last_two_words_at_tlp_s && two_words_at_buffer_s)) begin
              if(mem_wr_total_tlp_r <= mem_wr_current_tlp_r) begin
                wr_state <= IDLE;
              end else begin
                wr_state <= INIT_WRITE;
              end
            end else begin
              wr_state <= WRITE;
            end
          end else begin
            wr_state <= WRITE;
          end
        end
        default : begin
          wr_state <= IDLE;
        end
      endcase
    end
  end


  ////////
  // FSM: memory read request
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      rd_state <= IDLE;
    end else begin
      case(rd_state)
        IDLE : begin
          if(M_AXIS_RQ_TREADY && ENGINE_VALID && capabilities_s[1] && !pause_engine_r && (mem_rd_current_tlp_r <= mem_rd_total_tlp_r)) begin  // C2S engine
            rd_state <= INIT_READ;
          end
        end
        INIT_READ : begin
          if(M_AXIS_RQ_TREADY && !(req_tag_oh_r & current_tags_r) && mem_rd_current_tlp_r >= mem_rd_total_tlp_r) begin
            rd_state <= WAIT_READ;
          end else begin
            rd_state <= INIT_READ;
          end
        end
        WAIT_READ : begin // Wait for the last tlp.
          if(current_tags_r =={C_WINDOW_SIZE{1'b0}}) begin
            rd_state <= IDLE;
          end else begin
            rd_state <= WAIT_READ;
          end
        end
        default : begin
          rd_state <= IDLE;
        end
      endcase
    end
  end



  ////////
  // Split the data
  dma_rq_d2h_splitter #(
    .C_MODULE_IN_USE   (1                 ), // Force a  transmission if a C2S_TLAST is originated. 0 to just ignore this component (direct connection of AXI-Stream interfaces)
    .C_BUS_DATA_WIDTH  (C_BUS_DATA_WIDTH  ),
    .C_BUS_KEEP_WIDTH  (C_AXI_KEEP_WIDTH  ),
    .C_LOG2_MAX_PAYLOAD(C_LOG2_MAX_PAYLOAD)
  ) dma_rq_d2h_splitter_i (
    .CLK                      (CLK                      ),
    .RST_N                    (RST_N                    ),
    .C2S_FIFO_TREADY          (C2S_FIFO_TREADY          ),
    .C2S_FIFO_TDATA           (C2S_FIFO_TDATA           ),
    .C2S_FIFO_TLAST           (C2S_FIFO_TLAST           ),
    .C2S_FIFO_TVALID          (C2S_FIFO_TVALID          ),
    .C2S_FIFO_TKEEP           (C2S_FIFO_TKEEP           ),
    .C2S_PROC_TREADY          (c2s_proc_tready_s        ),
    .C2S_PROC_TDATA           (c2s_proc_tdata_s         ),
    .C2S_PROC_TLAST           (c2s_proc_tlast_s         ),
    .C2S_PROC_TVALID          (c2s_proc_tvalid_s        ),
    .C2S_PROC_TKEEP           (c2s_proc_tkeep_s         ),
    .ENGINE_STATE             (state                    ),
    .C2S_STATE                (wr_state                 ),
    .CURRENT_DESCRIPTOR_SIZE  (SIZE_AT_DESCRIPTOR       ),
    .DESCRIPTOR_MAX_TIMEOUT   (DESCRIPTOR_MAX_TIMEOUT   ),
    .HW_REQUEST_TRANSFERENCE  (HW_REQUEST_TRANSFERENCE  ),
    .HW_NEW_SIZE_AT_DESCRIPTOR(HW_NEW_SIZE_AT_DESCRIPTOR),
.VALID_INFO(VALID_INFO)
  );



endmodule
