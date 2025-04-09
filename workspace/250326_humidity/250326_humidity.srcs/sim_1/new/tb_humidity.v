`timescale 1ns / 1ps

module tb_humidity();

    reg clk, reset, btn_start;
    reg dht_sensor_data;
    reg io_oe;
    wire [15:0] data;
    wire  [3:0] led;
    wire dht_IO;

    assign dht_IO = (io_oe) ? dht_sensor_data : 1'bz;

    humidity dut(
        .clk(clk),
        .reset(reset),
        .btn_start(btn_start),
        .led(led),
        .data(data), 
        .dht_IO(dht_IO)
    );

    always #5 clk = ~clk;

    integer i, j;

    initial begin
        clk = 0;
        reset = 1;
        btn_start = 0;
        io_oe = 0;
        i = 0;
        j = 0;

        #100;
        reset = 0;
        for (j=0;j<2;j=j+1) begin
            #100;
            btn_start = 1;
            #100;
            btn_start = 0;

            // 18msec 대기
            wait(dht_IO);
            #50000;
            // 입력 모드로 변환
            io_oe = 1;

            // SYNC_LOW
            dht_sensor_data = 0;
            #80000; //80us

            // SYNC_HIGH
            dht_sensor_data = 1;
            #80000; //80us

            // DATA_START
            dht_sensor_data = 0;
            #50000; //50us        

            for(i=0;i<10;i=i+1) begin

                dht_sensor_data = 1;
                #20000; //20us '0'
                dht_sensor_data = 0;
                #50000; 
                
                // DATA(40bit) 입력 시작
                dht_sensor_data = 1;
                #60000; //60us '1'

                // DATA_START
                dht_sensor_data = 0;
                #50000; 

                // DATA(40bit) 입력 시작
                dht_sensor_data = 1;
                #20000; //20us '0'
                dht_sensor_data = 0;
                #50000; 

                // DATA(40bit) 입력 시작
                dht_sensor_data = 1;
                #60000; //60us '1'

                // DATA_START
                dht_sensor_data = 0;
                #50000; 
            end
            dht_sensor_data = 0;
            #50000; //50us 
            io_oe = 0;
             #50000;
        end
        #50000;
        $stop;
    end

endmodule
/*
`timescale 1ns / 1ps

module tb_DHT11_CU();

    reg clk;
    reg reset;
    reg btn_start;
    
    wire [39:0] data_out;
    wire [3:0] led;
    wire dht_io;
    
    reg dht_sensor_data;
    reg io_oe;

    assign dht_io = (io_oe) ? dht_sensor_data : 1'bz;

    TOP_DHT11 DUT(
        .clk(clk),
        .reset(reset),
        .btn_start(btn_start),
        .led(led),
        .data_out(data_out),
        .dht_io(dht_io)
    );


    always #5 clk = ~clk;

    integer i, j;

    initial begin
        clk = 0;
        reset = 1;
        btn_start = 0;
        io_oe = 0;
        i = 0;
        j = 0;

        #100;
        reset = 0;
        for (j=0;j<2;j=j+1) begin
            #100;
            btn_start = 1;
            #100;
            btn_start = 0;

            // 18msec 대기
            wait(dht_io);
            #50000;
            // 입력 모드로 변환
            io_oe = 1;

            // SYNC_LOW
            dht_sensor_data = 0;
            #80000; //80us

            // SYNC_HIGH
            dht_sensor_data = 1;
            #80000; //80us

            // DATA_START
            dht_sensor_data = 0;
            #50000; //50us        

            for(i=0;i<10;i=i+1) begin

                dht_sensor_data = 1;
                #20000; //20us '0'
                dht_sensor_data = 0;
                #50000; 
                
                // DATA(40bit) 입력 시작
                dht_sensor_data = 1;
                #60000; //60us '1'

                // DATA_START
                dht_sensor_data = 0;
                #50000; 

                // DATA(40bit) 입력 시작
                dht_sensor_data = 1;
                #20000; //20us '0'
                dht_sensor_data = 0;
                #50000; 

                // DATA(40bit) 입력 시작
                dht_sensor_data = 1;
                #60000; //60us '1'

                // DATA_START
                dht_sensor_data = 0;
                #50000; 
            end
            dht_sensor_data = 0;
            #50000; //50us 
            io_oe = 0;
             #50000;
        end
        #50000;
        $stop;
    end

endmodule*/
