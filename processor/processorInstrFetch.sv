`timescale 1ns / 10ps

/* Processor Instruction Fetch Submodule

Handles setting the new Program Counter value and fetching the next instruction
from Instruction Memory

Inputs:
    clk: system clock
    reset: system reset
    UncondBr: determine if branch is unconditional
    NextPCvalue: determine if PC is branching or incrementing by 4 as normal
    BrAdder_o: PC+branch constant

Outputs:
    instruction: 32-bit instruction obtained from Instruction Memory
    PC_o: 64-bit output value from the PC
*/
module processorInstrFetch (
    clk,
    reset,
    UncondBr,
    NextPCvalue,
    BrAdder_o,
    instruction,
    PC_o
);

    // IO Declaration
    input logic clk, reset, UncondBr, NextPCvalue;
    input logic [63:0] BrAdder_o;
    output logic [31:0] instruction;
    output logic [63:0] PC_o;

    // Intermediate Logic
    logic [63:0] IncrAdder_o, PCincrMux_o;

    // Synthesized multi-bit Mux port inputs
    logic [63:0] PCincrMux_i[2];  // Mux for choosing new PC input
    assign PCincrMux_i[0] = IncrAdder_o;
    assign PCincrMux_i[1] = BrAdder_o;

    // Submodule instances
    register #(64) ProgramCounter (
        .clk(clk),
        .reset(reset),
        .data_in(PCincrMux_o),
        .data_out(PC_o)
    );
    add64 PCincrAdder (
        .result(IncrAdder_o),
        .A(PC_o),
        .B(64'd4)
    );
    instructmem InstructionMemory (
        .address(PC_o),
        .instruction(instruction),
        .clk(clk)
    );
    mux2x1 #(64) PCincrMux (
        .out (PCincrMux_o),
        .in  (PCincrMux_i),
        .port(NextPCvalue)
    );

endmodule  // processorInstrFetch


/* Instruction Fetch Testbench

Note that instrmem will throw errors: this is expected.
*/
module processorInstrFetch_tb ();
    // Delay
    parameter DELAY = 200;

    // IO Declaration
    logic clk, reset, UncondBr, NextPCvalue;
    logic [63:0] BrAdder_o;
    logic [31:0] instruction;
    logic [63:0] PC_o;

    // Setting up a simulated clock
    parameter CLOCK_PERIOD = 5000;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD / 2) clk <= ~clk;  // Forever toggle the clock
    end  // Setting up a simulated clock

    // Instance
    processorInstrFetch dut (.*);

    // Test
    integer i;
    logic [63:0] PC_last;
    initial begin
        // Reset the PC to 0
        reset <= 1;
        repeat (2) @(posedge clk);
        reset <= 0;

        // Allow the PC to increment by 4
        NextPCvalue = 0;
        PC_last = PC_o;
        @(posedge clk);
        #(DELAY);
        assert (PC_o == 64'd4);

        // Check combinational logic for branching
        $display("Testing PC next value Mux");
        for (i = 0; i < 100; i++) begin : testNextPCmux
            PC_last = PC_o;
            BrAdder_o[21:0]  <= $urandom();
            BrAdder_o[42:22] <= $urandom();
            BrAdder_o[63:43] <= $urandom();
            NextPCvalue      <= $urandom();
            @(posedge clk);
            #(DELAY);
            if (NextPCvalue)
                assert (PC_o == BrAdder_o);
                else assert (PC_o == PC_last + 64'd4);
        end

        $stop();
    end  // Test

endmodule  // processorInstrFetch_tb
