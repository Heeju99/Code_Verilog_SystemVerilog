`timescale 1ns / 1ps

module register(
    input clk,
    input [31:0] d,
    output [31:0] q
    );

    reg [31:0] q_reg; //memory
    assign q = q_reg;

    always@(posedge clk)
        begin
            q_reg <= d;
        end

endmodule