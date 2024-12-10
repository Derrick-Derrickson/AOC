    module processor_skippy #(
        parameter SKIP_INDEX = 0
    ) (
        input logic clk,
        input logic rst_n,
        input logic [7:0] read_val,
        input logic en_processor,
        input logic newline,
        output logic is_safe
    );
        
    typedef enum {
        FIRST,
        FIRSTNT,
        SECOND,
        ASSENDING,
        DESCENDING,
        UNSAFE,
        DONE
    } state_t;
    byte prev_val;
    state_t state;
    byte index;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            index <= 0;
        end else if (en_processor) begin
            if (newline) index <= 0;
            else index <= index + 1;
        end
    end

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state <= FIRST;
            prev_val <= 0;
            is_safe <= 0;
        end
        else if (en_processor && (index != SKIP_INDEX)) begin
            case (state)
                FIRST: begin
                    if(is_safe) is_safe <= 0;
                    prev_val <= read_val;
                    state <= SECOND;
                end
                SECOND: begin

                    if (read_val < prev_val) begin
                        if ((prev_val - read_val >= 1) && (prev_val - read_val <= 3)) begin
                            state <= DESCENDING;
                            prev_val <= read_val;
                        end
                        else begin
                            state <= UNSAFE;

                        end
                    end
                    else if (read_val > prev_val) begin
                        if ((read_val - prev_val >= 1) && (read_val - prev_val <= 3)) begin
                            state <= ASSENDING;
                            prev_val <= read_val;
                        end
                        else begin
                                state <= UNSAFE;

                        end
                    end
                    else begin
                            state <= UNSAFE;

                    end
                end
                ASSENDING: begin
                    if (!((read_val > prev_val && (read_val-prev_val) <= 3))) begin
                            if(newline) state <= FIRST;
                            else state <= UNSAFE;

                        end
                        else if (newline) begin
                            state <= FIRST;
                            is_safe <= 1;
                    end else begin
                        prev_val <= read_val;
                    end
                end
                DESCENDING: begin
                    if (!((read_val < prev_val && (prev_val-read_val) <= 3))) begin
                        if(newline) state <= FIRST;
                            else state <= UNSAFE;
                        end
                        else if (newline) begin
                            state <= FIRST;
                            is_safe <= 1;
                    end else begin
                        prev_val <= read_val;
                    end
                end
                UNSAFE: begin
                    if(newline) begin
                        state <= FIRST;
                    end
                end
            endcase
        end else if (en_processor && (index == SKIP_INDEX)) begin
            if(newline && state != UNSAFE) begin
                state <= FIRST;
                is_safe <= 1;
            end else if (newline && state == UNSAFE) begin
                state <= FIRST;
                is_safe <= 0;
            end
        end
    end




    endmodule