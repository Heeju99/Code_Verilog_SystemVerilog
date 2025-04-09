`timescale 1ns / 1ps

module tb_uart_tx();
    reg clk, reset, btn_start;
    wire tx;

    send_tx_btn dut(
    .clk(clk),
    .reset(reset),
    .btn_start(btn_start),
    .tx(tx)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        btn_start = 1'b0;

        #20;
        reset = 0;
	    #20000000; 
	    btn_start = 1'b1;
	    #20000000; 
	    btn_start = 1'b0;
	    #20000000; 
	    btn_start = 1'b1;
	    #20000000; 
	    btn_start = 1'b0;

    end
endmodule
