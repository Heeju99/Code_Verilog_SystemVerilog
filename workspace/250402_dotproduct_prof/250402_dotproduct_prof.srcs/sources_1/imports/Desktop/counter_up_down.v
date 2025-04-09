`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        reset,
    output [3:0] fndCom,
    output [7:0] fndFont,
    //minus
    //input        sw_mode,
    //input        sw_run_stop,
    //input        sw_clear,
    // additional
    input           rx
);
    wire [13:0] fndData;
    wire [ 3:0] fndDot;
    wire w_en, w_clear, w_mode;
    //additional
    wire [7:0] rx_data;
    wire rx_done;


    uart u_uart(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
);

/*
//// rx+tx
    uart u_uart(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tx(tx),
        .tx_done(tx_done),
        .tx_data(tx_data),
        .tx_busy(tx_busy)
);
////*/

    control_unit U_control_unit (
        .clk(clk),
        .reset(reset),
        //.sw_mode(sw_mode),
        /*
        .sw_run_stop(sw_run_stop),
        .sw_clear(sw_clear),*/
        //additional
        .rx_data(rx_data),
        .rx_done(rx_done),
        //
        .en(w_en),
        .clear(w_clear),
        .mode(w_mode)
    );

    counter_up_down U_Counter (
        .clk(clk),
        .reset(reset),
        .mode(w_mode),
        .en(w_en),
        .clear(w_clear),
        .count(fndData),
        .dot_data(fndDot)
    );

    fndController U_FndController (
        .clk(clk),
        .reset(reset),
        .fndData(fndData),
        .fndDot(fndDot),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );


endmodule


module control_unit (
    input clk,
    input reset,
    //additional
    input rx_done,
    input [7:0] rx_data,
    //minus
    //input sw_mode,
    //input sw_run_stop,
    //input sw_clear,
    //
    output reg en,
    output reg clear,
    output mode
);

    localparam STOP = 0, RUN = 1, CLEAR = 2, MODE = 3;

    reg [1:0] state, state_next;
    reg [7:0] rx_data_reg, rx_data_next; 
    reg mode_reg, mode_next;

    assign mode = mode_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= STOP;
            mode_reg <= 0;
        end else begin
            state <= state_next;
            mode_reg <= mode_next;
        end
    end

    always @(*) begin
        mode_next = mode_reg;
        state_next = state;
        en = 1'b0;
        clear = 1'b0;
        //mode = sw_mode;
        case (state)
            STOP: begin
                // en = 1'b0;
                 //clear = 1'b0;
                //if (sw_run_stop) begin
                if(rx_data == "r") begin
                    state_next = RUN;
                end else if (rx_data == "c"/*sw_clear*/) begin
                    state_next = CLEAR;
                end else if (rx_data == "m") begin
                    state_next = MODE;
                end
            end
            RUN: begin
                en = 1'b1;
                if (rx_data == "s"/*sw_run_stop == 0*/) begin
                    state_next = STOP;
                end
            end
            CLEAR: begin
                clear = 1'b1;
                /*if (sw_clear == 0) begin
                    state_next = STOP;
                end*/
                state_next = STOP;
            end
            MODE : begin
                if(mode_reg == 1'b0) begin
                    mode_next = 1'b1;
                end else begin
                    mode_next = 1'b0;
                end
            end
        endcase
    end

endmodule


module comp_dot (
    input  [13:0] count,
    output [ 3:0] dot_data
);

    assign dot_data = ((count % 10) < 5) ? 4'b1101 : 4'b1111;
endmodule

module counter_up_down (
    input         clk,
    input         reset,
    input         mode,
    input         en,
    input         clear,
    output [13:0] count,
    output [ 3:0] dot_data
);
    wire tick;

    clk_div_10hz U_Clk_Div_10Hz (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .en(en),
        .tick(tick)
    );

    counter U_Counter_Up_Down (
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .mode(mode),
        .en(en),
        .clear(clear),
        .count(count)
    );

    comp_dot U_Comp_Dot (
        .count(count),
        .dot_data(dot_data)
    );

endmodule


module counter (
    input         clk,
    input         reset,
    input         tick,
    input         mode,
    input         en,
    input         clear,
    output [13:0] count
);
    reg [$clog2(10000)-1:0] counter;

    assign count = counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else begin
            if (clear) begin
                counter <= 0;
            end 
            if (en) begin
                if (mode == 1'b0) begin
                    if (tick) begin
                        if (counter == 9999) begin
                            counter <= 0;
                        end else begin
                            counter <= counter + 1;
                        end
                    end
                end else begin
                    if (tick) begin
                        if (counter == 0) begin
                            counter <= 9999;
                        end else begin
                            counter <= counter - 1;
                        end
                    end
                end
            end
        end
    end
endmodule

module clk_div_10hz (
    input clk,
    input reset,
    input clear,
    input en,
    output reg tick
);
    reg [$clog2(10_000_000)-1:0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (en) begin
                if (div_counter == 10_000_000 - 1) begin
                    div_counter <= 0;
                    tick <= 1'b1;
                end else begin
                    div_counter <= div_counter + 1;
                    tick <= 1'b0;
                end
            end
            if (clear) begin
                div_counter <= 0;
                tick <= 1'b1;
            end
        end
    end
endmodule
