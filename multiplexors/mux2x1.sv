`timescale 1ns / 10ps

/* 2:1 Multiplexor Module

Parameters:
    SIZE: size (in bits) of data at each port

Inputs:
    in: set of input data for each port
    port: desired port to pass to output

Outputs:
    out: desired data at selected input port
*/
module mux2x1 #(
    parameter SIZE = 1
) (
    out,
    in,
    port
);
    output logic [SIZE-1:0] out;
    input logic [SIZE-1:0] in[2];
    input logic port;

    // Flip the 'input' for easier wiring logic
    logic [1:0] mux_in[SIZE];
    dimensionSwap #(
        .INPUT_UNPACKED_SIZE(2),
        .INPUT_PACKED_SIZE  (SIZE)
    ) swap (
        .in (in),
        .out(mux_in)
    );

    // Create SIZE muxes and wire to the output
    genvar i;
    generate
        for (i = 0; i < SIZE; i++) begin : generateMux
            mux2x1_base mux (
                .out (out[i]),
                .in  (mux_in[i]),
                .port(port)
            );
        end
    endgenerate

endmodule  // mux2x1


module mux2x1_base (
    out,
    in,
    port
);
    output logic out;
    input logic [1:0] in;
    input logic port;

    // Intermediate logic
    logic not_port, port0, port1, port_out;
    not #0.05 inversePort (not_port, port);
    and #0.05 getPort0 (port0, in[0], not_port);
    and #0.05 getPort1 (port1, in[1], port);
    or #0.05 getPortOut (port_out, port0, port1);

    assign out = port_out;
endmodule  // mux2x1_base


// Testbench
module mux2x1_tb ();
    logic [3:0] out;
    logic port;
    logic [3:0] in[2];

    mux2x1 #(4) dut (.*);

    assign in[0] = 4'b0000;
    assign in[1] = 4'b1111;

    initial begin
        port = 0;
        #10;
        port = 1;
        #10;
        $stop;
    end
endmodule  // mux2x1_tb

module mux2x1_base_tb ();
    logic out;
    logic [1:0] in;
    logic port;

    mux2x1_base dut (.*);

    logic [4:0] combinations_base;

    initial begin
        for (
            combinations_base = 4'b0000;
            combinations_base < 4'b1000;
            combinations_base++
        ) begin : muxloop
            // check each input combiation with each port combination
            in   = combinations_base[1:0];
            port = combinations_base[2];
            #10;
            // make sure the output matches the input at the port
            assert (out == in[port]);

        end

        $stop;
    end
endmodule  // mux2x1_base_tb
