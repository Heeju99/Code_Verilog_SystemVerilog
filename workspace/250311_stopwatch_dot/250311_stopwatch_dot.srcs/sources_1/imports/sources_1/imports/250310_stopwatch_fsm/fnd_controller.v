`timescale 1ns / 1ps

module fnd_controller(
    input clk, reset,
    input switch_mode,
    input [6:0] msec,
    input [5:0] sec,
    input [5:0] min,
    input [4:0] hour,
    output reg [7:0] fnd_font,
    output [3:0] fnd_comm
);
    wire [7:0] font;
    wire w_o_clk_dv;
    wire [2:0] w_seg_sel;
    wire [3:0] w_bcd, w_digit_msec_1, w_digit_msec_10,
               w_digit_sec_1, w_digit_sec_10,
               w_digit_min_1, w_digit_min_10,
               w_digit_hour_1, w_digit_hour_10,
               w_msec_sec, w_min_hour;
    wire clk_100hz;

    clk_divider U_clk_divider(
        .clk(clk), 
        .reset(reset), 
        .o_clk(clk_100hz)
    );
    /*
    counter_4 U_Counter_4(
        .clk(clk_100hz),
        .reset(reset),
        .o_sel(w_seg_sel)
    );*/

    counter_8 U_Counter_8(
        .clk(clk_100hz),
        .reset(reset),
        .o_sel(w_seg_sel)
    );
    /*
    decoder_2x4 U_decoder_2x4(
        .seg_sel(w_seg_sel), 
        .seg_comm(seg_comm)
    );
    */

    decoder_3x8 U_decoder_3x8(
        .seg_sel(w_seg_sel), 
        .seg_comm(fnd_comm)
    );

    digit_splitter #(.BIT_WIDTH(7)) U_msec_ds( //msec 스플리터
        .bcd(msec), 
        .digit_1(w_digit_msec_1), 
        .digit_10(w_digit_msec_10) 
    );
    digit_splitter #(.BIT_WIDTH(6)) U_sec_ds( //sec 스플리터
        .bcd(sec), 
        .digit_1(w_digit_sec_1), 
        .digit_10(w_digit_sec_10) 
    );
    digit_splitter #(.BIT_WIDTH(6)) U_min_ds( //min 스플리터
        .bcd(min), 
        .digit_1(w_digit_min_1), 
        .digit_10(w_digit_min_10) 
    );
    digit_splitter #(.BIT_WIDTH(5)) U_hour_ds( //hour 스플리터
        .bcd(hour), 
        .digit_1(w_digit_hour_1), 
        .digit_10(w_digit_hour_10) 
    );
    /*
    mux_4x1 U_Mux_4x1 (
        .bcd(w_bcd),
        .sel(w_seg_sel),
        .digit_1(w_digit_msec_1),
        .digit_10(w_digit_msec_10),
        .digit_100(w_digit_sec_1),
        .digit_1000(w_digit_sec_10)
    );
    */
    mux_8x1 u_mux_8x1_msecsec(
    .sel(w_seg_sel),
    .x0(w_digit_msec_1), 
    .x1(w_digit_msec_10), 
    .x2(w_digit_sec_1), 
    .x3(w_digit_sec_10), 
    .x4(4'hE), //첫 프레임 출력 + 두번째 프레임 꺼서 dot 표현하기 위함
    .x5(4'hE), 
    .x6(4'hf), 
    .x7(4'hE),
    .y(w_msec_sec)
);
    mux_8x1 u_mux_8x1_minhour(
    .sel(w_seg_sel),
    .x0(w_digit_min_1), 
    .x1(w_digit_min_10), 
    .x2(w_digit_hour_1), 
    .x3(w_digit_hour_10), 
    .x4(4'hE), //첫 프레임 출력 + 두번째 프레임 꺼서 dot 표현하기 위함
    .x5(4'hE), 
    .x6(4'hf), 
    .x7(4'hE),
    .y(w_min_hour)
);
    mux_2x1 u_mux_2x1(
    .switch_mode(switch_mode),
    .a0(w_msec_sec), //8x1 msec sec
    .a1(w_min_hour), //8x1 min hour
    .y(w_bcd)
);

    dp_blink u_clk_div_dp(
    .dp(w_o_clk_dv),
    .clk(clk),
    .rst(reset)
);

    //assign seg_comm = 4'b1110; // segment 0의 자리 on, seg는 anode type
    bcdtoseg U_bcdtoseg(
        .o_clk_dp(w_o_clk_dv),
        .bcd(w_bcd), // [3:0] sum값
        .seg(font)
        );


   /* assign seg_comm = 4'b0000;

     always @(BTN) begin
     case(BTN)
     2'b00: seg_comm = 4'b1110; //0이 켜지는 거래..
     2'b01: seg_comm = 4'b1101;
     2'b10: seg_comm = 4'b1011;
     2'b11: seg_comm = 4'b0111;
     endcase
     end
    */
always @(*) begin
        if(w_seg_sel == 3'b010 || w_seg_sel == 3'b110) begin
            fnd_font = {w_o_clk_dv,font[6:0]};
        end else fnd_font = font;
    end

endmodule

module clk_divider(
    input clk,reset,
    output o_clk
);

    //parameter FCOUNT = 500_000; // 상수화 하기, 변수개념

    // $clog2 : 수를 나타내는데 필요한 비트수 계산
    reg [19:0] r_counter; //20비트 또는 19자리에 $clog2(1_000_000)하면 비트수 계산됨
    reg r_clk;
    
    assign o_clk = r_clk;
    
    always@(posedge clk, posedge reset) begin
        if(reset) begin
        r_counter <= 0; //non-blocking 구문
        r_clk <= 1'b0;
        end else begin
            if(r_counter == 99_999) begin // clock divide 계산, 100Mh -> 100hz
                r_counter <=0; //백만개를 셋을 때 r_counter로 보내기
                r_clk <= 1'b1; // r_clk : 0 -> 1
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0; // r_clk : 0으로 유지
            end
        end
    end

endmodule

module dp_blink (
    input clk,
    input rst,
    output reg dp
);

    initial begin
        dp = 1'b1;
    end

    parameter FCOUNT = 100_000_000;

    reg [$clog2(FCOUNT)-1:0] r_counter;

    always@(posedge clk, posedge rst) begin
        if(rst) begin
            r_counter <= 0;
            dp <= 1'b1;
        end else begin
            if(r_counter == FCOUNT - 1 ) begin // 500mHz
                r_counter <= 0;
                dp <= ~dp;
            end else if(r_counter == FCOUNT - FCOUNT/4) begin
                dp <= ~dp;
                r_counter <= r_counter + 1;
            end else begin
                r_counter <= r_counter + 1;
            end
        end
    end
    
endmodule

/*
module counter_4( //4진 카운터
    input clk, reset,
    output [1:0] o_sel
);

reg [1:0] r_counter;
assign o_sel = r_counter;

always@(posedge clk, posedge reset) begin
    if(reset) begin
        r_counter <= 0;
    end else begin
        r_counter <= r_counter + 1; // 0 1 2 3 0 1 2 3 ... 
        // 조합논리와 다르게 edge만 체크함
        // 조합회로는 항상<=
    end
end
*/

module counter_8( //8진 카운터
    input clk, reset,
    output [2:0] o_sel
);

reg [2:0] r_counter;
assign o_sel = r_counter;

always@(posedge clk, posedge reset) begin
    if(reset) begin
        r_counter <= 0;
    end else begin
        r_counter <= r_counter + 1; // 0 1 2 3 0 1 2 3 ... 
        // 조합논리와 다르게 edge만 체크함
        // 조합회로는 항상<=
    end
end

endmodule

/*
module decoder_2x4 (
    input [1:0] seg_sel,
    output reg [3:0] seg_comm
);

//2x4 decoder
always @(seg_sel) begin
    case(seg_sel)
    2'b00:   seg_comm=4'b1110;
    2'b01:   seg_comm=4'b1101;
    2'b10:   seg_comm=4'b1011;
    2'b11:   seg_comm=4'b0111;
    default: seg_comm=4'b1110;
    endcase
end

endmodule
*/

module decoder_3x8 (
    input [2:0] seg_sel,
    output reg [3:0] seg_comm
);

//2x4 decoder
always @(seg_sel) begin
    case(seg_sel)
    3'b000:   seg_comm=4'b1110;
    3'b001:   seg_comm=4'b1101;
    3'b010:   seg_comm=4'b1011;
    3'b011:   seg_comm=4'b0111;
    3'b100:   seg_comm=4'b1110;
    3'b101:   seg_comm=4'b1101;
    3'b110:   seg_comm=4'b1011;
    3'b111:   seg_comm=4'b0111;
    default:  seg_comm=4'b1111;
    endcase
end

endmodule

module digit_splitter #(parameter BIT_WIDTH = 7)(
    //input [13:0] bcd,
    input [BIT_WIDTH -1:0] bcd,
    output [3:0] digit_1,
    output [3:0] digit_10
);

assign digit_1 = bcd % 10; //10의 1의 자리
assign digit_10 = bcd / 10 % 10; //10의 10의 자리

endmodule

/*
module mux_4x1(
    input [1:0] sel,
    input [3:0] digit_1, digit_10, digit_100, digit_1000,
    output reg [3:0] bcd
);

    // * : input 모두 감시, 아니면 개별 입력 선택할 수 있다.
    // always : 항상 감시한다 @이벤트 이하를 ()의 변화가 있으면, begin-end를 수행하라.
    always @(sel, digit_1, digit_10, digit_100, digit_1000) begin // ,대신 or도 가능함
        case(sel)
            2'b00: bcd = digit_1;
            2'b01: bcd = digit_10;
            2'b10: bcd = digit_100;
            2'b11: bcd = digit_1000;
            default: bcd = 4'bx;
        endcase
    end

endmodule
*/

module mux_8x1(
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

    // * : input 모두 감시, 아니면 개별 입력 선택할 수 있다.
    // always : 항상 감시한다 @이벤트 이하를 ()의 변화가 있으면, begin-end를 수행하라.
    always @(sel, x0, x1, x2, x3, x4, x5, x6, x7) begin // ,대신 or도 가능함
        case(sel)
            3'b000: y = x0;
            3'b001: y = x1;
            3'b010: y = x2;
            3'b011: y = x3;
            3'b100: y = x4;
            3'b101: y = x5;
            3'b110: y = x6;
            3'b111: y = x7;
            default: y = 4'hf;
        endcase
    end

endmodule

module mux_2x1(
    input switch_mode,
    input [3:0] a0, a1,
    output reg [3:0] y
);

    // * : input 모두 감시, 아니면 개별 입력 선택할 수 있다.
    // always : 항상 감시한다 @이벤트 이하를 ()의 변화가 있으면, begin-end를 수행하라.
    always @(*) begin // ,대신 or도 가능함
        case(switch_mode)
            1'b0: y = a0;
            1'b1: y = a1;
            default: y = 4'hf;
        endcase
    end

endmodule

module bcdtoseg(
    input o_clk_dp,
    input [3:0] bcd, //[3:0] sum값
    output reg [7:0] seg
);
    // always구문은 출력으로 wire가 될 수 없음. 항상 reg type을 가져야 한다. 
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
                4'hA: seg = 8'h88;
                4'hB: seg = 8'h83;
                4'hC: seg = 8'hc6;
                4'hD: seg = 8'ha1;
                4'hE: seg = 8'hff;
                4'hF: seg = o_clk_dp ? 8'h7f:8'hff; 
                default: seg = 8'hff;
            endcase
        end
endmodule