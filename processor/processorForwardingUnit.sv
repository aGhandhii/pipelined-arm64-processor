`timescale 1ns / 10ps

/* Processor Forwarding Unit Submodule

Inputs:
    ID_instruction: instruction from current Instruction Decode stage
    Reg2Loc: determine input to data read 2 on the Register File
    Da: Register File port 0 output
    Db: Register File port 1 output
    EX_instruction: instruction from current Execution stage
    EX_data: Output data from current Execution stage
    EX_MemWrite: MemWrite control signal from current Execution stage
    EX_MemRead: MemRead control signal from current Execution stage
    EX_RegWrite: RegWrite control signal from current Execution stage
    MA_Rd: Register Destination for current Memory Access stage
    MA_data: Output data (Memory, MOV, or ALU) from current Memory Access stage
    MA_MemWrite: MemWrite control signal from current Memory Access stage
    MA_MemRead: MemRead control signal from current Memory Access stage
    MA_RegWrite: RegWrite control signal from current Memory Access stage

Outputs:
    Da_forwarded: calculated forwarded value for next Execution stage
    Db_forwarded: calculated forwarded value for next Execution stage
*/
module processorForwardingUnit (
    ID_instruction,
    Reg2Loc,
    Da,
    Db,
    EX_instruction,
    EX_data,
    EX_MemWrite,
    EX_MemRead,
    EX_RegWrite,
    MA_Rd,
    MA_data,
    MA_MemWrite,
    MA_MemRead,
    MA_RegWrite,
    Da_forwarded,
    Db_forwarded
);
    // IO Declaration
    input logic [31:0] ID_instruction, EX_instruction;
    input logic [63:0] Da, Db, EX_data, MA_data;
    input logic [4:0] MA_Rd;
    input logic EX_MemWrite, EX_MemRead, EX_RegWrite, Reg2Loc;
    input logic MA_MemWrite, MA_MemRead, MA_RegWrite;
    output logic [63:0] Da_forwarded, Db_forwarded;

    // Instruction Constants
    logic [4:0] ID_Rn, ID_Rm, ID_Rd, EX_Rd;
    assign ID_Rn = ID_instruction[9:5];
    assign ID_Rm = ID_instruction[20:16];
    assign ID_Rd = ID_instruction[4:0];
    assign EX_Rd = EX_instruction[4:0];

    ////////////////////////////
    // INTERNAL CONTROL LOGIC //
    //vvvvvvvvvvvvvvvvvvvvvvvv//

    // Intermediate Execution signals
    logic NotEX_MemWrite, NotEX_MemRead, NotEX_RegWrite;
    not #0.05 invertEXMW (NotEX_MemWrite, EX_MemWrite);
    not #0.05 invertEXMR (NotEX_MemRead, EX_MemRead);
    not #0.05 invertEXRW (NotEX_RegWrite, EX_RegWrite);

    logic EX_isBranch, EX_isStore, EX_isLoad, EX_isX31;
    and #0.05 getExBr (
        EX_isBranch, NotEX_MemWrite, NotEX_MemRead, NotEX_RegWrite
    );
    and #0.05 getExSt (EX_isStore, EX_MemWrite, NotEX_MemRead, NotEX_RegWrite);
    and #0.05 getExLo (EX_isLoad, NotEX_MemWrite, EX_MemRead, EX_RegWrite);
    isEqual5 getEx31 (
        .result(EX_isX31),
        .A(EX_Rd),
        .B(5'd31)
    );

    // Intermediate Memory Access signals
    logic NotMA_MemWrite, NotMA_MemRead, NotMA_RegWrite;
    not #0.05 invertMAMW (NotMA_MemWrite, MA_MemWrite);
    not #0.05 invertMAMR (NotMA_MemRead, MA_MemRead);
    not #0.05 invertMARW (NotMA_RegWrite, MA_RegWrite);

    logic MA_isBranch, MA_isStore, MA_isX31;
    and #0.05 getMaBr (
        MA_isBranch, NotMA_MemWrite, NotMA_MemRead, NotMA_RegWrite
    );
    and #0.05 getMaSt (MA_isStore, MA_MemWrite, NotMA_MemRead, NotMA_RegWrite);
    isEqual5 getMa31 (
        .result(MA_isX31),
        .A(MA_Rd),
        .B(5'd31)
    );

    // Obtaining Validity signals
    logic EX_isValid, MA_isValid;
    nor #0.05 getEXvalidity (
        EX_isValid, EX_isBranch, EX_isStore, EX_isLoad, EX_isX31
    );
    nor #0.05 getMAvalidity (MA_isValid, MA_isBranch, MA_isStore, MA_isX31);

    //^^^^^^^^^^^^^^^^^^^^^^^^//
    // INTERNAL CONTROL LOGIC //
    ////////////////////////////


    // Synthesized multi-bit Mux port inputs
    logic [63:0] DaForwardMux_i[4];
    assign DaForwardMux_i[0] = Da;
    assign DaForwardMux_i[1] = MA_data;
    assign DaForwardMux_i[2] = EX_data;
    assign DaForwardMux_i[3] = EX_data;
    logic [63:0] DbForwardMux_i[4];
    assign DbForwardMux_i[0] = Db;
    assign DbForwardMux_i[1] = MA_data;
    assign DbForwardMux_i[2] = EX_data;
    assign DbForwardMux_i[3] = EX_data;

    // Forwarding logic for Da
    logic ExDaOut, MaDaOut, DaSel0, DaSel1;
    isEqual5 ExDaTest (
        .result(ExDaOut),
        .A(EX_Rd),
        .B(ID_Rn)
    );
    isEqual5 MaDaTest (
        .result(MaDaOut),
        .A(MA_Rd),
        .B(ID_Rn)
    );
    and #0.05 getDaSel1 (DaSel1, ExDaOut, EX_isValid);
    and #0.05 getDaSel0 (DaSel0, MaDaOut, MA_isValid);
    mux4x1 #(64) DaForwardingMux (
        .in  (DaForwardMux_i),
        .out (Da_forwarded),
        .port({DaSel1, DaSel0})
    );

    // Forwarding logic for Db
    logic ExRdDbEq, ExRmDbEq, ExDbRegMux_o, MaRdDbEq, MaRmDbEq, MaDbRegMux_o;
    logic DbSel0, DbSel1;
    isEqual5 ExDbTest0 (
        .result(ExRdDbEq),
        .A(EX_Rd),
        .B(ID_Rd)
    );
    isEqual5 ExDbTest1 (
        .result(ExRmDbEq),
        .A(EX_Rd),
        .B(ID_Rm)
    );
    isEqual5 MaDbTest0 (
        .result(MaRdDbEq),
        .A(MA_Rd),
        .B(ID_Rd)
    );
    isEqual5 MaDbTest1 (
        .result(MaRmDbEq),
        .A(MA_Rd),
        .B(ID_Rm)
    );
    mux2x1_base ExDbRegMux (
        .in  ({ExRmDbEq, ExRdDbEq}),
        .out (ExDbRegMux_o),
        .port(Reg2Loc)
    );
    mux2x1_base MaDbRegMux (
        .in  ({MaRmDbEq, MaRdDbEq}),
        .out (MaDbRegMux_o),
        .port(Reg2Loc)
    );
    and #0.05 getDbSel1 (DbSel1, ExDbRegMux_o, EX_isValid);
    and #0.05 getDbSel0 (DbSel0, MaDbRegMux_o, MA_isValid);
    mux4x1 #(64) DbForwardingMux (
        .in  (DbForwardMux_i),
        .out (Db_forwarded),
        .port({DbSel1, DbSel0})
    );

endmodule  // processorForwardingUnit


// Testbench
module processorForwardingUnit_tb ();

    parameter DELAY = 100;

    // IO Replication
    logic [31:0] ID_instruction, EX_instruction;
    logic [63:0] Da, Db, EX_data, MA_data;
    logic [4:0] MA_Rd;
    logic EX_MemWrite, EX_MemRead, EX_RegWrite, Reg2Loc;
    logic MA_MemWrite, MA_MemRead, MA_RegWrite;
    logic [63:0] Da_forwarded, Db_forwarded;

    // Instance
    processorForwardingUnit dut (.*);

    // Test
    integer i;
    initial begin

        $display("Testing forwarding logic for Da");
        Da = 64'hDEAD;
        EX_data = 64'hBEEF;
        MA_data = 64'hCAFE;
        ID_instruction[9:5] = 5'b00000;
        EX_instruction[4:0] = 5'b00000;
        MA_Rd = 5'b00000;
        for (i = 0; i < 50; i++) begin : testDa
            EX_MemWrite = $urandom();
            EX_MemRead  = $urandom();
            EX_RegWrite = EX_MemWrite ? 1'b0 : $urandom();
            MA_MemWrite = $urandom();
            MA_MemRead  = $urandom();
            MA_RegWrite = MA_MemWrite ? 1'b0 : $urandom();
            #(DELAY);
        end
        // Set Rd to X31
        EX_instruction[4:0] = 5'd31;
        MA_Rd = 5'd31;
        for (i = 0; i < 50; i++) begin : testDa31
            EX_MemWrite = $urandom();
            EX_MemRead  = $urandom();
            EX_RegWrite = EX_MemWrite ? 1'b0 : $urandom();
            MA_MemWrite = $urandom();
            MA_MemRead  = $urandom();
            MA_RegWrite = MA_MemWrite ? 1'b0 : $urandom();
            #(DELAY);
            assert (Da_forwarded == Da);
        end


        $display("Testing forwarding logic for Db");
        Db = 64'hF00D;
        ID_instruction[20:16] = 5'b00000;
        ID_instruction[4:0] = 5'b00000;
        for (i = 0; i < 50; i++) begin : testDb31
            Reg2Loc     = $urandom();
            EX_MemWrite = $urandom();
            EX_MemRead  = $urandom();
            EX_RegWrite = EX_MemWrite ? 1'b0 : $urandom();
            MA_MemWrite = $urandom();
            MA_MemRead  = $urandom();
            MA_RegWrite = MA_MemWrite ? 1'b0 : $urandom();
            #(DELAY);
            assert (Db_forwarded == Db);
        end
        // Set Rd back to ID Rd/Rm
        Db = 64'hAAAAF00D;
        EX_instruction[4:0] = 5'd0;
        MA_Rd = 5'd0;
        // Test for Rd
        ID_instruction[4:0] = 5'd10;
        Reg2Loc = 1'b0;
        for (i = 0; i < 50; i++) begin : testDbRd
            EX_MemWrite = $urandom();
            EX_MemRead  = $urandom();
            EX_RegWrite = EX_MemWrite ? 1'b0 : $urandom();
            MA_MemWrite = $urandom();
            MA_MemRead  = $urandom();
            MA_RegWrite = MA_MemWrite ? 1'b0 : $urandom();
            #(DELAY);
            assert (Db_forwarded == Db);
        end
        // Test for Rm
        Db = 64'hBBBBF00D;
        ID_instruction[20:16] = 5'd10;
        EX_instruction[4:0] = 5'd10;
        Reg2Loc = 1'b1;
        for (i = 0; i < 50; i++) begin : testDbRm
            EX_MemWrite = $urandom();
            EX_MemRead  = $urandom();
            EX_RegWrite = EX_MemWrite ? 1'b0 : $urandom();
            MA_MemWrite = $urandom();
            MA_MemRead  = $urandom();
            MA_RegWrite = MA_MemWrite ? 1'b0 : $urandom();
            #(DELAY);
        end
        // Remove instant restrictions and test
        ID_instruction[4:0] = 5'd0;
        ID_instruction[20:16] = 5'd0;
        Db = 64'hF00D;
        for (i = 0; i < 50; i++) begin : testDbGeneric
            Reg2Loc     = $urandom();
            EX_MemWrite = $urandom();
            EX_MemRead  = $urandom();
            EX_RegWrite = EX_MemWrite ? 1'b0 : $urandom();
            MA_MemWrite = $urandom();
            MA_MemRead  = $urandom();
            MA_RegWrite = MA_MemWrite ? 1'b0 : $urandom();
            #(DELAY);
        end

        $stop();
    end  // Test
endmodule  // processorForwardingUnit_tb
