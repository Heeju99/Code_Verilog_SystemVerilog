`timescale 1ns / 1ps

module tb_TOP_UART_STOPWATCH();

    reg clk;
    reg reset;
    reg rx;
    reg btn_left, btn_right, btn_down;
    reg [4:0]sw_mode;
    wire tx;
    wire [3:0] fnd_comm;
    wire [7:0] fnd_font;
    wire [4:0] led;

    wire dht_io;
    wire trigger;
    reg echo;

    TOP_FIFO_STOPWATCH_SENSOR DUT(
        .clk(clk),
        .reset(reset),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_down(btn_down),
        .sw_mode(sw_mode),
        .rx(rx),
        .tx(tx),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm),

    // HC-SR04
        .echo(echo),
        .trigger(trigger),

    // DHT11
        .dht_io(dht_io)
    );

    always #5 clk = ~clk;
    integer i;
    initial begin
        clk = 0;
        reset = 1;
        rx = 0;
        btn_left = 0;
        btn_right = 0;
        btn_down = 0;
        echo = 0;
        sw_mode = 4'b0000;

        #1000;
        reset = 0;
        #1000;

        // 3번 진행 #104160
        for(i=0;i<3;i=i+1) begin
            // run stop clear
            rx = 0; #104160; send_bit("R"); rx = 1; #104160;
            rx = 0; #104160; send_bit("R"); rx = 1; #104160;
            rx = 0; #104160; send_bit("C"); rx = 1; #104160;

            // watch mode로 변경
            sw_mode[4:3] = 2'b01;
            // sec++ sec++
            rx = 0; #104160; send_bit("S"); rx = 1; #104160;
            rx = 0; #104160; send_bit("S"); rx = 1; #104160;

            // min_hour 변경
            sw_mode[0] = 1;
            // min++ min++
            rx = 0; #104160; send_bit("M"); rx = 1; #104160;
            rx = 0; #104160; send_bit("M"); rx = 1; #104160;

            // hour++ hour++
            rx = 0; #104160; send_bit("H"); rx = 1; #104160;
            rx = 0; #104160; send_bit("H"); rx = 1; #104160;

            // minus mode로 변경
            sw_mode[1] = 1;
            // sec-- sec--
            rx = 0; #104160; send_bit("S"); rx = 1; #104160;
            rx = 0; #104160; send_bit("S"); rx = 1; #104160;
            // min-- min--
            rx = 0; #104160; send_bit("M"); rx = 1; #104160;
            rx = 0; #104160; send_bit("M"); rx = 1; #104160;

            // hour-- hour--
            rx = 0; #104160; send_bit("H"); rx = 1; #104160;
            rx = 0; #104160; send_bit("H"); rx = 1; #104160;

            // run stop clear
            rx = 0; #104160; send_bit("R"); rx = 1; #104160;
            rx = 0; #104160; send_bit("R"); rx = 1; #104160;
            rx = 0; #104160; send_bit("C"); rx = 1; #104160;

            
            // // FPGA로 동작
            // // run stop clear
            // #100000000; btn_left = 1;  #100000000; btn_left = 0;
            // #100000000; btn_left = 1;  #100000000; btn_left = 0;
            // #100000000; btn_right = 1;  #100000000; btn_left = 0;

            // // watch mode로 변경
            // sw_mode[1] = 1;
            // // sec++ sec++
            //  #104160; btn_left = 1;  #104160; btn_left = 0;
            //  #104160; btn_left = 1;  #104160; btn_left = 0;

            // // min_hour 변경
            // sw_mode[0] = 1;
            // // min++ min++
            //  #104160; btn_down = 1;  #104160; btn_down = 0;
            //  #104160; btn_down = 1;  #104160; btn_down = 0;

            // // hour++ hour++
            //  #104160; btn_right = 1; #104160; btn_right = 0;
            //  #104160; btn_right = 1; #104160; btn_right = 0;

            // // minus mode로 변경
            // sw_mode[2] = 1;
            // // sec-- sec--
            //  #104160; btn_left = 1;  #104160; btn_left = 0;
            //  #104160; btn_left = 1;  #104160; btn_left = 0;
            // // min-- min--
            //  #104160; btn_down = 1;  #104160; btn_down = 0;
            //  #104160; btn_down = 1;  #104160; btn_down = 0;

            // // hour-- hour--
            //  #104160; btn_right = 1; #104160; btn_right = 0;
            //  #104160; btn_right = 1; #104160; btn_right = 0;

            // // run stop clear
            //  #104160; btn_left = 1;  #104160; btn_left = 0;
            //  #104160; btn_left = 1;  #104160; btn_left = 0;
            // #104160; btn_right = 1;  #104160; btn_left = 0;

            // mode 초기화
            sw_mode = 4'b0000;
        end
        #104160;
        $stop;


    end

    task send_bit(input [7:0] data);
        integer i;
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #104160;
        end
    endtask

endmodule
