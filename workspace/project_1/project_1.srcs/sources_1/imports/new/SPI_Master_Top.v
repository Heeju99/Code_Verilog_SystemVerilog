`timescale 1ns / 1ps

module SPI_Master_Top #(
    parameter DATA_WIDTH = 8,
    parameter SLAVE_CS   = 2,
    parameter BYTES_PER_PACKET = 4,   // 한 번에 보낼 바이트 수
    parameter PACKET_COUNT = 10       // 총 패킷 수
) (
    // Global signals
    input wire clk,   // 125MHz system clock
    input wire reset, // Reset signal

    // Control signals
    input  wire                  start,    // 원본 버튼 입력 (디바운스 전)
    output wire                  done,         // 전체 시퀀스 완료 신호

    // SPI interface
    output wire                SCLK,  // SPI Clock
    output wire                MOSI,  // Master Out Slave In
    output wire [SLAVE_CS-1:0] CS     // Chip Select
);

    // 내부 신호들
    wire start_debounced;      // 디바운스된 버튼 신호
    wire spi_start;
    wire [7:0] spi_tx_data;
    wire spi_done;
    wire spi_ready;
    wire spi_mosi;
    
    // MOSI는 전송 중일 때만 활성화
    assign MOSI = spi_ready ? 1'b0 : spi_mosi;

    // 버튼 디바운스 모듈
    btn_debounce U_Debounce (
        .clk    (clk),
        .reset  (reset),
        .i_btn  (start),
        .o_btn  (start_debounced)
    );

    // SPI 패킷 컨트롤러
    SPI_Packet_Controller #(
        .BYTES_PER_PACKET(BYTES_PER_PACKET),
        .PACKET_COUNT(PACKET_COUNT)
    ) U_Packet_Controller (
        .clk           (clk),
        .reset         (reset),
        .start_button  (start_debounced),  // 디바운스된 신호 사용
        .sequence_done (done),
        .spi_start     (spi_start),
        .spi_tx_data   (spi_tx_data),
        .spi_done      (spi_done),
        .spi_ready     (spi_ready)
    );

    // SPI Master 인스턴스
    SPI_Master #(
        .SLAVE_CS  (SLAVE_CS),
        .DATA_WIDTH(DATA_WIDTH),
        .SCLK_DIV  (125)
    ) U_SPI_Master (
        .clk      (clk),
        .reset    (reset),
        .cpol     (1'b0),
        .cpha     (1'b0),
        .start    (spi_start),
        .tx_data  (spi_tx_data),
        .rx_data  (),
        .done     (spi_done),
        .ready    (spi_ready),
        .slave_sel(1'b0),
        .SCLK     (SCLK),
        .MOSI     (spi_mosi),
        .MISO     (),
        .CS       (CS)
    );

endmodule