// TEC-PLUS hardwired controller — sequential wrapper (CTL-F01)
// STO latched on negedge T3; decode in hardwired_ctrl_core.

`timescale 1ns / 1ps

module hardwired_ctrl (
    input  wire       CLR_n,
    input  wire       T3,
    input  wire       QD,
    input  wire       SWA,
    input  wire       SWB,
    input  wire       SWC,
    input  wire       IR4,
    input  wire       IR5,
    input  wire       IR6,
    input  wire       IR7,
    input  wire       W1,
    input  wire       W2,
    input  wire       W3,
    input  wire       C,
    input  wire       Z,

    output wire       DRW,
    output wire       PCINC,
    output wire       LPC,
    output wire       LAR,
    output wire       PCADD,
    output wire       ARINC,
    output wire       SELCTL,
    output wire       MEMW,
    output wire       STOP,
    output wire       LIR,
    output wire       LDZ,
    output wire       LDC,
    output wire       CIN,
    output wire       S0,
    output wire       S1,
    output wire       S2,
    output wire       S3,
    output wire       M,
    output wire       ABUS,
    output wire       SBUS,
    output wire       MBUS,
    output wire       SHORT,
    output wire       LONG,
    output wire       SEL0,
    output wire       SEL1,
    output wire       SEL2,
    output wire       SEL3
);

    wire [2:0] mode = {SWC, SWB, SWA};
    wire [3:0] op   = {IR7, IR6, IR5, IR4};

    localparam WR_REG = 3'b100;
    localparam RD_REG = 3'b011;

    reg        STO;
    wire       SSTO;
    wire       clr_reg = ((mode == WR_REG) | (mode == RD_REG)) & STO & W2;

    always @(negedge T3 or negedge CLR_n) begin
        if (!CLR_n)
            STO <= 1'b0;
        else if (clr_reg)
            STO <= 1'b0;
        else if (SSTO)
            STO <= 1'b1;
    end

    hardwired_ctrl_core u_core (
        .mode     (mode),
        .op       (op),
        .w1       (W1),
        .w2       (W2),
        .w3       (W3),
        .c        (C),
        .z        (Z),
        .sto      (STO),
        .drw      (DRW),
        .pcinc    (PCINC),
        .lpc      (LPC),
        .lar      (LAR),
        .pcadd    (PCADD),
        .arinc    (ARINC),
        .selctl   (SELCTL),
        .memw     (MEMW),
        .stop     (STOP),
        .lir      (LIR),
        .ldz      (LDZ),
        .ldc      (LDC),
        .cin      (CIN),
        .s0       (S0),
        .s1       (S1),
        .s2       (S2),
        .s3       (S3),
        .m        (M),
        .abus     (ABUS),
        .sbus     (SBUS),
        .mbus     (MBUS),
        .short_sig(SHORT),
        .long_sig (LONG),
        .sel0     (SEL0),
        .sel1     (SEL1),
        .sel2     (SEL2),
        .sel3     (SEL3),
        .ssto     (SSTO)
    );

endmodule
