`timescale 1ns / 10ps

/* 32:1 Multiplexor Module

Parameters:
    SIZE: size (in bits) of data at each port

Inputs:
    in: set of input data for each port
    port: desired port to pass to output

Outputs:
    out: desired data at selected input port
*/
module mux32x1 #(
    parameter SIZE = 1
) (
    out,
    in,
    port
);
    output logic [SIZE-1:0] out;
    input logic [SIZE-1:0] in[32];
    input logic [4:0] port;

    // Flip the 'input' for easier wiring logic
    logic [31:0] mux_in[SIZE];
    dimensionSwap #(
        .INPUT_UNPACKED_SIZE(32),
        .INPUT_PACKED_SIZE  (SIZE)
    ) swap (
        .in (in),
        .out(mux_in)
    );


    // Create SIZE muxes and wire to the output
    genvar i;
    generate
        for (i = 0; i < SIZE; i++) begin : generateMux
            mux32x1_base mux (
                .out (out[i]),
                .in  (mux_in[i]),
                .port(port)
            );
        end
    endgenerate

endmodule  // mux32x1


// 1-bit base module
module mux32x1_base (
    out,
    in,
    port
);
    output logic out;
    input logic [31:0] in;
    input logic [4:0] port;

    // Intermediate mux logic (two 16:1 and one 2:1)
    logic m16_0, m16_1;

    mux16x1_base mux160 (
        .out (m16_0),
        .in  (in[15:0]),
        .port(port[3:0])
    );

    mux16x1_base mux161 (
        .out (m16_1),
        .in  (in[31:16]),
        .port(port[3:0])
    );

    mux2x1_base mux2 (
        .out (out),
        .in  ({m16_1, m16_0}),
        .port(port[4])
    );

endmodule  // mux32x1_base


// Testbench
module mux32x1_tb ();
    logic [4:0] out;
    logic [4:0] in[32];
    logic [4:0] port;

    logic [5:0] j;
    always_comb begin
        for (j = 0; j < 32; j++) begin
            in[j] = j[4:0];
        end
    end

    mux32x1 #(5) dut (.*);

    integer i;

    initial begin
        for (i = 0; i < 32; i++) begin : loop
            port = i;
            #10;
        end
        $stop;
    end

endmodule  // mux32x1_tb

module mux32x1_base_tb ();
    logic out;
    logic [31:0] in;
    logic [4:0] port;

    mux32x1_base dut (.*);

    logic [37:0] combinations_base;

    initial begin
        for (
            combinations_base = 38'd0;
            combinations_base < 38'b1_00000_00000000000000000000000000000000;
            combinations_base++
        ) begin : muxloop
            // check each input combiation with each port combination
            in   = combinations_base[31:0];
            port = combinations_base[36:32];
            #10;
            // make sure the output matches the input at the port
            assert (out == in[port]);
        end
        $stop;
    end
endmodule  // mux32x1_base_tb
