`timescale 1ns / 1ps

interface counter_intf;
    logic clk;        // logic wire,reg type이 합쳐진 것
    logic reset;
    logic [7:0] OutPort;
endinterface

class transaction;     //객체간 상호 작용

endclass

//tr generator가 mailbox에 tr값을 넣기 위해 주소 지정
class generator;
    transaction tr; //transaction class 불러오기, 실체화
    virtual counter_intf counter_if;
    mailbox #(transaction) gen2drv_mbox;  //generator에서 mailbox로 보내기 위함

    function new(mailbox#(transaction) gen2drv_mbox);
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction

    //transaction 만들어서 반복해서 mailbox에 넣는 과정
    task run(int run_count);
        repeat (run_count) begin
            tr = new();
            gen2drv_mbox.put(tr);
            #10;
        end
    endtask //automatic
endclass

class driver;
    transaction tr;
    virtual counter_intf counter_if;
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox#(transaction) gen2drv_mbox, virtual counter_intf counter_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.counter_if = counter_if;
    endfunction

    task reset();
        counter_if <= 0;
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            #10;
        end
    endtask
endclass

class environment;
    generator  gen;
    mailbox  #(transaction) gen2drv_mbox;
    driver drv;

    function new(virtual counter_intf counter_if);
        gen2drv_mbox = new();
        gen = new(gen2drv_mbox);
        drv = new(gen2drv_mbox, counter_if);
    endfunction

    task run();
        fork
            gen.run(11);
            drv.run();
        join_any
        #10 $finish;
    endtask
endclass

module tb_counter_55_sv();
    environment env;
    counter_intf counter_if(); //실제 하드웨어

    Counter_adder_55 dut(
        .clk(counter_if.clk),
        .reset(counter_if.reset),
        .OutPort(counter_if.OutPort)
    );
    always #5 counter_if.clk = ~counter_if.clk;

    initial begin
        counter_if.clk = 0;
        counter_if.reset = 1;
        #10 counter_if.reset = 0;

        env = new(counter_if);
        env.run();
    end
endmodule