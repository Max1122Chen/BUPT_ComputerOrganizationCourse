// Pipeline register file — IF/EX and EX/MEM (PL-F01)
// EX/MEM holds through W2 (+ W3 for LD/ST); retires at phase end.

`timescale 1ns / 1ps

module pipe_regs (
    input  wire       CLR_n,
    input  wire       T3,
    input  wire       W1,
    input  wire       W2,
    input  wire       W3,
    input  wire       stall,
    input  wire       flush_ifex,
    input  wire [7:0] ir_in,

    output reg [7:0]  ifex_ir,
    output reg [3:0]  ifex_op,
    output reg [1:0]  ifex_rd,
    output reg [1:0]  ifex_rs,
    output reg        ifex_valid,
    output reg        ifex_is_mem,
    output reg        ifex_is_ld,
    output reg        ifex_writes_rd,

    output reg [7:0]  exmem_ir,
    output reg [3:0]  exmem_op,
    output reg [1:0]  exmem_rd,
    output reg [1:0]  exmem_rs,
    output reg        exmem_valid,
    output reg        exmem_is_mem,
    output reg        exmem_is_ld,
    output reg        exmem_writes_rd
);

    function automatic [3:0] f_op;
        input [7:0] ir;
        begin
            f_op = ir[7:4];
        end
    endfunction

    function automatic f_is_mem;
        input [3:0] op;
        begin
            f_is_mem = (op == 4'b0101) | (op == 4'b0110);
        end
    endfunction

    function automatic f_is_ld;
        input [3:0] op;
        begin
            f_is_ld = (op == 4'b0101);
        end
    endfunction

    function automatic f_writes_rd;
        input [3:0] op;
        begin
            f_writes_rd = (op == 4'b0001) | (op == 4'b0010) | (op == 4'b0011) |
                          (op == 4'b0100) | (op == 4'b0101);
        end
    endfunction

    wire [3:0] in_op = f_op(ir_in);

    always @(negedge T3 or negedge CLR_n) begin
        if (!CLR_n) begin
            ifex_valid      <= 1'b0;
            exmem_valid     <= 1'b0;
            ifex_ir         <= 8'h00;
            ifex_op         <= 4'h0;
            exmem_ir        <= 8'h00;
            exmem_op        <= 4'h0;
        end else if (W2 && flush_ifex) begin
            ifex_valid <= 1'b0;
        end else if (W2 && exmem_valid && !exmem_is_mem) begin
            exmem_valid <= 1'b0;
        end else if (W3 && exmem_valid && exmem_is_mem) begin
            exmem_valid <= 1'b0;
        end else if (W1) begin
            if (flush_ifex) begin
                ifex_valid <= 1'b0;
            end else if (!stall) begin
                if (!exmem_valid && ifex_valid) begin
                    exmem_ir        <= ifex_ir;
                    exmem_op        <= ifex_op;
                    exmem_rd        <= ifex_rd;
                    exmem_rs        <= ifex_rs;
                    exmem_valid     <= 1'b1;
                    exmem_is_mem    <= ifex_is_mem;
                    exmem_is_ld     <= ifex_is_ld;
                    exmem_writes_rd <= ifex_writes_rd;
                end

                ifex_ir        <= ir_in;
                ifex_op        <= in_op;
                ifex_rd        <= ir_in[3:2];
                ifex_rs        <= ir_in[1:0];
                ifex_valid     <= 1'b1;
                ifex_is_mem    <= f_is_mem(in_op);
                ifex_is_ld     <= f_is_ld(in_op);
                ifex_writes_rd <= f_writes_rd(in_op);
            end
        end
    end

endmodule
