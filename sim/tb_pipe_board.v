// Board-safe pipeline hazard test (HAZARD_FINE_GRAIN=0, IR3–0 tied off)

`timescale 1ns / 1ps

module tb_pipe_board;

    reg        CLR_n;
    reg        T3;
    reg        QD;
    reg        SWA, SWB, SWC;
    reg [7:0]  ir;
    reg        W1, W2, W3;
    reg        C, Z;

    wire       PCINC;

    integer    errors;

    hardwired_ctrl_pipe dut (
        .CLR_n(CLR_n),
        .T3(T3), .QD(QD), .SWA(SWA), .SWB(SWB), .SWC(SWC),
        .IR0(1'b0), .IR1(1'b0), .IR2(1'b0), .IR3(1'b0),
        .IR4(ir[4]), .IR5(ir[5]), .IR6(ir[6]), .IR7(ir[7]),
        .W1(W1), .W2(W2), .W3(W3),
        .C(C), .Z(Z),
        .DRW(), .PCINC(PCINC), .LPC(), .LAR(), .PCADD(), .ARINC(),
        .SELCTL(), .MEMW(), .STOP(), .LIR(),
        .LDZ(), .LDC(), .CIN(),
        .S0(), .S1(), .S2(), .S3(), .M(),
        .ABUS(), .SBUS(), .MBUS(),
        .SHORT(), .LONG(),
        .SEL0(), .SEL1(), .SEL2(), .SEL3()
    );

    task clear_w;
        begin W1 = 0; W2 = 0; W3 = 0; end
    endtask

    task negedge_t3;
        begin T3 = 1; #1; T3 = 0; #1; end
    endtask

    initial begin
        errors = 0;
        CLR_n = 1;
        T3 = 0; QD = 0;
        SWA = 0; SWB = 0; SWC = 0;
        ir = 8'h00; C = 0; Z = 0;
        clear_w();
        #1; CLR_n = 0; #1; CLR_n = 1;

        // LD opcode in IF/EX + ADD opcode waiting → conservative stall
        ir = 8'h56;
        W1 = 1; #1;
        negedge_t3();
        clear_w();
        ir = 8'h09;
        W1 = 1; #1;
        negedge_t3();
        clear_w();
        ir = 8'h00;
        W1 = 1; #1;
        if (PCINC !== 1'b0) begin
            $display("FAIL board-safe: PCINC should be 0 during stall");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: tb_pipe_board OK");
        else
            $display("FAIL: tb_pipe_board errors=%0d", errors);

        if (errors != 0)
            $fatal(1);
        $finish;
    end

endmodule
