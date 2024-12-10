    module processor (
        input logic clk,
        input logic rst_n,
        input logic [7:0] read_val,
        input logic en,
        output logic [31:0] data_out,
        output logic data_out_valid
    );

    localparam byte opening[0:3] = "mul(";
    localparam byte closing = ")";
    localparam byte comma = ",";

    int index;
    int tens_index;
    logic [31:0] var1;
    logic [31:0] var2;

    typedef enum {
        MUL,
        VAR1,
        COM,
        VAR2,
        CLOSE
    } state_t;
    state_t state;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            index <= 0;
            state <= MUL;
        end else if(en) begin
            if(read_val == opening[0]) begin
                index <= 1;
                data_out_valid <= 0;
                state <= MUL;
            end else begin

            case(state)
            MUL: begin
                if (read_val == opening[index]) begin
                    index <= index + 1;
                end else index <= 0;
                if (index == 3) begin
                    state <= VAR1;
                    var1 <= 0;
                    var2 <= 0;
                end
            end
            VAR1: begin
                if (read_val >= "0" && read_val <= "9" ) begin
                    var1 <= var1 * 10 + (read_val - "0");
                end else if (read_val == comma) begin
                    state <= VAR2;
                end else begin
                    index <= 0;
                    state <= MUL;
                end
            end
            COM: begin
                if (read_val == comma) begin
                    state <= VAR2;
                end else begin
                    index <= 0;
                    state <= MUL;
                end
            end
            VAR2: begin
                if (read_val >= "0" && read_val <= "9" ) begin
                    var2 <= var2 * 10 + (read_val - "0");
                end else if (read_val == closing) begin
                    state <= CLOSE;
                    data_out <= var1 * var2;
                    data_out_valid <= 1;
                end else begin
                    index <= 0;
                    state <= MUL;
                end
            end
            CLOSE: begin
                index <= 0;
                data_out_valid <= 0;
                state <= MUL;
            end
            endcase
            end
        end
    end

    endmodule