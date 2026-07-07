// Manual STO phase testbench

`timescale 1ns / 1ps

module tb_manual_sto;

    reg        CLR_n;
    reg        T3;
    reg        SWA, SWB, SWC;
    reg        W1, W2;
    wire       STO;
    integer    errors;

    manual_sto dut (
        .CLR_n(CLR_n),
        .T3(T3),
        .SWA(SWA),
        .SWB(SWB),
        .SWC(SWC),
        .W1(W1),
        .W2(W2),
        .STO(STO)
    );

    task tick;
        begin
            T3 = 0; #1;
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

    initial begin
        errors = 0;
        CLR_n = 0; T3 = 0; SWA = 0; SWB = 0; SWC = 0; W1 = 0; W2 = 0;
        tick();
        CLR_n = 1;
        expect1(STO, 1'b0, "reset STO");

        // SW=001 write memory: STO toggles after W1 falls.
        SWC = 0; SWB = 0; SWA = 1;
        W1 = 1; tick();
        expect1(STO, 1'b0, "wrmem W1 high holds STO");
        W1 = 0; tick();
        expect1(STO, 1'b1, "wrmem W1 fall toggles STO");

        // Changing mode resets STO.
        SWC = 0; SWB = 1; SWA = 1;
        tick();
        expect1(STO, 1'b0, "mode change resets STO");

        // SW=100 write register: W1 does not toggle; W2 falling edge does.
        SWC = 1; SWB = 0; SWA = 0;
        W1 = 1; tick();
        W1 = 0; tick();
        expect1(STO, 1'b0, "wrreg W1 fall does not toggle STO");
        W2 = 1; tick();
        W2 = 0; tick();
        expect1(STO, 1'b1, "wrreg W2 fall toggles STO");

        CLR_n = 0; tick();
        expect1(STO, 1'b0, "CLR_n resets STO");

        if (errors == 0)
            $display("PASS: tb_manual_sto all checks OK");
        else
            $display("FAIL: tb_manual_sto errors=%0d", errors);

        if (errors != 0)
            $fatal(1);
        $finish;
    end

endmodule
