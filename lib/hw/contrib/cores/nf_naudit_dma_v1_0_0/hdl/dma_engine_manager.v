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
@class dma_descriptor_reg
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

module dma_engine_manager #(
  parameter C_ADDR_WIDTH             = 16           ,
  parameter C_DATA_WIDTH             = 64           ,
  parameter C_ENGINE_TABLE_OFFSET    = 32'h200      , // Offset in the bar for every engine:
  // engine i will be at position  C_ENGINE_TABLE_OFFSET + i*C_OFFSET_BETWEEN_ENGINES
  parameter C_OFFSET_BETWEEN_ENGINES = 16'h2000     ,
  parameter C_NUM_ENGINES            = 2            ,
  parameter C_NUM_DESCRIPTORS        = 1024         , // Number of descriptors represented in each engine.
  parameter C_DEFAULT_TIMEOUT        = 64'd100000000  // 100 ms
) (
  input  wire                             CLK                      ,
  input  wire                             RST_N                    ,
  ///////////
  // Connection with the core Completer DMA interface
  ///////////
  input  wire                             S_MEM_IFACE_EN           ,
  input  wire [         C_ADDR_WIDTH-1:0] S_MEM_IFACE_ADDR         ,
  output wire [         C_DATA_WIDTH-1:0] S_MEM_IFACE_DOUT         ,
  input  wire [         C_DATA_WIDTH-1:0] S_MEM_IFACE_DIN          ,
  input  wire [       C_DATA_WIDTH/8-1:0] S_MEM_IFACE_WE           ,
  output reg                              S_MEM_IFACE_ACK          ,
  ///////////
  // Connection with the core Requester DMA interface
  ///////////
  output wire [$clog2(C_NUM_ENGINES)-1:0] ACTIVE_ENGINE            ,
  output wire [                      7:0] STATUS_BYTE              ,
  input  wire [                      7:0] CONTROL_BYTE             ,
  input  wire [                     63:0] BYTE_COUNT               ,
  output reg                              ENGINE_VALID             ,
  output reg  [                     63:0] DESCRIPTOR_ADDR          ,
  output reg  [                     63:0] DESCRIPTOR_SIZE          ,
  output reg  [                     63:0] DESCRIPTOR_MAX_TIMEOUT   ,
  input  wire                             HW_REQUEST_TRANSFERENCE  ,
  input  wire [                     63:0] HW_NEW_SIZE_AT_DESCRIPTOR,
  output wire [        C_NUM_ENGINES-1:0] IRQ                      ,
  output wire                             OPERATION_IN_COURSE      ,
  input  wire [    (C_NUM_ENGINES/2)-1:0] C2S_TVALID
);

  assign DWORD_TLP = 0; //express in 32 bits words. Not used

  localparam c_offset_between_descriptors = 10'h4;
  localparam c_offset_engines_config      = 10'h4; // Descriptor j of engine i will be at position  C_ENGINE_TABLE_OFFSET + i*C_OFFSET_BETWEEN_ENGINES + j*c_offset_between_descriptors + c_offset_engines_config

  reg                      ack_pending_r           ;
  reg                      mem_ack_pending_pipe_1_r, mem_ack_pending_pipe_2_r;
  wire [C_NUM_ENGINES-1:0] engine_access_s         ;
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      S_MEM_IFACE_ACK          <= 1'b0;
      mem_ack_pending_pipe_1_r <= 1'b0;
      mem_ack_pending_pipe_2_r <= 1'b0;
    end else begin
      mem_ack_pending_pipe_1_r <= (S_MEM_IFACE_EN & !HW_REQUEST_TRANSFERENCE) || (ack_pending_r);
      mem_ack_pending_pipe_2_r <= mem_ack_pending_pipe_1_r;
      S_MEM_IFACE_ACK          <= engine_access_s ? (S_MEM_IFACE_EN & !HW_REQUEST_TRANSFERENCE) || (ack_pending_r) : mem_ack_pending_pipe_2_r;
    end
  end

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      ack_pending_r <= 1'b0;
    end else begin
      ack_pending_r <= (S_MEM_IFACE_EN & HW_REQUEST_TRANSFERENCE);
    end
  end


  // DMA engine registers implementation
  reg  [C_NUM_ENGINES-1:0] enable_r                                          ;
  reg  [C_NUM_ENGINES-1:0] reset_r                                           ;
  reg  [C_NUM_ENGINES-1:0] engine_irq_r                                      ;
  reg  [C_NUM_ENGINES-1:0] running_r                                         ;
  reg  [C_NUM_ENGINES-1:0] stop_r                                            ;
  reg  [C_NUM_ENGINES-1:0] error_r                                           ;
  wire [              1:0] capabilities_s                 [C_NUM_ENGINES-1:0];
  reg  [C_NUM_ENGINES-1:0] irq_pending_r                                     ;
  reg  [             63:0] time_r                         [C_NUM_ENGINES-1:0];
  reg  [             63:0] byte_count_r                   [C_NUM_ENGINES-1:0];
  reg  [              1:0] last_index_descriptor_updated_r[C_NUM_ENGINES-1:0];

  //reg  [63:0]                                     descriptor_addr_r               [C_NUM_ENGINES-1:0][C_NUM_DESCRIPTORS-1:0];
  reg [$clog2(C_NUM_DESCRIPTORS)-1:0] last_index_descriptor_r[C_NUM_ENGINES-1:0];

  //reg  [63:0]                                     descriptor_size_r               [C_NUM_ENGINES-1:0][C_NUM_DESCRIPTORS-1:0];
  // reg  [7:0]                                      control_descriptor_r            [C_NUM_ENGINES-1:0][C_NUM_DESCRIPTORS-1:0];


  reg [             C_DATA_WIDTH-1:0] rdata_engine_r           [C_NUM_ENGINES-1:0];
  reg [             C_DATA_WIDTH-1:0] rdata_descriptor_r       [C_NUM_ENGINES-1:0];
  reg [    $clog2(C_NUM_ENGINES)-1:0] read_engine_r                               ;
  reg [            C_NUM_ENGINES-1:0] is_engine_read_r                            ;
  reg [            C_NUM_ENGINES-1:0] cl_engine_stats_r                           ;
  reg [$clog2(C_NUM_DESCRIPTORS)-1:0] active_index_descriptor_r[C_NUM_ENGINES-1:0];

  // Maximum time, express in nanoseconds that the engine will wait before forcing a transference
  // This is useful for network-oriented applications. Just applicable in the C2S direction.
  reg [63:0] max_timeout_r[C_NUM_ENGINES-1:0];

  //////////////////////////
  // BRAM Interface
  //////////////////////////

  reg [$clog2(C_NUM_DESCRIPTORS)-1:0] addra_size_r   [C_NUM_ENGINES-1:0];
  reg [$clog2(C_NUM_DESCRIPTORS)-1:0] addra_address_r[C_NUM_ENGINES-1:0];
  reg [$clog2(C_NUM_DESCRIPTORS)-1:0] addra_control_r[C_NUM_ENGINES-1:0];

  // Enable and write port
  reg [C_NUM_ENGINES-1:0] ena_size_r                       ;
  reg [C_NUM_ENGINES-1:0] ena_address_r                    ;
  reg [C_NUM_ENGINES-1:0] ena_control_r                    ;
  reg [              7:0] wea_size_r    [C_NUM_ENGINES-1:0];
  reg [              7:0] wea_address_r [C_NUM_ENGINES-1:0];
  reg [              7:0] wea_control_r [C_NUM_ENGINES-1:0];
  reg [             63:0] dina_size_r   [C_NUM_ENGINES-1:0];
  reg [             63:0] dina_address_r[C_NUM_ENGINES-1:0];
  reg [             63:0] dina_control_r[C_NUM_ENGINES-1:0];

  wire [63:0] doutb_size_s   [C_NUM_ENGINES-1:0];
  wire [63:0] douta_size_s   [C_NUM_ENGINES-1:0]; // The user has to read the size from the FIFO just in case it has been altered
  wire [63:0] doutb_address_s[C_NUM_ENGINES-1:0];
  wire [63:0] douta_address_s[C_NUM_ENGINES-1:0];
  wire [63:0] doutb_control_s[C_NUM_ENGINES-1:0];
  wire [63:0] douta_control_s[C_NUM_ENGINES-1:0];


  //


  reg  [C_NUM_ENGINES-1:0] irq_r         ;
  reg                      generate_irq_r;
  wire                     pause_engine_s;



  wire is_end_of_operation_s;
  wire operation_error_s    ;

  assign is_end_of_operation_s = CONTROL_BYTE[3];
  assign operation_error_s     = CONTROL_BYTE[4];
  assign pause_engine_s        = CONTROL_BYTE[5];

  assign STATUS_BYTE = {irq_pending_r[ACTIVE_ENGINE],capabilities_s[ACTIVE_ENGINE][1:0],error_r[ACTIVE_ENGINE], stop_r[ACTIVE_ENGINE],running_r[ACTIVE_ENGINE],reset_r[ACTIVE_ENGINE],enable_r[ACTIVE_ENGINE]};


  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      DESCRIPTOR_ADDR        <= 64'h0;
      DESCRIPTOR_SIZE        <= 64'h0;
      DESCRIPTOR_MAX_TIMEOUT <= 64'h0;
    end else begin
      DESCRIPTOR_ADDR        <= doutb_address_s[ACTIVE_ENGINE];
      DESCRIPTOR_SIZE        <= doutb_size_s[ACTIVE_ENGINE];
      DESCRIPTOR_MAX_TIMEOUT <= { 2'h0, max_timeout_r[ACTIVE_ENGINE][63:2]}; // The clock has a 4 ns period, calculate the number of inactive cycles.
    end
  end

  reg  [    $clog2(C_NUM_ENGINES)-1:0] active_engine_pipe_r          ;
  reg  [$clog2(C_NUM_DESCRIPTORS)-1:0] active_index_descriptor_pipe_r;
  wire                                 orchestrator_valid_s          ;
  dma_engine_orchestrator #(
    .C_NUM_ENGINES    (C_NUM_ENGINES    ),
    .C_DEFAULT_TIMEOUT(C_DEFAULT_TIMEOUT)
  ) dma_engine_orchestrator_i (
    .CLK                (CLK                 ),
    .RST_N              (RST_N               ),
    .ENABLE_ENGINES     (enable_r            ),
    .ACTIVE_ENGINE      (ACTIVE_ENGINE       ),
    .ENGINE_VALID       (orchestrator_valid_s),
    .STATUS_BYTE        (STATUS_BYTE         ),
    .CONTROL_BYTE       (CONTROL_BYTE        ),
    .OPERATION_IN_COURSE(OPERATION_IN_COURSE ),
    .C2S_TVALID         (C2S_TVALID          )
  );


  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      active_engine_pipe_r           <= 0;
      active_index_descriptor_pipe_r <= 0;
    end else begin
      active_engine_pipe_r           <= ACTIVE_ENGINE;
      active_index_descriptor_pipe_r <= active_index_descriptor_r[ACTIVE_ENGINE];
    end
  end

  // The output have to wait  some cycles until it is available
  reg pause_engine_r;
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      pause_engine_r <= 1'h0;
    end else begin
      pause_engine_r <= pause_engine_s;
    end
  end
  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      ENGINE_VALID <= 1'h0;
    end else begin
      if(pause_engine_s) begin
        ENGINE_VALID <= orchestrator_valid_s;
      end else if((is_end_of_operation_s) || (pause_engine_r)) begin // If the user chooses another ENGINE or an operation finishes disable the valid signal.
        ENGINE_VALID <= 1'h0;
      end else if(ACTIVE_ENGINE == active_engine_pipe_r && active_index_descriptor_r[ACTIVE_ENGINE] == active_index_descriptor_pipe_r && !stop_r[ACTIVE_ENGINE]) begin
        ENGINE_VALID <= orchestrator_valid_s;
      end else begin
        ENGINE_VALID <= 1'h0;
      end
    end
  end


  genvar  i;
  genvar  j;
  integer k;
  // Choose among all the engines.
  assign S_MEM_IFACE_DOUT = is_engine_read_r[read_engine_r] ?  rdata_engine_r[read_engine_r] : rdata_descriptor_r[read_engine_r];

  always @(negedge RST_N or posedge CLK) begin
    if(!RST_N) begin
      read_engine_r <= 0;
    end else begin
      read_engine_r <= (S_MEM_IFACE_ADDR - C_ENGINE_TABLE_OFFSET) / C_OFFSET_BETWEEN_ENGINES;
    end
  end

  generate for (i = 0; i < C_NUM_ENGINES; i = i + 1) begin
      assign engine_access_s[i] = S_MEM_IFACE_ADDR>=(C_ENGINE_TABLE_OFFSET + i*C_OFFSET_BETWEEN_ENGINES) && S_MEM_IFACE_ADDR<=(C_ENGINE_TABLE_OFFSET + i*C_OFFSET_BETWEEN_ENGINES + c_offset_engines_config);


      // Write logic to regs based on the user decission
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          enable_r[i]    <= 1'b0;
          reset_r[i]     <= 1'b0;
          engine_irq_r[i]  <= 1'b1;

          cl_engine_stats_r[i]  <= 1'b0;
          last_index_descriptor_r[i] <= 0;
          max_timeout_r[i] <= C_DEFAULT_TIMEOUT;

          last_index_descriptor_updated_r[i] <= 2'h00;
        end else begin
          reset_r[i]            <= 1'b0; // Automatically clean the reset_r after one cycle.
          cl_engine_stats_r[i]  <= 1'b0;
          enable_r[i]           <= enable_r[i] & (!stop_r[i]);

          if(S_MEM_IFACE_EN && S_MEM_IFACE_WE) begin
            case(S_MEM_IFACE_ADDR)
              C_ENGINE_TABLE_OFFSET + i*C_OFFSET_BETWEEN_ENGINES : begin  // Control byte of DMA engine
                // Clean values.
                cl_engine_stats_r[i]  <= 1'b1;

                // Update values
                if(S_MEM_IFACE_WE[0]) begin
                  engine_irq_r[i]     <= S_MEM_IFACE_DIN[2];
                  reset_r[i]          <= S_MEM_IFACE_DIN[1];
                  //  enable_r[i]         <= S_MEM_IFACE_DIN[0];
                end
              end
              C_ENGINE_TABLE_OFFSET + i*C_OFFSET_BETWEEN_ENGINES + 1: begin      // Stop at descriptor ...
                cl_engine_stats_r[i]  <= 1'b1;

                if($clog2(C_NUM_DESCRIPTORS)<=8) begin
                  if(S_MEM_IFACE_WE[0]) last_index_descriptor_r[i]   <= S_MEM_IFACE_DIN[$clog2(C_NUM_DESCRIPTORS)-1:0];

                  if(S_MEM_IFACE_WE[0]) begin
                    last_index_descriptor_updated_r[i] <= 2'b00;
                    enable_r[i] <= 1'b1;
                  end
                end else begin
                  if(S_MEM_IFACE_WE[0]) last_index_descriptor_r[i][7:0]                                <= S_MEM_IFACE_DIN[7:0];
                  if(S_MEM_IFACE_WE[1]) last_index_descriptor_r[i][$clog2(C_NUM_DESCRIPTORS)-1:8]      <= S_MEM_IFACE_DIN[$clog2(C_NUM_DESCRIPTORS)-1:8];

                  if(S_MEM_IFACE_WE[0]&S_MEM_IFACE_WE[1]) begin
                    enable_r[i] <= 1'b1;
                    last_index_descriptor_updated_r[i] <= 2'b00;
                  end else if((S_MEM_IFACE_WE[0] & last_index_descriptor_updated_r[i][1]) | (S_MEM_IFACE_WE[1] & last_index_descriptor_updated_r[i][0])) begin
                    enable_r[i] <= 1'b1;
                    last_index_descriptor_updated_r[i] <= 2'b00;
                  end else begin
                    last_index_descriptor_updated_r[i] <= S_MEM_IFACE_WE[1:0];
                  end

                end
              end
              C_ENGINE_TABLE_OFFSET + i*C_OFFSET_BETWEEN_ENGINES + 2: begin
                if(S_MEM_IFACE_WE[0]) max_timeout_r[i][7:0]    <= S_MEM_IFACE_DIN[7:0];
                if(S_MEM_IFACE_WE[1]) max_timeout_r[i][15:8]   <= S_MEM_IFACE_DIN[15:8];
                if(S_MEM_IFACE_WE[2]) max_timeout_r[i][23:16]  <= S_MEM_IFACE_DIN[23:16];
                if(S_MEM_IFACE_WE[3]) max_timeout_r[i][31:24]  <= S_MEM_IFACE_DIN[31:24];
                if(S_MEM_IFACE_WE[4]) max_timeout_r[i][39:32]  <= S_MEM_IFACE_DIN[39:32];
                if(S_MEM_IFACE_WE[5]) max_timeout_r[i][47:40]  <= S_MEM_IFACE_DIN[47:40];
                if(S_MEM_IFACE_WE[6]) max_timeout_r[i][55:48]  <= S_MEM_IFACE_DIN[55:48];
                if(S_MEM_IFACE_WE[7]) max_timeout_r[i][63:56]  <= S_MEM_IFACE_DIN[63:56];
              end
              default: begin
              end
            endcase
          end
        end
      end


      // BRAM instantation.
      blk_mem_descriptor blk_mem_descriptor_size (
        .clka (CLK                         ), // input wire clka
        .ena  (ena_size_r[i]               ), // input wire ena
        .wea  (wea_size_r[i]               ), // input wire [7 : 0] wea
        .addra(addra_size_r[i]             ), // input wire [9 : 0] addra
        .dina (dina_size_r[i]              ), // input wire [63 : 0] dina
        .douta(douta_size_s[i]             ), // output wire [63 : 0] douta
        .clkb (CLK                         ), // input wire clkb
        .enb  (1'b1                        ), // input wire enb
        .addrb(active_index_descriptor_r[i]), //(S_MEM_IFACE_ADDR-i*C_OFFSET_BETWEEN_ENGINES-c_offset_engines_config-1)/c_offset_between_descriptors),  // input wire [9 : 0] addrb
        .web  (8'b0                        ), // input wire [0 : 0] web
        .dinb (64'b0                       ), // input wire [63 : 0] dinb
        .doutb(doutb_size_s[i]             )  // output wire [63 : 0] doutb
      );


      blk_mem_descriptor blk_mem_descriptor_address (
        .clka (CLK                         ), // input wire clka
        .ena  (ena_address_r[i]            ), // input wire ena
        .wea  (wea_address_r[i]            ), // input wire [7 : 0] wea
        .addra(addra_address_r[i]          ), // input wire [9 : 0] addra
        .dina (dina_address_r[i]           ), // input wire [63 : 0] dina
        .douta(douta_address_s[i]          ), // output wire [63 : 0] douta
        .clkb (CLK                         ), // input wire clkb
        .enb  (1'b1                        ), // input wire enb
        .addrb(active_index_descriptor_r[i]), //(S_MEM_IFACE_ADDR-i*C_OFFSET_BETWEEN_ENGINES-c_offset_engines_config)/c_offset_between_descriptors),  // input wire [9 : 0] addrb
        .web  (8'b0                        ), // input wire [0 : 0] web
        .dinb (64'b0                       ), // input wire [63 : 0] dinb
        .doutb(doutb_address_s[i]          )  // output wire [63 : 0] doutb
      );
      blk_mem_descriptor blk_mem_descriptor_control (
        .clka (CLK                         ), // input wire clka
        .ena  (ena_control_r[i]            ), // input wire ena
        .wea  (wea_control_r[i]            ), // input wire [7 : 0] wea
        .addra(addra_control_r[i]          ), // input wire [9 : 0] addra
        .dina (dina_control_r[i]           ), // input wire [63 : 0] dina
        .douta(douta_control_s[i]          ), // output wire [63 : 0] douta
        .clkb (CLK                         ), // input wire clkb
        .enb  (1'b1                        ), // input wire enb
        .addrb(active_index_descriptor_r[i]), //(S_MEM_IFACE_ADDR-i*C_OFFSET_BETWEEN_ENGINES-c_offset_engines_config-2)/c_offset_between_descriptors),  // input wire [9 : 0] addrb
        .web  (8'b0                        ), // input wire [0 : 0] web
        .dinb (64'b0                       ), // input wire [63 : 0] dinb
        .doutb(doutb_control_s[i]          )  // output wire [63 : 0] doutb
      );


      wire [31:0] effective_addres_s;
      wire [$clog2(c_offset_between_descriptors)-1:0] effective_addres_trunc_s;
      assign effective_addres_s = (S_MEM_IFACE_ADDR-C_ENGINE_TABLE_OFFSET- i*C_OFFSET_BETWEEN_ENGINES - c_offset_engines_config);
      assign effective_addres_trunc_s = effective_addres_s[$clog2(c_offset_between_descriptors)-1:0];
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          ena_size_r[i]        <= 1'b0;
          wea_size_r[i]        <= {8{1'b0}};
          ena_address_r[i]     <= 1'b0;
          wea_address_r[i]     <= {8{1'b0}};
          ena_control_r[i]     <= 1'b0;
          wea_control_r[i]     <= {8{1'b0}};
        end else begin
          if(HW_REQUEST_TRANSFERENCE) begin
            ena_size_r[i]    <= i==ACTIVE_ENGINE;
            ena_address_r[i] <= 1'h0;
            ena_control_r[i] <= 1'h0;
            wea_size_r[i]    <= 8'hff;
          end else if(S_MEM_IFACE_EN && effective_addres_s <= c_offset_between_descriptors*C_NUM_DESCRIPTORS) begin // If we are writing and this transaction correspond to the current engine
            wea_size_r[i]    <= S_MEM_IFACE_WE;
            wea_address_r[i] <= S_MEM_IFACE_WE;
            wea_control_r[i] <= S_MEM_IFACE_WE;

            case(effective_addres_trunc_s)
              0: begin
                ena_size_r[i]    <= 1'h0;
                ena_address_r[i] <= 1'h1;
                ena_control_r[i] <= 1'h0;
              end
              1: begin
                ena_size_r[i]    <= 1'h1;
                ena_address_r[i] <= 1'h0;
                ena_control_r[i] <= 1'h0;
              end
              2: begin
                ena_size_r[i]    <= 1'h0;
                ena_address_r[i] <= 1'h0;
                ena_control_r[i] <= 1'h1;
              end
              default: begin
                ena_size_r[i]    <= 1'h0;
                ena_address_r[i] <= 1'h0;
                ena_control_r[i] <= 1'h0;
              end

            endcase
          end else begin
            ena_size_r[i]    <= 1'h0;
            ena_address_r[i] <= 1'h0;
            ena_control_r[i] <= 1'h0;
          end
        end
      end

      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          dina_size_r[i]     <= 64'h0;
          dina_address_r[i]  <= 64'h0;
          dina_control_r[i]  <= 64'h0;
        end else begin
          dina_size_r[i]        <= HW_REQUEST_TRANSFERENCE && i==ACTIVE_ENGINE ? HW_NEW_SIZE_AT_DESCRIPTOR : S_MEM_IFACE_DIN;
          dina_address_r[i]     <= S_MEM_IFACE_DIN;
          dina_control_r[i]     <= S_MEM_IFACE_DIN;
        end
      end

      // Index at word level:
      //    Position 0  -  Descriptor 0
      //    Position 1  -  Descriptor 1
      //                .
      //                .
      //                .
      //    Position i  -  Descriptor i
      //                .
      //                .
      //
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          addra_size_r[i]        <= {`CLOG2(C_NUM_DESCRIPTORS){1'b0}};
          addra_address_r[i]     <= {`CLOG2(C_NUM_DESCRIPTORS){1'b0}};
          addra_control_r[i]     <= {`CLOG2(C_NUM_DESCRIPTORS){1'b0}};
        end else begin
          addra_size_r[i]    <= HW_REQUEST_TRANSFERENCE && i==ACTIVE_ENGINE ? active_index_descriptor_r[ACTIVE_ENGINE] : (S_MEM_IFACE_ADDR-C_ENGINE_TABLE_OFFSET-i*C_OFFSET_BETWEEN_ENGINES-c_offset_engines_config-1)/c_offset_between_descriptors;
          addra_address_r[i] <= (S_MEM_IFACE_ADDR-C_ENGINE_TABLE_OFFSET-i*C_OFFSET_BETWEEN_ENGINES-c_offset_engines_config)/c_offset_between_descriptors;
          addra_control_r[i] <= (S_MEM_IFACE_ADDR-C_ENGINE_TABLE_OFFSET-i*C_OFFSET_BETWEEN_ENGINES-c_offset_engines_config-2)/c_offset_between_descriptors;
        end
      end

      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          rdata_descriptor_r[i] <= {C_DATA_WIDTH{1'b0}};
        end else begin
          case(effective_addres_trunc_s)

            0: begin
              rdata_descriptor_r[i]    <= douta_address_s[i];
            end
            1: begin
              rdata_descriptor_r[i]    <= douta_size_s[i];
            end
            2: begin
              rdata_descriptor_r[i]    <= douta_control_s[i];
            end
          endcase
        end
      end

      // Read logic from regs
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          rdata_engine_r[i] <= {C_DATA_WIDTH{1'b0}};
          is_engine_read_r[i] <= 1'b0;
        end else begin
          if(S_MEM_IFACE_EN) begin
            case(S_MEM_IFACE_ADDR)
              C_ENGINE_TABLE_OFFSET + i*C_OFFSET_BETWEEN_ENGINES : begin  // Control byte of DMA engine
                rdata_engine_r[i] <= { {C_DATA_WIDTH-9{1'b0}},engine_irq_r[i],irq_pending_r[i],capabilities_s[i][1:0],error_r[i], stop_r[i],running_r[i],reset_r[i],enable_r[i]};
                is_engine_read_r[i] <= 1'b1;
              end
              C_ENGINE_TABLE_OFFSET + i*C_OFFSET_BETWEEN_ENGINES + 1: begin
                //rdata_engine_r[i] <= {{C_DATA_WIDTH/2-`CLOG2(C_NUM_DESCRIPTORS){1'h0}},active_index_descriptor_r[i],{C_DATA_WIDTH/2-`CLOG2(C_NUM_DESCRIPTORS){1'h0}}, last_index_descriptor_r[i]};
                rdata_engine_r[i] <= {{(C_DATA_WIDTH/2){1'b0}}, {(C_DATA_WIDTH/4-10){1'b0}}, active_index_descriptor_r[i], {(C_DATA_WIDTH/4-10){1'b0}} , last_index_descriptor_r[i]};

                is_engine_read_r[i] <= 1'b1;
              end
              C_ENGINE_TABLE_OFFSET + i*C_OFFSET_BETWEEN_ENGINES + 2: begin
                rdata_engine_r[i] <= time_r[i];
                is_engine_read_r[i] <= 1'b1;
              end
              C_ENGINE_TABLE_OFFSET + i*C_OFFSET_BETWEEN_ENGINES + 3: begin
                rdata_engine_r[i] <= byte_count_r[i];
                is_engine_read_r[i] <= 1'b1;
              end
              default: begin
                rdata_engine_r[i] <= {C_DATA_WIDTH{1'b0}};
                is_engine_read_r[i] <= 1'b0;
              end
            endcase
          end
        end
      end


      // Counters.
      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          time_r[i]        <= 64'h00;
          byte_count_r[i]  <= 64'h00;
          running_r[i]     <= 1'b0;
        end else begin
          if(cl_engine_stats_r[i]) begin
            time_r[i]        <= 64'h00;
            byte_count_r[i]  <= 64'h00;
            running_r[i]     <= 1'b0;
          end else if(enable_r[i] && !stop_r[i]) begin
            time_r[i]        <= time_r[i] + 1;
            byte_count_r[i]  <= byte_count_r[i] + BYTE_COUNT;
          end else begin
            time_r[i]        <= time_r[i];
            byte_count_r[i]  <= byte_count_r[i];
          end
          running_r[i]  <= enable_r[i] & !stop_r[i];
        end
      end
      // Control bytes. Internal design
      assign capabilities_s[i] = i%2+1; // Odd engines -> C2S. Even engines -> S2C

      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          stop_r[i]         <= 1'b0;
          error_r[i]        <= 1'b0;
          irq_pending_r[i]  <= 1'b0;
        end else begin
          if( cl_engine_stats_r[i] ) begin
            stop_r[i]         <= 1'b0;
            error_r[i]        <= 1'b0;
            irq_pending_r[i]  <= 1'b0;
          end else if(i == ACTIVE_ENGINE) begin
            if (i%2 == 0) begin
              stop_r[i]         <= is_end_of_operation_s && (active_index_descriptor_r[i] + 1 == last_index_descriptor_r[i]) ? 1'b1 : 1'b0;
            end else begin
              stop_r[i]         <= is_end_of_operation_s && (active_index_descriptor_r[i] == last_index_descriptor_r[i]) ? 1'b1 : 1'b0;
            end
            error_r[i]        <= operation_error_s;
            irq_pending_r[i]  <= irq_pending_r[i] | irq_r[i];
          end else begin
            stop_r[i]         <= stop_r[i];
            error_r[i]        <= error_r[i];
            irq_pending_r[i]  <=  irq_pending_r[i];
          end
        end
      end


      always @(negedge RST_N or posedge CLK) begin
        if(!RST_N) begin
          active_index_descriptor_r[i] <= 0;
        end else begin
          if( is_end_of_operation_s && i==ACTIVE_ENGINE ) begin
            if(active_index_descriptor_r[i] == C_NUM_DESCRIPTORS-1) begin
              active_index_descriptor_r[i] <= 0;
            end else begin
              active_index_descriptor_r[i] <= active_index_descriptor_r[i] + 1;
            end
          end else begin
            active_index_descriptor_r[i] <= active_index_descriptor_r[i];
          end
        end
      end
    end
  endgenerate

  assign IRQ = irq_r;
  always @(negedge RST_N or posedge CLK) begin
    if (!RST_N) begin
      irq_r <= 0;
      generate_irq_r <= 1'b0;
    end else begin
      generate_irq_r <= doutb_control_s[ACTIVE_ENGINE] & engine_irq_r[ACTIVE_ENGINE]; // Global IRQs and engine IRQs are enable.
      if(is_end_of_operation_s && generate_irq_r) begin   // Check if a descriptor has finished and needs an IRQ
        irq_r <= (1<<ACTIVE_ENGINE);
      end else begin
        irq_r <= 0;
      end
    end
  end


endmodule
