`timescale 1ns / 1ps

module fndcontroller(
    input clk,
    input reset,
    input [13:0] fndData,
    output [3:0] fndComm,
    output [7:0] fndFont
    );

    wire w_tick;
    //wire [1:0] w_digit_sel;
    wire [2:0] w_digit_sel;
    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_digit, w_dot;
    wire[9:0] w_count_50;



    clk_div u_clk_div_1khz( //1kHz
    .clk(clk),
    .reset(reset),
    .tick(w_tick)
);
/*
    counter_2bit u_counter_2bit(
    .clk(clk),
    .reset(reset),
    .tick(w_tick),
    .count(w_digit_sel)
);*/

    counter_4bit u_counter_4bit(
    .clk(clk),
    .reset(reset),
    .tick(w_tick),
    .count(w_digit_sel)
);

    counter_50bit u_counter_50bit(
    .clk(clk),
    .reset(reset),
    .tick(w_tick),
    .count(w_count_50)
);

/*
    decoder_2x4 u_decoder_2x4(
    .x(w_digit_sel),
    .y(fndComm)
);
*/
    decoder_3x8 u_decoder_3x8(
    .x(w_digit_sel),
    .y(fndComm)
);


    digit_splitter u_digit_splitter(
    .fndData(fndData),
    .digit_1000(w_digit_1000),
    .digit_100(w_digit_100),
    .digit_10(w_digit_10),
    .digit_1(w_digit_1)
);

/*
    MUX_4X1 u_MUX_4X1(
    .sel(w_digit_sel),
    .x0(w_digit_1),
    .x1(w_digit_10),
    .x2(w_digit_100),
    .x3(w_digit_1000),
    .y(w_digit)
);*/

    comparator u_compartor(
    .count_50(w_count_50),
    .dot(w_dot)
);

    MUX_3X8 u_MUX_3X8(
    .sel(w_digit_sel),
    .x0(w_digit_1),
    .x1(w_digit_10),
    .x2(w_digit_100),
    .x3(w_digit_1000),
    .x4(4'ha),
    .x5(w_dot)/*(w_dot)*/,
    .x6(4'ha),
    .x7(4'ha),
    .y(w_digit)
);


    bcd2seg u_bcd2seg(
    .bcd(w_digit),
    .seg(fndFont)
);

endmodule

module clk_div( //1kHz  
    input clk,
    input reset,
    output reg tick
);

    reg [$clog2(100_000)-1:0] div_counter;

    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                div_counter <= 0;
                tick <= 1'b0;
            end else begin
                if(div_counter == 100_000 -1) begin
                    div_counter <= 0;
                    tick <= 1'b1;
                end else begin
                    div_counter <= div_counter + 1;
                    tick <= 1'b0;
                end
            end
        end
endmodule 


module counter_2bit(
    input clk,
    input reset,
    input tick,
    output reg [1:0] count
);
    always@(posedge clk, posedge reset) begin
        if(reset) begin
            count <= 0;
        end else begin
            if(tick) begin
                count <= count + 1;
            end
        end
    end
endmodule

module counter_4bit(
    input clk,
    input reset,
    input tick,
    output reg [2:0] count
);
    always@(posedge clk, posedge reset) begin
        if(reset) begin
            count <= 0;
        end else begin
            if(tick) begin
                count <= count + 1;
            end
        end
    end
endmodule

module counter_50bit(
    input clk,
    input reset,
    input tick,
    output reg [9:0] count
);
    always@(posedge clk, posedge reset) begin
        if(reset) begin
            count <= 0;
        end else begin
            if(tick) begin
                if(count == 999) begin
                    count <= 0;
                end else begin
                    count <= count + 1;
                end
            end
        end
    end
endmodule


module decoder_2x4(
    input [1:0] x,
    output reg [3:0] y
);
    always@(*) begin
        case(x)
            2'b00 : y = 4'b1110;
            2'b01 : y = 4'b1101;
            2'b10 : y = 4'b1011;
            2'b11 : y = 4'b0111;
            default y = 4'hf;
        endcase
    end
endmodule

module decoder_3x8(
    input [2:0] x,
    output reg [3:0] y
);
    always@(*) begin
        case(x)
            3'b000 : y = 4'b1110;
            3'b001 : y = 4'b1101;
            3'b010 : y = 4'b1011;
            3'b011 : y = 4'b0111;
            3'b100 : y = 4'b1110;
            3'b101 : y = 4'b1101;
            3'b110 : y = 4'b1011;
            3'b111 : y = 4'b0111;
            default y = 4'hf;
        endcase
    end
endmodule

module digit_splitter(
    input [13:0] fndData,
    output [3:0] digit_1000,
    output [3:0] digit_100,
    output [3:0] digit_10,
    output [3:0] digit_1
);
    assign digit_1 = fndData % 10;
    assign digit_10 = fndData / 10 % 10;
    assign digit_100 = fndData / 100 % 10;
    assign digit_1000 = fndData / 1000 % 10;
endmodule

module MUX_4X1(
    input [1:0] sel,
    input [3:0] x0,
    input [3:0] x1,
    input [3:0] x2,
    input [3:0] x3,
    output reg [3:0] y
);
    always@(*)begin
        case(sel)
            2'b00 : y = x0;
            2'b01 : y = x1;
            2'b10 : y = x2;
            2'b11 : y = x3;
            default : y= 0;
        endcase
    end
endmodule

module MUX_3X8(
    input [2:0] sel,
    input [3:0] x0,
    input [3:0] x1,
    input [3:0] x2,
    input [3:0] x3,
    input [3:0] x4,
    input [3:0] x5,
    input [3:0] x6,
    input [3:0] x7,
    output reg [3:0] y
);
    always@(*)begin
        case(sel)
            3'b000 : y = x0;
            3'b001 : y = x1;
            3'b010 : y = x2;
            3'b011 : y = x3;
            3'b100 : y = x4;
            3'b101 : y = x5;
            3'b110 : y = x6;
            3'b111 : y = x7;
            default : y= 0;
        endcase
    end
endmodule


module bcd2seg (
    input [3:0] bcd,
    output reg [7:0] seg
);
    always @(*) begin // 항상 대상이벤트를 감시
            case(bcd) //case문 안에서 assign문 사용안함
                4'h0: seg = 8'hc0; //8비트의 헥사c0값
                4'h1: seg = 8'hF9;
                4'h2: seg = 8'hA4;
                4'h3: seg = 8'hB0;
                4'h4: seg = 8'h99;
                4'h5: seg = 8'h92;
                4'h6: seg = 8'h82;
                4'h7: seg = 8'hf8;
                4'h8: seg = 8'h80;
                4'h9: seg = 8'h90;
                4'ha: seg = 8'hff;
                4'hb: seg = 8'h7f;
                default: seg = 8'hff;
            endcase
        end
endmodule

module comparator(
    input [9:0] count_50,
    output [3:0] dot
);
    assign dot = (count_50 > 500) ? 4'hb : 4'ha;
endmodule