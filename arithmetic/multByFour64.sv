`timescale 1ns / 10ps

/* This module Multiplies a 64-bit input by 4.

Inputs:
    in: 64-bit input to multiply by 4

Outputs:
    out: input x 4 (64-bits)
*/
module multByFour64 (
    in,
    out
);

    // IO Declaration
    input logic [63:0] in;
    output logic [63:0] out;

    // Multiply by 4 by left-shifting the input by 2
    assign out = {in[61:0], 2'b00};

endmodule  // multByFour64


// Testbench Module
module multByFour64_tb ();

    // Replicate IO
    logic [63:0] in;
    logic [63:0] out;

    // Module instance
    multByFour64 dut (.*);

    // Simulation
    integer i;
    initial begin
        for (i = 0; i < 100; i++) begin : testMultBy4
            in[21:0]  = $urandom();
            in[42:22] = $urandom();
            in[63:43] = $urandom();
            #10;
            assert (out == in * 4);
        end
        $stop();
    end  // Simulation

endmodule  // multByFour64_tb
