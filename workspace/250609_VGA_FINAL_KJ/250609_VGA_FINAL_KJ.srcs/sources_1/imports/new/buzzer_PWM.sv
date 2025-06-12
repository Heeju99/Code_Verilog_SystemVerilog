module buzzer_PWM (
    input  logic clk,
    input  logic reset,
    input  logic button,
    output logic PWM_signal,
    output logic buzzer_done
);

    typedef enum logic [1:0] { IDLE, PLAY } play_state_t;

    typedef struct packed {
        logic [31:0] freq_cnt;
        logic [31:0] dur;
    } note_t;

    // 정확한 음 높이 (100MHz 기준)
    localparam logic [31:0] MI   = 100_000_000 / 659.25;
    localparam logic [31:0] LA   = 100_000_000 / 880.00;
    localparam logic [31:0] SOL  = 100_000_000 / 783.99;
    localparam logic [31:0] MUTE = 0;

    // 음표 길이
    localparam logic [31:0] DUR_QUARTER = 25_000_000;
    localparam logic [31:0] DUR_EIGHTH  = 12_500_000;
    localparam logic [31:0] DUR_HALF    = 50_000_000;

    localparam int NOTE_COUNT = 20;

 note_t melody[NOTE_COUNT] = '{
    '{MI, DUR_EIGHTH},
    '{MUTE, DUR_EIGHTH},
    '{LA, DUR_EIGHTH},
    '{MUTE, DUR_EIGHTH},
    '{LA, DUR_QUARTER},
    '{MUTE, DUR_QUARTER},
    '{LA, DUR_QUARTER},
    '{MUTE, DUR_QUARTER},
    '{SOL, DUR_QUARTER},
    '{MUTE, DUR_QUARTER},
    '{LA, DUR_EIGHTH},
    '{MUTE, DUR_EIGHTH},
    '{LA, DUR_EIGHTH},
    '{MUTE, DUR_EIGHTH},
    '{MI, DUR_EIGHTH},
    '{MUTE, DUR_EIGHTH},
    '{MI, DUR_EIGHTH},
    '{MUTE, DUR_EIGHTH},
    '{SOL, DUR_HALF},
    '{MUTE, DUR_HALF}
 };

    // 내부 상태
    play_state_t play_state = IDLE;
    logic [4:0] note_index = 0;
    logic [31:0] note_timer = 0;
    logic [31:0] freq_cnt = 0;
    logic [31:0] half_cnt = 0;
    logic [31:0] pwm_cnt = 0;
    logic PWM_en = 0;

    // 버튼 에지 감지
    logic prev_button = 0;
    logic button_edge = 0;

    // always_ff @(posedge clk) begin
    //     prev_button <= button;
    //     button_edge <= button & ~prev_button;
    // end

    // 재생 상태 FSM
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            play_state <= IDLE;
            note_index <= 0;
            note_timer <= 0;
            PWM_en <= 0;
            buzzer_done <= 0;
        end else begin
            case (play_state)
                IDLE: begin
                    if (button) begin //button_edge
                        buzzer_done <= 1'b0;
                        note_index <= 0;
                        note_timer <= 0;
                        freq_cnt <= melody[0].freq_cnt;
                        half_cnt <= melody[0].freq_cnt >> 1;
                        PWM_en <= (melody[0].freq_cnt != 0);
                        play_state <= PLAY;
                    end
                end

                PLAY: begin
                    if (note_timer >= melody[note_index].dur - 1) begin
                        note_timer <= 0;
                        note_index <= note_index + 1;
                        if (note_index + 1 < NOTE_COUNT) begin
                            freq_cnt <= melody[note_index + 1].freq_cnt;
                            half_cnt <= melody[note_index + 1].freq_cnt >> 1;
                            PWM_en <= (melody[note_index + 1].freq_cnt != 0);
                        end else begin
                            play_state <= IDLE;
                            PWM_en <= 0;
                            buzzer_done <= 1'b1;
                        end
                    end else begin
                        note_timer <= note_timer + 1;
                    end
                end
            endcase
        end
    end

    // PWM 출력
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            PWM_signal <= 0;
            pwm_cnt <= 0;
        end else if (PWM_en) begin
            PWM_signal <= (pwm_cnt <= half_cnt);
            pwm_cnt <= (pwm_cnt >= freq_cnt) ? 0 : pwm_cnt + 1;
        end else begin
            PWM_signal <= 0;
            pwm_cnt <= 0;
        end
    end

endmodule