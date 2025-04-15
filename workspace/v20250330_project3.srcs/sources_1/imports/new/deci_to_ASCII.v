`timescale 1ns / 1ps

module deci_to_ASCII(
    input [3:0] data_digit,
    output reg [7:0] data_ASCII
);

    always @(*) begin
        data_ASCII = 8'h00;
        case (data_digit)
            4'h0: data_ASCII = 8'h30;
            4'h1: data_ASCII = 8'h31;
            4'h2: data_ASCII = 8'h32;
            4'h3: data_ASCII = 8'h33;
            4'h4: data_ASCII = 8'h34;
            4'h5: data_ASCII = 8'h35;
            4'h6: data_ASCII = 8'h36;
            4'h7: data_ASCII = 8'h37;
            4'h8: data_ASCII = 8'h38;
            4'h9: data_ASCII = 8'h39;
        endcase
    end
endmodule
