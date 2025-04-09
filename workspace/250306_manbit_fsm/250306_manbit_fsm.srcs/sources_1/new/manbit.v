
`timescale 1ns / 1ps

module Top_Upcounter(
    input clk, reset,
    input [2:0] sw,
    // input BTN, clear,
    output [3:0] seg_comm,
    output [7:0] seg
);

    //10000을 $clog2로 필요한 버튼 수 계산된 결과값
    wire [13:0] w_count;
    wire clk_10;
    wire w_run_stop, w_clear;

    wire w_tick_100hz;

    
    // instance
    tick_100hz U_Tick_100hz(
        .clk(clk), .reset(reset), .run_stop(w_run_stop), .o_tick_100hz(w_tick_100hz)
    );
    

    counter_tick U_Counter_tick(
    .clk(clk), .reset(reset), .tick(w_tick_100hz),
    .counter(w_count)
    );
    
    // clk_divider_10 U_clk_divider_10(
    //     .clk(clk), .reset(reset), .o_clk(clk_10)
    // );

    // counter_10000 U_counter_10000(
    //     .clk(clk_10),
    //     .reset(reset),
    //     .count(w_count),
    //     .clear(w_clear),
    //     .count_stop(w_run_stop)
    // );

    fnd_controller U_fnd_cntl(
        .clk(clk),
        .reset(reset),
        .bcd(w_count), // 14비트
        .seg(seg),
        .seg_comm(seg_comm));

    control_unit U_Control_unit(
        .clk(clk), 
        .reset(reset), 
        .i_run_stop(sw[1]), 
        .i_clear(sw[0]), 
        .o_clear(w_clear), 
        .o_run_stop(w_run_stop)
    );

endmodule



// 100Mhz -> 10hz 만들기 -> 100hz
// 100Hz tick generator
module tick_100hz(
  input clk, //100MHz 클럭으로 카운트하기기 
  input reset,
  input run_stop,
  output o_tick_100hz
);

reg [23:0] r_counter;
reg r_tick_100hz;

assign o_tick_100hz = r_tick_100hz;


always@(posedge clk, posedge reset) begin
    if(reset) begin
        r_counter <= 0;
    end else begin
        if (run_stop == 1'b1) begin
            if(r_counter == 1_000_000-1) begin //100M -> 10
                r_counter <= 0;
                r_tick_100hz <= 1'b1;
        end else begin
            r_counter <= r_counter + 1;
            r_tick_100hz <= 1'b0; // 100M = 1 tick
        end
    end
    end
end
endmodule



module counter_10000(
    input clk, reset,
    input count_stop, clear,
    output [$clog2(10000)-1:0] count //14비트
    );
    
    reg [$clog2(10000)-1:0] r_counter;

    assign count = r_counter; 

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_counter <= 0;

        end else if(clear) begin
                r_counter <= 0;
        end
            else if(count_stop) begin
                r_counter <= r_counter;
            end

        else begin
            if (r_counter == 10000 - 1) begin
                r_counter <= 0;
            end else begin
                r_counter <= r_counter + 1;
            end
        end
    end
endmodule



module counter_tick(
    input clk, reset, tick,
    output [$clog2(10_000)-1 : 0] counter
);
    // state, next
    reg [$clog2(10_000)-1 : 0] counter_reg, counter_next;

    assign counter = counter_reg;

    // state
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            counter_reg <=0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // next
    // parameter 선언없이 코드짜기
    always @(counter_reg) begin
        counter_next = counter_reg;
        if (tick == 1'b1) begin // tick count, 1tick = clk
            if (counter_reg == 10_000-1) begin
                counter_next = 0; // 현재 상태가 10000까지 도달했을 때 다시 0으로 시작
            end else begin
                counter_next = counter_reg + 1;
            end
        end
    end


endmodule



// fsm
module control_unit(
    input clk, reset,
    input i_run_stop, i_clear,
    output reg o_run_stop, o_clear
);
    parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010;

    // state 관리
    reg [2:0] cstate, nstate;

    // state sequencial logic
    // state 저장, 유지
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            cstate <= STOP;
        end else begin 
            cstate <= nstate;
        end
    end


    // next combinational logic
    always @(*) begin
        nstate = cstate;
        case(cstate) 

        STOP: 
        if(i_run_stop == 1'b1) nstate = RUN;
        else if (i_clear) nstate = CLEAR;
        else nstate = cstate;

        RUN: 
        if(i_run_stop == 1'b0) nstate = STOP;
        else if (i_clear) nstate = CLEAR;
        else nstate = cstate;

        CLEAR:
        if(i_clear == 1'b0) nstate = STOP;
        
        default: nstate = STOP;

        endcase
    end


    // combinational output logic
    always @(*) begin
        case (cstate)

        STOP: begin
        o_run_stop = 1'b0;
        o_clear = 1'b0;
        end

        RUN: begin
        o_run_stop = 1'b1;
        o_clear = 1'b0;
        end

        CLEAR: begin
        o_run_stop = 1'b0;
        o_clear = 1'b1;
        end

        default: begin
        o_run_stop = 1'b0;
        o_clear = 1'b0;
        end

    endcase
    end

endmodule
