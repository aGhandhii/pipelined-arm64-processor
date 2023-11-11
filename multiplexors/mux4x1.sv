`timescale 1ns / 10ps

/* 4:1 Multiplexor Module

Parameters:
    SIZE: size (in bits) of data at each port

Inputs:
    in: set of input data for each port
    port: desired port to pass to output

Outputs:
    out: desired data at selected input port
*/
module mux4x1 #(
    parameter SIZE = 1
) (
    out,
    in,
    port
);
    output logic [SIZE-1:0] out;
    input logic [SIZE-1:0] in[4];
    input logic [1:0] port;

    // Flip the 'input' for easier wiring logic
    logic [3:0] mux_in[SIZE];
    dimensionSwap #(
        .INPUT_UNPACKED_SIZE(4),
        .INPUT_PACKED_SIZE  (SIZE)
    ) swap (
        .in (in),
        .out(mux_in)
    );

    // Create SIZE muxes and wire to the output
    genvar i;
    generate
        for (i = 0; i < SIZE; i++) begin : generateMux
            mux4x1_base mux (
                .out (out[i]),
                .in  (mux_in[i]),
                .port(port)
            );
        end
    endgenerate

endmodule  // mux4x1


// 1-bit base mux
module mux4x1_base (
    out,
    in,
    port
);
    output logic out;
    input logic [3:0] in;
    input logic [1:0] port;

    // Intermediate 2x1 mux logic
    logic m0_out, m1_out;

    mux2x1_base mux0 (
        .out (m0_out),
        .in  (in[1:0]),
        .port(port[0])
    );

    mux2x1_base mux1 (
        .out (m1_out),
        .in  (in[3:2]),
        .port(port[0])
    );

    mux2x1_base mux (
        .out (out),
        .in  ({m1_out, m0_out}),
        .port(port[1])
    );

endmodule  // mux4x1_base


// Testbench
module mux4x1_tb ();
    logic [2:0] out;
    logic [2:0] in[4];
    logic [1:0] port;

    assign in[0] = 3'b000;
    assign in[1] = 3'b001;
    assign in[2] = 3'b100;
    assign in[3] = 3'b111;

    mux4x1 #(3) dut (.*);

    initial begin
        port = 2'b00;
        #10;
        port = 2'b01;
        #10;
        port = 2'b10;
        #10;
        port = 2'b11;
        #10;
        $stop;
    end

endmodule  // mux4x1_tb

module mux4x1_base_tb ();
    logic out;
    logic [3:0] in;
    logic [1:0] port;

    mux4x1_base dut (.*);

    logic [6:0] combinations_base;

    initial begin
        for (
            combinations_base = 7'd0;
            combinations_base < 7'b1_00_0000;
            combinations_base++
        ) begin : muxloop
            // check each input combiation with each port combination
            in   = combinations_base[3:0];
            port = combinations_base[5:4];
            #10;
            // make sure the output matches the input at the port
            assert (out == in[port]);
        end
        $stop;
    end
endmodule  // mux4x1_base_tb
