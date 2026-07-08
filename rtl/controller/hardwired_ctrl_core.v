// Combinational control decode — shared by sequential and pipeline wrappers.
// Reference: docs/course/*-图片-43.jpg

`timescale 1ns / 1ps

module hardwired_ctrl_core (
    input  wire [2:0] mode,
    input  wire [3:0] op,
    input  wire       w1,
    input  wire       w2,
    input  wire       w3,
    input  wire       c,
    input  wire       z,
    input  wire       sto,

    output reg        drw,
    output reg        pcinc,
    output reg        lpc,
    output reg        lar,
    output reg        pcadd,
    output reg        arinc,
    output reg        selctl,
    output reg        memw,
    output reg        stop,
    output reg        lir,
    output reg        ldz,
    output reg        ldc,
    output reg        cin,
    output reg        s0,
    output reg        s1,
    output reg        s2,
    output reg        s3,
    output reg        m,
    output reg        abus,
    output reg        sbus,
    output reg        mbus,
    output reg        short_sig,
    output reg        long_sig,
    output reg        sel0,
    output reg        sel1,
    output reg        sel2,
    output reg        sel3,
    output reg        ssto
);

    localparam RUN    = 3'b000;
    localparam WR_REG = 3'b100;
    localparam RD_REG = 3'b011;
    localparam RD_MEM = 3'b010;
    localparam WR_MEM = 3'b001;

    localparam ADD = 4'b0001, SUB = 4'b0010, AND_ = 4'b0011, INC = 4'b0100;
    localparam LD  = 4'b0101, ST  = 4'b0110, JC  = 4'b0111, JZ  = 4'b1000;
    localparam JMP = 4'b1001, STP = 4'b1110;

    always @(*) begin
        drw      = 1'b0;
        pcinc    = 1'b0;
        lpc      = 1'b0;
        lar      = 1'b0;
        pcadd    = 1'b0;
        arinc    = 1'b0;
        selctl   = 1'b0;
        memw     = 1'b0;
        stop     = 1'b0;
        lir      = 1'b0;
        ldz      = 1'b0;
        ldc      = 1'b0;
        cin      = 1'b0;
        s0       = 1'b0;
        s1       = 1'b0;
        s2       = 1'b0;
        s3       = 1'b0;
        m        = 1'b0;
        abus     = 1'b0;
        sbus     = 1'b0;
        mbus     = 1'b0;
        short_sig = 1'b0;
        long_sig = 1'b0;
        sel0     = 1'b0;
        sel1     = 1'b0;
        sel2     = 1'b0;
        sel3     = 1'b0;
        ssto     = 1'b0;

        case (mode)
        RUN: begin
            if (w1) begin
                lir   = 1'b1;
                pcinc = 1'b1;
            end else if (w2) begin
                case (op)
                ADD: begin
                    m = 1'b0; s3 = 1'b1; s2 = 1'b0; s1 = 1'b0; s0 = 1'b1; cin = 1'b1;
                    abus = 1'b1; drw = 1'b1; ldz = 1'b1; ldc = 1'b1;
                end
                SUB: begin
                    m = 1'b0; s3 = 1'b0; s2 = 1'b1; s1 = 1'b1; s0 = 1'b0; cin = 1'b0;
                    abus = 1'b1; drw = 1'b1; ldz = 1'b1; ldc = 1'b1;
                end
                AND_: begin
                    m = 1'b1; s3 = 1'b1; s2 = 1'b0; s1 = 1'b1; s0 = 1'b1;
                    abus = 1'b1; drw = 1'b1; ldz = 1'b1;
                end
                INC: begin
                    m = 1'b0; s3 = 1'b0; s2 = 1'b0; s1 = 1'b0; s0 = 1'b0; cin = 1'b0;
                    abus = 1'b1; drw = 1'b1; ldz = 1'b1; ldc = 1'b1;
                end
                LD: begin
                    m = 1'b1; s3 = 1'b1; s2 = 1'b0; s1 = 1'b1; s0 = 1'b0;
                    abus = 1'b1; lar = 1'b1; long_sig = 1'b1;
                end
                ST: begin
                    m = 1'b1; s3 = 1'b1; s2 = 1'b1; s1 = 1'b1; s0 = 1'b1;
                    abus = 1'b1; lar = 1'b1; long_sig = 1'b1;
                end
                JC: if (c) pcadd = 1'b1;
                JZ: if (z) pcadd = 1'b1;
                JMP: begin
                    m = 1'b1; s3 = 1'b1; s2 = 1'b1; s1 = 1'b1; s0 = 1'b1;
                    abus = 1'b1; lpc = 1'b1;
                end
                STP: stop = 1'b1;
                default: ;
                endcase
            end else if (w3) begin
                case (op)
                LD: begin
                    mbus = 1'b1; drw = 1'b1;
                end
                ST: begin
                    m = 1'b1; s3 = 1'b1; s2 = 1'b0; s1 = 1'b1; s0 = 1'b0;
                    abus = 1'b1; memw = 1'b1;
                end
                default: ;
                endcase
            end
        end

        WR_REG: begin
            if (w1) begin
                sbus = 1'b1; selctl = 1'b1; drw = 1'b1; stop = 1'b1;
                if (!sto) begin
                    sel3 = 1'b0; sel2 = 1'b0; sel1 = 1'b1; sel0 = 1'b1;
                end else begin
                    sel3 = 1'b1; sel2 = 1'b0; sel1 = 1'b0; sel0 = 1'b1;
                end
            end else if (w2) begin
                sbus = 1'b1; selctl = 1'b1; drw = 1'b1; stop = 1'b1;
                if (!sto) begin
                    sel3 = 1'b0; sel2 = 1'b1; sel1 = 1'b0; sel0 = 1'b0;
                    ssto = 1'b1;
                end else begin
                    sel3 = 1'b1; sel2 = 1'b1; sel1 = 1'b1; sel0 = 1'b0;
                end
            end
        end

        RD_REG: begin
            if (w1) begin
                selctl = 1'b1; stop = 1'b1;
                sel3 = 1'b0; sel2 = 1'b0; sel1 = 1'b0; sel0 = 1'b1;
            end else if (w2) begin
                selctl = 1'b1; stop = 1'b1;
                sel3 = 1'b1; sel2 = 1'b0; sel1 = 1'b1; sel0 = 1'b1;
            end
        end

        RD_MEM: begin
            if (w1) begin
                selctl = 1'b1; stop = 1'b1; short_sig = 1'b1;
                if (!sto) begin
                    sbus = 1'b1; lar = 1'b1; ssto = 1'b1;
                end else begin
                    mbus = 1'b1; arinc = 1'b1;
                end
            end
        end

        WR_MEM: begin
            if (w1) begin
                selctl = 1'b1; stop = 1'b1; short_sig = 1'b1;
                if (!sto) begin
                    sbus = 1'b1; lar = 1'b1; ssto = 1'b1;
                end else begin
                    sbus = 1'b1; memw = 1'b1; arinc = 1'b1;
                end
            end
        end

        default: ;
        endcase
    end

endmodule
