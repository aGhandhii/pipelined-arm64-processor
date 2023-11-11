`timescale 1ns / 10ps

/* Instruction ROM Module

Supports reads only, but is initialized based upon the file specified.
All accesses are 32-bit. Addresses are byte-addresses, and must be
word-aligned (bottom two words of the address must be 0)
*/

`define BENCHMARK "./benchmarks/toUpper.arm"

// Bytes in memory; must be a power of two
`define INSTRUCT_MEM_SIZE 1024

module instructmem (
    input logic [63:0] address,
    output logic [31:0] instruction,
    input logic clk  // Memory is combinational, but used for error-checking
);

    // Force %t's to print in a nice format.
    initial $timeformat(-9, 2, " ns", 10);

    // Make sure size is a power of two and reasonable.
    initial
        assert((`INSTRUCT_MEM_SIZE & (`INSTRUCT_MEM_SIZE-1)) == 0 && `INSTRUCT_MEM_SIZE > 4);

    // Make sure accesses are reasonable.
    always_ff @(posedge clk) begin
        // address or size could be all X's at startup, so ignore this case
        if (address !== 'x) begin
            assert (address[1:0] == 0);  // Makes sure address is aligned
            assert (address + 3 < `INSTRUCT_MEM_SIZE);  // And in-bounds
        end
    end

    // The data storage itself.
    logic [31:0] mem[`INSTRUCT_MEM_SIZE/4-1:0];

    // Load the program - change the filename to pick a different program.
    initial begin
        $readmemb(`BENCHMARK, mem);
        $display("Running benchmark: ", `BENCHMARK);
    end

    // Handle the reads.
    integer i;
    always_comb begin
        if (address + 3 >= `INSTRUCT_MEM_SIZE) instruction = 'x;
        else instruction = mem[address/4];
    end

endmodule  // instructmem

module instructmem_tb ();

    parameter ClockDelay = 5000;

    logic [63:0] address;
    logic        clk;
    logic [31:0] instruction;

    instructmem dut (
        .address,
        .instruction,
        .clk
    );

    initial begin  // Set up the clock
        clk <= 0;
        forever #(ClockDelay / 2) clk <= ~clk;
    end

    integer i;
    initial begin
        // Read every location, including just past the end of the memory.
        for (i = 0; i <= `INSTRUCT_MEM_SIZE; i = i + 4) begin
            address <= i;
            @(posedge clk);
        end
        $stop;

    end
endmodule  // instructmem_tb
