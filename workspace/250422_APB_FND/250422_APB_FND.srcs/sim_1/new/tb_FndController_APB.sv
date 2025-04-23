/*`timescale 1ns / 1ps

class transaction; //FND에서 사용하는 값들을 만들어주기 위함
    
    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    //  outport signals
    logic [ 3:0] fndComm;  //dut out data
    logic [ 7:0] fndFont;   //dut out data

    //제약사항 적용하기
    constraint c_padder{PADDR inside {4'h0, 4'h4, 4'h8};} // 안의 값 중 하나만 사용
    constraint c_wdata{PWDATA <10;} // 10보다 작게

    task display(string name);
        $display(
        "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, fndComm=%h,fndFont=%h",
         name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, fndComm, fndFont);
    endtask //automatic

endclass //transaction


interface APB_Slave_Interface; //dut에 값을 넣기 전의 발사대 느낌
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    //  outport signals
    logic [ 3:0] fndComm;  //dut out data
    logic [ 7:0] fndFont;   //dut out data

endinterface

class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox #(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run (int repeat_counter);
        transaction fnd_tr;
        repeat (repeat_counter) begin
            fnd_tr = new(); //make instance
            if(!fnd_tr.randomize()) $error("Randomization Fail");
            fnd_tr.display("GEN");
            Gen2Drv_mbox.put(fnd_tr);
            @(gen_next_event); //wait a event from driver
        end
    endtask //run
endclass

class driver;
    virtual APB_Slave_Interface fnd_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
            mailbox #(transaction) Gen2Drv_mbox, event gen_next_event);
        this.fnd_intf = fnd_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run();
        forever begin
            Gen2Drv_mbox.get(fnd_tr);
            fnd_tr.display("DRV");
            @(posedge fnd_intf.PCLK); //Setup 구간
            fnd_intf.PADDR   <= fnd_tr.PADDR; 
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1;    ///write 동작 실행
            fnd_intf.PENABLE <= 1'b0;
            fnd_intf.PSEL    <= 1'b1;
            @(posedge fnd_intf.PCLK); //ACCESS 구간
            fnd_intf.PADDR   <= fnd_tr.PADDR; 
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1; 
            fnd_intf.PENABLE <= 1'b1;
            fnd_intf.PSEL    <= 1'b1;
            wait(fnd_intf.PREADY == 1'b1);
            @(posedge fnd_intf.PCLK);
            @(posedge fnd_intf.PCLK);
            ->gen_next_event; // event trigger, done신호를 generator에 보내는 역할
        end
    endtask
endclass

class environment;
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Mon2Scb_mbox;
    generator fnd_gen;
    driver fnd_drv;
    event gen_next_event;
    monitor fnd_mon;
    scoreboard fnd_scb;

    function new(virtual APB_Slave_Interface fnd_intf);
        Gen2Drv_mbox = new();
        Mon2Scb_mbox = new();
        this.fnd_gen = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv = new(fnd_intf, Gen2Drv_mbox, gen_next_event);
        this.fnd_mon = new(fnd_intf, Mon2Scb_mbox);
        this.fnd_scb = new(Mon2Scb_mbox);
    endfunction
    
    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
            fnd_mon.run();
            fnd_scb.run();
        join_any
    endtask
endclass

module tb_FndController_APB();

    environment fnd_env;
    APB_Slave_Interface fnd_intf();

    always #5 fnd_intf.PCLK = ~fnd_intf.PCLK;

    FND_Periph DUT(
    // global signal
        .PCLK(fnd_intf.PCLK),
        .PRESET(fnd_intf.PRESET),
        // APB Interface signals
        .PADDR(fnd_intf.PADDR),
        .PWDATA(fnd_intf.PWDATA),
        .PWRITE(fnd_intf.PWRITE),
        .PENABLE(fnd_intf.PENABLE),
        .PSEL(fnd_intf.PSEL),
        .PRDATA(fnd_intf.PRDATA),
        .PREADY(fnd_intf.PREADY),
        // outport signals
        .fndComm(fnd_intf.fndComm),
        .fndFont(fnd_intf.fndFont)
);

    initial begin
        fnd_intf.PCLK = 0;
        fnd_intf.PRESET = 1;
        #10;
        fnd_intf.PRESET = 0;
        fnd_env = new(fnd_intf);
        fnd_env.run(10);
        #30;
        $finish;
    end
endmodule
*/

`timescale 1ns / 1ps

class transaction; //FND에서 사용하는 값들을 만들어주기 위함
    
    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    //  outport signals
    logic [ 3:0] fndComm;  //dut out data
    logic [ 7:0] fndFont;   //dut out data

    //제약사항 적용하기
    constraint c_padder{PADDR inside {4'h0, 4'h4, 4'h8};} // 안의 값 중 하나만 사용
    constraint c_wdata{PWDATA <10;} // 10보다 작게

    task display(string name);
        $display(
        "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, fndComm=%h, fndFont=%h",
         name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, fndComm, fndFont);
    endtask //automatic

endclass //transaction


interface APB_Slave_Interface; //dut에 값을 넣기 전의 발사대 느낌
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    //  outport signals
    logic [ 3:0] fndComm;  //dut out data
    logic [ 7:0] fndFont;   //dut out data

endinterface

class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox #(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run (int repeat_counter);
        transaction fnd_tr;
        repeat (repeat_counter) begin
            fnd_tr = new(); //make instance
            if(!fnd_tr.randomize()) $error("Randomization Fail");
            fnd_tr.display("GEN");
            Gen2Drv_mbox.put(fnd_tr);
            @(gen_next_event); //wait a event from driver
        end
    endtask //run
endclass

class driver;
    virtual APB_Slave_Interface fnd_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
            mailbox #(transaction) Gen2Drv_mbox, event gen_next_event);
        this.fnd_intf = fnd_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run();
        forever begin
            Gen2Drv_mbox.get(fnd_tr);
            fnd_tr.display("MON");
            @(posedge fnd_intf.PCLK); //Setup 구간
            fnd_intf.PADDR   <= fnd_tr.PADDR; 
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1;    ///write 동작 실행
            fnd_intf.PENABLE <= 1'b0;
            fnd_intf.PSEL    <= 1'b1;
            @(posedge fnd_intf.PCLK); //ACCESS 구간
            fnd_intf.PADDR   <= fnd_tr.PADDR; 
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1; 
            fnd_intf.PENABLE <= 1'b1;
            fnd_intf.PSEL    <= 1'b1;
            wait(fnd_intf.PREADY == 1'b1);
            @(posedge fnd_intf.PCLK);
            @(posedge fnd_intf.PCLK);
            ->gen_next_event; // event trigger
        end
    endtask
endclass

class environment;
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Mon2Scb_mbox;
    generator fnd_gen;
    driver fnd_drv;
    event gen_next_event;
    monitor fnd_mon;
    scoreboard fnd_scb;

    function new(virtual APB_Slave_Interface fnd_intf);
        Gen2Drv_mbox = new();
        Mon2Scb_mbox = new();
        this.fnd_gen = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv = new(fnd_intf, Gen2Drv_mbox, gen_next_event);
        this.fnd_mon = new(fnd_intf, Mon2Scb_mbox);
        this.fnd_scb = new(Mon2Scb_mbox);
    endfunction
    
    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
	fnd_mon.run();
	fnd_scb.run(); //값 들어오면 무한 비교
        join_any
    endtask
endclass

class monitor;
    virtual APB_Slave_Interface fnd_intf;
    mailbox #(transaction) Mon2Scb_mbox;
    function new(virtual APB_Slave_Interface fnd_intf, mailbox #(transaction) Mon2Scb_mbox);
    this.Mon2Scb_mbox = Mon2Scb_mbox;
    this.fnd_intf = fnd_intf;
endfunction

    task run();
        transaction fnd_tr;
            forever begin
                fnd_tr = new();
                @(posedge fnd_intf.PCLK); //Setup 구간
                fnd_tr.PADDR   <= fnd_intf.PADDR; 
                fnd_tr.PWDATA  <= fnd_intf.PWDATA;
                fnd_tr.PWRITE  <= fnd_intf.PWRITE;///write 동작 실행
                fnd_tr.PENABLE <= fnd_intf.PENABLE;
                fnd_tr.PSEL    <= fnd_intf.PSEL;
	    fnd_tr.fndComm <= fnd_intf.fndComm;
                fnd_tr.fndFont   <= fnd_intf.fndFont; 
                @(posedge fnd_intf.PCLK); //ACCESS 구간
                fnd_tr.PADDR   <= fnd_intf.PADDR; 
                fnd_tr.PWDATA  <= fnd_intf.PWDATA;
                fnd_tr.PWRITE  <= fnd_intf.PWRITE; 
                fnd_tr.PENABLE <= fnd_intf.PENABLE;
                fnd_tr.PSEL    <= fnd_intf.PSEL;
	    fnd_tr.fndComm <= fnd_intf.fndComm;
                fnd_tr.fndFont   <= fnd_intf.fndFont; 
                wait(fnd_intf.PREADY == 1'b1);
                @(posedge fnd_intf.PCLK);
                @(posedge fnd_intf.PCLK);
                fnd_tr.display("DRV");
                Mon2Scb_mbox.put(fnd_tr);
            end
    endtask
endclass

class scoreboard;
    mailbox #(transaction) Mon2Scb_mbox;

    function new(mailbox #(transaction) Mon2Scb_mbox);
        this.Mon2Scb_mbox = Mon2Scb_mbox;
    endfunction

    task run ();
        transaction fnd_tr;
        forever begin
            Mon2Scb_mbox.get(fnd_tr);

            // 여기서 DUT의 출력(fndComm, fndFont)을 체크하는 로직 작성
            if (fnd_tr.PADDR == 4'h0) begin
                // 예를 들면, 주소가 0일 때 fndComm, fndFont 비교
                if (fnd_tr.fndComm !== 4'h0) $error("[SCB] fndComm mismatch! Expected: 0, Got: %h", fnd_tr.fndComm);
                if (fnd_tr.fndFont !== (1 << fnd_tr.PWDATA)) $error("[SCB] fndFont mismatch! Expected: %h, Got: %h", (1 << fnd_tr.PWDATA), fnd_tr.fndFont);
            end
            else if (fnd_tr.PADDR == 4'h4) begin
                // 예를 들면, 주소가 4일 때
                if (fnd_tr.fndComm !== 4'h4) $error("[SCB] fndComm mismatch! Expected: 4, Got: %h", fnd_tr.fndComm);
                if (fnd_tr.fndFont !== (1 << fnd_tr.PWDATA)) $error("[SCB] fndFont mismatch! Expected: %h, Got: %h", (1 << fnd_tr.PWDATA), fnd_tr.fndFont);
            end
            else if (fnd_tr.PADDR == 4'h8) begin
                if (fnd_tr.fndComm !== 4'h8) $error("[SCB] fndComm mismatch! Expected: 8, Got: %h", fnd_tr.fndComm);
                if (fnd_tr.fndFont !== (1 << fnd_tr.PWDATA)) $error("[SCB] fndFont mismatch! Expected: %h, Got: %h", (1 << fnd_tr.PWDATA), fnd_tr.fndFont);
            end
            else begin
                $error("[SCB] Invalid Address %h detected!", fnd_tr.PADDR);
            end
        end
    endtask
endclass
// FND에서 표시할 값은 PWDATA 값을 기반으로 시프트 연산을 통해 2의 거듭제곱 패턴을 생성하게 돼.
//그 이유는 PWDATA 값이 숫자이기 때문에, 그 숫자만큼 1을 왼쪽으로 이동시켜서 해당 숫자에 맞는 
//비트 패턴을 FND에 전달하려는 목적이야.

module tb_FndController_APB();

    environment fnd_env;
    APB_Slave_Interface fnd_intf();

    always #5 fnd_intf.PCLK = ~fnd_intf.PCLK;

    FND_Periph DUT(
    // global signal
        .PCLK(fnd_intf.PCLK),
        .PRESET(fnd_intf.PRESET),
        // APB Interface signals
        .PADDR(fnd_intf.PADDR),
        .PWDATA(fnd_intf.PWDATA),
        .PWRITE(fnd_intf.PWRITE),
        .PENABLE(fnd_intf.PENABLE),
        .PSEL(fnd_intf.PSEL),
        .PRDATA(fnd_intf.PRDATA),
        .PREADY(fnd_intf.PREADY),
        // outport signals
        .fndComm(fnd_intf.fndComm),
        .fndFont(fnd_intf.fndFont)
);

    initial begin
        fnd_intf.PCLK = 0;
        fnd_intf.PRESET = 1;
        #10;
        fnd_intf.PRESET = 0;
        fnd_env = new(fnd_intf);
        fnd_env.run(10);
        #30;
        $finish;
    end
endmodule