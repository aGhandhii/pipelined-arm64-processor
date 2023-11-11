`timescale 1ns / 10ps

/* ALU individual-bit Module

Inputs:
    Cin: carry-in bit
    A: Input bit 1
    B: Input bit 2
    select: operation selector

Outputs:
    out: output bit
    Cout: carry-out bit
*/
module ALU_bitSlice (
    Cin,
    A,
    B,
    select,
    out,
    Cout
);

    // IO Declaration
    input logic A, B, Cin;
    input logic [2:0] select;
    output logic out, Cout;

    // Logic for operation selector mux
    logic op_000, op_010, op_011, op_100, op_101, op_110;

    // Handle direct input
    assign op_000 = B;

    // Handle bitwise inputs
    and #0.05 andIn (op_100, A, B);
    or #0.05 orIn (op_101, A, B);
    xor #0.05 xorIn (op_110, A, B);

    // Account for addition/subtraction
    // Before passing inputs into the full adder, we might need to invert B
    logic notB, fullAdderB;
    not #0.05 invertB (notB, B);
    mux2x1_base selectB (
        .out (fullAdderB),
        .in  ({notB, B}),
        .port(select[0])
    );

    // Using our determined inputs, wire the full adder and capture the output
    logic fullAdderOut;
    fullAdder addSub (
        .sum(fullAdderOut),
        .Cout(Cout),
        .Cin(Cin),
        .A(A),
        .B(fullAdderB)
    );

    // Wire the full adder to the appropriate mux ports
    assign op_010 = fullAdderOut;
    assign op_011 = fullAdderOut;

    // We now have all the mux inputs
    logic [7:0] operationMuxIn;

    // Wire the inputs: set arbitrary values for unused ports
    assign operationMuxIn = {
        1'b0, op_110, op_101, op_100, op_011, op_010, 1'b0, op_000
    };

    // Create the operation mux and set the output
    mux8x1_base operationMux (
        .out (out),
        .in  (operationMuxIn),
        .port(select)
    );

endmodule  // ALU_bitSlice


// Testbench
// The main goal of the testbench is to check all operations with all input
// combinations. We will assume that unused ports will go unused.
module ALU_bitSlice_tb ();

    // Replicate IO
    logic A, B, Cin, out, Cout;
    logic [2:0] select;

    // Create instance
    ALU_bitSlice dut (.*);

    // Loop variables
    integer i;
    logic   addOut;

    // Main test
    initial begin
        $display("Testing Passthrough");
        select = 3'b000;
        B = 1'b0;
        #10;
        assert (out == B);
        B = 1'b1;
        #10;
        assert (out == B);

        $display("Testing Addition and Subraction");
        for (i = 0; i < 8; i++) begin : testAddSub
            // Add Portion
            A = i[0];
            B = i[1];
            Cin = i[2];
            select = 3'b010;
            #10;

            // Make sure output and carry bit are as expected
            if (A == B) begin
                if (A == 1'b1) begin
                    assert (Cout == 1'b1);
                    assert (Cin ? out == 1'b1 : out == 1'b0);
                end else begin
                    assert (Cout == 1'b0);
                    assert (out == Cin);
                end
            end else begin
                assert (Cin ? out == 1'b0 : out == 1'b1);
                assert (Cin ? Cout == 1'b1 : Cout == 1'b0);
            end  // Check output and carryout bits

            // Switch to subtraction with inverted B, same output as ADD
            addOut = out;
            B = ~i[1];  // feed inverted value to counteract polarity mux
            select = 3'b011;
            #10;
            assert (out == addOut);  // Add and Sub produce same output
        end  // Test ADD SUB

        $display("Testing AND");
        select = 3'b100;
        for (i = 0; i < 8; i++) begin : testAnd
            A   = i[0];
            B   = i[1];
            Cin = i[2];
            #10;
            addOut = A & B;
            assert (out == addOut);
        end  // Test AND

        $display("Testing OR");
        select = 3'b101;
        for (i = 0; i < 8; i++) begin : testOr
            A   = i[0];
            B   = i[1];
            Cin = i[2];
            #10;
            assert (out == A | B);
        end  // Test OR

        $display("Testing XOR");
        select = 3'b110;
        for (i = 0; i < 8; i++) begin : testXor
            A   = i[0];
            B   = i[1];
            Cin = i[2];
            #10;
            assert (out == A ^ B);
        end  // Test XOR

        $stop;  // End simulation

    end  // Main test

endmodule  // ALU_bitSlice_tb
