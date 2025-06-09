module vga_text (
    input  logic       clk,
    input  logic       reset,
    input  logic       DE1,
    input  logic       DE2,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       text_en_surv1,
    input  logic       text_en_surv2,
    input  logic       text_en_over1,
    input  logic       text_en_over2,
    output logic       text_pixel_score1,
    output logic       text_pixel_score2,
    output logic       text_pixel_result1,
    output logic       text_pixel_result2,
    input logic        sel_text1,
    input logic        sel_text2,

    // score play_fsm
    input logic [2:0] score1,
    input logic [2:0] score2
);

    logic [7:0] message_surv [0:6];
    logic [7:0] message_over [0:8];
    logic [7:0] message_score1[0:2];
    logic [7:0] message_score2[0:2];
    logic [5:0] asc_score1, asc_score2;
    logic text_pixel_surv1, text_pixel_over1;
    logic text_pixel_surv2, text_pixel_over2;

    assign text_pixel_result1 = sel_text1 ? text_pixel_surv1 : text_pixel_over1;
    assign text_pixel_result2 = sel_text2 ? text_pixel_surv2 : text_pixel_over2;
    assign asc_score1 = score1 + 8'h30;  
    assign asc_score2 = score2 + 8'h30;  

    // //score ascii
    // score_count U_SCORE_CNT ( 
    //     .clk       (clk),
    //     .reset     (reset),
    //     .asc_score (asc_score)
    // );

    //survive
    initial begin
        message_surv[0] = "S";
        message_surv[1] = "U";
        message_surv[2] = "R";
        message_surv[3] = "V";
        message_surv[4] = "I";
        message_surv[5] = "V";
        message_surv[6] = "E";
    end

    //game over
    initial begin
        message_over[0] = "G";
        message_over[1] = "A";
        message_over[2] = "M";
        message_over[3] = "E";
        message_over[4] = " ";
        message_over[5] = "O";
        message_over[6] = "V";
        message_over[7] = "E";
        message_over[8] = "R";
    end

    //score
    initial begin
        message_score1[1] <= "/";
        message_score1[2] <= "5"; 
    end
    
    //score
    initial begin
        message_score2[1] <= "/";
        message_score2[2] <= "5"; 
    end
    
    always_ff @( posedge clk, posedge reset ) begin
        if (reset) begin 
            message_score1[0] <= "0";
            message_score2[0] <= "0";
        end
        else begin
            message_score1[0] <= asc_score1; //현재 점수
            message_score2[0] <= asc_score2; //현재 점수
        end
    end

    //score 출력
    vga_text_renderer #(
        .X_START  (200),
        .Y_START  (50),
        .NUM_CHARS(3),
        .SCALE    (2)
    ) U_Textscore1 (
        .clk        (clk),
        .DE         (DE1),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .text_en    (1'b1),
        .message_ram(message_score1),
        .text_pixel (text_pixel_score1)
    );
    
    //score 출력
    vga_text_renderer #(
        .X_START  (520),
        .Y_START  (50),
        .NUM_CHARS(3),
        .SCALE    (2)
    ) U_Textscore2 (
        .clk        (clk),
        .DE         (DE2),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .text_en    (1'b1),
        .message_ram(message_score2),
        .text_pixel (text_pixel_score2)
    );

    //result - survive1
    vga_text_renderer #(
        .X_START  (104),
        .Y_START  (232),
        .NUM_CHARS(7),
        .SCALE    (2)
    ) U_TextSurvive1 (
        .clk        (clk),
        .DE         (DE1),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .text_en    (text_en_surv1),
        .message_ram(message_surv),
        .text_pixel (text_pixel_surv1)
    );

    //result - game over1
    vga_text_renderer #(
        .X_START  (88),
        .Y_START  (232),
        .NUM_CHARS(9),
        .SCALE    (2)
    ) U_TextOver1 (
        .clk        (clk),
        .DE         (DE1),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .text_en    (text_en_over1),
        .message_ram(message_over),
        .text_pixel (text_pixel_over1)
    );
    
    //result - survive2
    vga_text_renderer #(
        .X_START  (424),
        .Y_START  (232),
        .NUM_CHARS(7),
        .SCALE    (2)
    ) U_TextSurvive2 (
        .clk        (clk),
        .DE         (DE2),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .text_en    (text_en_surv2),
        .message_ram(message_surv),
        .text_pixel (text_pixel_surv2)
    );

    //result - game over2
    vga_text_renderer #(
        .X_START  (408),
        .Y_START  (232),
        .NUM_CHARS(9),
        .SCALE    (2)
    ) U_TextOver2 (
        .clk        (clk),
        .DE         (DE2),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .text_en    (text_en_over2),
        .message_ram(message_over),
        .text_pixel (text_pixel_over2)
    );


endmodule


module vga_text_renderer #(
    parameter int X_START   = 124,
    parameter int Y_START   = 240,
    parameter int NUM_CHARS = 9,
    parameter int SCALE     = 2
) (
    input  logic       clk,
    input  logic       DE,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       text_en,
    input  logic [7:0] message_ram[0:NUM_CHARS-1],
    output logic       text_pixel
);

    localparam int CHAR_WIDTH = 8 * SCALE;
    localparam int CHAR_HEIGHT = 8 * SCALE;

    // 폰트 ROM
    logic [7:0] font_rom[0:2047];  // 256 characters * 8 rows

    initial begin
        $readmemh("font8x8.mem", font_rom);
    end

    logic [ 4:0] char_col;
    logic [ 3:0] char_row;
    logic [ 7:0] char_ascii;
    logic [ 7:0] char_bitmap;
    logic [10:0] font_addr;

    assign char_col = (x_pixel - X_START) / CHAR_WIDTH;
    assign char_row = (y_pixel - Y_START) / CHAR_HEIGHT;

    always_comb begin
        text_pixel = 1'b0;

        if (text_en && 
            x_pixel >= X_START && x_pixel < X_START + NUM_CHARS * CHAR_WIDTH &&
            y_pixel >= Y_START && y_pixel < Y_START + CHAR_HEIGHT) begin

            char_ascii = message_ram[char_col];
            font_addr   = char_ascii * 8 + ((y_pixel - Y_START)/SCALE) % CHAR_HEIGHT;
            char_bitmap = font_rom[font_addr];

            if (char_bitmap[((x_pixel-X_START)/SCALE)%CHAR_WIDTH]) begin
                text_pixel = 1'b1;
            end
        end
    end

endmodule

module score_count ( //임의로 1초마다 카운트 +1 -> 신호로 바꿀 것 
    input  logic clk,
    input  logic reset,
    output logic [5:0] asc_score
);
    logic [2:0] score;
    logic [$clog2(1_0000_0000-1):0] cnt;

    assign asc_score = score + 8'h30;  

    always_ff @( posedge clk, posedge reset) begin 
        if (reset) begin
            cnt   <= 0;
            score <= 0;
        end
        else begin
            if (cnt <= 1_0000_0000 - 1) begin
                if (score == 7) score <= 0; 
                else            score <= score + 1;
                cnt <= 0;
            end
            else begin
                cnt <= cnt + 1;
            end
        end
    end

endmodule