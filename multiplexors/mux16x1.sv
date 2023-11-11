`timescale 1ns / 10ps

/* 16:1 Multiplexor Module

Parameters:
    SIZE: size (in bits) of data at each port

Inputs:
    in: set of input data for each port
    port: desired port to pass to output

Outputs:
    out: desired data at selected input port
*/
module mux16x1 #(
    parameter SIZE = 1
) (
    out,
    in,
    port
);
    output logic [SIZE-1:0] out;
    input logic [SIZE-1:0] in[16];
    input logic [3:0] port;

    // Flip the 'input' for easier wiring logic
    logic [15:0] mux_in[SIZE];
    dimensionSwap #(
        .INPUT_UNPACKED_SIZE(16),
        .INPUT_PACKED_SIZE  (SIZE)
    ) swap (
        .in (in),
        .out(mux_in)
    );

    // Create SIZE muxes and wire to the output
    genvar i;
    generate
        for (i = 0; i < SIZE; i++) begin : generateMux
            mux16x1_base mux (
                .out (out[i]),
                .in  (mux_in[i]),
                .port(port)
            );
        end
    endgenerate

endmodule  // mux16x1


// 1-bit base module
module mux16x1_base (
    out,
    in,
    port
);
    output logic out;
    input logic [15:0] in;
    input logic [3:0] port;

    // Intermediate mux logic (two 8:1 and one 2:1)
    logic m8_0, m8_1;

    mux8x1_base mux80 (
        .out (m8_0),
        .in  (in[7:0]),
        .port(port[2:0])
    );

    mux8x1_base mux81 (
        .out (m8_1),
        .in  (in[15:8]),
        .port(port[2:0])
    );

    mux2x1_base mux2 (
        .out (out),
        .in  ({m8_1, m8_0}),
        .port(port[3])
    );

endmodule  // mux16x1_base


// Testbench
module mux16x1_tb ();
    logic [3:0] out;
    logic [3:0] in[16];
    logic [3:0] port;

    logic [4:0] j;
    always_comb begin
        for (j = 0; j < 16; j++) begin
            in[j] = j[3:0];
        end
    end

    mux16x1 #(4) dut (.*);

    integer i;

    initial begin
        for (i = 0; i < 16; i++) begin : loop
            port = i;
            #10;
        end
        $stop;
    end

endmodule  // mux16x1_tb

module mux16x1_base_tb ();
    logic out;
    logic [15:0] in;
    logic [3:0] port;

    mux16x1_base dut (.*);

    logic [20:0] combinations_base;

    initial begin
        for (
            combinations_base = 21'd0;
            combinations_base < 21'b1_0000_0000000000000000;
            combinations_base++
        ) begin : muxloop
            // check each input combiation with each port combination
            in   = combinations_base[15:0];
            port = combinations_base[19:16];
            #10;
            // make sure the output matches the input at the port
            assert (out == in[port]);
        end
        $stop;
    end
endmodule  // mux16x1_base_tb
