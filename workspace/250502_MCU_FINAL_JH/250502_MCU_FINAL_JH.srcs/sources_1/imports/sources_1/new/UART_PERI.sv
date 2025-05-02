`timescale 1ns / 1ps
module uart_Periph (
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

    output logic tx,   
    input  logic rx
);
    logic [1:0] FSRR;
    logic [1:0] FSRT;
    
    logic [7:0] FWD;
    logic [7:0] FRD;

    logic       empty_tx;
    logic       full_tx;
    logic [7:0] wdata;
    logic       wr_en;
    logic       tx_done;
    // read side
    logic       empty_rx;
    logic       full_rx;
    logic [7:0] rdata;
    logic       rd_en;
    logic       empty;   

    assign FSRR  = {empty_rx, full_rx}; // rx
    assign wdata = FWD;
    assign FRD   = rdata;
    assign FSRT  = {empty_tx, full_tx}; // tx

    APB_SlaveIntf_uart_fifo U_APB_Intf_uart_fifo (.*);
    uart_fifo_ctrl U_uart_fifo_ctrl (
        .*
    );


    uart_fifo U_uart_fifo_IP (
        .clk(PCLK),
        .reset(PRESET),
        //pc
        .i_rx(rx),
        .o_tx(tx),
        // write side
        .fifo_tx_empty(empty_tx),
        .fifo_tx_full(full_tx),
        .fifo_tx_wdata(wdata),
        .fifo_tx_wr_en(wr_en),
        .tx_done(tx_done),
    // read side
        .fifo_rx_full(full_rx),
        .fifo_rx_rdata(rdata),
        .fifo_rx_rd_en(rd_en),
        .fifo_rx_empty(empty_rx)
    );

endmodule

module APB_SlaveIntf_uart_fifo (
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
    input  logic [ 1:0] FSRR,
    input  logic [ 1:0] FSRT, 
    output logic [ 7:0] FWD,
    input  logic [ 7:0] FRD

);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    // assign FCR = slv_reg0[7:0];
    // assign FPR = slv_reg1[3:0];
    assign slv_reg0[1:0] = FSRR;  // rx, empty ,full,
    assign FWD = slv_reg1[7:0];
    assign slv_reg2[7:0] = FRD;  // read data
    assign slv_reg3[1:0] = FSRT;  // tx, empty ,full,



    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            //slv_reg0 <= 0;
            slv_reg1 <= 0;
            //slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: ;  //slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        2'd2: ;  //slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        //2'd2: PRDATA <= slv_reg2;
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end
endmodule

module uart_fifo_ctrl (
    input logic PCLK,
    input logic PRESET,
    input logic PWRITE,
    input logic [3:0] PADDR,
    input logic PREADY,
    output logic wr_en,
    output logic rd_en
);
    parameter IDLE = 0, WRITE = 1, READ = 2;
    logic [1:0] state, next;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            state <= 1'b0;
        end else begin
            state <= next;
        end
    end


    always_comb begin
        next  = state;
        wr_en = 0;
        rd_en = 0;
        case (state)
            IDLE: begin
                wr_en = 0;
                rd_en = 0;
                if (PREADY && ~(PADDR[3:2] == 2'd0)) begin
                    if (PWRITE) begin
                        next = WRITE;
                    end else begin
                        next = READ;
                    end
                end
            end
            WRITE: begin
                wr_en = 1;     
                rd_en = 0;
                next  = IDLE;
            end
            READ: begin
                wr_en = 0;
                rd_en = 1;
                next  = IDLE;
            end

        endcase
    end
endmodule


module uart_fifo (
    input logic clk,
    input logic reset,
    //pc
    input logic i_rx,
    output logic o_tx,
    //apb_slave
    output logic fifo_tx_empty,
    output logic fifo_tx_full,
    input logic [7:0] fifo_tx_wdata,
    input logic fifo_tx_wr_en,
    output logic tx_done,

    output logic fifo_rx_full,
    output logic [7:0] fifo_rx_rdata,
    input logic fifo_rx_rd_en,
    output logic fifo_rx_empty
);

    logic [7:0] w_rx_data;
    logic w_rx_done;

    logic w_fifo_tx_empty;
    logic [7:0] w_fifo_tx_rdata;

    assign fifo_tx_empty = w_fifo_tx_empty;

    uart RX_TX (
        .clk(clk),
        .reset(reset),
        //tx
        .i_btn_start(~w_fifo_tx_empty),
        .i_data(w_fifo_tx_rdata),
        .o_tx_done(tx_done),  //
        .o_tx(o_tx),
        //rx
        .i_rx(i_rx),
        .o_rx_done(w_rx_done),
        .o_rx_data(w_rx_data)
    );

    fifo FIFO_TX (
        .clk(clk),
        .reset(reset),
        //write
        .wdata(fifo_tx_wdata),
        .wr_en(fifo_tx_wr_en),
        .full(fifo_tx_full),
        //read
        .rdata(w_fifo_tx_rdata),
        .rd_en(~tx_done),  //
        .empty(w_fifo_tx_empty)
    );

    fifo FIFO_RX (
        .clk  (clk),
        .reset(reset),
        //write
        .wdata(w_rx_data),
        .wr_en(w_rx_done),
        .full (fifo_rx_full),
        //read
        .rdata(fifo_rx_rdata),
        .rd_en(fifo_rx_rd_en),
        .empty(fifo_rx_empty)
    );
endmodule


module uart (
    input logic clk,
    input logic reset,
    //tx
    input logic i_btn_start,
    input logic [7:0] i_data,
    output logic o_tx_done,
    output logic o_tx,
    //rx
    input logic i_rx,
    output logic o_rx_done,
    output logic [7:0] o_rx_data
);

    logic w_tick;

    baud_tick_gen U_BAUD_TICK_GEN (
        .clk(clk),
        .reset(reset),
        .o_baud_tick(w_tick)
    );

    uart_tx U_UART_TX (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick),
        .i_start_trigger(i_btn_start),
        .i_data(i_data),
        .o_tx(o_tx),
        .o_tx_done(o_tx_done)
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .rst(reset),
        .tick(w_tick),
        .rx(i_rx),
        .rx_done(o_rx_done),
        .rx_data(o_rx_data)
    );


endmodule



module uart_tx (
    input logic clk,
    input logic reset,
    input logic i_tick,
    input logic i_start_trigger,
    input logic [7:0] i_data,
    output logic o_tx,
    output logic o_tx_done
);

    //fsm
    parameter IDLE = 4'h0;
    parameter SEND = 4'h1;
    parameter START = 4'h2;
    parameter DATA = 4'h3;
    parameter STOP = 4'h4;

    reg [3:0] state, next;

    reg tx_reg, tx_next;

    reg tx_done_reg, tx_done_next;

    reg [2:0] data_count_reg, data_count_next;

    reg [3:0] tick_count_reg, tick_count_next;

    reg [7:0] temp_data_reg, temp_data_next;

    assign o_tx = tx_reg;
    assign o_tx_done = tx_done_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tx_reg <= 1'b1; //Uart tx line을 초기에 항상 1로 만들기 위함.
            tx_done_reg <= 1'b0;
            data_count_reg <= 0;
            tick_count_reg <= 0;
            temp_data_reg <= 0;
        end else begin
            state <= next;
            tx_reg <= tx_next;
            tx_done_reg <= tx_done_next;
            data_count_reg <= data_count_next;
            tick_count_reg <= tick_count_next;
            temp_data_reg <= temp_data_next;
        end
    end

    always_comb begin
        next = state;
        tx_next = tx_reg;
        tx_done_next = tx_done_reg;
        data_count_next = data_count_reg;
        tick_count_next = tick_count_reg;
        temp_data_next = temp_data_reg;
        case (state)
            IDLE: begin
                tx_next = 1'b1;
                tx_done_next = 1'b0;  //
                tick_count_next = 4'b0;
                if (i_start_trigger) begin
                    next = SEND;
                    temp_data_next = i_data;
                end
            end
            SEND: begin
                if (i_tick) begin
                    next = START;
                end
            end
            START: begin
                // tx_done_next = 1'b1;//
                tx_next = 1'b0;  // 출력을 0으로 유지  
                if (i_tick) begin
                    if (tick_count_reg == 15) begin
                        next = DATA;
                        tick_count_next = 0;//nest state로 갈때 tick_count초기화 
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                // tx_next = i_data[data_count_reg];//
                tx_next = temp_data_reg[data_count_reg];  //
                if (i_tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        if (data_count_reg == 7) begin
                            next = STOP;
                            data_count_next = 0;
                        end else begin
                            next = DATA;
                            data_count_next = data_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (i_tick) begin
                    if (tick_count_reg == 15) begin
                        tx_done_next = 1'b1;  //  
                        next = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule


module uart_rx (
    input logic clk,  // 시스템 클럭
    input logic rst,  // 비동기 리셋
    input logic tick,
    input logic rx,
    output logic  rx_done,
    output logic  [7:0] rx_data
);
    //parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

    logic [1:0] state, next;
    logic rx_done_reg, rx_done_next;
    logic [2:0] bit_count_reg, bit_count_next;
    logic [4:0] tick_count_reg, tick_count_next; // rx tick max count
    logic [7:0] rx_data_reg, rx_data_next;
    // output
    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    // state
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= 0;
            rx_done_reg <= 0;
            rx_data_reg <= 0;
            bit_count_reg <= 0;
            tick_count_reg <= 0;
        end else begin
            state <= next;
            rx_done_reg <= rx_done_next;
            rx_data_reg <= rx_data_next;
            bit_count_reg <= bit_count_next;
            tick_count_reg <= tick_count_next;
        end
    end

    //next
    always @(*) begin
        next = state;
        tick_count_next = tick_count_reg;
        bit_count_next = bit_count_reg;
        rx_data_next = rx_data_reg;
        rx_done_next = 1'b0;
        case (state)
            IDLE: begin
                tick_count_next = 0;
                bit_count_next = 0;
                rx_done_next = 1'b0;
                if (rx == 1'b0) begin
                    next = START;
                end
            end
            START: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 7) begin
                        next = DATA;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 15) begin
                        // read data
                        rx_data_next [bit_count_reg] = rx;
                        if (bit_count_reg == 7) begin
                            next = STOP;
                            tick_count_next = 0; // 다음 스테이트 가면 초기화
                        end else begin
                            next = DATA;    
                            bit_count_next = bit_count_reg + 1;
                            tick_count_next = 0;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                    if (tick == 1'b1) begin
                    if (tick_count_reg == 23) begin
                        rx_done_next = 1'b1;
                        next = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule


module baud_tick_gen (
    input  logic clk,
    input  logic reset,
    output logic o_baud_tick
);

    parameter BAUD_RATE = 9600;
    // parameter BAUD_RATE = 19200;
    localparam BAUD_COUNT = (100_000_000 / BAUD_RATE) / 16;
    reg [$clog2(BAUD_COUNT)-1:0] count_reg;
    reg [$clog2(BAUD_COUNT)-1:0] count_next;

    reg tick_reg;
    reg tick_next;

    assign o_baud_tick = tick_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    always_comb begin
        count_next = count_reg;  //
        tick_next  = tick_reg;  //
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 0;
        end
    end
endmodule
