`timescale 1ns / 1ps

module uart(
    input clk,
    input reset,
    input rx,
    output rx_done,
    output rx_data
    /*
    output tx,
    output tx_done,
    output [7:0]tx_data,
    output tx_busy*/
);

    wire w_tick;
    //,rx_done;

    clk_baud u_clk_baud(
    .clk(clk),
    .reset(reset),
    .tick(w_tick)
);

    uart_short uart_short(
    .clk(clk),
    .reset(reset),
    .rx(rx),
    .tick(w_tick),
    .rx_done(rx_done),
    .rx_data(rx_data)
);


/*
    uart_tx u_uart_tx(
        .clk(clk),
        .reset(reset),
        .tick(wtick),
        .tx(tx),
        .trigger(rx_done), // connect with rx_done
        .tx_done(tx_done),  //connect witch pc
        .tx_data(tx_data),
        .tx_busy(tx_busy)
    );
*/

endmodule

module clk_baud (
    input clk,
    input reset,
    output reg tick
);
    localparam BAUD_COUNT = (100_000_000)/9600/16;
    reg [$clog2(BAUD_COUNT)-1:0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
                if (div_counter == BAUD_COUNT - 1) begin
                    div_counter <= 0;
                    tick <= 1'b1;
                end else begin
                    div_counter <= div_counter + 1;
                    tick <= 1'b0;
                end
            end
        end
endmodule


module uart_short (
    input clk,
    input reset,
    input tick,
    input rx,
    output rx_done,
    output [7:0] rx_data
);
    
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state, next;
    reg rx_done_reg, rx_done_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [5:0] tick_count_reg, tick_count_next; 
    reg [7:0] rx_data_reg, rx_data_next;

    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            rx_done_reg <= 0;
            bit_count_reg <= 0;
            tick_count_reg <= 0;
            rx_data_reg <= 0;
        end
        else begin
            state <= next;
            rx_done_reg <= rx_done_next;
            bit_count_reg <= bit_count_next;
            tick_count_reg <= tick_count_next;
            rx_data_reg <= rx_data_next;
        end
    end

    always @(*) begin
        next = state;
        rx_done_next = rx_done_reg;
        bit_count_next = bit_count_reg;
        tick_count_next = tick_count_reg;
        rx_data_next = rx_data_reg;
        case (state)
            IDLE: begin
                tick_count_next = 0;
                bit_count_next = 0;
                rx_done_next = 1'b0;
                if (rx == 0) begin
                    next = START;
                end
            end  
            START: begin
                if(tick) begin
                    if(tick_count_reg == 7) begin
                        next = DATA;
                        tick_count_next = 0;
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end            
            end  
            DATA: begin
                if (tick) begin
                    rx_data_next[bit_count_reg] = rx;
                    if(tick_count_reg == 15) begin
                        tick_count_next = 0;
                        if (bit_count_reg == 7) begin
                            bit_count_next = 0;
                            next = STOP;
                        end
                        else begin
                            next = DATA;
                            bit_count_next = bit_count_reg + 1;
                        end
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end  
            STOP: begin
                if(tick) begin
                    if (tick_count_reg == 23) begin
                        rx_done_next = 1'b1;
                        next = IDLE;
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end  
        endcase
    end

endmodule

module uart_tx(
        input clk,
        input reset,
        input tick,
        input tx,
        input trigger, // connect with rx_done
        output tx_done,  //connect witch pc
        output [7:0] tx_data,
        output tx_busy
    );

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state, next;
    reg tx_done_reg, tx_done_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [5:0] tick_count_reg, tick_count_next; 
    reg [7:0] tx_data_reg, tx_data_next;
    reg tx_busy_reg, tx_busy_next;

    assign tx_done = tx_done_reg;
    assign tx_data = tx_data_reg;
    assign tx_busy = tx_busy_reg;

    always@(*) begin
        next = state;
        tx_done_next = tx_done_reg;
        bit_count_next = bit_count_reg;
        tick_count_next = tick_count_reg;
        tx_data_next = tx_data_reg;
        tx_busy_next = tx_busy_reg;
        case(state)
            IDLE : begin
                tx_busy_next = 0;
                tick_count_next = 0;
                bit_count_next = 0;
                tx_done_next = 1'b0;
                if (trigger) begin
                    next = START;
                end
            end  
            START : begin
                tx_busy_next = 1'b1;
                if(tick) begin
                    if(tick_count_reg == 7) begin
                        next = DATA;
                        tick_count_next = 0;
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end            
            end  
            DATA :  begin
                tx_data_next[bit_count_reg] = tx;
                if (tick) begin
                    if(tick_count_reg == 15) begin
                        tick_count_next = 0;
                        if (bit_count_reg == 7) begin
                            next = STOP;
                        end
                        else begin
                            next = DATA;
                            bit_count_next = bit_count_reg + 1;
                        end
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end  
            STOP : begin
                if(tick) begin
                    if (tick_count_reg == 15) begin
                        tx_done_next = 1'b1;
                        next = IDLE;
                    end
                    else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end  
        endcase
    end
endmodule