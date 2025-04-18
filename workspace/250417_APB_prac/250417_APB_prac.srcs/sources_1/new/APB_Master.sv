module APB_Master(
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // Internal Interface Signals (from CPU)
    input  logic [31:0] addr,
    input  logic        wdata,
    output logic [31:0] rdata,
    input  logic        write, //1:write, 0:read
    input  logic        transfer, //trigger
    output logic        ready,
    // APB Interface Signals
    output logic        PWRITE,
    output logic [31:0] PADDR,
    output logic        PSEL1,
    output logic        PENABLE,
    output logic [31:0] PWDATA,
    input  logic [31:0] PRDATA1, //peripheral 개수 만큼 생김
    input  logic        PREADY1  //peripheral 개수 만큼 생김
    );

    logic [31:0]  temp_addr_reg,  temp_addr_next;
    logic [31:0]  temp_wdata_reg, temp_wdata_next;
    logic         temp_write_reg, temp_write_next;

    typedef enum bit [1:0] { IDLE, SETUP, ACCESS } apb_state_e;
    apb_state_e state, next;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if(PRESET) begin
            state <= IDLE;
            temp_addr_reg  = 0;
            temp_wdata_reg = 0;
            temp_write_reg = 0;
        end
        else begin
            state <= next;
            temp_addr_reg  = temp_addr_next;
            temp_wdata_reg = temp_wdata_next;
            temp_write_reg = temp_write_next;
        end
    end

    always_comb begin
        next = state;
        temp_addr_next  = temp_addr_reg;
        temp_wdata_next = temp_wdata_reg;
        temp_write_next = temp_write_reg;
            case(state)
                IDLE   : begin
                    PSEL1 = 1'b0;
                    if(transfer) begin
                        next = SETUP;
                        temp_addr_next = addr; // latching, ACCESS에서 값 유지하는 동안 다른 값 못들어오게
                        temp_wdata_next = wdata;
                        temp_write_next = write;
                    end
                end
                SETUP  : begin
                    PADDR   = temp_addr_reg;  //얘 때문에
                    PENABLE = 1'b0;
                    if(temp_write_reg) begin   // write mode
                        PWRITE = 1'b1;
                        PWDATA = temp_wdata_reg; 
                    end else begin    // read mode
                        PWRITE = 1'b0;
                    end         
                    next = ACCESS;
                end
                ACCESS : begin
                    PADDR   = temp_addr_reg;  
                    PENABLE = 1'b1;            // 얘만 변화
                    if(temp_write_reg) begin   // 기존값 유지
                        PWRITE = 1'b1;
                        PWDATA = temp_wdata_reg; 
                    end else begin    // read mode
                        PWRITE = 1'b0;
                    end  
                    if(PREADY1) next = IDLE;
                    else next = ACCESS; 
                end
            endcase
    end

endmodule