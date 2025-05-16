`timescale 1ns / 1ps

module SPI_SLAVE(
    input   sclk,
    input  [7:0]  mosi,
    output   [7:0]  miso,
    input   cs,
    output [3:0] fnd_comm,
    output [7:0] fnd_font
    );

    parameter IDLE = 2'b00, CP0 = 2'b01, CP1 = 2'b10;
    reg [1:0] state_reg, state_next;



    always @(posedge clk) begin
        if(reset) begin
            state_reg <= 0;
            temp_tx_data_reg <= 0;
            bit_counter_reg <= 0;
            sclk_counter_reg <= 0;
            done_reg <= 0;
            ready_reg <= 0;
            cs_reg <= 1'b1;
        end else begin
            state_reg <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            bit_counter_reg <= bit_counter_next;
            sclk_counter_reg <= sclk_counter_next;
            done_reg <= done_next;
            ready_reg <= ready_next;
            cs_reg <= cs_next;
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
           case(state_reg)
            IDLE: begin
                temp_tx_data_next = 8'h0;
                done_next = 1'b0;
                ready_next = 1'b1;
                cs_next = 1'b1;
                if(sclk) begin
                    if(start)begin
                        cs_next = 1'b0;
                        ready_next = 1'b0;
                        state_next = CP0;
                    end else begin
                        state_next = IDLE;
                    end
                end
            end
            CP0: begin
                if(sclk) begin
                    if(sclk_counter_reg == 49) begin
                        sclk_counter_next = 0;
                        state_next = CP1;
                    end else begin
                        sclk_counter_next = sclk_counter_reg + 1;
                    end
                end
            end
            CP1: begin
                if(sclk) begin
                    if(sclk_counter_reg == 49) begin
                        sclk_counter_next = 0;
                        if(bit_counter_reg == 7) begin
                            done_next = 1'b1;
                            bit_counter_next = 0;
                            state_next = IDLE;
                        end else begin
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

/*
module spi(
    input sclk,
    input [7:0] mosi,
    output [7:0] miso,
    input cs,
    output [7:0] data,
    output done
);
    always @() begin
        
    end

    always @(*) begin
        case(state_reg)
            IDLE :
            L_BYTE :
            H_BYTE :
        endcase
    end
endmodule

module fsm(
    input [7:0] data,
    input done,
    output fnd
);
endmodule
*/