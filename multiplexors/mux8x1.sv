`timescale 1ns / 10ps

/* 8:1 Multiplexor Module

Parameters:
    SIZE: size (in bits) of data at each port

Inputs:
    in: set of input data for each port
    port: desired port to pass to output

Outputs:
    out: desired data at selected input port
*/
module mux8x1 #(
    parameter SIZE = 1
) (
    out,
    in,
    port
);
    output logic [SIZE-1:0] out;
    input logic [SIZE-1:0] in[8];
    input logic [2:0] port;

    // Flip the 'input' for easier wiring logic
    logic [7:0] mux_in[SIZE];
    dimensionSwap #(
        .INPUT_UNPACKED_SIZE(8),
        .INPUT_PACKED_SIZE  (SIZE)
    ) swap (
        .in (in),
        .out(mux_in)
    );

    // Create SIZE muxes and wire to the output
    genvar i;
    generate
        for (i = 0; i < SIZE; i++) begin : generateMux
            mux8x1_base mux (
                .out (out[i]),
                .in  (mux_in[i]),
                .port(port)
            );
        end
    endgenerate

endmodule  // mux8x1


// 1-bit base module
module mux8x1_base (
    out,
    in,
    port
);
    output logic out;
    input logic [7:0] in;
    input logic [2:0] port;

    // Intermediate mux logic (two 4:1 and one 2:1)
    logic m4_0, m4_1;

    mux4x1_base mux40 (
        .out (m4_0),
        .in  (in[3:0]),
        .port(port[1:0])
    );

    mux4x1_base mux41 (
        .out (m4_1),
        .in  (in[7:4]),
        .port(port[1:0])
    );

    mux2x1_base mux2 (
        .out (out),
        .in  ({m4_1, m4_0}),
        .port(port[2])
    );

endmodule  // mux8x1_base


// Testbench
module mux8x1_tb ();
    logic [2:0] out;
    logic [2:0] in[8];
    logic [2:0] port;

    always_comb begin
        in[0] = 3'b000;
        in[1] = 3'b001;
        in[2] = 3'b010;
        in[3] = 3'b011;
        in[4] = 3'b100;
        in[5] = 3'b101;
        in[6] = 3'b110;
        in[7] = 3'b111;
    end

    mux8x1 #(3) dut (.*);

    initial begin
        port = 3'd0;
        #10;
        port = 3'd1;
        #10;
        port = 3'd2;
        #10;
        port = 3'd3;
        #10;
        port = 3'd4;
        #10;
        port = 3'd5;
        #10;
        port = 3'd6;
        #10;
        port = 3'd7;
        #10;
        $stop;
    end

endmodule  // mux8x1_tb

module mux8x1_base_tb ();
    logic out;
    logic [7:0] in;
    logic [2:0] port;

    mux8x1_base dut (.*);

    logic [11:0] combinations_base;

    initial begin
        for (
            combinations_base = 12'd0;
            combinations_base < 12'b1_000_00000000;
            combinations_base++
        ) begin : muxloop
            // check each input combiation with each port combination
            in   = combinations_base[7:0];
            port = combinations_base[9:8];
            #10;
            // make sure the output matches the input at the port
            assert (out == in[port]);
        end
        $stop;
    end
endmodule  // mux8x1_base_tb
