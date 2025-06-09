`timescale 1ns / 1ps

module play_fsm (
    // global signals
    input logic clk,
    input logic reset,

    // buzzer signals
    input  logic start_btn,
    input  logic buzzer_done,
    output logic buzzer_start,

    // motion_detect signals
    input logic motion_detected,
    output logic text_en_surv,
    output logic text_en_over,
    output logic [2:0] score,
    output logic sel_text,
    output logic [4:0] led
);

    logic [$clog2(300_000_000)-1:0] count_3sec_reg, count_3sec_next;

    logic text_en_over_reg, text_en_over_next;
    logic text_en_surv_reg, text_en_surv_next;
    logic sel_text_reg, sel_text_next;
    logic [3:0] led_reg, led_next;
    logic [2:0] score_reg, score_next;

    assign score        = score_reg;
    assign text_en_over = text_en_over_reg;
    assign text_en_surv = text_en_surv_reg;
    assign sel_text     = sel_text_reg;
    assign led     = led_reg;

    typedef enum {
        IDLE,
        BUZZER,
        PLAY,
        SUCCESS,
        FAIL,
        REPEAT
    } state_e;
    state_e state, state_next;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            count_3sec_reg <= 0;
            text_en_over_reg <= 0;
            text_en_surv_reg <= 0;
            score_reg <= 0;
            sel_text_reg <= 0;
            led_reg <= 0;
        end else begin
            state <= state_next;
            count_3sec_reg <= count_3sec_next;
            text_en_over_reg <= text_en_over_next;
            text_en_surv_reg <= text_en_surv_next;
            score_reg <= score_next;
            sel_text_reg <= sel_text_next;
            led_reg <= led_next;
        end
    end

    always_comb begin
        state_next = state;
        buzzer_start = 0;
        count_3sec_next = count_3sec_reg;
        text_en_over_next = text_en_over_reg;
        text_en_surv_next = text_en_surv_reg;
        score_next = score_reg;
        sel_text_next = sel_text_reg;
        led_next = led_reg;
        case (state)
            IDLE: begin
                led_next = 5'b00000;
                count_3sec_next = 0;
                if (start_btn) begin
                    score_next = 0;
                    text_en_over_next = 0;
                    text_en_surv_next = 0;
                    sel_text_next = 0;
                    buzzer_start = 1'b1;
                    state_next = BUZZER;
                end
            end
            BUZZER: begin
                led_next = 5'b00001;
                buzzer_start = 1'b0;
                count_3sec_next = 0;
                if (buzzer_done) begin
                    text_en_surv_next = 0;
                    text_en_over_next = 0;
                    sel_text_next = 0;
                    state_next = PLAY;
                end
            end
            PLAY: begin
                led_next = 5'b00010;
                if (count_3sec_reg == 300_000_000 - 2) begin
                    count_3sec_next = 0;
                    state_next = SUCCESS;
                end else if (motion_detected) begin
                    text_en_over_next = motion_detected;
                    sel_text_next = 1'b0;
                    count_3sec_next = count_3sec_reg + 1;
                    state_next = FAIL;
                end else begin
                    count_3sec_next = count_3sec_reg + 1;
                end
            end
            SUCCESS: begin
                led_next = 5'b00100;
                state_next = REPEAT;
                score_next = score_reg + 1;
            end
            FAIL: begin
                led_next = 5'b01000;
                if (count_3sec_reg == 300_000_000 - 1) begin
                    count_3sec_next = 0;
                    state_next = IDLE;
                end else begin
                    count_3sec_next = count_3sec_reg + 1;
                end
            end
            REPEAT: begin
                led_next = 5'b10000;
                if(score_reg == 5) begin
                    text_en_surv_next = 1'b1;  //~motion_detected
                    sel_text_next = 1'b1;
                    state_next = IDLE;
                end
                else begin
                    buzzer_start = 1'b1;
                    state_next = BUZZER;
                end
            end
        endcase
    end

endmodule
