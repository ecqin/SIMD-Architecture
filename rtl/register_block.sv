//===================================================================
// Filename: register_block.sv
// Author: Eric Qin
// Purpose: Top File of register block system verilog file
//===================================================================


/*
==========================================
   Register Design Information
==========================================

Generic file to model the GPR and Predicate register file

Single read and write port for simplicity... 

*/

`include "harmonica_cfg.sv" 

module register_block(
  input clk,
  input reset,
  
  // TODO expand warp_number_read width
  input [LOG2_NUM_WARPS-1:0] warp_number_read,
  input [LOG2_NUM_WARPS-1:0] warp_number_write,
  input logic block_read_en,
  input logic [NUM_TOTAL_THREADS-1:0] thread_en_vector,

  // 3 read ports, as some instructions may read 3 locations within the register file
  input logic read_en_0,
  input logic read_en_1,
  input logic read_en_2,
  input logic [LOG2_NUM_REGS-1:0] read_addr_0,
  input logic [LOG2_NUM_REGS-1:0] read_addr_1,
  input logic [LOG2_NUM_REGS-1:0] read_addr_2,

  // TODO change name block_read_en and write_en to something similar
  // 1 write port
  input logic write_en,
  input logic [NUM_LANES-1:0] write_en_pred,
  input logic [LOG2_NUM_REGS-1:0] write_addr,
  input logic [NUM_LANES*MACHINE_WIDTH-1:0] write_data_vector_0,

  // 3 read outputs
  output logic [NUM_LANES*MACHINE_WIDTH-1:0] read_data_vector_0,
  output logic [NUM_LANES*MACHINE_WIDTH-1:0] read_data_vector_1,
  output logic [NUM_LANES*MACHINE_WIDTH-1:0] read_data_vector_2
);

  logic [LOG2_NUM_WARPS-1:0] warp_number_read_ff;

  logic [NUM_TOTAL_THREADS-1:0] block_read_en_vector;
  logic [NUM_TOTAL_THREADS-1:0] reg_read_en;
  logic [MACHINE_WIDTH-1:0] read_data_block_0 [0:NUM_TOTAL_THREADS-1];
  logic [MACHINE_WIDTH-1:0] read_data_block_1 [0:NUM_TOTAL_THREADS-1];
  logic [MACHINE_WIDTH-1:0] read_data_block_2 [0:NUM_TOTAL_THREADS-1];

  logic [NUM_TOTAL_THREADS-1:0] block_write_pred_vector;
  logic [NUM_TOTAL_THREADS-1:0] block_write_en_vector;
  logic [NUM_TOTAL_THREADS-1:0] reg_write_en;
  
 
  // enables to target each register for reading 
  // FIXME -> reading all of block is not efficient...
  assign block_read_en_vector = {{MACHINE_WIDTH-1{block_read_en}}, block_read_en};
  assign reg_read_en = block_read_en_vector & thread_en_vector;

  // TODO -> add more architectual combinations / parameterize it )

  // TODO for predicated instructions // FIXME -> parameterize
  always_comb begin
    if (write_en_pred[0] == 1'b1) begin
      block_write_pred_vector[7:0] <= 8'h01;
    end else begin
      block_write_pred_vector[7:0] <= 8'h00;
    end

    if (write_en_pred[1] == 1'b1) begin
      block_write_pred_vector[15:8] <= 8'h01;
    end else begin
      block_write_pred_vector[15:8] <= 8'h00;
    end

    if (write_en_pred[2] == 1'b1) begin
      block_write_pred_vector[23:16] <= 8'h01;
    end else begin
      block_write_pred_vector[23:16] <= 8'h00;
    end

    if (write_en_pred[3] == 1'b1) begin
      block_write_pred_vector[31:24] <= 8'h01;
    end else begin
      block_write_pred_vector[31:24] <= 8'h00;
    end

    if (write_en_pred[4] == 1'b1) begin
      block_write_pred_vector[39:32] <= 8'h01;
    end else begin
      block_write_pred_vector[39:32] <= 8'h00;
    end

    if (write_en_pred[5] == 1'b1) begin
      block_write_pred_vector[47:40] <= 8'h01;
    end else begin
      block_write_pred_vector[47:40] <= 8'h00;
    end

    if (write_en_pred[6] == 1'b1) begin
      block_write_pred_vector[55:48] <= 8'h01;
    end else begin
      block_write_pred_vector[55:38] <= 8'h00;
    end

    if (write_en_pred[7] == 1'b1) begin
      block_write_pred_vector[63:56] <= 8'h01;
    end else begin
      block_write_pred_vector[63:56] <= 8'h00;
    end
  end

  assign block_write_en_vector = ((block_write_pred_vector << warp_number_write) & ({MACHINE_WIDTH{write_en}}));
  assign reg_write_en = block_write_en_vector & thread_en_vector;


  // Signal to the next for data vector generation
  always @ (posedge clk) begin
    warp_number_read_ff <= warp_number_read;
  end
  

  // read the data from the correct register file based on the warp, thread, and enables based on indexing
  // FIXME, TODO --> logic may be faulty. hardcoded for temp fix, need to paramterize
  `ifdef NUMBER_OF_SIMD_LANES_IS_4

  // FIXME --> add logic 

  `elsif NUMBER_OF_SIMD_LANES_IS_8

  assign read_data_vector_0 = {
	read_data_block_0[warp_number_read_ff],
	read_data_block_0[warp_number_read_ff+8],
	read_data_block_0[warp_number_read_ff+16],
	read_data_block_0[warp_number_read_ff+24],
	read_data_block_0[warp_number_read_ff+32],
	read_data_block_0[warp_number_read_ff+40],
	read_data_block_0[warp_number_read_ff+48],
	read_data_block_0[warp_number_read_ff+56]};

  assign read_data_vector_1 = {
	read_data_block_1[warp_number_read_ff],
	read_data_block_1[warp_number_read_ff+8],
	read_data_block_1[warp_number_read_ff+16],
	read_data_block_1[warp_number_read_ff+24],
	read_data_block_1[warp_number_read_ff+32],
	read_data_block_1[warp_number_read_ff+40],
	read_data_block_1[warp_number_read_ff+48],
	read_data_block_1[warp_number_read_ff+56]};

  assign read_data_vector_2 = {
	read_data_block_2[warp_number_read_ff],
	read_data_block_2[warp_number_read_ff+8],
	read_data_block_2[warp_number_read_ff+16],
	read_data_block_2[warp_number_read_ff+24],
	read_data_block_2[warp_number_read_ff+32],
	read_data_block_2[warp_number_read_ff+40],
	read_data_block_2[warp_number_read_ff+48],
	read_data_block_2[warp_number_read_ff+56]};

  `endif

  // make sure we are writing to the correct register file
  // TODO enable / read enable / write enables confusing names --> need to rename
  

  // generate one register file for each thread

  // fix write logic
  generate 
    genvar reg_index;  
    for (reg_index=0; reg_index<NUM_TOTAL_THREADS; reg_index=reg_index+1) begin
      register_file RF(.clk(clk), // input
                       .reset(reset), // input 
                       .read_en(reg_read_en[reg_index]), // input
                       .read_en_0(read_en_0), // input
                       .read_en_1(read_en_1), // input
                       .read_en_2(read_en_2), // input
                       .read_addr_0(read_addr_0), // input
                       .read_addr_1(read_addr_1), // input
                       .read_addr_2(read_addr_2), // input 
                       .write_en(reg_write_en[reg_index]), // input
                       .write_addr(write_addr), // input
                       .write_data(write_data_vector_0), // input 
                       .read_data_0(read_data_block_0[reg_index]), // output
                       .read_data_1(read_data_block_1[reg_index]), // output
                       .read_data_2(read_data_block_2[reg_index])); // output
    end
  endgenerate


endmodule

