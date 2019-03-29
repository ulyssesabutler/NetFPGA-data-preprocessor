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
@class dma_engine_orchestrator
@author      Jose Fernando Zazo Rollon (josefernando.zazo@naudit.es)
@date        20/04/2015
@brief
Register the informationa associated with the different descriptors in used by the app.
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

module dma_engine_orchestrator #(
  parameter C_NUM_ENGINES     = 2            ,
  parameter C_DEFAULT_TIMEOUT = 64'd100000000  // 100 ms
) (
  input  wire                             CLK                ,
  input  wire                             RST_N              ,
  input  wire [        C_NUM_ENGINES-1:0] ENABLE_ENGINES     ,
  output wire [$clog2(C_NUM_ENGINES)-1:0] ACTIVE_ENGINE      ,
  output wire                             ENGINE_VALID       ,
  input  wire [                      7:0] STATUS_BYTE        ,
  input  wire [                      7:0] CONTROL_BYTE       ,
  output wire                             OPERATION_IN_COURSE,
  input  wire [    (C_NUM_ENGINES/2)-1:0] C2S_TVALID
);


  wire                             is_end_of_operation_s  ;
  wire                             is_engine_enable_s     ;
  wire                             is_engine_stopped_s    ;
  wire                             is_engine_pending_irq_s;
  wire                             pause_engine_s         ;
  reg  [$clog2(C_NUM_ENGINES)-1:0] active_engine_r        ;


  assign is_end_of_operation_s   = CONTROL_BYTE[3];
  assign pause_engine_s          = CONTROL_BYTE[5];
  assign is_engine_enable_s      = STATUS_BYTE[0];
  assign is_engine_stopped_s     = STATUS_BYTE[3] | !ENABLE_ENGINES[active_engine_r] ;
  assign is_engine_pending_irq_s = STATUS_BYTE[7];


  reg       detected_end_r;
  reg [1:0] state         ;

  localparam LOOKING_FOR_ENGINE = 0;
  localparam WAITING_TO_ENGINE  = 1;
  localparam WAIT_FOR_READY     = 2;


  reg    [(C_NUM_ENGINES/2)-1:0] detected_transmission_r;
  genvar                         i                      ;

  // Consider d2h engines just in the case where a previous valid has been asserted.
  generate
    for(i=0; i<(C_NUM_ENGINES/2); i=i+1) begin
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          detected_transmission_r[i] <= 1'b0;
        end else begin
          if((!is_end_of_operation_s||pause_engine_s)&&active_engine_r==i) begin
            detected_transmission_r[i] <= 1'b0;
          end else begin
            detected_transmission_r[i] <= detected_transmission_r[i] | C2S_TVALID[i];
          end
        end
      end
    end
  endgenerate

  reg [    C_NUM_ENGINES-1:0] enable_engines_pipe_r  ;
  generate
    for(i=0; i<C_NUM_ENGINES; i=i+1) begin
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          enable_engines_pipe_r[i]   <= 1'b0;
        end else begin
          enable_engines_pipe_r[i] <= ENABLE_ENGINES[i];
        end
      end
    end
  endgenerate
  function [$clog2(C_NUM_ENGINES)-1:0] roundRobin(input [$clog2(C_NUM_ENGINES)-1:0] current_engine);
    begin
      if(current_engine < C_NUM_ENGINES-1) begin
        roundRobin <= current_engine + 1;
      end else begin
        roundRobin <= {`CLOG2(C_NUM_ENGINES){1'b0}};
      end
    end
  endfunction

  function [$clog2(C_NUM_ENGINES)-1:0] findNextSuitableEngine(input [$clog2(C_NUM_ENGINES)-1:0] current_engine, input [C_NUM_ENGINES-1:0] engine_bitmask, input [C_NUM_ENGINES/2-1:0] data_bitmask);
    integer j;
    begin
      //findNextSuitableEngine <= roundRobin(current_engine);

      findNextSuitableEngine = current_engine;
      for(j=0; j<C_NUM_ENGINES-1; j=j+1) begin
        if((j+current_engine+1)%2) begin
          //if(engine_bitmask[(j+current_engine+1)%C_NUM_ENGINES]) begin
          findNextSuitableEngine = (j+current_engine+1)%C_NUM_ENGINES;
          //end
        end else begin
          if(/*engine_bitmask[(j+current_engine+1)%C_NUM_ENGINES] && */ data_bitmask[((j+current_engine+1)%C_NUM_ENGINES)/2]) begin
            findNextSuitableEngine = (j+current_engine+1)%C_NUM_ENGINES;
          end
        end
      end
    end
  endfunction

  function  detectedValidEngine(input [$clog2(C_NUM_ENGINES)-1:0] current_engine, input [C_NUM_ENGINES-1:0] engine_bitmask, input [C_NUM_ENGINES/2-1:0] data_bitmask);
    integer j;
    begin

      detectedValidEngine = 0;
      for(j=0; j<C_NUM_ENGINES; j=j+1) begin
        if((j+current_engine+1)%2) begin
          if(engine_bitmask[(j+current_engine+1)%C_NUM_ENGINES]) begin
            detectedValidEngine = 1;
          end
        end else begin
          if(engine_bitmask[(j+current_engine+1)%C_NUM_ENGINES] && data_bitmask[((j+current_engine+1)%C_NUM_ENGINES)/2]) begin
            detectedValidEngine = 1;
          end
        end
      end
    end
  endfunction

  reg detected_engine_r;
  reg                             suitable_engine_r    ;
  reg [                      2:0] memory_valid_r       ;
  reg                             operation_in_course_r;

  reg [1:0] state_r;
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      state             <= LOOKING_FOR_ENGINE;
      active_engine_r   <= 0;
      detected_engine_r <= 0;
      suitable_engine_r <= 0;
      memory_valid_r    <= 3'b000;
    end else begin
      case(state)
        LOOKING_FOR_ENGINE : begin
          suitable_engine_r <= 1'b0;

          if(!is_engine_stopped_s && memory_valid_r==3'b111) begin  // if the engine is enable and it has not finished
            state <= WAITING_TO_ENGINE;
            suitable_engine_r <= 1'b1;
          end else begin
            if(pause_engine_s || state_r != LOOKING_FOR_ENGINE || operation_in_course_r) begin
              state <= LOOKING_FOR_ENGINE;
              suitable_engine_r <= pause_engine_s;
            end else if(memory_valid_r) begin // Wait until the candidate is valid.
              memory_valid_r    <= memory_valid_r+1;
            end else begin
              active_engine_r   <= findNextSuitableEngine(active_engine_r, ENABLE_ENGINES, detected_transmission_r);
              state             <= LOOKING_FOR_ENGINE;
              memory_valid_r  <= 3'b001;
            end
          end
        end
        WAITING_TO_ENGINE : begin
          detected_engine_r <= 0;
          memory_valid_r    <= 3'b000;

          if(is_end_of_operation_s) begin
            if(pause_engine_s) begin
              state <= WAIT_FOR_READY;
            end else begin
              state <= LOOKING_FOR_ENGINE;
              suitable_engine_r <= 1'b0;
            end
          end
        end
        WAIT_FOR_READY : begin
          if(pause_engine_s && OPERATION_IN_COURSE) begin
            state <= WAIT_FOR_READY;
          end else begin
            state <= LOOKING_FOR_ENGINE;
            suitable_engine_r <= 1'b0;
          end
        end
        default : begin
          state <= LOOKING_FOR_ENGINE;
        end
      endcase
    end
  end

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      operation_in_course_r <= 0;
    end else begin
      if(is_end_of_operation_s || pause_engine_s) begin
        operation_in_course_r <= pause_engine_s;
      end else begin
        operation_in_course_r <= (ENABLE_ENGINES[active_engine_r] & enable_engines_pipe_r[active_engine_r] & !is_engine_stopped_s & suitable_engine_r);
      end
    end
  end

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      state_r <= 0;
    end else begin
      if(!pause_engine_s) begin
        state_r <= state;
      end
    end
  end

  assign OPERATION_IN_COURSE = operation_in_course_r;
  assign ACTIVE_ENGINE       = active_engine_r;
  assign ENGINE_VALID  = (state_r != LOOKING_FOR_ENGINE && (state!=LOOKING_FOR_ENGINE || pause_engine_s));

endmodule
