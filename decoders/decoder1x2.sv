`timescale 1ns / 10ps

/* 1:2 Decoder Module

Inputs:
    enable: value to pass to output, set to 1 if unused
    in: port selection to pass enable

Outputs:
    out: all output ports with passed 'enable' at port 'in'
*/
module decoder1x2 (
    out,
    in,
    enable
);
    output logic [1:0] out;
    input logic in;
    input logic enable;

    // Intermediate logic
    logic not_in, port_0, port_1;
    not #0.05 (not_in, in);
    and #0.05 (port_0, not_in, enable);
    and #0.05 (port_1, in, enable);

    assign out[0] = port_0;
    assign out[1] = port_1;

endmodule  // decoder1x2


// Testbench
module decoder1x2_tb ();
    logic [1:0] out;
    logic in;
    logic enable;
    decoder1x2 dut (.*);

    initial begin
        enable = 1;
        in = 0;
        #10;
        in = 1;
        #10;
        enable = 0;
        in = 0;
        #10;
        in = 1;
        #10;
        $stop;
    end

endmodule  // decoder1x2_tb
