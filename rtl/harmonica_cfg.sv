//===================================================================
// Filename: harmonica_cfg.sv
// Author: Eric Qin
// Purpose: Header file, includes defines and structure information
//===================================================================

/*===================================================
   Harmonica Parameters Enabling
=====================================================
Select your model parameters, make sure only one is active per block

*/
//=================================================
// Block 1: Architecture Size//
//=================================================
//`define ARCHITECTURE_SIZE_IS_32
`define ARCHITECTURE_SIZE_IS_64

//=================================================
// Block 2: Instruction Encoding 
//=================================================
`define INSTRUCTION_ENCODING_IS_WORD

//=================================================
// Block 3: Number of GP/ Pred Registers per lane
//=================================================
//`define NUMBER_OF_REGISTERS_IS_16
`define NUMBER_OF_REGISTERS_IS_32
//`define NUMBER_OF_REGISTERS_IS_64

//=================================================
// Block 4: Number of SIMD lanes
//=================================================
//`define NUMBER_OF_SIMD_LANES_IS_4
`define NUMBER_OF_SIMD_LANES_IS_8

//=================================================
// Block 5: Number of warps (thread groups)
//=================================================
//`define NUMBER_OF_WARPS_IS_4
`define NUMBER_OF_WARPS_IS_8

//-------------------------------------------------------------------//

//=================================================
// Block 6: Memory Addressing
//=================================================
//`define MEMORY_ADDRESSING_IS_BYTE
`define MEMORY_ADDRESSING_IS_WORD


//=================================================
// Research Block: Enable FIFO Bufferings
//=================================================
//`define ENABLE_FIFO_BUFFERING

//=================================================
// Research Block: Enable Paging
//=================================================
//`define ENABLE_PAGING


//-------------------------------------------------------------------//
//--------Dependent Defines based on Base Parameters ----------------//
//-------------------------------------------------------------------//

// define machine width
`ifdef ARCHITECTURE_SIZE_IS_32
  parameter MACHINE_WIDTH=32;
`elsif ARCHITECTURE_SIZE_IS_64
  parameter MACHINE_WIDTH=64;
`endif

// define number of warps
`ifdef NUMBER_OF_WARPS_IS_4
  parameter NUM_WARPS=4;
  parameter LOG2_NUM_WARPS=2;
`elsif NUMBER_OF_WARPS_IS_8
  parameter NUM_WARPS=8;
  parameter LOG2_NUM_WARPS=3;
`endif

// define number of registers
`ifdef NUMBER_OF_REGISTERS_IS_16
  parameter NUM_REGS=16;
  parameter LOG2_NUM_REGS=4;
`elsif NUMBER_OF_REGISTERS_IS_32
  parameter NUM_REGS=32;
  parameter LOG2_NUM_REGS=5;
  `define NUMBER_OF_REGISTERS_IS_16
`elsif NUMBER_OF_REGISTERS_IS_64
  parameter NUM_REGS=64;
  parameter LOG2_NUM_REGS=6;
  `define NUMBER_OF_REGISTERS_IS_32
  `define NUMBER_OF_REGISTERS_IS_16
`endif

// define number of parallel execution units
`ifdef NUMBER_OF_SIMD_LANES_IS_4
  parameter NUM_EXUNIT = 4;
  parameter NUM_LANES = 4;
  `define NUMBER_OF_EXUNIT_IS_4
`elsif NUMBER_OF_SIMD_LANES_IS_8
  parameter NUM_EXUNIT = 8;
  parameter NUM_LANES = 8;
  `define NUMBER_OF_EXUNIT_IS_4
  `define NUMBER_OF_EXUNIT_IS_8
`endif 



// TODO: Fix below and make it easier to read, kind of messy right now
// define number of hardware threads
`ifdef NUMBER_OF_WARPS_IS_8
  `ifdef NUMBER_OF_SIMD_LANES_IS_8
    parameter NUM_TOTAL_THREADS=64;
    parameter NUM_THREADS_PER_WARP=8;
    `define NUMBER_OF_TOTAL_HARDWARE_THREADS_IS_64
    `define NUMBER_OF_TOTAL_HARDWARE_THREADS_IS_32
    `define NUMBER_OF_TOTAL_HARDWARE_THREADS_IS_16
  `elsif NUMBER_OF_SIMD_LANES_IS_4
    parameter NUM_TOTAL_THREADS=32;
    parameter NUM_THREADS_PER_WARP=4;
    `define NUMBER_OF_TOTAL_HARDWARE_THREADS_IS_32
    `define NUMBER_OF_TOTAL_HARDWARE_THREADS_IS_16
  `endif
`elsif NUMBER_OF_WARPS_IS_4
  `ifdef NUMBER_OF_SIMD_LANES_IS_8
    parameter NUM_TOTAL_THREADS=32;
    parameter NUM_THREADS_PER_WARP=8;
    `define NUMBER_OF_TOTAL_HARDWARE_THREADS_IS_32
    `define NUMBER_OF_TOTAL_HARDWARE_THREADS_IS_16
  `elsif NUMBER_OF_SIMD_LANES_IS_4
    parameter NUM_TOTAL_THREADS=16;
    parameter NUM_THREADS_PER_WARP=4;
    `define NUMBER_OF_TOTAL_HARDWARE_THREADS_IS_16
  `endif
`endif

// WARP Parameter
  parameter LINE_WIDTH = LOG2_NUM_WARPS + MACHINE_WIDTH + NUM_THREADS_PER_WARP;

//-------------------------------------------------------------------//
//---------------------Structure Initialization----------------------//
//-------------------------------------------------------------------//

// Struct for the control logic from the decode stage
typedef struct {
  logic [MACHINE_WIDTH-1:0] instruction;

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

} flopControl_t;

 // Struct for the Warp Table information
  typedef struct {
    logic [LOG2_NUM_WARPS-1:0] warpID;
    logic [MACHINE_WIDTH-1:0] pc;
    logic [NUM_THREADS_PER_WARP-1:0] mask;
  } flopWarpData_t ;

//-------------------------------------------------------------------//
//---------------------Interface Initialization----------------------//
//-------------------------------------------------------------------//
// For debugging purposes
// Still Determining how to implement this..... and if it is worthwile
interface register_data;
  logic mem_read;
endinterface










