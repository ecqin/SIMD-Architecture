//===================================================================
// Filename: decoder.sv
// Author: Eric Qin
// Purpose: Decoder for HARP Instruction Set
//===================================================================


/*

==========================================
   INSTRUCTION CLASS TABLE
==========================================

Argument Class     |   Description                    |   Example
-------------------------------------------------------------------------------
AC_NONE             No arguments                       di;
AC_2REG             2 GPRs, 1 in, 1 out                neg %r1 %r2;
AC_2IMM             1 immediate in, 1 GPR out          ldi %r1, #0xff;
AC_3REG             3 GPRs, 2 in, 1 out                add %r1, %r2, %r2;
AC_3PREG            3 pred. regs, 2in, 1 out           andp @p0, @p0, @p1;
AC_3IMM             GPR in, imm. in, GPR out           andi %r1, %r3, #3;
AC_3REGSRC          3 GPRs in                          tlbadd %r0, %r1, %r2;
AC_1IMM             1 immi in                          jmpi label;
AC_1REG             1 reg in                           jmpr $r;
AC_3IMMSRC          2 GPRs in, 1 imm. in               st %r1, %r2, #10;
AC_PREG_REG         GPR in, pred. reg. out             iszero @p0, %r3;
AC_2PREG            2 pred. regs, 1 in, 1 out          notp @p0, @p0;    


==========================================
   INSTRUCTION NOTES
==========================================

Includes barrier instruction

Split and Join handle branch divergence

==========================================
   CONTROLS OUTPUT GUIDE
==========================================
Functional Unit Execution Control Signal (exec_ctl)

---------------------
    dec_alu_ctl  table
---------------------
        nop   = 00000
	neg   = 00001
	not   = 00010
	and   = 00011
	or    = 00100
	xor   = 00101
	add   = 00110
	sub   = 00111
	mul   = 01000
	div   = 01001
	mod   = 01010
	shl   = 01011
	shr   = 01100
	
reg_field_rf_sel => if 0 { use pred} else if 1 { use gpr} for the "reg operand" fields

==========================================
   HARP INSTRUCTION SET ARCHITECTURE
==========================================

-------------------------------------------------

In the case of a 64-bit architecure with 32 GPR and 32 predicate register...

[63] predicated bit
[62:58] specify pred reg.
[57:52] opcode
[51:47] reg operand
[46:42] reg operand
[41:37] reg operand
[36:0] immediate



TODO -> write logic that will save energy, clean up code that sets to 0 unnessarily
TODO/ FIXME -> do not hardset value

*/

`include "harmonica_cfg.sv" 

module decoder (
  // instruction input to decode
  input logic [MACHINE_WIDTH-1:0] dec_instruction,

  // control bit to determine if register block will be used
  output logic GPR_read_en,
  output logic PRED_read_en,
  output logic GPR_write_en,
  output logic PRED_write_en,

  // control for predicate
  output logic dec_predicated_bit,
  output logic [LOG2_NUM_REGS-1:0] dec_pred_operand,

  // output logic to read the address of general purpose registers
  output logic gpr_rd_en_0,
  output logic gpr_rd_en_1,
  output logic gpr_rd_en_2,
  output logic [LOG2_NUM_REGS-1:0] gpr_rd_addr_0,
  output logic [LOG2_NUM_REGS-1:0] gpr_rd_addr_1,
  output logic [LOG2_NUM_REGS-1:0] gpr_rd_addr_2,

  // output logic to read the address of predicate registers
  output logic pred_rd_en_0,
  output logic pred_rd_en_1,
  output logic pred_rd_en_2,
  output logic [LOG2_NUM_REGS-1:0] pred_rd_addr_0,
  output logic [LOG2_NUM_REGS-1:0] pred_rd_addr_1,
  output logic [LOG2_NUM_REGS-1:0] pred_rd_addr_2,

  // ALU control
  output logic [4:0] dec_alu_ctl,
  

  // PC Control
  output logic pc_jump,

  // FIXME add write location and pred logic

  // WIP, need cleanup
  output logic mem_read,
  output logic mem_write,

  // TODO Logic for predicate instruction
  output logic [4:0] dec_alu_pred_0

);

  logic [5:0] dec_opcode;
  logic [4:0] dec_reg_operand_0;
  logic [4:0] dec_reg_operand_1;
  logic [4:0] dec_reg_operand_2;
  logic [36:0] dec_immediate;

  logic PRED_read_en_temp;

  assign dec_predicated_bit = dec_instruction[MACHINE_WIDTH-1];
  assign dec_pred_operand = dec_instruction[62:58];
  assign dec_opcode = dec_instruction[57:52];
  assign dec_reg_operand_0 = dec_instruction[51:47];
  assign dec_reg_operand_1 = dec_instruction[46:42];
  assign dec_reg_operand_2 = dec_instruction[41:37];
  assign dec_immediate = dec_instruction[36:0];

  // Determines if the Predicate Regs need to be read
  assign PRED_read_en = PRED_read_en_temp || dec_instruction[MACHINE_WIDTH-1];

  // Opcode Decoder
  // TODO Implement Join and Split instructions, need a stack to handle branch divergence
  always_comb begin
    unique case (dec_opcode)
      // nop - NONE
      6'h00: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b0; gpr_rd_en_1 <= 1'b0; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= 'b0 ; gpr_rd_addr_1 <= 'b0 ; gpr_rd_addr_2 <= 'b0 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00000;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // di - NONE
      6'h01: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // ei - NONE
      6'h02: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // tlbadd - 3REGSRC
      6'h03: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // tlbflush - NONE 
      6'h04: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // neg - 2REG 
      6'h05: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b0; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= 'b0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00001;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // not - 2REG 
      6'h06: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b0; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= 'b0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00010;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // and - 3REG
      6'h07: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b1;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; 
               gpr_rd_addr_2 <= dec_reg_operand_2 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00011;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // or - 3REG
      6'h08: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b1;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; 
               gpr_rd_addr_2 <= dec_reg_operand_2 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00100;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // xor - 3REG
      6'h09: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b1;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; 
               gpr_rd_addr_2 <= dec_reg_operand_2 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00101;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // add - 3REG
      6'h0a: begin 
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b1;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; 
               gpr_rd_addr_2 <= dec_reg_operand_2 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00110;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // sub - 3REG
      6'h0b: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b1;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; 
               gpr_rd_addr_2 <= dec_reg_operand_2 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00111;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // mul - 3REG 
      6'h0c: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b1;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; 
               gpr_rd_addr_2 <= dec_reg_operand_2 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b01000;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // div - 3REG
      6'h0d: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b1;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; 
               gpr_rd_addr_2 <= dec_reg_operand_2 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b01001;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // mod - 3REG
      6'h0e: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b1;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; 
               gpr_rd_addr_2 <= dec_reg_operand_2 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b01010;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // shl - 3REG
      6'h0f: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b1;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; 
               gpr_rd_addr_2 <= dec_reg_operand_2 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b01011;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // shr - 3REG
      6'h10: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b1;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; 
               gpr_rd_addr_2 <= dec_reg_operand_2 ;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b01100;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // andi - 3IMM
      6'h11: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00011;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // ori - 3IMM
      6'h12: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00100;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // xori - 3IMM
      6'h13: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00101;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // addi - 3IMM
      6'h14: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00110;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // subi - 3IMM
      6'h15: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00111;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // muli - 3IMM 
      6'h16: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b01000;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // divi - 3IMM
      6'h17: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b01001;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // modi - 3IMM
      6'h18: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b01010;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // shli - 3IMM 
      6'h19: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b01011;

               pc_jump <= 1'b0;
             end

      // shri - 3IMM 
      6'h1a: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b01100;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // jali
      6'h1b: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;

               pc_jump <= 1'b1; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // jalr
      6'h1c: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b1; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // jmpi
      6'h1d: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;

               pc_jump <= 1'b1; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // jmpr
      6'h1e: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b1; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // clone
      6'h1f: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // jalis
      6'h20: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b1; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // jalrs
      6'h21: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b1; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // jmprt
      6'h22: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b1; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // ld
      6'h23: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b1; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b1; mem_write <= 1'b0;
             end

      // st
      6'h24: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               gpr_rd_en_0 <= 1'b1; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= dec_reg_operand_0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0;
               pred_rd_en_0 <= 1'b0; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= 'b0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0;

               dec_alu_ctl  <= 5'b00110; // need to add immediate offset to register value

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b1;
             end

      // ldi
      6'h25: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b1; mem_write <= 1'b0;
             end

      // rtop
      6'h26: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // andp
      6'h27: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b1;
               GPR_write_en = 1'b0; PRED_write_en = 1'b1;
               gpr_rd_en_0 <= 1'b0; gpr_rd_en_1 <= 1'b0; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= 'b0 ; gpr_rd_addr_1 <= 'b0 ; gpr_rd_addr_2 <= 'b0 ;
               pred_rd_en_0 <= 1'b1; pred_rd_en_1 <= 1'b1; pred_rd_en_2 <= 1'b1;
               pred_rd_addr_0 <= dec_reg_operand_0 ; pred_rd_addr_1 <= dec_reg_operand_1 ;
               pred_rd_addr_2 <= dec_reg_operand_2 ;

               dec_alu_ctl  <= 5'b00011;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // orp
      6'h28: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b1;
               GPR_write_en = 1'b0; PRED_write_en = 1'b1;
               gpr_rd_en_0 <= 1'b0; gpr_rd_en_1 <= 1'b0; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= 'b0 ; gpr_rd_addr_1 <= 'b0 ; gpr_rd_addr_2 <= 'b0 ;
               pred_rd_en_0 <= 1'b1; pred_rd_en_1 <= 1'b1; pred_rd_en_2 <= 1'b1;
               pred_rd_addr_0 <= dec_reg_operand_0 ; pred_rd_addr_1 <= dec_reg_operand_1 ;
               pred_rd_addr_2 <= dec_reg_operand_2 ;

               dec_alu_ctl  <= 5'b00100;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // xorp
      6'h29: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b1;
               GPR_write_en = 1'b0; PRED_write_en = 1'b1;
               gpr_rd_en_0 <= 1'b0; gpr_rd_en_1 <= 1'b0; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= 'b0 ; gpr_rd_addr_1 <= 'b0 ; gpr_rd_addr_2 <= 'b0 ;
               pred_rd_en_0 <= 1'b1; pred_rd_en_1 <= 1'b1; pred_rd_en_2 <= 1'b1;
               pred_rd_addr_0 <= dec_reg_operand_0 ; pred_rd_addr_1 <= dec_reg_operand_1 ;
               pred_rd_addr_2 <= dec_reg_operand_2 ;

               dec_alu_ctl  <= 5'b00101;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // notp
      6'h2a: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b1;
               GPR_write_en = 1'b0; PRED_write_en = 1'b1;
               gpr_rd_en_0 <= 1'b0; gpr_rd_en_1 <= 1'b0; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= 'b0 ; gpr_rd_addr_1 <= 'b0 ; gpr_rd_addr_2 <= 'b0 ;
               pred_rd_en_0 <= 1'b1; pred_rd_en_1 <= 1'b1; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= dec_reg_operand_0 ; pred_rd_addr_1 <= dec_reg_operand_1 ; 
	       pred_rd_addr_2 <= 'b0 ;

               dec_alu_ctl  <= 5'b00010;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // isneg
      6'h2b: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b1;
               GPR_write_en = 1'b0; PRED_write_en = 1'b1;
               gpr_rd_en_0 <= 1'b0; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= 'b0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0 ;
               pred_rd_en_0 <= 1'b1; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= dec_reg_operand_0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0 ;

               dec_alu_ctl  <= 5'b01101;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // iszero
      6'h2c: begin
	       GPR_read_en = 1'b1; PRED_read_en_temp = 1'b1;
               GPR_write_en = 1'b0; PRED_write_en = 1'b1;
               gpr_rd_en_0 <= 1'b0; gpr_rd_en_1 <= 1'b1; gpr_rd_en_2 <= 1'b0;
               gpr_rd_addr_0 <= 'b0 ; gpr_rd_addr_1 <= dec_reg_operand_1 ; gpr_rd_addr_2 <= 'b0 ;
               pred_rd_en_0 <= 1'b1; pred_rd_en_1 <= 1'b0; pred_rd_en_2 <= 1'b0;
               pred_rd_addr_0 <= dec_reg_operand_0 ; pred_rd_addr_1 <= 'b0 ; pred_rd_addr_2 <= 'b0 ;

               dec_alu_ctl  <= 5'b01110;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // halt
      6'h2d: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // trap
      6'h2e: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

     // jmpru
      6'h2f: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b1; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // skep
      6'h30: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // reti
      6'h31: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // tlbrm
      6'h32: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // itof
      6'h33: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // ftoi
      6'h34: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // fadd
      6'h35: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // fsub
      6'h36: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // fmul
      6'h37: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // fdiv
      6'h38: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // fneg
      6'h39: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // wspawn %dest, %pc, %src - 3REG
      // Create new warp, copying %src in current warp to the %dest in new warp
      6'h3a: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // split - NONE
      // Control flow diverge
      6'h3b: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // join - NONE
      // Control flow reconverge
      6'h3c: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

      // bar %id, %n - NA
      // Barrier of %n warps. Identified by %id.
      6'h3d: begin
	       GPR_read_en = 1'b0; PRED_read_en_temp = 1'b0;
               GPR_write_en = 1'b0; PRED_write_en = 1'b0;
               dec_alu_ctl  <= 'b0;

               pc_jump <= 1'b0; mem_read <= 1'b0; mem_write <= 1'b0;
             end

    endcase  // end unique case 
  end // end always_comb

endmodule


