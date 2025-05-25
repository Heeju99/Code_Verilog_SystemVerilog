`timescale 1ns / 1ps

module I2C_Slave (
    input        clk,
    //external port
    input        DONE,
    input        SRESET,
    input       SCL,
    inout        SDA,     //inout
    output [7:0] LED
);

    localparam IDLE = 0, START = 1, ADDR = 2, DATA = 3, WRITE = 4, STOP = 5, HOLD = 6,
               WAIT = 7, STORE = 8, SS = 9;
    localparam Slave_ADDR = 7'b110_0000;

    reg       sda_next, sda_reg, sclk_sync0, sclk_sync1, SDA_en, SDA_en_next;
    reg [3:0] state, state_next;
    reg [7:0] addr_next, addr_reg;
    reg [7:0] led_next, led_reg;
    reg [$clog2(7)-1:0] bit_counter_next, bit_counter_reg;
    reg [$clog2(1250)-1:0] clk_counter_next, clk_counter_reg;

    assign SDA = (SDA_en) ? sda_reg : 1'bz;
    assign LED = led_reg;

    // rising, falling edge detector

    always @(posedge clk, posedge SRESET) begin
        if (SRESET) begin
            sclk_sync0 <= 0;
            sclk_sync1 <= 0;
        end else begin
            sclk_sync0 <= SCL;
            sclk_sync1 <= sclk_sync0;
        end
    end

    assign sclk_rising = (sclk_sync0 && ~sclk_sync1) ? 1 : 0;
    assign sclk_falling = (~sclk_sync0 && sclk_sync1) ? 1 : 0;



    //FSM

    always @(posedge clk, posedge SRESET) begin
        if (SRESET) begin
            state           <= 0;
            bit_counter_reg <= 0;
            led_reg         <= 0;
            sda_reg         <= 0;
            addr_reg        <= 0;
            clk_counter_reg <= 0;
            SDA_en          <= 0;
        end else begin
            state           <= state_next;
            bit_counter_reg <= bit_counter_next;
            led_reg         <= led_next;
            sda_reg         <= sda_next;
            addr_reg        <= addr_next;
            clk_counter_reg <= clk_counter_next;
            SDA_en          <= SDA_en_next;
        end
    end

    always @(*) begin
        state_next       = state;
        bit_counter_next = bit_counter_reg;
        led_next         = led_reg;
        sda_next         = sda_reg;
        SDA_en_next      = SDA_en;
        addr_next        = addr_reg;
        clk_counter_next = clk_counter_reg;

        case (state)
            //0
            IDLE: begin
                bit_counter_next = 0;
                SDA_en_next      = 0;
                if (SCL && !SDA) begin
                    state_next = HOLD; 
                end
            end
            //6
            HOLD: begin
                if (clk_counter_reg == 499) begin
                    clk_counter_next = 0;
                    state_next       = START;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            //1
            START: begin
                SDA_en_next = 0;
                if (sclk_falling) begin
                    addr_next = {addr_reg[6:0], SDA};
                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        state_next = ADDR;
                    end
                    else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end 
                end
            end
            //2
            ADDR: begin
                SDA_en_next = 0;
                if (clk_counter_reg == 249) begin
                    if (addr_reg[7:1] == Slave_ADDR) begin
                        state_next = WRITE;
                    end
                    else begin
                        state_next = STOP;
                    end
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            //3
            DATA: begin
                SDA_en_next = 0;
                if (sclk_falling) begin
                    led_next = {led_reg[6:0], SDA};
                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        state_next = STORE;
                    end
                    else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end 
                end
            end
            //8
            STORE: begin
                SDA_en_next = 0;
                if (clk_counter_reg == 249) begin
                    clk_counter_next = 0;
                    state_next = SS;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            //4
            WRITE: begin
                SDA_en_next  = 1;
                sda_next     = 1'b0;
                if (clk_counter_reg == 1245) begin
                    clk_counter_next = 0;
                    state_next       = WAIT;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            //9
            SS: begin
                SDA_en_next = 1;
                sda_next    = 1'b0;
                if (clk_counter_reg == 996) begin
                    clk_counter_next = 0;
                    state_next       = WAIT;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            //7
            WAIT: begin
                SDA_en_next = 0;
                if (clk_counter_reg == 1001) begin
                    if (SCL==1) begin
                        state_next = STOP;
                    end
                    else state_next = DATA;
                    clk_counter_next = 0;
                end else begin
                    clk_counter_next = clk_counter_reg + 1;
                end
            end
            //5
            STOP: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule