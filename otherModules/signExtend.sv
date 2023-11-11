`timescale 1ns / 10ps

/* This module Sign-Extends an array to the user-specified length.

**NOTE**
INPUT_SIZE <= OUTPUT_SIZE

Parameters:
    INPUT_SIZE: size of input array
    OUTPUT_SIZE: size of output array

Inputs:
    in: input array to sign-extend

Outputs:
    out: sign-extended array
*/
module signExtend #(
    parameter INPUT_SIZE,
    OUTPUT_SIZE
) (
    in,
    out
);

    // IO Declaration
    input logic [INPUT_SIZE-1:0] in;
    output logic [OUTPUT_SIZE-1:0] out;

    // Wire the output, extend based on the sign of the input
    assign out = {{(OUTPUT_SIZE - INPUT_SIZE) {in[INPUT_SIZE-1]}}, in};

endmodule  // signExtend


// Testbench Module
module signExtend_tb ();

    // Replicate IO
    logic [3:0] in;
    logic [7:0] out;

    signExtend #(
        .INPUT_SIZE (4),
        .OUTPUT_SIZE(8)
    ) dut (
        .*
    );

    // Simulation
    integer i;
    initial begin
        for (i = 0; i < 16; i++) begin : testSignExtend
            in = i[3:0];
            #10;
            assert (out == {{4{in[3]}}, in});
        end
        $stop();
    end  // Simulation

endmodule  // signExtend_tb
