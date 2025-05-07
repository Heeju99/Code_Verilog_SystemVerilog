`timescale 1ns / 1ps

interface APB_Slave_Interface;
    logic        PCLK;
    logic        PRESET;

    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    // export signals
    logic        trigger;
    logic        echo;
    //additional
    logic  [ 8:0] distance;
    logic  [16:0] rand_distance;

endinterface 

class transaction;
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic          PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;
    logic             PREADY;
    // export signals

    logic        trigger;
    logic        echo;
    //additional
    logic  [ 8:0] distance;
    rand logic  [16:0] rand_distance;

    constraint c_paddr {PADDR inside {4'h0, 4'h4};} 
    constraint c_dist {24 < rand_distance;
                       80 > rand_distance;}
    constraint c_paddr_0 {
        if (PADDR == 0)
        PWDATA inside {32'h00000000, 32'h00000001};
    }
    task display(string name);
        $display(
            "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h ,PENABLE=%h, PSEL=%h, PRDATA=%0d, PREADY=%h, trigger=%h, echo=%h, distance=%d, rand_distance=%d",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY,
            trigger, echo, distance, rand_distance);
    endtask  //display
endclass  //transaction


class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;
    

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction sen_tr;
        repeat (repeat_counter) begin
            sen_tr = new(); 
            if (!sen_tr.randomize())
                $error("Randomization fail");  
            sen_tr.display("GEN");  
            Gen2Drv_mbox.put(sen_tr); 
            @(gen_next_event); 
        end
    endtask  //run
endclass  //generater

class driver;
    virtual APB_Slave_Interface sen_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    transaction sen_tr;
    event drv_next_event;

    function new(virtual APB_Slave_Interface sen_intf,
                 mailbox#(transaction) Gen2Drv_mbox,
                 event drv_next_event);
        this.sen_intf = sen_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
        this.drv_next_event = drv_next_event;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(sen_tr);
            sen_tr.display("DRV");
            @(posedge sen_intf.PCLK);
            sen_intf.PADDR <= sen_tr.PADDR;
            sen_intf.PWDATA <= sen_tr.PWDATA;
            sen_intf.PWRITE <= sen_tr.PWRITE;
            sen_intf.PENABLE <= 1'b0;
            sen_intf.PSEL <= 1'b1;

            @(posedge sen_intf.PCLK);
            sen_intf.PADDR <= sen_tr.PADDR;
            sen_intf.PWDATA <= sen_tr.PWDATA;
            sen_intf.PWRITE <= sen_tr.PWRITE;
            sen_intf.PENABLE <= 1'b1;
            sen_intf.PSEL <= 1'b1;
            sen_intf.rand_distance <= sen_tr.rand_distance;
            //sen_intf.distance <= sen_tr.distance;
            wait (sen_intf.PREADY == 1'b1);
                #50;
            if (sen_tr.PADDR == 0 && sen_tr.PWDATA == 1 && sen_tr.PWRITE) begin
                wait(sen_intf.trigger == 1); 
                wait(sen_intf.trigger == 0); 
                #10700; //8cycle Sonic Burst
                sen_intf.echo  <= 1;
                #(sen_tr.rand_distance * 1000 * 58);  
                sen_intf.echo <= 0;
            end
            ->drv_next_event;
        end
    endtask  //run
endclass  //dirver

class monitor;
    mailbox #(transaction) Mon2SCB_mbox;
    virtual APB_Slave_Interface sen_intf;
    transaction sen_tr;
    event drv_next_event;

    function new(virtual APB_Slave_Interface sen_intf,
                 mailbox#(transaction) Mon2SCB_mbox,
                 event drv_next_event);
        this.sen_intf = sen_intf;
        this.Mon2SCB_mbox = Mon2SCB_mbox;
        this.drv_next_event = drv_next_event;
    endfunction  //new()

    task run();
        forever begin
            sen_tr = new();
            @(drv_next_event);
            @(posedge sen_intf.PCLK);
            @(posedge sen_intf.PCLK);

            #1;
            sen_tr.PADDR   = sen_intf.PADDR;
            sen_tr.PWDATA  = sen_intf.PWDATA;
            sen_tr.PWRITE  = sen_intf.PWRITE;
            sen_tr.PENABLE = sen_intf.PENABLE;
            sen_tr.PSEL    = sen_intf.PSEL;
            sen_tr.PRDATA  = sen_intf.PRDATA;
            sen_tr.PREADY  = sen_intf.PREADY;
            //additional
            sen_tr.trigger  = sen_intf.trigger;
            sen_tr.echo     = sen_intf.echo;
            sen_tr.distance = sen_intf.distance;
            sen_tr.rand_distance = sen_intf.rand_distance;
            Mon2SCB_mbox.put(sen_tr);
            sen_tr.display("MON");
            @(posedge sen_intf.PCLK);
        end
    endtask  //run
endclass  //monitor

class scoreboard;
    mailbox #(transaction) Mon2SCB_mbox;
    transaction sen_tr;
    event gen_next_event;

    // reference model
    logic [31:0] refSenReg[0:2];
    logic [31:0] expected_distance;

    //to count
    logic [9:0] write_cnt = 0;
    logic [9:0] pass_cnt = 0;
    logic [9:0] fail_cnt = 0;
    logic [9:0] total_cnt = 0;
    logic [9:0] read_cnt = 0;

    logic detect_pass;
    logic enable_pass;

    function new(mailbox#(transaction) Mon2SCB_mbox, event gen_next_event);
        this.Mon2SCB_mbox   = Mon2SCB_mbox;
        this.gen_next_event = gen_next_event;
        for (int i = 0; i < 3; i++) begin
            refSenReg[i] = 0;
        end
    endfunction  //new()

task run();
    forever begin
    detect_pass = 0;
    enable_pass = 0;
        Mon2SCB_mbox.get(sen_tr);
        sen_tr.display("SCB");

        if (sen_tr.PWRITE) begin  // write mode
            refSenReg[sen_tr.PADDR] = sen_tr.PWDATA;
            write_cnt = write_cnt + 1;

            if (refSenReg[0] == 1) begin  //FCR_EN == 1
                expected_distance = (sen_tr.rand_distance);
                if (sen_tr.PADDR == 4'h0) begin
                    if (sen_tr.distance[8:0] == expected_distance[8:0]) begin
                        enable_pass = 1;
                        $display("SENSOR ENABLE PASS: %0d == %0d", sen_tr.distance[8:0], expected_distance[8:0]);
                    end else begin
                        enable_pass = 0;
                        $display("SENSOR ENABLE FAIL: %0d != %0d", sen_tr.distance[8:0], expected_distance[8:0]);
                    end
                end else begin //PADDR == 4'h4;
                    $display("ENABLE NOT ALLOWED");
                    enable_pass = 1;
                end
            end else begin //FCR_EN == 0;
                $display("ENABLE NOT ALLOWED");
                    enable_pass = 1;
            end
        end else begin  // read mode
            refSenReg[1] = sen_tr.distance;
            read_cnt = read_cnt + 1;
            if(sen_tr.PADDR == 4'h4) begin
                if(sen_tr.PRDATA[8:0] == refSenReg[1][8:0]) begin
                    detect_pass = 1;
                    $display("SENSOR Detect PASS: %0d == %0d", sen_tr.PRDATA[8:0], refSenReg[1][8:0]);
                end else begin
                    detect_pass = 0;
                    $display("SENSOR Detect FAIL: %0d == %0d", sen_tr.PRDATA[8:0], refSenReg[1][8:0]);
                end
            end else begin
                $display("SENSOR DETECT NOT ALLOWED");
                enable_pass = 1;
            end
        end
        ->gen_next_event;

        // 
        if (detect_pass == 1 || enable_pass == 1) begin
            pass_cnt = pass_cnt + 1;
        end else begin
            fail_cnt = fail_cnt + 1;
        end
        total_cnt = total_cnt + 1;
    end
endtask

    task report();
        $display("===============================");
        $display("==        Final Report       ==");
        $display("===============================");
        $display("      Write Test : %0d", write_cnt);
        $display("      Read Test  : %0d", read_cnt);
        $display("      PASS Test  : %0d", pass_cnt);
        $display("      Fail Test  : %0d", fail_cnt);
        $display("      Total Test : %0d", total_cnt);
        $display("===============================");
        $display("==   testbench is finished  ==");
        $display("===============================");
    endtask  //report

endclass  //scoreboard

class envirnment;
    
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Mon2SCB_mbox;
    generator              sen_gen;
    driver                 sen_drv;
    monitor                sen_mon;
    scoreboard             sen_scb;
    event                  gen_next_event;
    event                  drv_next_event;

    function new(virtual APB_Slave_Interface sen_intf);
        this.Gen2Drv_mbox = new();
        this.Mon2SCB_mbox = new();
        this.sen_gen = new(Gen2Drv_mbox, gen_next_event);
        this.sen_drv = new(sen_intf, Gen2Drv_mbox, drv_next_event);
        this.sen_mon = new(sen_intf, Mon2SCB_mbox, drv_next_event);
        this.sen_scb = new(Mon2SCB_mbox, gen_next_event);
    endfunction

    task run(int count);
        fork
            sen_gen.run(count);
            sen_drv.run();
            sen_mon.run();
            sen_scb.run();
        join_any
            sen_scb.report();
    endtask  //run
endclass  //envirnment

module tb_Sensor();

    envirnment sen_env;
    APB_Slave_Interface sen_intf(); // interface는 new를 만들어주지 않음

    always #5 sen_intf.PCLK = ~sen_intf.PCLK;

    ultrasonic_periph dut (
        // global signal
        .PCLK  (sen_intf.PCLK),
        .PRESET(sen_intf.PRESET),

        .PADDR  (sen_intf.PADDR),
        .PWDATA (sen_intf.PWDATA),
        .PWRITE (sen_intf.PWRITE),
        .PENABLE(sen_intf.PENABLE),

        .PSEL(sen_intf.PSEL),
        .PRDATA(sen_intf.PRDATA),
        .PREADY(sen_intf.PREADY),
        // signals
        .trigger(sen_intf.trigger),
        .echo(sen_intf.echo),
        .distance(sen_intf.distance)
    );

    initial begin
        sen_intf.PCLK   = 0;
        sen_intf.PRESET = 1;
        #10 sen_intf.PRESET = 0;
        sen_env = new(sen_intf); 
        sen_env.run(10000);  
        #30;
        $display("finished");
        $finish;
    end
endmodule

