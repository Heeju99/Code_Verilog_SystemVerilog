`timescale 1ns / 1ps

module tb_FIFO();

    // global signal
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

    // inport signals
    logic real_ready;

    FIFO_Periph DUT(
    .PCLK(PCLK),
    .PRESET(PRESET),
    // APB Interface Signals
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PSEL(PSEL),
    .PRDATA(PRDATA),
    .PREADY(PREADY),

    // inport signals
    .real_ready(real_ready)
);

    always #5 PCLK = ~PCLK;

    initial begin
        PCLK       = 0;
        PRESET     = 1;
        #10 PRESET = 0;
        @(posedge PCLK);
        PADDR      = 4;
        PWDATA     = 3;
        PWRITE     = 1;
        PSEL       = 1;
        PENABLE    = 1;
        @(posedge PCLK);
        PSEL       = 0;
        PENABLE    = 0;

        wait(PREADY);
        @(posedge PCLK);
        @(posedge PCLK);
        @(posedge PCLK);

        PADDR      = 4;
        PWDATA     = 5;
        PWRITE     = 1;
        PSEL       = 1;
        PENABLE    = 1;
        @(posedge PCLK);
        PSEL       = 0;
        PENABLE    = 0;

        wait(PREADY);
        @(posedge PCLK);
        @(posedge PCLK);
        @(posedge PCLK);

        //read
        PADDR      = 8;
        PWRITE     = 0;
        PSEL       = 1;
        PENABLE    = 1;
        @(posedge PCLK);
        PSEL       = 0;
        PENABLE    = 0;

        wait(PREADY);
        @(posedge PCLK);
        @(posedge PCLK);
        @(posedge PCLK);

        PADDR      = 8;
        PWRITE     = 0;
        PSEL       = 1;
        PENABLE    = 1;
        @(posedge PCLK);
        PSEL       = 0;
        PENABLE    = 0;

        end
endmodule
