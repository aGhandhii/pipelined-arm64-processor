`timescale 1ns / 10ps

/* Simplified 64-bit Adder Module

This module adds two 64-bit values and returns the result as a 64-bit value.
Carry-in and Carry-out are ignored, only intermediate carries are calculated.

Inputs:
    A: 64-bit input
    B: 64-bit input

Outputs:
    result: 64-bit output
*/
module add64 (
    result,
    A,
    B
);

    // IO Declaration
    input logic [63:0] A, B;
    output logic [63:0] result;

    // Intermediate carry bits
    logic [64:0] carryBits;
    assign carryBits[0] = 1'b0;  // No subtraction

    // Generate fullAdders to handle addition
    genvar i;
    generate
        for (i = 0; i < 64; i++) begin : generateFullAdders
            fullAdder addBit (
                .A(A[i]),
                .B(B[i]),
                .sum(result[i]),
                .Cin(carryBits[i]),
                .Cout(carryBits[i+1])
            );
        end
    endgenerate  // Generate fullAdders

endmodule  // add64


// Testbench
module add64_tb ();
    // IO
    logic [63:0] A, B, result;

    // Instance
    add64 dut (.*);

    // Test
    integer i;
    initial begin
        for (i = 0; i < 100; i++) begin : testAdd64
            A[21:0]  = $urandom();
            A[42:22] = $urandom();
            A[63:43] = $urandom();
            B[21:0]  = $urandom();
            B[42:22] = $urandom();
            B[63:43] = $urandom();
            #10;
            assert (result == A + B);
        end
        $stop();
    end  // Test

endmodule
