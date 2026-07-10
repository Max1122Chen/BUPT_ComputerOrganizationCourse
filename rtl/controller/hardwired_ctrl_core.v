// PL-F01 — RUN-mode decode core (CTL-F01 basic 10 instructions, EX/MEM stages)

`timescale 1ns / 1ps

module hardwired_ctrl_core (
    input  wire [3:0] op,
    input  wire       C,
    input  wire       Z,
    input  wire       stage_ex,
    input  wire       stage_mem,

    output wire       branch_taken,
    output reg        DRW,
    output reg        LPC,
    output reg        LAR,
    output reg        PCADD,
    output reg        MEMW,
    output reg        STOP,
    output reg        LDZ,
    output reg        LDC,
    output reg        CIN,
    output reg        S0,
    output reg        S1,
    output reg        S2,
    output reg        S3,
    output reg        M,
    output reg        ABUS,
    output reg        MBUS,
    output reg        LONG
);

    localparam ADD = 4'b0001, SUB = 4'b0010, AND_ = 4'b0011, INC = 4'b0100;
    localparam LD  = 4'b0101, ST  = 4'b0110, JC  = 4'b0111, JZ  = 4'b1000;
    localparam JMP = 4'b1001, STP = 4'b1110;

    wire jc_taken = (op == JC) && C;
    wire jz_taken = (op == JZ) && Z;
    assign branch_taken = stage_ex && ((op == JMP) || jc_taken || jz_taken);

    always @(*) begin
        DRW    = 1'b0;
        LPC    = 1'b0;
        LAR    = 1'b0;
        PCADD  = 1'b0;
        MEMW   = 1'b0;
        STOP   = 1'b0;
        LDZ    = 1'b0;
        LDC    = 1'b0;
        CIN    = 1'b0;
        S0     = 1'b0;
        S1     = 1'b0;
        S2     = 1'b0;
        S3     = 1'b0;
        M      = 1'b0;
        ABUS   = 1'b0;
        MBUS   = 1'b0;
        LONG   = 1'b0;

        if (stage_ex) begin
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
        end else if (stage_mem) begin
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

endmodule
