`timescale 1ns / 10ps

/* Processor Control Unit Submodule.

Determines control signals based on instruction.
Unlike other modules, RTL logic is permitted here.

Inputs:
    instruction: 32-bit ARM instruction
    Z: zero flag
    N_stored: Stored Negative flag
    V_stored: Stored Overflow flag

Outputs:
    Reg2Loc: decide input for ReadRegisterB to the RegFile
        -> 0 for Rd
        -> 1 for Rm
    MemToReg: determine if memory read data or ALU output is written to Rd
        -> 0 for ALU output
        -> 1 for memory read data
    MOVcmd: determine if instruction is a MOV command
    StoreFlags: determines if current flags are placed in flag DFFs
    MOVkeep: determines if MOV command is MOVK or MOVZ
        -> 0 for MOVZ
        -> 1 for MOVK
    MemByteSize: number of bytes to write/read to/from memory
        -> 0 for LDUR/STUR
        -> 1 for LDURB/STURB
    RegWrite: wren for register file
    MemWrite: wren for data memory
    MemRead: rden for data memory
    UncondBr: determine if branch is unconditional
    NextPCvalue: determine if PC is branching or incrementing by 4
    ALUsrc: 2-bit input, determines 'B' input to main ALU module
        -> 00 to pass DataB from RegFile
        -> 01 to pass Daddr9 (memory operation)
        -> 10 to pass ALU_Imm12 (immediate input)
    ALUop: operation for the main ALU to perform
        000 -> PASS_B
        010 -> ADD
        011 -> SUB
        100 -> AND
        101 -> OR
        110 -> XOR
*/
module processorControlUnit (
    Reg2Loc,
    MemToReg,
    MOVcmd,
    StoreFlags,
    MOVkeep,
    MemByteSize,
    RegWrite,
    MemWrite,
    MemRead,
    UncondBr,
    NextPCvalue,
    ALUsrc,
    ALUop,
    instruction,
    Z,
    N_stored,
    V_stored
);

    // Paramaterize ALU opcodes
    parameter logic [2:0] PASS_B = 3'b000;
    parameter logic [2:0] ADD = 3'b010;
    parameter logic [2:0] SUB = 3'b011;
    parameter logic [2:0] AND = 3'b100;

    // IO Declaration
    output logic Reg2Loc, MemToReg, MOVcmd, StoreFlags, MOVkeep, MemByteSize;
    output logic RegWrite, MemWrite, MemRead, UncondBr, NextPCvalue;
    output logic [1:0] ALUsrc;
    output logic [2:0] ALUop;
    input logic Z, N_stored, V_stored;
    input logic [31:0] instruction;

    // Extra Internal Logic for determining NextPCvalue
    logic BrTaken, CondBrType;
    assign CondBrType = instruction[30];

    // Control Logic
    always_comb begin

        // Logic for all instructions except for NextPCvalue
        casex (instruction[31:21])
            11'b1001000100x: begin  // ADDI
                Reg2Loc = 1'bx;
                MemToReg = 1'b0;
                MOVcmd = 1'b0;
                StoreFlags = 1'b0;
                MOVkeep = 1'bx;
                MemByteSize = 1'bx;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead = 1'b0;
                UncondBr = 1'bx;
                BrTaken = 1'b0;
                ALUsrc = 2'b10;
                ALUop = ADD;
            end
            11'b10101011000: begin  // ADDS
                Reg2Loc = 1'b1;
                MemToReg = 1'b0;
                MOVcmd = 1'b0;
                StoreFlags = 1'b1;
                MOVkeep = 1'b0;
                MemByteSize = 1'bx;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead = 1'b0;
                UncondBr = 1'bx;
                BrTaken = 1'b0;
                ALUsrc = 2'b00;
                ALUop = ADD;
            end
            11'b11101011000: begin  // SUBS
                Reg2Loc = 1'b1;
                MemToReg = 1'b0;
                MOVcmd = 1'b0;
                StoreFlags = 1'b1;
                MOVkeep = 1'bx;
                MemByteSize = 1'bx;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead = 1'b0;
                UncondBr = 1'bx;
                BrTaken = 1'b0;
                ALUsrc = 2'b00;
                ALUop = SUB;
            end
            11'b000101xxxxx: begin  // B
                Reg2Loc = 1'bx;
                MemToReg = 1'bx;
                MOVcmd = 1'bx;
                StoreFlags = 1'b0;
                MOVkeep = 1'bx;
                MemByteSize = 1'bx;
                RegWrite = 1'b0;
                MemWrite = 1'b0;
                MemRead = 1'b0;
                UncondBr = 1'b1;
                BrTaken = 1'b1;
                ALUsrc = 2'bxx;
                ALUop = 3'bxxx;
            end
            11'b01010100xxx: begin  // B.LT
                // Check for expected branch condition
                if (instruction[4:0] == 5'b01011) begin
                    Reg2Loc = 1'bx;
                    MemToReg = 1'bx;
                    MOVcmd = 1'bx;
                    StoreFlags = 1'b0;
                    MOVkeep = 1'bx;
                    MemByteSize = 1'bx;
                    RegWrite = 1'b0;
                    MemWrite = 1'b0;
                    MemRead = 1'b0;
                    UncondBr = 1'b0;
                    BrTaken = 1'b1;
                    ALUsrc = 2'bxx;
                    ALUop = 3'bxxx;
                end else begin
                    // If not found, match the default case
                    Reg2Loc = 1'bx;
                    MemToReg = 1'bx;
                    MOVcmd = 1'bx;
                    StoreFlags = 1'b0;
                    MOVkeep = 1'bx;
                    MemByteSize = 1'bx;
                    RegWrite = 1'b0;
                    MemWrite = 1'b0;
                    MemRead = 1'b0;
                    UncondBr = 1'bx;
                    BrTaken = 1'b0;
                    ALUsrc = 2'bxx;
                    ALUop = 3'bxxx;
                end
            end
            11'b10110100xxx: begin  // CBZ
                Reg2Loc = 1'b0;
                MemToReg = 1'bx;
                MOVcmd = 1'bx;
                StoreFlags = 1'b0;
                MOVkeep = 1'bx;
                MemByteSize = 1'bx;
                RegWrite = 1'b0;
                MemWrite = 1'b0;
                MemRead = 1'b0;
                UncondBr = 1'b0;
                BrTaken = 1'b1;
                ALUsrc = 2'b00;
                ALUop = PASS_B;
            end
            11'b11111000010: begin  // LDUR
                Reg2Loc = 1'bx;
                MemToReg = 1'b1;
                MOVcmd = 1'b0;
                StoreFlags = 1'b0;
                MOVkeep = 1'bx;
                MemByteSize = 1'b0;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead = 1'b1;
                UncondBr = 1'bx;
                BrTaken = 1'b0;
                ALUsrc = 2'b01;
                ALUop = ADD;
            end
            11'b00111000010: begin  // LDURB
                Reg2Loc = 1'bx;
                MemToReg = 1'b1;
                MOVcmd = 1'b0;
                StoreFlags = 1'b0;
                MOVkeep = 1'bx;
                MemByteSize = 1'b1;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead = 1'b1;
                UncondBr = 1'bx;
                BrTaken = 1'b0;
                ALUsrc = 2'b01;
                ALUop = ADD;
            end
            11'b11111000000: begin  // STUR
                Reg2Loc = 1'b0;
                MemToReg = 1'bx;
                MOVcmd = 1'b0;
                StoreFlags = 1'b0;
                MOVkeep = 1'bx;
                MemByteSize = 1'b0;
                RegWrite = 1'b0;
                MemWrite = 1'b1;
                MemRead = 1'b0;
                UncondBr = 1'bx;
                BrTaken = 1'b0;
                ALUsrc = 2'b01;
                ALUop = ADD;
            end
            11'b00111000000: begin  // STURB
                Reg2Loc = 1'b0;
                MemToReg = 1'bx;
                MOVcmd = 1'b0;
                StoreFlags = 1'b0;
                MOVkeep = 1'bx;
                MemByteSize = 1'b1;
                RegWrite = 1'b0;
                MemWrite = 1'b1;
                MemRead = 1'b0;
                UncondBr = 1'bx;
                BrTaken = 1'b0;
                ALUsrc = 2'b01;
                ALUop = ADD;
            end
            11'b111100101xx: begin  // MOVK
                Reg2Loc = 1'b0;
                MemToReg = 1'b0;
                MOVcmd = 1'b1;
                StoreFlags = 1'b0;
                MOVkeep = 1'b1;
                MemByteSize = 1'bx;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead = 1'b0;
                UncondBr = 1'bx;
                BrTaken = 1'b0;
                ALUsrc = 2'b00;
                ALUop = AND;
            end
            11'b110100101xx: begin  // MOVZ
                Reg2Loc = 1'bx;
                MemToReg = 1'b0;
                MOVcmd = 1'b1;
                StoreFlags = 1'b0;
                MOVkeep = 1'b0;
                MemByteSize = 1'bx;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead = 1'b0;
                UncondBr = 1'bx;
                BrTaken = 1'b0;
                ALUsrc = 2'bxx;
                ALUop = 3'bxxx;
            end
            default: begin  // Unknown Instruction, progress without writes
                Reg2Loc = 1'bx;
                MemToReg = 1'bx;
                MOVcmd = 1'bx;
                StoreFlags = 1'b0;
                MOVkeep = 1'bx;
                MemByteSize = 1'bx;
                RegWrite = 1'b0;
                MemWrite = 1'b0;
                MemRead = 1'b0;
                UncondBr = 1'bx;
                BrTaken = 1'b0;
                ALUsrc = 2'bxx;
                ALUop = 3'bxxx;
            end
        endcase  // All control signals except for NextPCvalue

        // Control Unit Logic for NextPCvalue
        // Handle t=0 case with undefined logic
        if ((UncondBr === 1'bx) | (BrTaken === 1'bx)) NextPCvalue = 1'b0;
        else if (UncondBr) NextPCvalue = BrTaken;
        // THIS CREATES AN ISSUE WHERE BRANCHES ARE NOT TAKEN WHEN THEY SHOULD
        // BE.
        else if (CondBrType === 1'bx) NextPCvalue = 1'b0;
        else begin
            // Check 'B.LT' and 'CBZ'
            if (CondBrType & BrTaken)
                if ((V_stored === 1'bx) | (N_stored === 1'bx))
                    NextPCvalue = 1'b0;
                else NextPCvalue = (N_stored ^ V_stored) & BrTaken;
            else if (~CondBrType & BrTaken)
                if (Z === 1'bx) NextPCvalue = 1'b0;
                else NextPCvalue = Z & BrTaken;
            else NextPCvalue = 1'b0;
        end

    end  // Control Logic

endmodule  // processorControlUnit


// Testbench for the Control Unit
module processorControlUnit_tb ();

    // Variable delay
    parameter DELAY = 100;

    // Test variable
    integer i;

    // ALU Operation shortcuts
    parameter logic [2:0] PASS_B = 3'b000;
    parameter logic [2:0] ADD = 3'b010;
    parameter logic [2:0] SUB = 3'b011;
    parameter logic [2:0] AND = 3'b100;

    // IO Replication
    logic Reg2Loc, MemToReg, MOVcmd, StoreFlags, MOVkeep, MemByteSize;
    logic RegWrite, MemWrite, MemRead, UncondBr, NextPCvalue;
    logic [1:0] ALUsrc;
    logic [2:0] ALUop;
    logic Z, N_stored, V_stored;
    logic [31:0] instruction;

    // Module instance
    processorControlUnit dut (.*);

    // Testbench
    initial begin
        // General approach:
        // Send in an instruction and assert that the associated control
        // signals for the instruction are set as expected
        $display("Testing ADDI");
        instruction = 32'b1001000100_000000000001_11111_00000;
        #(DELAY);
        assert (~MemToReg && ~MOVcmd && ~StoreFlags && RegWrite);
        assert (~MemWrite && ~MemRead);
        assert ((ALUsrc == 2'b10) && (ALUop == ADD));

        $display("Testing ADDS");
        instruction = 32'b10101011000_00100_000000_00011_00101;
        #(DELAY);
        assert (Reg2Loc && ~MemToReg && ~MOVcmd && StoreFlags);
        assert (RegWrite && ~MemWrite && ~MemRead);
        assert ((ALUsrc == 2'b00) && (ALUop == ADD));

        $display("Testing SUBS");
        instruction = 32'b11101011000_00001_000000_00011_00100;
        #(DELAY);
        assert (Reg2Loc && ~MemToReg && ~MOVcmd && StoreFlags);
        assert (RegWrite && ~MemWrite && ~MemRead);
        assert ((ALUsrc == 2'b00) && (ALUop == SUB));

        $display("Testing B");
        instruction = 32'b000101_00000000000000000000000000;
        #(DELAY);
        assert (~StoreFlags && ~RegWrite && ~MemWrite);
        assert (~MemRead && UncondBr);

        // Run multiple times with different N and V values
        $display("Testing B.LT");
        instruction = 32'b01010100_0000000000000000100_01011;
        #(DELAY);
        assert (~StoreFlags && ~RegWrite && ~MemWrite);
        assert (~MemRead && ~UncondBr);

        // Run multiple times with different Z values
        $display("Testing CBZ");
        instruction = 32'b10110100_0000000000000000100_00000;
        #(DELAY);
        assert (~Reg2Loc && ~StoreFlags && ~RegWrite && ~MemWrite);
        assert (~MemRead && ~UncondBr);
        assert ((ALUsrc == 2'b00) && (ALUop == PASS_B));

        $display("Testing LDUR");
        instruction = 32'b11111000010_000000101_00_00100_00111;
        #(DELAY);
        assert (MemToReg && ~MOVcmd && ~StoreFlags && ~MemByteSize);
        assert (RegWrite && ~MemWrite && MemRead);
        assert ((ALUsrc == 2'b01) && (ALUop == ADD));

        $display("Testing LDURB");
        instruction = 32'b00111000010_000001001_00_11111_01001;
        #(DELAY);
        assert (MemToReg && ~MOVcmd && ~StoreFlags && MemByteSize);
        assert (RegWrite && ~MemWrite && MemRead);
        assert ((ALUsrc == 2'b01) && (ALUop == ADD));

        $display("Testing STUR");
        instruction = 32'b11111000000_000000000_00_11111_00000;
        #(DELAY);
        assert (~Reg2Loc && ~MOVcmd && ~StoreFlags && ~MemByteSize);
        assert (~RegWrite && MemWrite && ~MemRead);
        assert ((ALUsrc == 2'b01) && (ALUop == ADD));

        $display("Testing STURB");
        instruction = 32'b00111000000_000000110_00_11111_00000;
        #(DELAY);
        assert (~Reg2Loc && ~MOVcmd && ~StoreFlags);
        assert (MemByteSize && ~RegWrite && MemWrite && ~MemRead);
        assert ((ALUsrc == 2'b01) && (ALUop == ADD));

        $display("Testing MOVK");
        instruction = 32'b111100101_10_1101111010101101_00001;
        #(DELAY);
        assert (~Reg2Loc && MOVcmd && ~StoreFlags && MOVkeep);
        assert (RegWrite && ~MemWrite && ~MemRead && ~MemToReg);
        assert ((ALUsrc == 2'b00) && (ALUop == AND));

        $display("Testing MOVZ");
        instruction = 32'b110100101_00_1101111010101101_00000;
        #(DELAY);
        assert (MOVcmd && ~StoreFlags && ~MOVkeep && RegWrite);
        assert (~MemWrite && ~MemRead && ~MemToReg);

        $display("Testing Next PC incrementation Logic");
        // Run a 'B' command to set both UncondBr and BrTaken to 1
        instruction = 32'b000101_00000000000000000000000000;
        #(DELAY);
        assert (NextPCvalue == 1'b1);
        // Run a B.LT command to set UncondBr to 0
        // This also sets CondBrType to 1
        instruction = 32'b01010100_0000000000000000100_01011;
        #(DELAY);
        assert (NextPCvalue == 1'b0);
        // Slowly define inputs, make sure that NextPCvalue is not asserted
        // Until all inputs are defined
        Z = 1'b0;
        #(DELAY);
        assert (NextPCvalue == 1'b0);
        V_stored = 1'b0;
        #(DELAY);
        assert (NextPCvalue == 1'b0);
        N_stored = 1'b1;
        #(DELAY);
        assert (NextPCvalue == N_stored ^ V_stored);
        for (i = 0; i < 20; i++) begin : testBLT
            V_stored = $urandom();
            N_stored = $urandom();
            #(DELAY);
            assert (NextPCvalue == N_stored ^ V_stored);
        end
        // Run a CBZ command to set CondBrType to 0
        instruction = 32'b10110100_0000000000000000100_00000;
        #(DELAY);
        for (i = 0; i < 20; i++) begin : testCBZ
            Z = $urandom();
            #(DELAY);
            assert (NextPCvalue == Z);
        end

        $stop();  // End the simulation
    end  // Testbench

endmodule  // processorControlUnit_tb
