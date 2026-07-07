// Control-vector testbench for hardwired_ctrl (SIM-F01 / CTL-F01)

`timescale 1ns / 1ps

module tb_ctrl;

    reg        T3;
    reg        SWA, SWB, SWC;
    reg [7:0]  ir;
    reg        W1, W2, W3;
    reg        C, Z;
    reg        STO;

    wire       DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR;
    wire       LDZ, LDC, CIN;
    wire       S0, S1, S2, S3, M;
    wire       ABUS, SBUS, MBUS, SHORT, LONG;
    wire       SEL0, SEL1, SEL2, SEL3;

    integer    errors;

    hardwired_ctrl dut (
        .T3(T3), .SWA(SWA), .SWB(SWB), .SWC(SWC),
        .IR4(ir[4]), .IR5(ir[5]), .IR6(ir[6]), .IR7(ir[7]),
        .W1(W1), .W2(W2), .W3(W3),
        .C(C), .Z(Z), .STO(STO),
        .DRW(DRW), .PCINC(PCINC), .LPC(LPC), .LAR(LAR),
        .PCADD(PCADD), .ARINC(ARINC), .SELCTL(SELCTL),
        .MEMW(MEMW), .STOP(STOP), .LIR(LIR),
        .LDZ(LDZ), .LDC(LDC), .CIN(CIN),
        .S0(S0), .S1(S1), .S2(S2), .S3(S3), .M(M),
        .ABUS(ABUS), .SBUS(SBUS), .MBUS(MBUS),
        .SHORT(SHORT), .LONG(LONG),
        .SEL0(SEL0), .SEL1(SEL1), .SEL2(SEL2), .SEL3(SEL3)
    );

    task clear_w;
        begin W1 = 0; W2 = 0; W3 = 0; end
    endtask

    task expect1;
        input got;
        input exp;
        input [8*64-1:0] name;
        begin
            if (got !== exp) begin
                $display("FAIL %s: got %b exp %b", name, got, exp);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        T3 = 0; SWA = 0; SWB = 0; SWC = 0;
        ir = 8'h00; C = 0; Z = 0; STO = 0;
        clear_w();

        // --- W1 fetch: ADD opcode irrelevant for LIR ---
        ir = 8'h11;
        W1 = 1; T3 = 0;
        #1;
        expect1(LIR, 1'b1, "fetch LIR");
        expect1(PCINC, 1'b0, "fetch PCINC before T3");
        T3 = 1; #1;
        expect1(PCINC, 1'b1, "fetch PCINC at T3");
        expect1(SHORT, 1'b0, "fetch W1 must not assert SHORT");
        clear_w(); T3 = 0;

        // --- W2 ADD ---
        ir = 8'h11;
        W2 = 1; #1;
        expect1(ABUS, 1'b1, "ADD ABUS");
        expect1(DRW, 1'b1, "ADD DRW");
        expect1(CIN, 1'b1, "ADD CIN");
        expect1(S3, 1'b1, "ADD S3");
        expect1(S0, 1'b1, "ADD S0");
        expect1(SELCTL, 1'b1, "ADD SELCTL");
        clear_w();

        // --- W2 SUB ---
        ir = 8'h20;
        W2 = 1; #1;
        expect1(S3, 1'b0, "SUB S3");
        expect1(S2, 1'b1, "SUB S2");
        expect1(S1, 1'b1, "SUB S1");
        expect1(ABUS, 1'b1, "SUB ABUS");
        clear_w();

        // --- W2 LD + W3 ---
        ir = 8'h51;
        W2 = 1; #1;
        expect1(LAR, 1'b1, "LD W2 LAR");
        expect1(LONG, 1'b1, "LD W2 LONG");
        clear_w();
        W3 = 1; #1;
        expect1(DRW, 1'b1, "LD W3 DRW");
        expect1(MBUS, 1'b1, "LD W3 MBUS");
        expect1(SHORT, 1'b1, "LD W3 SHORT");
        clear_w();

        // --- W2 ST + W3 ---
        ir = 8'h62;
        W2 = 1; #1;
        expect1(LONG, 1'b1, "ST W2 LONG");
        clear_w();
        W3 = 1; #1;
        expect1(MEMW, 1'b1, "ST W3 MEMW");
        expect1(SHORT, 1'b1, "ST W3 SHORT");
        clear_w();

        // --- JC taken / not taken ---
        ir = 8'h70; C = 1; W2 = 1; #1;
        expect1(PCADD, 1'b1, "JC taken");
        clear_w(); C = 0;
        W2 = 1; #1;
        expect1(PCADD, 1'b0, "JC not taken");
        clear_w();

        // --- JZ ---
        ir = 8'h80; Z = 1; W2 = 1; #1;
        expect1(PCADD, 1'b1, "JZ taken");
        clear_w(); Z = 0;

        // --- JMP ---
        ir = 8'h91;
        W2 = 1; #1;
        expect1(LPC, 1'b1, "JMP LPC");
        expect1(M, 1'b1, "JMP M");
        clear_w();

        // --- STP ---
        ir = 8'hE0;
        W2 = 1; #1;
        expect1(STOP, 1'b1, "STP STOP");
        clear_w();

        // --- W2 AND / INC ---
        ir = 8'h33; W2 = 1; #1;
        expect1(M, 1'b1, "AND M");
        expect1(S3, 1'b1, "AND S3");
        clear_w();

        ir = 8'h40; W2 = 1; #1;
        expect1(S3, 1'b0, "INC S3");
        expect1(LDC, 1'b1, "INC LDC");
        clear_w();

        // --- OUT / EI / IRET ---
        ir = 8'hA2; W2 = 1; #1;
        expect1(ABUS, 1'b1, "OUT ABUS");
        clear_w();

        ir = 8'hD0; W2 = 1; #1;
        expect1(SHORT, 1'b1, "EI SHORT");
        clear_w();

        ir = 8'hB0; W2 = 1; #1;
        expect1(LPC, 1'b1, "IRET LPC");
        clear_w();

        // --- manual write reg SW=100 ---
        SWC = 1; SWB = 0; SWA = 0;
        W1 = 1; #1;
        expect1(SBUS, 1'b1, "wrreg SBUS");
        expect1(DRW, 1'b1, "wrreg DRW");
        expect1(SEL1, 1'b1, "wrreg SEL1");
        expect1(SEL0, 1'b1, "wrreg SEL0");
        SWC = 0; SWB = 0; SWA = 0;
        clear_w();

        // --- manual read mem SW=010 ---
        SWC = 0; SWB = 1; SWA = 0; STO = 0;
        W1 = 1; #1;
        expect1(SBUS, 1'b1, "rdmem SBUS");
        expect1(LAR, 1'b1, "rdmem LAR");
        expect1(SHORT, 1'b1, "rdmem SHORT");
        SWC = 0; SWB = 0; SWA = 0;
        clear_w();

        if (errors == 0)
            $display("PASS: tb_ctrl all checks OK");
        else
            $display("FAIL: tb_ctrl errors=%0d", errors);

        if (errors != 0)
            $fatal(1);
        $finish;
    end

endmodule
