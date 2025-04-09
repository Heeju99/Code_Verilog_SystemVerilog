`timescale 1ns / 1ps

module calculator (
    input [7:0] a,
    input [7:0] b,
    input [1:0] seg_cel,
    output [3:0] seg_comm,
    output [7:0] seg,
    output carry_led
);
    wire [7:0]sum2seg;
    adder_8bit u_adder_8bit (
        .a(a),
        .b(b),
        .c(carry_led),
        .s(sum2seg)
    );

    fnd_controller u_fnd_controller (
        .bcd(sum2seg),
        .seg_comm(seg_comm),
        .seg(seg),
        .btn(seg_cel)
    );
endmodule

module adder_8bit(
    input [7:0] a,
    input [7:0] b,
    output c,
    output [7:0] s
    );
    wire w_cin;
    adder_4bit U_4bit_adder0(
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(1'b0),
        .c(w_cin),
        .s(s[3:0])
    );
    adder_4bit U_4bit_adder1(
        .a(a[7:4]),
        .b(b[7:4]),
        .c(c),
        .cin(w_cin),
        .s(s[7:4])
    );
endmodule

module adder_4bit (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output c,
    output [3:0] s
);
    wire [3:0] w_c;
    full_adder U_full_adder0 (
        .a  (a[0]),
        .b  (b[0]),
        .cin(1'b0),   //1bit binary 0
        .s  (s[0]),
        .c  (w_c[0])
    );
    full_adder U_full_adder1 (
        .a  (a[1]),
        .b  (b[1]),
        .cin(w_c[0]),
        .c  (w_c[1]),
        .s  (s[1])
    );
    full_adder U_full_adder2 (
        .a  (a[2]),
        .b  (b[2]),
        .cin(w_c[1]),
        .c  (w_c[2]),
        .s  (s[2])
    );
    full_adder U_full_adder3 (
        .a  (a[3]),
        .b  (b[3]),
        .cin(w_c[2]),
        .c  (c),
        .s  (s[3])
    );
endmodule

module full_adder (
    input  a,
    input  b,
    input  cin,
    output c,
    output s
);
    wire w_s, c1, c2;
    half_adder U_half_adder0 (
        .a(a),
        .b(b),
        .c(c1),
        .s(w_s)
    );
    half_adder U_half_adder1 (
        .a(w_s),
        .b(cin),
        .c(c2),
        .s(s)
    );
    assign c = c1 | c2;
endmodule

module half_adder (
    input  a,
    input  b,
    output c,
    output s
);
    //assign s = a ^ b;
    //assign c = a & b;
    //Gate Primitive 방식, verilog lib
    xor (s, a, b);  //(출력,입력0,입력1,.....)
    and (c, a, b);  //(출력,입력0,입력1....)
endmodule
