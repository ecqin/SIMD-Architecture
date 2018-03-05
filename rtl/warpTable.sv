//===================================================================
// Filename: warpTable.sv
// Author: Eric Qin
// Purpose: Warp FIFO Table in Sched() stage. Acts as a scheduler
//===================================================================


/*
==========================================
   Warp Description
==========================================

// Lots of TODO and FIXME
// Need to include hardcoded value starter code to get program to run...
// work on wspawn / jalrs in the future

*/

`include "harmonica_cfg.sv" 

module warpTable (
  input logic clk,
  input logic reset,
  input logic read_packet_en,
  input logic write_packet_en,
  input logic [LOG2_NUM_WARPS+MACHINE_WIDTH+NUM_THREADS_PER_WARP-1:0] write_packet_data,
  output logic [LOG2_NUM_WARPS+MACHINE_WIDTH+NUM_THREADS_PER_WARP-1:0] read_packet_data,
  output logic fifo_is_empty,
  output logic fifo_is_full
);

  // Each Warp Table entry will include:
  // 1) ID (log2 of the number of warps)
  // 2) PC (Machine width)
  // 3) Mask (Number of lanes)

  //parameter LINE_WIDTH = LOG2_NUM_WARPS + MACHINE_WIDTH + NUM_THREADS_PER_WARP;
  parameter FIFO_DEPTH = 128;
  integer i;

  logic [(LINE_WIDTH-1):0] warpTable [0:(FIFO_DEPTH-1)];
  logic [FIFO_DEPTH-1:0] valid; // valid bit for each warp line

  logic [6:0] head_pointer;
  logic [6:0] tail_pointer;

  // Reset will clear out all warpTable entries and reset the pointers
  // It will also implement tempory hardcoded starter code to get the program running
  // TODO: need to update code as this is for debugging purposes
  always @ (posedge clk or posedge reset) begin
    if (reset == 1'b1) begin 
      for (i=8; i<FIFO_DEPTH; i=i+1) begin
        warpTable[i] <= 'b0;
        valid[i] <= 'b0;
      end

      // implement starter code: FIXME paramertize it
      // all warps starts at the first instruction, will need to readjust in the future
      // FIXME, reduce to 1 warp running at first, and call additional warps through the wspawn instruction

      warpTable[0][LINE_WIDTH-1:LINE_WIDTH-LOG2_NUM_WARPS] <= 3'b000;
      warpTable[0][LINE_WIDTH-LOG2_NUM_WARPS-1:LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH] <= 64'b0;
      warpTable[0][LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH-1:0] <= 8'hFF;
      valid[0] = 1'b1;

      warpTable[1][LINE_WIDTH-1:LINE_WIDTH-LOG2_NUM_WARPS] <= 3'b001;
      warpTable[1][LINE_WIDTH-LOG2_NUM_WARPS-1:LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH] <= 64'b0;
      warpTable[1][LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH-1:0] <= 8'hFF;
      valid[1] = 1'b1;

      warpTable[2][LINE_WIDTH-1:LINE_WIDTH-LOG2_NUM_WARPS] <= 3'b010;
      warpTable[2][LINE_WIDTH-LOG2_NUM_WARPS-1:LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH] <= 64'b0;
      warpTable[2][LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH-1:0] <= 8'hFF;
      valid[2] = 1'b1;

      warpTable[3][LINE_WIDTH-1:LINE_WIDTH-LOG2_NUM_WARPS] <= 3'b011;
      warpTable[3][LINE_WIDTH-LOG2_NUM_WARPS-1:LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH] <= 64'b0;
      warpTable[3][LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH-1:0] <= 8'hFF;
      valid[3] = 1'b1;

      warpTable[4][LINE_WIDTH-1:LINE_WIDTH-LOG2_NUM_WARPS] <= 3'b100;
      warpTable[4][LINE_WIDTH-LOG2_NUM_WARPS-1:LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH] <= 64'b0;
      warpTable[4][LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH-1:0] <= 8'hFF;
      valid[4] = 1'b1;

      warpTable[5][LINE_WIDTH-1:LINE_WIDTH-LOG2_NUM_WARPS] <= 3'b101;
      warpTable[5][LINE_WIDTH-LOG2_NUM_WARPS-1:LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH] <= 64'b0;
      warpTable[5][LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH-1:0] <= 8'hFF;
      valid[5] = 1'b1;

      warpTable[6][LINE_WIDTH-1:LINE_WIDTH-LOG2_NUM_WARPS] <= 3'b110;
      warpTable[6][LINE_WIDTH-LOG2_NUM_WARPS-1:LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH] <= 64'b0;
      warpTable[6][LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH-1:0] <= 8'hFF;
      valid[6] = 1'b1;

      warpTable[7][LINE_WIDTH-1:LINE_WIDTH-LOG2_NUM_WARPS] <= 3'b111;
      warpTable[7][LINE_WIDTH-LOG2_NUM_WARPS-1:LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH] <= 64'b0;
      warpTable[7][LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH-1:0] <= 8'hFF;
      valid[7] = 1'b1;

      head_pointer <= 7'b0000000; // first valid entry
      tail_pointer <= 7'b0001000; // entry after a valid entry (so the tail pointer is pointing to an empty entry, or should be)
    end
  end


  // Logic to determine if FIFO is empty or full
  assign fifo_is_empty = !valid[head_pointer];
  assign fifo_is_full = valid[tail_pointer];


  // write new entry to the tail of the FIFO (need to block operations) ( at negative edge? ) -> might not need to be negative edge....
  always @ (posedge clk) begin
    // if write enable and there is an empty space....
    if ((write_packet_en == 1'b1) && (valid[tail_pointer] == 1'b0) && (reset == 1'b0)) begin
      warpTable[tail_pointer] = write_packet_data;
      valid[tail_pointer] = 1'b1;
      // increment tail pointer in a circular buffer structure
      if (tail_pointer < 7'b1111111) begin
        tail_pointer = tail_pointer + 1;
      end else begin
        tail_pointer = 7'h00;
      end
    end
  end

  // read new entry from the head of the FIFO (need to block operations)
  always @ (posedge clk) begin
    if (reset == 1'b1) begin
      read_packet_data = 'b0;
    end else begin
      if ((read_packet_en == 1'b1) && (valid[head_pointer] == 1'b1) && (reset == 1'b0)) begin
        read_packet_data = warpTable[head_pointer];
        valid[head_pointer] = 'b0;
        // increment head pointer in a circular buffer structure
        if (head_pointer < 7'b11111111) begin
          head_pointer = head_pointer + 1;
        end else begin
          head_pointer = 7'h00;
        end
      end
    end
  end

  
endmodule


