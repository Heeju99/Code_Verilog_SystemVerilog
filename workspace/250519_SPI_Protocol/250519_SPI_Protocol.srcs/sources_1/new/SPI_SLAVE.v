`timescale 1ns / 1ps

module SPI_SLAVE(

    );
endmodule

module SPI_SLAVE_Interface(
    input        reset,
    //External Signals
    input        SCLK,
    input        MOSI,
    output       MISO,
    input        SS,
    //Internal Signals
    output  reg  done,
    output       write,
    output [1:0] addr,
    output [7:0] wdata,
    input  [7:0] rdata
);

    localparam IDLE = 2'b00, CP0 = 2'b01, CP1 = 2'b10;

    reg [1:0] state, state_next;
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [7:0] temp_rx_data_reg, temp_rx_data_next;
    reg [2:0] bit_counter_reg, bit_counter_next;

    assign MISO = SS ? (1'bz) : temp_tx_data_reg[7]; //Miso는 Register의 7번째 값만

    //MOSI sequence (posedge SCLK)
    //Rising Edge에서 Data를 sampling
    always @(posedge SCLK) begin
        if(SS == 0) begin
            temp_rx_data_reg <= {temp_rx_data_reg[6:0], MOSI};
        end    
    end

    //MISO sequence (negedge SCLK)
    //Falling Edge에서 Data를 출력
    always @(negedge SCLK) begin
    end

    always @(*) begin
        state_next = state;
        temp_tx_data_next = temp_tx_data_reg;
        case(state)
            SO_IDLE : begin
                if(SS == 0 && rd_en) begin
                    temp_tx_data_next = rdata;
                    state_next = SO_DATA;
                end
            end
            SO_DATA : begin
                if(SS == 0 && rd_en) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0],1'b0};
                end
            end
        endcase
    end

    always @(negedge SCLK) begin
        if (!ss && en) begin
            temp_tx_data_reg <= rdata;
            en <= 1'b0;
        end else if (!ss) begin
            temp_tx_data_reg <= {temp_tx_data_reg[6:0], 1'b0};
        end else begin
            en <= 1'b1;
        end
    end


// nope ?
    always @(posedge SCLK, posedge reset) begin
        if(reset) begin
            state <= IDLE;
            temp_tx_data_reg <= 0; 
            temp_rx_data_reg <= 0;
            bit_counter_reg  <= 0;
        end else begin
            state <= state_next;
            temp_tx_data_reg <= temp_tx_data_next; 
            temp_rx_data_reg <= temp_rx_data_next;
            bit_counter_reg  <= bit_counter_next;
        end    
    end

    always @(*) begin
        temp_tx_data_next = temp_tx_data_reg;
        temp_rx_data_next = temp_rx_data_reg;
        bit_counter_next  = bit_counter_reg;
        case(state)
            IDLE : begin
                if(SS == 0) begin
                    temp_tx_data_next = rdata;
                end
            end
            CP0  : begin
                if(SCLK == 1) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0], MOSI};
                    state_next = CP1;
                end
            end
            CP1  : begin
                if(SCLK == 0) begin
                    if(bit_counter_reg == 7) begin
                        done = 1'b1;
                        state_next = IDLE;
                    end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        bit_counter_next = bit_counter_reg + 1;
                        state_next = CP0;
                    end
                end
            end
        endcase
    end
endmodule