`timescale 1ns / 1ps


module tb_TOP_UART_STOPWATCH();

    reg clk;
    reg reset;
    reg btn_left, btn_up, btn_down;
    reg [2:0]switch_mode;
    reg rx;
    wire tx;
    wire [3:0] fnd_comm;
    wire [7:0] fnd_font;
    wire [4:0] led;

    HIGH_Module DUT(
        .clk(clk),
        .reset(reset),
        .btn_left(btn_left), 
        .btn_up(btn_up), 
        .btn_down(btn_down),
        .switch_mode(switch_mode),
        .rx(rx),
        .tx(tx),
        .fnd_comm(fnd_comm),
        .fnd_font(fnd_font),
        .led(led)
    );

    always #5 clk = ~clk;
    integer i;
    initial begin
        clk = 0;
        reset = 1;
        rx = 0;
        btn_left = 0;
        btn_up = 0;
        btn_down = 0;
        switch_mode = 3'b000;

        #10;
        reset = 0;
        #10;

        for(i=0;i<2;i=i+1) begin
            // stopwach mode로 변경
            switch_mode[0] = 0;
            switch_mode[1] = 0;
            switch_mode[2] = 0;
            // run stop clear
            rx = 0; #104160; send_bit("R"); rx = 1; #208320; 
            rx = 0; #104160; send_bit("R"); rx = 1; #208320; 
            rx = 0; #104160; send_bit("C"); rx = 1; #208320;

            // watch mode로 변경
            switch_mode[1] = 1;
            // sec++ sec++
            rx = 0; #104160; send_bit("S"); rx = 1; #208320;
            rx = 0; #104160; send_bit("M"); rx = 1; #208320;

            // min_hour 변경
            switch_mode[0] = 1;
            // min++ min++
            rx = 0; #104160; send_bit("S"); rx = 1; #208320;
            rx = 0; #104160; send_bit("M"); rx = 1; #208320;

            // hour++ hour++
            rx = 0; #104160; send_bit("H"); rx = 1; #208320;
            rx = 0; #104160; send_bit("M"); rx = 1; #208320;

            // minus mode로 변경
            switch_mode[2] = 1;
            // sec-- sec--
            rx = 0; #104160; send_bit("S"); rx = 1; #208320;
            rx = 0; #104160; send_bit("M"); rx = 1; #208320;
            // min-- min--
            rx = 0; #104160; send_bit("S"); rx = 1; #208320;
            rx = 0; #104160; send_bit("M"); rx = 1; #208320;

            // hour-- hour--
            rx = 0; #104160; send_bit("H"); rx = 1; #208320;
            rx = 0; #104160; send_bit("M"); rx = 1; #208320;
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