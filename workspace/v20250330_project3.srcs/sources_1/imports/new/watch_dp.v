`timescale 1ns / 1ps

module wacth_dp (
    input clk,
    input reset,
    input cu_sec_up,
    input cu_min_up,
    input cu_hour_up,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour,
    input [2:0] sw_mode
);

    wire w_clk_100hz;
    wire w_msec_tick, w_sec_tick, w_min_tick;

    time_counter_clk #(.TICK_COUNT(100), .BIT_WIDTH (7)) U_Time_Msec (
        .clk(clk),
        .reset(reset),
        .tick(w_clk_100hz),
        .btn(1'b0),
        .o_time(msec),
        .o_tick(w_msec_tick),
        .tick_sw_minus(1'b0)
    );
    time_counter_clk #(.TICK_COUNT(60),.BIT_WIDTH (6)) U_Time_Sec (
        .clk(clk),
        .reset(reset),
        .tick(w_msec_tick),
        .btn(cu_sec_up),
        .o_time(sec),
        .o_tick(w_sec_tick),
        .tick_sw_minus(sw_mode)
    );
    time_counter_clk #(.TICK_COUNT(60),.BIT_WIDTH (6)) U_Time_Min (
        .clk(clk),
        .reset(reset),
        .tick(w_sec_tick),
        .btn(cu_min_up),
        .o_time(min),
        .o_tick(w_min_tick),
        .tick_sw_minus(sw_mode)
    );
    time_counter_clk #(.TICK_COUNT (24),.BIT_WIDTH  (5),.RESET_VALUE(12)) U_Time_Hour (
        .clk(clk),
        .reset(reset),
        .tick(w_min_tick),
        .btn(cu_hour_up),
        .o_time(hour),
        .o_tick(),
        .tick_sw_minus(sw_mode)
    );

    clk1_div_100 U_CLK_Div (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_clk_100hz)
    );

endmodule

module time_counter_clk #(parameter TICK_COUNT = 100, BIT_WIDTH = 7, RESET_VALUE = 0) (
    input clk,
    input reset,
    input tick,
    input btn,
    input [2:0] tick_sw_minus,
    output [BIT_WIDTH -1 : 0] o_time,
    output o_tick
);

    reg [$clog2(TICK_COUNT)-1:0] count_reg, count_next;
    reg tick_reg, tick_next;

    assign o_time = count_reg;  // 카운트
    assign o_tick = tick_reg;  // sec 카운트


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= RESET_VALUE;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        tick_next = 1'b0;   // 0 -> 1 -> 0 (바로 다음 clk에) 원래 0인 상태로 설정
        if (btn == 1'b1) begin
            if (tick_sw_minus == 3'b011) begin
                // 감소 모드
                if (count_reg == 0) begin
                    count_next = TICK_COUNT - 1;
                    tick_next  = 1'b0;
                end else begin
                    count_next = count_reg - 1;
                    tick_next  = 1'b0;
                end
            end else if(tick_sw_minus == 3'b010)begin
                // 증가 모드
                if (count_reg == TICK_COUNT - 1) begin
                    count_next = 0;
                    tick_next  = 1'b0;
                end else begin
                    count_next = count_reg + 1;
                    tick_next  = 1'b0;
                end
            end
        end

        if (tick == 1'b1) begin
            // 증가 모드 (tick에 따라 증가)
            if (count_reg == TICK_COUNT - 1) begin
                count_next = 0;
                tick_next  = 1'b1;
            end else begin
                count_next = count_reg + 1;
                tick_next  = 1'b0;
            end
        end
    end
endmodule

module clk1_div_100 (
    input  clk,
    input reset,
    //    input run, clear,
    output o_clk
);
    parameter FCOUNT = 1_000_000;   //1_000_000      //테스트벤츠용으로 빠른결과를 보기위해 10으로변경
    reg [$clog2(FCOUNT)-1:0] count_reg, count_next;
    reg clk_reg, clk_next;  // 출력을 ff으로 내보내기 위해서 만듦.

    assign o_clk = clk_reg;  // 최종 출력. 

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= 0;
            clk_reg   <= 0;
        end else begin
            count_reg <= count_next;
            clk_reg   <= clk_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        clk_next = 1'b0;    // 틱이 발생하고, 초기화를 통해 다시 발생하지 않도록 함.

        if (count_reg == FCOUNT - 1) begin
            count_next = 0;
            clk_next   = 1'b1;  // 출력 high
        end else begin
            count_next = count_reg + 1;
            clk_next   = 1'b0;
        end

    end
endmodule
