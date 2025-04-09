`timescale 1ns / 1ps

module fnd_controller (
    input  [7:0] bcd,
    //input  [1:0] btn,
    output [7:0] seg,
    output [3:0] seg_comm
);
    //btn2comm u_btn2comm (
    //    .btn(btn),
    //    .seg_comm(seg_comm)
    //);

    bcd2seg u_bcd2seg (
        .bcd(bcd),
        .seg(seg)
    );
    assign seg_comm = 4'b0000; 
endmodule

/*module btn2comm (
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
*/
module bcd2seg (
    input [7:0] bcd,
    output reg [7:0] seg
);
    //always 구문은 wire가 될 수 없고 reg로만 사용 가능
    always @(bcd) begin
        case (bcd)
            8'h0: seg = 8'hc0;
            8'h1: seg = 8'hf9;
            8'h2: seg = 8'ha4;
            8'h3: seg = 8'hb0;
            8'h4: seg = 8'h99;
            8'h5: seg = 8'h92;
            8'h6: seg = 8'h82;
            8'h7: seg = 8'hf8;
            8'h8: seg = 8'h80;
            8'h9: seg = 8'h90;
            8'ha: seg = 8'h88;
            8'hb: seg = 8'h83;
            8'hc: seg = 8'hc6;
            8'hd: seg = 8'ha1;
            8'he: seg = 8'h86;
            8'hf: seg = 8'h8e;
            default: seg = 8'hff;
        endcase
    end
endmodule
