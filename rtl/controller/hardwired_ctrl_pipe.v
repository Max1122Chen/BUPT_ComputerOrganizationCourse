// PL-F01 — pipelined hardwired controller (Opcode_cache + allow_ex phase model)
// v1: RUN basic 10 instructions only; no interrupt. Manual modes bypass pipeline.

`timescale 1ns / 1ps

module hardwired_ctrl_pipe (
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
    wire [3:0] op_in = {IR7, IR6, IR5, IR4};

    localparam RUN    = 3'b000;
    localparam WR_REG = 3'b100;
    localparam RD_REG = 3'b011;
    localparam RD_MEM = 3'b010;
    localparam WR_MEM = 3'b001;

    localparam LD = 4'b0101;
    localparam ST = 4'b0110;

    reg        STO;
    reg        SSTO;
    reg        allow_ex;
    reg        deny_ex;
    reg        instr_cached;
    reg [3:0]  opcode_cache;

    wire       pipe_run = (mode == RUN);
    wire       is_mem_op = (opcode_cache == LD) || (opcode_cache == ST);

    wire       stage_ex  = pipe_run && allow_ex && instr_cached;
    wire       stage_mem = pipe_run && !allow_ex && instr_cached;

    wire       core_drw, core_lpc, core_lar, core_pcadd, core_memw, core_stop;
    wire       core_ldz, core_ldc, core_cin;
    wire       core_s0, core_s1, core_s2, core_s3, core_m, core_abus, core_mbus, core_long;
    wire       branch_taken;

    hardwired_ctrl_core u_core (
        .op           (opcode_cache),
        .C            (C),
        .Z            (Z),
        .stage_ex     (stage_ex),
        .stage_mem    (stage_mem),
        .branch_taken (branch_taken),
        .DRW          (core_drw),
        .LPC          (core_lpc),
        .LAR          (core_lar),
        .PCADD        (core_pcadd),
        .MEMW         (core_memw),
        .STOP         (core_stop),
        .LDZ          (core_ldz),
        .LDC          (core_ldc),
        .CIN          (core_cin),
        .S0           (core_s0),
        .S1           (core_s1),
        .S2           (core_s2),
        .S3           (core_s3),
        .M            (core_m),
        .ABUS         (core_abus),
        .MBUS         (core_mbus),
        .LONG         (core_long)
    );

    wire branch_flush = pipe_run && allow_ex && instr_cached && branch_taken;
    wire clr_reg = ((mode == WR_REG) | (mode == RD_REG)) & STO & W2;

    always @(negedge T3 or negedge CLR_n) begin
        if (!CLR_n)
            STO <= 1'b0;
        else if (clr_reg)
            STO <= 1'b0;
        else if (SSTO)
            STO <= 1'b1;
    end

    always @(negedge T3 or negedge CLR_n) begin
        if (!CLR_n) begin
            allow_ex     <= 1'b1;
            deny_ex      <= 1'b0;
            instr_cached <= 1'b0;
            opcode_cache <= 4'b0000;
        end else if (pipe_run) begin
            if (branch_flush) begin
                instr_cached <= 1'b0;
                deny_ex      <= 1'b0;
                allow_ex     <= 1'b1;
            end else if (allow_ex) begin
                if (!instr_cached) begin
                    opcode_cache <= op_in;
                    instr_cached <= 1'b1;
                    allow_ex     <= 1'b1;
                end else if (is_mem_op) begin
                    deny_ex      <= 1'b1;
                    allow_ex     <= 1'b0;
                end else begin
                    opcode_cache <= op_in;
                    allow_ex     <= 1'b1;
                end
            end else begin
                deny_ex      <= 1'b0;
                opcode_cache <= op_in;
                instr_cached <= 1'b1;
                allow_ex     <= 1'b1;
            end
        end
    end

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
        SSTO   = 1'b0;

        if (!pipe_run) begin
            case (mode)
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
        end else begin
            if (allow_ex) begin
                if (instr_cached) begin
                    DRW   = core_drw;
                    LPC   = core_lpc;
                    LAR   = core_lar;
                    PCADD = core_pcadd;
                    MEMW  = core_memw;
                    STOP  = core_stop;
                    LDZ   = core_ldz;
                    LDC   = core_ldc;
                    CIN   = core_cin;
                    S0    = core_s0;
                    S1    = core_s1;
                    S2    = core_s2;
                    S3    = core_s3;
                    M     = core_m;
                    ABUS  = core_abus;
                    MBUS  = core_mbus;
                    LONG  = core_long;
                end
                if (!branch_flush) begin
                    LIR   = 1'b1;
                    PCINC = 1'b1;
                end
            end else if (instr_cached) begin
                DRW   = core_drw;
                LPC   = core_lpc;
                LAR   = core_lar;
                PCADD = core_pcadd;
                MEMW  = core_memw;
                STOP  = core_stop;
                LDZ   = core_ldz;
                LDC   = core_ldc;
                CIN   = core_cin;
                S0    = core_s0;
                S1    = core_s1;
                S2    = core_s2;
                S3    = core_s3;
                M     = core_m;
                ABUS  = core_abus;
                MBUS  = core_mbus;
                LONG  = core_long;
            end
        end
    end

endmodule
