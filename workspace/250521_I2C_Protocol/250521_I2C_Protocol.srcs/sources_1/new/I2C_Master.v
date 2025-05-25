`timescale 1ns / 1ps

module I2C_Master(
    //Global Input
    input clk,
    input reset,
    //external
    input [7:0] tx_data,
    input start,
    input stop,
    //input i2c_en,
    //output [7:0] rx_data,
    //interanal signal
    output reg SCL,
    //output reg SDA,
    inout  SDA,

    //additional for simulation
    output tx_done,
    input  ACK
    //output rx_done
);


    parameter IDLE = 0, START1 = 1, START2 = 2, HOLD1 = 3, DATA1 = 4, DATA2 = 5, DATA3 = 6,
              DATA4 = 7, HOLD2 = 8, STOP1 = 9, STOP2 = 10, HOLD4 = 20,
              ACK1_W = 15, ACK2_W = 16, ACK3_W = 17, ACK4_W = 18;//, READ1 = 11, READ2 = 12, READ3 = 13,
              //READ4 = 14, ACK1_W = 15, ACK2_W = 16, ACK3_W = 17, ACK4_W = 18,
              //ACK1_R = 19, ACK2_R = 20, ACK3_R = 21, ACK4_R = 22;

    reg [4:0] state, state_next;
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [7:0] temp_rx_data_reg, temp_rx_data_next;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg [8:0] scl_counter_reg, scl_counter_next;
    reg SDA_en, sda_reg;
    //additional
    reg tx_done_reg, tx_done_next;
    reg rx_done_reg, rx_done_next;

    assign tx_done = tx_done_reg;
    assign rx_done = rx_done_reg;

    assign SDA = (SDA_en) ? (sda_reg) : 1'bz;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state            <= IDLE;
            temp_tx_data_reg <= 0; 
            scl_counter_reg  <= 0;
            bit_counter_reg  <= 0;
            temp_rx_data_reg <= 0;
            tx_done_reg      <= 0;
            rx_done_reg      <= 0;
        end else begin
            state            <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            scl_counter_reg  <= scl_counter_next;
            bit_counter_reg  <= bit_counter_next;
            temp_rx_data_reg <= temp_rx_data_next;
            tx_done_reg      <= tx_done_next;
            rx_done_reg      <= rx_done_next;
        end
    end

always @(*) begin
    state_next        = state;
    temp_tx_data_next = temp_tx_data_reg;
    scl_counter_next  = scl_counter_reg;
    bit_counter_next  = bit_counter_reg;
    temp_rx_data_next = temp_rx_data_reg;
    tx_done_next      = tx_done_reg;
    rx_done_next      = rx_done_reg;
    sda_reg           = 0;
    SDA_en            = 0;
    case(state)
        //0
        IDLE: begin
            tx_done_next = 0;
            rx_done_next = 0;
            scl_counter_next = 0;
            bit_counter_next = 0;
            SCL = 1;
            sda_reg = 1;
            SDA_en = 1;
            temp_tx_data_next = tx_data[7:0];
            temp_rx_data_next = 8'h00;
            if(start) begin
                state_next = START1;
            end
        end
        //1
        START1 : begin
            SCL = 1;
            sda_reg = 0;
            SDA_en = 1;
            if(scl_counter_reg == 499) begin
                scl_counter_next = 0;
                state_next = START2;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //2
        START2 : begin
            SCL = 0;
            sda_reg = 0;
            SDA_en = 1;
            if(scl_counter_reg == 499) begin
                scl_counter_next = 0;
                state_next = DATA1;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //3
        HOLD1 : begin
            if(temp_tx_data_reg[7] == 0) begin
                state_next = DATA1;
            //end else begin
            //    state_next = READ1;
            end
            if(stop) begin
                state_next = STOP1;
            end
        end
        //4
        DATA1 : begin
            SCL = 0;
            sda_reg = temp_tx_data_reg[7];
            SDA_en = 1;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = DATA2;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //5
        DATA2 : begin
            SCL = 1;
            sda_reg = temp_tx_data_reg[7];
            SDA_en = 1;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = DATA3;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //6
        DATA3 : begin
            SCL = 1;
            sda_reg = temp_tx_data_reg[7];
            SDA_en = 1;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = DATA4;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //7
        DATA4 : begin
            SCL = 0;
            sda_reg = temp_tx_data_reg[7];
            SDA_en = 1;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                if(bit_counter_reg == 7) begin
                    //additional
                    tx_done_next = 1;
                    //
                    bit_counter_next = 0;
                    state_next = HOLD4;//ACK1_W;
                end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        bit_counter_next = bit_counter_reg + 1;
                        state_next = ACK1_W; //DATA1;
                    end
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end

        HOLD4 : begin
            SCL = 1;
            sda_reg = 0;
            SDA_en = 1;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = ACK1_W;
            end else begin
                scl_counter_next = scl_counter_reg + 1; 
            end
        end

        //15
        ACK1_W : begin
            tx_done_next = 0;
            SCL = 0;
            SDA_en = 0;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = ACK2_W;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //16
        ACK2_W : begin
            SCL = 1;
            SDA_en = 0;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = ACK3_W;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //17
        ACK3_W : begin
            SCL = 1;
            SDA_en = 0;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = ACK4_W;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //18
        ACK4_W : begin
            SCL = 0;
            SDA_en = 0;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = HOLD2;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        
        //8
        HOLD2 : begin
            SCL = 0;
            sda_reg = 0;
            SDA_en = 1;
            temp_tx_data_next = tx_data[7:0];
            //change state
            //state_next = DATA1;
            if(scl_counter_reg == 249) begin
                if(SDA == 0) begin
                    state_next = DATA1;// DATA1
                end else begin
                    state_next = STOP1;
                end
                if(stop) begin
                    state_next = STOP1;
                end
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //9
        STOP1 : begin //8
            SCL = 1;
            sda_reg = 0;
            SDA_en = 1;
            if(scl_counter_reg == 499) begin
                scl_counter_next = 0;
                state_next = STOP2;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //10
        STOP2 : begin
            SCL = 1;
            sda_reg = 1;
            SDA_en = 1;
            if(scl_counter_reg == 499) begin
                scl_counter_next = 0;
                state_next = IDLE;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
//      //
// read //
//      //
/*        //11
        READ1 : begin
            SCL = 0;
            SDA = 1'bz;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = READ2;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //12
        READ2 : begin
            SCL = 1;
            temp_rx_data_next[7] = SDA;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = READ3;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //13
        READ3 : begin
            SCL = 1;
            SDA = 1'bz;
            //temp_rx_data_next[7] = SDA;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = READ4;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //14
        READ4 : begin
            SCL = 0;
            SDA = 1'bz;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                if(bit_counter_reg == 7) begin
                    //additional
                    rx_done_next = 1;
                    //
                    bit_counter_next = 0;

                    rx_data[7:0] = temp_rx_data_reg[7:0];
                    state_next = ACK1_R;

                end else begin
                        //temp_rx_data_next = {temp_rx_data_reg[6:0], 1'b0};
                        bit_counter_next = bit_counter_reg + 1;
                        state_next = READ1;
                    end
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end

        ACK1_R : begin
            SCL = 0;
            SDA = 0;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = ACK2_R;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //5
        ACK2_R : begin
            SCL = 1;
            SDA = 0;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = ACK3_R;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //6
        ACK3_R : begin
            SCL = 1;
            SDA = 0;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = ACK4_R;
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
        //7
        ACK4_R : begin
            SCL = 0;
            SDA = 0;
            if(scl_counter_reg == 249) begin
                scl_counter_next = 0;
                state_next = HOLD2; 
            end else begin
                scl_counter_next = scl_counter_reg + 1;
            end
        end
*/
    endcase
end

endmodule

