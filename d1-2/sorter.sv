module sorter (
    input logic clk,
    input logic reset,
    input logic go,
    output logic done,
    input [15:0] length,
    //
    output logic [31:0] addr,
    output logic [31:0] data_in,
    input logic [31:0] data_out,
    output logic we
);

typedef enum { 
    IDLE,
    COMPARE_START,
    COMPARE,
    SWAPA,
    SWAPB,
    DONE
} state_t;

state_t state;

logic [31:0]  A;
logic [31:0]  B;
int loc_count;
reg clean;

always_ff @(posedge clk) begin
    if (!reset) begin
        state <= IDLE;
        loc_count <= 0;
        done <= 0;
        clean <= 1;
    end else begin

        case (state)
            IDLE: begin
                if (go) begin
                    state <= COMPARE_START;
                    addr <= 0;
                    done <= 0;
                    clean <= 1;
                end
            end
            COMPARE_START: begin
                state <= COMPARE;
                A <= data_out;
                addr <= addr + 1;
            end
            COMPARE: begin
                if (addr >= length) begin
                    if (clean) state <= DONE;
                    else begin
                        state <= COMPARE_START;
                        addr <= 0;
                        clean <= 1;
                    end
                    end else if (A > data_out) begin
                        state <= SWAPA;
                        we <= 1;
                        data_in <= A;
                        B <= data_out;
                        clean <= 0;
                end else begin
                    A <= data_out;
                    addr <= addr + 1;
                end
            end
            SWAPA: begin
                state <= SWAPB;
                we <= 1;
                data_in <= B;
                addr <= addr - 1;
            end
            SWAPB: begin
                addr <= addr+2;
                //A <= B;
                we <= 0;
                state <= COMPARE;
            end
            DONE: begin
                state <= IDLE;
                done <= 1;
            end
        endcase
    end
end



endmodule