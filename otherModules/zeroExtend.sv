`timescale 1ns / 10ps

/* This module Zero-Extends an array to the user-specified length.

**NOTE**
INPUT_SIZE <= OUTPUT_SIZE

Parameters:
    INPUT_SIZE: size of input array
    OUTPUT_SIZE: size of output array

Inputs:
    in: input array to zero-extend

Outputs:
    out: zero-extended array
*/
module zeroExtend #(
    parameter INPUT_SIZE,
    OUTPUT_SIZE
) (
    in,
    out
);

    // IO Declaration
    input logic [INPUT_SIZE-1:0] in;
    output logic [OUTPUT_SIZE-1:0] out;

    // Wire the output, zero extend remaining elements
    assign out = {{(OUTPUT_SIZE - INPUT_SIZE) {1'b0}}, in};

endmodule  // zeroExtend


// Testbench Module
module zeroExtend_tb ();

    // Replicate IO
    logic [3:0] in;
    logic [7:0] out;

    zeroExtend #(
        .INPUT_SIZE (4),
        .OUTPUT_SIZE(8)
    ) dut (
        .*
    );

    // Simulation
    integer i;
    initial begin
        for (i = 0; i < 16; i++) begin : testZeroExtend
            in = i[3:0];
            #10;
            assert (out == {{4{1'b0}}, in});
        end
        $stop();
    end  // Simulation

endmodule  // zeroExtend_tb
