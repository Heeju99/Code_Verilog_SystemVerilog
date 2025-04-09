`timescale 1ns / 1ps

module uart(
    input clk,
    input reset,
    input [7:0] tx_data,
    input tx_start,
    input rx,
    output tx_done,
    output tx_busy,
    output tx,
    output rx_data,
    output rx_done
    );

    wire w_br_tick;

    transmitter u_transmitter(
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .br_tick(w_br_tick),
        .tx_done(tx_done),
        .tx_busy(tx_busy),
        .tx(tx)
);

    receiver u_receiver(
        .clk(clk),
        .reset(reset),
        .br_tick(w_br_tick),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data)    
);

    baudrate_gen u_baudrate_gen(
        .clk(clk),
        .reset(reset),
        .br_tick(w_br_tick)
);

endmodule

module receiver(
    input clk,
    input reset,
    input br_tick,
    input rx,
    output rx_done,
    output [7:0] rx_data    
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state, next;
    reg [3:0] tick_counter_reg, tick_counter_next;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg [7:0] temp_data_reg, temp_data_next;
    reg rx_done_reg, rx_done_next;

    assign rx_data = temp_data_reg;
    assign rx_done = rx_done_reg;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= IDLE;
            tick_counter_reg <= 0; 
            bit_counter_reg <= 0;
            temp_data_reg <= 0;
            rx_done_reg <= 0;       
        end else begin
            state <= next;
            tick_counter_reg <= tick_counter_next;
            bit_counter_reg <= bit_counter_next;
            temp_data_reg <= temp_data_next;
            rx_done_reg <= rx_done_next;
        end
    end

    always @(*) begin
        next = state;
        tick_counter_next = tick_counter_reg;
        bit_counter_next = bit_counter_reg;
        temp_data_next = temp_data_reg;
        rx_done_next = rx_done_reg;
        case(state)
            IDLE : begin
                rx_done_next = 1'b0;
                    if(rx == 0) begin
                        next = START;
                        bit_counter_next = 0;
                        tick_counter_next = 0;
                        temp_data_next = 0;
                    end
            end
            START :begin
                if(br_tick) begin
                    if(tick_counter_reg == 7) begin
                        tick_counter_next = 0;
                        next = DATA;
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
            DATA : begin
                if(br_tick) begin
                    if(tick_counter_reg == 15) begin
                        tick_counter_next = 0;
                        temp_data_next = {rx,temp_data_next[7:1]};
                        if(bit_counter_reg == 7) begin
                            bit_counter_next = 0;
                            next = STOP;
                        end else begin
                            bit_counter_next = bit_counter_reg + 1;
                        end
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
            STOP : begin
                if(br_tick) begin
                    if(tick_counter_reg == 15)begin
                        rx_done_next = 1'b1;
                        tick_counter_next = 0;
                        next = IDLE; 
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule

module transmitter(
    input clk,
    input reset,
    input [7:0] tx_data,
    input tx_start,
    input br_tick,
    output  tx_done,
    output  tx_busy,
    output reg tx
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state, next;
    reg [7:0] temp_data_reg, temp_data_next;
    reg [3:0] tick_counter_reg, tick_counter_next;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg tx_busy_reg, tx_busy_next, tx_done_reg, tx_done_next;

    assign tx_done = tx_done_reg;
    assign tx_busy = tx_busy_reg; 

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= 0;
            temp_data_reg <= 0;
            tick_counter_reg <= 0; 
            bit_counter_reg <= 0;
            tx_done_reg <= 0;
            tx_busy_reg <= 0;
        end else begin
            state <= next;
            temp_data_reg <= temp_data_next;
            tick_counter_reg <= tick_counter_next;
            bit_counter_reg <= bit_counter_next;
            tx_done_reg <= tx_done_next;
            tx_busy_reg <= tx_busy_next;
        end
    end

    always @(*) begin
            next = state;
            temp_data_next = temp_data_reg;
            tick_counter_next = tick_counter_reg;
            bit_counter_next = bit_counter_reg;
            tx_done_next = tx_done_reg;
            tx_busy_next = tx_busy_reg;
            case(state)
                IDLE:begin
                    tx = 1'b1;
                    tx_busy_next = 1'b0;
                    tx_done_next = 1'b0;
                    if(tx_start) begin
                        next = START;
                        temp_data_next = tx_data; //temp라는 임시 저장소
                        tx_busy_next = 1'b1;
                    end
                end
                START:begin
                    tx = 1'b0;
                    if(br_tick) begin
                        if(tick_counter_reg == 15) begin
                            tick_counter_next = 0;
                            bit_counter_next = 0;  
                            next = DATA;
                        end else begin
                            tick_counter_next = tick_counter_reg + 1;
                        end
                    end
                end
                DATA:begin
                    tx = temp_data_reg[0];
                    if(br_tick)begin
                        if(tick_counter_reg == 15) begin
                            tick_counter_next = 0;
                            if(bit_counter_reg == 7) begin
                                next = STOP;
                            end else begin
                                bit_counter_next = bit_counter_reg + 1;
                                temp_data_next = {1'b0,temp_data_reg[7:1]}; //shift register
                            end
                        end else begin
                            tick_counter_next = tick_counter_reg + 1;
                        end
                    end
                end
                STOP:begin
                    tx = 1'b1;
                    if(br_tick) begin
                        if(tick_counter_reg == 15) begin
                            next = IDLE;
                            tick_counter_next = 0;
                            tx_done_next = 1'b1;
                        end else begin
                            tick_counter_next = tick_counter_reg + 1;
                        end
                    end
                end
        endcase
    end
endmodule

module baudrate_gen(
    input clk,
    input reset,
    output reg br_tick
);

    reg [13:0] br_counter;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            br_counter <= 0;
            br_tick <= 0; 
        end else begin
            if(br_counter == 100_000_000 /9600 /16 -1) // 100M를 9600으로 나눠 9600bps
                begin
                    br_counter <= 0;
                    br_tick <= 1'b1;
                end else begin
                    br_counter <= br_counter + 1;
                    br_tick <= 0;
                end
            end
        end
endmodule