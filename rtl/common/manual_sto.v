// Manual-mode STO phase toggle (TEC flowchart-43 upper path)
// STO is not pinned on TEC-PLUS image-47; flip after each completed W1
// in write/read memory and write-register modes.

`timescale 1ns / 1ps

module manual_sto (
    input  wire       CLR_n,
    input  wire       T3,
    input  wire       SWA,
    input  wire       SWB,
    input  wire       SWC,
    input  wire       W1,
    input  wire       W2,
    output wire       STO
);

    wire [2:0] sw = {SWC, SWB, SWA};

    // Memory modes use W1-only STO branches; write-register uses W1/W2.
    wire mem_sto_en = (sw == 3'b001) || (sw == 3'b010);
    wire reg_sto_en = (sw == 3'b100);

    reg        sto_r;
    reg        w1_q;
    reg        w2_q;
    reg [2:0]  sw_q;

    assign STO = sto_r;

    always @(posedge T3 or negedge CLR_n) begin
        if (!CLR_n) begin
            sto_r <= 1'b0;
            w1_q  <= 1'b0;
            w2_q  <= 1'b0;
            sw_q  <= 3'b000;
        end else begin
            if (sw != sw_q)
                sto_r <= 1'b0;
            else if (mem_sto_en && w1_q && !W1)
                sto_r <= ~sto_r;
            else if (reg_sto_en && w2_q && !W2)
                sto_r <= ~sto_r;

            w1_q <= W1;
            w2_q <= W2;
            sw_q <= sw;
        end
    end

endmodule
