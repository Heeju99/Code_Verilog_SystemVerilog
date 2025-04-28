`timescale 1ns / 1ps

module ultrasonic_periph(
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // export signals
    //output logic [ 8:0] dist,
    output logic        trigger,
    input  logic        echo
);

    logic       fcr_en;
    logic [8:0] distance;
    logic       echo_done;

    APB_SlaveIntf_sensor U_APB_Intf_sensor (.*);
    sensor_dp U_sensor_IP (.*);
endmodule

module APB_SlaveIntf_sensor (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    output logic        fcr_en,
    input  logic [ 8:0] distance,
    //additional
    input  logic        echo_done
);
    logic [31:0] slv_reg0, slv_reg1;//, slv_reg2, slv_reg3;

    assign fcr_en = slv_reg0[0];   // 출력 여부 사용 (1: 사용 , 0: 비활성화)
    assign slv_reg1[8:0] = distance;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0; //fcr_en
            //slv_reg1 <= 0; //dist
            //slv_reg2 <= 0; 
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                    if (PWRITE) begin
                        case (PADDR[3:2])
                            2'd0: slv_reg0 <= PWDATA;   //fcr_en
                            2'd1: ;                     //dist
                            //2'd2: slv_reg2 <= PWDATA; 
                            // 2'd3: slv_reg3 <= PWDATA;
                        endcase
                end else begin
                    PRDATA <= 32'bx;
                        case (PADDR[3:2])
                            2'd0: PRDATA <= slv_reg0;  //fcr_en
                            2'd1: PRDATA <= slv_reg1;  //dist
                            //2'd2: PRDATA <= slv_reg2;  
                            // 2'd3: PRDATA <= slv_reg3;
                        endcase
                    end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module sensor_dp(
    input  logic PCLK,
    input  logic PRESET,
    input  logic echo,
    //input btn_start,
    //additional
    input  logic fcr_en,
    output logic trigger,
    output logic [8:0] distance,
    //additional
    output logic echo_done
    );

    clk_div_100 u_clk_div_100(
    .clk(PCLK), 
    .reset(PRESET),
    .o_tick(o_tick)
);

    parameter IDLE = 2'b00, START = 2'b01, HIGH_COUNT = 2'b10, DIST_CAL = 2'b11;
    logic [1:0] state, next;
    logic trigger_reg, trigger_next; //tick register
    logic trigger_1us_reg, trigger_1us_next;
    logic [3:0] tick_count_reg, tick_count_next;
    logic [14:0]tick_1us_count_reg, tick_1us_count_next; 
    logic [8:0] dist_reg, dist_next;
    //additional
    logic echo_done_reg, echo_done_next;

    assign echo_done = echo_done_reg;
    assign trigger = trigger_reg;
    assign distance = dist_reg;
    always@(posedge PCLK, posedge PRESET)
        begin
            if(PRESET) begin
                state <= 0;
                tick_count_reg <= 0;
                tick_1us_count_reg <= 0;
                trigger_reg <= 0;
                trigger_1us_reg <=0;
                dist_reg <= 0;
                echo_done_reg <= 0; 
            end
            else begin
                state <= next;
                tick_count_reg <= tick_count_next;
                tick_1us_count_reg <= tick_1us_count_next;
                trigger_reg <= trigger_next;
                trigger_1us_reg <= trigger_1us_next;
                dist_reg <= dist_next;
                echo_done_reg <= echo_done_next;
            end
        end

    always@(*)begin
        next = state;
        trigger_next = trigger_reg;
        trigger_1us_next = trigger_1us_reg;
        tick_count_next = tick_count_reg;
        tick_1us_count_next = tick_1us_count_reg;
        dist_next = dist_reg;
        //additional
        echo_done_next = echo_done_reg;
            case(state)
                IDLE: begin
                    trigger_next = 0;
                    echo_done_next = 0;
                    if(fcr_en) begin
                        next = START;
                    end
                end
                START : begin
                    if(o_tick) begin
                        if(tick_count_reg == 10) begin
                            trigger_next = 0;
                            tick_count_next = 0;
                         
                            next = HIGH_COUNT;
                       
                            //next = HIGH_COUNT;
                        end else begin
                            trigger_next = 1;
                            tick_count_next = tick_count_reg + 1;
                        end
                    end
                    //if(trigger_reg == 0) begin
                    //    next = HIGH_COUNT;
                    //end
                end
                HIGH_COUNT : begin
                    dist_next = 0; 
                    tick_1us_count_next = 0;
                    if(echo) begin
                        next = DIST_CAL;
                    end
                end
                DIST_CAL : begin
                    if(o_tick) begin
                        tick_1us_count_next = tick_1us_count_reg + 1;   
                    end
                    if(echo == 0) begin
                        echo_done_next = 1;
                        if(dist_reg > 400) begin
                            dist_next = 400;
                        end else if (tick_1us_count_reg > 23500)begin
                            next = IDLE;
                        end else begin
                            dist_next = tick_1us_count_reg /58;
                            next = IDLE;
                        end
                    end
                end
        endcase
    end
endmodule

module clk_div_100(
    input  logic clk,
    input  logic reset,
    output logic o_tick
);
    // for test --> 속도 10M정도로 올렷음
    parameter FCOUNT = 100; //1us tick generate
    logic [$clog2(FCOUNT)-1:0] count_reg, count_next;
    logic tick_reg, tick_next; // 출력을 f/f으로 내보내기 위해서.

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
/*
    module sensor(
    input  logic clk,
    input  logic reset,
    input  logic echo,
    input  logic btn_start,
    output logic trigger,
    input  logic rx,
    output logic tx,
    output logic [7:0] seg,
    output logic [3:0] seg_comm,
    output logic led
);

    assign led = echo;
    wire [8:0] dist;
    wire o_btn_start;

    wire w_rx_done, w_tx_done;
    wire full_rx, empty_rx, full_tx, empty_tx;
    wire [7:0] data_rx_tx, rdata_tx, wdata_rx;
    //additional
    wire w_echo_done;
    wire [3:0] w_digit_1, w_digit_10, w_digit_100;
    wire [7:0] w_o_bcd;
    wire [7:0] w_split_data_100, w_split_data_10, w_split_data_1;
    wire w_enable_wr;

    button_debounce u_button_debounce(
        .clk(clk),
        .reset(reset),
        .i_btn(btn_start),
        .o_btn(o_btn_start)
    );

    sensor_dp u_sensor_dp(
        .clk(clk),
        .reset(reset),
        .echo(echo), //input
        .btn_start(o_btn_start | (data_rx_tx == "o" & ~empty_rx)),
        .trigger(trigger), //output
        .echo_done(w_echo_done), //additional
        .dist(dist)
    );

     top_uart u_top_uart(
        .clk(clk),
        .reset(reset),
        .btn_start(~empty_tx),
        .tx_data_in(rdata_tx),
        .tx(tx),
        .tx_done(w_tx_done),
        .rx(rx),
        .rx_done(w_rx_done),
        .rx_data(wdata_rx)
    );

    FIFO u_fifo_RX(
        .clk(clk),
        .reset(reset),
        .wdata(wdata_rx),
        .wr(w_rx_done),
        .rd(~full_tx), //얘도 바꿔야댐 (~full_tx)
        .full(full_rx),
        .empty(empty_rx), //수정
        .rdata(data_rx_tx) //sensor dp btn_start와 or 연산
    );

    FIFO u_fifo_TX(
        .clk(clk),
        .reset(reset),
        .wdata(w_o_bcd), // splitter_use에서 나오는 split_data연결(data_rx_tx)
        .wr(w_enable_wr), // 수정
        .rd(~w_tx_done),
        .full(full_tx),  //없앰 (full_tx)
        .empty(empty_tx),
        .rdata(rdata_tx)
    );

    splitter_change u_splitter_100(
        .bcd(w_digit_100), 
        .split_data(w_split_data_100) 
    );

    splitter_change u_splitter_10(
        .bcd(w_digit_10), 
        .split_data(w_split_data_10) 
    );

    splitter_change u_splitter_1(
        .bcd(w_digit_1), 
        .split_data(w_split_data_1) 
    );

    digit_send u_digit_send(
        .clk(clk),
        .reset(reset),
        .split_data_100(w_split_data_100),
        .split_data_10(w_split_data_10),
        .split_data_1(w_split_data_1),
        .echo_done(w_echo_done),
        .enable_wr(w_enable_wr),
        .o_bcd(w_o_bcd)
);

    fnd_controller u_fnd_controller(
        .clk(clk), 
        .reset(reset),
        .bcd(dist),
        .seg(seg),
        .seg_comm(seg_comm),
        .w_digit_1(w_digit_1),
        .w_digit_10(w_digit_10),
        .w_digit_100(w_digit_100),
        .w_digit_1000()
    
);
endmodule

module digit_send(
    input clk,
    input reset,
    input [7:0] split_data_100,
    input [7:0] split_data_10,
    input [7:0] split_data_1,
    input echo_done,
    output reg enable_wr,
    output reg [7:0] o_bcd
);
    /*parameter IDLE = 3'b000, DIGIT_100 = 3'b001, WAIT_100 = 3'b010,
                             DIGIT_10 = 3'b011, WAIT_10 = 3'b100,
                             DIGIT_1 = 3'b101, WAIT_1 = 3'b110;
    */
    /*
    parameter IDLE = 2'b00, DIGIT_100 = 2'b01, DIGIT_10 = 2'b10, DIGIT_1 = 2'b11;
    reg [2:0] state, next;
    reg [7:0] digit_data;
    reg clk_reg, clk_next;
    always@(posedge clk, posedge reset)
        begin
            if(reset) begin
                state <= 0;
                clk_reg <= 0;
            end
            else begin
                state <= next;
                clk_reg <= clk_next;
            end
        end

    always@(*) begin
        clk_next = clk_reg;
        next = state;
        enable_wr = 1'b0;
        case(state)
            IDLE : begin
                if(echo_done == 1) begin
                    clk_next = 0;
                    next = DIGIT_100;
                end else begin
                    next = IDLE;
                end
            end
            DIGIT_100 : begin
                o_bcd = split_data_100;
                enable_wr = 1'b1;
                if(clk_reg == 1) begin
                    enable_wr =1'b0;
                    clk_next = 0;
                    next = DIGIT_10;
                end else begin
                    clk_next = clk_reg + 1;
                end
                //next = WAIT_100;
            end
            /*WAIT_100 : begin
                enable_wr = 1'b1;
                o_bcd = split_data_100;
                next = DIGIT_10;
            end*/
/*
            DIGIT_10 : begin
                o_bcd = split_data_10;
                enable_wr = 1'b1;
                if(clk_reg == 1) begin
                    enable_wr =1'b0;
                    clk_next = 0;
                    next = DIGIT_1;
                end else begin
                    clk_next = clk_reg + 1;
                end
            end
            /*DIGIT_10 : begin
                enable_wr = 1'b0;
                next = WAIT_10;
            end
            */
            /*WAIT_10 : begin
                enable_wr = 1'b1;
                o_bcd = split_data_10;
                next = DIGIT_1;
            end*/
            
            /*

            DIGIT_1 : begin
                o_bcd = split_data_1;
                enable_wr = 1'b1;
                if(clk_reg == 1) begin
                    enable_wr =1'b0;
                    clk_next = 0;
                    next = IDLE;
                end else begin
                    clk_next = clk_reg + 1;
                end
            end
            /*WAIT_1 : begin
                enable_wr = 1'b1;
                o_bcd = split_data_1;
                next = IDLE;
            end*/
/*        endcase
    end
endmodule
*/
/*

module splitter_change(
    input [3:0] bcd, //digit_100, digit_10, digit_0을 넣을 모듈
    output reg [7:0] split_data  //==digit_splitter에서 나오는 값을 4bit를 8bit로 변환
);

    always@(bcd)begin
        case(bcd)
            4'h0: split_data = 8'h30; //8비트의 ASCII
            4'h1: split_data = 8'h31;
            4'h2: split_data = 8'h32;
            4'h3: split_data = 8'h33;
            4'h4: split_data = 8'h34;
            4'h5: split_data = 8'h35;
            4'h6: split_data = 8'h36;
            4'h7: split_data = 8'h37;
            4'h8: split_data = 8'h38;
            4'h9: split_data = 8'h39;
            default: split_data = 8'hff;
        endcase
    end
endmodule
*/

