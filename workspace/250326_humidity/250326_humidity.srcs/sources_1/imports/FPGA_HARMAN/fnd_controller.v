`timescale 1ns / 1ps

module fnd_controller(
    input clk, reset,
    input [15:0] bcd,
    output [7:0] seg,
    output [3:0] seg_comm
);
    wire [1:0] w_seg_sel;
    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_bcd;
    wire clk_100hz;

    clk_divider U_clk_divider(
        .clk(clk), 
        .reset(reset), 
        .o_clk(clk_100hz)
    );

    counter_4 U_Counter_4(
        .clk(clk_100hz), 
        .reset(reset), 
        .o_sel(w_seg_sel)
    );

    decoder_2x4 U_decoder_2x4(
        .seg_sel(w_seg_sel), 
        .seg_comm(seg_comm)
    );

    digit_splitter_INT U_Digit_splitter_INT(
        .bcd(bcd[15:8]),  
        .digit_100(w_digit_100), 
        .digit_1000(w_digit_1000)
    );
    
    digit_splitter_FLT U_Digit_splitter_FLT(
        .bcd(bcd[7:0]), 
        .digit_1(w_digit_1), 
        .digit_10(w_digit_10)
    );

    mux_4x1 U_Mux_4x1 (
       .bcd(w_bcd),
       .sel(w_seg_sel), 
       .digit_1(w_digit_1), 
       .digit_10(w_digit_10), 
       .digit_100(w_digit_100), 
       .digit_1000(w_digit_1000)
    );

    bcdtoseg U_bcdtoseg(
        .bcd(w_bcd), // [3:0] sum값
        .seg(seg)
    );

    //assign seg_comm = 4'b1110; // segment 0의 자리 on, seg는 anode type
   // assign seg_comm = 4'b0000;

    // always @(BTN) begin
    // case(BTN)
    // 2'b00: seg_comm = 4'b1110; //0이 켜지는 거래..
    // 2'b01: seg_comm = 4'b1101;
    // 2'b10: seg_comm = 4'b1011;
    // 2'b11: seg_comm = 4'b0111;
    // endcase
    // end

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

endmodule


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

module digit_splitter_INT(
    input [7:0] bcd,
    output [3:0] digit_100,
    output [3:0] digit_1000
);

assign digit_100 = bcd  % 10; //10의 100의 자리
assign digit_1000 = bcd / 10 % 10; //10의 1000의 자리

endmodule

module digit_splitter_FLT(
    input [7:0] bcd,
    output [3:0] digit_1,
    output [3:0] digit_10
);

assign digit_1 = bcd % 10; //10의 1의 자리
assign digit_10 = bcd / 10 % 10; //10의 10의 자리


endmodule


module mux_4x1(
    input [1:0] sel,
    input [3:0] digit_1, digit_10, digit_100, digit_1000,
    output reg [3:0] bcd
);

    // * : input 모두 감시, 아니면 개별 입력 선택할 수 있다.
    // always : 항상 감시한다 @이벤트 이하를 ()의 변화가 있으면, begin-end를 수행하라.
    always @(*) begin // ,대신 or도 가능함
        case(sel)
            2'b00: bcd = digit_1;
            2'b01: bcd = digit_10;
            2'b10: bcd = digit_100;
            2'b11: bcd = digit_1000;
            default: bcd = 4'bx;
        endcase
    end

endmodule


module bcdtoseg(
    input [3:0] bcd, //[3:0] sum값
    output reg [7:0] seg
);
    // always구문은 출력으로 wire가 될 수 없음. 항상 reg type을 가져야 한다. 
    always @(bcd) begin // 항상 대상이벤트를 감시
        
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
        4'hE: seg = 8'h86;
        4'hF: seg = 8'h8E;
        default: seg = 8'hff;
        endcase
    end

endmodule