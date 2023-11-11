`timescale 1ns / 10ps

/* 5-Bit Equality Tester Module

This module compares two 5-bit values for equality.

Inputs:
    A: 5-bit input
    B: 5-bit input

Outputs:
    result: (A == B)
*/
module isEqual5 (
    result,
    A,
    B
);

    // IO Declaration
    input logic [4:0] A, B;
    output logic result;

    // Intermediate Logic
    logic res0, res1, res2, res3, res4;
    logic andOut0, andOut1;

    // XNOR all bit pairs for bitwise equality
    xnor #0.05 checkBit0 (res0, A[0], B[0]);
    xnor #0.05 checkBit1 (res1, A[1], B[1]);
    xnor #0.05 checkBit2 (res2, A[2], B[2]);
    xnor #0.05 checkBit3 (res3, A[3], B[3]);
    xnor #0.05 checkBit4 (res4, A[4], B[4]);

    // AND the results together to determine the result
    and #0.05 andRes0 (andOut0, res0, res1, res2);
    and #0.05 andRes1 (andOut1, res3, res4);
    and #0.05 getResult (result, andOut0, andOut1);

endmodule  // isEqual5


// Testbench module
module isEqual5_tb ();

    // Replicate IO
    logic [4:0] A, B;
    logic result;

    // Instance
    isEqual5 dut (.*);

    // Test
    integer i;
    initial begin

        $display("Checking random combinations");
        for (i = 0; i < 100; i++) begin : testRandom
            A = $urandom();
            B = $urandom();
            #10;
            assert (result == (A == B));
        end

        $display("Checking guranteed equality cases");
        for (i = 0; i < 50; i++) begin : testGuranteed
            A = $urandom();
            B = A;
            #10;
            assert (result == 1'b1);
        end

        $stop();
    end  // Test

endmodule  // isEqual5_tb
