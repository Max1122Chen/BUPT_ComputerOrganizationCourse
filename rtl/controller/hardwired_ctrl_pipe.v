// TEC-PLUS pipelined hardwired controller (PL-F01)
// RUN: IF/EX/MEM overlap; manual SW modes bypass pipeline (sequential core).

`timescale 1ns / 1ps

module hardwired_ctrl_pipe #(
    // 0 = TEC-PLUS default (IR4–7 only, conservative hazard)
    // 1 = simulation / full IR — fine-grained Rd/Rs compare
    parameter HAZARD_FINE_GRAIN = 1'b0
) (
    input  wire       CLR_n,
    input  wire       T3,
    input  wire       QD,
    input  wire       SWA,
    input  wire       SWB,
    input  wire       SWC,
    input  wire       IR0,
    input  wire       IR1,
    input  wire       IR2,
    input  wire       IR3,
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

    localparam RUN    = 3'b000;
    localparam WR_REG = 3'b100;
    localparam RD_REG = 3'b011;

    wire [2:0] mode = {SWC, SWB, SWA};
    wire [7:0] ir     = {IR7, IR6, IR5, IR4, IR3, IR2, IR1, IR0};
    wire       run_mode = (mode == RUN);

    // --- manual STO (same as sequential wrapper) ---
    reg        STO;
    wire       SSTO_manual;
    wire       clr_reg = ((mode == WR_REG) | (mode == RD_REG)) & STO & W2;

    always @(negedge T3 or negedge CLR_n) begin
        if (!CLR_n)
            STO <= 1'b0;
        else if (clr_reg)
            STO <= 1'b0;
        else if (SSTO_manual)
            STO <= 1'b1;
    end

    // --- pipeline registers & hazards (RUN only) ---
    wire       stall;
    wire       branch_taken;
    wire       flush_ifex;

    wire [7:0] ifex_ir;
    wire [3:0] ifex_op;
    wire [1:0] ifex_rd;
    wire [1:0] ifex_rs;
    wire       ifex_valid;
    wire       ifex_is_mem;
    wire       ifex_is_ld;
    wire       ifex_writes_rd;

    wire [7:0] exmem_ir;
    wire [3:0] exmem_op;
    wire [1:0] exmem_rd;
    wire [1:0] exmem_rs;
    wire       exmem_valid;
    wire       exmem_is_mem;
    wire       exmem_is_ld;
    wire       exmem_writes_rd;

    pipe_regs u_regs (
        .CLR_n          (CLR_n),
        .T3             (T3),
        .W1             (W1 & run_mode),
        .W2             (W2 & run_mode),
        .W3             (W3 & run_mode),
        .stall          (stall),
        .flush_ifex     (flush_ifex),
        .ir_in          (ir),
        .ifex_ir        (ifex_ir),
        .ifex_op        (ifex_op),
        .ifex_rd        (ifex_rd),
        .ifex_rs        (ifex_rs),
        .ifex_valid     (ifex_valid),
        .ifex_is_mem    (ifex_is_mem),
        .ifex_is_ld     (ifex_is_ld),
        .ifex_writes_rd (ifex_writes_rd),
        .exmem_ir       (exmem_ir),
        .exmem_op       (exmem_op),
        .exmem_rd       (exmem_rd),
        .exmem_rs       (exmem_rs),
        .exmem_valid    (exmem_valid),
        .exmem_is_mem   (exmem_is_mem),
        .exmem_is_ld    (exmem_is_ld),
        .exmem_writes_rd(exmem_writes_rd)
    );

    hazard_unit #(
        .HAZARD_FINE_GRAIN(HAZARD_FINE_GRAIN)
    ) u_haz (
        .W2             (W2 & run_mode),
        .c              (C),
        .z              (Z),
        .ifex_op        (ifex_op),
        .ifex_rd        (ifex_rd),
        .ifex_rs        (ifex_rs),
        .ifex_valid     (ifex_valid),
        .exmem_op       (exmem_op),
        .exmem_rd       (exmem_rd),
        .exmem_valid    (exmem_valid),
        .exmem_is_ld    (exmem_is_ld),
        .exmem_writes_rd(exmem_writes_rd),
        .stall          (stall),
        .branch_taken   (branch_taken),
        .flush_ifex     (flush_ifex)
    );

    // --- decode: manual sequential vs pipelined RUN ---
    wire [3:0] manual_op = {IR7, IR6, IR5, IR4};
    wire [3:0] pipe_op;
    wire       pipe_w1;
    wire       pipe_w2;
    wire       pipe_w3;

    assign pipe_w1 = run_mode & W1;
    assign pipe_w2 = run_mode & W2 & exmem_valid;
    assign pipe_w3 = run_mode & W3 & exmem_valid & exmem_is_mem;
    assign pipe_op = exmem_op;

    wire       core_w1 = run_mode ? pipe_w1 : W1;
    wire       core_w2 = run_mode ? pipe_w2 : W2;
    wire       core_w3 = run_mode ? pipe_w3 : W3;
    wire [3:0] core_op = run_mode ? pipe_op : manual_op;

    wire       drw_c, pcinc_c, lpc_c, lar_c, pcadd_c, arinc_c;
    wire       selctl_c, memw_c, stop_c, lir_c;
    wire       ldz_c, ldc_c, cin_c;
    wire       s0_c, s1_c, s2_c, s3_c, m_c;
    wire       abus_c, sbus_c, mbus_c;
    wire       short_c, long_c;
    wire       sel0_c, sel1_c, sel2_c, sel3_c;

    hardwired_ctrl_core u_core (
        .mode     (mode),
        .op       (core_op),
        .w1       (core_w1),
        .w2       (core_w2),
        .w3       (core_w3),
        .c        (C),
        .z        (Z),
        .sto      (STO),
        .drw      (drw_c),
        .pcinc    (pcinc_c),
        .lpc      (lpc_c),
        .lar      (lar_c),
        .pcadd    (pcadd_c),
        .arinc    (arinc_c),
        .selctl   (selctl_c),
        .memw     (memw_c),
        .stop     (stop_c),
        .lir      (lir_c),
        .ldz      (ldz_c),
        .ldc      (ldc_c),
        .cin      (cin_c),
        .s0       (s0_c),
        .s1       (s1_c),
        .s2       (s2_c),
        .s3       (s3_c),
        .m        (m_c),
        .abus     (abus_c),
        .sbus     (sbus_c),
        .mbus     (mbus_c),
        .short_sig(short_c),
        .long_sig (long_c),
        .sel0     (sel0_c),
        .sel1     (sel1_c),
        .sel2     (sel2_c),
        .sel3     (sel3_c),
        .ssto     (SSTO_manual)
    );

    assign DRW    = drw_c;
    assign LPC    = lpc_c;
    assign LAR    = lar_c;
    assign PCADD  = pcadd_c;
    assign ARINC  = arinc_c;
    assign SELCTL = selctl_c;
    assign MEMW   = memw_c;
    assign STOP   = stop_c;
    assign LIR    = lir_c;
    assign LDZ    = ldz_c;
    assign LDC    = ldc_c;
    assign CIN    = cin_c;
    assign S0     = s0_c;
    assign S1     = s1_c;
    assign S2     = s2_c;
    assign S3     = s3_c;
    assign M      = m_c;
    assign ABUS   = abus_c;
    assign SBUS   = sbus_c;
    assign MBUS   = mbus_c;
    assign SEL0   = sel0_c;
    assign SEL1   = sel1_c;
    assign SEL2   = sel2_c;
    assign SEL3   = sel3_c;
    assign LONG   = long_c;

    // RUN: suppress PCINC on stall; SHORT on 2-cycle EX stage
    assign PCINC = run_mode ? (pcinc_c & ~stall) : pcinc_c;
    assign SHORT = run_mode ? (pipe_w2 & ~exmem_is_mem) : short_c;

endmodule
