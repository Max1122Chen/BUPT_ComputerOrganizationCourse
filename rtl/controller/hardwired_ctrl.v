// TEC-PLUS hardwired controller — sequential (CTL-F01)
// Control reference: docs/course/*-图片-43.jpg

`timescale 1ns / 1ps

module hardwired_ctrl (
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
    input  wire       STO,

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

    wire [2:0] sw      = {SWC, SWB, SWA};
    wire [3:0] ir_op   = {IR7, IR6, IR5, IR4};
    wire       instr_mode = (sw == 3'b000);

    localparam OP_ADD  = 4'b0001;
    localparam OP_SUB  = 4'b0010;
    localparam OP_AND  = 4'b0011;
    localparam OP_INC  = 4'b0100;
    localparam OP_LD   = 4'b0101;
    localparam OP_ST   = 4'b0110;
    localparam OP_JC   = 4'b0111;
    localparam OP_JZ   = 4'b1000;
    localparam OP_JMP  = 4'b1001;
    localparam OP_OUT  = 4'b1010;
    localparam OP_IRET = 4'b1011;
    localparam OP_DI   = 4'b1100;
    localparam OP_EI   = 4'b1101;
    localparam OP_STP  = 4'b1110;

    always @(*) begin
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
        LDZ    = 1'b0;
        LDC    = 1'b0;
        CIN    = 1'b0;
        S0     = 1'b0;
        S1     = 1'b0;
        S2     = 1'b0;
        S3     = 1'b0;
        M      = 1'b0;
        ABUS   = 1'b0;
        SBUS   = 1'b0;
        MBUS   = 1'b0;
        SHORT  = 1'b0;
        LONG   = 1'b0;
        SEL0   = 1'b0;
        SEL1   = 1'b0;
        SEL2   = 1'b0;
        SEL3   = 1'b0;

        if (instr_mode) begin
            if (W1) begin
                // W1 fetch: LIR/PCINC only. Do NOT assert SHORT here — on TEC
                // timing gen, SHORT@W1 skips W2 and stays on W1.
                LIR = 1'b1;
                if (T3)
                    PCINC = 1'b1;
            end

            if (W2) begin
                case (ir_op)
                    OP_ADD: begin
                        S3 = 1'b1; S2 = 1'b0; S1 = 1'b0; S0 = 1'b1;
                        CIN = 1'b1; ABUS = 1'b1; DRW = 1'b1;
                        LDZ = 1'b1; LDC = 1'b1; SELCTL = 1'b1; SHORT = 1'b1;
                    end
                    OP_SUB: begin
                        S3 = 1'b0; S2 = 1'b1; S1 = 1'b1; S0 = 1'b0;
                        ABUS = 1'b1; DRW = 1'b1;
                        LDZ = 1'b1; LDC = 1'b1; SELCTL = 1'b1; SHORT = 1'b1;
                    end
                    OP_AND: begin
                        M = 1'b1; S3 = 1'b1; S2 = 1'b0; S1 = 1'b1; S0 = 1'b1;
                        ABUS = 1'b1; DRW = 1'b1; LDZ = 1'b1; SELCTL = 1'b1; SHORT = 1'b1;
                    end
                    OP_INC: begin
                        S3 = 1'b0; S2 = 1'b0; S1 = 1'b0; S0 = 1'b0;
                        ABUS = 1'b1; DRW = 1'b1;
                        LDZ = 1'b1; LDC = 1'b1; SELCTL = 1'b1; SHORT = 1'b1;
                    end
                    OP_LD: begin
                        M = 1'b1; S3 = 1'b1; S2 = 1'b0; S1 = 1'b1; S0 = 1'b0;
                        ABUS = 1'b1; LAR = 1'b1; LONG = 1'b1; SELCTL = 1'b1;
                    end
                    OP_ST: begin
                        M = 1'b1; S3 = 1'b1; S2 = 1'b1; S1 = 1'b1; S0 = 1'b1;
                        ABUS = 1'b1; LAR = 1'b1; LONG = 1'b1; SELCTL = 1'b1;
                    end
                    OP_JC: begin
                        if (C) PCADD = 1'b1;
                        SHORT = 1'b1;
                    end
                    OP_JZ: begin
                        if (Z) PCADD = 1'b1;
                        SHORT = 1'b1;
                    end
                    OP_JMP: begin
                        M = 1'b1; S3 = 1'b1; S2 = 1'b1; S1 = 1'b1; S0 = 1'b1;
                        ABUS = 1'b1; LPC = 1'b1; SELCTL = 1'b1; SHORT = 1'b1;
                    end
                    OP_OUT: begin
                        ABUS = 1'b1; SELCTL = 1'b1; SHORT = 1'b1;
                    end
                    OP_IRET: begin
                        LPC = 1'b1; SHORT = 1'b1;
                    end
                    OP_DI: begin
                        STOP = 1'b1; SHORT = 1'b1;
                    end
                    OP_EI: begin
                        SHORT = 1'b1;
                    end
                    OP_STP: begin
                        STOP = 1'b1; SHORT = 1'b1;
                    end
                    default: ;
                endcase
            end

            if (W3) begin
                case (ir_op)
                    OP_LD: begin
                        DRW = 1'b1; MBUS = 1'b1; SHORT = 1'b1;
                    end
                    OP_ST: begin
                        M = 1'b1; S3 = 1'b1; S2 = 1'b0; S1 = 1'b1; S0 = 1'b0;
                        ABUS = 1'b1; MEMW = 1'b1; SHORT = 1'b1;
                    end
                    default: ;
                endcase
            end
        end else begin
            case (sw)
                3'b100: begin
                    if (W1) begin
                        SBUS = 1'b1; SELCTL = 1'b1; DRW = 1'b1; STOP = 1'b1;
                        if (!STO) begin
                            SEL1 = 1'b1; SEL0 = 1'b1;
                        end else begin
                            SEL3 = 1'b1; SEL0 = 1'b1;
                        end
                    end
                    if (W2) begin
                        SBUS = 1'b1; SELCTL = 1'b1; DRW = 1'b1; STOP = 1'b1;
                        if (!STO) begin
                            SEL2 = 1'b1;
                        end else begin
                            SEL3 = 1'b1; SEL2 = 1'b1; SEL1 = 1'b1;
                        end
                    end
                end
                3'b011: begin
                    if (W1) begin
                        SEL0 = 1'b1; SELCTL = 1'b1; STOP = 1'b1;
                    end
                    if (W2) begin
                        SEL3 = 1'b1; SEL1 = 1'b1; SEL0 = 1'b1;
                        SELCTL = 1'b1; STOP = 1'b1;
                    end
                end
                3'b010: begin
                    SHORT = 1'b1; SELCTL = 1'b1; STOP = 1'b1;
                    if (W1) begin
                        if (!STO) begin
                            SBUS = 1'b1; LAR = 1'b1;
                        end else begin
                            MBUS = 1'b1; ARINC = 1'b1;
                        end
                    end
                end
                3'b001: begin
                    SHORT = 1'b1; SELCTL = 1'b1; STOP = 1'b1;
                    if (W1) begin
                        if (!STO) begin
                            SBUS = 1'b1; LAR = 1'b1;
                        end else begin
                            SBUS = 1'b1; MEMW = 1'b1; ARINC = 1'b1;
                        end
                    end
                end
                default: ;
            endcase
        end
    end

endmodule
