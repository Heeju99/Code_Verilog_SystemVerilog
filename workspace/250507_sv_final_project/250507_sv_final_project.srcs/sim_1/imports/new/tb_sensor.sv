`timescale 1ns / 1ps

class transaction;
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand bit          PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;
    logic             PREADY;
    // export signals

    logic        trigger;
    logic        echo;
    //logic      [ 3:0] fndComm;
    //logic      [ 7:0] fndFont;
    //logic      [ 1:0] digit_sel;

    constraint c_paddr {PADDR inside {4'h0, 4'h4, 4'h8};}
    constraint c_waddr {PWDATA < 400;}
    constraint c_paddr_0 {
        if (PADDR == 0)
        PWDATA inside {1'b0, 1'b1};
        else
        if (PADDR == 4)
        PWDATA < 10000;
        else
        if (PADDR == 8) PWDATA inside {1'b0, 1'b1};
    }

    task display(string name);
        $display(
            "[%s] PADDR=%h, PWDATA=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, trigger=%h, echo=%h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY,
            trigger, echo);
    endtask  //display
endclass  //transaction

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
    logic [ 3:0] fndComm;
    logic [ 7:0] fndFont;
    logic [ 1:0] digit_sel;

endinterface  //APB_Slave_Interface

class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction fnd_tr;
        repeat (repeat_counter) begin
            fnd_tr = new(); 
            if (!fnd_tr.randomize())
                $error("Randomization fail");  
            fnd_tr.display("GEN");  
            Gen2Drv_mbox.put(fnd_tr); 
            @(gen_next_event); 
        end
    endtask  //run
endclass  //generater

class driver;
    virtual APB_Slave_Interface fnd_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Gen2Drv_mbox);
        this.fnd_intf = fnd_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(fnd_tr);
            fnd_tr.display("DRV");
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR <= fnd_tr.PADDR;
            fnd_intf.PWDATA <= fnd_tr.PWDATA;
            fnd_intf.PWRITE <= fnd_tr.PWRITE;
            fnd_intf.PENABLE <= 1'b0;
            fnd_intf.PSEL <= 1'b1;
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR <= fnd_tr.PADDR;
            fnd_intf.PWDATA <= fnd_tr.PWDATA;
            fnd_intf.PWRITE <= fnd_tr.PWRITE;
            fnd_intf.PENABLE <= 1'b1;
            fnd_intf.PSEL <= 1'b1;
            wait (fnd_intf.PREADY == 1'b1);
            @(posedge fnd_intf.PCLK);
            @(posedge fnd_intf.PCLK);
            @(posedge fnd_intf.PCLK);
        end
    endtask  //run
endclass  //dirver

class monitor;
    mailbox #(transaction) Mon2SCB_mbox;
    virtual APB_Slave_Interface fnd_intf;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Mon2SCB_mbox);
        this.fnd_intf = fnd_intf;
        this.Mon2SCB_mbox = Mon2SCB_mbox;
    endfunction  //new()

    task run();
        forever begin
            fnd_tr = new();
            @(posedge fnd_intf.PREADY);
            #1;
            fnd_tr.PADDR   = fnd_intf.PADDR;
            fnd_tr.PWDATA  = fnd_intf.PWDATA;
            fnd_tr.PWRITE  = fnd_intf.PWRITE;
            fnd_tr.PENABLE = fnd_intf.PENABLE;
            fnd_tr.PSEL    = fnd_intf.PSEL;
            fnd_tr.PRDATA  = fnd_intf.PRDATA;
            fnd_tr.PREADY  = fnd_intf.PREADY;
            fnd_tr.fndComm = fnd_intf.fndComm;
            fnd_tr.fndFont = fnd_intf.fndFont;
            fnd_tr.digit_sel     = fnd_intf.digit_sel;
            Mon2SCB_mbox.put(fnd_tr);
            fnd_tr.display("MON");
            @(posedge fnd_intf.PCLK);
        end
    endtask  //run
endclass  //monitor

class scoreboard;
    mailbox #(transaction) Mon2SCB_mbox;
    transaction fnd_tr;
    event gen_next_event;

    // reference model
    logic [3:0] digit[3:0];
    logic [31:0] refFndReg[0:2];
    logic [7:0] refFndFont[0:15] = '{
        8'hC0,
        8'hF9,
        8'hA4,
        8'hB0,
        8'h99,
        8'h92,
        8'h82,
        8'hF8,
        8'h80,
        8'h90,
        8'h88,
        8'h83,
        8'hC6,
        8'hA1,
        8'h86,
        8'h8E
    };
    logic [9:0] write_cnt = 0; //to count
    logic [9:0] read_cnt = 0;
    logic [9:0] pass_cnt = 0;
    logic [9:0] fail_cnt = 0;
    logic [9:0] total_cnt = 0;

    logic font_pass;
    logic enable_pass;
    logic read_pass;

    function new(mailbox#(transaction) Mon2SCB_mbox, event gen_next_event);
        this.Mon2SCB_mbox   = Mon2SCB_mbox;
        this.gen_next_event = gen_next_event;
        for (int i = 0; i < 3; i++) begin
            refFndReg[i] = 0;
        end
    endfunction  //new()

    task run();
        font_pass   = 0;
        enable_pass = 0;
        read_pass   = 0;
        forever begin
            Mon2SCB_mbox.get(fnd_tr);
            fnd_tr.display("SCB");
            if (fnd_tr.PWRITE) begin  // write mode
                refFndReg[fnd_tr.PADDR[3:2]] = fnd_tr.PWDATA;
                //reference register updata
                digit[0] = refFndReg[1] % 10;
                digit[1] = (refFndReg[1] / 10) % 10;
                digit[2] = (refFndReg[1] / 100) % 10;
                digit[3] = (refFndReg[1] / 1000) % 10;

                write_cnt = write_cnt + 1; //write mode count
                //fdr check
                if ({~refFndReg[2][fnd_tr.digit_sel],refFndFont[digit[fnd_tr.digit_sel]][6:0]} == fnd_tr.fndFont) begin
                    $display("FND Font PASS, %h, %h", {
                             ~refFndReg[2][fnd_tr.digit_sel],
                             refFndFont[digit[fnd_tr.digit_sel]][6:0]},
                             fnd_tr.fndFont);
                    font_pass = 1;
                end else begin
                    $display("FND Font FAIL, %h, %h", {
                             ~refFndReg[2][fnd_tr.digit_sel],
                             refFndFont[digit[fnd_tr.digit_sel]][6:0]},
                             fnd_tr.fndFont);
                    font_pass = 0;
                end

                //fcr_en
                if (refFndReg[0] == 0) begin  //en == 0
                    if (4'hf == fnd_tr.fndComm) begin
                        $display("FND EnableComport PASS");
                        enable_pass = 1;
                    end else begin
                        $display("FND Enable FAIL");
                        enable_pass = 0;
                    end
                //fndComm enable
                //enable signal이 fndcomm에 가하는 effect
                end else begin  // en == 1;
                    if (4'b1 << fnd_tr.digit_sel == ~fnd_tr.fndComm[3:0])
                        $display("FND Comport PASS, %h, %h", 4'b1 << fnd_tr.digit_sel, ~fnd_tr.fndComm[3:0]);
                    else
                        $display("FND Comport FAIL, %h, %h", 4'b1 << fnd_tr.digit_sel, ~fnd_tr.fndComm[3:0]);
                end
            end else begin  // read mode
                if (refFndReg[fnd_tr.PADDR[3:2]] == fnd_tr.PRDATA) begin
                    $display("FND Read PASS, %h, %h", refFndReg[fnd_tr.PADDR[3:2]], fnd_tr.PRDATA);

                    read_pass = 1; //to count
                end else begin
                    $display("FND Read FAIL, %h, %h", refFndReg[fnd_tr.PADDR[3:2]], fnd_tr.PRDATA);
                    read_pass = 0; //to count
                end
                read_cnt = read_cnt + 1; //read count
            end
            ->gen_next_event; //send "done" to Gen

            //calculate score + display
            if ((font_pass == 1 & enable_pass == 1) | read_pass == 1) begin
                pass_cnt = pass_cnt + 1;
            end else begin
                fail_cnt = fail_cnt + 1;
            end
            total_cnt = total_cnt + 1;
        end
    endtask  //run

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
        $display("==   test bench is finished  ==");
        $display("===============================");
    endtask  //report

endclass  //scoreboard

class envirnment;
    
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Mon2SCB_mbox;
    generator              fnd_gen;
    driver                 fnd_drv;
    monitor                fnd_mon;
    scoreboard             fnd_scb;
    event                  gen_next_event;

    function new(virtual APB_Slave_Interface fnd_intf);
        this.Gen2Drv_mbox = new();
        this.Mon2SCB_mbox = new();
        this.fnd_gen = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv = new(fnd_intf, Gen2Drv_mbox);
        this.fnd_mon = new(fnd_intf, Mon2SCB_mbox);
        this.fnd_scb = new(Mon2SCB_mbox, gen_next_event);
    endfunction

    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
            fnd_mon.run();
            fnd_scb.run();
        join_any
            fnd_scb.report();
    endtask  //run
endclass  //envirnment

module tb_FNDcontroller ();

    envirnment fnd_env;
    APB_Slave_Interface fnd_intf(); // interface는 new를 만들어주지 않음

    always #5 fnd_intf.PCLK = ~fnd_intf.PCLK;

    ultrasonic_periph dut (
        // global signal
        .PCLK  (fnd_intf.PCLK),
        .PRESET(fnd_intf.PRESET),

        .PADDR  (fnd_intf.PADDR),
        .PWDATA (fnd_intf.PWDATA),
        .PWRITE (fnd_intf.PWRITE),
        .PENABLE(fnd_intf.PENABLE),

        .PSEL(fnd_intf.PSEL),
        .PRDATA(fnd_intf.PRDATA),
        .PREADY(fnd_intf.PREADY),
        // inport signals
        .trigger(fnd_intf.trigger),
        .echo(fnd_intf.echo)
    );

    initial begin
        fnd_intf.PCLK   = 0;
        fnd_intf.PRESET = 1;
        #10 fnd_intf.PRESET = 0;
        fnd_env = new(fnd_intf);  // envirnment instance 생성
        fnd_env.run(1000);  // 10번 시도
        #30;
        $display("finished");
        $finish;
    end
endmodule

