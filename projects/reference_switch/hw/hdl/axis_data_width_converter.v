/*************************************************************************************************\
|* AXI Stream Data Width Converter
|* ===============================
\*************************************************************************************************/

module axis_data_width_converter
#(
  // AXI Stream Data Width
  parameter IN_TDATA_WIDTH  = 256,
  parameter OUT_TDATA_WIDTH = IN_TDATA_WIDTH / 4,
  parameter TUSER_WIDTH     = 128,

  localparam BUFFER_WIDTH   = IN_TDATA_WIDTH + OUT_TDATA_WIDTH
)
(
  // Global Ports
  input                                  axis_aclk,
  input                                  axis_resetn,

  input  [IN_TDATA_WIDTH - 1:0]          axis_original_tdata,
  input  [((IN_TDATA_WIDTH / 8)) - 1:0]  axis_original_tkeep,
  input  [TUSER_WIDTH-1:0]               axis_original_tuser,
  input                                  axis_original_tvalid,
  output                                 axis_original_tready,
  input                                  axis_original_tlast,

  output [OUT_TDATA_WIDTH - 1:0]         axis_resize_tdata,
  output [((OUT_TDATA_WIDTH / 8)) - 1:0] axis_resize_tkeep,
  output [TUSER_WIDTH - 1:0]             axis_resize_tuser,
  output                                 axis_resize_tvalid,
  input                                  axis_resize_tready,
  output                                 axis_resize_tlast
);
  // Output Queue
  reg [OUT_TDATA_WIDTH - 1:0]            output_queue_tdata;
  reg [(OUT_TDATA_WIDTH / 8) - 1:0]      output_queue_tkeep;
  reg [TUSER_WIDTH - 1:0]                output_queue_tuser;
  reg                                    output_queue_tlast;
  
  reg                                    write_to_output_queue;
  wire                                   output_queue_nearly_full;
  wire                                   output_queue_empty;

  // Output FIFO
  fallthrough_small_fifo
  #(
    .WIDTH(OUT_TDATA_WIDTH+TUSER_WIDTH+OUT_TDATA_WIDTH/8+1), // Fit the whole AXIS packet and the headers
    .MAX_DEPTH_BITS(4)
  )
  output_fifo
  (
    .din         ({output_queue_tdata, output_queue_tkeep, output_queue_tuser, output_queue_tlast}), // Pass the packet heads as input directly to the queue
    .wr_en       (write_to_output_queue), // Write enable
    .rd_en       (send_from_module), // Read enabled
    .dout        ({axis_resize_tdata, axis_resize_tkeep, axis_resize_tuser, axis_resize_tlast}), // Return TLAST, TKEEP, and TUSER directly to the next stage. Write TDATA to a wire for processing
    .full        (),
    .prog_full   (),
    .nearly_full (output_queue_nearly_full),
    .empty       (output_queue_empty),
    .reset       (~axis_resetn),
    .clk         (axis_aclk)
  );

  assign send_from_module   = axis_resize_tvalid & axis_resize_tready;
  assign axis_resize_tvalid = ~output_queue_empty;

  // Buffers
  reg  [BUFFER_WIDTH - 1:0]              write_buffer_tdata;
  reg  [(BUFFER_WIDTH / 8) - 1:0]        write_buffer_tkeep;
  reg  [TUSER_WIDTH - 1:0]               write_buffer_tuser;
  reg                                    write_buffer_tlast;

  reg  [BUFFER_WIDTH - 1:0]              read_buffer_tdata;
  reg  [(BUFFER_WIDTH / 8) - 1:0]        read_buffer_tkeep;
  reg  [TUSER_WIDTH - 1:0]               read_buffer_tuser;
  reg                                    read_buffer_tlast;

  // Step 1: Move data from input to write buffer
  wire                                   should_move_data_to_write_buffer;

  wire [BUFFER_WIDTH - 1:0]              write_buffer_data_after_write;
  wire [(BUFFER_WIDTH / 8) - 1:0]        write_buffer_keep_after_write;

  copy_into_empty
  #(
    .SRC_DATA_WIDTH(IN_TDATA_WIDTH),
    .DEST_DATA_WIDTH(BUFFER_WIDTH)
  )
  copy_from_input_to_write_buffer
  (
    .src_data_in(axis_original_tdata),
    .src_keep_in(axis_original_tkeep),

    .dest_data_in(read_buffer_tdata),
    .dest_keep_in(read_buffer_tkeep),

    .dest_data_out(write_buffer_data_after_write),
    .dest_keep_out(write_buffer_keep_after_write)
  );

  reg  [BUFFER_WIDTH - 1:0]              write_buffer_tdata_next;
  reg  [(BUFFER_WIDTH / 8) - 1:0]        write_buffer_tkeep_next;
  reg  [TUSER_WIDTH - 1:0]               write_buffer_tuser_next;
  reg                                    write_buffer_tlast_next;

  assign should_move_data_to_write_buffer = axis_original_tready & axis_original_tvalid;
  assign axis_original_tready = ~read_buffer_tkeep[OUT_TDATA_WIDTH / 8] & ~read_buffer_tlast;

  always @(*) begin
    write_buffer_tdata_next = read_buffer_tdata;
    write_buffer_tkeep_next = read_buffer_tkeep;
    write_buffer_tuser_next = read_buffer_tuser;
    write_buffer_tlast_next = read_buffer_tlast;

    if (should_move_data_to_write_buffer) begin
      write_buffer_tdata_next = write_buffer_data_after_write;
      write_buffer_tkeep_next = write_buffer_keep_after_write;
      write_buffer_tuser_next = axis_original_tuser ? axis_original_tuser : read_buffer_tuser;
      write_buffer_tlast_next = axis_original_tlast;
    end
  end

  always @(posedge axis_aclk) begin
    if (~axis_resetn) begin
      write_buffer_tdata <= 0;
      write_buffer_tkeep <= 0;
      write_buffer_tuser <= 0;
      write_buffer_tlast <= 0;
    end else begin
      write_buffer_tdata <= write_buffer_tdata_next;
      write_buffer_tkeep <= write_buffer_tkeep_next;
      write_buffer_tuser <= write_buffer_tuser_next;
      write_buffer_tlast <= write_buffer_tlast_next;
    end
  end

  // Step 2: Move data from write buffer to output buffer
  wire [BUFFER_WIDTH - 1:0]              read_buffer_data_after_read;
  wire [(BUFFER_WIDTH / 8) - 1:0]        read_buffer_keep_after_read;

  wire [OUT_TDATA_WIDTH - 1:0]           output_queue_tdata_after_write;
  wire [(OUT_TDATA_WIDTH / 8) - 1:0]     output_queue_tkeep_after_write;

  copy_into_empty 
  #(
    .SRC_DATA_WIDTH(BUFFER_WIDTH),
    .DEST_DATA_WIDTH(OUT_TDATA_WIDTH)
  )
  copy_from_buffer_to_output
  (
    .src_data_in(write_buffer_tdata),
    .src_keep_in(write_buffer_tkeep),

    .dest_data_in(0),
    .dest_keep_in(0),

    .src_data_out(read_buffer_data_after_read),
    .src_keep_out(read_buffer_keep_after_read),

    .dest_data_out(output_queue_tdata_after_write),
    .dest_keep_out(output_queue_tkeep_after_write)
  );

  reg  [BUFFER_WIDTH - 1:0]              read_buffer_tdata_next;
  reg  [(BUFFER_WIDTH / 8) - 1:0]        read_buffer_tkeep_next;
  reg  [TUSER_WIDTH - 1:0]               read_buffer_tuser_next;
  reg                                    read_buffer_tlast_next;

  reg [OUT_TDATA_WIDTH - 1:0]            output_queue_tdata_next;
  reg [(OUT_TDATA_WIDTH / 8) - 1:0]      output_queue_tkeep_next;
  reg [TUSER_WIDTH - 1:0]                output_queue_tuser_next;
  reg                                    output_queue_tlast_next;

  wire                                   will_buffer_be_empty                = ~|read_buffer_keep_after_read;
  wire                                   will_current_network_packet_be_read = will_buffer_be_empty & write_buffer_tlast;
  wire                                   should_move_data_to_output          = ((&output_queue_tkeep_after_write) | will_current_network_packet_be_read) & ~output_queue_nearly_full; // This fills the output buffer or empties the input buffer

  always @(*) begin
    read_buffer_tdata_next = write_buffer_tdata;
    read_buffer_tkeep_next = write_buffer_tkeep;
    read_buffer_tuser_next = write_buffer_tuser;
    read_buffer_tlast_next = write_buffer_tlast;

    output_queue_tdata_next = 0;
    output_queue_tkeep_next = 0;
    output_queue_tuser_next = 0;
    output_queue_tlast_next = 0;

    if (should_move_data_to_output) begin
      read_buffer_tdata_next = read_buffer_data_after_read;
      read_buffer_tkeep_next = read_buffer_keep_after_read;
      read_buffer_tlast_next = write_buffer_tlast & ~will_current_network_packet_be_read;

      output_queue_tdata_next = output_queue_tdata_after_write;
      output_queue_tkeep_next = output_queue_tkeep_after_write;
      output_queue_tuser_next = write_buffer_tuser;
      output_queue_tlast_next = will_current_network_packet_be_read;
    end
  end

  always @(posedge axis_aclk) begin
    if (~axis_resetn) begin
      read_buffer_tdata <= 0;
      read_buffer_tkeep <= 0;
      read_buffer_tuser <= 0;
      read_buffer_tlast <= 0;

      output_queue_tdata <= 0;
      output_queue_tkeep <= 0;
      output_queue_tuser <= 0;
      output_queue_tlast <= 0;

      write_to_output_queue <= 0;
    end else begin
      read_buffer_tdata <= read_buffer_tdata_next;
      read_buffer_tkeep <= read_buffer_tkeep_next;
      read_buffer_tuser <= read_buffer_tuser_next;
      read_buffer_tlast <= read_buffer_tlast_next;

      output_queue_tdata <= output_queue_tdata_next;
      output_queue_tkeep <= output_queue_tkeep_next;
      output_queue_tuser <= output_queue_tuser_next;
      output_queue_tlast <= output_queue_tlast_next;

      write_to_output_queue <= should_move_data_to_output;
    end
  end

endmodule

/*************************************************************************************************\
|* Helper Modules for Data Width Converter
|* =======================================
\*************************************************************************************************/

module copy_into_empty
#(
  parameter SRC_DATA_WIDTH   = 256,
  parameter DEST_DATA_WIDTH  = 256,
  localparam SRC_KEEP_WIDTH  = SRC_DATA_WIDTH / 8,
  localparam DEST_KEEP_WIDTH = DEST_DATA_WIDTH / 8
)
(
  input  [SRC_DATA_WIDTH - 1:0]  src_data_in,
  input  [SRC_KEEP_WIDTH - 1:0]  src_keep_in,

  input  [DEST_DATA_WIDTH - 1:0]  dest_data_in,
  input  [DEST_KEEP_WIDTH - 1:0]  dest_keep_in,

  output [SRC_DATA_WIDTH - 1:0] src_data_out,
  output [SRC_KEEP_WIDTH - 1:0] src_keep_out,

  output [DEST_DATA_WIDTH - 1:0] dest_data_out,
  output [DEST_KEEP_WIDTH - 1:0] dest_keep_out
);

  wire    [31:0] first_non_empty_in_dest_data_out;
  wire    [31:0] first_non_empty_in_dest_keep_out;

  first_null_index
  #(
    .DATA_WIDTH(DEST_KEEP_WIDTH)
  )
  first_non_empty_in_dest_keep_out_calc
  (
    .data(dest_keep_in),
    .index(first_non_empty_in_dest_keep_out)
  );
  assign first_non_empty_in_dest_data_out = first_non_empty_in_dest_keep_out * 8;

  assign dest_data_out = (src_data_in << first_non_empty_in_dest_data_out) | dest_data_in;
  assign dest_keep_out = (src_keep_in << first_non_empty_in_dest_keep_out) | dest_keep_in;

  assign src_data_out  = src_data_in >> (DEST_DATA_WIDTH - first_non_empty_in_dest_data_out);
  assign src_keep_out  = src_keep_in >> (DEST_KEEP_WIDTH - first_non_empty_in_dest_keep_out);

endmodule

module first_null_index
#(parameter DATA_WIDTH = 32)
(
  input      [DATA_WIDTH - 1:0] data,
  output reg [31:0]             index
);

  reg signed [31:0] i;
  reg               found_non_null_index;

  always @(*) begin
    found_non_null_index = 0;
    index                = DATA_WIDTH;
    
    for (i = DATA_WIDTH - 1; i >= 0; i = i - 1) begin
      if (data[i])
        found_non_null_index = 1;
      else if (~found_non_null_index)
        index = i;
    end
  end

endmodule