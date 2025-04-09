`timescale 1ns / 1ps

module alu(
    input wire [3:0] a,      // 첫 번째 입력
    input wire [3:0] b,      // 두 번째 입력
    input wire [1:0] op,     // 연산 코드 (00: ADD, 01: SUB, 10: AND, 11: OR)
    output reg [3:0] result  // 결과 출력
);
    always @(*) begin
        case (op)
            2'b00: result = a + b;   // 덧셈
            2'b01: result = a - b;   // 뺄셈
            2'b10: result = a & b;   // AND 연산
            2'b11: result = a | b;   // OR 연산
            default: result = 4'b0000;
        endcase
    end
endmodule

