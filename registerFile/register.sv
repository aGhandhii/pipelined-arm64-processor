`timescale 1ns / 10ps

/* This module creates a Register of user-specified size.

Parameters:
    SIZE: size (in bits) of register to be created [default 64]

Inputs:
    clk: system clock
    reset: system reset
    data_in: SIZE-bit input

Outputs:
    data_out: SIZE-bit output
*/
module register #(
    parameter SIZE = 64
) (
    clk,
    reset,
    data_in,
    data_out
);

    // IO Declaration
    input logic clk, reset;
    input logic [SIZE-1:0] data_in;
    output logic [SIZE-1:0] data_out;

    // Generate DFF's
    genvar i;
    generate
        for (i = 0; i < SIZE; i++) begin : generateDFF
            D_FF PC_bit (
                .q(data_out[i]),
                .d(data_in[i]),
                .reset(reset),
                .clk(clk)
            );
        end
    endgenerate  // Generate DFF's

endmodule  // register


// Register Testbench
module register_tb ();

    // IO
    logic [63:0] data_in, data_out;
    logic reset, clk;

    // Setting up a simulated clock
    parameter CLOCK_PERIOD = 5000;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD / 2) clk <= ~clk;  // Forever toggle the clock
    end  // Setting up a simulated clock

    // Instance
    register #(64) dut (.*);

    // Testbench
    integer i;
    initial begin
        for (i = 0; i < 100; i++) begin : testReg
            // Reset the system
            reset <= 1;
            repeat (2) @(posedge clk);
            // Write random data to the register
            reset <= 0;
            data_in[21:0] <= $urandom();
            data_in[42:22] <= $urandom();
            data_in[63:43] <= $urandom();
            repeat (2) @(posedge clk);
            assert (data_out == data_in);
        end
        $stop();
    end

endmodule  // register_tb
