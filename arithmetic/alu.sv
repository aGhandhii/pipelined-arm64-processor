`timescale 1ns / 10ps

/* Arithmetic Logic Unit (ALU) main module.

This module combines bit slices and allows for 64-bit operations listed in
the bit slice modules. It also generates flags for zero, carryout, overflow,
and negative results.

Inputs:
    A: 64-bit input
    B: 64-bit input
    cntrl: 3-bit operation controller input

Outputs:
    result: 64-bit output
    negative: N flag
    zero: Z flag
    overflow: V flag
    carry_out: C flag
*/
module alu (
    result,
    negative,
    zero,
    overflow,
    carry_out,
    A,
    B,
    cntrl
);

    // IO Declaration
    input logic [63:0] A, B;
    input logic [2:0] cntrl;
    output logic [63:0] result;
    output logic negative, zero, overflow, carry_out;

    // Using intermediate logic to store carry-in and carry-out values
    logic [64:0] carryBits;

    // We need to account for subtraction
    assign carryBits[0] = cntrl[0];

    // Instantiate 64 bit-slices
    genvar i;
    generate
        for (i = 0; i < 64; i++) begin : setALUBits
            ALU_bitSlice slice (
                .Cin(carryBits[i]),
                .A(A[i]),
                .B(B[i]),
                .select(cntrl),
                .out(result[i]),
                .Cout(carryBits[i+1])
            );
        end
    endgenerate  // ALU bit instances

    // Set CarryOut Flag
    assign carry_out = carryBits[64];

    // Set Overflow Flag
    xor #0.05 getOverflow (overflow, carryBits[63], carryBits[64]);

    // Set Negative Flag
    assign negative = result[63];

    // Set Zero Flag
    // We first need to invert the result bits, then we AND them all together
    logic [63:0] not_result;
    not64 invertResult (
        .in (result),
        .out(not_result)
    );
    and64 getZeroFlag (
        .in (not_result),
        .out(zero)
    );

endmodule  // alu


/* Testbench for the main ALU module

ALU Flag guide:
    negative:
        whether the result output is negative if interpreted as 2's comp.
    zero:
        whether the result output was a 64-bit zero.
    overflow:
        on an add or subtract, whether the computation overflowed if the
        inputs are interpreted as 2's comp.
    carry_out:
        on an add or subtract, whether the computation produced a carry-out.

ALU operation controls:
    cntrl: |  Operation:                | Notes:
    ----------------------------------------------------------------------
    000:   |  result = B                | overflow + carry_out unimportant
    010:   |  result = A + B            |
    011:   |  result = A - B            |
    100:   |  result = bitwise A & B    | overflow + carry_out unimportant
    101:   |  result = bitwise A | B    | overflow + carry_out unimportant
    110:   |  result = bitwise A XOR B  | overflow + carry_out unimportant
    ----------------------------------------------------------------------
*/
module alu_tb ();

    parameter DELAY = 100000;

    enum logic [2:0] {
        PASS_B = 3'b000,
        ADD = 3'b010,
        SUB = 3'b011,
        AND = 3'b100,
        OR = 3'b101,
        XOR = 3'b110
    } opcode;

    logic [2:0] cntrl;
    logic [63:0] A, B;
    logic [63:0] result;
    logic negative, zero, overflow, carry_out;

    // alu instance
    alu dut (.*);

    integer i, j;
    logic [63:0] test_val;
    initial begin

        $display("Testing PASS_B");
        opcode = PASS_B;
        cntrl  = opcode;
        for (i = 0; i < 100; i++) begin
            A = $urandom();
            B = $urandom();
            #(DELAY);
            assert (result == B && negative == B[63] && zero == (B == '0));
        end

        $display("Testing ADD");
        opcode = ADD;
        cntrl  = opcode;
        // Add some random numbers
        for (i = 0; i < 20; i++) begin
            A = $urandom();
            B = $urandom();
            #(DELAY);
            assert (result == A + B);
            assert ((A == B) == zero);
            // Allow for negative values
            A[63:33] = $urandom();
            B[63:33] = $urandom();
            #(DELAY);
            assert (result == A + B);
            assert ((A == B) == zero);
        end
        // Explicitly test overflow, zero, carryout, and negative
        A = 64'h8000000000000000;  // most negative value
        B = 64'hFFFFFFFFFFFFFFFF;  // -1, should overflow to max positive
        #(DELAY);
        assert (result == A + B);
        assert (overflow && ~zero && carry_out && ~negative);
        A = 64'hFFFFFFFFFFFFFFFF;  // -1
        B = 64'd1;
        #(DELAY);
        assert (result == A + B);
        assert (~overflow && zero && carry_out && ~negative);
        A = 64'hFFFFFFFFFFFFFFFF;  // -1
        B = 64'd3;
        #(DELAY);
        assert (result == A + B);
        assert (~overflow && ~zero && carry_out && ~negative);
        A = 64'd1;
        B = 64'd0 - 64'd3;
        #(DELAY) assert (result == A + B);
        assert (~overflow && ~zero && ~carry_out && negative);

        $display("Testing SUB");
        opcode = SUB;
        cntrl  = opcode;
        // Add some random numbers
        for (i = 0; i < 20; i++) begin
            A = $urandom();
            B = $urandom();
            #(DELAY);
            assert (result == A - B);
            assert ((A == B) == zero);
            // Allow for negative values
            A[63:33] = $urandom();
            B[63:33] = $urandom();
            #(DELAY);
            assert (result == A - B);
            assert ((A == B) == zero);
        end
        // Explicitly test overflow, zero, carryout, and negative
        A = 64'h8000000000000000;  // most negative value
        B = 64'd1;  // 1. will overflow to max positive
        #(DELAY);
        assert (result == A - B);
        assert (overflow && ~zero && carry_out && ~negative);
        A = 64'hFFFFFFFFFFFFFFFF;  // -1
        B = 64'hFFFFFFFFFFFFFFFF;  // -1
        #(DELAY);
        assert (result == A - B);
        assert (~overflow && zero && carry_out && ~negative);
        A = 64'd1;
        B = 64'd4;
        #(DELAY) assert (result == A - B);
        assert (~overflow && ~zero && ~carry_out && negative);

        $display("Testing AND");
        opcode = AND;
        cntrl  = opcode;
        // Add some random numbers
        for (i = 0; i < 20; i++) begin
            A = $urandom();
            B = $urandom();
            A[63:33] = $urandom();
            B[63:33] = $urandom();
            #(DELAY);
            //$display("A&B\t\t%64b\nResult\t\t%64b", A&B, result);
            assert (A & B ^ result == 0);  // == was not working properly
            assert ((A == B) == zero);
        end

        $display("Testing OR");
        opcode = OR;
        cntrl  = opcode;
        // Add some random numbers
        for (i = 0; i < 20; i++) begin
            A = $urandom();
            B = $urandom();
            A[63:33] = $urandom();
            B[63:33] = $urandom();
            #(DELAY);
            //$display("A|B\t\t%64b\nResult\t\t%64b", A|B, result);
            assert (result == A | B);
            assert ((A == B) == zero);
        end

        $display("Testing XOR");
        opcode = XOR;
        cntrl  = opcode;
        // Add some random numbers
        for (i = 0; i < 20; i++) begin
            A = $urandom();
            B = $urandom();
            A[63:33] = $urandom();
            B[63:33] = $urandom();
            #(DELAY);
            //$display("A^B\t\t%64b\nResult\t\t%64b", A^B, result);
            assert (result == A ^ B);
            assert ((A == B) == zero);
        end

    end
endmodule  // alu_tb
