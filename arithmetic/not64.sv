`timescale 1ns / 10ps

/* Invert 64 bits

Inputs:
    in: 64-bit input

Outputs:
    out: inverse of all bits of in
*/
module not64 (
    in,
    out
);
    // Declare IO
    input logic [63:0] in;
    output logic [63:0] out;

    genvar i;
    generate
        for (i = 0; i < 64; i++) begin : invertInput
            logic inverseBit;
            not #0.05 inverse (inverseBit, in[i]);
            assign out[i] = inverseBit;
        end
    endgenerate  // invert bits

endmodule  // not64


// Testbench module
module not64_tb ();

    // Replicate IO
    logic [63:0] in;
    logic [63:0] out;

    // Iterator
    integer i;

    // Instance
    not64 dut (.*);

    // Test
    initial begin
        for (i = 0; i < 100; i++) begin : testNot64
            in[63:32] = $urandom();
            in[31:0]  = $urandom();
            #(10);
            assert (out == ~in);
        end
        $stop;  // end simulation
    end  // Test

endmodule  // not64_tb
