`timescale 1ns / 10ps

/* Data Memory Module

Supports reads and writes

Data initialized to "X"

*Note: Memory is Little-Endian*
The values of double words range from:
    Mem[0]*256^0 + Mem[1]*256 + Mem[2]*256^2 + ... + Mem[7]*256^7

Size is the number of bytes to transfer, and memory supports any power of 2
access size up to double-word. However, all accesses must be aligned. The
address of any access of size S must be a multiple of S.
*/

// Bytes in memory; must be a power of two
`define DATA_MEM_SIZE 1024

module datamem (
    input  logic [63:0] address,
    input  logic        write_enable,
    input  logic        read_enable,
    input  logic [63:0] write_data,
    input  logic        clk,
    input  logic [ 3:0] xfer_size,
    output logic [63:0] read_data
);

    // Force %t's to print in a nice format.
    initial $timeformat(-9, 2, " ns", 10);

    // Make sure size is a power of two and reasonable.
    initial
        assert(
            (`DATA_MEM_SIZE & (`DATA_MEM_SIZE-1)) == 0 && `DATA_MEM_SIZE > 8
        );

    // Make sure accesses are reasonable.
    always_ff @(posedge clk) begin
        // address or size could be all X's at startup, so ignore this case.
        if (address !== 'x && (write_enable || read_enable)) begin
            // Makes sure address is aligned
            assert ((address & (xfer_size - 1)) == 0);
            // Make sure size is a power of 2
            assert ((xfer_size & (xfer_size - 1)) == 0);
            // Make sure in bounds
            assert (address + xfer_size <= `DATA_MEM_SIZE);
        end
    end

    // The data storage itself.
    logic [7:0] mem[`DATA_MEM_SIZE-1:0];

    // Compute a properly aligned address
    logic [63:0] aligned_address;
    always_comb begin
        case (xfer_size)
            1: aligned_address = address;
            2: aligned_address = {address[63:1], 1'b0};
            4: aligned_address = {address[63:2], 2'b00};
            8: aligned_address = {address[63:3], 3'b000};
            default:
            aligned_address = {
                address[63:3], 3'b000
            };  // Bad addresses forced to double-word aligned.
        endcase
    end

    // Handle the reads.
    integer i;
    always_comb begin
        read_data = 'x;
        if (read_enable == 1) begin
            for (i = 0; i < xfer_size; i++) begin
                // 8*i+7 -: 8 means "start at 8*i+7, for 8 bits total"
                read_data[8*i+7-:8] = mem[aligned_address+i];
            end
        end
    end

    // Handle the writes.
    integer j;
    always_ff @(posedge clk) begin
        if (write_enable) begin
            for (j = 0; j < xfer_size; j++) begin
                mem[aligned_address+j] <= write_data[8*j+7-:8];
            end
        end
    end
endmodule  // datamem

module datamem_tb ();

    parameter ClockDelay = 5000;

    logic [63:0] address;
    logic        write_enable;
    logic        read_enable;
    logic [63:0] write_data;
    logic        clk;
    logic [ 3:0] xfer_size;
    logic [63:0] read_data;

    datamem dut (
        .address,
        .write_enable,
        .write_data,
        .clk,
        .xfer_size,
        .read_data
    );

    initial begin  // Set up the clock
        clk <= 0;
        forever #(ClockDelay / 2) clk <= ~clk;
    end

    // Keep copy of what we've done so far.
    logic [7:0] test_data[`DATA_MEM_SIZE-1:0];

    integer i, j, t;
    logic [63:0] rand_addr, rand_data;
    logic [3:0] rand_size;
    logic       rand_we;

    initial begin
        address <= '0;
        read_enable <= '0;
        write_enable <= '0;
        write_data <= 'x;
        xfer_size <= 4'd8;
        @(posedge clk);
        for (i = 0; i < 1024 * `DATA_MEM_SIZE; i++) begin
            // Set up transfer in rand_*, then send to outputs.
            rand_we   = $random();
            rand_data = $random();
            rand_size = $random() & 2'b11;
            rand_size = 4'b0001 << rand_size;  // 1, 2, 4, or 8
            rand_addr = $random() & (`DATA_MEM_SIZE - 1);
            rand_addr = (rand_addr / rand_size) * rand_size;  // Block aligned

            write_enable <= rand_we;
            read_enable  <= ~rand_we;
            xfer_size    <= rand_size;
            address      <= rand_addr;
            write_data   <= rand_data;

            @(posedge clk);  // Do the xfer.

            if (rand_we) begin  // Track Writes
                for (j = 0; j < rand_size; j++)
                test_data[rand_addr+j] = rand_data[8*j+7-:8];
            end else begin  // Verify reads
                for (j = 0; j < rand_size; j++) begin
                    // === will return true when comparing X's
                    assert (test_data[rand_addr+j] === read_data[8*j+7-:8]);
                end
            end
        end
        $stop;
    end
endmodule  // datamem_tb
