`timescale 1ns / 1ps

module OV7670_MemController (
    input  logic        pclk,
    input  logic        reset,
    input  logic        href,
    input  logic        v_sync,
    input  logic [ 7:0] ov7670_data,
    output logic        we,
    output logic [16:0] wAddr,
    output logic [15:0] wData
);

    logic [9:0] h_counter;
    logic [7:0] v_counter;
    logic [7:0] byte0, byte1;
    logic       byte_toggle;
    logic [15:0] pix_data_reg;
    logic [16:0] addr_reg;

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            h_counter     <= 0;
            v_counter     <= 0;
            byte0         <= 0;
            byte1         <= 0;
            byte_toggle   <= 0;
            we            <= 0;
            pix_data_reg  <= 0;
            addr_reg      <= 0;
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
                    addr_reg     <= v_counter * 160 + h_counter;
                    h_counter    <= h_counter + 1;
                    we    <= 1;
                end
                byte_toggle <= ~byte_toggle;

                if (h_counter == 319 && byte_toggle == 1) begin
                    h_counter <= 0;
                    if (v_counter < 239)
                        v_counter <= v_counter + 1;
                end
            end else begin
                h_counter   <= 0;
                byte_toggle <= 0;
            end
        end
    end

    assign wAddr = addr_reg;
    assign wData = pix_data_reg;

endmodule


// `timescale 1ns / 1ps

// module OV7670_MemController (
//     input  logic        pclk,
//     input  logic        reset,
//     input  logic        href,
//     input  logic        v_sync,
//     input  logic [ 7:0] ov7670_data,
//     output logic        we,
//     output logic [16:0] wAddr,
//     output logic [15:0] wData
// );
//     logic [ 9:0] h_counter;  // 320 * 2 = 640(320 pixel)
//     logic [ 7:0] v_counter;  // 240
//     logic [15:0] pix_data;

//     assign wAddr = v_counter * 160 + h_counter[9:1];
//     assign wData = pix_data;

//     always_ff @(posedge pclk, posedge reset) begin : h_sequence
//         if (reset) begin
//             pix_data  <= 0;
//             h_counter <= 0;
//             we        <= 0;
//         end else begin
//             if(href == 1'b0) begin
//                 h_counter <= 0;
//                 we        <= 0;
//             end
//             else begin
//                 h_counter <= h_counter + 1;
//                 if (h_counter[0] == 1'b0) begin  // even data
//                     pix_data[15:8] <= ov7670_data;
//                     we <= 1'b0;
//                 end else begin  // odd data
//                     pix_data[7:0] <= ov7670_data;
//                     we <= 1'b1;
//                 end
//             end
//         end
//     end

//     always_ff @(posedge pclk, posedge reset) begin : v_sequence
//         if (reset) begin
//             v_counter <= 0;
//         end else begin
//             if(v_sync) begin
//                 v_counter <= 0;
//             end
//             else begin
//                 if(h_counter == 639) begin
//                     v_counter <= v_counter + 1;
//                 end
//             end
//         end
//     end
// endmodule
