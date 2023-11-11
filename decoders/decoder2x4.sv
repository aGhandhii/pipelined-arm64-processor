`timescale 1ns / 10ps

/* 2:4 Decoder Module

Inputs:
    enable: value to pass to output, set to 1 if unused
    in: port selection to pass enable

Outputs:
    out: all output ports with passed 'enable' at port 'in'
*/
module decoder2x4 (
    out,
    in,
    enable
);
    output logic [3:0] out;
    input logic [1:0] in;
    input logic enable;

    // 2 1:2 decoders
    logic not_in, dec0_en, dec1_en;

    not #0.05 (not_in, in[1]);
    and #0.05 (dec0_en, not_in, enable);
    and #0.05 (dec1_en, in[1], enable);

    decoder1x2 dec0 (
        .out(out[1:0]),
        .in(in[0]),
        .enable(dec0_en)
    );
    decoder1x2 dec1 (
        .out(out[3:2]),
        .in(in[0]),
        .enable(dec1_en)
    );

endmodule  // decoder2x4


// Testbench
module decoder2x4_tb ();
    logic [3:0] out;
    logic [1:0] in;
    logic enable;
    decoder2x4 dut (.*);

    logic [3:0] i;

    initial begin
        for (i = 4'b0; i < 4'b1000; i++) begin
            {enable, in[1:0]} = i[2:0];
            #10;
        end
        $stop;
    end

endmodule  // decoder2x4_tb
