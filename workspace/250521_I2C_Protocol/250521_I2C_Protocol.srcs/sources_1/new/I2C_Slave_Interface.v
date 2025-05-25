`timescale 1ns / 1ps

module I2C_Slave_Interface(
    input clk,
    input reset,
    //external Signal
    input SCL,
    inout SDA
);

    parameter ADDR = 7'b0000_001;
    localparam IDLE = 0, ADD = 1, WRITE = 2, HOLD = 3, DATA = 4, STOP = 5, WAIT = 6, CHECK_ADDR = 7;

    reg [2:0] state, state_next;
    reg [7:0] temp_slave_data_reg, temp_slave_data_next;
    reg [7:0] temp_rx_data_reg, temp_rx_data_next;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg sda_reg, SDA_en;

    reg flag;

    assign SDA = (SDA_en) ? (sda_reg) : 1'bz;


//additional
    reg sclk_sync0, sclk_sync1;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            sclk_sync0 <= 0;
            sclk_sync1 <= 0;
        end else begin
            sclk_sync0 <= SCL;
            sclk_sync1 <= sclk_sync0;
        end
    end
    wire scl_rising  = sclk_sync0 & ~sclk_sync1;
    wire scl_falling = ~sclk_sync0 & sclk_sync1;


    always @(negedge SCL) begin
        if(SDA == 0) begin
            flag <= 1;
        end else begin
            flag <= 0;
        end
    end

    always @(posedge SCL, posedge reset) begin
        if(reset) begin
            state               <= IDLE;
            bit_counter_reg     <= 0;
            temp_rx_data_reg    <= 0;
            temp_slave_data_reg <= 0;
        end else begin
            state               <= state_next;
            bit_counter_reg     <= bit_counter_next;
            temp_rx_data_reg    <= temp_rx_data_next;
            temp_slave_data_reg <= temp_slave_data_next;
        end
    end

/*
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= IDLE;
            temp_slave_data_reg <= 0;
            temp_rx_data_reg    <= 0;
            bit_counter_reg     <= 0;
        end else begin
            state               <= state_next;
            temp_slave_data_reg <= temp_slave_data_next;
            temp_rx_data_reg    <= temp_rx_data_next;
            bit_counter_reg     <= bit_counter_next;
        end
    end
*/

    always @(*) begin
        state_next           = state;
        temp_slave_data_next = temp_slave_data_reg;
        temp_rx_data_next    = temp_rx_data_reg;
        bit_counter_next     = bit_counter_reg;
        case(state)
            IDLE   : begin
                SDA_en = 0;
                if(flag) begin
                //if(SDA == 0) begin//SCL == 1 && 
                    sda_reg = 0;
                    SDA_en = 1;
                    state_next = ADD;
                end
            end
            ADD : begin
                SDA_en = 0;
                temp_slave_data_next = {temp_slave_data_reg[6:0], SDA};
                    if(bit_counter_reg == 7) begin
                        SDA_en = 0;
                        bit_counter_next = 0;
                        if(temp_slave_data_reg[7:1] == ADDR) begin //주소 비교
                            state_next = WRITE; //WRITE;
                        end
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
            end
            
            //SEND ACK to Master
            WRITE : begin 
                    sda_reg = 0;
                    SDA_en = 1;
                    if(scl_falling) begin
                    state_next = HOLD;
                end
            end

            HOLD : begin
                SDA_en = 0;
                if(SCL == 1 && SDA == 0) begin
                    state_next = STOP;
                end else begin
                    state_next = DATA;
                end
            end

            DATA : begin
                SDA_en = 0;
                temp_rx_data_next = {temp_rx_data_reg[6:0], SDA};
                if(bit_counter_reg == 7) begin
                    state_next = HOLD;
                    bit_counter_next = 0;
                end else begin
                    bit_counter_next = bit_counter_reg + 1;
                end 
            end

            STOP : begin
                SDA_en = 0;
                if(SCL == 1 && SDA == 1) begin
                    state_next = IDLE;
                end
            end
        endcase
    end
endmodule
