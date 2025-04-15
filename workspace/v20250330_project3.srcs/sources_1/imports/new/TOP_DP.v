`timescale 1ns / 1ps

module TOP_DP(
    input clk,
    input reset,
    input [4:0] sw_mode,

    // STOPWATCH, WATCH
    input run, // CU
    input clear, // CU
    input cu_sec, // CU
    input cu_min, // CU
    input cu_hour, // CU
    output [6:0] msec, // FND
    output [15:0] sec_msec, // mux
    output [15:0] hour_min, // mux
    //output [4:0] led                                 

    // HC-SR04
    input echo_done, // CU
    input [11:0] distance_digit, // FND
    output wr_tx_HCSR04, // CU(uart)
    output [7:0] data_HCSR04_tx, // CU(uart)

    // DHT11
    input dht_done, // CU
    input [39:0] data_in, // DHT11_cu to DP
    input [15:0] DHT11_decimal_data, // fnd to DP
    output [15:0] data_out, // DP to fnd
    output wr_tx_DHT11, // DP to CU(uart)
    output [7:0] data_DHT11_tx // DP to CU(uart)
    );

    TOP_STOPWATCH_WATCH U_STOPWATCH_WATCH_DP(
        .clk(clk),
        .reset(reset),
        .run(run),
        .clear(clear),
        .cu_sec(cu_sec),
        .cu_min(cu_min),
        .cu_hour(cu_hour),
        .sel_mode(sw_mode[4:3]), // STOPWATCH, WATCH sel
        .sw_plus_minus({sw_mode[4:3], sw_mode[1]}),
        .msec(msec),
        .sec_msec(sec_msec),
        .hour_min(hour_min)
        //.led
    );

    HCSR04_dp U_HCSR04_dp(
        .clk(clk),
        .reset(reset),
        .echo_done(echo_done),
        .distance_digit(distance_digit),
        .wr_tx(wr_tx_HCSR04),
        .data_sensor_tx(data_HCSR04_tx)
    );

    DHT11_dp U_DHT11_dp(
        .clk(clk),
        .reset(reset),
        .dht_done(dht_done),
        .data_in(data_in),
        .sw_tem_hum(sw_mode[4:2]),
        .DHT11_decimal_data(DHT11_decimal_data),
        .data_out(data_out),
        .wr_tx(wr_tx_DHT11),
        .data_sensor_tx(data_DHT11_tx)
    );

endmodule
