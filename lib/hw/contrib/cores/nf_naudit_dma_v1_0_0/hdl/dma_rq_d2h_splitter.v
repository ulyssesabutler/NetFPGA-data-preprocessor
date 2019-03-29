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
@class dma_rq_d2h_splitter
@author      Jose Fernando Zazo Rollon (josefernando.zazo@naudit.es)
@date        05/11/2015
@brief This design just split the information into chunks when a TLAST is detected or a timeout is reached
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

module dma_rq_d2h_splitter #(
  parameter C_MODULE_IN_USE                = 1  ,
  parameter C_BUS_DATA_WIDTH               = 256,
  parameter                                           C_BUS_KEEP_WIDTH = (C_BUS_DATA_WIDTH/8),
  parameter C_MAX_SIMULTANEOUS_DESCRIPTORS = 2  ,
  parameter C_LOG2_MAX_PAYLOAD             = 8    // 2**C_LOG2_MAX_PAYLOAD in bytes
) (
  input  wire                        CLK                      ,
  input  wire                        RST_N                    ,
  ////////////
  //  c2s fifo interface: 1 AXI-Stream (data to be transferred in memory write requests)
  ////////////
  output wire                        C2S_FIFO_TREADY          ,
  input  wire [C_BUS_DATA_WIDTH-1:0] C2S_FIFO_TDATA           ,
  input  wire                        C2S_FIFO_TLAST           ,
  input  wire                        C2S_FIFO_TVALID          ,
  input  wire [C_BUS_KEEP_WIDTH-1:0] C2S_FIFO_TKEEP           ,
  ////////////
  //  Divided data: 1 AXI-Stream (data to be transferred in memory write requests). The descriptor has been corrected with the appropiate value
  //  if a TLAST has been detected.
  ////////////
  input  wire                        C2S_PROC_TREADY          ,
  output wire [C_BUS_DATA_WIDTH-1:0] C2S_PROC_TDATA           ,
  output wire                        C2S_PROC_TLAST           ,
  output wire                        C2S_PROC_TVALID          ,
  output wire [C_BUS_KEEP_WIDTH-1:0] C2S_PROC_TKEEP           ,
  ////////////
  //  Descriptor interface: Interface with the necessary data to complete a memory read/write request.
  ////////////
  input  wire [                15:0] ENGINE_STATE             ,
  input  wire [                15:0] C2S_STATE                ,
  input  wire [                63:0] CURRENT_DESCRIPTOR_SIZE  ,
  input  wire [                63:0] DESCRIPTOR_MAX_TIMEOUT   ,
  output wire                        HW_REQUEST_TRANSFERENCE  ,
  output wire [                63:0] HW_NEW_SIZE_AT_DESCRIPTOR,
output wire VALID_INFO
);


  generate if(C_MODULE_IN_USE) begin

      // States of the FSMs at the higher level
      localparam                                  IDLE       = 16'h0;
      localparam                                  INIT_WRITE = 16'h1;
      localparam                                  WRITE      = 16'h2;
      localparam                                  INIT_READ  = 16'h3;
      localparam                                  WAIT_READ  = 16'h4;
      localparam                                  WAIT_RD_OP = 16'h5;
      localparam                                  WAIT_WR_OP = 16'h6;





      // States of the FSMs at this level
      localparam                                  WAIT_DATA  = 16'h0;
      localparam                                  COM_CHANGE = 16'h1;
      localparam                                  NO_CHANGE  = 16'h2;
      localparam                                  WAIT_ENGINE  = 16'h3;
      localparam                                  RESTART_DESC  = 16'h4;


      assign max_words_tlp_s                      = { {64-C_LOG2_MAX_PAYLOAD-1{1'b0}},1'b1, {C_LOG2_MAX_PAYLOAD-2{1'b0}} }; //(1<<(C_LOG2_MAX_PAYLOAD-2)); //32  bit words


      wire [15:0] maximum_payload_size  = (1<<(C_LOG2_MAX_PAYLOAD));  // Number of words of bytes that conform a packet.
      wire [6:0] maximum_payload_dwords  = (1<<(C_LOG2_MAX_PAYLOAD-5)); // Number of words of 256b that conform a packet.
      wire       c2s_proc_fifo_tvalid_s;
      reg        c2s_proc_fifo_tready_r;


      wire c2s_fifo_fifo_tvalid_s;
      wire c2s_stream_fifo_tready_s;
      stream_fifo stream_fifo_i (
        .s_aclk       (CLK                                      ), // input wire s_aclk
        .s_aresetn    (RST_N                                    ), // input wire s_aresetn
        .s_axis_tvalid(c2s_fifo_fifo_tvalid_s                   ), // input wire s_axis_tvalid
        .s_axis_tready(c2s_stream_fifo_tready_s                 ), // output wire s_axis_tready
        .s_axis_tdata (C2S_FIFO_TDATA                           ), // input wire [255 : 0] s_axis_tdata
        .s_axis_tkeep (C2S_FIFO_TKEEP                           ), // input wire [31 : 0] s_axis_tkeep
        .s_axis_tlast (C2S_FIFO_TLAST                           ), // input wire s_axis_tlast
        .m_axis_tvalid(c2s_proc_fifo_tvalid_s                   ), // output wire m_axis_tvalid
        .m_axis_tready(C2S_PROC_TREADY  & c2s_proc_fifo_tready_r), // input wire m_axis_tready
        .m_axis_tdata (C2S_PROC_TDATA                           ), // output wire [255 : 0] m_axis_tdata
        .m_axis_tkeep (C2S_PROC_TKEEP                           ), // output wire [31 : 0] m_axis_tkeep
        .m_axis_tlast (C2S_PROC_TLAST                           )
      );
      assign C2S_PROC_TVALID = c2s_proc_fifo_tvalid_s & c2s_proc_fifo_tready_r;
      reg  [63:0]                                       desc_size_buffer [0:C_MAX_SIMULTANEOUS_DESCRIPTORS-1];
      reg  [C_MAX_SIMULTANEOUS_DESCRIPTORS-1:0]         desc_size_upd;
      wire [$clog2(C_MAX_SIMULTANEOUS_DESCRIPTORS):0]   desc_size_buf_occupancy;
      wire                                              desc_size_buf_full;
      reg  [$clog2(C_MAX_SIMULTANEOUS_DESCRIPTORS):0]   desc_size_buf_rd_ptr;
      reg  [$clog2(C_MAX_SIMULTANEOUS_DESCRIPTORS):0]   desc_size_buf_wr_ptr;


assign VALID_INFO = desc_size_buf_occupancy!=0 || C2S_PROC_TREADY;
      assign desc_size_buf_occupancy                    = desc_size_buf_wr_ptr - desc_size_buf_rd_ptr;
      assign desc_size_buf_full                         = desc_size_buf_occupancy[$clog2(C_MAX_SIMULTANEOUS_DESCRIPTORS)];

      function [$clog2(C_MAX_SIMULTANEOUS_DESCRIPTORS)-1:0] trunc(input [$clog2(C_MAX_SIMULTANEOUS_DESCRIPTORS):0] value);
        trunc = value[$clog2(C_MAX_SIMULTANEOUS_DESCRIPTORS)-1:0];
      endfunction

      reg [63:0] current_packet; // DEBUG signal
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          current_packet   <= 0;
        end else begin
          if(C2S_FIFO_TLAST & C2S_FIFO_TVALID & C2S_FIFO_TREADY) begin
            current_packet <=current_packet +1;
          end
        end
      end

      reg [15:0] c2s_state_pipe_r;
      reg [15:0] state_pipe_r;

      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          c2s_state_pipe_r   <= IDLE;
          state_pipe_r       <= IDLE;
        end else begin
          c2s_state_pipe_r   <= C2S_STATE;
          state_pipe_r       <= ENGINE_STATE;
        end
      end


      reg [15:0] consume_state;
      reg [15:0] current_desc_size_r;
      wire [15:0] current_desc_size_adjusted_s;
      wire restart_current_tlp_size_s;

      assign C2S_FIFO_TREADY = c2s_stream_fifo_tready_s && (consume_state==WAIT_DATA) && C2S_STATE!=IDLE;
      assign c2s_fifo_fifo_tvalid_s = C2S_FIFO_TVALID && (consume_state==WAIT_DATA) && C2S_STATE!=IDLE;


      ///////////////
      //Count the cycles that we have spent without receiving more data.
      reg  [63:0] inactive_time_r;
      reg         detected_prev_data_r;
      wire        restart_current_timeout_s;
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          inactive_time_r          <= 64'h0;
          detected_prev_data_r     <= 1'h0;
        end else begin
          if(restart_current_timeout_s) begin
            inactive_time_r <= 64'h0;
            detected_prev_data_r <= 1'h0;
          end else begin
            if(C2S_FIFO_TVALID & C2S_FIFO_TREADY) begin
              detected_prev_data_r     <= 1'h1;
              inactive_time_r <= 64'h0;
            end else if(ENGINE_STATE!=IDLE && C2S_STATE!=IDLE) begin // If we are attending an operation
              inactive_time_r <= inactive_time_r+detected_prev_data_r;
            end
          end
        end
      end


      ///////////////
      //Count the number of bytes in the current TLP (limited by the restart_current_tlp_s signal).
      // · Possible cases for a reset
      //     i)   The size is bigger than the maximum payload size
      //     ii)  The user (at software space) limited the current transference so we cannot aggregate more information
      //     iii) The hardware design asserted the TLAST signal.
      wire [15:0] current_tlp_size_s;
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          current_desc_size_r <= 16'h0;
        end else begin
          if(restart_current_tlp_size_s) begin
            current_desc_size_r <= C2S_FIFO_TVALID & C2S_FIFO_TREADY ? current_tlp_size_s : 16'h0;
          end else begin
            if(C2S_FIFO_TVALID & C2S_FIFO_TREADY) begin
              current_desc_size_r <= current_desc_size_adjusted_s;
            end
          end
        end
      end

      reg [63:0] remaining_size_descr_pipe_r;
      reg [63:0] remaining_size_descr_r;

      wire complete_descr_s;
      assign complete_descr_s = (desc_size_buffer[trunc(desc_size_buf_wr_ptr)] || current_desc_size_r) && remaining_size_descr_pipe_r<=32;
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          remaining_size_descr_r <= 64'h0;
          remaining_size_descr_pipe_r <= 64'h0;
        end else begin

          if(ENGINE_STATE!=IDLE) begin
            if(C2S_FIFO_TVALID & C2S_FIFO_TREADY) begin // Do not count exactly, current_desc_size_r will take that count
              remaining_size_descr_r <= remaining_size_descr_r-32;
              remaining_size_descr_pipe_r <= remaining_size_descr_r;
            end else begin
              remaining_size_descr_r <= remaining_size_descr_r;
              remaining_size_descr_pipe_r <= remaining_size_descr_pipe_r;
            end
          end else begin
            remaining_size_descr_r  <= CURRENT_DESCRIPTOR_SIZE-C_BUS_DATA_WIDTH/8;
            remaining_size_descr_pipe_r <= remaining_size_descr_r;
          end
        end
      end

      reg [63:0] current_desc_size_plus_tlp;
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          current_desc_size_plus_tlp <= 64'h0;
        end else begin
          current_desc_size_plus_tlp <= desc_size_buffer[trunc(desc_size_buf_wr_ptr)]  + maximum_payload_size;
        end
      end

      assign restart_current_tlp_size_s = (current_desc_size_r >= (maximum_payload_size))
        || consume_state==COM_CHANGE || consume_state==NO_CHANGE;
      assign restart_current_timeout_s  = consume_state==COM_CHANGE || consume_state==NO_CHANGE;

      assign current_tlp_size_s   = C2S_FIFO_TKEEP[0]+ C2S_FIFO_TKEEP[1]+ C2S_FIFO_TKEEP[2]+ C2S_FIFO_TKEEP[3]
        + C2S_FIFO_TKEEP[4]+ C2S_FIFO_TKEEP[5]+ C2S_FIFO_TKEEP[6]+ C2S_FIFO_TKEEP[7]
        + C2S_FIFO_TKEEP[8]+ C2S_FIFO_TKEEP[9]+ C2S_FIFO_TKEEP[10]+ C2S_FIFO_TKEEP[11]
        + C2S_FIFO_TKEEP[12]+ C2S_FIFO_TKEEP[13]+ C2S_FIFO_TKEEP[14]+ C2S_FIFO_TKEEP[15]
        + C2S_FIFO_TKEEP[16]+ C2S_FIFO_TKEEP[17]+ C2S_FIFO_TKEEP[18]+ C2S_FIFO_TKEEP[19]
        + C2S_FIFO_TKEEP[20]+ C2S_FIFO_TKEEP[21]+ C2S_FIFO_TKEEP[22]+ C2S_FIFO_TKEEP[23]
        + C2S_FIFO_TKEEP[24]+ C2S_FIFO_TKEEP[25]+ C2S_FIFO_TKEEP[26]+ C2S_FIFO_TKEEP[27]
        + C2S_FIFO_TKEEP[28]+ C2S_FIFO_TKEEP[29]+ C2S_FIFO_TKEEP[30]+ C2S_FIFO_TKEEP[31];
      assign current_desc_size_adjusted_s = current_desc_size_r + current_tlp_size_s;


      // First FSM. Count the number of bytes received and check if the changes has to be communicate to the upper layer.
      // The information is stored in a small fifo (no bigger than 4096 bytes).
      integer j;
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          consume_state <= WAIT_DATA;
          desc_size_upd  <= 0;
          desc_size_buf_wr_ptr        <= 7'h0;
          for(j=0;j<C_MAX_SIMULTANEOUS_DESCRIPTORS;j=j+1) begin
            desc_size_buffer[j] <= 0;
          end
        end else begin

          case(consume_state)
            WAIT_DATA: begin // Counter the number of received bytes and check the boundary conditions
              // We do NOT count every pulse. Just increment every time a TLP is full.
              if(C2S_FIFO_TVALID & C2S_FIFO_TREADY) begin
                // 1) We receive information and a transference is asked with it (TLAST). Indicate to the next FSM the need of communicating the changes.
                if(C2S_FIFO_TLAST) begin
                  consume_state <= COM_CHANGE;
                  //2) The total number of bytes asked by the user has been reached. Don't update the info but send the remaining bytes of the packet
                end else if(complete_descr_s) begin
                  consume_state <= NO_CHANGE;
                  //3) A normal update. 128-4096B has been received but both (software and app design) are waiting for a bigger value
                end else if(current_desc_size_r >= (maximum_payload_size-C_BUS_DATA_WIDTH/8)) begin
                  desc_size_buffer[trunc(desc_size_buf_wr_ptr)]   <=  current_desc_size_plus_tlp;
                end
              end else begin // Disable timeout
                /*  if(inactive_time_r>DESCRIPTOR_MAX_TIMEOUT) begin
                consume_state <= COM_CHANGE;
                end*/
              end

              desc_size_upd[trunc(desc_size_buf_wr_ptr)] <= 1'b0;
            end
            COM_CHANGE: begin          // Communicate the change and update counters
              desc_size_buffer[trunc(desc_size_buf_wr_ptr)]   <= desc_size_buffer[trunc(desc_size_buf_wr_ptr)]  + current_desc_size_r;
              desc_size_upd[trunc(desc_size_buf_wr_ptr)] <= 1'b1;

              desc_size_buf_wr_ptr <= desc_size_buf_wr_ptr + 1;

              if(C2S_STATE==IDLE) begin
                consume_state <= RESTART_DESC;
              end else begin
                consume_state <= WAIT_ENGINE;
              end
            end

            NO_CHANGE: begin          // Update counters
              desc_size_buffer[trunc(desc_size_buf_wr_ptr)]   <= desc_size_buffer[trunc(desc_size_buf_wr_ptr)]  + current_desc_size_r;
              desc_size_upd[trunc(desc_size_buf_wr_ptr)]      <= 1'b0;

              desc_size_buf_wr_ptr <= desc_size_buf_wr_ptr + 1;

              if(C2S_STATE==IDLE) begin
                consume_state <= RESTART_DESC;
              end else begin
                consume_state <= WAIT_ENGINE;
              end
            end
            WAIT_ENGINE: begin // Do not consume more data until the DMA core has finished with the previous operation
              if(C2S_STATE==IDLE) begin
                consume_state <= WAIT_DATA;
              end else begin
                consume_state <= WAIT_ENGINE;
              end

              desc_size_buffer[trunc(desc_size_buf_wr_ptr)] <= 64'h0;
              desc_size_upd[trunc(desc_size_buf_wr_ptr)]    <= 1'b0;

            end

            RESTART_DESC: begin // Can it be supressed? -> Time restrictions
              desc_size_buffer[trunc(desc_size_buf_wr_ptr)] <= 64'h0;
              desc_size_upd[trunc(desc_size_buf_wr_ptr)]    <= 1'b0;

              consume_state <= WAIT_DATA;
            end
          endcase
        end
      end



      localparam                                  EXTRACT_DATA  = 16'h2;
      localparam                                  WAIT_TLP      = 16'h3;
      localparam                                  END_DESC      = 16'h4;
      localparam                                  BUBBLE        = 16'h5;
      localparam                                  BUBBLE_NOT_READY  = 16'h6;


      reg [15:0] extract_state;
      reg [64-C_BUS_DATA_WIDTH/8-1:0] ready_ncycles_r;
      reg [63:0] hw_new_size_at_descriptor_r;
      reg hw_request_transference_r;
      reg [63:0] prev_tlp_r;
      wire [63:0] remaining_bytes_s;
      wire [63:0] transmitted_bytes_s;
      reg  [15:0] cnt_bubble_r;




      assign HW_REQUEST_TRANSFERENCE   = hw_request_transference_r;
      assign HW_NEW_SIZE_AT_DESCRIPTOR = hw_new_size_at_descriptor_r;


      assign transmitted_bytes_s = (prev_tlp_r<<C_LOG2_MAX_PAYLOAD);
      assign remaining_bytes_s = desc_size_buffer[trunc(desc_size_buf_rd_ptr)]-transmitted_bytes_s;
      //  assign remaining_bytes_s = ((desc_size_buffer[trunc(desc_size_buf_rd_ptr)][63:C_LOG2_MAX_PAYLOAD]-prev_tlp_r)<<C_LOG2_MAX_PAYLOAD) + desc_size_buffer[trunc(desc_size_buf_rd_ptr)][C_LOG2_MAX_PAYLOAD-1:0];

      ///////////////
      // In this FSM we transfer the information to the user.
      //Prior to this, if a change is necessary, we order the update of the fields (bytes of transference)
      reg [63:0] remaining_bytes_pipe_r;
      wire [$clog2(C_BUS_DATA_WIDTH/8)-1:0] remaining_size_lsb_s;
      assign remaining_size_lsb_s = (desc_size_buffer[trunc(desc_size_buf_rd_ptr)][$clog2(C_BUS_DATA_WIDTH/8)-1:0]);
      always @(negedge RST_N or posedge CLK) begin   // Ensure that the SIZE is correct before a new TLP starts
        if(!RST_N) begin
          desc_size_buf_rd_ptr      <= 7'h0;
          ready_ncycles_r            <= 0;

          hw_request_transference_r   <= 1'b0;
          hw_new_size_at_descriptor_r <= 64'h0;
          prev_tlp_r                  <= 64'h0;
          cnt_bubble_r                <= 16'h0;
          remaining_bytes_pipe_r      <= 64'h0;
          extract_state               <= EXTRACT_DATA;
        end else begin
          case(extract_state)
            EXTRACT_DATA: begin
              hw_request_transference_r   <= 1'b0;
              hw_new_size_at_descriptor_r <= desc_size_buffer[trunc(desc_size_buf_rd_ptr)];
              cnt_bubble_r <= 10; // The engine_manager will spend some pulses on updates.
              c2s_proc_fifo_tready_r    <= 1'b0;

              remaining_bytes_pipe_r <= desc_size_buffer[trunc(desc_size_buf_rd_ptr)];


              // We are going to assert the valid signal in several cases:
              // i)  The engine is running and we have send all the information with the previous piece of data
              // ii) The engine is running and all the information is available
              // iii) An intermediate TLP is ready
              if(desc_size_buf_occupancy && ENGINE_STATE!=IDLE && C2S_STATE!=IDLE) begin  // i)
                if(desc_size_upd[trunc(desc_size_buf_rd_ptr)]) begin // We send less bytes that the initial quantity expected by the software design
                  hw_request_transference_r   <= 1'b1;             // some bubbles has to be inserted until the information is correctly updated.
                  c2s_proc_fifo_tready_r    <= 1'b0;
                  extract_state <= desc_size_buffer[trunc(desc_size_buf_rd_ptr)]<=transmitted_bytes_s ? BUBBLE_NOT_READY : BUBBLE;
                end else begin                                     // Else: just deliver the information
                  c2s_proc_fifo_tready_r   <= 1'b1;
                  extract_state <= END_DESC;
                end


                // Two options: We send a single full TLP, or just the remainder.
                ready_ncycles_r <=  remaining_size_lsb_s == 0 ?
                  (remaining_bytes_s[63:$clog2(C_BUS_DATA_WIDTH/8)])
                  : (remaining_bytes_s[63:$clog2(C_BUS_DATA_WIDTH/8)]) + 1;


              end else if(desc_size_buffer[trunc(desc_size_buf_rd_ptr)][63:C_LOG2_MAX_PAYLOAD]!=prev_tlp_r) begin  // We have to deliver some intermediate TLPs.
                c2s_proc_fifo_tready_r   <= 1'b1;
                ready_ncycles_r <=  (remaining_bytes_s[63:$clog2(C_BUS_DATA_WIDTH/8)]);
                extract_state <= WAIT_TLP;
              end else begin // Wait a bit more...
                c2s_proc_fifo_tready_r   <= 1'b0;
                ready_ncycles_r          <=  0;
                extract_state <= EXTRACT_DATA;
              end

            end
            BUBBLE: begin // This state is used to loose cnt_bubble_r pulses (in order to assure that the DMA engine has adquired the new descriptor size value)
              hw_request_transference_r   <= 1'b0;
              if(cnt_bubble_r==1) begin
                c2s_proc_fifo_tready_r   <= 1'b1;
                extract_state <= END_DESC;
              end else begin
                c2s_proc_fifo_tready_r   <= 1'b0;
                cnt_bubble_r <= cnt_bubble_r - 1;
              end
            end
            BUBBLE_NOT_READY: begin // This state is used to loose cnt_bubble_r pulses (in order to assure that the DMA engine has adquired the new descriptor size value)
              hw_request_transference_r   <= 1'b0;
              c2s_proc_fifo_tready_r   <= 1'b0;
              if(cnt_bubble_r==1) begin
                ready_ncycles_r     <= 16'h0;
                prev_tlp_r          <= 64'h0;
                c2s_proc_fifo_tready_r  <= 1'b0;
                desc_size_buf_rd_ptr <= desc_size_buf_rd_ptr+1;
                extract_state <= EXTRACT_DATA;
              end else begin
                cnt_bubble_r <= cnt_bubble_r - 1;
              end
            end
            WAIT_TLP: begin // Wait ncycles before recheck the condition (intermediate TLP ending)
              c2s_proc_fifo_tready_r   <= 1'b1;
              if(c2s_proc_fifo_tvalid_s & C2S_PROC_TREADY) begin
                if(ready_ncycles_r == 1) begin
                  ready_ncycles_r     <= 16'h0;
                  prev_tlp_r          <= remaining_bytes_pipe_r[63:C_LOG2_MAX_PAYLOAD]; // This is always a multiple of C_LOG2_MAX_PAYLOAD
                  c2s_proc_fifo_tready_r  <= 1'b0;
                  extract_state       <= EXTRACT_DATA;
                end else begin
                  ready_ncycles_r <= ready_ncycles_r - 1;
                end
              end
            end
            END_DESC: begin // Wait ncycles before recheck the condition (end of petition ending)
              c2s_proc_fifo_tready_r   <= 1'b1;
              if(c2s_proc_fifo_tvalid_s & C2S_PROC_TREADY) begin
                if(ready_ncycles_r == 1) begin
                  desc_size_buf_rd_ptr <= desc_size_buf_rd_ptr+1;
                  ready_ncycles_r     <= 16'h0;
                  prev_tlp_r          <= 64'h0;
                  c2s_proc_fifo_tready_r  <= 1'b0;

                  extract_state       <= EXTRACT_DATA;
                end else begin
                  ready_ncycles_r <= ready_ncycles_r - 1;
                end
              end
            end
          endcase
        end
      end
    end else begin // Case when this module is disable
      assign     C2S_FIFO_TREADY = C2S_PROC_TREADY;
      assign     C2S_PROC_TDATA = C2S_FIFO_TDATA;
      assign     C2S_PROC_TLAST = C2S_FIFO_TLAST;
      assign     C2S_PROC_TVALID = C2S_FIFO_TVALID;
      assign     C2S_PROC_TKEEP = C2S_FIFO_TKEEP;


      assign HW_REQUEST_TRANSFERENCE = 1'b0;
      assign HW_NEW_SIZE_AT_DESCRIPTOR = 64'h0;
    end
  endgenerate

endmodule
