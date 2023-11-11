`timescale 1ns / 10ps

/* This module creates an Enabled Register of user-specified size.

Parameters:
    SIZE: size (in bits) of register to be created [default 64]

Inputs:
    clk: system clock
    reset: system reset
    wren: write-enable
    data_in: SIZE-bit input

Outputs:
    data_out: SIZE-bit output
*/
module registerEnabled #(
    parameter SIZE = 64
) (
    clk,
    reset,
    wren,
    data_in,
    data_out
);

    // IO Declaration
    input logic clk, reset, wren;
    input logic [SIZE-1:0] data_in;
    output logic [SIZE-1:0] data_out;

    // Generate register DFF's
    genvar i;
    generate
        for (i = 0; i < SIZE; i++) begin : generateDFF
            // Write-enable intermediate logic
            logic not_wren, din_and, dout_and, dff_din;

            // Calculate DFF input data
            not #0.05 invertWriteEnable (not_wren, wren);
            and #0.05 checkActiveWren (din_and, wren, data_in[i]);
            and #0.05 checkInactiveWren (dout_and, not_wren, data_out[i]);
            or #0.05 getDFFData (dff_din, din_and, dout_and);

            // DFF instance
            D_FF register_bit (
                .q(data_out[i]),
                .d(dff_din),
                .reset(reset),
                .clk(clk)
            );
        end
    endgenerate  // Generate register DFF's

endmodule  // registerEnabled


/* Testbench for enabled register.

Create a 5-bit register and test writing with and without write-enable.
Also assert reset works as intended.
*/
module registerEnabled_tb ();
    // Replicate IO
    logic clk, reset, wren;
    logic [4:0] data_in, data_out;

    // Setting up a simulated clock
    parameter CLOCK_PERIOD = 5000;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD / 2) clk <= ~clk;  // Forever toggle the clock
    end  // Setting up a simulated clock

    // Register instance: 5-bit data
    register #(5) dut (.*);

    // Testbench
    initial begin
        // Reset the system
        reset <= 1;
        repeat (2) @(posedge clk);
        reset <= 0;

        // Activate write-enable and place 10101 into the register
        wren <= 1;
        data_in <= 5'b10101;
        repeat (2) @(posedge clk);

        // Deactivate write enable and attempt to write 11111
        wren <= 0;
        data_in <= 5'b11111;
        repeat (2) @(posedge clk);

        // Reset the system
        reset <= 1;
        repeat (2) @(posedge clk);
        reset <= 0;

        $stop;  // End simulation
    end  // Testbench

endmodule  // registerEnabled_tb
