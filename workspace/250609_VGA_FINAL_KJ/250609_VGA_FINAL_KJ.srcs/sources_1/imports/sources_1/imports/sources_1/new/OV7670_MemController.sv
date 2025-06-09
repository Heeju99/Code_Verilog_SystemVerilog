`timescale 1ns / 1ps

module OV7670_MemController (
    input  logic        pclk,
    input  logic        reset,
    input  logic        href,
    input  logic        v_sync,
    input  logic [ 7:0] ov7670_data,
    output logic        we,
    output logic [16:0] wAddr1,
    output logic [16:0] wAddr2,
    output logic [15:0] wData
);

    logic [9:0] h_counter;
    logic [7:0] v_counter;
    logic [7:0] byte0, byte1;
    logic       byte_toggle;
    logic [15:0] pix_data_reg;
    logic [16:0] addr_reg1;
    logic [16:0] addr_reg2;

    always_ff @(posedge pclk) begin
        if (reset) begin
            h_counter     <= 0;
            v_counter     <= 0;
            byte0         <= 0;
            byte1         <= 0;
            byte_toggle   <= 0;
            we            <= 0;
            pix_data_reg  <= 0;
            addr_reg1      <= 0;
            addr_reg2      <= 0;
        end else begin
            we <= 0;
            if (v_sync) begin
                h_counter   <= 0;
                v_counter   <= 0;
                byte_toggle <= 0;
            end else if (href) begin
                if (byte_toggle == 0) begin
                    byte0 <= ov7670_data;
                end else begin
                    pix_data_reg <= {byte0, ov7670_data};  // safe: ov7670_data는 이미 valid
                    addr_reg1     <= (v_counter>>1) * 160 + (h_counter>>1);
                    addr_reg2     <= (v_counter>>2) * 80 + (h_counter>>2);
                    h_counter    <= h_counter + 1;
                    we    <= 1;
                end
                byte_toggle <= ~byte_toggle;

                if (h_counter == 319 && byte_toggle == 1) begin //319
                    h_counter <= 0;
                    if (v_counter < 239) // 239
                        v_counter <= v_counter + 1;
                end
            end else begin
                h_counter   <= 0;
                byte_toggle <= 0;
            end
        end
    end

    assign wAddr1 = addr_reg1;
    assign wAddr2 = addr_reg2;
    assign wData = pix_data_reg;

endmodule