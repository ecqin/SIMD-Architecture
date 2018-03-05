//===================================================================
// Filename: harmonica_tb.sv
// Author: Eric Qin
// Purpose: Top level system testing of the harmonica core
//===================================================================

`include "harmonica_cfg.sv" 

module harmonica_tb();

  parameter iCacheDepth=52;
  parameter dCacheDepth=48;

  reg clk;
  reg reset;

/*  // Reading hex values from a file to the cache module...
  initial begin
    $readmemh("./testbench/testbench0.input", temp_instr_mem);
  end */

  reg [63:0] InstructionCache [0:iCacheDepth-1] = {
	64'h0000000000000000,            //nop	0
	64'h0000000000000000,            //nop	1
	64'h0000000000000000,            //nop	2
	64'h0000000084000110,            //andi %r1, %r1, #0 -- 3 // r1 should be 0x0
	64'h0005000084000112,            //andi %r5, %r1, #5 -- 4 // r5 should be 0x0
        64'h0000000008000051,		 //neg %r2 %r2 -- 5 // r2 should be 0xfffffffffffffffe
        64'h0000000084000060,		 //not %r1 %r1 -- 6 // r1 should be 0xffffffffffffffff
	
	64'h000000000c600072,            //and %r4 %r3 %r3 -- 7 // r4 should be 0x3
	64'h0000000090400082,            //or %r5 %r4 %r2 -- 8 // r5 should be 0xffffffffffffffff
	64'h0000000090400092,            //xor %r5 %r4 %r2 -- 9 // r5 should be 0xfffffffffffffffd
        64'h000000008c2000a2,		 //add %r5 %r3 %r1 -- a // r5 should be 0x2
        64'h000000009c0000b2,		 //sub %r5 %r7 %r0 -- b // r5 should be 0x7

	64'h00000000250000c5,            //mul %r10 %r9 %r8 -- c // r10 should be 0x48
	64'h00000000290000d5,            //div %r10 %r10 %r8 -- d // r10 should be 0x9
	64'h00000000ffc000e0,            //mod %r1 %r31 %r30 -- e // r1 should be 0x1
        64'h00000000042000f1,		 //shl %r2 %r1 %r1 -- f // r2 should be 0x2
        64'h0000000008200101,		 //shr %r2 %r2 %r1 -- 10 // r2 should be 0x1

	64'h0001000080000122,            //ori %r5 %r0 #1 -- 11 // r5 should be 0x1
	64'h0001000094000132,            //xori %r5 %r5 #1 -- 12 // r5 should be 0x0
	64'h0001000094000142,            //addi %r5 %r5 #1 -- 13 // r5 should be 0x1
        64'h0001000094000152,		 //subi %r5 %r5 #1 -- 14 // r5 should be 0x0
        64'h0002000084000162,		 //muli %r5 %r1 #2 -- 15 // r5 should be 0x2
	64'h0002000094000172,            //divi %r5 %r5 #2 -- 16 // r5 should be 0x1
	64'h0001000018000183,            //modi %r6 %r6 #1 -- 17 // r6 should be 0x0
	64'h0002000004000193,            //shli %r6 %r1 #2 -- 18 // r6 should be 0x4
        64'h00010000180001a3,		 //shri %r6 %r6 #1 -- 19 // ~ 43695 ns with the value of 0x2
///////////// Debug Breakpoint 1 Start
	// Memory needs to be updated TODO
	64'h0001000080000235,		 // ld %r11, %r0, #1 -- RE 1a //  r11 should be 0xfffffffffffffff1
	64'h0001000000000245,		 // st %r10, %r0, #1 -- not completely correct, FIXME

	64'h000000000c800271,            //andp @p2, @p3, @p4;  -- 1c // p2 should be 0x0
	64'h0000000090a00281,		 //orp @p3, @p4, @p5 -- 1d // p3 should be 0x5
	64'h0000000014c00292,		 //xorp @p4, @p5, @p6 -- 1e // p4 should be 0x3
	64'h00000000000002a0,		 //notp @p0 @p0 -- 1f // p0 should be 0xffffffffffffffff
	64'h00000000040002b0,		 //isneg @p0 %r1 -- 20 // p0 should be 0x0
	64'h00000000000002c0,		 //iszero @p0, %r0 -- 21 // p0 should be 0x1  ~ 57700 ns 

        64'h0000000084008910,            //@p2 ? andi %r1, %r1, #0  // @p2 is 0 // no change for r1
	64'h00000000d400851a,		 //@p1 ? andi %r21, %r21, #0  // @p1 is 1 // r21 change to 0
	64'h0000000000000000,            //nop	0
	64'h0000000000000000,            //nop	1
	64'h0000000000000000,            //nop	2
	64'h0000000000000000,            //nop	3
	64'h0000000000000000,            //nop	4
	64'h0000000000000000,            //nop	5


///////////// Debug Breakpoint 1 End
	64'h00000000000001d0,            //jmpi index 0 --> to NOP! -- checked 

////////////////////// DEBUG BREAKPOINT 2 //////////////////////////////////

	64'h0005000094000112,            //andi %r5, %r5, #5  -- checked
	64'h00050000fc00011f,            //andi %r31, %r31, #5 -- checked
        64'h000000001cc000b4,            //sub %r8, %r7, %r6 -- checked
	64'h0000000084c000b2,            //sub %r5, %r1, %r6 
	64'h0001000080000235,		 // ld %r11, %r0, #1 
	64'h0000000084000110,            //nop 
	64'h0005000084000112,            //nop 
	64'h0005000094000112,            //nop 
        64'h0000000000000000};           //nop

  reg [63:0] DataCache [0:dCacheDepth-1] = {
	64'hfffffffffffffff0,
	64'hfffffffffffffff1,
	64'hfffffffffffffff2,
	64'hfffffffffffffff3,
	64'hfffffffffffffff4,
	64'hfffffffffffffff5,
	64'hfffffffffffffff6,
	64'hfffffffffffffff7,
	64'hfffffffffffffff8,
	64'hfffffffffffffff9,
	64'hfffffffffffffffa,
	64'hfffffffffffffffb,
	64'hfffffffffffffffc,
	64'hfffffffffffffffd,
	64'hfffffffffffffffe,
	64'hffffffffffffffff,
	64'h0000000000000010,
	64'h0000000000000011,
	64'h0000000000000012,
	64'h0000000000000013,
	64'h0000000000000014,
	64'h0000000000000015,
	64'h0000000000000016,
        64'h0000000000000017,
	64'h0000000000000018,
	64'h0000000000000019,
	64'h000000000000001a,
	64'h000000000000001b,
	64'h000000000000001c,
	64'h000000000000001d,
	64'h000000000000001e,
        64'h000000000000001f,
	64'h0000000000000020,
	64'h0000000000000021,
	64'h0000000000000022,
	64'h0000000000000023,
	64'h0000000000000024,
	64'h0000000000000025,
	64'h0000000000000026,
        64'h0000000000000027,
	64'h0000000000000028,
	64'h0000000000000029,
	64'h000000000000002a,
	64'h000000000000002b,
	64'h000000000000002c,
	64'h000000000000002d,
	64'h000000000000002e,
        64'h000000000000002f};

  // Instruction Cache Interconnect Singnals
  logic [MACHINE_WIDTH-1:0] iCacheReadData;
  logic [29:0] iCacheAddr;

  // Data Cache Interconnect
  // TODO / FIXME -> expand it to handle reading in blocks 
  logic [MACHINE_WIDTH-1:0] dCacheReadData;
  logic [MACHINE_WIDTH-1:0] dCacheWriteData;
  logic [29:0] dCacheAddr;

  logic dCacheEn;
  logic dCache_select;

  // Instruction Cache // need to change to @ posedge FIXME --> timing
  always_comb begin
    `ifdef MEMORY_ADDRESSING_IS_WORD
      iCacheReadData = InstructionCache[iCacheAddr];
    `elsif IMEMORY_ADDRESSING_IS_BYTE
      `ifdef ARCHITECTURE_SIZE_IS_64
        iCacheReadData = InstructionCache[iCacheAddr/8];
      `elsif ARCHITECTURE_SIZE_IS_32
        iCacheReadData = InstructionCache[iCacheAddr/4];;
      `endif // ARCHITECTURE_SIZE
    `endif // MEMORY_ADDRESSING
  end

  always @ (posedge clk) begin
    `ifdef MEMORY_ADDRESSING_IS_WORD
      assign dCacheReadData = (dCacheEn && !dCache_select) ? DataCache[dCacheAddr] : 'b0;
    `elsif IMEMORY_ADDRESSING_IS_BYTE
      `ifdef ARCHITECTURE_SIZE_IS_64
        assign dCacheReadData = (dCacheEn && !dCache_select) ? DataCache[dCacheAddr/8] : 'b0;
      `elsif ARCHITECTURE_SIZE_IS_32
        assign dCacheReadData = (dCacheEn && !dCache_select) ? DataCache[dCacheAddr/4] : 'b0;
      `endif // ARCHITECTURE_SIZE
    `endif // MEMORY_ADDRESSING
  end
  
  // Write to the Dcache through the store command
  always @ (posedge clk) begin
    if (dCacheEn && dCache_select) begin
      DataCache[dCacheAddr] = dCacheWriteData;
    end
  end

  // Instantiate Harmonica Core
  harmonica harmonica_core(
		.phi(clk), // core input
		.reset(reset),  // core input

		.dmem_0_resp_contents_data_0(dCacheReadData[MACHINE_WIDTH-1:0]), // core input // FIXME
		.dmem_0_resp_contents_data_1(dCacheReadData[MACHINE_WIDTH-1:0]), // core input 
		.dmem_0_resp_contents_data_2(dCacheReadData[MACHINE_WIDTH-1:0]), // core input
		.dmem_0_resp_contents_data_3(dCacheReadData[MACHINE_WIDTH-1:0]), // core input
		.dmem_0_resp_contents_data_4(dCacheReadData[MACHINE_WIDTH-1:0]), // core input
		.dmem_0_resp_contents_data_5(dCacheReadData[MACHINE_WIDTH-1:0]), // core input
		.dmem_0_resp_contents_data_6(dCacheReadData[MACHINE_WIDTH-1:0]), // core input
		.dmem_0_resp_contents_data_7(dCacheReadData[MACHINE_WIDTH-1:0]), // core input

		.dmem_0_req_contents_data_0(dCacheWriteData[MACHINE_WIDTH-1:0]), // core output  // FIXME
		.dmem_0_req_contents_data_1(dCacheWriteData[MACHINE_WIDTH-1:0]), // core output
		.dmem_0_req_contents_data_2(dCacheWriteData[MACHINE_WIDTH-1:0]), // core output
		.dmem_0_req_contents_data_3(dCacheWriteData[MACHINE_WIDTH-1:0]), // core output
		.dmem_0_req_contents_data_4(dCacheWriteData[MACHINE_WIDTH-1:0]), // core output
		.dmem_0_req_contents_data_5(dCacheWriteData[MACHINE_WIDTH-1:0]), // core output
		.dmem_0_req_contents_data_6(dCacheWriteData[MACHINE_WIDTH-1:0]), // core output
		.dmem_0_req_contents_data_7(dCacheWriteData[MACHINE_WIDTH-1:0]), // core output

		.dmem_0_req_contents_addr(dCacheAddr),  // core output
		.dmem_0_req_valid(dCacheEn), // core output
		.dmem_0_req_contents_wr(dCache_select), // core output - select is 1 for write, 0 for read


		.imem_resp_contents_data_0(iCacheReadData[55:48]), // core input
		.imem_resp_contents_data_1(iCacheReadData[63:56]), // core input 
		.imem_resp_contents_data_2(iCacheReadData[39:32]), // core input
		.imem_resp_contents_data_3(iCacheReadData[47:40]), // core input
		.imem_resp_contents_data_4(iCacheReadData[23:16]), // core input
		.imem_resp_contents_data_5(iCacheReadData[31:24]), // core input
		.imem_resp_contents_data_6(iCacheReadData[7:0]), // core input
		.imem_resp_contents_data_7(iCacheReadData[15:8]), // core input
		.imem_req_contents_addr(iCacheAddr));

  // Instantiate Harmonica Tracker for Debugging Purposes
  // Use external code to print multiple out and the copy & paste // FIXME bad code
  harmonica_tracker harmonica_tracker (
		.clk(harmonica_tb.harmonica_core.phi),
		.GRF0(harmonica_tb.harmonica_core.generalRF.genblk1[0].RF.RF),
		.GRF1(harmonica_tb.harmonica_core.generalRF.genblk1[1].RF.RF),
		.GRF2(harmonica_tb.harmonica_core.generalRF.genblk1[2].RF.RF),
		.GRF3(harmonica_tb.harmonica_core.generalRF.genblk1[3].RF.RF),
		.GRF4(harmonica_tb.harmonica_core.generalRF.genblk1[4].RF.RF),
		.GRF5(harmonica_tb.harmonica_core.generalRF.genblk1[5].RF.RF),
		.GRF6(harmonica_tb.harmonica_core.generalRF.genblk1[6].RF.RF),
		.GRF7(harmonica_tb.harmonica_core.generalRF.genblk1[7].RF.RF),
		.GRF8(harmonica_tb.harmonica_core.generalRF.genblk1[8].RF.RF),
		.GRF9(harmonica_tb.harmonica_core.generalRF.genblk1[9].RF.RF),
		.GRF10(harmonica_tb.harmonica_core.generalRF.genblk1[10].RF.RF),
		.GRF11(harmonica_tb.harmonica_core.generalRF.genblk1[11].RF.RF),
		.GRF12(harmonica_tb.harmonica_core.generalRF.genblk1[12].RF.RF),
		.GRF13(harmonica_tb.harmonica_core.generalRF.genblk1[13].RF.RF),
		.GRF14(harmonica_tb.harmonica_core.generalRF.genblk1[14].RF.RF),
		.GRF15(harmonica_tb.harmonica_core.generalRF.genblk1[15].RF.RF),
		.GRF16(harmonica_tb.harmonica_core.generalRF.genblk1[16].RF.RF),
		.GRF17(harmonica_tb.harmonica_core.generalRF.genblk1[17].RF.RF),
		.GRF18(harmonica_tb.harmonica_core.generalRF.genblk1[18].RF.RF),
		.GRF19(harmonica_tb.harmonica_core.generalRF.genblk1[19].RF.RF),
		.GRF20(harmonica_tb.harmonica_core.generalRF.genblk1[20].RF.RF),
		.GRF21(harmonica_tb.harmonica_core.generalRF.genblk1[21].RF.RF),
		.GRF22(harmonica_tb.harmonica_core.generalRF.genblk1[22].RF.RF),
		.GRF23(harmonica_tb.harmonica_core.generalRF.genblk1[23].RF.RF),
		.GRF24(harmonica_tb.harmonica_core.generalRF.genblk1[24].RF.RF),
		.GRF25(harmonica_tb.harmonica_core.generalRF.genblk1[25].RF.RF),
		.GRF26(harmonica_tb.harmonica_core.generalRF.genblk1[26].RF.RF),
		.GRF27(harmonica_tb.harmonica_core.generalRF.genblk1[27].RF.RF),
		.GRF28(harmonica_tb.harmonica_core.generalRF.genblk1[28].RF.RF),
		.GRF29(harmonica_tb.harmonica_core.generalRF.genblk1[29].RF.RF),
		.GRF30(harmonica_tb.harmonica_core.generalRF.genblk1[30].RF.RF),
		.GRF31(harmonica_tb.harmonica_core.generalRF.genblk1[31].RF.RF),
		.GRF32(harmonica_tb.harmonica_core.generalRF.genblk1[32].RF.RF),
		.GRF33(harmonica_tb.harmonica_core.generalRF.genblk1[33].RF.RF),
		.GRF34(harmonica_tb.harmonica_core.generalRF.genblk1[34].RF.RF),
		.GRF35(harmonica_tb.harmonica_core.generalRF.genblk1[35].RF.RF),
		.GRF36(harmonica_tb.harmonica_core.generalRF.genblk1[36].RF.RF),
		.GRF37(harmonica_tb.harmonica_core.generalRF.genblk1[37].RF.RF),
		.GRF38(harmonica_tb.harmonica_core.generalRF.genblk1[38].RF.RF),
		.GRF39(harmonica_tb.harmonica_core.generalRF.genblk1[39].RF.RF),
		.GRF40(harmonica_tb.harmonica_core.generalRF.genblk1[40].RF.RF),
		.GRF41(harmonica_tb.harmonica_core.generalRF.genblk1[41].RF.RF),
		.GRF42(harmonica_tb.harmonica_core.generalRF.genblk1[42].RF.RF),
		.GRF43(harmonica_tb.harmonica_core.generalRF.genblk1[43].RF.RF),
		.GRF44(harmonica_tb.harmonica_core.generalRF.genblk1[44].RF.RF),
		.GRF45(harmonica_tb.harmonica_core.generalRF.genblk1[45].RF.RF),
		.GRF46(harmonica_tb.harmonica_core.generalRF.genblk1[46].RF.RF),
		.GRF47(harmonica_tb.harmonica_core.generalRF.genblk1[47].RF.RF),
		.GRF48(harmonica_tb.harmonica_core.generalRF.genblk1[48].RF.RF),
		.GRF49(harmonica_tb.harmonica_core.generalRF.genblk1[49].RF.RF),
		.GRF50(harmonica_tb.harmonica_core.generalRF.genblk1[50].RF.RF),
		.GRF51(harmonica_tb.harmonica_core.generalRF.genblk1[51].RF.RF),
		.GRF52(harmonica_tb.harmonica_core.generalRF.genblk1[52].RF.RF),
		.GRF53(harmonica_tb.harmonica_core.generalRF.genblk1[53].RF.RF),
		.GRF54(harmonica_tb.harmonica_core.generalRF.genblk1[54].RF.RF),
		.GRF55(harmonica_tb.harmonica_core.generalRF.genblk1[55].RF.RF),
		.GRF56(harmonica_tb.harmonica_core.generalRF.genblk1[56].RF.RF),
		.GRF57(harmonica_tb.harmonica_core.generalRF.genblk1[57].RF.RF),
		.GRF58(harmonica_tb.harmonica_core.generalRF.genblk1[58].RF.RF),
		.GRF59(harmonica_tb.harmonica_core.generalRF.genblk1[59].RF.RF),
		.GRF60(harmonica_tb.harmonica_core.generalRF.genblk1[60].RF.RF),
		.GRF61(harmonica_tb.harmonica_core.generalRF.genblk1[61].RF.RF),
		.GRF62(harmonica_tb.harmonica_core.generalRF.genblk1[62].RF.RF),
		.GRF63(harmonica_tb.harmonica_core.generalRF.genblk1[63].RF.RF)
		);

  // Instantiate Harmonica Tracker for Debugging Purposes
  // Use external code to print multiple out and the copy & paste // FIXME bad code
  harmonica_tracker_pred harmonica_tracker_pred (
		.clk(harmonica_tb.harmonica_core.phi),
		.PRED0(harmonica_tb.harmonica_core.predicateRF.genblk1[0].RF.RF),
		.PRED1(harmonica_tb.harmonica_core.predicateRF.genblk1[1].RF.RF),
		.PRED2(harmonica_tb.harmonica_core.predicateRF.genblk1[2].RF.RF),
		.PRED3(harmonica_tb.harmonica_core.predicateRF.genblk1[3].RF.RF),
		.PRED4(harmonica_tb.harmonica_core.predicateRF.genblk1[4].RF.RF),
		.PRED5(harmonica_tb.harmonica_core.predicateRF.genblk1[5].RF.RF),
		.PRED6(harmonica_tb.harmonica_core.predicateRF.genblk1[6].RF.RF),
		.PRED7(harmonica_tb.harmonica_core.predicateRF.genblk1[7].RF.RF),
		.PRED8(harmonica_tb.harmonica_core.predicateRF.genblk1[8].RF.RF),
		.PRED9(harmonica_tb.harmonica_core.predicateRF.genblk1[9].RF.RF),
		.PRED10(harmonica_tb.harmonica_core.predicateRF.genblk1[10].RF.RF),
		.PRED11(harmonica_tb.harmonica_core.predicateRF.genblk1[11].RF.RF),
		.PRED12(harmonica_tb.harmonica_core.predicateRF.genblk1[12].RF.RF),
		.PRED13(harmonica_tb.harmonica_core.predicateRF.genblk1[13].RF.RF),
		.PRED14(harmonica_tb.harmonica_core.predicateRF.genblk1[14].RF.RF),
		.PRED15(harmonica_tb.harmonica_core.predicateRF.genblk1[15].RF.RF),
		.PRED16(harmonica_tb.harmonica_core.predicateRF.genblk1[16].RF.RF),
		.PRED17(harmonica_tb.harmonica_core.predicateRF.genblk1[17].RF.RF),
		.PRED18(harmonica_tb.harmonica_core.predicateRF.genblk1[18].RF.RF),
		.PRED19(harmonica_tb.harmonica_core.predicateRF.genblk1[19].RF.RF),
		.PRED20(harmonica_tb.harmonica_core.predicateRF.genblk1[20].RF.RF),
		.PRED21(harmonica_tb.harmonica_core.predicateRF.genblk1[21].RF.RF),
		.PRED22(harmonica_tb.harmonica_core.predicateRF.genblk1[22].RF.RF),
		.PRED23(harmonica_tb.harmonica_core.predicateRF.genblk1[23].RF.RF),
		.PRED24(harmonica_tb.harmonica_core.predicateRF.genblk1[24].RF.RF),
		.PRED25(harmonica_tb.harmonica_core.predicateRF.genblk1[25].RF.RF),
		.PRED26(harmonica_tb.harmonica_core.predicateRF.genblk1[26].RF.RF),
		.PRED27(harmonica_tb.harmonica_core.predicateRF.genblk1[27].RF.RF),
		.PRED28(harmonica_tb.harmonica_core.predicateRF.genblk1[28].RF.RF),
		.PRED29(harmonica_tb.harmonica_core.predicateRF.genblk1[29].RF.RF),
		.PRED30(harmonica_tb.harmonica_core.predicateRF.genblk1[30].RF.RF),
		.PRED31(harmonica_tb.harmonica_core.predicateRF.genblk1[31].RF.RF),
		.PRED32(harmonica_tb.harmonica_core.predicateRF.genblk1[32].RF.RF),
		.PRED33(harmonica_tb.harmonica_core.predicateRF.genblk1[33].RF.RF),
		.PRED34(harmonica_tb.harmonica_core.predicateRF.genblk1[34].RF.RF),
		.PRED35(harmonica_tb.harmonica_core.predicateRF.genblk1[35].RF.RF),
		.PRED36(harmonica_tb.harmonica_core.predicateRF.genblk1[36].RF.RF),
		.PRED37(harmonica_tb.harmonica_core.predicateRF.genblk1[37].RF.RF),
		.PRED38(harmonica_tb.harmonica_core.predicateRF.genblk1[38].RF.RF),
		.PRED39(harmonica_tb.harmonica_core.predicateRF.genblk1[39].RF.RF),
		.PRED40(harmonica_tb.harmonica_core.predicateRF.genblk1[40].RF.RF),
		.PRED41(harmonica_tb.harmonica_core.predicateRF.genblk1[41].RF.RF),
		.PRED42(harmonica_tb.harmonica_core.predicateRF.genblk1[42].RF.RF),
		.PRED43(harmonica_tb.harmonica_core.predicateRF.genblk1[43].RF.RF),
		.PRED44(harmonica_tb.harmonica_core.predicateRF.genblk1[44].RF.RF),
		.PRED45(harmonica_tb.harmonica_core.predicateRF.genblk1[45].RF.RF),
		.PRED46(harmonica_tb.harmonica_core.predicateRF.genblk1[46].RF.RF),
		.PRED47(harmonica_tb.harmonica_core.predicateRF.genblk1[47].RF.RF),
		.PRED48(harmonica_tb.harmonica_core.predicateRF.genblk1[48].RF.RF),
		.PRED49(harmonica_tb.harmonica_core.predicateRF.genblk1[49].RF.RF),
		.PRED50(harmonica_tb.harmonica_core.predicateRF.genblk1[50].RF.RF),
		.PRED51(harmonica_tb.harmonica_core.predicateRF.genblk1[51].RF.RF),
		.PRED52(harmonica_tb.harmonica_core.predicateRF.genblk1[52].RF.RF),
		.PRED53(harmonica_tb.harmonica_core.predicateRF.genblk1[53].RF.RF),
		.PRED54(harmonica_tb.harmonica_core.predicateRF.genblk1[54].RF.RF),
		.PRED55(harmonica_tb.harmonica_core.predicateRF.genblk1[55].RF.RF),
		.PRED56(harmonica_tb.harmonica_core.predicateRF.genblk1[56].RF.RF),
		.PRED57(harmonica_tb.harmonica_core.predicateRF.genblk1[57].RF.RF),
		.PRED58(harmonica_tb.harmonica_core.predicateRF.genblk1[58].RF.RF),
		.PRED59(harmonica_tb.harmonica_core.predicateRF.genblk1[59].RF.RF),
		.PRED60(harmonica_tb.harmonica_core.predicateRF.genblk1[60].RF.RF),
		.PRED61(harmonica_tb.harmonica_core.predicateRF.genblk1[61].RF.RF),
		.PRED62(harmonica_tb.harmonica_core.predicateRF.genblk1[62].RF.RF),
		.PRED63(harmonica_tb.harmonica_core.predicateRF.genblk1[63].RF.RF)
		);


/////////////////////////////////////////////////////////////////////////////////////
  // dump vcd file, set initial values, and determine finish
  initial begin
    //$dumpfile("h2_tb.vcd");
    //$dumpvars;
    clk = 0;
    reset = 0;
    #200 reset = 1;

    //$fscanf(testbench0,"%h\n", memoryload_bus);

    #1750 reset = 0;
    #100000 $finish();
  end

  // Clock generator and signal trackers
  always begin
    #100
    clk = ~clk;
    //$display("clk: %b\treset: %b\tcount: %x", clk, reset, count);
  end

  // I may also want a write the output value of the data cache to a textfile??


endmodule
