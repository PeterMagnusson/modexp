//======================================================================
//
// tb_modexp_autogenerated.v
// -----------
// Testbench modular exponentiation core.
//
//
// Author: Joachim Strombergson, Peter Magnusson
// Copyright (c) 2015, Assured AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

//------------------------------------------------------------------
// Simulator directives.
//------------------------------------------------------------------
`timescale 1ns/100ps


//------------------------------------------------------------------
// Test module.
//------------------------------------------------------------------
module tb_modexp_autogenerated();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG = 1;

  localparam CLK_HALF_PERIOD = 1;
  localparam CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

  // The DUT address map.
  localparam GENERAL_PREFIX      = 4'h0;
  localparam ADDR_NAME0          = 8'h00;
  localparam ADDR_NAME1          = 8'h01;
  localparam ADDR_VERSION        = 8'h02;

  localparam ADDR_CTRL           = 8'h08;
  localparam CTRL_START_BIT      = 0;

  localparam ADDR_STATUS         = 8'h09;
  localparam STATUS_READY_BIT    = 0;

  localparam ADDR_MODULUS_LENGTH  = 8'h20;
  localparam ADDR_MESSAGE_LENGTH  = 8'h21;
  localparam ADDR_EXPONENT_LENGTH = 8'h22;

  localparam MODULUS_PREFIX      = 4'h1;
  localparam ADDR_MODULUS_START  = 8'h00;
  localparam ADDR_MODULUS_END    = 8'hff;

  localparam EXPONENT_PREFIX     = 4'h2;
  localparam ADDR_EXPONENT_START = 8'h00;
  localparam ADDR_EXPONENT_END   = 8'hff;

  localparam MESSAGE_PREFIX      = 4'h3;
  localparam MESSAGE_START       = 8'h00;
  localparam MESSAGE_END         = 8'hff;

  localparam RESULT_PREFIX       = 4'h4;
  localparam RESULT_START        = 8'h00;
  localparam RESULT_END          = 8'hff;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0]  cycle_ctr;
  reg [31 : 0]  error_ctr;
  reg [31 : 0]  tc_ctr;

  reg [31 : 0]  read_data;
  reg [127 : 0] result_data;

  reg           tb_clk;
  reg           tb_reset_n;
  reg           tb_cs;
  reg           tb_we;
  reg [11  : 0] tb_address;
  reg [31 : 0]  tb_write_data;
  wire [31 : 0] tb_read_data;
  wire          tb_error;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  modexp dut(
             .clk(tb_clk),
             .reset_n(tb_reset_n),
             .cs(tb_cs),
             .we(tb_we),
             .address(tb_address),
             .write_data(tb_write_data),
             .read_data(tb_read_data)
            );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Always running clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD;
      tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // sys_monitor()
  //
  // An always running process that creates a cycle counter and
  // conditionally displays information about the DUT.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      cycle_ctr = cycle_ctr + 1;

      #(CLK_PERIOD);

      if (DEBUG)
        begin
          dump_dut_state();
        end
    end


  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state();
    begin
      $display("cycle: 0x%016x", cycle_ctr);
      $display("State of DUT");
      $display("------------");
      $display("Inputs and outputs:");
      $display("cs   = 0x%01x, we = 0x%01x", tb_cs, tb_we);
      $display("addr = 0x%08x, read_data = 0x%08x, write_data = 0x%08x",
               tb_address, tb_read_data, tb_write_data);
      $display("");

      $display("State:");
      $display("ready_reg = 0x%01x, start_reg = 0x%01x, start_new = 0x%01x, start_we = 0x%01x",
               dut.ready_reg, dut.start_reg, dut.start_new, dut.start_we);
      $display("residue_valid = 0x%01x", dut.residue_valid_reg);
      $display("loop_counter_reg = 0x%08x", dut.loop_counter_reg);
      $display("exponent_length_reg = 0x%02x, modulus_length_reg = 0x%02x",
               dut.exponent_length_reg, dut.modulus_length_reg);
      $display("length_reg = 0x%02x, length_m1_reg = 0x%02x",
               dut.length_reg, dut.length_m1_reg);
      $display("ctrl_reg = 0x%04x", dut.modexp_ctrl_reg);
      $display("");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut();
    begin
      $display("*** Toggle reset.");
      tb_reset_n = 0;

      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
      $display("");
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // display_test_results()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_results();
    begin
      if (error_ctr == 0)
        begin
          $display("*** All %02d test cases completed successfully", tc_ctr);
        end
      else
        begin
          $display("*** %02d tests completed - %02d test cases did not complete successfully.",
                   tc_ctr, error_ctr);
        end
    end
  endtask // display_test_results


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim();
    begin
      cycle_ctr          = 0;
      error_ctr          = 0;
      tc_ctr             = 0;

      tb_clk             = 0;
      tb_reset_n         = 1;

      tb_cs              = 0;
      tb_we              = 0;
      tb_address         = 8'h00;
      tb_write_data      = 32'h00000000;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // read_word()
  //
  // Read a data word from the given address in the DUT.
  // the word read will be available in the global variable
  // read_data.
  //----------------------------------------------------------------
  task read_word(input [11 : 0] address);
    begin
      tb_address = address;
      tb_cs = 1;
      tb_we = 0;
      #(CLK_PERIOD);
      read_data = tb_read_data;
      tb_cs = 0;

      if (DEBUG)
        begin
          $display("*** (read_word) Reading 0x%08x from 0x%02x.", read_data, address);
          $display("");
        end
    end
  endtask // read_word


  //----------------------------------------------------------------
  // write_word()
  //
  // Write the given word to the DUT using the DUT interface.
  //----------------------------------------------------------------
  task write_word(input [11 : 0] address,
                  input [31 : 0] word);
    begin
      if (DEBUG)
        begin
          $display("*** (write_word) Writing 0x%08x to 0x%02x.", word, address);
          $display("");
        end

      tb_address = address;
      tb_write_data = word;
      tb_cs = 1;
      tb_we = 1;
      #(2 * CLK_PERIOD);
      tb_cs = 0;
      tb_we = 0;
    end
  endtask // write_word


  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait until the ready flag in the core is set.
  //----------------------------------------------------------------
  task wait_ready();
    begin
      while (tb_read_data != 32'h00000001)
          read_word({GENERAL_PREFIX, ADDR_STATUS});

      if (DEBUG)
        $display("*** (wait_ready) Ready flag has been set.");
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // dump_message_mem()
  //
  // Dump the contents of the message memory.
  //----------------------------------------------------------------
  task dump_message_mem();
    reg [8 : 0] i;
    begin
      $display("Contents of the message memory:");
      for (i = 0 ; i < 256 ; i = i + 8)
        begin
          $display("message_mem[0x%02x .. 0x%02x] = 0x%08x 0x%08x 0x%08x 0x%08x  0x%08x 0x%08x 0x%08x 0x%08x",
                   i[7 : 0], (i[7 : 0] + 8'h07),
                   dut.message_mem.mem[(i[7 : 0] + 0)], dut.message_mem.mem[(i[7 : 0] + 1)],
                   dut.message_mem.mem[(i[7 : 0] + 2)], dut.message_mem.mem[(i[7 : 0] + 3)],
                   dut.message_mem.mem[(i[7 : 0] + 4)], dut.message_mem.mem[(i[7 : 0] + 5)],
                   dut.message_mem.mem[(i[7 : 0] + 6)], dut.message_mem.mem[(i[7 : 0] + 7)],
                   );
        end
      $display("");
    end
  endtask // dump_message_mem


  //----------------------------------------------------------------
  // dump_exponent_mem()
  //
  // Dump the contents of the exponent memory.
  //----------------------------------------------------------------
  task dump_exponent_mem();
    reg [8 : 0] i;
    begin
      $display("Contents of the exponent memory:");
      for (i = 0 ; i < 256 ; i = i + 8)
        begin
          $display("exponent_mem[0x%02x .. 0x%02x] = 0x%08x 0x%08x 0x%08x 0x%08x  0x%08x 0x%08x 0x%08x 0x%08x",
                   i[7 : 0], (i[7 : 0] + 8'h07),
                   dut.exponent_mem.mem[(i[7 : 0] + 0)], dut.exponent_mem.mem[(i[7 : 0] + 1)],
                   dut.exponent_mem.mem[(i[7 : 0] + 2)], dut.exponent_mem.mem[(i[7 : 0] + 3)],
                   dut.exponent_mem.mem[(i[7 : 0] + 4)], dut.exponent_mem.mem[(i[7 : 0] + 5)],
                   dut.exponent_mem.mem[(i[7 : 0] + 6)], dut.exponent_mem.mem[(i[7 : 0] + 7)],
                   );
        end
      $display("");
    end
  endtask // dump_exponent_mem


  //----------------------------------------------------------------
  // dump_modulus_mem()
  //
  // Dump the contents of the modulus memory.
  //----------------------------------------------------------------
  task dump_modulus_mem();
    reg [8 : 0] i;
    begin
      $display("Contents of the modulus memory:");
      for (i = 0 ; i < 256 ; i = i + 8)
        begin
          $display("modulus_mem[0x%02x .. 0x%02x] = 0x%08x 0x%08x 0x%08x 0x%08x  0x%08x 0x%08x 0x%08x 0x%08x",
                   i[7 : 0], (i[7 : 0] + 8'h07),
                   dut.modulus_mem.mem[(i[7 : 0] + 0)], dut.modulus_mem.mem[(i[7 : 0] + 1)],
                   dut.modulus_mem.mem[(i[7 : 0] + 2)], dut.modulus_mem.mem[(i[7 : 0] + 3)],
                   dut.modulus_mem.mem[(i[7 : 0] + 4)], dut.modulus_mem.mem[(i[7 : 0] + 5)],
                   dut.modulus_mem.mem[(i[7 : 0] + 6)], dut.modulus_mem.mem[(i[7 : 0] + 7)],
                   );
        end
      $display("");
    end
  endtask // dump_modulus_mem


  //----------------------------------------------------------------
  // dump_residue_mem()
  //
  // Dump the contents of the residue memory.
  //----------------------------------------------------------------
  task dump_residue_mem();
    reg [8 : 0] i;
    begin
      $display("Contents of the residue memory:");
      for (i = 0 ; i < 256 ; i = i + 8)
        begin
          $display("residue_mem[0x%02x .. 0x%02x] = 0x%08x 0x%08x 0x%08x 0x%08x  0x%08x 0x%08x 0x%08x 0x%08x",
                   i[7 : 0], (i[7 : 0] + 8'h07),
                   dut.residue_mem.mem[(i[7 : 0] + 0)], dut.residue_mem.mem[(i[7 : 0] + 1)],
                   dut.residue_mem.mem[(i[7 : 0] + 2)], dut.residue_mem.mem[(i[7 : 0] + 3)],
                   dut.residue_mem.mem[(i[7 : 0] + 4)], dut.residue_mem.mem[(i[7 : 0] + 5)],
                   dut.residue_mem.mem[(i[7 : 0] + 6)], dut.residue_mem.mem[(i[7 : 0] + 7)],
                   );
        end
      $display("");
    end
  endtask // dump_residue_mem


  //----------------------------------------------------------------
  // dump_result_mem()
  //
  // Dump the contents of the result memory.
  //----------------------------------------------------------------
  task dump_result_mem();
    reg [8 : 0] i;
    begin
      $display("Contents of the result memory:");
      for (i = 0 ; i < 256 ; i = i + 8)
        begin
          $display("result_mem[0x%02x .. 0x%02x] = 0x%08x 0x%08x 0x%08x 0x%08x  0x%08x 0x%08x 0x%08x 0x%08x",
                   i[7 : 0], (i[7 : 0] + 8'h07),
                   dut.result_mem.mem[(i[7 : 0] + 0)], dut.result_mem.mem[(i[7 : 0] + 1)],
                   dut.result_mem.mem[(i[7 : 0] + 2)], dut.result_mem.mem[(i[7 : 0] + 3)],
                   dut.result_mem.mem[(i[7 : 0] + 4)], dut.result_mem.mem[(i[7 : 0] + 5)],
                   dut.result_mem.mem[(i[7 : 0] + 6)], dut.result_mem.mem[(i[7 : 0] + 7)],
                   );
        end
      $display("");
    end
  endtask // dump_result_mem


  //----------------------------------------------------------------
  // dump_memories()
  //
  // Dump the contents of the memories in the dut.
  //----------------------------------------------------------------
  task dump_memories();
    begin
      dump_message_mem();
      dump_exponent_mem();
      dump_modulus_mem();
      dump_residue_mem();
      dump_result_mem();
    end
  endtask // dump_memories

task autogenerated_BASIC_M4962768465676381896();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_M4962768465676381896");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h00000001);
write_word({MESSAGE_PREFIX, 8'h01}, 32'h946473e1);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h00000001);
write_word({EXPONENT_PREFIX, 8'h01}, 32'h0e85e74f);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000002););
write_word({MODULUS_PREFIX, 8'h00}, 32'h00000001);
write_word({MODULUS_PREFIX, 8'h01}, 32'h70754797);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000002););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000002);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h00000000))
  begin
    $display("Expected: 0x00000000, got 0x%08x", read_data);
  end
read_word({RESULT_PREFIX,8'h01});
read_data = tb_read_data;
if (read_data !== 32'h7761ed4f))
  begin
    $display("Expected: 0x7761ed4f, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_M4962768465676381896
task autogenerated_BASIC_8982867242010371843();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_8982867242010371843");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h00000001);
write_word({MESSAGE_PREFIX, 8'h01}, 32'h6eb4ac2d);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h00000001);
write_word({EXPONENT_PREFIX, 8'h01}, 32'hbb200e41);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000002););
write_word({MODULUS_PREFIX, 8'h00}, 32'h00000001);
write_word({MODULUS_PREFIX, 8'h01}, 32'h27347dc3);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000002););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000002);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h00000000))
  begin
    $display("Expected: 0x00000000, got 0x%08x", read_data);
  end
read_word({RESULT_PREFIX,8'h01});
read_data = tb_read_data;
if (read_data !== 32'h87d16204))
  begin
    $display("Expected: 0x87d16204, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_8982867242010371843
task autogenerated_BASIC_5090788032873075449();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_5090788032873075449");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h00000001);
write_word({MESSAGE_PREFIX, 8'h01}, 32'h9e504a03);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h00000001);
write_word({EXPONENT_PREFIX, 8'h01}, 32'h9bc057ef);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000002););
write_word({MODULUS_PREFIX, 8'h00}, 32'h00000001);
write_word({MODULUS_PREFIX, 8'h01}, 32'hc8b53fe5);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000002););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000002);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h00000001))
  begin
    $display("Expected: 0x00000001, got 0x%08x", read_data);
  end
read_word({RESULT_PREFIX,8'h01});
read_data = tb_read_data;
if (read_data !== 32'hc1a6494c))
  begin
    $display("Expected: 0xc1a6494c, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_5090788032873075449
task autogenerated_BASIC_8448510918869952728();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_8448510918869952728");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h00000001);
write_word({MESSAGE_PREFIX, 8'h01}, 32'h73f7b309);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h00000001);
write_word({EXPONENT_PREFIX, 8'h01}, 32'h91c10f7f);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000002););
write_word({MODULUS_PREFIX, 8'h00}, 32'h00000001);
write_word({MODULUS_PREFIX, 8'h01}, 32'h4be322c9);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000002););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000002);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h00000000))
  begin
    $display("Expected: 0x00000000, got 0x%08x", read_data);
  end
read_word({RESULT_PREFIX,8'h01});
read_data = tb_read_data;
if (read_data !== 32'h9a155286))
  begin
    $display("Expected: 0x9a155286, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_8448510918869952728
task autogenerated_BASIC_4036237668019554146();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_4036237668019554146");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h00000001);
write_word({MESSAGE_PREFIX, 8'h01}, 32'hd0f3961d);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h00000001);
write_word({EXPONENT_PREFIX, 8'h01}, 32'hcdbc9c9d);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000002););
write_word({MODULUS_PREFIX, 8'h00}, 32'h00000001);
write_word({MODULUS_PREFIX, 8'h01}, 32'h30367d5b);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000002););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000002);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h00000001))
  begin
    $display("Expected: 0x00000001, got 0x%08x", read_data);
  end
read_word({RESULT_PREFIX,8'h01});
read_data = tb_read_data;
if (read_data !== 32'h15a9c15d))
  begin
    $display("Expected: 0x15a9c15d, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_4036237668019554146
task autogenerated_BASIC_M8925041444689012509();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_M8925041444689012509");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h00000001);
write_word({MESSAGE_PREFIX, 8'h01}, 32'h34130e17);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h00000001);
write_word({EXPONENT_PREFIX, 8'h01}, 32'hf45e52c9);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000002););
write_word({MODULUS_PREFIX, 8'h00}, 32'h00000001);
write_word({MODULUS_PREFIX, 8'h01}, 32'h9cb5c68d);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000002););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000002);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h00000000))
  begin
    $display("Expected: 0x00000000, got 0x%08x", read_data);
  end
read_word({RESULT_PREFIX,8'h01});
read_data = tb_read_data;
if (read_data !== 32'h7c129d37))
  begin
    $display("Expected: 0x7c129d37, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_M8925041444689012509
task autogenerated_BASIC_M5713608137760059379();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_M5713608137760059379");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h00000001);
write_word({MESSAGE_PREFIX, 8'h01}, 32'h77505dbd);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h00000001);
write_word({EXPONENT_PREFIX, 8'h01}, 32'hdb808627);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000002););
write_word({MODULUS_PREFIX, 8'h00}, 32'h00000001);
write_word({MODULUS_PREFIX, 8'h01}, 32'had1fed09);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000002););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000002);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h00000001))
  begin
    $display("Expected: 0x00000001, got 0x%08x", read_data);
  end
read_word({RESULT_PREFIX,8'h01});
read_data = tb_read_data;
if (read_data !== 32'h842cd733))
  begin
    $display("Expected: 0x842cd733, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_M5713608137760059379
task autogenerated_BASIC_6816968587684568101();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_6816968587684568101");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h00000001);
write_word({MESSAGE_PREFIX, 8'h01}, 32'h3272b6ef);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h00000001);
write_word({EXPONENT_PREFIX, 8'h01}, 32'h2cb6c09b);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000002););
write_word({MODULUS_PREFIX, 8'h00}, 32'h00000001);
write_word({MODULUS_PREFIX, 8'h01}, 32'hefbc64fd);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000002););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000002);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h00000001))
  begin
    $display("Expected: 0x00000001, got 0x%08x", read_data);
  end
read_word({RESULT_PREFIX,8'h01});
read_data = tb_read_data;
if (read_data !== 32'h59c3b603))
  begin
    $display("Expected: 0x59c3b603, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_6816968587684568101
task autogenerated_BASIC_4168013900853404774();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_4168013900853404774");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h00000001);
write_word({MESSAGE_PREFIX, 8'h01}, 32'h3c20bbcf);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h00000001);
write_word({EXPONENT_PREFIX, 8'h01}, 32'ha495d8ab);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000002););
write_word({MODULUS_PREFIX, 8'h00}, 32'h00000001);
write_word({MODULUS_PREFIX, 8'h01}, 32'h75ddb9ef);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000002););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000002);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h00000001))
  begin
    $display("Expected: 0x00000001, got 0x%08x", read_data);
  end
read_word({RESULT_PREFIX,8'h01});
read_data = tb_read_data;
if (read_data !== 32'h1413eac7))
  begin
    $display("Expected: 0x1413eac7, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_4168013900853404774
task autogenerated_BASIC_M8394821325674331878();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_M8394821325674331878");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h00000001);
write_word({MESSAGE_PREFIX, 8'h01}, 32'h93d3d0d3);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h00000001);
write_word({EXPONENT_PREFIX, 8'h01}, 32'h43c2dfef);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000002););
write_word({MODULUS_PREFIX, 8'h00}, 32'h00000001);
write_word({MODULUS_PREFIX, 8'h01}, 32'h7443cbf1);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000002););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000002);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h00000000))
  begin
    $display("Expected: 0x00000000, got 0x%08x", read_data);
  end
read_word({RESULT_PREFIX,8'h01});
read_data = tb_read_data;
if (read_data !== 32'hc2eda7c3))
  begin
    $display("Expected: 0xc2eda7c3, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_M8394821325674331878
task autogenerated_BASIC_M2919828800172604435();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_M2919828800172604435");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h3d746ec5);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h3f7ea6d5);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000001););
write_word({MODULUS_PREFIX, 8'h00}, 32'h29b6675f);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000001););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000001);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h040c43d8))
  begin
    $display("Expected: 0x040c43d8, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_M2919828800172604435
task autogenerated_BASIC_4770912732078070597();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_4770912732078070597");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h200c0f45);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h24774bab);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000001););
write_word({MODULUS_PREFIX, 8'h00}, 32'h234ca073);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000001););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000001);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h14505436))
  begin
    $display("Expected: 0x14505436, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_4770912732078070597
task autogenerated_BASIC_3593487472385409519();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_3593487472385409519");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h248819d1);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h2ad2b6ed);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000001););
write_word({MODULUS_PREFIX, 8'h00}, 32'h269cc6bf);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000001););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000001);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h0f09d466))
  begin
    $display("Expected: 0x0f09d466, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_3593487472385409519
task autogenerated_BASIC_4981749054780354961();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_4981749054780354961");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h27bec4e7);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h36fe540f);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000001););
write_word({MODULUS_PREFIX, 8'h00}, 32'h25a46d61);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000001););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000001);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h0bab2269))
  begin
    $display("Expected: 0x0bab2269, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_4981749054780354961
task autogenerated_BASIC_7702189670289360961();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_7702189670289360961");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h302def29);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h25b9c233);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000001););
write_word({MODULUS_PREFIX, 8'h00}, 32'h33af5461);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000001););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000001);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h0229dc08))
  begin
    $display("Expected: 0x0229dc08, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_7702189670289360961
task autogenerated_BASIC_M5169634701858105792();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_M5169634701858105792");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h240d8cf5);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h2a6a7381);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000001););
write_word({MODULUS_PREFIX, 8'h00}, 32'h3471d1e9);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000001););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000001);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h244dec19))
  begin
    $display("Expected: 0x244dec19, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_M5169634701858105792
task autogenerated_BASIC_6469444563916025786();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_6469444563916025786");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h3cc9270b);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h27858fdd);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000001););
write_word({MODULUS_PREFIX, 8'h00}, 32'h21e65001);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000001););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000001);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h17200d8c))
  begin
    $display("Expected: 0x17200d8c, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_6469444563916025786
task autogenerated_BASIC_M2453278165832221565();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_M2453278165832221565");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h30ca6ceb);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h212c387b);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000001););
write_word({MODULUS_PREFIX, 8'h00}, 32'h2e07a7bb);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000001););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000001);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h0fc15a1f))
  begin
    $display("Expected: 0x0fc15a1f, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_M2453278165832221565
task autogenerated_BASIC_M1847183855567461116();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_M1847183855567461116");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h3d02c5a1);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h35f12b45);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000001););
write_word({MODULUS_PREFIX, 8'h00}, 32'h32f0b03f);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000001););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000001);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h2340f96f))
  begin
    $display("Expected: 0x2340f96f, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_M1847183855567461116
task autogenerated_BASIC_M7037130911981370263();
reg [31 : 0] read_data;
begin
tc_ctr = tc_ctr + 1;
$display("autogenerated_BASIC_M7037130911981370263");
write_word({MESSAGE_PREFIX, 8'h00}, 32'h2692d1cd);
write_word({EXPONENT_PREFIX, 8'h00}, 32'h3b21ef8d);
write_word({GENERAL_PREFIX, ADDR_EXPONENT_LENGTH}, 32'h00000001););
write_word({MODULUS_PREFIX, 8'h00}, 32'h2042c76d);
write_word({GENERAL_PREFIX, ADDR_MODULUS_LENGTH}, 32'h00000001););
dump_memories()
write_word({GENERAL_PREFIX, ADDR_CTRL}, 32'h00000001);
wait_ready();
read_word({RESULT_PREFIX,8'h00});
read_data = tb_read_data;
if (read_data !== 32'h1b753aea))
  begin
    $display("Expected: 0x1b753aea, got 0x%08x", read_data);
  end
end
endtask // autogenerated_BASIC_M7037130911981370263

  //----------------------------------------------------------------
  // main
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : main

      $display("   -= Testbench for modexp started =-");
      $display("    =================================");
      $display("");

      init_sim();
      dump_dut_state();
      reset_dut();
      dump_dut_state();

autogenerated_BASIC_M4962768465676381896();
autogenerated_BASIC_8982867242010371843();
autogenerated_BASIC_5090788032873075449();
autogenerated_BASIC_8448510918869952728();
autogenerated_BASIC_4036237668019554146();
autogenerated_BASIC_M8925041444689012509();
autogenerated_BASIC_M5713608137760059379();
autogenerated_BASIC_6816968587684568101();
autogenerated_BASIC_4168013900853404774();
autogenerated_BASIC_M8394821325674331878();
autogenerated_BASIC_M2919828800172604435();
autogenerated_BASIC_4770912732078070597();
autogenerated_BASIC_3593487472385409519();
autogenerated_BASIC_4981749054780354961();
autogenerated_BASIC_7702189670289360961();
autogenerated_BASIC_M5169634701858105792();
autogenerated_BASIC_6469444563916025786();
autogenerated_BASIC_M2453278165832221565();
autogenerated_BASIC_M1847183855567461116();
autogenerated_BASIC_M7037130911981370263();

      display_test_results();

      $display("");
      $display("*** modexp simulation done. ***");
      $finish;
    end // main
endmodule // tb_modexp

//======================================================================
// EOF tb_modexp.v
//======================================================================