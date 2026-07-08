// Pipeline controller testbench (PL-F01)

`timescale 1ns / 1ps

module tb_pipe;

    reg        CLR_n;
    reg        T3;
    reg        QD;
    reg        SWA, SWB, SWC;
    reg [7:0]  ir;
    reg        W1, W2, W3;
    reg        C, Z;

    wire       DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR;
    wire       LDZ, LDC, CIN;
    wire       S0, S1, S2, S3, M;
    wire       ABUS, SBUS, MBUS, SHORT, LONG;
    wire       SEL0, SEL1, SEL2, SEL3;

    integer    errors;

    hardwired_ctrl_pipe #(
        .HAZARD_FINE_GRAIN(1'b1)
    ) dut (
        .CLR_n(CLR_n),
        .T3(T3), .QD(QD), .SWA(SWA), .SWB(SWB), .SWC(SWC),
        .IR0(ir[0]), .IR1(ir[1]), .IR2(ir[2]), .IR3(ir[3]),
        .IR4(ir[4]), .IR5(ir[5]), .IR6(ir[6]), .IR7(ir[7]),
        .W1(W1), .W2(W2), .W3(W3),
        .C(C), .Z(Z),
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

    task negedge_t3;
        begin T3 = 1; #1; T3 = 0; #1; end
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

    // One machine cycle: W1 -> T3- -> W2 -> W3
    task machine_cycle;
        input [7:0] ir_fetch;
        input       do_w2;
        input       do_w3;
        begin
            ir = ir_fetch;
            W1 = 1; #1;
            negedge_t3();
            clear_w();
            if (do_w2) begin
                W2 = 1; #1;
                clear_w();
            end
            if (do_w3) begin
                W3 = 1; #1;
                clear_w();
            end
        end
    endtask

    task pipe_reset;
        begin
            clear_w();
            CLR_n = 0; #1; CLR_n = 1; #1;
            T3 = 0;
        end
    endtask

    // Prime EX/MEM with fetch_insn, then W2 executes it (one insn latency).
    task pipe_exec_w2;
        input [7:0] fetch_insn;
        begin
            machine_cycle(fetch_insn, 0, 0);
            ir = 8'h00;
            W1 = 1; #1;
            negedge_t3();
            clear_w();
            W2 = 1; #1;
        end
    endtask

    initial begin
        errors = 0;
        CLR_n = 1;
        T3 = 0; QD = 0;
        SWA = 0; SWB = 0; SWC = 0;
        ir = 8'h00; C = 0; Z = 0;
        clear_w();
        #1; CLR_n = 0; #1; CLR_n = 1;

        // --- RUN W1 fetch ---
        pipe_reset();
        ir = 8'h11;
        W1 = 1; #1;
        expect1(LIR, 1'b1, "pipe fetch LIR");
        expect1(PCINC, 1'b1, "pipe fetch PCINC");
        clear_w();

        // --- Prime pipeline: fetch ADD then SUB; execute ADD on 2nd cycle W2 ---
        pipe_reset();
        machine_cycle(8'h11, 0, 0);
        ir = 8'h20;
        W1 = 1; #1;
        negedge_t3();
        clear_w();
        W2 = 1; #1;
        expect1(ABUS, 1'b1, "pipe EX ADD ABUS");
        expect1(CIN, 1'b1, "pipe EX ADD CIN");
        expect1(SHORT, 1'b1, "pipe EX ADD SHORT");
        clear_w();

        // --- LD 3-cycle: W2 LAR then W3 DRW ---
        pipe_reset();
        pipe_exec_w2(8'h51);
        expect1(LAR, 1'b1, "pipe EX LD LAR");
        expect1(LONG, 1'b1, "pipe EX LD LONG");
        expect1(SHORT, 1'b0, "pipe EX LD no SHORT");
        clear_w();
        W3 = 1; #1;
        expect1(DRW, 1'b1, "pipe MEM LD DRW");
        expect1(MBUS, 1'b1, "pipe MEM LD MBUS");
        clear_w();

        // --- load-use stall: LD R1,[R2] (0x56) then ADD R0,R1 (0x09) ---
        pipe_reset();
        machine_cycle(8'h56, 0, 0);
        ir = 8'h09;
        W1 = 1; #1;
        negedge_t3();
        clear_w();
        ir = 8'h00;
        W1 = 1; #1;
        expect1(PCINC, 1'b0, "pipe stall no PCINC");
        clear_w();
        W2 = 1; #1;
        expect1(LAR, 1'b1, "pipe stall cycle LD still EX");
        clear_w();
        W3 = 1; #1;
        clear_w();

        // --- manual bypass SW=011 ---
        pipe_reset();
        SWC = 0; SWB = 1; SWA = 1;
        W1 = 1; #1;
        expect1(SEL0, 1'b1, "pipe manual rdreg W1 SEL0");
        expect1(STOP, 1'b1, "pipe manual rdreg STOP");
        SWC = 0; SWB = 0; SWA = 0;
        clear_w();

        // --- branch: JMP executes in EX ---
        pipe_reset();
        pipe_exec_w2(8'h91);
        expect1(LPC, 1'b1, "pipe EX JMP LPC");
        clear_w();

        if (errors == 0)
            $display("PASS: tb_pipe fine-grain OK");
        else
            $display("FAIL: tb_pipe fine-grain errors=%0d", errors);

        if (errors != 0)
            $fatal(1);
        $finish;
    end

endmodule
