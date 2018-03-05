//===================================================================
// Filename: executionUnits.sv
// Author: Eric Qin
// Purpose: Top Module for all of the Functional Units
//===================================================================


`include "harmonica_cfg.sv" 

module executionUnits(
  input logic clk,
  input logic reset,
  input logic [NUM_LANES-1:0] enable_vector,
  input logic [4:0] alu_op,
  input logic [NUM_LANES*MACHINE_WIDTH-1:0] alu_A_vector,
  input logic [NUM_LANES*MACHINE_WIDTH-1:0] alu_B_vector,
  input logic mem_read,
  input logic mem_write,
  output logic [NUM_LANES*MACHINE_WIDTH-1:0] alu_out_vector

);


  // Width of the parallel execution units is the number of threads per warp / number of lanes
  generate 
    genvar lane_index;
    for (lane_index=0; lane_index<NUM_LANES ; lane_index=lane_index+1) begin
      functionalUnit exe_unit(.clk(clk), // input
		.reset(reset), // input
		.enable(enable_vector[lane_index]), // input
		.alu_op(alu_op), // input
		.alu_A(alu_A_vector[lane_index*MACHINE_WIDTH+MACHINE_WIDTH-1:lane_index*MACHINE_WIDTH]), // input
		.alu_B(alu_B_vector[lane_index*MACHINE_WIDTH+MACHINE_WIDTH-1:lane_index*MACHINE_WIDTH]), // input
		.mem_read(mem_read),
		.mem_write(mem_write),
		.alu_out(alu_out_vector[lane_index*MACHINE_WIDTH+MACHINE_WIDTH-1:lane_index*MACHINE_WIDTH])); // output
    end
  endgenerate

endmodule
