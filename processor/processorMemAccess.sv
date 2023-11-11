`timescale 1ns / 10ps

/* Processor Memory Access Submodule

Inputs:
    clk: system clock
    instruction: 32-bit ARM instruction
    Db: data out from Read Register 2
    ALU_o_i: main ALU data out
    XferSizeMux_o: byte transfer size for data memory
    MOVkeepMux_o_i: MOV value
    MemWrite: wren for data memory
    MemRead: rden for data memory

Outputs:
    MOVkeepMux_o_o: MOV value
    ALU_o_o: main ALU data out
    Dout: data out from Data Memory
    Rd: register to write new Rd data to
*/
module processorMemAccess (
    clk,
    instruction,
    Db,
    ALU_o_i,
    XferSizeMux_o,
    MOVkeepMux_o_i,
    MemWrite,
    MemRead,
    MOVkeepMux_o_o,
    ALU_o_o,
    Dout,
    Rd
);
    // IO Declaration
    input logic clk;
    input logic MemWrite, MemRead;
    input logic [3:0] XferSizeMux_o;
    input logic [31:0] instruction;
    input logic [63:0] Db, ALU_o_i, MOVkeepMux_o_i;
    output logic [4:0] Rd;
    output logic [63:0] MOVkeepMux_o_o, ALU_o_o, Dout;

    // Wire passing IO
    assign ALU_o_o = ALU_o_i;
    assign MOVkeepMux_o_o = MOVkeepMux_o_i;
    assign Rd = instruction[4:0];

    // Submodule Instantiation
    datamem DataMemory (
        .address(ALU_o_i),
        .write_enable(MemWrite),
        .read_enable(MemRead),
        .write_data(Db),
        .clk(clk),
        .xfer_size(XferSizeMux_o),
        .read_data(Dout)
    );

endmodule  // processorMemAccess


// Memory Access Testbech Module
module processorMemAccess_tb ();

    // Delay
    parameter DELAY = 500;

    // IO
    logic clk;
    logic MemWrite, MemRead;
    logic [ 3:0] XferSizeMux_o;
    logic [31:0] instruction;
    logic [63:0] Db, ALU_o_i, MOVkeepMux_o_i;
    logic [4:0] Rd;
    logic [63:0] MOVkeepMux_o_o, MOVadd_o, ALU_o_o, Dout;

    // Setting up a simulated clock
    parameter CLOCK_PERIOD = 5000;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD / 2) clk <= ~clk;  // Forever toggle the clock
    end  // Setting up a simulated clock

    // Instance
    processorMemAccess dut (.*);

    // Test
    integer i;
    logic [63:0] testVal;
    initial begin
        $display("Testing IO Wire connectivity");
        for (i = 0; i < 20; i++) begin : testWires
            ALU_o_i[21:0]          = $urandom();
            ALU_o_i[42:22]         = $urandom();
            ALU_o_i[63:43]         = $urandom();
            MOVkeepMux_o_i[21:0]  = $urandom();
            MOVkeepMux_o_i[42:22] = $urandom();
            MOVkeepMux_o_i[63:43] = $urandom();
            instruction[4:0]       = $urandom();
            #(DELAY);
            assert (ALU_o_o == ALU_o_i);
            assert (MOVkeepMux_o_o == MOVkeepMux_o_i);
            assert (Rd == instruction[4:0]);
        end

        $display("Testing Data Memory");
        /* Approach:
        Write doublewords to known addresses in memory, then read them back
        and assert the expected values.
        Read bytes from known addresses and assert.
        Write bytes to previously written addresses, read the back and assert
        the write.
        */
        ALU_o_i <= 64'd0;  // addr
        Db <= 64'hDEADBEEFCAFEF00D;  // Din
        XferSizeMux_o <= 4'd8;  // doubleword
        MemRead <= 1'b1;
        MemWrite <= 1'b1;
        @(posedge clk);
        #(DELAY);
        assert (Dout == Db);
        MemWrite = 1'b0;
        XferSizeMux_o = 4'd1;  // Single Byte
        for (i = 0; i < 7; i++) begin : testDataMemory
            ALU_o_i = ALU_o_i + 64'd1;
            #(DELAY);
            testVal = 64'hDEADBEEFCAFEF00D >> (8 * (i + 1));
            assert (Dout[7:0] == testVal[7:0]);
        end
        MemWrite <= 1'b1;
        ALU_o_i  <= 64'd1;
        Db = 64'hAB;
        @(posedge clk);
        #(DELAY);
        MemWrite <= 1'b0;
        ALU_o_i <= 64'd0;
        XferSizeMux_o <= 4'd8;
        @(posedge clk);
        #(DELAY);
        assert (Dout[15:8] == 8'hAB);

        $stop();
    end

endmodule  // processorMemAccess_tb
