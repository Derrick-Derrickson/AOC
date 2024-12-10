    module processor (
        input logic clk,
        input logic rst_n,
        input logic [7:0] read_val,
        input logic en_processor,
        input logic newline,
        output logic is_safe,
        output logic is_unsafe
    );
        
    typedef enum {
        FIRST,
        SECOND,
        ASSENDING,
        DESCENDING,
        UNSAFE,
        DONE
    } state_t;
    byte prev_val;
    reg damp;
    state_t state;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state <= FIRST;
            prev_val <= 0;
            is_safe <= 0;
            is_unsafe <= 0;
            damp <=0;
        end
        else if (en_processor) begin
            case (state)
                FIRST: begin
                    if(is_safe) is_safe <= 0;
                    if(is_unsafe) is_unsafe <= 0;
                    prev_val <= read_val;
                    state <= SECOND;
                    damp <=0;
                end
                SECOND: begin
                    if (read_val < prev_val) begin
                        if ((prev_val - read_val >= 1) && (prev_val - read_val <= 3)) begin
                            state <= DESCENDING;
                            prev_val <= read_val;
                        end
                        else begin
                            if(damp) begin
                            state <= UNSAFE;
                            is_unsafe <= 1;
                            end
                            else begin
                                damp <= 1;
                            end
                        end
                    end
                    else if (read_val > prev_val) begin
                        if ((read_val - prev_val >= 1) && (read_val - prev_val <= 3)) begin
                            state <= ASSENDING;
                            prev_val <= read_val;
                        end
                        else begin
                            if(damp) begin
                                state <= UNSAFE;
                                is_unsafe <= 1;
                            end
                            else begin
                                damp <= 1;
                            end
                        end
                    end
                    else begin
                        if(damp) begin
                            state <= UNSAFE;
                            is_unsafe <= 1;
                        end
                            else begin
                                damp <= 1;
                            end
                    end
                end
                ASSENDING: begin
                    if (!((read_val > prev_val && (read_val-prev_val) <= 3))) begin
                        if(!damp) begin
                            damp <= 1;
                            if (newline) begin
                                state <= FIRST;
                                is_safe <= 1;
                            end
                        end else begin
                            if (newline) state <= FIRST;
                            else state <= UNSAFE;
                            is_unsafe <= 1;
                        end
                    end else if (newline) begin
                        state <= FIRST;
                        is_safe <= 1;
                    end else begin
                        prev_val <= read_val;
                    end
                end
                DESCENDING: begin
                    if (!((read_val < prev_val && (prev_val-read_val) <= 3))) begin
                        if(!damp) begin
                            damp <= 1;
                            if (newline) begin
                                state <= FIRST;
                                is_safe <= 1;
                            end
                        end else begin
                            if (newline) state <= FIRST;
                            else state <= UNSAFE;
                            is_unsafe <= 1;
                        end
                    end else if (newline) begin
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
        end
    end




    endmodule