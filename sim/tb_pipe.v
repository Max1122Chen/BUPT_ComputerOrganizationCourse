// Pipeline control-vector testbench for hardwired_ctrl_pipe (PL-F01 + PL-F02)

`timescale 1ns / 1ps

module tb_pipe;

    reg        CLR_n;
    reg        T3;
    reg        QD;
    reg        SWA, SWB, SWC;
    reg [7:0]  ir;
    reg        W1, W2, W3;
    reg        C, Z;
    reg        INTR;

    wire       DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR;
    wire       LDZ, LDC, CIN;
    wire       S0, S1, S2, S3, M;
    wire       ABUS, SBUS, MBUS, SHORT, LONG;
    wire       SEL0, SEL1, SEL2, SEL3;
    wire       LIAR, IABUS;

    integer    errors;

    localparam LD  = 8'h56;
    localparam ADD = 8'h11;
    localparam INC = 8'h40;
    localparam EI  = 8'hD0;
    localparam IRET = 8'hB0;
    localparam JMP = 8'h90;

    hardwired_ctrl_pipe dut (
        .CLR_n(CLR_n),
        .T3(T3), .QD(QD), .SWA(SWA), .SWB(SWB), .SWC(SWC),
        .IR4(ir[4]), .IR5(ir[5]), .IR6(ir[6]), .IR7(ir[7]),
        .W1(W1), .W2(W2), .W3(W3),
        .C(C), .Z(Z), .INTR(INTR),
        .DRW(DRW), .PCINC(PCINC), .LPC(LPC), .LAR(LAR),
        .PCADD(PCADD), .ARINC(ARINC), .SELCTL(SELCTL),
        .MEMW(MEMW), .STOP(STOP), .LIR(LIR),
        .LDZ(LDZ), .LDC(LDC), .CIN(CIN),
        .S0(S0), .S1(S1), .S2(S2), .S3(S3), .M(M),
        .ABUS(ABUS), .SBUS(SBUS), .MBUS(MBUS),
        .SHORT(SHORT), .LONG(LONG),
        .SEL0(SEL0), .SEL1(SEL1), .SEL2(SEL2), .SEL3(SEL3),
        .LIAR(LIAR), .IABUS(IABUS)
    );

    task step_t3;
        begin
            T3 = 1; #1;
            T3 = 0; #1;
        end
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

    task pipe_cycle;
        begin
            #1;
            step_t3();
        end
    endtask

    initial begin
        errors = 0;
        CLR_n = 1;
        T3 = 0; QD = 0;
        SWA = 0; SWB = 0; SWC = 0;
        W1 = 0; W2 = 0; W3 = 0;
        ir = 8'h00; C = 0; Z = 0; INTR = 0;

        #1; CLR_n = 0;
        #1; CLR_n = 1;

        // --- §3.4 LD -> ADD -> INC (mem-exclusive IF) ---

        // c1: IF only (I1=LD in IR)
        ir = LD;
        #1;
        expect1(LIR,   1'b1, "c1 LIR");
        expect1(PCINC, 1'b1, "c1 PCINC");
        expect1(LAR,   1'b0, "c1 no EX");
        pipe_cycle();

        // c2: EX(LD) only — no IF (IR must stay LD through MEM)
        #1;
        expect1(LAR,   1'b1, "c2 LD LAR");
        expect1(LONG,  1'b1, "c2 LD LONG");
        expect1(ABUS,  1'b1, "c2 LD ABUS");
        expect1(LIR,   1'b0, "c2 no LIR");
        expect1(PCINC, 1'b0, "c2 no PCINC");
        pipe_cycle();

        // c3: MEM(LD) only
        #1;
        expect1(MBUS,  1'b1, "c3 LD MBUS");
        expect1(DRW,   1'b1, "c3 LD DRW");
        expect1(LIR,   1'b0, "c3 no LIR");
        expect1(PCINC, 1'b0, "c3 no PCINC");
        expect1(LAR,   1'b0, "c3 no EX");
        pipe_cycle();
        ir = ADD;

        // c4: IF(ADD) only
        #1;
        expect1(LIR,   1'b1, "c4 LIR");
        expect1(PCINC, 1'b1, "c4 PCINC");
        expect1(ABUS,  1'b0, "c4 no EX");
        pipe_cycle();
        ir = INC;

        // c5: EX(ADD) + IF(INC)
        #1;
        expect1(ABUS,  1'b1, "c5 ADD ABUS");
        expect1(DRW,   1'b1, "c5 ADD DRW");
        expect1(CIN,   1'b1, "c5 ADD CIN");
        expect1(LIR,   1'b1, "c5 LIR");
        expect1(PCINC, 1'b1, "c5 PCINC");
        pipe_cycle();
        ir = ADD;

        // c6: EX(INC) + IF
        #1;
        expect1(ABUS,  1'b1, "c6 INC ABUS");
        expect1(DRW,   1'b1, "c6 INC DRW");
        expect1(LIR,   1'b1, "c6 LIR");
        expect1(PCINC, 1'b1, "c6 PCINC");
        pipe_cycle();

        // --- branch flush: JMP taken suppresses fetch ---
        #1; CLR_n = 0; #1; CLR_n = 1;
        ir = JMP;
        #1;
        expect1(LIR, 1'b1, "pre-jmp LIR");
        pipe_cycle();
        ir = ADD;

        #1;
        expect1(LPC,   1'b1, "jmp EX LPC");
        expect1(LIR,   1'b0, "jmp no LIR");
        expect1(PCINC, 1'b0, "jmp no PCINC");
        pipe_cycle();

        // --- interrupt after EX: drain current op, then LIAR x2, load ---
        #1; CLR_n = 0; #1; CLR_n = 1;
        ir = EI;
        #1;
        expect1(LIR,   1'b1, "ei IF LIR");
        expect1(PCINC, 1'b1, "ei IF PCINC");
        pipe_cycle();

        ir = ADD;
        #1;
        expect1(LIR,   1'b1, "ei EX fetch next");
        expect1(PCINC, 1'b1, "ei EX fetch next PCINC");
        pipe_cycle();

        ir = INC;
        INTR = 1'b1;
        #1;
        expect1(ABUS,  1'b1, "int EX current op completes");
        expect1(DRW,   1'b1, "int EX current op DRW");
        expect1(LIR,   1'b1, "int capture same-cycle fetch still visible");
        pipe_cycle();

        W1 = 1'b1;
        INTR = 1'b0;
        ir = ADD;
        #1;
        expect1(LIAR,  1'b1, "int ack LIAR");
        expect1(STOP,  1'b1, "int ack STOP");
        expect1(SHORT, 1'b1, "int ack SHORT");
        expect1(LIR,   1'b0, "int ack no fetch");
        pipe_cycle();

        #1;
        expect1(LIAR,  1'b1, "int ack2 LIAR");
        expect1(STOP,  1'b1, "int ack2 STOP");
        expect1(SHORT, 1'b1, "int ack2 SHORT");
        expect1(SBUS,  1'b0, "int ack2 no SBUS");
        pipe_cycle();

        #1;
        expect1(SBUS,  1'b1, "int load SBUS");
        expect1(LPC,   1'b1, "int load LPC");
        expect1(SHORT, 1'b1, "int load SHORT");
        expect1(LIAR,  1'b0, "int load no LIAR");
        pipe_cycle();
        W1 = 1'b0;

        ir = IRET;
        #1;
        expect1(LIR,   1'b1, "post-int IF LIR");
        expect1(PCINC, 1'b1, "post-int IF PCINC");
        pipe_cycle();

        // --- IRET executes on EX with IABUS+LPC ---
        #1;
        expect1(IABUS, 1'b1, "iret IABUS");
        expect1(LPC,   1'b1, "iret LPC");
        expect1(LIR,   1'b0, "iret EX no IF");
        expect1(PCINC, 1'b0, "iret EX no PCINC");
        pipe_cycle();

        #1;
        expect1(LIR,   1'b1, "iret next IF");
        expect1(PCINC, 1'b1, "iret next PCINC");
        pipe_cycle();

        // --- manual WR_REG bypass (W1) ---
        #1; CLR_n = 0; #1; CLR_n = 1;
        SWA = 0; SWB = 0; SWC = 1;
        W1 = 1; #1;
        expect1(SBUS,   1'b1, "manual SBUS");
        expect1(SELCTL, 1'b1, "manual SELCTL");
        expect1(DRW,    1'b1, "manual DRW");
        W1 = 0;

        if (errors == 0)
            $display("PASS tb_pipe (%0d checks)", 0);
        else
            $display("FAIL tb_pipe: %0d errors", errors);

        $finish;
    end

endmodule
