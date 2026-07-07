// TEC-PLUS top — hardwired controller only (data path is on the lab board)

`timescale 1ns / 1ps

module top (
    input  wire       CLR_n,
    input  wire       T3,
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

    // STO: internal toggle in manual mem/reg-write modes (no FPGA pin on image-47).
    wire sto;

    manual_sto u_sto (
        .CLR_n (CLR_n),
        .T3    (T3),
        .SWA   (SWA),
        .SWB   (SWB),
        .SWC   (SWC),
        .W1    (W1),
        .STO   (sto)
    );

    hardwired_ctrl u_ctrl (
        .T3     (T3),
        .SWA    (SWA),
        .SWB    (SWB),
        .SWC    (SWC),
        .IR4    (IR4),
        .IR5    (IR5),
        .IR6    (IR6),
        .IR7    (IR7),
        .W1     (W1),
        .W2     (W2),
        .W3     (W3),
        .C      (C),
        .Z      (Z),
        .STO    (sto),
        .DRW    (DRW),
        .PCINC  (PCINC),
        .LPC    (LPC),
        .LAR    (LAR),
        .PCADD  (PCADD),
        .ARINC  (ARINC),
        .SELCTL (SELCTL),
        .MEMW   (MEMW),
        .STOP   (STOP),
        .LIR    (LIR),
        .LDZ    (LDZ),
        .LDC    (LDC),
        .CIN    (CIN),
        .S0     (S0),
        .S1     (S1),
        .S2     (S2),
        .S3     (S3),
        .M      (M),
        .ABUS   (ABUS),
        .SBUS   (SBUS),
        .MBUS   (MBUS),
        .SHORT  (SHORT),
        .LONG   (LONG),
        .SEL0   (SEL0),
        .SEL1   (SEL1),
        .SEL2   (SEL2),
        .SEL3   (SEL3)
    );

endmodule
