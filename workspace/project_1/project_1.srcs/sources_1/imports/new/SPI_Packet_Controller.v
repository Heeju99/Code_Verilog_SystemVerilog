`timescale 1ns / 1ps

//==============================================================================
// SPI 패킷 전송 컨트롤러 모듈
//==============================================================================

module SPI_Packet_Controller #(
    parameter BYTES_PER_PACKET = 4,    // 한 번에 보낼 바이트 수
    parameter PACKET_COUNT = 10         // 총 패킷 수
) (
    input wire clk,
    input wire reset,
    
    // 사용자 인터페이스
    input wire start_button,        // 버튼 입력 (edge triggered)
    output reg sequence_done,       // 전체 시퀀스 완료
    
    // SPI Master 인터페이스  
    output reg spi_start,           // SPI 시작 신호
    output reg [7:0] spi_tx_data,   // SPI 전송 데이터
    input wire spi_done,            // SPI 완료 신호
    input wire spi_ready            // SPI 준비 신호
);

    // 0.1초 = 100ms = 12,500,000 클럭 (125MHz 기준)
    localparam TIMER_100MS = 12_500_000;
    
    // 상태 머신
    localparam IDLE = 2'b00, 
               TRANSMIT = 2'b01, 
               WAIT_TIMER = 2'b10,
               COOLDOWN = 2'b11;  // 쿨다운 상태 추가
    
    // 전송할 데이터 (4바이트씩 10세트 = 40바이트 총)
    reg [7:0] tx_data [0:39];  // 40바이트 데이터
    initial begin
        // 패킷 1 (4바이트)
        tx_data[0] = 8'h01; tx_data[1] = 8'h02; tx_data[2] = 8'h03; tx_data[3] = 8'h04;
        // 패킷 2 (4바이트)  
        tx_data[4] = 8'h11; tx_data[5] = 8'h12; tx_data[6] = 8'h13; tx_data[7] = 8'h14;
        // 패킷 3 (4바이트)
        tx_data[8] = 8'h21; tx_data[9] = 8'h22; tx_data[10] = 8'h23; tx_data[11] = 8'h24;
        // 패킷 4 (4바이트)
        tx_data[12] = 8'h31; tx_data[13] = 8'h32; tx_data[14] = 8'h33; tx_data[15] = 8'h34;
        // 패킷 5 (4바이트)
        tx_data[16] = 8'h41; tx_data[17] = 8'h42; tx_data[18] = 8'h43; tx_data[19] = 8'h44;
        // 패킷 6 (4바이트)
        tx_data[20] = 8'h51; tx_data[21] = 8'h52; tx_data[22] = 8'h53; tx_data[23] = 8'h54;
        // 패킷 7 (4바이트)
        tx_data[24] = 8'h61; tx_data[25] = 8'h62; tx_data[26] = 8'h63; tx_data[27] = 8'h64;
        // 패킷 8 (4바이트)
        tx_data[28] = 8'h71; tx_data[29] = 8'h72; tx_data[30] = 8'h73; tx_data[31] = 8'h74;
        // 패킷 9 (4바이트)
        tx_data[32] = 8'h81; tx_data[33] = 8'h82; tx_data[34] = 8'h83; tx_data[35] = 8'h84;
        // 패킷 10 (4바이트)
        tx_data[36] = 8'h91; tx_data[37] = 8'h92; tx_data[38] = 8'h93; tx_data[39] = 8'h94;
    end
    
    // 상태 머신 및 제어 신호
    reg [1:0] state, state_next;
    reg [31:0] timer_counter, timer_counter_next;
    reg [3:0] packet_counter, packet_counter_next;  // 0~9 (10개 패킷)
    reg [1:0] byte_counter, byte_counter_next;      // 0~3 (4바이트)
    reg spi_start_next;
    reg [7:0] spi_tx_data_next;
    reg sequence_done_next;
    
    // 순차 로직
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            timer_counter <= 0;
            packet_counter <= 0;
            byte_counter <= 0;
            spi_start <= 1'b0;
            spi_tx_data <= 8'h00;
            sequence_done <= 1'b0;
        end else begin
            state <= state_next;
            timer_counter <= timer_counter_next;
            packet_counter <= packet_counter_next;
            byte_counter <= byte_counter_next;
            spi_start <= spi_start_next;
            spi_tx_data <= spi_tx_data_next;
            sequence_done <= sequence_done_next;
        end
    end
    
    // 조합 로직
    always @(*) begin
        // 기본값
        state_next = state;
        timer_counter_next = timer_counter;
        packet_counter_next = packet_counter;
        byte_counter_next = byte_counter;
        spi_start_next = 1'b0;
        spi_tx_data_next = spi_tx_data;
        sequence_done_next = 1'b0;
        
        case (state)
            IDLE: begin
                if (start_button) begin  // 디바운스된 버튼 edge 신호
                    // 버튼 눌림 - 첫 번째 패킷의 첫 번째 바이트 전송 시작
                    packet_counter_next = 0;
                    byte_counter_next = 0;
                    spi_tx_data_next = tx_data[0];  // 첫 번째 바이트
                    spi_start_next = 1'b1;
                    state_next = TRANSMIT;
                end
            end
            
            TRANSMIT: begin
                    if (spi_done) begin
                    if (byte_counter == BYTES_PER_PACKET - 1) begin
                        // 현재 패킷의 4바이트 전송 완료
                        if (packet_counter == PACKET_COUNT - 1) begin
                            // 전체 시퀀스 완료 - 쿨다운 시작
                            timer_counter_next = 0;
                            state_next = COOLDOWN;
                        end else begin
                            // 다음 패킷을 위해 0.1초 대기
                            timer_counter_next = 0;
                            state_next = WAIT_TIMER;
                        end
                    end else begin
                        // 현재 패킷의 다음 바이트 전송
                        byte_counter_next = byte_counter + 1;
                        spi_tx_data_next = tx_data[packet_counter * BYTES_PER_PACKET + byte_counter + 1];
                        spi_start_next = 1'b1;
                    end
                end
            end
            
            WAIT_TIMER: begin
                if (timer_counter == TIMER_100MS - 1) begin
                    // 0.1초 대기 완료 - 다음 패킷 전송 시작
                    packet_counter_next = packet_counter + 1;
                    byte_counter_next = 0;
                    spi_tx_data_next = tx_data[(packet_counter + 1) * BYTES_PER_PACKET];
                    spi_start_next = 1'b1;
                    state_next = TRANSMIT;
                end else begin
                    timer_counter_next = timer_counter + 1;
                end
            end
            
            COOLDOWN: begin
                if (timer_counter == TIMER_100MS - 1) begin
                    // 쿨다운 완료 - 시퀀스 완료 신호 출력 후 IDLE로
                    sequence_done_next = 1'b1;
                    state_next = IDLE;
                end else begin
                    timer_counter_next = timer_counter + 1;
                end
            end
            
            default: state_next = IDLE;
        endcase
    end

endmodule
