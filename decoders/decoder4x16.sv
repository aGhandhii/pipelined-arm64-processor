`timescale 1ns / 10ps

/* 4:16 Decoder Module

Inputs:
    enable: value to pass to output, set to 1 if unused
    in: port selection to pass enable

Outputs:
    out: all output ports with passed 'enable' at port 'in'
*/
module decoder4x16 (
    out,
    in,
    enable
);
    output logic [15:0] out;
    input logic [3:0] in;
    input logic enable;

    // 2 3:8 decoders
    logic not_in, dec0_en, dec1_en;

    not #0.05 (not_in, in[3]);
    and #0.05 (dec0_en, not_in, enable);
    and #0.05 (dec1_en, in[3], enable);

    decoder3x8 dec0 (
        .out(out[7:0]),
        .in(in[2:0]),
        .enable(dec0_en)
    );
    decoder3x8 dec1 (
        .out(out[15:8]),
        .in(in[2:0]),
        .enable(dec1_en)
    );

endmodule  // decoder4x16


// Testbench
module decoder4x16_tb ();
    logic [15:0] out;
    logic [3:0] in;
    logic enable;
    decoder4x16 dut (.*);

    logic [5:0] i;

    initial begin
        for (i = 6'd0; i < 6'b100000; i++) begin
            {enable, in[3:0]} = i[4:0];
            #10;
        end
        $stop;
    end

endmodule  // decoder4x16_tb
