`timescale 1ns / 1ps

class transaction;

    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;  // dut out data
    logic             PREADY;  // dut out data
    // outport signals
    logic      [ 3:0] fndComm;  // dut out data
    logic      [ 7:0] fndFont;  // dut out data
    //additional
    logic      [ 1:0] digit_sel;

    constraint c_paddr {PADDR inside {4'h0, 4'h4, 4'h8};}
    constraint c_pwdata {PWDATA < 10000;}
    constraint c_paddr_0 {
        if(PADDR == 4'h0)   //FCR_en
            PWDATA inside {1'b0,1'b1};
        else if(PADDR == 4'h4)  //FDR
            PWDATA < 10000; 
        else if(PADDR == 4'h8)  //FPR
            PWDATA < 4'b1111;
    }

    task display(string name);
        $display(
            "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, fndComm=%h, fndFont=%h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, fndComm,
            fndFont);
    endtask  //

endclass  //transaction

interface APB_Slave_Interface;
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;  // dut out data
    logic        PREADY;  // dut out data
    // outport signals
    logic [ 3:0] fndComm;  // dut out data
    logic [ 7:0] fndFont;  // dut out data
    //additional
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
            fnd_tr = new();  // make instrance
            if (!fnd_tr.randomize()) $error("Randomization fail!");
            fnd_tr.display("GEN");
            Gen2Drv_mbox.put(fnd_tr);
            @(gen_next_event);  // wait a event from driver
        end
    endtask  //
endclass  //generator

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
            fnd_intf.PADDR   <= fnd_tr.PADDR;
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1;
            fnd_intf.PENABLE <= 1'b0;
            fnd_intf.PSEL    <= 1'b1;
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR   <= fnd_tr.PADDR;
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1;
            fnd_intf.PENABLE <= 1'b1;
            fnd_intf.PSEL    <= 1'b1;
            wait (fnd_intf.PREADY == 1'b1);
        end
    endtask  //
endclass  //driver

class monitor;
    mailbox #(transaction) Mon2SCB_mbox;
    virtual APB_Slave_Interface fnd_intf;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf, mailbox #(transaction) Mon2SCB_mbox);
        this.fnd_intf = fnd_intf;
        this.Mon2SCB_mbox = Mon2SCB_mbox;
    endfunction

    task run();
        forever begin
            fnd_tr = new(); //instance 생성
            wait (fnd_intf.PREADY == 1'b1); // wait for PREADY From DUT intf
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
            fnd_tr.digit_sel = fnd_intf.digit_sel;
            fnd_tr.display("MON");
            Mon2SCB_mbox.put(fnd_tr);
            @(posedge fnd_intf.PCLK);
        end
    endtask
endclass

class scoreboard;
    mailbox #(transaction) Mon2SCB_mbox;
    transaction fnd_tr;
    event gen_next_event;

    //reference model
    logic [31:0] refFndReg[0:2]; //32bit register 3개
    logic [7:0] refFndFont[0:15] = {
            8'hc0, //8비트의 헥사c0값
            8'hF9,
            8'hA4,
            8'hB0,
            8'h99,
            8'h92,
            8'h82,
            8'hf8,
            8'h80,
            8'h90,
            8'h88,
            8'h83,
            8'hc6,
            8'ha1,
            8'h86,
            8'h8e
    };

    logic [6:0] write_cnt;
    logic [6:0] read_cnt;
    logic [6:0] pass_cnt;
    logic [6:0] fail_cnt;
    logic [6:0] total_cnt;

    function new(mailbox #(transaction) Mon2SCB_mbox,event gen_next_event);
        this.Mon2SCB_mbox = Mon2SCB_mbox;
        this.gen_next_event = gen_next_event;

        for (int i = 0; i < 3; i++) begin //초기화
            refFndReg[i] = 0;
        end
    endfunction //new()


     task run();
        transaction fnd_tr;
        forever begin
            Mon2SCB_mbox.get(fnd_tr);
            fnd_tr.display("SCB");

            if (fnd_tr.PWRITE) begin // write mode
                refFndReg[fnd_tr.PADDR[3:2]] = fnd_tr.PWDATA;
                int digit[0] = refFndReg[1] % 10;
                int digit[1] = refFndReg[1] /10 % 10;
                int digit[2] = refFndReg[1] /100 % 10;
                int digit[3] = refFndReg[1] /1000 % 10;
                // fpr check
                    if (refFndReg[2][digit[fnd_tr.digit_sel]] == ~fnd_tr.fndFont[7])
                        $display("FND DP PASS %h, %h", refFndReg[2][digit[fnd_tr.digit_sel]], ~fnd_tr.fndFont[7]);
                    else
                        $display("FND DP FAIL %h, %h", refFndReg[2][digit[fnd_tr.digit_sel]], ~fnd_tr.fndFont[7]);

                    // fcr_en check
                    if (refFndReg[0] == 0) begin
                        if (fnd_tr.fndComm == 4'hf)
                            $display("FND Enable Pass");
                        else
                            $display("FND Enable Fail");
                    end else begin
                    // fdr check
                    if ({~refFndReg[2][digit[fnd_tr.digit_sel]], refFndFont[digit[fnd_tr.digit_sel]][6:0]}== fnd_tr.fndFont)
                        $display("FND FONT PASS %h, %h",{~refFndReg[2][digit[fnd_tr.digit_sel]], refFndFont[digit[fnd_tr.digit_sel]][6:0]},fnd_tr.fndFont );
                    else
                        $display("FND FONT FAIL %h, %h", {~refFndReg[2][digit[fnd_tr.digit_sel]], refFndFont[digit[fnd_tr.digit_sel]][6:0]}, fnd_tr.fndFont);
                    end
                end else begin  // read mode
            end
            ->gen_next_event;
        end
    endtask 

    task report();
        $display("=========================");
        $display("======Final Report=======");
        $display("=========================");
        $display("Write Test %0d", scb.write_cnt);
        $display("Read  Test %0d", scb.read_cnt);
        $display("Pass  Test %0d", scb.pass_cnt);
        $display("Fail  Test %0d", scb.fail_cnt);
        $display("Total Test %0d", scb.total_cnt);
        $display("=========================");
        $display("==testbench is finished==");
        $display("=========================");
    endtask
endclass //className

class envirnment;
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Mon2SCB_mbox;
    generator fnd_gen;
    driver fnd_drv;
    event gen_next_event;
    monitor fnd_mon;
    scoreboard fnd_scb;

    function new(virtual APB_Slave_Interface fnd_intf);
        Gen2Drv_mbox = new();
        Mon2SCB_mbox = new();
        this.fnd_gen = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv = new(fnd_intf, Gen2Drv_mbox);
        this.fnd_mon = new(fnd_intf, Mon2SCB_mbox);
        this.fnd_scb = new(Mon2SCB_mbox, gen_next_event);
    endfunction  //new()

    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
            fnd_mon.run();
            fnd_scb.run();
        join_any
        ;
    endtask  //
endclass  //envirnment

module tb_fndController_APB_Periph ();

    envirnment fnd_env;
    APB_Slave_Interface fnd_intf ();

    always #5 fnd_intf.PCLK = ~fnd_intf.PCLK;

    FND_Periph dut (
        // global signal
        .PCLK(fnd_intf.PCLK),
        .PRESET(fnd_intf.PRESET),
        // APB Interface Signals
        .PADDR(fnd_intf.PADDR),
        .PWDATA(fnd_intf.PWDATA),
        .PWRITE(fnd_intf.PWRITE),
        .PENABLE(fnd_intf.PENABLE),
        .PSEL(fnd_intf.PSEL),
        .PRDATA(fnd_intf.PRDATA),
        .PREADY(fnd_intf.PREADY),
        // outport signals
        .fndComm(fnd_intf.fndComm),
        .fndFont(fnd_intf.fndFont),
        //additional
        .digit_sel(fnd_intf.digit_sel)
    );

    initial begin
        fnd_intf.PCLK   = 0;
        fnd_intf.PRESET = 1;
        #10 fnd_intf.PRESET = 0;
        fnd_env = new(fnd_intf);
        fnd_env.run(50);
        fnd_env.fnd_scb.report();
        #30;
        $display("finished");
        $stop;
    end
endmodule
