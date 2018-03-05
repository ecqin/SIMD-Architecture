//===================================================================
// Filename: register_file.sv
// Author: Eric Qin
// Purpose: Generic register implementation of the Harmonica processor
//===================================================================


/*
==========================================
   Register Design Information
==========================================

Generic file to model the GPR and Predicate register file

Single read and write port for simplicity... 

*/

`include "harmonica_cfg.sv" 

module register_file(
  input clk,
  input reset,

  // 3 read ports, as some instructions may read 3 locations within the register file
  input read_en,
  input logic read_en_0,
  input logic read_en_1,
  input logic read_en_2,
  input logic [LOG2_NUM_REGS-1:0] read_addr_0,
  input logic [LOG2_NUM_REGS-1:0] read_addr_1,
  input logic [LOG2_NUM_REGS-1:0] read_addr_2,

  // 1 write port
  input logic write_en,
  input logic [LOG2_NUM_REGS-1:0] write_addr,
  input logic [MACHINE_WIDTH-1:0] write_data,

  // 3 read outputs
  output logic [MACHINE_WIDTH-1:0] read_data_0,
  output logic [MACHINE_WIDTH-1:0] read_data_1,
  output logic [MACHINE_WIDTH-1:0] read_data_2
);
  // RF Cell based on Machine Width and number of registers
  logic [MACHINE_WIDTH-1:0] RF [0:NUM_REGS-1];


  // clear out the register file at the negedge of reset
  always @ (posedge reset) begin
`ifdef NUMBER_OF_REGISTERS_IS_16
    RF[0] = 0;
    RF[1] = 1;
    RF[2] = 2;
    RF[3] = 3;
    RF[4] = 4;
    RF[5] = 5;
    RF[6] = 6;
    RF[7] = 7;
    RF[8] = 8;
    RF[9] = 9;
    RF[10] = 10;
    RF[11] = 11;
    RF[12] = 12;
    RF[13] = 13;
    RF[14] = 14;
    RF[15] = 15;
`endif // NUMBER_OF_REGISTERS_IS_16
`ifdef NUMBER_OF_REGISTERS_IS_32
    RF[16] = 16;
    RF[17] = 17;
    RF[18] = 18;
    RF[19] = 19;
    RF[20] = 20;
    RF[21] = 21;
    RF[22] = 22;
    RF[23] = 23;
    RF[24] = 24;
    RF[25] = 25;
    RF[26] = 26;
    RF[27] = 27;
    RF[28] = 28;
    RF[29] = 29;
    RF[30] = 30;
    RF[31] = 31;
`endif // NUMBER_OF_REGISTERS_IS_32
`ifdef NUMBER_OF_REGISTERS_IS_64
    RF[32] = 32;
    RF[33] = 33;
    RF[34] = 34;
    RF[35] = 35;
    RF[36] = 36;
    RF[37] = 37;
    RF[38] = 38;
    RF[39] = 39;
    RF[40] = 40;
    RF[41] = 41;
    RF[42] = 42;
    RF[43] = 43;
    RF[44] = 44;
    RF[45] = 45;
    RF[46] = 46;
    RF[47] = 47;
    RF[48] = 48;
    RF[49] = 49;
    RF[50] = 50;
    RF[51] = 51;
    RF[52] = 52;
    RF[53] = 53;
    RF[54] = 54;
    RF[55] = 55;
    RF[56] = 56;
    RF[57] = 57;
    RF[58] = 58;
    RF[59] = 59;
    RF[60] = 60;
    RF[61] = 61;
    RF[62] = 62;
    RF[63] = 63;
`endif // NUMBER_OF_REGISTERS_IS_64
  end
     

  // read functionality of the register file (at positive edge of clock)
  always @ (posedge clk) begin
    if (reset == 1'b0 && read_en == 1'b1) begin
      if (read_en_0 == 1'b1) begin
        read_data_0 <= RF[read_addr_0];
      end else begin
        read_data_0 <= 'b0;
      end

      if (read_en_1 == 1'b1) begin
        read_data_1 <= RF[read_addr_1];
      end else begin
        read_data_1 <= 'b0;
      end

      if (read_en_2 == 1'b1) begin
       read_data_2 <= RF[read_addr_2];
      end else begin
       read_data_2 <= 'b0;
      end
    end
  end

  // write functionality of the register file (at negative edge of clock)
  always @ (negedge clk) begin
    if (write_en == 1'b1) begin
      RF[write_addr] <= write_data;
    end
  end
endmodule



