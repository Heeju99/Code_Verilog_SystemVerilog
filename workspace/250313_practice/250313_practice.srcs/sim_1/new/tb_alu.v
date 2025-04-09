`timescale 1ns / 1ps
module tb_alu();

    reg [3:0] a, b;      // 두 번째 입력
    reg [1:0] op;     // 연산 코드 (00: ADD, 01: SUB, 10: AND, 11: OR)
    wire [3:0] result;  // 결과 출력

    alu dut(
        .a(a),      // 첫 번째 입력
        .b(b),      // 두 번째 입력
        .op(op),     // 연산 코드 (00: ADD, 01: SUB, 10: AND, 11: OR)
        .result(result)  // 결과 출력
);
    // taskt 정의 : 특정 연산을 테스트하고 결과를 출력
    task test_alu;
        input[3:0] test_a;
        input[3:0] test_b;
        input[3:0] test_op;
        input[3:0] expected;

        begin
             a = test_a;
             b = test_b;
             op = test_op;

             if (result === expected) begin
                $diplay("Pass : a= %h, b = %h, op=%b -> result = %h", test_a, test_b, test_op, result, expected);
             end else begin
                $diplay("Fail : a= %h, b = %h, op=%b -> result = %h (expected %h)",
                            test_a, test_b, test_op, result, expected);
             end
        end
    endtask

    initial begin
        $display("Starting ALU Test");
        $monitor("Time = %0t | a = %h | b = %h | op = %b | result = %h", $time, a, b, op, result);
        test_alu(4'h3, 4'h5, 2'b00 , 4'h8);
        test_alu(4'h7, 4'h2, 2'b01 , 4'h5);
        test_alu(4'hF, 4'hA, 2'b10 , 4'hA);
        test_alu(4'hc, 4'h3, 2'b11 , 4'hF);
        $display("ALU Test Completed");
        $finish;
    end
endmodule
