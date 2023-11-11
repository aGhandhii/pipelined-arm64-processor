`timescale 1ns / 10ps

/* Single Cycle Processor

Combines Instruction Fetch, Instruction Decode, Control Unit, Execution,
Memory Access, and Write Back submodules into a single-cycle processor.

Inputs:
    clk: system clock
    reset: system reset
*/
module singleCycleProcessor (
    clk,
    reset
);
    // IO Declaration
    input logic clk, reset;

    ////////////////////////
    // INTERMEDIATE WIRES //
    ////////////////////////

    // Instruction Fetch Output Wires
    logic [31:0] IF_instruction;
    logic [63:0] IF_PC_o;

    // Instruction Decode Output Wires
    logic [31:0] ID_instruction_o;
    logic [63:0] ID_MOVmask_o, ID_Da, ID_Db, ID_DT_Address, ID_ALU_Imm;
    logic [63:0] ID_BrAdder_o;

    // Control Unit Output Wires
    logic Reg2Loc, MemToReg, MOVcmd, StoreFlags, MOVkeep, MemByteSize;
    logic RegWrite, MemWrite, MemRead, UncondBr, NextPCvalue;
    logic [1:0] ALUsrc;
    logic [2:0] ALUop;

    // Execution Output Wires
    logic EX_Z, EX_V, EX_N;
    logic [ 3:0] EX_XferSizeMux_o;
    logic [31:0] EX_instruction_o;
    logic [63:0] EX_Db_o, EX_ALU_o, EX_MOVkeepMux_o;

    // Flag Storage Intermediate Wires
    logic V_stored, N_stored, V_stored_next, N_stored_next;

    // Memory Access Output Wires
    logic [4:0] MA_Rd;
    logic [63:0] MA_MOVkeepMux_o_o, MA_ALU_o_o, MA_Dout;

    // Write Back Output Wires
    logic WB_RegWrite_prev;
    logic [4:0] WB_Rd_o;
    logic [63:0] WB_RdWriteDataMux_o;

    /////////////////////////////
    // Submodule Instantiation //
    /////////////////////////////

    processorInstrFetch InstructionFetch (
        .clk(clk),
        .reset(reset),
        .UncondBr(UncondBr),
        .NextPCvalue(NextPCvalue),
        .BrAdder_o(ID_BrAdder_o),
        .instruction(IF_instruction),
        .PC_o(IF_PC_o)
    );
    processorInstrDecode InstructionDecode (
        .clk(clk),
        .instruction_i(IF_instruction),
        .PC_i(IF_PC_o),
        .Rd_prev(WB_Rd_o),
        .RdWriteDataMux_o(WB_RdWriteDataMux_o),
        .Reg2Loc(Reg2Loc),
        .RegWrite(WB_RegWrite_prev),
        .UncondBr(UncondBr),
        .BrAdder_o(ID_BrAdder_o),
        .MOVmask_o(ID_MOVmask_o),
        .Da(ID_Da),
        .Db(ID_Db),
        .ALU_Imm(ID_ALU_Imm),
        .DT_Address(ID_DT_Address),
        .instruction_o(ID_instruction_o)
    );
    processorControlUnit ControlUnit (
        .Reg2Loc(Reg2Loc),
        .MemToReg(MemToReg),
        .MOVcmd(MOVcmd),
        .StoreFlags(StoreFlags),
        .MOVkeep(MOVkeep),
        .MemByteSize(MemByteSize),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .UncondBr(UncondBr),
        .NextPCvalue(NextPCvalue),
        .ALUsrc(ALUsrc),
        .ALUop(ALUop),
        .instruction(IF_instruction),
        .Z(EX_Z),
        .N_stored(N_stored),
        .V_stored(V_stored)
    );
    processorExecution Execution (
        .instruction_i(ID_instruction_o),
        .MOVmask_o(ID_MOVmask_o),
        .Da(ID_Da),
        .Db_i(ID_Db),
        .DT_Address(ID_DT_Address),
        .ALU_Imm(ID_ALU_Imm),
        .ALUsrc(ALUsrc),
        .ALUop(ALUop),
        .MemByteSize(MemByteSize),
        .MOVcmd(MOVcmd),
        .MOVkeep(MOVkeep),
        .Z(EX_Z),
        .instruction_o(EX_instruction_o),
        .V(EX_V),
        .N(EX_N),
        .Db_o(EX_Db_o),
        .ALU_o(EX_ALU_o),
        .XferSizeMux_o(EX_XferSizeMux_o),
        .MOVkeepMux_o(EX_MOVkeepMux_o)
    );
    processorMemAccess MemoryAccess (
        .clk(clk),
        .instruction(EX_instruction_o),
        .Db(EX_Db_o),
        .ALU_o_i(EX_ALU_o),
        .XferSizeMux_o(EX_XferSizeMux_o),
        .MOVkeepMux_o_i(EX_MOVkeepMux_o),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .MOVkeepMux_o_o(MA_MOVkeepMux_o_o),
        .ALU_o_o(MA_ALU_o_o),
        .Dout(MA_Dout),
        .Rd(MA_Rd)
    );
    processorWriteBack WriteBack (
        .MOVkeepMux_o(MA_MOVkeepMux_o_o),
        .ALU_o(MA_ALU_o_o),
        .Dout(MA_Dout),
        .Rd_i(MA_Rd),
        .RegWrite(RegWrite),
        .MemByteSize(MemByteSize),
        .MOVcmd(MOVcmd),
        .MemToReg(MemToReg),
        .RegWrite_prev(WB_RegWrite_prev),
        .Rd_o(WB_Rd_o),
        .RdWriteDataMux_o(WB_RdWriteDataMux_o)
    );

    // FLAG STORAGE
    mux2x1_base VstoreMux (
        .out (V_stored_next),
        .in  ({EX_V, V_stored}),
        .port(StoreFlags)
    );
    mux2x1_base NstoreMux (
        .out (N_stored_next),
        .in  ({EX_N, N_stored}),
        .port(StoreFlags)
    );
    D_FF storeOverflowDff (
        .q(V_stored),
        .d(V_stored_next),
        .reset(reset),
        .clk(clk)
    );
    D_FF storeNegativeDff (
        .q(N_stored),
        .d(N_stored_next),
        .reset(reset),
        .clk(clk)
    );

endmodule  // singleCycleProcessor


/* Top-Level Testbench for the Single Cycle Processor.

Load an ARM file in instructmem; choose a cycle count that guarantees the
program will be completed. The CPI for this Processor is 1, so calculating
the value is simply the number of instructions executed in the program.
*/
module singleCycleProcessor_tb ();
    // Constants
    parameter DELAY = 50;
    parameter NUM_CYCLES = 2000;

    // IO
    logic clk, reset;

    // Setting up a simulated clock
    parameter CLOCK_PERIOD = 5000;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD / 2) clk <= ~clk;  // Forever toggle the clock
    end  // Setting up a simulated clock

    // Instance
    singleCycleProcessor dut (.*);

    // Test
    integer i;
    initial begin
        // Reset the system
        reset <= 1;
        @(posedge clk) #(DELAY);
        reset <= 0;

        // Execute the ARM program
        for (i = 0; i < NUM_CYCLES; i++) begin : testSingleCycleProcessor
            @(posedge clk);
            #(DELAY);
        end

        $stop();
    end  // Test

endmodule  // singleCycleProcessor_tb
