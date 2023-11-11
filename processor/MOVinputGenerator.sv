`timescale 1ns / 10ps

/* This module handles creating the Bitmask and Shifted Value for MOV commands.

Inputs:
    value_i: 16-bit input to shift to proper location
    mask_i: 16-bit value to pad remaining output bits
    shamt: 2-bit shift-amount
        -> shamt * 16 = shift amount

Outputs:
    out: 64-bit output
*/
module MOVinputGenerator (
    value_i,
    mask_i,
    shamt,
    out
);

    // IO Declaration
    input logic [15:0] value_i, mask_i;
    input logic [1:0] shamt;
    output logic [63:0] out;

    // Intermediate Mux input logic
    logic [15:0] MOVmux64in[4];
    logic [15:0] MOVmux48in[4];
    logic [15:0] MOVmux32in[4];
    logic [15:0] MOVmux16in[4];

    // Wire mux inputs
    assign MOVmux64in[0] = mask_i;
    assign MOVmux64in[1] = mask_i;
    assign MOVmux64in[2] = mask_i;
    assign MOVmux64in[3] = value_i;

    assign MOVmux48in[0] = mask_i;
    assign MOVmux48in[1] = mask_i;
    assign MOVmux48in[2] = value_i;
    assign MOVmux48in[3] = mask_i;

    assign MOVmux32in[0] = mask_i;
    assign MOVmux32in[1] = value_i;
    assign MOVmux32in[2] = mask_i;
    assign MOVmux32in[3] = mask_i;

    assign MOVmux16in[0] = value_i;
    assign MOVmux16in[1] = mask_i;
    assign MOVmux16in[2] = mask_i;
    assign MOVmux16in[3] = mask_i;

    // Wire muxes to define the output
    mux4x1 #(16) MOVout64 (
        .out (out[63:48]),
        .in  (MOVmux64in),
        .port(shamt)
    );
    mux4x1 #(16) MOVout48 (
        .out (out[47:32]),
        .in  (MOVmux48in),
        .port(shamt)
    );
    mux4x1 #(16) MOVout32 (
        .out (out[31:16]),
        .in  (MOVmux32in),
        .port(shamt)
    );
    mux4x1 #(16) MOVout16 (
        .out (out[15:0]),
        .in  (MOVmux16in),
        .port(shamt)
    );

endmodule  // MOVinputGenerator


// Testbench Module
module MOVinputGenerator_tb ();

    // Replicate IO
    logic [15:0] value_i, mask_i;
    logic [ 1:0] shamt;
    logic [63:0] out;

    // Instance
    MOVinputGenerator dut (.*);

    // Simulation
    initial begin
        value_i = 16'h0000;
        mask_i  = 16'hFFFF;
        shamt   = 2'b00;
        #10;
        value_i = 16'h0000;
        mask_i  = 16'hFFFF;
        shamt   = 2'b01;
        #10;
        value_i = 16'h0000;
        mask_i  = 16'hFFFF;
        shamt   = 2'b10;
        #10;
        value_i = 16'h0000;
        mask_i  = 16'hFFFF;
        shamt   = 2'b11;
        #10;
        value_i = 16'hABCD;
        mask_i  = 16'd0;
        shamt   = 2'b00;
        #10;
        value_i = 16'hABCD;
        mask_i  = 16'd0;
        shamt   = 2'b01;
        #10;
        value_i = 16'hABCD;
        mask_i  = 16'd0;
        shamt   = 2'b10;
        #10;
        value_i = 16'hABCD;
        mask_i  = 16'd0;
        shamt   = 2'b11;
        #10;
        $stop();
    end

endmodule  // MOVinputGenerator_tb
