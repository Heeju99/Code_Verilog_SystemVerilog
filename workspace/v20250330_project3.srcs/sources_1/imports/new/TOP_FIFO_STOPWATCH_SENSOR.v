`timescale 1ns / 1ps

module TOP_FIFO_STOPWATCH_SENSOR(
    input clk,
    input reset,
    input btn_left,
    input btn_right,
    input btn_down,
    input [4:0] sw_mode,
    input rx,
    output tx,
    output [7:0] fnd_font,
    output [3:0] fnd_comm,

    // HC-SR04
    input echo,
    output trigger,

    // DHT11
    inout dht_io
    );

    wire w_btn_left, w_btn_right, w_btn_down;
    wire w_wr_tx;
    wire [7:0] w_wdata_tx;
    wire w_empty_rx_b;
    wire [7:0] w_rdata_rx;
    wire w_wr_tx_HCSR04;
    wire [7:0] w_data_HCSR04_tx;
    wire w_wr_tx_DHT11;
    wire [7:0] w_data_DHT11_tx;
    wire run, clear, cu_hour, cu_min, cu_sec;
    wire w_echo_done;
    wire [6:0] w_msec;
    wire [8:0] w_distance;
    wire [15:0] w_sec_msec, w_min_hour;
    wire [39:0] w_data_DHT11;
    wire w_dht_done;
    wire [15:0] w_temp_hum;
    wire [15:0] w_data_in_fnd;
    wire [15:0] w_data_digit;

    btn_top U_Btn_TOP(
        .clk(clk),
        .reset(reset),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_down(btn_down),
        .o_left(w_btn_left),
        .o_right(w_btn_right),
        .o_down(w_btn_down)
    );

    uart_fifo U_UART_FIFO(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .wr_tx(w_wr_tx),
        .wdata_tx(w_wdata_tx),
        .empty_rx_b(w_empty_rx_b),
        .rdata_rx(w_rdata_rx),
        .tx(tx)
    );

    CTRL_UNIT U_CTRL_UNIT(   
        .clk(clk), // FPGA
        .reset(reset), // FPGA
        .sw_mode(sw_mode), // FPGA
        .rdata_rx(w_rdata_rx), // uart
        .empty_rx_b(w_empty_rx_b), // uart
        .btn_left(w_btn_left), // FPGA
        .btn_right(w_btn_right), // FPGA
        .btn_down(w_btn_down),  //FPGA

        // HC-SR04 input
        .echo(echo), // sensor
        .wr_tx_HCSR04(w_wr_tx_HCSR04), // CU(uart)
        .data_HCSR04_tx(w_data_HCSR04_tx), // CU(uart)

        // DHT11 input
        .wr_tx_DHT11(w_wr_tx_DHT11), // DP to CU(uart)
        .data_DHT11_tx(w_data_DHT11_tx), // DP to CU(uart)

        // UART output
        .wdata_tx(w_wdata_tx),
        .wr_tx(w_wr_tx),

        // STOPWATCH, WATCH output
        .run(run), // DP
        .clear(clear), // DP
        .cu_sec(cu_sec), // DP
        .cu_min(cu_min), // DP
        .cu_hour(cu_hour), // DP

        // HC-SR04 output 
        .trigger(trigger), // sensor
        .echo_done(w_echo_done), // DP
        .distance(w_distance),  // mux

        // DHT11  output
        .data_DHT11_out(w_data_DHT11), // DP
        .dht_done(w_dht_done), // DP

        .dht_io(dht_io) // sensor
    );

    TOP_DP U_TOP_DP(
        .clk(clk),
        .reset(reset),
        .sw_mode(sw_mode),

        // STOPWATCH, WATCH
        .run(run), // CU
        .clear(clear), // CU
        .cu_sec(cu_sec), // CU
        .cu_min(cu_min), // CU
        .cu_hour(cu_hour), // CU
        .msec(w_msec), // FND
        .sec_msec(w_sec_msec), // mux
        .hour_min(w_min_hour), // mux
        //output [4:0] led                                 

        // HC-SR04
        .echo_done(w_echo_done), // CU
        .distance_digit(w_data_digit[11:0]), // FND
        .wr_tx_HCSR04(w_wr_tx_HCSR04), // CU(uart)
        .data_HCSR04_tx(w_data_HCSR04_tx), // CU(uart)

        // DHT11
        .dht_done(w_dht_done), // CU
        .data_in(w_data_DHT11), // DHT11_cu to DP
        .DHT11_decimal_data(w_data_digit), // fnd to DP
        .data_out(w_temp_hum), // DP to fnd
        .wr_tx_DHT11(w_wr_tx_DHT11), // DP to CU(uart)
        .data_DHT11_tx(w_data_DHT11_tx) // DP to CU(uart)
    );

    mux_4X1_16bit U_mux_4X1_16bit(
        .sw_mode({sw_mode[4],sw_mode[3],sw_mode[0]}), 
        .sec_msec(w_sec_msec),
        .hour_min(w_min_hour),
        .distance(w_distance),
        .temp_hum(w_temp_hum),
        .data_in_fnd(w_data_in_fnd)
    );

    fnd_controller U_fnd_controller(
        .clk(clk),
        .reset(reset),
        .data_in(w_data_in_fnd),
        .sw_mode(sw_mode[4:3]), // {Sensor sel, STOP,WAT mode}
        .msec(w_msec),
        .data_digit(w_data_digit),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm)
    );

endmodule
