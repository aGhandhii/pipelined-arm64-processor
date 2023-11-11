`timescale 1ns / 10ps

/* Pipelined Processor

Combines Instruction Fetch, Instruction Decode, Control Unit, Forwarding Unit,
Execution, Memory Access, and Write Back submodules into a 5-stage
pipelined processor.

Inputs:
    clk: system clock
    reset: system reset
*/
module pipelinedProcessor (
    clk,
    reset
);
    // IO Declaration
    input logic clk, reset;

    // Inverted clock
    logic notClk;
    not #0.05 invertedSystemClock (notClk, clk);

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

    // Forwarding Unit Output Wires
    logic [63:0] Da_forwarded, Db_forwarded, EX_data;
    logic [63:0] ExForwardDataMux_i[2];
    assign ExForwardDataMux_i[0] = EX_ALU_o;
    assign ExForwardDataMux_i[1] = EX_MOVkeepMux_o;

    // Accelerated CBZ logic
    logic [63:0] Z_inverse;
    logic Z_accel;
    not64 invertDb (
        .in (Db_forwarded),
        .out(Z_inverse)
    );
    and64 getAcceleratedZeroFlag (
        .in (Z_inverse),
        .out(Z_accel)
    );

    // Flag Storage Intermediate Wires
    logic V_stored, N_stored, V_stored_next, N_stored_next;

    // Memory Access Output Wires
    logic [4:0] MA_Rd;
    logic [63:0] MA_MOVkeepMux_o_o, MA_ALU_o_o, MA_Dout;

    // Write Back Output Wires
    logic WB_RegWrite_prev;
    logic [4:0] WB_Rd_o;
    logic [63:0] WB_RdWriteDataMux_o;

    ////////////////////////
    // PIPELINE REGISTERS //
    ////////////////////////

    // IF_ID Register
    logic [95:0] IF_ID_i, IF_ID_o;
    logic [63:0] IF_ID_PC_o;
    logic [31:0] IF_ID_instruction;
    assign IF_ID_i           = {IF_PC_o, IF_instruction};
    assign IF_ID_PC_o        = IF_ID_o[95:32];
    assign IF_ID_instruction = IF_ID_o[31:0];

    // ID_EX Register
    logic [364:0] ID_EX_i, ID_EX_o;
    logic [63:0] ID_EX_MOVmask_o, ID_EX_DT_Address, ID_EX_ALU_Imm;
    logic [63:0] ID_EX_Da, ID_EX_Db;
    logic [31:0] ID_EX_instruction;
    logic [ 2:0] ID_EX_ALUop;
    logic [ 1:0] ID_EX_ALUsrc;
    logic ID_EX_StoreFlags, ID_EX_MemWrite, ID_EX_MemRead, ID_EX_MemByteSize;
    logic ID_EX_MOVcmd, ID_EX_RegWrite, ID_EX_MOVkeep, ID_EX_MemToReg;
    assign ID_EX_i = {
        ID_MOVmask_o,
        ID_ALU_Imm,
        ID_DT_Address,
        ID_instruction_o,
        Da_forwarded,
        Db_forwarded,
        ALUsrc,
        ALUop,
        StoreFlags,
        MemWrite,
        MemRead,
        MemByteSize,
        MOVcmd,
        RegWrite,
        MOVkeep,
        MemToReg
    };
    assign ID_EX_MOVmask_o = ID_EX_o[364:301];
    assign ID_EX_ALU_Imm = ID_EX_o[300:237];
    assign ID_EX_DT_Address = ID_EX_o[236:173];
    assign ID_EX_instruction = ID_EX_o[172:141];
    assign ID_EX_Da = ID_EX_o[140:77];
    assign ID_EX_Db = ID_EX_o[76:13];
    assign ID_EX_ALUsrc = ID_EX_o[12:11];
    assign ID_EX_ALUop = ID_EX_o[10:8];
    assign ID_EX_StoreFlags = ID_EX_o[7];
    assign ID_EX_MemWrite = ID_EX_o[6];
    assign ID_EX_MemRead = ID_EX_o[5];
    assign ID_EX_MemByteSize = ID_EX_o[4];
    assign ID_EX_MOVcmd = ID_EX_o[3];
    assign ID_EX_RegWrite = ID_EX_o[2];
    assign ID_EX_MOVkeep = ID_EX_o[1];
    assign ID_EX_MemToReg = ID_EX_o[0];

    // EX_MA Register
    logic [233:0] EX_MA_i, EX_MA_o;
    logic [63:0] EX_MA_MOVkeepMux_o, EX_MA_ALU_o, EX_MA_Db_o;
    logic [31:0] EX_MA_instruction;
    logic [ 3:0] EX_MA_XferSizeMux_o;
    logic EX_MA_MemWrite, EX_MA_MemRead, EX_MA_MemByteSize, EX_MA_MOVcmd;
    logic EX_MA_RegWrite, EX_MA_MemToReg;
    assign EX_MA_i = {
        EX_MOVkeepMux_o,
        EX_ALU_o,
        EX_Db_o,
        EX_XferSizeMux_o,
        EX_instruction_o,
        ID_EX_MemWrite,
        ID_EX_MemRead,
        ID_EX_MemByteSize,
        ID_EX_MOVcmd,
        ID_EX_RegWrite,
        ID_EX_MemToReg
    };
    assign EX_MA_MOVkeepMux_o = EX_MA_o[233:170];
    assign EX_MA_ALU_o = EX_MA_o[169:106];
    assign EX_MA_Db_o = EX_MA_o[105:42];
    assign EX_MA_XferSizeMux_o = EX_MA_o[41:38];
    assign EX_MA_instruction = EX_MA_o[37:6];
    assign EX_MA_MemWrite = EX_MA_o[5];
    assign EX_MA_MemRead = EX_MA_o[4];
    assign EX_MA_MemByteSize = EX_MA_o[3];
    assign EX_MA_MOVcmd = EX_MA_o[2];
    assign EX_MA_RegWrite = EX_MA_o[1];
    assign EX_MA_MemToReg = EX_MA_o[0];

    // WB_Reg Register
    logic [69:0] WB_Reg_i, WB_Reg_o;
    logic [63:0] WB_Reg_RdWriteDataMux_o;
    logic [4:0] WB_Reg_Rd_o;
    logic WB_Reg_RegWrite_prev;
    assign WB_Reg_i = {WB_RegWrite_prev, WB_Rd_o, WB_RdWriteDataMux_o};
    assign WB_Reg_RegWrite_prev = WB_Reg_o[69];
    assign WB_Reg_Rd_o = WB_Reg_o[68:64];
    assign WB_Reg_RdWriteDataMux_o = WB_Reg_o[63:0];


    /////////////////////////////
    // SUBMODULE INSTANTIATION //
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
    register #(96) IF_ID_Register (
        .clk(clk),
        .reset(reset),
        .data_in(IF_ID_i),
        .data_out(IF_ID_o)
    );
    processorInstrDecode InstructionDecode (
        .clk(notClk),
        .instruction_i(IF_ID_instruction),
        .PC_i(IF_ID_PC_o),
        .Rd_prev(WB_Reg_Rd_o),
        .RdWriteDataMux_o(WB_Reg_RdWriteDataMux_o),
        .Reg2Loc(Reg2Loc),
        .RegWrite(WB_Reg_RegWrite_prev),
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
        .instruction(IF_ID_instruction),
        .Z(Z_accel),
        .N_stored(N_stored),
        .V_stored(V_stored)
    );
    processorForwardingUnit ForwardingUnit (
        .ID_instruction(ID_instruction_o),
        .Reg2Loc(Reg2Loc),
        .Da(ID_Da),
        .Db(ID_Db),
        .EX_instruction(EX_instruction_o),
        .EX_data(EX_data),
        .EX_MemWrite(ID_EX_MemWrite),
        .EX_MemRead(ID_EX_MemRead),
        .EX_RegWrite(ID_EX_RegWrite),
        .MA_Rd(MA_Rd),
        .MA_data(WB_RdWriteDataMux_o),
        .MA_MemWrite(EX_MA_MemWrite),
        .MA_MemRead(EX_MA_MemRead),
        .MA_RegWrite(EX_MA_RegWrite),
        .Da_forwarded(Da_forwarded),
        .Db_forwarded(Db_forwarded)
    );
    register #(365) ID_EX_Register (
        .clk(clk),
        .reset(reset),
        .data_in(ID_EX_i),
        .data_out(ID_EX_o)
    );
    processorExecution Execution (
        .instruction_i(ID_EX_instruction),
        .MOVmask_o(ID_EX_MOVmask_o),
        .Da(ID_EX_Da),
        .Db_i(ID_EX_Db),
        .DT_Address(ID_EX_DT_Address),
        .ALU_Imm(ID_EX_ALU_Imm),
        .ALUsrc(ID_EX_ALUsrc),
        .ALUop(ID_EX_ALUop),
        .MemByteSize(ID_EX_MemByteSize),
        .MOVcmd(ID_EX_MOVcmd),
        .MOVkeep(ID_EX_MOVkeep),
        .Z(EX_Z),
        .instruction_o(EX_instruction_o),
        .V(EX_V),
        .N(EX_N),
        .Db_o(EX_Db_o),
        .ALU_o(EX_ALU_o),
        .XferSizeMux_o(EX_XferSizeMux_o),
        .MOVkeepMux_o(EX_MOVkeepMux_o)
    );
    mux2x1 #(64) getExForwardingData (
        .out (EX_data),
        .in  (ExForwardDataMux_i),
        .port(ID_EX_MOVcmd)
    );
    register #(234) EX_MA_Register (
        .clk(clk),
        .reset(reset),
        .data_in(EX_MA_i),
        .data_out(EX_MA_o)
    );
    processorMemAccess MemoryAccess (
        .clk(clk),
        .instruction(EX_MA_instruction),
        .Db(EX_MA_Db_o),
        .ALU_o_i(EX_MA_ALU_o),
        .XferSizeMux_o(EX_MA_XferSizeMux_o),
        .MOVkeepMux_o_i(EX_MA_MOVkeepMux_o),
        .MemWrite(EX_MA_MemWrite),
        .MemRead(EX_MA_MemRead),
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
        .RegWrite(EX_MA_RegWrite),
        .MemByteSize(EX_MA_MemByteSize),
        .MOVcmd(EX_MA_MOVcmd),
        .MemToReg(EX_MA_MemToReg),
        .RegWrite_prev(WB_RegWrite_prev),
        .Rd_o(WB_Rd_o),
        .RdWriteDataMux_o(WB_RdWriteDataMux_o)
    );
    register #(70) WB_Register (
        .clk(clk),
        .reset(reset),
        .data_in(WB_Reg_i),
        .data_out(WB_Reg_o)
    );

    //////////////////
    // FLAG STORAGE //
    //////////////////
    mux2x1_base VstoreMux (
        .out (V_stored_next),
        .in  ({EX_V, V_stored}),
        .port(ID_EX_StoreFlags)
    );
    mux2x1_base NstoreMux (
        .out (N_stored_next),
        .in  ({EX_N, N_stored}),
        .port(ID_EX_StoreFlags)
    );
    D_FF storeOverflowDff (
        .q(V_stored),
        .d(V_stored_next),
        .reset(reset),
        .clk(notClk)
    );
    D_FF storeNegativeDff (
        .q(N_stored),
        .d(N_stored_next),
        .reset(reset),
        .clk(notClk)
    );

endmodule  // pipelinedProcessor


// Testbench
module pipelinedProcessor_tb ();
    // Constants
    parameter DELAY = 10;
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
    pipelinedProcessor dut (.*);

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

endmodule  // pipelinedProcessor_tb
