//===================================================================
// Filename: harmonica.sv
// Author: Eric Qin
// Purpose: Top Core Level implementation of the Harmonica processor
//===================================================================


/*
==========================================
   Harmonica Parameters
==========================================

HARP is distinguished by its parameterizability

For naming conventions, a 4w32/32/8/4 architecture is:

- 4 byte (32-bit) machine words
- word-orientated instruction encodings
- 32 general-purpose and predicate registers
- 8 lanes per warp
- supports 4 warps

Another implementation to be used is: 8w32/32/8/8

- 8 byte (64-bit) registers and addresses
- Word-based (64-bit) fixed-width instruction encoding
- 32 general-purpose registers per lane
- 32 predicate register per lane
- 8 SIMD lanes
- 8 warps (thread groups)

======================================================
   Harmonica MicroArchitecture & Pipeline Description
======================================================

Harmonica is a five stage pipeline design...

The semantics of the architecture allow these warps to be completely independent, executing a single instruction on each active lane in each trip through the pipeline

Details are taken from the original paper...
------------------------------------------
             1 - Sched()

* Simple queue of warp states

* Single issue design, a single warp per cycle proceeds from the scheduler to the fetch stage

* Warps are scheduled in a FIFO manner (leading to a simple circular buffer design for the warp table)


------------------------------------------
             2 - Fetch()

* The warp ID is used as the tag value for both loads and instruction fetches

* The warp state is stored in a table while the operation completes

* Warps leave the fetch stage in the order in which their responses return from the instruction cache

* Them, the warps continue to the two register read pipeline stages

------------------------------------------
             3 - PredRegs()

* Use a single-issue desgn (enables a simplification of the register file)

* Single read port and single write port

* Contains mutiple RFs, one for each thread?

* Contains the predicate registers...

------------------------------------------
             4 - GPRegs()

* Use a single-issue desgn (enables a simplification of the register file)

* Single read port and single write port

* Contains mutiple RFs, one for each thread?

* Contains the interger/FP registers...

------------------------------------------
             5 - Exec()

* Once the warps have gathered their operands from the register stages, execution can be performed

* Harmonica dispatches warps to functional units by opcode with a simple router

* Warps which have finished executing their instructions are returned to the schedule stage, with their program counters and thread masks updated as required by the instruction executed. Concurrently with this their results are written back to the register file.

* Because warps share no state, execution units are independent, with an interface consisting entirely of an input and ouput with a single ready bit for backpressure; a FIFO interface.

* Includes a simple load/store unit to connect to the data cache.. stores the warp state in a table

------------------------------------------
             Additional Notes

Instruction Set Features

* SIMT cores keep threads within a warp at the same program counter in order to reduce pipeline control overhead


*/

`include "harmonica_cfg.sv" 

module harmonica(
  
  // ------------------inputs ----------------------- //
  input logic phi,
  input logic reset,
  input logic dmem_0_req_ready,
  input logic [MACHINE_WIDTH-1:0] dmem_0_resp_contents_data_0, // Edit 8 to MACHINE_WIDTH (FIXME?)
  input logic [MACHINE_WIDTH-1:0] dmem_0_resp_contents_data_1,  // FIXME Defines to NUMBER OF LANES
  input logic [MACHINE_WIDTH-1:0] dmem_0_resp_contents_data_2,
  input logic [MACHINE_WIDTH-1:0] dmem_0_resp_contents_data_3,
`ifdef ARCHITECTURE_SIZE_IS_64
  input logic [MACHINE_WIDTH-1:0] dmem_0_resp_contents_data_4,
  input logic [MACHINE_WIDTH-1:0] dmem_0_resp_contents_data_5,
  input logic [MACHINE_WIDTH-1:0] dmem_0_resp_contents_data_6,
  input logic [MACHINE_WIDTH-1:0] dmem_0_resp_contents_data_7,
`endif // ARCHITECTURE_SIZE_IS_64
  input logic [2:0] dmem_0_resp_contents_id,
  input logic dmem_0_resp_contents_llsc,
  input logic dmem_0_resp_contents_llsc_suc,
  input logic dmem_0_resp_contents_wr,
  input logic dmem_0_resp_valid,
  input logic dmem_1_req_ready,
  input logic [MACHINE_WIDTH-1:0] dmem_1_resp_contents_data_0, // Edit 8 to MACHINE_WIDTH for number of lanes
  input logic [MACHINE_WIDTH-1:0] dmem_1_resp_contents_data_1, 
  input logic [MACHINE_WIDTH-1:0] dmem_1_resp_contents_data_2,
  input logic [MACHINE_WIDTH-1:0] dmem_1_resp_contents_data_3,
`ifdef ARCHITECTURE_SIZE_IS_64
  input logic [MACHINE_WIDTH-1:0] dmem_1_resp_contents_data_4,
  input logic [MACHINE_WIDTH-1:0] dmem_1_resp_contents_data_5,
  input logic [MACHINE_WIDTH-1:0] dmem_1_resp_contents_data_6,
  input logic [MACHINE_WIDTH-1:0] dmem_1_resp_contents_data_7,
`endif // ARCHITECTURE_SIZE_IS_64
  input logic [2:0] dmem_1_resp_contents_id,
  input logic dmem_1_resp_contents_llsc,
  input logic dmem_1_resp_contents_llsc_suc,
  input logic dmem_1_resp_contents_wr,
  input logic dmem_1_resp_valid,
  input logic imem_req_ready,
  input logic [7:0] imem_resp_contents_data_0,
  input logic [7:0] imem_resp_contents_data_1,
  input logic [7:0] imem_resp_contents_data_2,
  input logic [7:0] imem_resp_contents_data_3,
`ifdef ARCHITECTURE_SIZE_IS_64
  input logic [7:0] imem_resp_contents_data_4,
  input logic [7:0] imem_resp_contents_data_5,
  input logic [7:0] imem_resp_contents_data_6,
  input logic [7:0] imem_resp_contents_data_7,
`endif // ARCHITECTURE_SIZE_IS_64
  input logic [2:0] imem_resp_contents_id,
  input logic imem_resp_contents_llsc,
  input logic imem_resp_contents_llsc_suc,
  input logic imem_resp_contents_wr,
  input logic imem_resp_valid,

  // ------------------outputs ----------------------- //
  output logic [29:0] dmem_0_req_contents_addr,
  output logic [MACHINE_WIDTH-1:0] dmem_0_req_contents_data_0,  // FIXME? 8 to machine width
  output logic [MACHINE_WIDTH-1:0] dmem_0_req_contents_data_1,
  output logic [MACHINE_WIDTH-1:0] dmem_0_req_contents_data_2,
  output logic [MACHINE_WIDTH-1:0] dmem_0_req_contents_data_3,
`ifdef ARCHITECTURE_SIZE_IS_64
  output logic [MACHINE_WIDTH-1:0] dmem_0_req_contents_data_4,
  output logic [MACHINE_WIDTH-1:0] dmem_0_req_contents_data_5,
  output logic [MACHINE_WIDTH-1:0] dmem_0_req_contents_data_6,
  output logic [MACHINE_WIDTH-1:0] dmem_0_req_contents_data_7,
`endif // ARCHITECTURE_SIZE_IS_64
  output logic [2:0] dmem_0_req_contents_id,
  output logic dmem_0_req_contents_llsc,
  output logic [3:0] dmem_0_req_contents_mask,
  output logic dmem_0_req_contents_wr,
  output logic dmem_0_req_valid,
  output logic dmem_0_resp_ready,

  output logic [29:0] dmem_1_req_contents_addr,
  output logic [MACHINE_WIDTH-1:0] dmem_1_req_contents_data_0, // edit size from 8 to machine width
  output logic [MACHINE_WIDTH-1:0] dmem_1_req_contents_data_1,
  output logic [MACHINE_WIDTH-1:0] dmem_1_req_contents_data_2,
  output logic [MACHINE_WIDTH-1:0] dmem_1_req_contents_data_3,
`ifdef ARCHITECTURE_SIZE_IS_64
  output logic [MACHINE_WIDTH-1:0] dmem_1_req_contents_data_4,
  output logic [MACHINE_WIDTH-1:0] dmem_1_req_contents_data_5,
  output logic [MACHINE_WIDTH-1:0] dmem_1_req_contents_data_6,
  output logic [MACHINE_WIDTH-1:0] dmem_1_req_contents_data_7,
`endif // ARCHITECTURE_SIZE_IS_64
  output logic [2:0] dmem_1_req_contents_id,
  output logic dmem_1_req_contents_llsc,
  output logic [3:0] dmem_1_req_contents_mask,
  output logic dmem_1_req_contents_wr,
  output logic dmem_1_req_valid,
  output logic dmem_1_resp_ready,

  output logic [29:0] imem_req_contents_addr,
  output logic [7:0] imem_req_contents_data_0,
  output logic [7:0] imem_req_contents_data_1,
  output logic [7:0] imem_req_contents_data_2,
  output logic [7:0] imem_req_contents_data_3,
`ifdef ARCHITECTURE_SIZE_IS_64
  output logic [7:0] imem_req_contents_data_4,
  output logic [7:0] imem_req_contents_data_5,
  output logic [7:0] imem_req_contents_data_6,
  output logic [7:0] imem_req_contents_data_7,
`endif // ARCHITECTURE_SIZE_IS_64
  output logic [2:0] imem_req_contents_id,
  output logic imem_req_contents_llsc,
  output logic [3:0] imem_req_contents_mask,
  output logic imem_req_contents_wr,
  output logic imem_req_valid,
  output logic imem_resp_ready
);

//---------------------------------------------------------------------------------------//
// Sched() stage 

  // Warp Information
  logic [LINE_WIDTH-1:0] warp_packet;

  logic write_packet_en_sched;

  logic [LINE_WIDTH-1:0] write_packet;
  logic [LOG2_NUM_WARPS-1:0] write_warp_id;
  logic [MACHINE_WIDTH-1:0] write_warp_pc; // FIXME not instruction but PC
  logic [NUM_THREADS_PER_WARP-1:0] write_warp_mask;  


//---------------------------------------------------------------------------------------//
// Fetch() stage


  logic write_packet_en_fetch;

  // PC information FIXME
  logic [29:0] pc_counter;
  logic [29:0] pc_counter_next_word; 
  logic [MACHINE_WIDTH-1:0] instruction;

  // active threads have the value of 1, inactive threads have the value of 0
  // t(i,j) -> i is the warp ID and j is the position of the thread within the warp
  
  logic [NUM_TOTAL_THREADS-1:0] thread_en;

  // decoder logic
  logic GPR_read_en;
  logic PRED_read_en;
  logic GPR_write_en;
  logic PRED_write_en;
  logic dec_predicated_bit;
  logic [LOG2_NUM_REGS-1:0] dec_pred_operand;
  logic gpr_rd_en_0;
  logic gpr_rd_en_1;
  logic gpr_rd_en_2;
  logic [LOG2_NUM_REGS-1:0] gpr_rd_addr_0;
  logic [LOG2_NUM_REGS-1:0] gpr_rd_addr_1;
  logic [LOG2_NUM_REGS-1:0] gpr_rd_addr_2;
  logic pred_rd_en_0;
  logic pred_rd_en_1;
  logic pred_rd_en_2;
  logic [LOG2_NUM_REGS-1:0] pred_rd_addr_0;
  logic [LOG2_NUM_REGS-1:0] pred_rd_addr_1;
  logic [LOG2_NUM_REGS-1:0] pred_rd_addr_2;
  logic [4:0] dec_alu_ctl;
  logic pc_jump;
  logic mem_read;
  logic mem_write;
  
//---------------------------------------------------------------------------------------//
// PredRegs() stage


  // For predicated branches
  logic PRED_ctl_block_en;
  logic [4:0] pred_ctl_rd_addr_0; // FIXME parameterize
  logic pred_ctl_rd_en_0;

  logic [NUM_LANES-1:0] pred_warp_thread_en_vector; // TODO, add more documentation

  logic write_packet_en_pred;

  logic [NUM_LANES*MACHINE_WIDTH-1:0] pred_data_vector_0;
  logic [NUM_LANES*MACHINE_WIDTH-1:0] pred_data_vector_1;
  logic [NUM_LANES*MACHINE_WIDTH-1:0] pred_data_vector_2;

//---------------------------------------------------------------------------------------//
// GPRegs() stage


  logic write_packet_en_gpr;

  logic [NUM_LANES-1:0] pred_warp_thread_en_vector_g_ff;

  logic [NUM_LANES*MACHINE_WIDTH-1:0] pred_data_vector_0_ff;
  logic [NUM_LANES*MACHINE_WIDTH-1:0] pred_data_vector_1_ff;
  logic [NUM_LANES*MACHINE_WIDTH-1:0] pred_data_vector_2_ff;

  logic [NUM_LANES*MACHINE_WIDTH-1:0] gpr_data_vector_0;
  logic [NUM_LANES*MACHINE_WIDTH-1:0] gpr_data_vector_1;
  logic [NUM_LANES*MACHINE_WIDTH-1:0] gpr_data_vector_2;

//---------------------------------------------------------------------------------------//
// Exec() stage 

  logic write_packet_en_exec;

  logic [NUM_LANES-1:0] pred_warp_thread_en_vector_e_ff;

  logic [NUM_LANES*MACHINE_WIDTH-1:0] exe_A_vector;
  logic [NUM_LANES*MACHINE_WIDTH-1:0] exe_B_vector;
  logic [NUM_LANES*MACHINE_WIDTH-1:0] exe_out_vector;

  logic [NUM_LANES*MACHINE_WIDTH-1:0] load_vector;


  // writeback logic and warp table logic

  logic [LOG2_NUM_WARPS-1:0] warp_id_exec_ff;
  logic [MACHINE_WIDTH-1:0] warp_pc_exec_ff;
  logic [NUM_THREADS_PER_WARP-1:0] warp_mask_exec_ff;

  logic write_packet_en_exec_ff;

  logic [NUM_LANES*MACHINE_WIDTH-1:0] gpr_write_addr_ff;
  logic [NUM_LANES*MACHINE_WIDTH-1:0] pred_write_addr_ff;
  logic GPR_write_en_ff;
  logic PRED_write_en_ff;
  logic [NUM_LANES*MACHINE_WIDTH-1:0] exe_out_vector_ff;
  logic [MACHINE_WIDTH-1:0] inst_exec_ff;

  logic [NUM_LANES-1:0] pred_warp_thread_en_vector_wb_ff;

//---------------------------------------------------------------------------------------//
// Bus Structs for pipeline

// Control Data Bus
  flopControl_t fetchControlBus, predregControlBus, gpregControlBus, execControlBus;
// Warp Information Bus
  flopWarpData_t schedWarpBus, fetchWarpBus, predregWarpBus, gpregWarpBus, execWarpBus;

/*==========================================================
                   Sched() stage
==========================================================*/
  // Warp Table Module
  // TODO -> finish connecting all of the signals and enables
  warpTable harp_warpTable(.clk(phi),
		.reset(reset),
		.read_packet_en(1'b1),  // FIXME
		.write_packet_en(write_packet_en_exec_ff),
		.write_packet_data(write_packet),
		.read_packet_data(warp_packet),
		.fifo_is_empty(),  // TODO
		.fifo_is_full());  // need to add pipeline stalls (valid/ true)

  // insert warp information to struct to get flopped
  always_comb begin
    if (reset == 1'b1) begin
      schedWarpBus.warpID = 'b0;
      schedWarpBus.pc = 'b0;
      schedWarpBus.mask = 'b0;
    end else begin
      schedWarpBus.warpID = warp_packet[LINE_WIDTH-1:LINE_WIDTH-LOG2_NUM_WARPS];
      schedWarpBus.pc = warp_packet[LINE_WIDTH-LOG2_NUM_WARPS-1:LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH];
      schedWarpBus.mask = warp_packet[LINE_WIDTH-LOG2_NUM_WARPS-MACHINE_WIDTH-1:0];
    end
  end
  

  // TODO- make it more easy to read and understand
  // FIXME, need to understand warp insertion timing, works, but prefer to logically show through code
  assign write_warp_id = execWarpBus.warpID;

  assign write_packet_en_sched = 1'b1;

  // Instruction Memory Addressing Logic for warp table
  always_comb begin
    if (execControlBus.pc_jump == 1'b0) begin
    `ifdef MEMORY_ADDRESSING_IS_WORD
      write_warp_pc <= execWarpBus.pc + 1'b1;
      //write_warp_pc <= warp_pc_exec_ff + 1'b1;
    `elsif MEMORY_ADDRESSING_IS_BYTE
      `ifdef ARCHITECTURE_SIZE_IS_64
        write_warp_pc <= execWarpBus.pc + 4'b1000;
        //write_warp_pc <= warp_pc_exec_ff + 4'b1000;
      `elsif ARCHITECTURE_SIZE_IS_32
        write_warp_pc <= execWarpBus.pc + 3'b100;
        //write_warp_pc <=  warp_pc_exec_ff + 3'b100;
      `endif // ARCHITECTURE_SIZE
    `endif // MEMORY_ADDRESSING
    end else begin
      write_warp_pc <= execControlBus.instruction[29:0];
      //write_warp_pc <= inst_exec_ff[29:0];
    end
  end

  // need to fix for divergence TODO, also need to fix for jump related instructions
  assign write_warp_mask = gpregWarpBus.mask;
  //assign write_warp_mask = warp_mask_exec_ff ;

  assign write_packet = {write_warp_id , write_warp_pc , write_warp_mask};

  // FF for control and warp details
  always @ (posedge phi or posedge reset) begin
    if (reset == 1'b1) begin
      fetchWarpBus <= '{default:'0};
      write_packet_en_fetch <= 'b0;
    end else begin
      fetchWarpBus <= schedWarpBus;
      write_packet_en_fetch <= write_packet_en_sched;

    end
  end


/*==========================================================
                   Fetch() stage
==========================================================*/


  // Set the Program Counter Value
  always @ (posedge reset or posedge phi) begin
    if (reset == 1'b1) begin
      pc_counter <= 'b0;  // Boot Vector will be set to 0x0
    end else begin
      pc_counter <= schedWarpBus.pc;  // need to save one cycle, rather than using fetchWarpBus, us schedWarpBus // TODO - make it less confusing
    end
  end

  // Requesting to Instruction Cache with the Program Counter
  assign imem_req_contents_addr = pc_counter;

  `ifdef ARCHITECTURE_SIZE_IS_64
    assign instruction = {imem_resp_contents_data_7,imem_resp_contents_data_6,
                          imem_resp_contents_data_5,imem_resp_contents_data_4,
                          imem_resp_contents_data_3,imem_resp_contents_data_2,
                          imem_resp_contents_data_1,imem_resp_contents_data_0};
  `elsif ARCHITECTURE_SIZE_IS_32
    assign instruction = {imem_resp_contents_data_3,imem_resp_contents_data_2,
                        imem_resp_contents_data_1,imem_resp_contents_data_0};
  `endif // ARCHITECTURE_SIZE

  
  decoder harp_decoder(.dec_instruction(instruction), // input
		.GPR_read_en(GPR_read_en), // output 
		.PRED_read_en(PRED_read_en), // output
		.GPR_write_en(GPR_write_en), // output
		.PRED_write_en(PRED_write_en), // output
		.dec_predicated_bit(dec_predicated_bit), // output
		.dec_pred_operand(dec_pred_operand), // output
		.gpr_rd_en_0(gpr_rd_en_0), // output
		.gpr_rd_en_1(gpr_rd_en_1), // output
		.gpr_rd_en_2(gpr_rd_en_2), // output
		.gpr_rd_addr_0(gpr_rd_addr_0), // output
		.gpr_rd_addr_1(gpr_rd_addr_1), // output
		.gpr_rd_addr_2(gpr_rd_addr_2), // output
		.pred_rd_en_0(pred_rd_en_0), // output
		.pred_rd_en_1(pred_rd_en_1), // output
		.pred_rd_en_2(pred_rd_en_2), // output
		.pred_rd_addr_0(pred_rd_addr_0), // output
		.pred_rd_addr_1(pred_rd_addr_1), // output
		.pred_rd_addr_2(pred_rd_addr_2), // output
		.dec_alu_ctl(dec_alu_ctl), // output
		.pc_jump(pc_jump), // output
		.mem_read(mem_read), // output
		.mem_write(mem_write)); // output

  // will then need to mask the threads.... based on the instruction and warp table


  // to Fetch Pipeline Bus to get flopped to the input of next stage
  assign fetchControlBus.instruction = instruction;
  assign fetchControlBus.GPR_read_en = GPR_read_en;
  assign fetchControlBus.PRED_read_en = PRED_read_en;
  assign fetchControlBus.GPR_write_en = GPR_write_en;
  assign fetchControlBus.PRED_write_en = PRED_write_en;
  assign fetchControlBus.dec_predicated_bit = dec_predicated_bit;
  assign fetchControlBus.dec_pred_operand = dec_pred_operand;
  assign fetchControlBus.gpr_rd_en_0 = gpr_rd_en_0;
  assign fetchControlBus.gpr_rd_en_1 = gpr_rd_en_1;
  assign fetchControlBus.gpr_rd_en_2 = gpr_rd_en_2;
  assign fetchControlBus.gpr_rd_addr_0 = gpr_rd_addr_0;
  assign fetchControlBus.gpr_rd_addr_1 = gpr_rd_addr_1;
  assign fetchControlBus.gpr_rd_addr_2 = gpr_rd_addr_2;
  assign fetchControlBus.pred_rd_en_0 = pred_rd_en_0;
  assign fetchControlBus.pred_rd_en_1 = pred_rd_en_1;
  assign fetchControlBus.pred_rd_en_2 = pred_rd_en_2;
  assign fetchControlBus.pred_rd_addr_0 = pred_rd_addr_0;
  assign fetchControlBus.pred_rd_addr_1 = pred_rd_addr_1;
  assign fetchControlBus.pred_rd_addr_2 = pred_rd_addr_2;
  assign fetchControlBus.dec_alu_ctl = dec_alu_ctl;
  assign fetchControlBus.pc_jump =pc_jump;
  assign fetchControlBus.mem_read = mem_read;
  assign fetchControlBus.mem_write = mem_write;

  always @ (posedge phi or posedge reset) begin
    if (reset == 1'b1) begin
      predregWarpBus <= '{default:'0};
      write_packet_en_pred <= 'b0;

      predregControlBus <= '{default:'0};
    end else begin
      predregWarpBus <= fetchWarpBus;
      write_packet_en_pred <= write_packet_en_fetch;

      predregControlBus <= fetchControlBus;
    end
  end


  // signals that are already flopped


/*==========================================================
                 PredRegs() stage
==========================================================*/
// FIXME - hardcoded thread_en_vector and warp number 
// v pred data vectors are already clocked, no need to flop, can be used in next stage

  always_comb begin // prediate bit logic to determine what to read from the pred register block
    PRED_ctl_block_en <= (predregControlBus.PRED_read_en | predregControlBus.dec_predicated_bit);
    if (predregControlBus.dec_predicated_bit == 1'b1) begin
      pred_ctl_rd_addr_0 <=  predregControlBus.dec_pred_operand;
      pred_ctl_rd_en_0 <= 1'b1;
    end else begin
      pred_ctl_rd_addr_0 <= predregControlBus.pred_rd_addr_0;
      pred_ctl_rd_en_0 <= predregControlBus.pred_rd_en_0;
    end
  end

  register_block predicateRF(.clk(phi), // input
		.reset(reset), // input
		.warp_number_read(predregWarpBus.warpID), // input
		.warp_number_write(warp_id_exec_ff), // input
		.block_read_en(PRED_ctl_block_en), // input 
		.thread_en_vector(64'hFFFFFFFFFFFFFFFF), // input // FIXME - hardcoded value // or is this correct?? in that predicate register block should always be enabled, and that it is the GPR block that could get masked out, can use 0101010101010101 << warp ID to save energy? // TODO
		.read_en_0(pred_ctl_rd_en_0), // input
		.read_en_1(predregControlBus.pred_rd_en_1), // input
		.read_en_2(predregControlBus.pred_rd_en_2), // input
		.read_addr_0(pred_ctl_rd_addr_0), // input
		.read_addr_1(predregControlBus.pred_rd_addr_1), // input
		.read_addr_2(predregControlBus.pred_rd_addr_2), // input
		.write_en(PRED_write_en_ff), // input
		.write_en_pred(8'hFF), // input // should be hardcoded for now
		.write_addr(inst_exec_ff[51:47]), // input 
		.write_data_vector_0(exe_out_vector_ff), // input
		.read_data_vector_0(pred_data_vector_0), // output
		.read_data_vector_1(pred_data_vector_1), // output
		.read_data_vector_2(pred_data_vector_2)); // output


  // TODO: generate more signals to determine if read_data_vector per entry is 0 or not. This will determine the thread enable in the next stage

  // FIXME Parameterize of the predicate thread enables to the gpr
  // FIXME & TODO --> mask the logic in the writeback stage as well.....
  // The purpose of the logic below is to make sure that the load word is not implemented ??? TODO Check
  // FIXME, does the logic below go into this section??
  always_comb begin
    // TODO check if the predicated bit should be dependent on gpred or pred
    if (predregControlBus.dec_predicated_bit == 1'b1) begin
      //if (pred_data_vector_0[(NUM_LANES-(NUM_LANES-1))*MACHINE_WIDTH-1:0] != 'b0) begin // FIXME paramterize
      // FIXME timing is off, 1 cycle to read from the vector
      if (pred_data_vector_0[63:0] != 'b0) begin
        pred_warp_thread_en_vector[0] <= 1'b1;
      end else begin
        pred_warp_thread_en_vector[0] <= 1'b0;
      end

      if (pred_data_vector_0[127:64] != 'b0) begin
        pred_warp_thread_en_vector[1] <= 1'b1;
      end else begin
        pred_warp_thread_en_vector[1] <= 1'b0;
      end

      if (pred_data_vector_0[191:128] != 'b0) begin
        pred_warp_thread_en_vector[2] <= 1'b1;
      end else begin
        pred_warp_thread_en_vector[2] <= 1'b0;
      end

      if (pred_data_vector_0[255:192] != 'b0) begin
        pred_warp_thread_en_vector[3] <= 1'b1;
      end else begin
        pred_warp_thread_en_vector[3] <= 1'b0;
      end

      if (pred_data_vector_0[319:256] != 'b0) begin
        pred_warp_thread_en_vector[4] <= 1'b1;
      end else begin
        pred_warp_thread_en_vector[4] <= 1'b0;
      end

      if (pred_data_vector_0[383:320] != 'b0) begin
        pred_warp_thread_en_vector[5] <= 1'b1;
      end else begin
        pred_warp_thread_en_vector[5] <= 1'b0;
      end

      if (pred_data_vector_0[447:384] != 'b0) begin
        pred_warp_thread_en_vector[6] <= 1'b1;
      end else begin
        pred_warp_thread_en_vector[6] <= 1'b0;
      end

      if (pred_data_vector_0[511:448] != 'b0) begin
        pred_warp_thread_en_vector[7] <= 1'b1;
      end else begin
        pred_warp_thread_en_vector[7] <= 1'b0;
      end
    end else begin
       pred_warp_thread_en_vector <= 8'hFF; // enable all threads if not predicated instruction
    end
  end

  // flop some signals from the PredRegs() stage to GPRegs() stage
  always @ (posedge phi or posedge reset) begin
    if (reset == 1'b1) begin
      gpregWarpBus <= '{default:'0};

      write_packet_en_gpr <= 'b0;

      gpregControlBus <= '{default:'0};

      pred_warp_thread_en_vector_g_ff <= 'b0;

    end else begin
      gpregWarpBus <= predregWarpBus;

      write_packet_en_gpr <= write_packet_en_pred;

      gpregControlBus <= predregControlBus;

      pred_warp_thread_en_vector_g_ff <= pred_warp_thread_en_vector;

    end
  end


//TODO
// May need to flip flop the pred_data_vector

/*==========================================================
                GPRegs() stage
==========================================================*/
// FIXME: need to parameterize some values and rename
// FIXME - hardcoded values

  register_block generalRF(.clk(phi),
		.reset(reset), // input
		.warp_number_read(gpregWarpBus.warpID), // input
		.warp_number_write(warp_id_exec_ff), // input
		.block_read_en(gpregControlBus.GPR_read_en), // input
		.thread_en_vector(64'hFFFFFFFFFFFFFFFF), // input // FIXME - hardcoded value // FIXME, logic may be incorrect, needs testing... only writeback need 
		.read_en_0(gpregControlBus.gpr_rd_en_0), // input
		.read_en_1(gpregControlBus.gpr_rd_en_1), // input
		.read_en_2(gpregControlBus.gpr_rd_en_2), // input
		.read_addr_0(gpregControlBus.gpr_rd_addr_0), // input
		.read_addr_1(gpregControlBus.gpr_rd_addr_1), // input
		.read_addr_2(gpregControlBus.gpr_rd_addr_2), // input
		.write_en(GPR_write_en_ff), // input
		.write_en_pred(pred_warp_thread_en_vector_e_ff), // input // FIXME // TODO check logic
		.write_addr(inst_exec_ff[51:47]), // input
		.write_data_vector_0(exe_out_vector_ff), // input
		.read_data_vector_0(gpr_data_vector_0), // output
		.read_data_vector_1(gpr_data_vector_1), // output
		.read_data_vector_2(gpr_data_vector_2)); // output


  // flop some signals from the GPRegs()stage to Exec() stage 
  always @ (posedge phi or posedge reset) begin
    if (reset == 1'b1) begin
      execWarpBus <= '{default:'0};

      write_packet_en_exec <= 'b0;

      execControlBus <= '{default:'0};
      pred_data_vector_0_ff <= 'b0;
      pred_data_vector_1_ff <= 'b0;
      pred_data_vector_2_ff <= 'b0;

      pred_warp_thread_en_vector_e_ff <= 'b0;

    end else begin
      execWarpBus <= gpregWarpBus;

      write_packet_en_exec <= write_packet_en_gpr;

      execControlBus <= gpregControlBus;
      pred_data_vector_0_ff <= pred_data_vector_0;
      pred_data_vector_1_ff <= pred_data_vector_1;
      pred_data_vector_2_ff <= pred_data_vector_2;

      pred_warp_thread_en_vector_e_ff <= pred_warp_thread_en_vector_g_ff;
    end
  end



/*==========================================================
                Exec() stage
==========================================================*/
// Muxes to select betwwen what input vector to use (From predicate or general purpose registers...)
// Must parse destination register, register data / intermediate data reference
/*In the case of a 64-bit architecure with 32 GPR and 32 predicate register...

[63] predicated bit
[62:58] specify pred reg.
[57:52] opcode
[51:47] reg operand
[46:42] reg operand
[41:37] reg operand
[36:0] immediate */

// TODO -> implement FIFO backloading structure (timing optimization)

  always_comb begin
    if (execControlBus.gpr_rd_en_1 == 1'b1) begin
      exe_A_vector <= gpr_data_vector_1;
    end else if (execControlBus.pred_rd_en_1 == 1'b1) begin
      exe_A_vector <= pred_data_vector_1_ff;
    end

    if (execControlBus.gpr_rd_en_2 == 1'b1) begin
      exe_B_vector <= gpr_data_vector_2;
    end else if (execControlBus.pred_rd_en_2 == 1'b1) begin
      exe_B_vector <= pred_data_vector_2_ff;
    end else begin // Take intermediate values
      exe_B_vector <= execControlBus.instruction[36:0]; //FIXME need to parameterize
    end
  end

  executionUnits executionUnits(.clk(phi), // input
		.reset(reset), // input
		.enable_vector(8'hFF), // input // FIXME --> hardcoded the enable
		.alu_op(execControlBus.dec_alu_ctl), // input
		.alu_A_vector(exe_A_vector), // input
		.alu_B_vector(exe_B_vector), // input
		.alu_out_vector(exe_out_vector));  // output

  // Load and Store Logic -- contains dmem address and read enable bit
  always_comb begin
    // parse the memory offset from the instruction based on either st or ld
    dmem_0_req_contents_addr = execControlBus.mem_write ? (gpr_data_vector_1 + execControlBus.instruction[29:0]) : execControlBus.instruction[29:0]; // FIXME -> parameterize

    // req to dmem valid only if mem_read or mem_write is enabled
    dmem_0_req_valid = execControlBus.mem_read || execControlBus.mem_write;

    dmem_0_req_contents_wr = execControlBus.mem_write; // if 1'b1, enable writing, if 1'b0 enable reading

    // store data logic
    if (execControlBus.mem_write == 1'b1) begin
      dmem_0_req_contents_data_0 <= gpr_data_vector_0[MACHINE_WIDTH-1:0];
      dmem_0_req_contents_data_1 <= gpr_data_vector_0[2*MACHINE_WIDTH-1:MACHINE_WIDTH];
      dmem_0_req_contents_data_2 <= gpr_data_vector_0[3*MACHINE_WIDTH-1:2*MACHINE_WIDTH];
      dmem_0_req_contents_data_3 <= gpr_data_vector_0[4*MACHINE_WIDTH-1:3*MACHINE_WIDTH];
      dmem_0_req_contents_data_4 <= gpr_data_vector_0[5*MACHINE_WIDTH-1:4*MACHINE_WIDTH];
      dmem_0_req_contents_data_5 <= gpr_data_vector_0[6*MACHINE_WIDTH-1:5*MACHINE_WIDTH];
      dmem_0_req_contents_data_6 <= gpr_data_vector_0[7*MACHINE_WIDTH-1:6*MACHINE_WIDTH];
      dmem_0_req_contents_data_7 <= gpr_data_vector_0[8*MACHINE_WIDTH-1:7*MACHINE_WIDTH];
    end

    // load data logic
    if (execControlBus.mem_read == 1'b1) begin
      load_vector[MACHINE_WIDTH-1:0] <= dmem_0_resp_contents_data_0;
      load_vector[2*MACHINE_WIDTH-1:MACHINE_WIDTH] <= dmem_0_resp_contents_data_1;
      load_vector[3*MACHINE_WIDTH-1:2*MACHINE_WIDTH] <= dmem_0_resp_contents_data_2;
      load_vector[4*MACHINE_WIDTH-1:3*MACHINE_WIDTH] <= dmem_0_resp_contents_data_3;
      load_vector[5*MACHINE_WIDTH-1:4*MACHINE_WIDTH] <= dmem_0_resp_contents_data_4;
      load_vector[6*MACHINE_WIDTH-1:5*MACHINE_WIDTH] <= dmem_0_resp_contents_data_5;
      load_vector[7*MACHINE_WIDTH-1:6*MACHINE_WIDTH] <= dmem_0_resp_contents_data_6;
      load_vector[8*MACHINE_WIDTH-1:7*MACHINE_WIDTH] <= dmem_0_resp_contents_data_7;
    end

  end


  always @ (posedge phi or posedge reset) begin
    if (reset == 1'b1) begin
      warp_id_exec_ff <= 'b0;
      warp_pc_exec_ff <= 'b0;
      warp_mask_exec_ff <= 'b0;

      write_packet_en_exec_ff <= 'b0;

      exe_out_vector_ff <= 'b0;

      pred_warp_thread_en_vector_e_ff <= 'b0;
    end else begin
      warp_id_exec_ff <= execWarpBus.warpID;
      warp_pc_exec_ff <= execWarpBus.pc;
      warp_mask_exec_ff <= execWarpBus.mask;

      write_packet_en_exec_ff <= write_packet_en_exec;

      exe_out_vector_ff = execControlBus.mem_read ? load_vector : exe_out_vector; // load or regular exe_out
      gpr_write_addr_ff <= execControlBus.gpr_rd_addr_0;
      pred_write_addr_ff <= execControlBus.pred_rd_en_0;
      GPR_write_en_ff <= execControlBus.GPR_write_en;
      PRED_write_en_ff <= execControlBus.PRED_write_en;
      inst_exec_ff <= execControlBus.instruction;

      pred_warp_thread_en_vector_wb_ff <= pred_warp_thread_en_vector_e_ff;
    end
  end


endmodule



