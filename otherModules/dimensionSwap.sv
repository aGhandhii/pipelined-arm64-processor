`timescale 1ns / 10ps

/* This module swaps the dimensions of an arbitrarily sized array.

Parameters:
    INPUT_UNPACKED_SIZE: size of input array's unpacked dimension
    INPUT_PACKED_SIZE: size of input array's packed dimension

Inputs:
    in: input array to be flipped

Outputs:
    out: flipped array
*/
module dimensionSwap #(
    parameter INPUT_UNPACKED_SIZE,
    INPUT_PACKED_SIZE
) (
    in,
    out
);

    // IO declaration
    input logic [INPUT_PACKED_SIZE-1:0] in[INPUT_UNPACKED_SIZE];
    output logic [INPUT_UNPACKED_SIZE-1:0] out[INPUT_PACKED_SIZE];

    // Dimension flip code
    genvar i;
    genvar j;
    generate
        for (i = 0; i < INPUT_PACKED_SIZE; i++) begin : dimensionSwapOuter
            // Make flipped arrays and wire to output
            logic [INPUT_UNPACKED_SIZE-1:0] flip;
            assign out[i] = flip;
            for (j = 0; j < INPUT_UNPACKED_SIZE; j++) begin : dimensionSwapInner
                logic [INPUT_PACKED_SIZE-1:0] flipVal;
                assign flipVal = in[j];
                assign flip[j] = flipVal[i];
            end
        end
    endgenerate  // Dimension flip code

endmodule  // dimensionSwap


// Testbench
module dimensionSwap_tb ();

    logic [4:0] in [2];
    logic [1:0] out[5];

    always_comb begin
        in[0] = 5'b10000;
        in[1] = 5'b11111;
    end

    dimensionSwap #(
        .INPUT_UNPACKED_SIZE(2),
        .INPUT_PACKED_SIZE  (5)
    ) dut (
        .*
    );

    // Expect out to be:
    // [10]
    // [10]
    // [10]
    // [10]
    // [11]
    initial begin
        #50;
        $stop;
    end

endmodule  // dimensionSwap_tb
