`timescale 1ns / 1ps

module tb_adder_4bit();
    reg [7:0] a, b;
    wire c;
    wire [7:0] s;

    adder_8bit dut(
        .a(a),
        .b(b),
        .c(c),
        .s(s)
    );
    integer i, j;
    initial begin
            a = 8'h0; b = 8'h0;
            #10;
            for(i = 1; i < 256; i = i*4)begin
                a = i;
                #10;
                for(j = 1; j < 256; j = j*4)begin
                    b = j;
                    #10;
                end
            end
            #10;
    end
endmodule