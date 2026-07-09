// TEC-PLUS hardwired controller — partner baseline replica (T3-clocked STO)
// Source: partner controller.v (docs/状态转移-信号真值表.md)
// STO: SSTO set in combo logic, latched on negedge T3 (after AR LAR load at T3↑).

`timescale 1ns / 1ps

module hardwired_ctrl (
    input  wire       CLR_n,
    input  wire       T3,
    input  wire       QD,       // board pin; not used in partner baseline
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

    output reg        DRW,
    output reg        PCINC,
    output reg        LPC,
    output reg        LAR,
    output reg        PCADD,
    output reg        ARINC,
    output reg        SELCTL,
    output reg        MEMW,
    output reg        STOP,
    output reg        LIR,
    output reg        LDZ,
    output reg        LDC,
    output reg        CIN,
    output reg        S0,
    output reg        S1,
    output reg        S2,
    output reg        S3,
    output reg        M,
    output reg        ABUS,
    output reg        SBUS,
    output reg        MBUS,
    output reg        SHORT,
    output reg        LONG,
    output reg        SEL0,
    output reg        SEL1,
    output reg        SEL2,
    output reg        SEL3
);

    wire [2:0] mode = {SWC, SWB, SWA};
    wire [3:0] op   = {IR7, IR6, IR5, IR4};

    reg        STO;
    reg        SSTO;

    localparam RUN    = 3'b000;
    localparam WR_REG = 3'b100;
    localparam RD_REG = 3'b011;
    localparam RD_MEM = 3'b010;
    localparam WR_MEM = 3'b001;

    localparam ADD = 4'b0001, SUB = 4'b0010, AND_ = 4'b0011, INC = 4'b0100;
    localparam LD  = 4'b0101, ST  = 4'b0110, JC  = 4'b0111, JZ  = 4'b1000;
    localparam JMP = 4'b1001, STP = 4'b1110;

    wire clr_reg = ((mode == WR_REG) | (mode == RD_REG)) & STO & W2;

    always @(negedge T3 or negedge CLR_n) begin
        if (!CLR_n)
            STO <= 1'b0;
        else if (clr_reg)
            STO <= 1'b0;
        else if (SSTO)
            STO <= 1'b1;
    end

    always @(*) begin
        LDZ    = 1'b0;
        LDC    = 1'b0;
        CIN    = 1'b0;
        S0     = 1'b0;
        S1     = 1'b0;
        S2     = 1'b0;
        S3     = 1'b0;
        M      = 1'b0;
        ABUS   = 1'b0;
        DRW    = 1'b0;
        PCINC  = 1'b0;
        LPC    = 1'b0;
        LAR    = 1'b0;
        PCADD  = 1'b0;
        ARINC  = 1'b0;
        SELCTL = 1'b0;
        MEMW   = 1'b0;
        STOP   = 1'b0;
        LIR    = 1'b0;
        SBUS   = 1'b0;
        MBUS   = 1'b0;
        SHORT  = 1'b0;
        LONG   = 1'b0;
        SEL0   = 1'b0;
        SEL1   = 1'b0;
        SEL2   = 1'b0;
        SEL3   = 1'b0;
        SSTO   = 1'b0;

        case (mode)
        RUN: begin
            if (W1) begin
                LIR   = 1'b1;
                PCINC = 1'b1;
            end else if (W2) begin
                case (op)
                ADD: begin
                    M = 1'b0; S3 = 1'b1; S2 = 1'b0; S1 = 1'b0; S0 = 1'b1; CIN = 1'b1;
                    ABUS = 1'b1; DRW = 1'b1; LDZ = 1'b1; LDC = 1'b1;
                end
                SUB: begin
                    M = 1'b0; S3 = 1'b0; S2 = 1'b1; S1 = 1'b1; S0 = 1'b0; CIN = 1'b0;
                    ABUS = 1'b1; DRW = 1'b1; LDZ = 1'b1; LDC = 1'b1;
                end
                AND_: begin
                    M = 1'b1; S3 = 1'b1; S2 = 1'b0; S1 = 1'b1; S0 = 1'b1;
                    ABUS = 1'b1; DRW = 1'b1; LDZ = 1'b1;
                end
                INC: begin
                    M = 1'b0; S3 = 1'b0; S2 = 1'b0; S1 = 1'b0; S0 = 1'b0; CIN = 1'b0;
                    ABUS = 1'b1; DRW = 1'b1; LDZ = 1'b1; LDC = 1'b1;
                end
                LD: begin
                    M = 1'b1; S3 = 1'b1; S2 = 1'b0; S1 = 1'b1; S0 = 1'b0;
                    ABUS = 1'b1; LAR = 1'b1; LONG = 1'b1;
                end
                ST: begin
                    M = 1'b1; S3 = 1'b1; S2 = 1'b1; S1 = 1'b1; S0 = 1'b1;
                    ABUS = 1'b1; LAR = 1'b1; LONG = 1'b1;
                end
                JC: if (C) PCADD = 1'b1;
                JZ: if (Z) PCADD = 1'b1;
                JMP: begin
                    M = 1'b1; S3 = 1'b1; S2 = 1'b1; S1 = 1'b1; S0 = 1'b1;
                    ABUS = 1'b1; LPC = 1'b1;
                end
                STP: STOP = 1'b1;
                default: ;
                endcase
            end else if (W3) begin
                case (op)
                LD: begin
                    MBUS = 1'b1; DRW = 1'b1;
                end
                ST: begin
                    M = 1'b1; S3 = 1'b1; S2 = 1'b0; S1 = 1'b1; S0 = 1'b0;
                    ABUS = 1'b1; MEMW = 1'b1;
                end
                default: ;
                endcase
            end
        end

        WR_REG: begin
            if (W1) begin
                SBUS = 1'b1; SELCTL = 1'b1; DRW = 1'b1; STOP = 1'b1;
                if (!STO) begin
                    SEL3 = 1'b0; SEL2 = 1'b0; SEL1 = 1'b1; SEL0 = 1'b1;
                end else begin
                    SEL3 = 1'b1; SEL2 = 1'b0; SEL1 = 1'b0; SEL0 = 1'b1;
                end
            end else if (W2) begin
                SBUS = 1'b1; SELCTL = 1'b1; DRW = 1'b1; STOP = 1'b1;
                if (!STO) begin
                    SEL3 = 1'b0; SEL2 = 1'b1; SEL1 = 1'b0; SEL0 = 1'b0;
                    SSTO = 1'b1;
                end else begin
                    SEL3 = 1'b1; SEL2 = 1'b1; SEL1 = 1'b1; SEL0 = 1'b0;
                end
            end
        end

        RD_REG: begin
            if (W1) begin
                SELCTL = 1'b1; STOP = 1'b1;
                SEL3 = 1'b0; SEL2 = 1'b0; SEL1 = 1'b0; SEL0 = 1'b1;
            end else if (W2) begin
                SELCTL = 1'b1; STOP = 1'b1;
                SEL3 = 1'b1; SEL2 = 1'b0; SEL1 = 1'b1; SEL0 = 1'b1;
            end
        end

        RD_MEM: begin
            if (W1) begin
                SELCTL = 1'b1; STOP = 1'b1; SHORT = 1'b1;
                if (!STO) begin
                    SBUS = 1'b1; LAR = 1'b1; SSTO = 1'b1;
                end else begin
                    MBUS = 1'b1; ARINC = 1'b1;
                end
            end
        end

        WR_MEM: begin
            if (W1) begin
                SELCTL = 1'b1; STOP = 1'b1; SHORT = 1'b1;
                if (!STO) begin
                    SBUS = 1'b1; LAR = 1'b1; SSTO = 1'b1;
                end else begin
                    SBUS = 1'b1; MEMW = 1'b1; ARINC = 1'b1;
                end
            end
        end

        default: ;
        endcase
    end

endmodule
