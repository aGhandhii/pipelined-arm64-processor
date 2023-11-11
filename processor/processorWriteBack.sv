`timescale 1ns / 10ps

/* Processor Write Back Submodule

Inputs:
    MOVkeepMux_o: MOV value
    ALU_o: main ALU data out
    Dout: data out from Data Memory
    Rd_i: input destination register for register write data
    RegWrite: wren for register file
    MemByteSize: number of bytes to write/read to/from memory
        -> 0 for LDUR/STUR
        -> 1 for LDURB/STURB
    MOVcmd: determine if instruction is a MOV command
    MemToReg: determine if memory read data or ALU output is written to Rd
        -> 0 for ALU output
        -> 1 for memory read data

Outputs:
    RegWrite_prev: wren for command just executed
    Rd_o: output destination register for register write data
    RdWriteDataMux_o: Future write data for Rd
*/
module processorWriteBack (
    MOVkeepMux_o,
    ALU_o,
    Dout,
    Rd_i,
    RegWrite,
    MemByteSize,
    MOVcmd,
    MemToReg,
    RegWrite_prev,
    Rd_o,
    RdWriteDataMux_o
);
    // IO Declaration
    input logic MemByteSize, MOVcmd, MemToReg, RegWrite;
    input logic [4:0] Rd_i;
    input logic [63:0] MOVkeepMux_o, ALU_o, Dout;
    output logic RegWrite_prev;
    output logic [4:0] Rd_o;
    output logic [63:0] RdWriteDataMux_o;

    // Wire passing IO
    assign RegWrite_prev = RegWrite;
    assign Rd_o = Rd_i;

    // Intermediate Logic
    logic [63:0] MemOutMux_o;

    // Synthesized multi-bit Mux port inputs
    logic [63:0] MemOutMux_i[2];
    assign MemOutMux_i[0] = Dout;
    assign MemOutMux_i[1] = {56'd0, Dout[7:0]};
    logic [63:0] RdWriteDataMux_i[4];
    assign RdWriteDataMux_i[0] = ALU_o;
    assign RdWriteDataMux_i[1] = MemOutMux_o;
    assign RdWriteDataMux_i[2] = MOVkeepMux_o;
    assign RdWriteDataMux_i[3] = MOVkeepMux_o;

    // Submodule Instantiation
    mux2x1 #(64) MemOutMux (
        .out (MemOutMux_o),
        .in  (MemOutMux_i),
        .port(MemByteSize)
    );
    mux4x1 #(64) RdWriteDataMux (
        .out (RdWriteDataMux_o),
        .in  (RdWriteDataMux_i),
        .port({MOVcmd, MemToReg})
    );

endmodule  // processorWriteBack


// Write Back Testbench
module processorWriteBack_tb ();

    // Delay
    parameter DELAY = 100;

    // IO
    logic MemByteSize, MOVcmd, MemToReg, RegWrite;
    logic [4:0] Rd_i;
    logic [63:0] MOVkeepMux_o, ALU_o, Dout;
    logic RegWrite_prev;
    logic [4:0] Rd_o;
    logic [63:0] RdWriteDataMux_o;

    // Instance
    processorWriteBack dut (.*);

    // Test
    integer i;
    logic [63:0] testVal;
    initial begin
        $display("Testing IO Wire connectivity");
        for (i = 0; i < 20; i++) begin : testWires
            RegWrite = $urandom();
            Rd_i = $urandom();
            #(DELAY);
            assert (RegWrite_prev == RegWrite);
            assert (Rd_o == Rd_i);
        end

        $display("Testing Data Memory Output Mux");
        MOVcmd = 1'b0;
        MemToReg = 1'b1;
        for (i = 0; i < 20; i++) begin : testDataMemoryOutMux
            Dout[21:0]  = $urandom();
            Dout[42:22] = $urandom();
            Dout[63:43] = $urandom();
            MemByteSize = $urandom();
            #(DELAY);
            testVal = {56'd0, Dout[7:0]};
            if (MemByteSize) begin
                assert (RdWriteDataMux_o == testVal);
            end else begin
                assert (RdWriteDataMux_o == Dout);
            end
        end

        $display("Testing Rd Write Data Mux");
        MemByteSize = 0;
        for (i = 0; i < 20; i++) begin : testRdWriteDataMux
            Dout[21:0] = $urandom();
            Dout[42:22] = $urandom();
            Dout[63:43] = $urandom();
            ALU_o[21:0] = $urandom();
            ALU_o[42:22] = $urandom();
            ALU_o[63:43] = $urandom();
            MOVkeepMux_o[21:0] = $urandom();
            MOVkeepMux_o[42:22] = $urandom();
            MOVkeepMux_o[63:43] = $urandom();
            MOVcmd = $urandom();
            MemToReg = $urandom();
            #(DELAY);
            if (MOVcmd) begin
                assert (RdWriteDataMux_o == MOVkeepMux_o);
            end else begin
                if (MemToReg)
                    assert (RdWriteDataMux_o == Dout);
                    else assert (RdWriteDataMux_o == ALU_o);
            end
        end

        $stop();
    end  // Test

endmodule  // processorWriteBack_tb
