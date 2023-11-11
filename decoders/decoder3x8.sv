`timescale 1ns / 10ps

/* 3:8 Decoder Module

Inputs:
    enable: value to pass to output, set to 1 if unused
    in: port selection to pass enable

Outputs:
    out: all output ports with passed 'enable' at port 'in'
*/
module decoder3x8 (
    out,
    in,
    enable
);
    output logic [7:0] out;
    input logic [2:0] in;
    input logic enable;

    // 2 2:4 decoders
    logic not_in, dec0_en, dec1_en;

    not #0.05 (not_in, in[2]);
    and #0.05 (dec0_en, not_in, enable);
    and #0.05 (dec1_en, in[2], enable);

    decoder2x4 dec0 (
        .out(out[3:0]),
        .in(in[1:0]),
        .enable(dec0_en)
    );
    decoder2x4 dec1 (
        .out(out[7:4]),
        .in(in[1:0]),
        .enable(dec1_en)
    );

endmodule  // decoder3x8


// Testbench
module decoder3x8_tb ();
    logic [7:0] out;
    logic [2:0] in;
    logic enable;
    decoder3x8 dut (.*);

    logic [4:0] i;

    initial begin
        for (i = 5'd0; i < 5'b10000; i++) begin
            {enable, in[2:0]} = i[3:0];
            #10;
        end
        $stop;
    end

endmodule  // decoder3x8_tb
