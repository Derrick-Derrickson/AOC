module d7 (
    input logic clk,
    input logic rst_n,
    input logic [7:0] read_val,
    input logic read_val_valid,
    input logic read_val_done,
    output logic [63:0] output_data,
    output logic output_data_valid
);
    parameter DEPTH = 11;//11;

    logic [63:0] postulate;
    logic [63:0] input_data[DEPTH:0];
    int data_counter;
    reg first_symbol;
    reg donez;
    int ans_index;
    reg test_ans;
    logic [63:0] temp_postulate;
    logic [DEPTH-1:0] enable;

    logic [DEPTH-1:0] answer_valid;

    //rec_add_mul
    rec_add_mul #(
        .DEPTH(DEPTH)
    ) rec_add_mul_inst(
        .clk(clk),
        .rst_n(rst_n),
        .input_data(input_data[DEPTH:1]),
        .prev_step(input_data[0]),
        .enable(enable),
        .answer(postulate),
        .answer_valid(answer_valid)
    );

    //4 MEMORIES, 1 for the postulate, 1 for the data, 1 for the answer, 1 for the data length
    //1 for the postulate
    //1 for the data
    //1 for the answer
    //1 for the data length
    m

    typedef enum { 
        POS_READ,
        SPACE,
        DATA_READ,
        ANS_LAT,
        DONE
     } state_t;
    state_t state;


    always_ff@(posedge clk) begin
        if(!rst_n) begin
            postulate <= 0;
            data_counter <= 0;
            first_symbol <= 0;
            state <= POS_READ;
            donez <= 0;
            ans_index <= 0;
            enable <= 1;
        end
        else begin
            case(state)
                POS_READ: begin
                    if(read_val_valid) begin
                    if (read_val >= "0" && read_val <= "9") begin
                            if(first_symbol) begin
                                postulate <= (read_val - "0");
                                first_symbol <= 0;
                            end
                            else postulate <= postulate*10 + (read_val - "0");
                        end else if(read_val == ":") begin
                                first_symbol <= 1;
                                state <= SPACE;
                            end 
                        end
                end

                SPACE: begin
                    if(read_val == " ") begin
                        state <= DATA_READ;
                    end
                end

                DATA_READ: begin
                    if(read_val_valid) begin
                        if (read_val >= "0" && read_val <= "9") begin
                            if(first_symbol) begin
                                input_data[data_counter] <= (read_val - "0");
                                first_symbol <= 0;
                            end
                            else input_data[data_counter] <= input_data[data_counter]*10 + (read_val - "0");
                        end else if(read_val == " ") begin
                                first_symbol <= 1;
                                data_counter <= data_counter + 1;
                                enable[data_counter+1] <= 1;
                        end else if(read_val == "\n") begin
                                enable[data_counter+1] <= 1;
                                state <= POS_READ;
                                first_symbol <= 1;
                                data_counter <= 0;
                                ans_index <= data_counter;
                                test_ans <= 1;
                                temp_postulate <= postulate;
                        end
                    end
                    if(read_val_done) begin
                        donez <= 1;
                        enable <= 1;
                        state <= ANS_LAT;
                        ans_index <= data_counter;
                        test_ans <= 1;
                        temp_postulate <= postulate;
                    end
                end

                ANS_LAT: begin
                    state <= DONE;
                end

                DONE: begin
                    state <= DONE;
                    output_data_valid <= 1;
                end

            endcase
            //test the ans
            if(test_ans) begin
                test_ans <= 0;
                enable <= 1;
                if(answer_valid[ans_index-1]) begin
                    output_data <= output_data + temp_postulate;
                end
            end
        end
    end






endmodule