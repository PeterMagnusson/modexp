//======================================================================
//
// rsa.v
// -----
// Top level wrapper for the RSA public key core. This wrapper 
// provides a simple memory like interface with 32 bit data access.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2014, Secworks Sweden AB
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

module rsa(
           // Clock and reset.
           input wire           clk,
           input wire           reset_n,
           
           // Control.
           input wire           cs,
           input wire           we,
           
           // Data ports.
           input wire  [7 : 0]  address,
           input wire  [31 : 0] write_data,
           output wire [31 : 0] read_data,
           output wire          error
          );

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter ADDR_NAME0       = 8'h00;
  parameter ADDR_NAME1       = 8'h01;
  parameter ADDR_VERSION     = 8'h02;

  parameter ADDR_KEYSIZE     = 8'h20;
  
  parameter CORE_NAME0     = 32'h72736120; // "rsa "
  parameter CORE_NAME1     = 32'h34303936; // "4096"
  parameter CORE_VERSION   = 32'h302e3031; // "0.01"

  // 4096 bits default key size.
  parameter DEFAULT_KEYSIZE = 4'h4;

  
  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [3 : 0] keysize_reg;
  reg [3 : 0] keysize_new;
  reg [3 : 0] keysize_we;

  
  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0] tmp_read_data;
  reg          tmp_error;
  
  
  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data = tmp_read_data;
  assign error     = tmp_error;
  
             
  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  
  
  //----------------------------------------------------------------
  // reg_update
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with synchronous
  // active low reset. All registers have write enable.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin
      if (!reset_n)
        begin
          keysize_reg <= KEYSIZE_4096;
        end
      else
        begin
          if (keysize_we)
            begin
              keysize_reg <= keysize_new;
            end
        end
    end // reg_update
  

  //----------------------------------------------------------------
  // api
  //
  // The interface command decoding logic.
  //----------------------------------------------------------------
  always @*
    begin : api
      keysize_new   = 4'h0;
      keysize_we    = 0;
      tmp_read_data = 32'h00000000;
      tmp_error     = 0;
      
      if (cs)
        begin
          if (we)
            begin
              case (address)
                // Write operations.
                ADDR_KEYSIZE:
                  begin
                    keysize_new = write_data[3 : 0];
                    keysize_we  = 0;
                  end
                
                default:
                  begin
                    tmp_error = 1;
                  end
              endcase // case (addr)
            end // if (write_read)

          else
            begin
              case (address)
                // Read operations.
                ADDR_NAME0:
                  begin
                    tmp_read_data = CORE_NAME0;
                  end
                
                ADDR_NAME1:
                  begin
                    tmp_read_data = CORE_NAME1;
                  end

                ADDR_VERSION:
                  begin
                    tmp_read_data = CORE_VERSION;
                  end
                
                ADDR_KEYSIZE:
                  begin
                    tmp_read_data = {28'h0000000, keysize_reg};
                  end
                
                default:
                  begin
                    tmp_error = 1;
                  end
              endcase // case (addr)
            end
        end
    end // addr_decoder
endmodule // sha1

//======================================================================
// EOF rsa.v
//======================================================================
