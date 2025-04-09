`timescale 1ns / 1ps

module fnd(
    input clk,
    input reset,
    input [13:0] bcd,
    output [7:0] seg,
    output [3:0] seg_comm
    );

    wire w_clk_100hz;
    wire [1:0] w_sel;
    wire [3:0] w_digit_1000,w_digit_100,w_digit_10,w_digit_1;
    wire [3:0] w_bcd;


    clk_div_100 u_clk_div_100(  //10_000_000
    .clk(clk),
    .reset(reset),
    .clk_100hz(w_clk_100hz)
);

    counter_4bit u_counter_4bit(
    .clk(w_clk_100hz),
    .reset(reset),
    .o_sel(w_sel)
);

    digit_splitter u_digit_splitter(
    .bcd(bcd),
    .digit_1000(w_digit_1000), 
    .digit_100(w_digit_100),
    .digit_10(w_digit_10),
    .digit_1(w_digit_1)
);

    decoder_2x4 u_decoder_2x4(
    .sel(w_sel),
    .seg_comm(seg_comm)
);

    MUX_4X1 u_MUX_4X1(
    .sel(w_sel),
    .x0(w_digit_1),
    .x1(w_digit_10),
    .x2(w_digit_100),
    .x3(w_digit_1000),
    .y(w_bcd)
);

    bcd2seg u_bcd_2seg(
    .bcd(w_bcd),
    .seg(seg)
);
endmodule


module counter_4bit(
    input clk,
    input reset,
    output [1:0] o_sel
);
    reg [1:0] r_counter;
    assign o_sel = r_counter;

    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                r_counter <= 0;
            end else begin
                r_counter <= r_counter + 1;
            end
        end
endmodule

module bcd2seg(
    input [3:0] bcd,
    output reg [7:0] seg
);
    always@(*) begin
        case(bcd)
            4'h0: seg = 8'hc0;
            4'h1: seg = 8'hf9;
            4'h2: seg = 8'ha4;
            4'h3: seg = 8'hb0;
            4'h4: seg = 8'h99;
            4'h5: seg = 8'h92;
            4'h6: seg = 8'h82;
            4'h7: seg = 8'hf8;
            4'h8: seg = 8'h80;
            4'h9: seg = 8'h90;
            default : seg = 8'hff;
        endcase
    end
endmodule

module digit_splitter(
    input [13:0] bcd,
    output [3:0] digit_1000, 
    output [3:0] digit_100,
    output [3:0] digit_10,
    output [3:0] digit_1
);
    assign digit_1 = bcd % 10;
    assign digit_10 = bcd / 10 % 10;
    assign digit_100 = bcd / 100 % 10;
    assign digit_1000 = bcd / 1000 % 10;
endmodule


module MUX_4X1(
    input [1:0] sel,
    input [3:0] x0,
    input [3:0] x1,
    input [3:0] x2,
    input [3:0] x3,
    output reg [3:0] y
);
    always@(*) begin
        case(sel)
            2'b00 : y = x0;
            2'b01 : y = x1;
            2'b10 : y = x2;
            2'b11 : y = x3;
            default : y = 0;
        endcase
    end
endmodule

module decoder_2x4(
    input [1:0] sel,
    output reg [3:0] seg_comm
);
    always@(*)begin
        case(sel)
            2'b00 : seg_comm = 4'b1110;
            2'b01 : seg_comm = 4'b1101;
            2'b10 : seg_comm = 4'b1011;
            2'b11 : seg_comm = 4'b0111;
            default : seg_comm = 4'hf;
        endcase
    end
endmodule



module clk_div_100(  //10_000_000
    input clk,
    input reset,
    output clk_100hz
);

    parameter FCOUNT = 100_000; 
    reg[$clog2(FCOUNT -1):0] count_reg, count_next;
    reg clk_100_reg, clk_100_next;

    assign clk_100hz = clk_100_reg;
    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                count_reg <= 0;
                clk_100_reg <= 0;
            end
            else begin
                count_reg <= count_next;
                clk_100_reg <= clk_100_next;
            end
        end
    
    always@(*) begin
        count_next = count_reg;
        clk_100_next = clk_100_reg;
        if(count_reg == FCOUNT -1) begin
            clk_100_next = 1;
            count_next = 0;
        end else begin
            count_next = count_reg + 1;
            clk_100_next = 0;
        end
    end
endmodule