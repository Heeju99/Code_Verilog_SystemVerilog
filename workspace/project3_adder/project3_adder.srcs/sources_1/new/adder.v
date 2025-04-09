`timescale 1ns / 1ps

module adder_4bit (
    input [0:3] a,
    input [0:3] b,
    output cout,
    output [0:3] s
);

    wire c1, c2, c3;

    half_adder u_half_adder1 (
        .a(a[0]),
        .b(b[0]),
        .c(c1),
        .s(s[0])
    );


    full_adder u_full_adder2 (
        .a  (a[1]),
        .b  (b[1]),
        .cin(c1),
        .c  (c2),
        .s  (s[1])

    );

    full_adder u_full_adder3 (
        .a  (a[2]),
        .b  (b[2]),
        .cin(c2),
        .c  (c3),
        .s  (s[2])

    );

    full_adder u_full_adder4 (
        .a  (a[3]),
        .b  (b[3]),
        .cin(c3),
        .c  (cout),
        .s  (s[3])
    );

endmodule


module full_adder (
    input  a,
    input  b,
    input  cin,
    output s,
    output c
);

    wire w_s;  // wiring U_HA1 out s to U_HA2 in a 
    wire w_c1, w_c2;  // wiring U_HA1 out c = w_c1 & U_HA2 out c = w_c2 

    assign c = w_c1 | w_c2;

    half_adder U_HA1 (
        .a(a),
        .b(b),
        .c(w_c1),
        .s(w_s)
    );

    half_adder U_HA2 (
        .a(w_s),
        .b(cin),
        .c(w_c2),
        .s(s)
    );

endmodule

module half_adder (
    input  a,
    input  b,
    output s,
    output c
);

    assign s = a ^ b;
    assign c = a & b;

endmodule


