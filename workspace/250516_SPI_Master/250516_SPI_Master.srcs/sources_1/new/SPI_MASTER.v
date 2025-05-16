`timescale 1ns / 1ps

module SPI_MASTER(
    //Global Signal
    input     clk,
    input     reset,
    //Master Left Signal
    input    start,
    input    [7:0] tx_data,
    output  reg [7:0] rx_data,
    output    done,
    output    ready,
    //to Slave Signal
    output   sclk,
    output   mosi,
    input    miso,
    output   cs 
    );

    wire tick;

    clk_1MHZ_div U_clk_1MHZ_div(
        .clk(clk),
        .reset(reset),
        .tick(tick)
);

    parameter IDLE = 2'b00, CP0 = 2'b01, CP1 = 2'b10;
    reg [1:0] state_reg, state_next;
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg [5:0] sclk_counter_reg, sclk_counter_next;
    reg done_reg, done_next;
    reg ready_reg, ready_next;
    reg cs_reg, cs_next;
    reg sclk_reg, sclk_next;

    assign done = done_reg;
    assign ready = ready_reg;
    assign cs = cs_reg;
    assign mosi = temp_tx_data_reg[7];
    assign sclk = sclk_reg;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state_reg <= 0;
            temp_tx_data_reg <= 0;
            bit_counter_reg <= 0;
            sclk_counter_reg <= 0;
            done_reg <= 0;
            ready_reg <= 0;
            cs_reg <= 1'b1;
            sclk_reg <= 0;
        end else begin
            state_reg <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            bit_counter_reg <= bit_counter_next;
            sclk_counter_reg <= sclk_counter_next;
            done_reg <= done_next;
            ready_reg <= ready_next;
            cs_reg <= cs_next;
            sclk_reg <= sclk_next;
        end
    end

    always @(*) begin
        state_next = state_reg;
        temp_tx_data_next = temp_tx_data_reg;
        bit_counter_next = bit_counter_reg;
        sclk_counter_next = sclk_counter_reg;
        done_next = done_reg;
        ready_next = ready_reg;
        cs_next = cs_reg;
        sclk_next = sclk_reg;
        case(state_reg)
            IDLE: begin
                temp_tx_data_next = 8'h0;
                done_next = 1'b0;
                ready_next = 1'b1;
                cs_next = 1'b1;
                sclk_next = 1'b0;
                if(tick) begin
                    if(start)begin
                        cs_next = 1'b0;
                        temp_tx_data_next = tx_data;
                        ready_next = 1'b0;
                        state_next = CP0;
                    end else begin
                        state_next = IDLE;
                    end
                end
            end
            CP0: begin
                sclk_next = 0;
                if(tick) begin
                    if(sclk_counter_reg == 49) begin
                        rx_data = {rx_data[6:0],miso};
                        sclk_counter_next = 0;
                        state_next = CP1;
                    end else begin
                        sclk_counter_next = sclk_counter_reg + 1;
                    end
                end
            end
            CP1: begin
                sclk_next = 1;
                if(tick) begin
                    if(sclk_counter_reg == 49) begin
                        sclk_counter_next = 0;
                        if(bit_counter_reg == 7) begin
                            done_next = 1'b1;
                            bit_counter_next = 0;
                            state_next = IDLE;
                        end else begin
                            temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                            bit_counter_next = bit_counter_reg + 1;
                            state_next = CP0;
                        end
                    end else begin
                        sclk_counter_next = sclk_counter_reg + 1;
                    end
                end
            end
        endcase    
    end
endmodule


module clk_1MHZ_div(
    input  clk,
    input  reset,
    output  tick
);
    reg [6:0] counter_reg, counter_next;
    reg tick_reg, tick_next;

    assign tick = tick_reg;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            counter_reg <= 0;
            tick_reg <= 0;
        end else begin
            counter_reg <= counter_next;
            tick_reg <= tick_next;
        end
    end

    always @(*) begin
        if(counter_reg == 99) begin
            tick_next = 1'b1;
            counter_next = 0;
        end else begin
            tick_next = 1'b0;
            counter_next = counter_reg + 1;
        end
    end
endmodule