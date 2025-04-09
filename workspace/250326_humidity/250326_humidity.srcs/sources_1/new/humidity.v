`timescale 1ns / 1ps

module humidity(
        input clk,
        input reset,
        input btn_start,
        input switch,
        output [3:0] led,
        output led7,
        //output [39:0] data, //39
        output [7:0] seg,
        output [3:0] seg_comm,
        inout dht_IO
    );

    wire w_o_tick;
    wire [39:0] w_data;
    wire [15:0] w_change_data;
    wire w_btn_start;
    assign data = w_data;
    clk_1usec u_clk_1usec(
        .clk(clk), 
        .reset(reset),
        .o_tick(w_o_tick)
);

    checksum u_checksum(
        .data(w_data),
        .led(led7)
    );

    button_debounce u_button_debounce(
        .clk(clk),
        .reset(reset),
        .i_btn(btn_start),
        .o_btn(w_btn_start)
    );

    mux_1x2 u_mux_1x2(
        .switch(switch),
        .data(w_data),
        .change_data(w_change_data)
);

    dnt11_controller u_dnt11_controller(
        .clk(clk),
        .reset(reset),
        .o_tick(w_o_tick),
        .btn_start(w_btn_start),
        .led(led),
        .data(w_data),
        .dht_IO(dht_IO)
);

    fnd_controller u_fnd_controller(
        .clk(clk), 
        .reset(reset),
        .bcd(w_change_data),
        .seg(seg),
        .seg_comm(seg_comm)
);

endmodule

module mux_1x2(
    input switch,
    input [39:0] data,
    output reg [15:0] change_data
);

    // * : input 모두 감시, 아니면 개별 입력 선택할 수 있다.
    // always : 항상 감시한다 @이벤트 이하를 ()의 변화가 있으면, begin-end를 수행하라.
    always @(*) begin // ,대신 or도 가능함
        case(switch)
            1'b0: change_data = data[39:24]; //humid
            1'b1: change_data = data[23:8]; //temp
            default:  change_data  = 4'bx;
        endcase
    end

endmodule

module dnt11_controller(
    input clk,
    input reset,
    input o_tick,
    input btn_start,
    output [3:0] led,
    output [39:0] data, //39
    inout dht_IO
);
    /*parameter START_CNT = 1800, WAIT_CNT =3, SYNC_CNT = 8, DATA_SYNC = 5,
              DATA_0 = 4, DATA_1 = 7, STOP_CNT = 5, TIMEOUT = 2000;*/
    parameter IDLE = 3'b000, START = 3'b001, WAIT = 3'b010, SYNC_LOW = 3'b011, 
              SYNC_HIGH = 3'b100, SYNC_DATA = 3'b101 , SYNC_DC = 3'b110, STOP = 3'b111;
    reg [2:0] state, next;
    reg [14:0] count_reg, count_next;
    reg io_oe_reg, io_oe_next;  //IO MODE change
    reg io_out_reg, io_out_next;
    reg led_reg, led_next;

    //additional
    reg [39:0] data_reg, data_next; //39
    reg [5:0] bit_count_reg, bit_count_next;


    //out 3state on/off
    assign led = {led_reg,state};
    assign dht_IO = (io_oe_reg) ? io_out_reg : 1'bz; //모드 설정
    assign data = data_reg;

    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                state <= 0;
                count_reg <= 0;
                led_reg <= 0;
                io_out_reg <= 1'b1;  //IDLE일때 HIGH로
                io_oe_reg <= 0;
                data_reg <= 0;
                bit_count_reg <= 0; 
            end else begin
                state <= next;
                count_reg <= count_next;
                led_reg <= led_next;
                io_out_reg <= io_out_next;
                io_oe_reg <= io_oe_next;
                data_reg <= data_next;
                bit_count_reg <= bit_count_next;
            end
        end
    always@(*)
        begin
            next = state;
            count_next = count_reg;
            io_out_next = io_out_reg;
            io_oe_next = io_oe_reg;  
            led_next = led_reg;
            //additional
            data_next = data_reg;
            bit_count_next = bit_count_reg;
            case(state)
                IDLE : begin
                    io_out_next = 1'b1;
                    io_oe_next = 1'b1;  //항상 출력모드로 설정
                    if(btn_start) begin
                        data_next = 0;
                        next = START;
                        count_next = 0;
                    end
                end
                START : begin
                    io_out_next = 1'b0;
                    if(o_tick) begin
                        if(count_reg == 18_000) begin  //18ms
                            next = WAIT;
                            count_next = 0;
                        end else begin
                            count_next = count_reg + 1;
                        end
                    end
                end
                WAIT : begin
                    io_out_next = 1'b1;
                    if(o_tick) begin
                        if(count_reg == 30) begin     //30us, WAIT_CNT => 10ms change
                            count_next = 0;
                            next  = SYNC_LOW;
                            io_oe_next = 1'b0;
                        end else begin
                            count_next = count_reg + 1;
                        end
                    end
                end
                SYNC_LOW : begin
                    if(o_tick) begin
                        if(count_reg == 20) begin
                            if(dht_IO) begin
                                count_next = 0;
                                next = SYNC_HIGH;
                            end
                        end else begin
                            count_next = count_reg + 1;
                        end
                    end
                end
                SYNC_HIGH :  begin
                    if(o_tick) begin
                        if(dht_IO == 0) begin
                            next = SYNC_DATA;
                        end
                    end
                end
                SYNC_DATA : begin
                    if(o_tick) begin
                        count_next = 0;
                        if(bit_count_reg == 40) begin
                            bit_count_next = 0;
                            count_next = 0;
                            next = STOP;
                        end else begin
                            if(dht_IO) begin
                                next = SYNC_DC;
                            end
                        end
                end
                    end
                        /*if(dht_IO) begin
                        //if(o_tick) begin
                            if(bit_count_reg == 40) begin //bit count, 40
                                bit_count_next = 0;
                                count_next = 0;
                                next = STOP;
                            end else begin
                                next = SYNC_DC;
                            end 
                        //end
                    end
                end*/
                SYNC_DC : begin
                    if(o_tick) begin
                        if(dht_IO == 0) begin
                            if(count_reg > 40) begin  //bit length
                                data_next[39 - (bit_count_reg)] = 1'b1;
                                bit_count_next = bit_count_reg + 1;
                                next = SYNC_DATA;
                            end else begin
                                data_next[39-(bit_count_reg)] = 1'b0;
                                bit_count_next = bit_count_reg + 1;
                                next = SYNC_DATA;
                            end
                        end else begin
                            count_next = count_reg + 1;
                        end
                    end

                end
                STOP : begin
                    if(o_tick) begin
                        if(count_reg == 50) begin
                            next = IDLE;
                            count_next = 0;
                        end else begin
                            count_next = count_reg + 1;
                        end
                    end
                end
            endcase
        end
endmodule

module clk_1usec(
    input clk, reset,
    output o_tick
);
    // for test --> 속도 10M정도로 올렷음   10ns -> 1msec  1usec = 100
    parameter FCOUNT = 100; //1us tick generate
    reg [$clog2(FCOUNT)-1:0] count_reg, count_next;
    reg tick_reg, tick_next; // 출력을 f/f으로 내보내기 위해서.

    assign o_tick = tick_reg; // 최종 출력. 

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            count_reg <= 0;
            tick_reg <= 0;
        end else begin 
            count_reg <= count_next;
            tick_reg <= tick_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        tick_next = 1'b0; // clk_reg;
            if(count_reg == (FCOUNT - 1)) begin
                count_next = tick_reg;
                tick_next = 1'b1; // 출력 high
            end else begin
                count_next = count_reg + 1;
                tick_next = 1'b0;
            end 
    end
endmodule