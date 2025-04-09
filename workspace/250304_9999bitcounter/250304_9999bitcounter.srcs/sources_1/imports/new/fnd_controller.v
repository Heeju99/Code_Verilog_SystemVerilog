`timescale 1ns / 1ps

module fnd_controller (
    input clk,
    input reset,
    input [13:0] count,
    output [7:0] seg,
    output [3:0] seg_comm
);
    wire [3:0] w_bcd, w_digit1, w_digit10, w_digit100, w_digit1000;
    wire [1:0] w_sel;
    wire clk_100Hz;
    wire w_count;

    clk_divider u_clk_divider(
        .clk(clk),
        .reset(reset),
        .o_clk(clk_100Hz)
    );

    btn2comm u_btn2comm (
        .btn(w_sel),
        .seg_comm(seg_comm)
    );

    digit_spliter u_digit_spliter(
        .count(w_count),
        .digit_1(w_digit1),
        .digit_10(w_digit10),
        .digit_100(w_digit100),
        .digit_1000(w_digit1000)
    );

    counter_4bit u_counter_4bit(
        .clk(clk_100Hz),
        .reset(reset),
        .o_sel(w_sel)
    );

    mux_4x1 u_mux_4x1(
        .sel(w_sel),
        .digit_1(w_digit1),
        .digit_10(w_digit10),
        .digit_100(w_digit100),
        .digit_1000(w_digit1000),
        .bcd(w_bcd)
    );

    bcd2seg u_bcd2seg (
        .bcd(w_bcd),
        .seg(seg)
    );

endmodule

module digit_spliter(
    input  [13:0] count,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);
    assign digit_1 = count % 10;
    assign digit_10 = (count) % 10;
    assign digit_100 = (count) % 10;
    assign digit_1000 = (count) % 10;
endmodule

module mux_4x1(
    input [1:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    output reg [3:0] bcd
);
    // * : input을 모두 감시, 아닐때는 개별로 지정 가능
    // always 하고 나오는 거는 reg 지정해줘야됨
    always@(sel, digit_1, digit_10, digit_100, digit_1000)
        begin
            case(sel)
                2'b00 : bcd = digit_1 ; 
                2'b01 : bcd = digit_10; 
                2'b10 : bcd = digit_100; 
                2'b11 : bcd = digit_1000;
                default : bcd = 4'bx; 
            endcase
        end
endmodule

module clk_divider(
    input clk,
    input reset,
    output o_clk
);
    parameter FCOUNT = 10_000_000;
    reg [$clog2(FCOUNT)-1:0] r_counter;
    // == reg[$clog2(1_000_000) -1 : 0] r_counter
    // == reg[FCOUNT-1:0] r_counter
    reg r_clk;
    assign o_clk = r_clk;
    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                r_counter <= 0;
                r_clk <= 1'b0;
            end
            else begin
                if(r_counter == FCOUNT - 1) begin //clk divider, 100MHz ->10Hz
                    r_counter <= 0;
                    r_clk <= 1'b1; 
                end
                else begin
                    r_counter <= r_counter + 1;
                    r_clk <= 1'b0;
                end
            end
        end
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

module btn2comm (
    input [1:0] btn,
    output reg [3:0] seg_comm
);

    always @(btn) begin
        case (btn)
            2'b00:   seg_comm = 4'b1110;
            2'b01:   seg_comm = 4'b1101;
            2'b10:   seg_comm = 4'b1011;
            2'b11:   seg_comm = 4'b0111;
            default: seg_comm = 4'b1111;
        endcase
    end
endmodule

module bcd2seg (
    input [3:0] bcd,
    output reg [7:0] seg
);
    //always 구문은 wire가 될 수 없고 reg로만 사용 가능
    always @(bcd) begin
        case (bcd)
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
            4'ha: seg = 8'h88;
            4'hb: seg = 8'h83;
            4'hc: seg = 8'hc6;
            4'hd: seg = 8'ha1;
            4'he: seg = 8'h86;
            4'hf: seg = 8'h8e;
            default: seg = 8'hff;
        endcase
    end
endmodule
