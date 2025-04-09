`timescale 1ns / 1ps

module top_stopwatch(
    input clk,
    input reset,
    input [2:0] switch_mode,
    input [7:0] data_in,
    input empty_rx_b,
    input btn_left,
    input btn_up,
    input btn_down,
    output [3:0] fnd_comm,
    output [7:0] fnd_font,
    output [4:0] led
    );

    wire w_btn_left, w_btn_down, w_btn_up;
    wire w_btn_run, w_btn_clear, w_btn_hour, w_btn_min, w_btn_sec;
    wire run, clear;

    wire [6:0] msec; 
    wire [5:0] sec, min;
    wire [4:0] hour;
    wire [6:0] msec_wch; 
    wire [5:0] sec_wch, min_wch;
    wire [4:0] hour_wch;
    wire [6:0] final_msec; 
    wire [5:0] final_sec, final_min;
    wire [4:0] final_hour;

    stopwatch_DP u_stopwatch_dp(
        .clk(clk),
        .reset(reset),
        .clear(clear | w_btn_clear),
        .run(run | w_btn_run), 
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );
    stopwatch_CU u_stopwatch_CU(
        .clk(clk),
        .reset(reset),
        .chip_select(switch_mode[1]), ///변경
        .i_btn_up(w_btn_up),
        .i_btn_down(w_btn_down),
        .o_run(run),
        .o_clear(clear)
    );
    led_2X4 u_led_2x4(
        .switch_mode(switch_mode), 
        .led(led)
    );
    fnd_controller u_fnd_controller(
        .clk(clk), 
        .reset(reset),
        .switch_mode(switch_mode),
        .msec(final_msec),
        .sec(final_sec),
        .min(final_min),
        .hour(final_hour),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm)
    );

    button_debounce u_button_debounce_up(
        .clk(clk),
        .reset(reset),
        .i_btn(btn_up),
        .o_btn(w_btn_up)
    );
    button_debounce u_button_debounce_left(
        .clk(clk),
        .reset(reset),
        .i_btn(btn_left),
        .o_btn(w_btn_left)
    );

    button_debounce u_button_debounce_down(
        .clk(clk),
        .reset(reset),
        .i_btn(btn_down),
        .o_btn(w_btn_down)
    );

    chip_8x4 u_chip_8x4(
        .chip_select(switch_mode[1]),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour),
        .msec_wch(msec_wch),
        .sec_wch(sec_wch),
        .min_wch(min_wch),
        .hour_wch(hour_wch),
        .to_fnd_msec(final_msec),
        .to_fnd_sec(final_sec),
        .to_fnd_min(final_min),
        .to_fnd_hour(final_hour)
);
    watch_dp u_watch_dp(
        .clk(clk),
        .reset(reset),
        .i_sec(w_o_sec | w_btn_sec),
        .i_min(w_o_min | w_btn_min),
        .i_hour(w_o_hour | w_btn_hour),
        .tick_sw_minus(switch_mode[2]),
        .msec_wch(msec_wch),
        .sec_wch(sec_wch),
        .min_wch(min_wch),
        .hour_wch(hour_wch)
    );
    watch_cu u_watch_cu(
        .clk(clk),
        .reset(reset),
        .chip_select(switch_mode[1]), ///변경경
        .i_btn_left(w_btn_left),
        .i_btn_up(w_btn_up),
        .i_btn_down(w_btn_down),
        .o_sec(w_o_sec),
        .o_min(w_o_min),
        .o_hour(w_o_hour)
    );
    uart_stopwatch u_uart_stopwatch(
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .empty_rx_b(empty_rx_b),
        .btn_run(w_btn_run),
        .btn_clear(w_btn_clear),
        .btn_hour(w_btn_hour),
        .btn_min(w_btn_min),
        .btn_sec(w_btn_sec)
);
endmodule

module uart_stopwatch(
    input clk,
    input reset,
    input [7:0]data_in,
    input empty_rx_b,
    output reg btn_run,
    output reg btn_clear,
    output reg btn_hour,
    output reg btn_min,
    output reg btn_sec
);
    parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010, HOUR = 3'b011, MIN = 3'b100, SEC = 3'b101;
    reg [2:0] state, next;
    reg [7:0] empty_data_reg, empty_data_next;

    always@(posedge clk, posedge reset)
    begin
        if(reset) begin
            state <= STOP;
        end
        else begin
            state <= next;
            empty_data_reg <= empty_data_next;
        end
    end
    
    always@(*)
        begin
            next = state;
            empty_data_next = empty_data_reg;
            if(empty_rx_b) begin
                empty_data_next = data_in;
            end else begin
                empty_data_next = 8'h00;
            end
             begin
                case(state)
                    STOP : begin
                        if(empty_data_next == "R" || "r" ) begin
                            next = RUN; 
                        end
                        else if(empty_data_next == "C" || "c") begin
                            next = CLEAR; 
                        end
                        else if(empty_data_next == "H" || "h") begin
                            next = HOUR; 
                        end
                        else if(empty_data_next == "M" || "m") begin
                            next = MIN; 
                        end
                        else if(empty_data_next == "S" || "s") begin
                            next = SEC; 
                        end
                        else begin
                            next = STOP;
                        end
                    end
                    RUN :
                        if(empty_data_next == "R" || "r") begin
                            next = STOP;
                        end
                    CLEAR:next = STOP;
                    HOUR:next = STOP;
                    MIN :next = STOP;
                    SEC :next = STOP;
                endcase
        end
    end

    // output logic
    always@(*)
        begin
            btn_run = 0;
            btn_clear = 0;
            btn_hour = 0;
            btn_min = 0;
            btn_sec = 0;
            case(state)
                STOP: begin
                    btn_run = 0;
                    btn_clear = 0;
                    btn_hour = 0;
                    btn_min = 0;
                    btn_sec = 0;
                end
                RUN: begin
                    btn_run = 1;
                    btn_clear = 0;
                    btn_hour = 0;
                    btn_min = 0;
                    btn_sec = 0;
                end
                CLEAR: begin
                    btn_run = 0;
                    btn_clear = 1;
                    btn_hour = 0;
                    btn_min = 0;
                    btn_sec = 0;
                end
                HOUR: begin
                    btn_run = 0;
                    btn_clear = 0;
                    btn_hour = 1;
                    btn_min = 0;
                    btn_sec = 0;
                end
                MIN : begin
                    btn_run = 0;
                    btn_clear = 0;
                    btn_hour = 0;
                    btn_min = 1;
                    btn_sec = 0;
                end
                SEC : begin
                    btn_run = 0;
                    btn_clear = 0;
                    btn_hour = 0;
                    btn_min = 0;
                    btn_sec = 1;
                end
            endcase
        end
endmodule

module chip_8x4(
    input chip_select,
    input [6:0] msec,
    input [5:0] sec,
    input [5:0] min,
    input [4:0] hour,
    input [6:0] msec_wch,
    input [5:0] sec_wch,
    input [5:0] min_wch,
    input [4:0] hour_wch,
    output reg [6:0] to_fnd_msec,
    output reg [5:0] to_fnd_sec,
    output reg [5:0] to_fnd_min,
    output reg [4:0] to_fnd_hour
);
    always@(*)
        begin if (chip_select == 1'b0) begin 
            to_fnd_msec = msec; 
            to_fnd_sec = sec; 
            to_fnd_min = min; 
            to_fnd_hour = hour; 
        end
        else if (chip_select == 1'b1)begin 
            to_fnd_msec = msec_wch; 
            to_fnd_sec = sec_wch; 
            to_fnd_min = min_wch; 
            to_fnd_hour = hour_wch; 
            end
        end
endmodule

module led_2X4(
    input [2:0]switch_mode, 
    output reg [4:0] led
);
always @(*)
    begin
        case(switch_mode)
            3'b000 : begin
                led = 5'b00001;
            end
            3'b001 : begin
                led = 5'b00010;
            end
            3'b010 : begin
                led = 5'b00100;
            end
            3'b011 : begin
                led = 5'b01000;
            end
            3'b111 :begin
                led = 5'b10000;
            end
        endcase
    end
endmodule

