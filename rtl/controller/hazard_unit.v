// Pipeline hazard detection — stall and branch flush (PL-F01)
//
// HAZARD_FINE_GRAIN=1: compare Rd/Rs (sim / full IR7–0)
// HAZARD_FINE_GRAIN=0: opcode-only conservative stall (TEC-PLUS board: IR4–7 only)

`timescale 1ns / 1ps

module hazard_unit #(
    parameter HAZARD_FINE_GRAIN = 1'b0
) (
    input  wire       W2,
    input  wire       c,
    input  wire       z,

    input  wire [3:0] ifex_op,
    input  wire [1:0] ifex_rd,
    input  wire [1:0] ifex_rs,
    input  wire       ifex_valid,

    input  wire [3:0] exmem_op,
    input  wire [1:0] exmem_rd,
    input  wire       exmem_valid,
    input  wire       exmem_is_ld,
    input  wire       exmem_writes_rd,

    output wire       stall,
    output wire       branch_taken,
    output wire       flush_ifex
);

    localparam ADD = 4'b0001, SUB = 4'b0010, AND_ = 4'b0011;

    wire ifex_is_rr = (ifex_op == ADD) | (ifex_op == SUB) | (ifex_op == AND_);

    wire load_use_fine = exmem_valid & exmem_is_ld & ifex_valid &
                         ((exmem_rd == ifex_rs) | (ifex_is_rr & (exmem_rd == ifex_rd)));

    wire raw_fine = exmem_valid & exmem_writes_rd & ifex_valid & ifex_is_rr &
                    (exmem_rd == ifex_rs);

    // Board: cannot see IR3–0 on FPGA; stall conservatively from opcode class only.
    wire load_use_safe = exmem_valid & exmem_is_ld & ifex_valid;
    wire raw_safe      = exmem_valid & exmem_writes_rd & ifex_valid & ifex_is_rr;

    wire load_use = HAZARD_FINE_GRAIN ? load_use_fine : load_use_safe;
    wire raw_hazard = HAZARD_FINE_GRAIN ? raw_fine : raw_safe;

    assign stall = load_use | raw_hazard;

    assign branch_taken = W2 & exmem_valid & (
        ((exmem_op == 4'b0111) & c) |
        ((exmem_op == 4'b1000) & z) |
        (exmem_op == 4'b1001));

    assign flush_ifex = branch_taken;

endmodule
