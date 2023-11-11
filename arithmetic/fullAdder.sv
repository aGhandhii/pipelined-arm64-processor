`timescale 1ns / 10ps

/* Full Adder Module

Inputs:
    Cin: carry-in bit
    A: Input bit 1
    B: Input bit 2

Outputs:
    sum: sum of inputs
    Cout: carry-out bit
*/
module fullAdder (
    sum,
    Cout,
    Cin,
    A,
    B
);

    // Initialize IO
    input logic A, B, Cin;
    output logic sum, Cout;

    // Intermediate logic for sum and Cout
    logic calcSum, AB_xor, AB_and, AB_or, Cin_and, calc_Cout;

    // Calculate sum
    xor #0.05 xorAB (AB_xor, A, B);
    xor #0.05 calculateSum (calcSum, AB_xor, Cin);

    // Calculate Cout
    and #0.05 andAB (AB_and, A, B);
    or #0.05 orAB (AB_or, A, B);
    and #0.05 andCin (Cin_and, Cin, AB_or);
    or #0.05 calculateCout (calc_Cout, AB_and, Cin_and);

    // Set the outputs
    assign sum  = calcSum;
    assign Cout = calc_Cout;

endmodule  // fullAdder



// Testbench
module fullAdder_tb ();

    // Replicate IO
    logic A, B, Cin, Cout, sum;

    // Logic to loop all possible inputs
    logic [3:0] inCombo;

    // Create test instance
    fullAdder dut (.*);

    // The testbench
    initial begin
        for (inCombo = 4'd0; inCombo < 4'b1000; inCombo++) begin : testInputs
            // Set the inputs
            A   = inCombo[2];
            B   = inCombo[1];
            Cin = inCombo[0];
            #10;  // Give the system time to update outputs
            $display("A: %d, B: %d, Cin: %d, Cout: %d, sum: %d", A, B, Cin,
                     Cout, sum);
            if (A == B) begin
                if (A == 1'b1) begin
                    assert (Cout == 1'b1);
                    assert (Cin ? sum == 1'b1 : sum == 1'b0);
                end else begin
                    assert (Cout == 1'b0);
                    assert (sum == Cin);
                end
            end else begin
                assert (Cin ? sum == 1'b0 : sum == 1'b1);
                assert (Cin ? Cout == 1'b1 : Cout == 1'b0);
            end
        end
        $stop;  // end the simulation
    end

endmodule  // fullAdder_tb
