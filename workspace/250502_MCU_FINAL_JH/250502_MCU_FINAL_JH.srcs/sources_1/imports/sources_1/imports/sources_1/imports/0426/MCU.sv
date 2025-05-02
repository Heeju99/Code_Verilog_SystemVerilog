`timescale 1ns / 1ps

module MCU (
    input  logic       clk,
    input  logic       reset,
    inout  logic [15:0] GPIOC,
    inout  logic [15:0] GPIOD,
    inout  logic INOUTDHT11,
    output logic [7:0] fndFont,
    output logic [3:0] fndCom,
    output logic tx,
    input logic rx,
    input logic HC_SR04_in,
    output logic HC_SR04_out
    
);
//

    // global signals
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [31:0] PADDR;
    logic [31:0] PWDATA;


    logic        PWRITE;
    logic        PENABLE;

    logic        PSEL_RAM;
    logic        PSEL_UART;
    logic        PSEL_GPIOC;
    logic        PSEL_GPIOD;
    logic        PSEL_FND;
    logic        PSEL_STOPWATCH;
    logic        PSEL_DHT11;
    logic        PSEL_HC_SR04;
    logic        PSEL_COUNT;

    logic [31:0] PRDATA_RAM;
    logic [31:0] PRDATA_UART;
    logic [31:0] PRDATA_GPIOC;
    logic [31:0] PRDATA_GPIOD;
    logic [31:0] PRDATA_FND;
    logic [31:0] PRDATA_STOPWATCH;
    logic [31:0] PRDATA_DHT11;
    logic [31:0] PRDATA_HC_SR04;
    logic [31:0] PRDATA_COUNT;
    
    logic        PREADY_RAM;
    logic        PREADY_UART;
    logic        PREADY_GPIOC;
    logic        PREADY_GPIOD;
    logic        PREADY_FND;
    logic        PREADY_STOPWATCH;
    logic        PREADY_DHT11;
    logic        PREADY_HC_SR04;
    logic        PREADY_COUNT;

    // CPU - APB_Master Signals
    // Internal Interface Signals
    logic        transfer;  // trigger signal
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        write;  // 1:write, 0:read
    logic        dataWe;
    logic [31:0] dataAddr;
    logic [31:0] dataWData;
    logic [31:0] dataRData;

    // ROM Signals
    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;

    assign PCLK = clk;
    assign PRESET = reset;
    assign addr = dataAddr;
    assign wdata = dataWData;
    assign dataRData = rdata;
    assign write = dataWe;

    rom U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    RV32I_Core U_Core (.*);

    APB_Master U_APB_Master (
        .*,
        .PSEL0  (PSEL_RAM),
        .PSEL1  (PSEL_GPIOC),
        .PSEL2  (PSEL_GPIOD),
        .PSEL3  (PSEL_FND),
        .PSEL4  (PSEL_UART),
        .PSEL5  (PSEL_DHT11),
        .PSEL6  (PSEL_HC_SR04),
        .PSEL7  (PSEL_COUNT),
        .PSEL8  (PSEL_STOPWATCH),
        .PSEL9  (),

        .PRDATA0(PRDATA_RAM),
        .PRDATA1(PRDATA_GPIOC),
        .PRDATA2(PRDATA_GPIOD),
        .PRDATA3(PRDATA_FND),
        .PRDATA4(PRDATA_UART),
        .PRDATA5(PRDATA_DHT11),
        .PRDATA6(PRDATA_HC_SR04),
        .PRDATA7(PRDATA_COUNT),
        .PRDATA8(PRDATA_STOPWATCH),
        .PRDATA9(),


        .PREADY0(PREADY_RAM),
        .PREADY1(PREADY_GPIOC),
        .PREADY2(PREADY_GPIOD),
        .PREADY3(PREADY_FND),
        .PREADY4(PREADY_UART),
        .PREADY5(PREADY_DHT11),
        .PREADY6(PREADY_HC_SR04),
        .PREADY7(PREADY_COUNT),
        .PREADY8(PREADY_STOPWATCH),
        .PREADY9()
    );

    ram U_RAM (
        .*,
        .PSEL  (PSEL_RAM),
        .PRDATA(PRDATA_RAM),
        .PREADY(PREADY_RAM)
    );





    GPIO_Periph U_GPIOC(
        .*,
        .PSEL(PSEL_GPIOC),
        .PRDATA(PRDATA_GPIOC),
        .PREADY(PREADY_GPIOC),
        // inport signals
        .inoutPort(GPIOC)
    );

    GPIO_Periph U_GPIOD(
        .*,
        .PSEL(PSEL_GPIOD),
        .PRDATA(PRDATA_GPIOD),
        .PREADY(PREADY_GPIOD),
        // inport signals
        .inoutPort(GPIOD)
    );
FND_Periph U_FND(
    // global signal
.*,
    .PSEL(PSEL_FND),
    .PRDATA(PRDATA_FND),
    .PREADY(PREADY_FND),
    // export signals
    .fndCom(fndCom),
    .fndFont(fndFont)
);




    uart_Periph U_UART_RX_Periph(
        .*,
        .PSEL(PSEL_UART),
        .PRDATA(PRDATA_UART),
        .PREADY(PREADY_UART),
        .tx(tx),
        .rx(rx)
    );



DHT11_Periph U_DHT11_Periph(
        .*,
        .PSEL(PSEL_DHT11),
        .PRDATA(PRDATA_DHT11),
        .PREADY(PREADY_DHT11),
        // inport signals
        .inoutPort(INOUTDHT11)
    );


    ultrasonic_periph U_HC_SR04_Periph(
    // global signal
        .*,
        .PSEL(PSEL_HC_SR04),
        .PRDATA(PRDATA_HC_SR04),
        .PREADY(PREADY_HC_SR04),
    // inport signals
    .trigger(HC_SR04_out),
    .echo(HC_SR04_in)
);



    Counter_Periph U_Counter_Periph(
    // global signal
        .*,
        .PSEL(PSEL_COUNT),
        .PRDATA(PRDATA_COUNT),
        .PREADY(PREADY_COUNT)
);

    STOPWATCH_Periph U_STOPWATCH_Periph(
    // global signal
        .*,
        .PSEL(PSEL_STOPWATCH),
        .PRDATA(PRDATA_STOPWATCH),
        .PREADY(PREADY_STOPWATCH)
);


endmodule
