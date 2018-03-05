//===================================================================
// Filename: functionalUnit.sv
// Author: Eric Qin
// Purpose: Basic ALU for HARP Instruction Set
//===================================================================


/*
==========================================
   FUNCTIONAL UNIT Description
==========================================

Includes the ALU, Bar, Mul, Div, Jmp, and Ld/St Functionality in the Execute State

Will also need a control flow divergence stack

The width of the parallel execution units is the number of threads per warp...

*/

`include "harmonica_cfg.sv" 

module functionalUnit(
  input logic clk,
  input logic reset,
  input logic enable,
  input logic [4:0] alu_op,
  input logic fp_ctl,
  input logic [MACHINE_WIDTH-1:0] alu_A,
  input logic [MACHINE_WIDTH-1:0] alu_B,
  input logic mem_read,
  input logic mem_write,
  output logic [MACHINE_WIDTH-1:0] alu_out
);


  // FIXME -> FP may require more cycles
  // FIXME -> signed wires..... and overflow signals


  // basic alu implementation // ENUMERATION
  always_comb begin
    if (enable == 1'b1) begin
      unique case (alu_op)
        5'b00000: alu_out <= 'b0;  // nop
        5'b00001: alu_out <= ~alu_A + 1'b1; // neg (2's complement)  
        5'b00010: alu_out <= ~alu_A; // not
        5'b00011: alu_out <= alu_A & alu_B;   // and    
        5'b00100: alu_out <= alu_A | alu_B;   // or    
        5'b00101: alu_out <= alu_A ^ alu_B;   // xor    
        5'b00110: alu_out <= alu_A + alu_B;   // add    
        5'b00111: alu_out <= alu_A - alu_B;   // sub    
        5'b01000: alu_out <= alu_A * alu_B;   // mul    // different module TODO
        5'b01001: alu_out <= alu_A / alu_B;   // div    // TODO
        5'b01010: alu_out <= alu_A % alu_B;   // mod    
        5'b01011: alu_out <= alu_A << alu_B;  // shl    
        5'b01100: alu_out <= alu_A >> alu_B;  // shr
	5'b01101: begin
			if (alu_A[MACHINE_WIDTH] == 1'b1) begin
				alu_out <= 'b1; // isneg
			end else begin
				alu_out <= 'b0;
			end
		  end
	5'b01110: begin
			if (alu_A == 'b0) begin
				alu_out <= 'b1; // iszero
			end else begin
				alu_out <= 'b0;
			end
		  end
        default: alu_out <= 'b0;
      endcase
    end	
  end

  // need FPU unit implementation
  always_comb begin
    unique case (fp_ctl)
      5'b00000: ;
    endcase
  end
  

  // Need to implement Barrier functionality
  // WIP


  // Need to implement Jmp and control flow divergence stack of split and join
  // WIP

endmodule
