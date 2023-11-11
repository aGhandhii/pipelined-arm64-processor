`timescale 1ns / 10ps

/* Processor Execution Submodule

Inputs:
    MOVmask_o: bitmask for a MOVK command
    Da: data out at Regfile port 1
    Db_i: data out at Regfile port 2
    DT_Address: Sign-Extended address (memory operation)
    ALU_Imm: Zero-Extended ALU immediate (ADDI)
    instruction_i: 32-bit ARM instruction
    ALUsrc: 2-bit input, determines 'B' input to main ALU module
        -> 00 to pass DataB from RegFile
        -> 01 to pass Daddr9 (memory operation)
        -> 10 to pass ALU_Imm12 (immediate input)
    ALUop: 3-bit operation for the main ALU to perform
        000 -> PASS_B
        010 -> ADD
        011 -> SUB
        100 -> AND
        101 -> OR
        110 -> XOR
    MemByteSize: number of bytes to write/read to/from memory
        -> 0 for LDUR/STUR
        -> 1 for LDURB/STURB
    MOVcmd: determine if instruction is a MOV command
    MOVkeep: determines if MOV command is MOVK or MOVZ
        -> 0 for MOVZ
        -> 1 for MOVK

Outputs:
    Z: Zero Flag
    N: Negative Flag
    V: Overflow Flag
    MOVkeepMux_o: MOV result
    ALU_o: 64-bit output from the main ALU
    Db_o: data out at Regfile port 2
    XferSizeMux_o: Input byte transfer size for memory access
    instruction_o: 32-bit ARM instruction
*/
module processorExecution (
    instruction_i,
    MOVmask_o,
    Da,
    Db_i,
    DT_Address,
    ALU_Imm,
    ALUsrc,
    ALUop,
    MemByteSize,
    MOVcmd,
    MOVkeep,
    Z,
    instruction_o,
    V,
    N,
    Db_o,
    ALU_o,
    XferSizeMux_o,
    MOVkeepMux_o
);
    // IO Declaration
    input logic MemByteSize, MOVcmd, MOVkeep;
    input logic [1:0] ALUsrc;
    input logic [2:0] ALUop;
    input logic [31:0] instruction_i;
    input logic [63:0] MOVmask_o, Da, Db_i, DT_Address, ALU_Imm;
    output logic Z, V, N;
    output logic [3:0] XferSizeMux_o;
    output logic [31:0] instruction_o;
    output logic [63:0] Db_o, ALU_o, MOVkeepMux_o;

    // Wire passing IO
    assign instruction_o = instruction_i;
    assign Db_o = Db_i;

    // Instruction Immediates and Assignments
    logic [ 1:0] MOVshamt;
    logic [15:0] MOV_imm16;
    assign MOVshamt  = instruction_i[22:21];
    assign MOV_imm16 = instruction_i[20:5];

    // Intermediate Logic
    logic C;  // Carry-out ALU flag; unused in this implementation
    logic [63:0] MOVcmdMux_o, ALUsrcMux_o, MOVadd_o, MOVshiftVal_o;

    // Synthesized multi-bit Mux port inputs
    logic [63:0] MOVcmdMux_i[2];
    assign MOVcmdMux_i[0] = Da;
    assign MOVcmdMux_i[1] = MOVmask_o;
    logic [63:0] ALUsrcMux_i[4];
    assign ALUsrcMux_i[0] = Db_i;
    assign ALUsrcMux_i[1] = DT_Address;
    assign ALUsrcMux_i[2] = ALU_Imm;
    assign ALUsrcMux_i[3] = 64'd0;  // Ignored
    logic [63:0] MOVkeepMux_i[2];
    assign MOVkeepMux_i[0] = MOVshiftVal_o;
    assign MOVkeepMux_i[1] = MOVadd_o;
    logic [3:0] XferSizeMux_i[2];
    assign XferSizeMux_i[0] = 4'd8;
    assign XferSizeMux_i[1] = 4'd1;

    // Submodule Instantiation
    MOVinputGenerator shiftVal (
        .value_i(MOV_imm16),
        .mask_i(16'h0000),
        .shamt(MOVshamt),
        .out(MOVshiftVal_o)
    );
    mux2x1 #(64) MOVcmdMux (
        .out (MOVcmdMux_o),
        .in  (MOVcmdMux_i),
        .port(MOVcmd)
    );
    mux4x1 #(64) ALUsrcMux (
        .out (ALUsrcMux_o),
        .in  (ALUsrcMux_i),
        .port(ALUsrc)
    );
    alu ALU_main (
        .result(ALU_o),
        .negative(N),
        .zero(Z),
        .overflow(V),
        .carry_out(C),
        .A(MOVcmdMux_o),
        .B(ALUsrcMux_o),
        .cntrl(ALUop)
    );
    add64 MOVadd (
        .result(MOVadd_o),
        .A(MOVshiftVal_o),
        .B(ALU_o)
    );
    mux2x1 #(64) MOVkeepMux (
        .out (MOVkeepMux_o),
        .in  (MOVkeepMux_i),
        .port(MOVkeep)
    );
    mux2x1 #(4) XferSizeMux (
        .out (XferSizeMux_o),
        .in  (XferSizeMux_i),
        .port(MemByteSize)
    );

endmodule  // processorExecution


// Processor Execution Submodule Testbench
module processorExecution_tb ();

    // Delay
    parameter DELAY = 100;

    // IO
    logic MemByteSize, MOVcmd, MOVkeep;
    logic [ 1:0] ALUsrc;
    logic [ 2:0] ALUop;
    logic [31:0] instruction_i;
    logic [63:0] MOVmask_o, Da, Db_i, DT_Address, ALU_Imm;
    logic Z, V, N;
    logic [ 3:0] XferSizeMux_o;
    logic [31:0] instruction_o;
    logic [63:0] Db_o, ALU_o, MOVkeepMux_o;

    // Instance
    processorExecution dut (.*);

    // Test
    integer i;
    initial begin
        $display("Testing IO Wire connectivity");
        for (i = 0; i < 20; i++) begin : testWires
            Db_i[21:0]           = $urandom();
            Db_i[42:22]          = $urandom();
            Db_i[63:43]          = $urandom();
            instruction_i[15:0]  = $urandom();
            instruction_i[31:16] = $urandom();
            #(DELAY);
            assert (Db_o == Db_i);
            assert (instruction_o == instruction_i);
        end

        $display("Testing MOV command value shifter");
        MOVkeep = 1'b0;
        for (i = 0; i < 20; i++) begin : testMOVshift
            instruction_i[22:21] = $urandom();  // MOVshamt
            instruction_i[20:5]  = $urandom();  // MOV_imm16
            #(DELAY);
            case (instruction_i[22:21])  // MOVshamt
                2'b00: begin
                    assert (MOVkeepMux_o == {48'd0, instruction_i[20:5]});
                end
                2'b01: begin
                    assert(
                        MOVkeepMux_o == {32'd0,instruction_i[20:5],16'd0}
                    );
                end
                2'b10: begin
                    assert(
                        MOVkeepMux_o == {16'd0,instruction_i[20:5],32'd0}
                    );
                end
                2'b11: begin
                    assert (MOVkeepMux_o == {instruction_i[20:5], 48'd0});
                end
                default: begin
                    // Do nothing
                end
            endcase
        end

        $display("Testing the ALU input Muxes");
        // Start with MOVcmd: set Db to 0, ALUsrc to pass Db, and ALUop to ADD
        // Change MOVcmd and assert the proper data at the ALU output
        Db_i             = 64'd0;
        ALUsrc           = 2'b00;
        ALUop            = 3'b010;  // ADD
        Da[21:0]         = $urandom();
        Da[42:22]        = $urandom();
        Da[63:43]        = $urandom();
        MOVmask_o[21:0]  = $urandom();
        MOVmask_o[42:22] = $urandom();
        MOVmask_o[63:43] = $urandom();
        MOVcmd           = 0;
        #(DELAY);
        assert (ALU_o == Da);
        MOVcmd = 1;
        #(DELAY);
        assert (ALU_o == MOVmask_o);
        // Move to ALUsrc: set ALUop to PASS_B and toggle the source, asserting
        // the expected data at ALU output
        ALUop             = 3'b000;  // PASS_B
        Db_i[21:0]        = $urandom();
        Db_i[42:22]       = $urandom();
        Db_i[63:43]       = $urandom();
        DT_Address[21:0]  = $urandom();
        DT_Address[42:22] = $urandom();
        DT_Address[63:43] = $urandom();
        ALU_Imm[21:0]     = $urandom();
        ALU_Imm[42:22]    = $urandom();
        ALU_Imm[63:43]    = $urandom();
        ALUsrc            = 2'b00;
        #(DELAY);
        assert (ALU_o == Db_i);
        ALUsrc = 2'b01;
        #(DELAY);
        assert (ALU_o == DT_Address);
        ALUsrc = 2'b10;
        #(DELAY);
        assert (ALU_o == ALU_Imm);

        $display("Testing the ALU operations and flag outputs");
        // PASS_B 000
        // Pass zero, then a non-zero value and check the flags
        ALUsrc = 2'b00;
        Db_i   = 64'd0;
        #(DELAY);
        assert (Z && ~V && ~N);
        Db_i = (64'd0 - 64'd15);
        #(DELAY);
        assert (~Z && ~V && N);
        // ADD 010
        // Add zero and zero, check flags, then random cases
        // SUB 011
        // Test random cases
        // AND 100
        // Test random cases
        ALUop = 3'b010;
        MOVmask_o = 64'd0;
        #(DELAY);
        assert (~Z && ~V && N);
        for (i = 0; i < 30; i++) begin : testALUaddsub
            case (i % 3)
                0: ALUop = 3'b010;  // ADD
                1: ALUop = 3'b011;  // SUB
                2: ALUop = 3'b100;  // AND
                default: ALUop = 3'b010;  // ADD
            endcase
            Db_i[21:0]       = $urandom();
            Db_i[42:22]      = $urandom();
            Db_i[63:43]      = $urandom();
            MOVmask_o[21:0]  = $urandom();
            MOVmask_o[42:22] = $urandom();
            MOVmask_o[63:43] = $urandom();
            #(DELAY);
            case (i % 3)
                0: assert (ALU_o == Db_i + MOVmask_o);  // ADD
                1: assert (ALU_o == MOVmask_o - Db_i);  // SUB
                2: assert ((Db_i & MOVmask_o) ^ ALU_o == 0);  // AND
                default: assert (ALU_o == Db_i + MOVmask_o);  // ADD
            endcase
        end

        $display("Testing the Memory Transfer Size Mux");
        MemByteSize = 0;
        #(DELAY);
        assert (XferSizeMux_o == 4'd8);
        MemByteSize = 1;
        #(DELAY);
        assert (XferSizeMux_o == 4'd1);

        $stop();
    end  // Test

endmodule  // processorExecution_tb
