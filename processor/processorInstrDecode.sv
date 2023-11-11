`timescale 1ns / 10ps

/* Processor Instruction Decode Submodule

Inputs:
    clk: system clock
    instruction_i: 32-bit ARM instruction
    PC_i: Program Counter value
    Rd_prev: Destination register from past instruction
    RdWriteDataMux_o: 64-bit input value for Rd write data
    Reg2Loc: decide input for ReadRegisterB to the RegFile
        -> 0 for Rd
        -> 1 for Rm
    RegWrite: wren for register file
    UncondBr: determine if branch is unconditional

Outputs:
    BrAdder_o: calculated next PC value in case of branch
    MOVmask_o: bitmask for a MOVK command
    Da: data out at Regfile port 1
    Db: data out at Regfile port 2
    ALU_Imm: Zero-Extended ALU immediate (ADDI)
    DT_Address: Sign-Extended address (memory operation)
    instruction_o: 32-bit ARM instruction
*/
module processorInstrDecode (
    clk,
    instruction_i,
    PC_i,
    Rd_prev,
    RdWriteDataMux_o,
    Reg2Loc,
    RegWrite,
    UncondBr,
    BrAdder_o,
    MOVmask_o,
    Da,
    Db,
    ALU_Imm,
    DT_Address,
    instruction_o
);
    // IO Declaration
    input logic clk, Reg2Loc, RegWrite, UncondBr;
    input logic [4:0] Rd_prev;
    input logic [31:0] instruction_i;
    input logic [63:0] PC_i, RdWriteDataMux_o;
    output logic [31:0] instruction_o;
    output logic [63:0] MOVmask_o, Da, Db, ALU_Imm, DT_Address, BrAdder_o;

    // Wire passing IO
    assign instruction_o = instruction_i;

    // Instruction Constants
    logic [18:0] CondAddr19;
    logic [25:0] BrAddr26;
    logic [4:0] Rd, Rm, Rn;
    logic [ 1:0] MOVshamt;
    logic [ 8:0] DT_Address9;
    logic [11:0] ALU_Imm12;

    // Instruction Constant Definitions
    assign CondAddr19 = instruction_i[23:5];
    assign BrAddr26 = instruction_i[25:0];
    assign Rd = instruction_i[4:0];
    assign Rm = instruction_i[20:16];
    assign Rn = instruction_i[9:5];
    assign MOVshamt = instruction_i[22:21];
    assign DT_Address9 = instruction_i[20:12];
    assign ALU_Imm12 = instruction_i[21:10];

    // Intermediate Logic
    logic [63:0] CondAddr, BrAddr, condMux_o, condMux_ox4;
    logic [4:0] Reg2LocMux_o;

    // Synthesized multi-bit Mux port inputs
    logic [4:0] Reg2LocMux_i [2];
    assign Reg2LocMux_i[0] = Rd;
    assign Reg2LocMux_i[1] = Rm;
    logic [63:0] condMux_i[2];  // Mux for branch condition type
    assign condMux_i[0] = CondAddr;
    assign condMux_i[1] = BrAddr;

    // Submodule Instantiation
    signExtend #(
        .INPUT_SIZE (19),
        .OUTPUT_SIZE(64)
    ) cond_SE (
        .in (CondAddr19),
        .out(CondAddr)
    );
    signExtend #(
        .INPUT_SIZE (26),
        .OUTPUT_SIZE(64)
    ) br_SE (
        .in (BrAddr26),
        .out(BrAddr)
    );
    mux2x1 #(64) condMux (
        .out (condMux_o),
        .in  (condMux_i),
        .port(UncondBr)
    );
    multByFour64 mult (
        .in (condMux_o),
        .out(condMux_ox4)
    );
    add64 branchAdder (
        .result(BrAdder_o),
        .A(condMux_ox4),
        .B(PC_i)
    );
    signExtend #(
        .INPUT_SIZE (9),
        .OUTPUT_SIZE(64)
    ) ZE_imm (
        .in (DT_Address9),
        .out(DT_Address)
    );
    zeroExtend #(
        .INPUT_SIZE (12),
        .OUTPUT_SIZE(64)
    ) SE_addr (
        .in (ALU_Imm12),
        .out(ALU_Imm)
    );
    MOVinputGenerator mask (
        .value_i(16'h0000),
        .mask_i(16'hFFFF),
        .shamt(MOVshamt),
        .out(MOVmask_o)
    );
    mux2x1 #(5) Reg2LocMux (
        .out (Reg2LocMux_o),
        .in  (Reg2LocMux_i),
        .port(Reg2Loc)
    );
    regfile RegisterFile (
        .ReadData1(Da),
        .ReadData2(Db),
        .WriteData(RdWriteDataMux_o),
        .ReadRegister1(Rn),
        .ReadRegister2(Reg2LocMux_o),
        .WriteRegister(Rd_prev),
        .RegWrite(RegWrite),
        .clk(clk)
    );

endmodule  // processorInstrDecode


/* Instruction Decode Testbench

For this testbench, we test the following properties:
    - IO wires are passed as expected
    - The proper 'condition' branch address is selected
    - The correct MOV bitmask is generated
    - The sign/zero extended outputs are correct
    - The Register File outputs are as expected
*/
module processorInstrDecode_tb ();
    // Delay
    parameter DELAY = 100;

    // IO
    logic clk, Reg2Loc, RegWrite, UncondBr;
    logic [ 4:0] Rd_prev;
    logic [31:0] instruction_i;
    logic [63:0] PC_i, RdWriteDataMux_o;
    logic [31:0] instruction_o;
    logic [63:0] MOVmask_o, Da, Db, ALU_Imm, DT_Address, BrAdder_o;

    // Setting up a simulated clock
    parameter CLOCK_PERIOD = 5000;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD / 2) clk <= ~clk;  // Forever toggle the clock
    end  // Setting up a simulated clock

    // Instance
    processorInstrDecode dut (.*);

    // ARM commands for testing
    logic [31:0] testInstructions[14];
    always_comb begin
        // ADDI X0, X31, #1
        testInstructions[0]  = 32'b1001000100_000000000001_11111_00000;
        // ADDS X7, X1, X5
        testInstructions[1]  = 32'b10101011000_00101_000000_00001_00111;
        // SUBS X31, X0, X3
        testInstructions[2]  = 32'b11101011000_00011_000000_00000_11111;
        // B +7
        testInstructions[3]  = 32'b000101_00000000000000000000000111;
        // B -7
        testInstructions[4]  = 32'b000101_11111111111111111111111001;
        // B.LT +8
        testInstructions[5]  = 32'b01010100_0000000000000001000_01011;
        // CBZ X31, +20
        testInstructions[6]  = 32'b10110100_0000000000000010100_11111;
        // CBZ X31, -1
        testInstructions[7]  = 32'b10110100_1111111111111111111_11111;
        // LDUR X7, [X4, #5]
        testInstructions[8]  = 32'b11111000010_000000101_00_00100_00111;
        // LDURB X11, [X31, #11]
        testInstructions[9]  = 32'b00111000010_000001011_00_11111_01011;
        // STUR X2, [X3, #8]
        testInstructions[10] = 32'b11111000000_000001000_00_00011_00010;
        // STURB X0, [X31, #4]
        testInstructions[11] = 32'b00111000000_000000100_00_11111_00000;
        // MOVK X1, #0xDEAD, LSL 32
        testInstructions[12] = 32'b111100101_10_1101111010101101_00001;
        // MOVZ X0, #0xCAFE, LSL 48
        testInstructions[13] = 32'b110100101_11_1100101011111110_00000;
    end

    // Test
    integer i;
    initial begin
        $display("Testing IO Wire connectivity");
        for (i = 0; i < 20; i++) begin : testWires
            instruction_i[15:0]  <= $urandom();
            instruction_i[31:16] <= $urandom();
            @(posedge clk);
            #(DELAY);
            assert (instruction_i == instruction_o);
        end

        $display("Test [Un]Conditional Branch Address Constants");
        UncondBr <= 1'b1;
        PC_i <= 64'b0;
        instruction_i <= testInstructions[3];  // B +7
        #(DELAY);
        assert (BrAdder_o == 64'd7 << 2);
        UncondBr <= 1'b1;
        instruction_i <= testInstructions[4];  // B -7
        #(DELAY);
        assert (BrAdder_o == (64'd0 - 64'd7) << 2);
        UncondBr <= 1'b0;  // Test the unexpected mux output
        #(DELAY);
        assert (BrAdder_o == (64'd0 - 64'd1) << 2);
        UncondBr <= 1'b0;
        instruction_i <= testInstructions[5];  // B.LT +8
        #(DELAY);
        assert (BrAdder_o == 64'd8 << 2);
        UncondBr <= 1'b0;
        instruction_i <= testInstructions[6];  // CBZ X31 +20
        #(DELAY);
        assert (BrAdder_o == 64'd20 << 2);
        UncondBr <= 1'b1;  // Test the unexpected mux output
        #(DELAY);
        assert (BrAdder_o == 64'd671 << 2);
        UncondBr <= 1'b0;
        instruction_i <= testInstructions[7];  // CBZ X31 -1
        #(DELAY);
        assert (BrAdder_o == (64'd0 - 64'd1) << 2);

        $display("Test MOV bitmask generation");
        instruction_i <= testInstructions[12];  // MOVK .. LSL 32
        #(DELAY);
        assert (MOVmask_o == 64'hFFFF_0000_FFFF_FFFF);
        instruction_i <= testInstructions[13];  // MOVZ .. LSL 48
        #(DELAY);
        assert (MOVmask_o == 64'h0000_FFFF_FFFF_FFFF);

        $display("Test sign/zero extend for ALU constants");
        for (i = 0; i < 20; i++) begin : testExtend
            instruction_i[21:10] <= $urandom();
            #(DELAY);
            assert (ALU_Imm == {{52{1'b0}}, instruction_i[21:10]});
            assert (
                DT_Address == {{55{instruction_i[20]}}, instruction_i[20:12]}
            );
        end

        $display("Testing the Register File");
        // Write '1738' to X0
        RegWrite <= 1'b1;
        Rd_prev <= 5'd0;  // Rd = X0
        RdWriteDataMux_o <= 64'd1738;
        @(posedge clk);
        #(DELAY);
        // Write '42069' to X1
        Rd_prev <= 5'd1;  // Rd = X1
        RdWriteDataMux_o <= 64'd42069;
        @(posedge clk);
        #(DELAY);
        // Write '-15' to X2
        Rd_prev <= 5'd2;  // Rd = X2
        RdWriteDataMux_o <= (64'd0 - 64'd15);
        @(posedge clk);
        #(DELAY);
        // Deactivate RegWrite and continually try to rewrite 999 to X2
        RegWrite <= 1'b0;
        RdWriteDataMux_o <= 64'd999;
        instruction_i[4:0] <= 5'd2;  // Rdcurr = X2
        instruction_i[9:5] <= 5'd0;  // Rn = X0
        instruction_i[20:16] <= 5'd1;  // Rm = X1
        // Toggle Reg2Loc and check register data
        Reg2Loc <= 1'b0;  // X0 at Da, X2 at Db
        @(posedge clk);
        #(DELAY);
        assert (Da == 64'd1738);
        assert (Db == (64'd0 - 64'd15));
        Reg2Loc <= 1'b1;  // X0 at Da, X1 at Db
        @(posedge clk);
        #(DELAY);
        assert (Da == 64'd1738);
        assert (Db == 64'd42069);

        $stop();
    end  // Test

endmodule  // processorInstrDecode_tb
