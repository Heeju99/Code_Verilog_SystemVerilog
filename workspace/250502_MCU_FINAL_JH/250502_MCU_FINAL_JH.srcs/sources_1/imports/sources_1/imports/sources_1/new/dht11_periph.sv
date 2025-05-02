`timescale 1ns / 1ps



module DHT11_Periph (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // inport signals
    inout logic inoutPort
);

    logic trigger;     
    logic [39:0] tdata;
    logic done;
    

    APB_SlaveIntf_DHT11 U_APB_Intf_DHT11 (.*);

    tick_1us u_tick_1us(
    .clk(PCLK),
    .reset(PRESET),
    .tick(tick)    
);


    IOBUF uIO    
    (
    .I(data_out),
    .O(data_in),
    .IO(inoutPort),
    .T(data_t)
    );



sensor_cu u_sensor_cu (
    .clk(PCLK),
    .reset(PRESET),
    .tick(tick),
    .PADDR(PADDR),
    .PREADY(PREADY),
    .start_trigger(trigger),
    .data_in(data_in),
    .data_out(data_out),
    .data_t(data_t),
    .o_data(tdata),
    .finish_tick(done),
    .led(),
    .o_state(),
    .data_count()
);
endmodule





module APB_SlaveIntf_DHT11 (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    output logic trigger,      
    input  logic [39:0] tdata,
    input  logic done
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2;  //, slv_reg2, slv_reg3;
    logic [15:0] temp_data;
    assign temp_data = tdata[39:32]*100 + tdata[23:16];
    assign trigger = slv_reg0[0];
    assign slv_reg1[15:0] = temp_data;
    assign slv_reg2 = done;
 






    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            //slv_reg1 <= 0;
            // slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            // slv_reg0 <= 0;
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        // 2'd1: slv_reg1 <= PWDATA;
                        // 2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end


endmodule

module tick_1us (
    input  clk,
    input  reset,
    output tick
);

    parameter BAUD_RATE = 9600;
    localparam BAUD_COUNT = 100;
    reg [$clog2(BAUD_COUNT)-1:0] count_reg, count_next;

    reg tick_reg, tick_next;
    assign tick = tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset == 1) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end


    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1'b1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end

endmodule

module sensor_cu (
    input clk,
    input reset,
    input [3:0] PADDR,
    input PREADY,
    input tick,
    input start_trigger,
    input data_in,
    output data_out,
    output data_t,
    output start_tick,
    output [39:0] o_data,
    output finish_tick,
    output led,
    output [3:0] o_state,
    output reg [5:0] data_count
);

    parameter IDLE = 4'b0000, START = 4'b0001, WAIT = 4'b0010, WAIT2 = 4'b0011, WAIT3 = 4'b0100;
    parameter SYNC = 4'b0101, DATA = 4'b0110, PAR = 4'b0111, WAIT4 = 4'b1110,DATA2 = 4'b1111;
    reg [3:0] state, next;
    reg [15:0] tick_count, tick_count_next;
    reg data_reg, data_next;
    reg [39:0] o_data_reg, o_data_next;

    reg start_tick_reg, start_tick_next;
    reg finish_tick_reg, finish_tick_next;
    reg  [5:0]data_count_next;
    reg led_reg, led_next;
    reg io_state,io_state_next;
    reg [7:0] real_count, real_count_next;
    reg [18:0] return_count, return_count_next;
    assign data_out = data_reg;
    assign data_t = ~io_state;  // 1이면 입력모드, 0이면 출력모드 (IOBUF에서 1=High-Z)

    assign start_tick = start_tick_reg;
    assign finish_tick = finish_tick_reg;
    assign led = led_reg;
    assign o_state = state;
    assign o_data = o_data_reg;
    // out 3state on/off
    // assign data = (io_state) ? data_reg : 1'bz;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            tick_count <= 0;
            data_reg <= 1;
            start_tick_reg <= 0;
            finish_tick_reg <= 0;
            led_reg <= 0;
            io_state <= 0;
            o_data_reg <= 0;
            data_count <= 0;
            real_count <= 0;
            return_count <= 0;
        end else begin
            state <= next;
            tick_count <= tick_count_next;
            data_reg <= data_next;
            start_tick_reg <= start_tick_next;
            finish_tick_reg <= finish_tick_next;
            led_reg <= led_next;
            io_state <= io_state_next;
            o_data_reg <= o_data_next;
            data_count <= data_count_next;
            real_count <= real_count_next;
            return_count <= return_count_next;
        end
    end
  

    always @(*) begin
        next = state;
        data_next = data_reg;
        tick_count_next = tick_count;
        start_tick_next = start_tick_reg;
        finish_tick_next = finish_tick_reg;
        led_next = led_reg;
        io_state_next = io_state;
        o_data_next = o_data_reg;
        data_count_next = data_count;
        real_count_next = real_count;
        return_count_next = return_count;
        if(tick) begin
            return_count_next = return_count +1;
        end
        if(return_count == 100000)
        begin
            finish_tick_next = 1;
            return_count_next = 0;
            next = IDLE;
        end
        else begin
        case (state)

            IDLE: begin
                data_next = 1;
                io_state_next = 1;
                // if(PREADY && (PADDR[3:2] == 2'd2)) begin
                //     finish_tick_next = 0;
                // end
                if (start_trigger == 1 && PREADY && (PADDR[3:2] == 2'd0)) begin
                    next = START;
                    return_count_next = 0;
                    data_count_next = 0;
                    real_count_next = 0;
                    finish_tick_next = 0;
                    o_data_next = 0;
                end
            end
            START:
            if (tick == 1) begin
                data_next = 0;
                tick_count_next = tick_count + 1;
                if (tick_count_next == 18000) begin
                    next = WAIT;
            return_count_next = 0;

                    data_next = 1;
                    tick_count_next = 0;
                end
            end
            WAIT:
            if (tick == 1) begin
                tick_count_next = tick_count + 1;
                if (tick_count_next == 15) begin
                    next = WAIT2;
            return_count_next = 0;

                    tick_count_next = 0;
                    io_state_next = 0;
                end
            end
            WAIT2: begin
                if (tick == 1) begin
                    tick_count_next = tick_count + 1;
                    if(tick_count_next == 50) begin
                        tick_count_next = 0;
                    if (data_in ==1) begin
                    next = WAIT3;
            return_count_next = 0;

                    end
                    end
            
                end
            end
            WAIT3: begin
                if (data_in == 0) begin
                    next = SYNC;
            return_count_next = 0;

                end
            end

            SYNC: begin
                if (data_count == 40) begin
                    data_count_next =0;
            return_count_next = 0;

                    next = PAR;
                end
                else if (data_in == 1) begin
                    real_count_next = real_count +1;
                    if(real_count_next == 100) begin
                    next = DATA;
            return_count_next = 0;

                    tick_count_next = 0;
                    real_count_next = 0;
                    end

                end
            end
            DATA: begin
                if (data_in == 1) begin
                    if (tick == 1) begin
                        tick_count_next = tick_count + 1;
                         if (tick_count_next> 200) begin
                            tick_count_next =0;
                            next =IDLE;
                            return_count_next = 0;

                    end
                    end
                end else if (data_in == 0) begin
                              next =DATA2; 
                                return_count_next = 0;

                end
            end
            DATA2: begin
                  if (tick_count_next < 50) begin
                        next = SYNC;
                        return_count_next = 0;

                        o_data_next[39-data_count] = 0;
                           data_count_next = data_count +1;
                            tick_count_next = 0;
                    end
                    else begin
                         next = SYNC;
                        return_count_next = 0;

                        o_data_next[39-data_count] = 1;
                          data_count_next = data_count +1;
                        tick_count_next = 0;
                    end                  
            end
            
            PAR: begin
                io_state_next = 1;
                if(tick == 1) begin
                tick_count_next = tick_count +1;
                end
                if(tick_count_next == 50) begin
                    data_next =1;
                    if( o_data_reg[39:32] + o_data_reg[31:24] + o_data_reg[23:16] +o_data_reg[15:8] != o_data_reg[7:0])
                    begin
                        led_next = 1;
                        finish_tick_next = 1;
                    end
                    else begin
                        led_next = 0;
                        finish_tick_next = 1;
                    end
                    tick_count_next =0;
                    next = IDLE;
                    return_count_next = 0;

                end
            end


        endcase
        end
    end
endmodule