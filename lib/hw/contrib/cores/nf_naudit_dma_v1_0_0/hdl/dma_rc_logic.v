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
@class dma_rc_logic
@author      Jose Fernando Zazo Rollon (josefernando.zazo@naudit.es)
@date        06/05/2015
@brief Design containing  the DMA requester completion interface. A completion TLP
must start at byte 0 in the AXI stream interface. Straddle option not supported.
TODO:
1) BYTE_COUNT is not implemented
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

module dma_rc_logic #(
  parameter C_BUS_DATA_WIDTH        = 256,
  parameter                                           C_BUS_KEEP_WIDTH = (C_BUS_DATA_WIDTH/32),
  parameter C_NUM_ENGINES           = 2  ,
  parameter C_WINDOW_SIZE           = 16 ,
  parameter C_LOG2_MAX_PAYLOAD      = 8  , // 2**C_LOG2_MAX_PAYLOAD in bytes
  parameter C_LOG2_MAX_READ_REQUEST = 14   // 2**C_LOG2_MAX_READ_REQUEST in bytes
) (
  input  wire                        CLK             ,
  input  wire                        RST_N           ,
  ////////////
  //  PCIe Interface: 1 AXI-Stream (requester side)
  ////////////
  input  wire [C_BUS_DATA_WIDTH-1:0] S_AXIS_RC_TDATA ,
  input  wire [                74:0] S_AXIS_RC_TUSER ,
  input  wire                        S_AXIS_RC_TLAST ,
  input  wire [C_BUS_KEEP_WIDTH-1:0] S_AXIS_RC_TKEEP ,
  input  wire                        S_AXIS_RC_TVALID,
  output wire [                21:0] S_AXIS_RC_TREADY,
  ////////////
  //  s2c fifo interface: 1 AXI-Stream
  ////////////
  output wire                        S2C_FIFO_TVALID ,
  input  wire                        S2C_FIFO_TREADY ,
  output wire [C_BUS_DATA_WIDTH-1:0] S2C_FIFO_TDATA  ,
  output wire                        S2C_FIFO_TLAST  ,
  output wire [C_BUS_KEEP_WIDTH-1:0] S2C_FIFO_TKEEP  ,
  ////////////
  //  Descriptor interface: Interface with the necessary data to complete a memory read/write request.
  ////////////
  output reg  [                63:0] BYTE_COUNT      ,
  input  wire [   C_WINDOW_SIZE-1:0] BUSY_TAGS       ,
  input  wire [C_WINDOW_SIZE*11-1:0] SIZE_TAGS       ,
  output reg  [   C_WINDOW_SIZE-1:0] COMPLETED_TAGS  ,
  output reg  [   C_WINDOW_SIZE-1:0] ERROR_TAGS      ,
  output wire [                63:0] DEBUG
);

  reg                         s2c_fifo_tvalid_r                        ;
  wire                        s2c_fifo_tready_s                        ;
  reg  [C_BUS_DATA_WIDTH-1:0] s2c_fifo_tdata_r                         ;
  reg  [C_BUS_KEEP_WIDTH-1:0] s2c_fifo_tkeep_r                         ;
  reg                         s2c_fifo_tlast_r                         ;
  reg  [C_BUS_DATA_WIDTH-1:0] s2c_fifo_tdata_pipe_r                    ; // Previous value of the signal s2c_fifo_tdata
  reg  [C_BUS_KEEP_WIDTH-1:0] s2c_fifo_tkeep_pipe_r                    ; // Previous value of the signal s2c_fifo_tkeep
  reg                         s_axis_rc_tlast_pipe_r                   ; // Previous value of the signal s_axis_rc_tlast
  wire [                10:0] size_tags_s           [C_WINDOW_SIZE-1:0]; // Expected number of words
  reg  [                10:0] done_tags_r           [C_WINDOW_SIZE-1:0]; // Completed words

  assign s2c_fifo_tready_s = S2C_FIFO_TREADY;

  // Strip the bus and divide it as an array (code more intelligible)
  genvar j;
  for(j=0; j<C_WINDOW_SIZE;j=j+1)
    assign size_tags_s[j] = SIZE_TAGS[11*(j+1)-1:11*j];


  // Get signals from  TUSER
  wire [3:0] first_be_s     ; // Ignored
  reg  [3:0] first_be_pipe_r; // Ignored
  wire [3:0] last_be_s      ; // Ignored
  reg  [3:0] last_be_pipe_r ; // Ignored
  wire       is_sop         ;

  assign is_sop     = S_AXIS_RC_TUSER[32];
  assign first_be_s = S_AXIS_RC_TUSER[3:0];
  assign last_be_s  = S_AXIS_RC_TUSER[7:4];


  // Get signals from  TDATA
  wire [ 7:0] tlp_tag_s   ;
  wire [ 3:0] tlp_error_s ;
  wire [11:0] tlp_dwords_s;

  assign tlp_tag_s    = S_AXIS_RC_TDATA[71:64];
  assign tlp_error_s  = S_AXIS_RC_TDATA[15:12];
  assign tlp_dwords_s = S_AXIS_RC_TDATA[42:32];


  // There will be one fifo for every TAG so reordenation is possible.
  reg [               159:0] tag_fifo_tdata_pipe_r[C_WINDOW_SIZE-1:0];
  reg [   C_WINDOW_SIZE-1:0] tag_state                               ;
  reg [C_BUS_KEEP_WIDTH-1:0] tag_fifo_tkeep_r     [C_WINDOW_SIZE-1:0];
  reg [C_BUS_KEEP_WIDTH-1:0] tag_fifo_tkeep_pipe_r[C_WINDOW_SIZE-1:0];

  reg  [   C_WINDOW_SIZE-1:0] tag_fifo_tvalid_r                   ;
  wire [   C_WINDOW_SIZE-1:0] tag_fifo_tready_s                   ;
  reg  [C_BUS_DATA_WIDTH-1:0] tag_fifo_tdata_r [C_WINDOW_SIZE-1:0];
  reg  [                15:0] tag_fifo_nelems_r[C_WINDOW_SIZE-1:0];

  wire [31:0] tag_fifo_tkeep_expanded_s[C_WINDOW_SIZE-1:0];

  wire [   C_WINDOW_SIZE-1:0] tag_tvalid_s                             ;
  reg  [   C_WINDOW_SIZE-1:0] tag_tready_r                             ;
  wire [C_BUS_DATA_WIDTH-1:0] tag_tdata_s           [C_WINDOW_SIZE-1:0];
  wire [                31:0] tag_tkeep_expanded_s  [C_WINDOW_SIZE-1:0];
  reg  [                15:0] tag_fifo_error_flush_r[C_WINDOW_SIZE-1:0];
  reg  [   C_WINDOW_SIZE-1:0] flush_tags_r                             ;
  wire [   C_WINDOW_SIZE-1:0] tag_tlast_s                              ;

  //We accept data if every fifo has free space.
  assign S_AXIS_RC_TREADY = {22{tag_fifo_tready_s == {C_WINDOW_SIZE{1'b1}}}};


  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      s_axis_rc_tlast_pipe_r <= 1'h0;
    end else begin
      s_axis_rc_tlast_pipe_r <= S_AXIS_RC_TLAST;
    end
  end


  genvar i;
  generate for(i=0; i<C_WINDOW_SIZE; i=i+1) begin
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          done_tags_r[i]         <= 11'h0;
        end else begin
          if(is_sop && tlp_tag_s==i && S_AXIS_RC_TVALID/* && tag_fifo_tready_s[i]*/) begin // assume tag_fifo will never be full
            done_tags_r[i]       <=  COMPLETED_TAGS[i] | ERROR_TAGS[i] ? tlp_dwords_s : done_tags_r[i] + tlp_dwords_s;
          end else begin
            done_tags_r[i]       <=  COMPLETED_TAGS[i] | ERROR_TAGS[i] ? 11'h0 : done_tags_r[i];
          end
        end
      end


      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          ERROR_TAGS[i] <= 1'b0;
        end else begin
          if(ERROR_TAGS[i]) begin //Ensure we active the signal just for one pulse
            ERROR_TAGS[i] <= 1'b0;
          end else if(flush_tags_r[i] &&  tag_fifo_error_flush_r[i] >= tag_fifo_nelems_r[i]) begin // Active flush_tag when the fifo is empty so a new RQ can be done
            ERROR_TAGS[i] <= 1'b1;
          end else begin
            ERROR_TAGS[i] <= 1'b0;
          end
        end
      end
      //We have detected a write to the fifo. Count the number of insertions
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          tag_fifo_nelems_r[i]            <= 16'h0;
        end else begin
          if(tag_fifo_tvalid_r[i] & tag_fifo_tready_s[i]) begin // Number of writes into the fifo
            tag_fifo_nelems_r[i]       <= COMPLETED_TAGS[i] | ERROR_TAGS[i] ? 16'h1 : tag_fifo_nelems_r[i] + 1;
          end else begin
            tag_fifo_nelems_r[i]       <= COMPLETED_TAGS[i] | ERROR_TAGS[i] ? 16'h0: tag_fifo_nelems_r[i];
          end
        end
      end
      //We have detected an error in a tlp and we have to flush the data in the fifo. Count the number of extractions
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          tag_fifo_error_flush_r[i] <= 16'h0;
        end else begin   //
          if(flush_tags_r[i] & tag_tvalid_s[i]) begin
            tag_fifo_error_flush_r[i] <= COMPLETED_TAGS[i] | ERROR_TAGS[i] ? 16'h1 : tag_fifo_error_flush_r[i] + 1;
          end else begin
            tag_fifo_error_flush_r[i] <= COMPLETED_TAGS[i] | ERROR_TAGS[i] ? 16'h0 : tag_fifo_error_flush_r[i];
          end
        end
      end

      ////////
      //Logic for stripping a completion packet and storing it in its corresponding FIFO (based on its tag):
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          flush_tags_r[i]   <= 1'b0;
        end else begin
          if(S_AXIS_RC_TVALID  && tlp_tag_s==i && is_sop &&  tlp_error_s) begin
            flush_tags_r[i] <= 1'b1;
          end else begin
            flush_tags_r[i] <= ERROR_TAGS[i] ? 1'b0 : flush_tags_r[i];
          end
        end
      end

      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          tag_state[i]              <= 1'b0;
          tag_fifo_tdata_r[i]       <= {C_BUS_DATA_WIDTH{1'b0}};
          tag_fifo_tkeep_r[i]       <= {C_BUS_KEEP_WIDTH{1'b0}};
          tag_fifo_tkeep_pipe_r[i]  <= {C_BUS_KEEP_WIDTH{1'b0}};
          tag_fifo_tdata_pipe_r[i]  <= {160{1'b0}};
          tag_fifo_tvalid_r[i]      <= 1'b0;
        end else begin
          tag_fifo_tkeep_pipe_r[i]   <= S_AXIS_RC_TKEEP;
          case(tag_state[i])
            1'b0: begin
              tag_fifo_tvalid_r[i]     <= 1'b0; // tready is always 1. FIFO greater than 4096B (maximum TLP read request size)
              tag_fifo_tdata_pipe_r[i] <= S_AXIS_RC_TDATA[255:96];

              if(S_AXIS_RC_TVALID  && tlp_tag_s==i && is_sop &&  tlp_error_s) begin //Check if this packet is ours and contain an error.
                tag_state[i]    <= 1'b0;
              end else if(S_AXIS_RC_TVALID  && tlp_tag_s==i && is_sop) begin //Check if this packet is ours.
                if( (1<<tlp_tag_s) & BUSY_TAGS ) begin // If the tag is valid, change the state
                  tag_state[i]         <= 1'b1;
                end
              end else begin
                tag_state[i]           <= 1'b0;
              end
            end
            1'b1: begin

              tag_fifo_tdata_r[i][159:0]   <= tag_fifo_tdata_pipe_r[i];
              tag_fifo_tdata_r[i][255:160] <= S_AXIS_RC_TVALID ? S_AXIS_RC_TDATA[95:0] : 96'h0;
              tag_fifo_tdata_pipe_r[i]     <= S_AXIS_RC_TVALID ? S_AXIS_RC_TDATA[255:96] : tag_fifo_tdata_pipe_r[i];

              if(S_AXIS_RC_TVALID && is_sop                        // Valid is active and it's a new packet
                && tlp_tag_s==i && tlp_error_s==4'h0) begin   // Flush the pipe and store the new transition
                if(tag_fifo_tkeep_pipe_r[i][C_BUS_KEEP_WIDTH-1:3]) begin
                  tag_fifo_tvalid_r[i]            <= 1'b1;
                end else begin
                  tag_fifo_tvalid_r[i]            <= 1'b0;
                end
                tag_fifo_tkeep_r[i]             <= {3'h0, tag_fifo_tkeep_pipe_r[i][C_BUS_KEEP_WIDTH-1:3] };
                tag_state[i]         <= 1'b1;
              end else if(S_AXIS_RC_TVALID && is_sop && tlp_tag_s==i) begin // Error
                tag_state[i]         <= 1'b0;
                tag_fifo_tvalid_r[i] <= 1'b0;
              end else if(s_axis_rc_tlast_pipe_r) begin // The previous packets is now finished. Flush the pipe
                if(tag_fifo_tkeep_pipe_r[i][C_BUS_KEEP_WIDTH-1:3]) begin
                  tag_fifo_tvalid_r[i]            <= 1'b1;
                end else begin
                  tag_fifo_tvalid_r[i]            <= 1'b0;
                end
                tag_state[i]                    <= 1'b0;
                tag_fifo_tkeep_r[i]             <= {3'h0,tag_fifo_tkeep_pipe_r[i][C_BUS_KEEP_WIDTH-1:3] };

              end else if(S_AXIS_RC_TVALID) begin // Send an intermediate piece of data to the fifo
                tag_fifo_tvalid_r[i]            <= 1'b1;
                tag_fifo_tkeep_r[i]             <= 8'hff;
                tag_state[i]                    <= 1'b1;
              end else begin
                tag_fifo_tvalid_r[i]     <= 1'b0;
              end
            end
            default: begin
              tag_state[i] <= 1'b0;
              tag_fifo_tvalid_r[i]      <= 1'b0;
            end
          endcase
        end
      end


      assign tag_fifo_tkeep_expanded_s[i] =  { {4{tag_fifo_tkeep_r[i][7]}},{4{tag_fifo_tkeep_r[i][6]}},{4{tag_fifo_tkeep_r[i][5]}},{4{tag_fifo_tkeep_r[i][4]}},
        {4{tag_fifo_tkeep_r[i][3]}}, {4{tag_fifo_tkeep_r[i][2]}},{4{tag_fifo_tkeep_r[i][1]}},{4{tag_fifo_tkeep_r[i][0]}} };


      tag_fifo tag_fifo_i (
        .s_aclk       (CLK                              ),
        .s_aresetn    (RST_N                            ),
        .s_axis_tvalid(tag_fifo_tvalid_r[i]             ),
        .s_axis_tready(tag_fifo_tready_s[i]             ),
        .s_axis_tdata (tag_fifo_tdata_r[i]              ),
        .s_axis_tkeep (tag_fifo_tkeep_expanded_s[i]     ),
        .m_axis_tvalid(tag_tvalid_s[i]                  ),
        .m_axis_tready(tag_tready_r[i] | flush_tags_r[i]),
        .m_axis_tdata (tag_tdata_s[i]                   ),
        .m_axis_tkeep (tag_tkeep_expanded_s[i]          )
      );

    end endgenerate



  reg [$clog2(C_WINDOW_SIZE)-1:0]                    current_tag_r;     // Next expected tag (by order)
  reg [C_WINDOW_SIZE-1:0]                            current_tag_oh_r;  // Same as  current_tag_r but in onehot codification
  reg [3:0]                                          extract_state;      //State of the FSM that will read from the small fifos
  // and store in the fifo placed in dma_logic
  reg [3:0]                                          next_extract_state; // In the WAIT state a next state has to be provided
  reg [15:0]                                         tag_fifo_extracted_r;
  localparam IDLE                                    = 4'h0;
  localparam DATA1                                   = 4'h1;
  localparam DATA2                                   = 4'h2;
  localparam FLUSH_WORD1                             = 4'h3;
  localparam FLUSH_WORD2                             = 4'h4;
  localparam WAIT                                    = 4'h5;
  //////////////////////////////////////////////////////////////////
  //assign DEBUG = {{64-`CLOG2(C_WINDOW_SIZE)-C_WINDOW_SIZE-2*11-4{1'b0}},   extract_state,tag_state, current_tag_r, done_tags_r[current_tag_r], size_tags_s[current_tag_r]};
  //reg [C_WINDOW_SIZE-1:0] fifo_full;
  //reg ini;

//  assign DEBUG[63:32] = {{16-C_WINDOW_SIZE{1'b0}}, fifo_full, tag_fifo_nelems_r[current_tag_r]};
/*
  always @(negedge RST_N or posedge CLK) begin
  if(!RST_N) begin
  fifo_full <= 0;
  ini <= 0;
  end else begin   //Assert TLAST when there is no more pending tags
  ini <= tag_fifo_tready_s == 8'hff ? 1'b1 : 1'b0;
  if(ini && ~tag_fifo_tready_s) begin
  fifo_full <= ~tag_fifo_tready_s;
  end else begin
  fifo_full <= fifo_full;
  end
  end
  end
  */
  reg [3:0] error;
  reg [12:0] remaining;
  reg is_last;
  assign DEBUG[31:0] = {{32-`CLOG2(C_WINDOW_SIZE)-2*11{1'b0}},  current_tag_r, done_tags_r[current_tag_r], size_tags_s[current_tag_r]};
  assign DEBUG[63:32] = {14'h0,is_last, error, remaining};// tag_fifo_nelems_r[current_tag_r]};

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      error <= 0;
      is_last <= 0;
    end else begin   //Assert TLAST when there is no more pending tags
      if(S_AXIS_RC_TVALID && is_sop && tlp_tag_s==current_tag_r) begin
        error <=  tlp_error_s ? tlp_error_s :  error;
        remaining <=  S_AXIS_RC_TDATA[28:16];
        is_last <=  S_AXIS_RC_TDATA[30];
      end else begin
        error <= error;
      end
    end
  end
  //////////////////////////////////////////////////////////////////



  assign S2C_FIFO_TVALID = s2c_fifo_tvalid_r;
  assign S2C_FIFO_TDATA  = s2c_fifo_tdata_r;
  assign S2C_FIFO_TLAST  = s2c_fifo_tlast_r;
  assign S2C_FIFO_TKEEP  = s2c_fifo_tkeep_r;
  //////////////////////
  // Extract the data from the individual fifos and put all the data together in a main s2c fifo (outside this module).
  // ·  PCIe warranties that the read completions are sent in order (increasing address)


  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      s2c_fifo_tlast_r <= 1'b0;
    end else begin   //Assert TLAST when there is no more pending tags
      if(S2C_FIFO_TVALID & S2C_FIFO_TREADY & s2c_fifo_tlast_r) begin
        s2c_fifo_tlast_r <= 1'b0;
      end else if((tag_fifo_extracted_r>=tag_fifo_nelems_r[current_tag_r]-1) &&  ((BUSY_TAGS & ~(current_tag_oh_r))==0)) begin
        s2c_fifo_tlast_r <= 1'b1;
      end else begin
        s2c_fifo_tlast_r <= 1'b0;
      end
    end
  end

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      tag_fifo_extracted_r <= 16'h0;
    end else begin   //
      if(tag_tready_r[current_tag_r] & tag_tvalid_s[current_tag_r]) begin
        tag_fifo_extracted_r <= COMPLETED_TAGS ? 16'h1 : tag_fifo_extracted_r + 1;
      end else begin
        tag_fifo_extracted_r <= COMPLETED_TAGS ? 16'h0 : tag_fifo_extracted_r;
      end
    end
  end

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      current_tag_oh_r     <= 1;
      current_tag_r        <= 0;
      extract_state        <= IDLE;
      next_extract_state   <= IDLE;
      tag_tready_r      <= 0;

      s2c_fifo_tvalid_r <= 0;
      s2c_fifo_tdata_r <= 0;
      s2c_fifo_tkeep_r <= 0;
      s2c_fifo_tdata_pipe_r <= 0;
      s2c_fifo_tkeep_pipe_r <= 0;

      COMPLETED_TAGS     <= {C_WINDOW_SIZE{1'b0}};

    end else begin
      case(extract_state) // The data is not going to be read until all the information associated to a tag
        // is in the correspondent fifo
        //    Number of writes in the fifo : tag_fifo_nelems_r
        //    Number of reads from  a fifo : tag_fifo_extracted_r
        //    Size in words (requester side)    : size_tags_s
        //    Size in words (completer side)    : done_tags_r
        IDLE: begin
          if(COMPLETED_TAGS==0) begin  // Ensure all the fields are reset
            if( (done_tags_r[current_tag_r] >= size_tags_s[current_tag_r]) && (current_tag_oh_r & BUSY_TAGS) && tag_tvalid_s[current_tag_r] ) begin // We come from another petition and valid is active. Go directly to DATA1
              extract_state <= DATA1;
              tag_tready_r[current_tag_r] <= 1'b1;
            end else begin
              extract_state <= IDLE;
            end
          end else begin
            COMPLETED_TAGS     <= {C_WINDOW_SIZE{1'b0}};
          end
          s2c_fifo_tvalid_r <= 0;
        end
        DATA1: begin // We have the register READY at 1. Falling this signal will imply the next cycle there will be valid data
          s2c_fifo_tdata_r <= tag_tdata_s[current_tag_r];
          s2c_fifo_tkeep_r <= {tag_tkeep_expanded_s[current_tag_r][28],tag_tkeep_expanded_s[current_tag_r][24],tag_tkeep_expanded_s[current_tag_r][20],tag_tkeep_expanded_s[current_tag_r][16],tag_tkeep_expanded_s[current_tag_r][12],tag_tkeep_expanded_s[current_tag_r][8],tag_tkeep_expanded_s[current_tag_r][4],tag_tkeep_expanded_s[current_tag_r][0]};
          if( tag_tvalid_s[current_tag_r] && s2c_fifo_tready_s) begin // If valid data and we can export it
            s2c_fifo_tvalid_r <= 1'b1;
            extract_state <= DATA1;
          end else if(tag_fifo_extracted_r>=tag_fifo_nelems_r[current_tag_r]) begin  // No more data but we have transferred something. Go to idle
            extract_state <= IDLE;
            s2c_fifo_tvalid_r <= 1'b0;

            tag_tready_r[current_tag_r] <= 1'b0;

            COMPLETED_TAGS <= current_tag_oh_r;

            if(current_tag_oh_r[C_WINDOW_SIZE-1]) begin        // Onehot codification.
              current_tag_oh_r     <= 1;
              current_tag_r        <= 0;
            end else begin
              current_tag_oh_r     <= current_tag_oh_r << 1;
              current_tag_r        <= current_tag_r +1;
            end
          end else if (!s2c_fifo_tready_s) begin
            tag_tready_r[current_tag_r] <= 1'b0;

            s2c_fifo_tdata_pipe_r <= tag_tdata_s[current_tag_r];
            s2c_fifo_tkeep_pipe_r <= {tag_tkeep_expanded_s[current_tag_r][28],tag_tkeep_expanded_s[current_tag_r][24],tag_tkeep_expanded_s[current_tag_r][20],tag_tkeep_expanded_s[current_tag_r][16],tag_tkeep_expanded_s[current_tag_r][12],tag_tkeep_expanded_s[current_tag_r][8],tag_tkeep_expanded_s[current_tag_r][4],tag_tkeep_expanded_s[current_tag_r][0]};

            extract_state <= DATA2;
          end else begin
            s2c_fifo_tvalid_r <= 1'b0;
          end
        end
        DATA2: begin // We have the register READY at 0. However, valid previous information is possible.
          s2c_fifo_tdata_pipe_r <= tag_tdata_s[current_tag_r];
          s2c_fifo_tkeep_pipe_r <= {tag_tkeep_expanded_s[current_tag_r][28],tag_tkeep_expanded_s[current_tag_r][24],tag_tkeep_expanded_s[current_tag_r][20],tag_tkeep_expanded_s[current_tag_r][16],tag_tkeep_expanded_s[current_tag_r][12],tag_tkeep_expanded_s[current_tag_r][8],tag_tkeep_expanded_s[current_tag_r][4],tag_tkeep_expanded_s[current_tag_r][0]};

          s2c_fifo_tdata_r      <= s2c_fifo_tdata_pipe_r;
          s2c_fifo_tkeep_r      <= s2c_fifo_tkeep_pipe_r;

          if( tag_tvalid_s[current_tag_r] && s2c_fifo_tready_s) begin // We can send one word this cycle
            s2c_fifo_tvalid_r <= 1'b1;
            extract_state     <= FLUSH_WORD2;
          end else if( !tag_tvalid_s[current_tag_r] ) begin  // just one word to transfer
            s2c_fifo_tvalid_r <= 1'b1;
            extract_state     <= FLUSH_WORD2;
          end else begin
            s2c_fifo_tvalid_r <= 1'b1;
            extract_state     <= FLUSH_WORD1;
          end
        end
        FLUSH_WORD1: begin  // We have to deliver the first word
          if(s2c_fifo_tready_s) begin
            s2c_fifo_tvalid_r <= 1'b1;
            s2c_fifo_tdata_r      <= s2c_fifo_tdata_pipe_r;
            s2c_fifo_tkeep_r      <= s2c_fifo_tkeep_pipe_r;

            if(tag_fifo_extracted_r>=tag_fifo_nelems_r[current_tag_r]) begin
              extract_state <= IDLE;
              tag_tready_r[current_tag_r] <= 1'b0;

              COMPLETED_TAGS <= current_tag_oh_r;

              if(current_tag_oh_r[C_WINDOW_SIZE-1]) begin        // Onehot codification.
                current_tag_oh_r     <= 1;
                current_tag_r        <= 0;
              end else begin
                current_tag_oh_r     <= current_tag_oh_r << 1;
                current_tag_r        <= current_tag_r +1;
              end
            end else begin
              extract_state <= FLUSH_WORD2;
            end
          end else begin
            s2c_fifo_tvalid_r <= 1'b1;
            extract_state     <= FLUSH_WORD1;
          end
        end
        FLUSH_WORD2: begin // We have to deliver the second word
          if(s2c_fifo_tready_s) begin
            s2c_fifo_tvalid_r <= 1'b0;

            if(tag_fifo_extracted_r>=tag_fifo_nelems_r[current_tag_r]) begin
              extract_state <= IDLE;
              tag_tready_r[current_tag_r] <= 1'b0;
              COMPLETED_TAGS <= current_tag_oh_r;

              if(current_tag_oh_r[C_WINDOW_SIZE-1]) begin        // Onehot codification.
                current_tag_oh_r     <= 1;
                current_tag_r        <= 0;
              end else begin
                current_tag_oh_r     <= current_tag_oh_r << 1;
                current_tag_r        <= current_tag_r +1;
              end
            end else begin
              tag_tready_r[current_tag_r] <= 1'b1;
              extract_state <= WAIT;
            end
          end else begin
            s2c_fifo_tvalid_r <= 1'b1;
            extract_state     <= FLUSH_WORD2;
          end
        end
        WAIT: begin
          extract_state <= next_extract_state;
        end
        default: begin
          current_tag_oh_r     <= {C_WINDOW_SIZE{1'b0}};
          current_tag_r        <= 0;
          extract_state        <= IDLE;
        end
      endcase
    end
  end

  ////////
  //Counting logic.
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      BYTE_COUNT         <= 64'h0;
    end else begin
      if(s2c_fifo_tvalid_r && s2c_fifo_tready_s) begin // Improve this estimation taking into consideration the TKEEP ?.
        BYTE_COUNT  <= 64'h8;
      end else begin
        BYTE_COUNT  <= 64'h0;
      end
    end
  end





endmodule
