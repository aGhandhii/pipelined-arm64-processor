`timescale 1ns / 10ps

/* AND 64 bits together

Inputs:
    in: 64-bit input

Outputs:
    out: AND of all bits of in
*/
module and64 (
    in,
    out
);
    // Declare IO
    input logic [63:0] in;
    output logic out;

    // First Step, AND by groups of 4 bits (64/4 = 16)
    logic [15:0] firstStepResults;
    genvar i;
    generate
        for (i = 0; i < 64; i = i + 4) begin : firstStepAnd
            and #0.05 firstStep (
                firstStepResults[i/4], in[i], in[i+1], in[i+2], in[i+3]
            );
        end
    endgenerate  // First Step

    // Second Step, AND by groups of 4 bits (16/4 = 4)
    logic [3:0] secondStepResults;
    generate
        for (i = 0; i < 16; i = i + 4) begin : SecondStepAnd
            and #0.05 secondStep (
                secondStepResults[i/4],
                firstStepResults[i],
                firstStepResults[i+1],
                firstStepResults[i+2],
                firstStepResults[i+3]
            );
        end
    endgenerate  // Second Step

    // Last Step, and the remaining bits
    and #0.05 lastStep (
        out,
        secondStepResults[0],
        secondStepResults[1],
        secondStepResults[2],
        secondStepResults[3]
    );

endmodule  // and64


// Testbench module
module and64_tb ();

    // Replicate IO
    logic [63:0] in;
    logic out;

    // Iterator
    integer i;

    // Instance
    and64 dut (.*);

    // Test
    initial begin
        in = 64'hFFFFFFFFFFFFFFFF;
        #10;
        assert (out == 1'b1);

        for (i = 0; i < 64; i++) begin : testAndBits
            in = 64'hFFFFFFFFFFFFFFFF;
            in[i] = 1'b0;
            #10;
            assert (out == 1'b0);
        end  // TestAndBits

        $stop;  // end simulation
    end  // Test

endmodule  // and64_tb
