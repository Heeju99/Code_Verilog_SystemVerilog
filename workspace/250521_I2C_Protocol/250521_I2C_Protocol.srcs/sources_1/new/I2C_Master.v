`timescale 1ns / 1ps

module I2C_Master(
    //Global Input
    input clk,
    input reset,
    //external
    input [7:0] tx_data,
    input start,
    input i2c_en,
    input stop,
    //interanal signal
    output reg SCL,
    output reg SDA,

    //additional
    output tx_done,
    input  ACK
);

    parameter IDLE = 0, START1 = 1, START2 = 2, DATA1 = 3, DATA2 = 4, DATA3 = 5, DATA4 = 6,
              HOLD = 7, STOP1 = 8, STOP2 = 9;

    reg [3:0] state, state_next;
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg [8:0] scl_counter_reg, scl_counter_next;
    reg tx_done_reg, tx_done_next;

    assign tx_done = tx_done_reg;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state            <= IDLE;
            temp_tx_data_reg <= 0; 
            scl_counter_reg  <= 0;
            bit_counter_reg  <= 0;
            tx_done_reg      <= 0;
        end else begin
            state            <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            scl_counter_reg  <= scl_counter_next;
            bit_counter_reg  <= bit_counter_next;
            tx_done_reg      <= tx_done_next;
        end
    end

always @(*) begin
    state_next        = state;
    temp_tx_data_next = temp_tx_data_reg;
    scl_counter_next  = scl_counter_reg;
    bit_counter_next  = bit_counter_reg;
    tx_done_next      = tx_done_reg;
    case(state)
        IDLE: begin
            tx_done_next = 0;
            scl_counter_next = 0;
            bit_counter_next = 0;
            SCL = 1;
            SDA = 1;
            temp_tx_data_next = tx_data[7:0];
            if(start) begin
                state_next = START1;
            end
        end
        START1 : begin
            SCL = 1;
            SDA = 0;
            if(scl_counter_reg == 499) begin
                scl_counter_next = 0;
                state_next = START2;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        START2 : begin
            SCL = 0;
            SDA = 0;
            if(scl_counter_reg == 499) begin
                scl_counter_next = 0;
                state_next = DATA1;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end

        DATA1 : begin
            SCL = 0;
            SDA = temp_tx_data_reg[7];
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = DATA2;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        DATA2 : begin
            SCL = 1;
            SDA = temp_tx_data_reg[7];
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = DATA3;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        DATA3 : begin
            SCL = 1;
            SDA = temp_tx_data_reg[7];
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = DATA4;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        DATA4 : begin
            SCL = 0;
            SDA = temp_tx_data_reg[7];
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                if(bit_counter_reg == 7) begin
                    //additional
                    tx_done_next = 1;
                    //
                    bit_counter_next = 0;
                    if(ACK == 1) begin //slave의 응답 확인
                        state_next = HOLD;
                    end else begin
                        state_next = STOP1;
                    end
                end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        bit_counter_next = bit_counter_reg + 1;
                        state_next = DATA1;
                    end
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        HOLD : begin //7
            //write
            if(temp_tx_data_reg[7] == 0) begin
                temp_tx_data_next = tx_data[7:0];
                state_next = DATA1;
            //end else begin
            //    state_next = READ1;
            end
            if(stop) begin
                state_next = STOP1;
            end
        end
        STOP1 : begin //8
            SCL = 1;
            SDA = 0;
            if(scl_counter_reg == 499) begin
                state_next = STOP2;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        STOP2 : begin
            SCL = 1;
            SDA = 1;
            if(scl_counter_reg == 499) begin
                state_next = IDLE;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end

    endcase
end

endmodule

