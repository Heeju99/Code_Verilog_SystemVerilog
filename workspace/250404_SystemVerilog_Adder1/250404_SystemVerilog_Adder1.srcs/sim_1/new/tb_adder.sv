`timescale 1ns / 1ps

//하드웨어 들어가기 전에 하나의 전선 다발로연결해준다는 느낌?
interface adder_intf;
    logic [7:0] a;        // logic wire,reg type이 합쳐진 것
    logic [7:0] b;
    logic [7:0] sum;
    logic       carry;
endinterface

class transaction;     //객체간 상호 작용
    rand bit [7:0] a;  //random한 값을 만들어 냄
    rand bit [7:0] b;
endclass

//tr generator가 mailbox에 tr값을 넣기 위해 주소 지정
class generator;
    transaction tr; //transaction class 불러오기, 실체화
    mailbox #(transaction) gen2drv_mbox;  //generator에서 mailbox로 보내기 위함
    // gen2drv_mbox 라는 메모리를 생성해줌


    function new(mailbox#(transaction) gen2drv_mbox);
        this.gen2drv_mbox = gen2drv_mbox;
    //앞에꺼는 generator class의 멤버, 뒤에꺼는 매개변수
    endfunction

    //transaction 만들어서 반복해서 mailbox에 넣는 과정
    task run(int run_count);
        repeat (run_count) begin //계속 반복하면서 new()가 반복 생성되는데,
                                 //내부의 garbage collector가 mailbox로 값을 가져간 new를 제거함. 
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr); //랜덤된 값을 mailbox에 넣게 됨.
            #10;
        end
    endtask //automatic
endclass

class driver;
    transaction tr;
    virtual adder_intf adder_if; //driver 클래스의 멤버 변수, 가상으로 interface랑 연결하려고
    mailbox #(transaction) gen2drv_mbox;  //mailbox랑 연결하려고


    function new(mailbox#(transaction) gen2drv_mbox, virtual adder_intf adder_if);
                                    // 매개 변수 : 가상의 interface 
        this.gen2drv_mbox = gen2drv_mbox; 
        //this = 이 클래스(=driver), .gen2drv = class의 멤버 변수에
        // = gen2drv_mbox 매개변수를 집어 넣는다.
        this.adder_if = adder_if; // 멤버 변수
    endfunction

    task reset();
        adder_if.a = 0;
        adder_if.b = 0;
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);  //mailbox에 저장된 tr을 가져와서
            adder_if.a = tr.a;     //tr.a를 interface에 가져다 줌
            adder_if.b = tr.b;     //tr.b를 interface에 가져다 줌
            #10;
        end
    endtask
endclass

class environment;
    generator  gen;
    mailbox  #(transaction) gen2drv_mbox;
    driver drv;

    //new = 예약어, 생성자(instance화 하면서 heap에 만들어버림)
    //virtual : 진짜 하드웨어를 가상으로 연결함(tb에서 진짜를 돌리기 전에 가상으로 먼저 하는 느낌?)
    function new(virtual adder_intf adder_if);
        gen2drv_mbox = new();
        gen = new(gen2drv_mbox); //mailbox와 연결해서 사용
        drv = new(gen2drv_mbox, adder_if); //mailbox, interface와 연결
    endfunction

    task run();          //heap 메모리에 있는 run이 동작하게 됨
        fork             //fork,join : thread 동작(동시 동작)
            gen.run(10); //generator에서 mailbox로 랜덤 tr을 집어 넣음(10)
            drv.run();   //driver는 mailbox에 tr이 들어오는 걸 감지하고 값을 받음. 
        join_any         //join_any : 여러 작업 중 하나라도 끝나면 fork 이후의 코드로 진행
        #10 $finish;
    endtask

endclass

module tb_adder();
    environment env;  ///....env는 handler(stack 영역 생성),environment class의 주소를 갖게 됨
    adder_intf adder_if(); //실제 하드웨어, instance 생성됨

    adder dut( //instance화
        .a(adder_if.a),   //interface에 여러개로 묶인 cable 중에서        
        .b(adder_if.b),   //뽑아서 연결해서 사용
        .sum(adder_if.sum),
        .carry(adder_if.carry)
    );

    initial begin
        env = new(adder_if);  ///.... env: handler(stack), new : heap 영역
        // 즉, new를 쓰면서 메모리에 instance화를 시켜주도록 함.
        env.run();            // environment의 run 동작
    end
endmodule

