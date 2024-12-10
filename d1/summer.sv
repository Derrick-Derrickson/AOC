module summer (
    input logic clk,
    input logic reset,
    input logic go,
    output logic done,
    input [15:0] length,
    //
    output logic [31:0] addr1,
    input logic [31:0] data1_out,
    //
    output logic [31:0] addr2,
    input logic [31:0] data2_out,
    //
    output logic [31:0] SUM
);

typedef enum { 
    IDLE,
    SUMMING,
    DONE
} state_t;

state_t state;

always_ff @(posedge clk) begin
    if (!reset) begin
        state <= IDLE;
        SUM <= 0;
    end else begin

        case (state)
            IDLE: begin
                if (go) begin
                    state <= SUMMING;
                    addr1 <= 0;
                    addr2 <= 0;
                end
            end
            SUMMING: begin
                if(data1_out > data2_out) SUM <= SUM + data1_out - data2_out;
                else SUM <= SUM + data2_out - data1_out;
                addr1 <= addr1 + 1;
                addr2 <= addr2 + 1;
                if (addr1 == length) begin
                    state <= DONE;
                end
            end
            DONE: begin
                done <= 1;
            end
        endcase
    end
end


endmodule