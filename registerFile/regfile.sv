`timescale 1ns / 10ps

/* This module creates a 64-bit ARM register file

Inputs:
    WriteData: 64-bit data to write to WriteRegister
    ReadRegister1: 5-bit register address to read from
    ReadRegister2: 5-bit register address to read from
    WriteRegister: 5-bit register address to write to
    RegWrite: Write-enable signal for WriteRegister
    clk: system clock

Outputs:
    ReadData1: 64-bit data read from ReadRegister1
    ReadData2: 64-bit data read from ReadRegister2
*/
module regfile (
    ReadData1,
    ReadData2,
    WriteData,
    ReadRegister1,
    ReadRegister2,
    WriteRegister,
    RegWrite,
    clk
);

    // IO Declaration
    output logic [63:0] ReadData1, ReadData2;
    input logic RegWrite, clk;
    input logic [63:0] WriteData;
    input logic [4:0] ReadRegister1, ReadRegister2, WriteRegister;

    // Intermediate logic
    logic [31:0] decoder_out;
    logic [63:0] mux_in_1[32];
    logic [63:0] mux_in_2[32];

    // The 'last' indexed register will always return zero
    assign mux_in_1[31] = 64'd0;
    assign mux_in_2[31] = 64'd0;

    // Register Creation
    // Make 31 registers and link them to the appropriate intermediate logic
    genvar i;
    generate
        for (i = 0; i < 31; i++) begin : generateRegisters
            // Store register output
            logic [63:0] regfile_reg_dout;

            // Wire the register
            registerEnabled #(64) regfile_reg (
                .clk(clk),
                .reset(1'b0),
                .wren(decoder_out[i]),
                .data_in(WriteData),
                .data_out(regfile_reg_dout)
            );

            // Attach to corresponding mux input ports
            assign mux_in_1[i] = regfile_reg_dout;
            assign mux_in_2[i] = regfile_reg_dout;
        end
    endgenerate  // Generate registers

    // Decoder Instance
    decoder5x32 regfile_decoder (
        .enable(RegWrite),
        .in(WriteRegister),
        .out(decoder_out)
    );

    // Mux Instances
    mux32x1 #(
        .SIZE(64)
    ) mux1 (
        .out (ReadData1),
        .in  (mux_in_1),
        .port(ReadRegister1)
    );
    mux32x1 #(
        .SIZE(64)
    ) mux2 (
        .out (ReadData2),
        .in  (mux_in_2),
        .port(ReadRegister2)
    );

endmodule  // regfile


// Testbench
module regfile_tb ();

    parameter ClockDelay = 5000;

    logic [4:0] ReadRegister1, ReadRegister2, WriteRegister;
    logic [63:0] WriteData;
    logic RegWrite, clk;
    logic [63:0] ReadData1, ReadData2;

    integer i;

    regfile dut (
        .ReadData1,
        .ReadData2,
        .WriteData,
        .ReadRegister1,
        .ReadRegister2,
        .WriteRegister,
        .RegWrite,
        .clk
    );

    // Force %t's to print in a nice format.
    initial $timeformat(-9, 2, " ns", 10);

    initial begin  // Set up the clock
        clk <= 0;
        forever #(ClockDelay / 2) clk <= ~clk;
    end

    initial begin
        // Try to write the value 0xA0 into register 31.
        // Register 31 should always be at the value of 0.
        RegWrite <= 5'd0;
        ReadRegister1 <= 5'd31;
        ReadRegister2 <= 5'd0;
        WriteRegister <= 5'd31;
        WriteData <= 64'h00000000000000A0;
        @(posedge clk);

        $display(
            "%t Attempting overwrite of register 31, which should always be 0",
            $time);
        RegWrite <= 1;
        repeat (2) @(posedge clk);

        // Assert that the value read from register 31 is still zero
        assert (ReadData1 == 64'd0);

        // Write a value into each register.
        // ReadRegister2 will point to undefined data during this loop
        $display("%t Writing pattern to all registers.", $time);
        for (i = 0; i < 31; i = i + 1) begin : writeRegisterData
            RegWrite <= 0;
            ReadRegister1 <= i - 1;
            ReadRegister2 <= i;
            WriteRegister <= i;
            WriteData <= i * 64'h0000010204080001;
            @(posedge clk);
            // Write the data to register i
            RegWrite <= 1;
            @(posedge clk);
        end

        // Go back and verify that the registers
        // retained the data.
        $display("%t Checking pattern.", $time);
        for (i = 1; i < 30; i++) begin : checkRegisterData
            // RegWrite is 0 so nothing will be written
            RegWrite <= 0;
            WriteRegister <= 31;
            WriteData <= 64'd0;

            // Get values at two closest registers and update ReadData
            ReadRegister1 <= i - 1;
            ReadRegister2 <= i;
            @(posedge clk);

            // Assert ReadData matches the values written in previous loop
            assert (ReadData1 == (i - 1) * 64'h0000010204080001);
            assert (ReadData2 == i * 64'h0000010204080001);
        end
        $stop;
    end
endmodule  // regfile_tb