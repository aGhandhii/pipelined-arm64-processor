`timescale 1ns / 10ps

/* 5:32 Decoder Module

Inputs:
    enable: value to pass to output, set to 1 if unused
    in: port selection to pass enable

Outputs:
    out: all output ports with passed 'enable' at port 'in'
*/
module decoder5x32 (
    out,
    in,
    enable
);
    output logic [31:0] out;
    input logic [4:0] in;
    input logic enable;

    // 2 4:16 decoders
    logic not_in, dec0_en, dec1_en;

    not #0.05 (not_in, in[4]);
    and #0.05 (dec0_en, not_in, enable);
    and #0.05 (dec1_en, in[4], enable);

    decoder4x16 dec0 (
        .out(out[15:0]),
        .in(in[3:0]),
        .enable(dec0_en)
    );
    decoder4x16 dec1 (
        .out(out[31:16]),
        .in(in[3:0]),
        .enable(dec1_en)
    );

endmodule  // decoder5x32


// Testbench
module decoder5x32_tb ();
    logic [31:0] out;
    logic [4:0] in;
    logic enable;
    decoder5x32 dut (.*);

    logic [6:0] i;

    initial begin
        for (i = 7'd0; i < 7'b1000000; i++) begin
            {enable, in[4:0]} = i[5:0];
            #10;
        end
        $stop;
    end

endmodule  // decoder5x32_tb
