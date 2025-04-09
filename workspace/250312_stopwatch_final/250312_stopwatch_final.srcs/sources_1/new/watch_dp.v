`timescale 1ns / 1ps

module watch_dp(
    input clk,
    input reset,
    input i_sec,
    input i_min,
    input i_hour,
    input tick_sw_minus,
    output [6:0] msec_wch,
    output [5:0] sec_wch,
    output [5:0] min_wch,
    output [4:0] hour_wch
    );
    wire w_clk_100hz;
    wire w_msec_tick, w_sec_tick, w_min_tick;

    time_counter_1 #(.TICK_COUNT(100), .BIT_WIDTH(7)) U_time_msec( 
    .clk(clk),
    .reset(reset),
    .btn(1'b0),
    .tick(w_clk_100hz), //100_divider에서 들어옴
    .tick_sw_minus(tick_sw_minus),
    .o_time(msec_wch), //splitter로 들어감
    .o_tick(w_msec_tick)  //출력틱
    );

    time_counter_1 #(.TICK_COUNT(60), .BIT_WIDTH(6)) U_time_sec( 
    .clk(clk),
    .reset(reset),
    .btn(i_sec),
    .tick(w_msec_tick), //msec_counter에서 들어옴
    .tick_sw_minus(tick_sw_minus),
    .o_time(sec_wch), //splitter로 들어감
    .o_tick(w_sec_tick) // 출력틱
    );

    time_counter_1 #(.TICK_COUNT(60), .BIT_WIDTH(6)) U_time_min( 
    .clk(clk),
    .reset(reset),
    .btn(i_min),
    .tick(w_sec_tick), //sec_counter에서 들어옴
    .tick_sw_minus(tick_sw_minus),
    .o_time(min_wch), //splitter로 들어감
    .o_tick(w_min_tick) // 출력틱
    );

    time_counter_1 #(.TICK_COUNT(24), .BIT_WIDTH(5), .RESET_VALUE(12)) U_time_hour(
    .clk(clk),
    .reset(reset),
    .btn(i_hour),
    .tick(w_min_tick_wch), //min_counter에서 들어옴
    .tick_sw_minus(tick_sw_minus),
    .o_time(hour_wch), //splitter로 들어감
    .o_tick() // 출력틱
    
    );

    clk_div_100_wch U_clk_divider_wch(
    .clk(clk),
    .reset(reset),
    //.run(run),
    //.clear(clear),
    .o_clk(w_clk_100hz)
);
endmodule

module time_counter_1 #(parameter TICK_COUNT = 100, BIT_WIDTH = 7, RESET_VALUE = 0)( 
    input clk,
    input reset,
    input btn,
    input tick,
    input tick_sw_minus,
    output [BIT_WIDTH -1 :0] o_time,
    output o_tick
);

    reg [$clog2(TICK_COUNT -1) : 0] count_reg, count_next;
    reg tick_reg, tick_next;

    assign o_time = count_reg;
    assign o_tick = tick_reg;
    // initial count_reg = RESET_VALUE;

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
            if (tick_sw_minus) begin
                // 감소 모드
                if (count_reg == 0) begin
                    count_next = TICK_COUNT - 1;
                    tick_next  = 1'b0;
                end else begin
                    count_next = count_reg - 1;
                    tick_next  = 1'b0;
                end
            end else begin
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

module clk_div_100_wch(
    input clk,
    input reset,
    //input run,
    //input clear,
    output o_clk
);
    parameter FCOUNT = 1_000_000;
    reg [$clog2(FCOUNT)-1 :0] count_reg, count_next;
    reg clk_reg, clk_next; //출력을 F/F로 보내기 위해서

    assign o_clk = clk_reg; //최종 출력

    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                count_reg <= 0;
                clk_reg <= 0;
            end
            else begin
                count_reg <= count_next;
                clk_reg <= clk_next;
            end
        end
    
    always@(*)
        begin
            count_next = count_reg;
            clk_next = 1'b0;  //틱이 발생하고, 초기화를 통해 다시 발생하지 않도록 함.
            //if (run == 1'b1) begin
                if(count_reg == FCOUNT-1) begin
                    count_next = 0;
                    clk_next = 1'b1;
                end
                else begin
                    count_next = count_reg + 1;
                    clk_next = 1'b0;
                end
            end
            /*else if (clear == 1'b1) begin
                count_next = 0;
                clk_next = 0;
            end*/
        //end

endmodule
