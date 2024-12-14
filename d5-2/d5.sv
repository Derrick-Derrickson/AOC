module d5 (
    input logic clk,
    input logic rst_n,
    input logic [7:0] read_val,
    input logic read_val_valid,
    input logic read_val_done,
    output logic [31:0] output_data,
    output logic [31:0] p1_score,
    output logic output_data_valid
);

logic [7:0] rul_X[2047:0];
logic [7:0] rul_Y[2047:0];
logic [7:0] X_index[2047:0];
logic [7:0] Y_index[2047:0];
logic [7:0] data;
logic newline;
logic [2047:0] active;
logic [2047:0] rule_broken;
logic en;
logic mem_save_we;

logic [511:0] wrong_strings;
logic [7:0] data_lengths[511:0];

wire any_broken = |rule_broken; //this is a cool operator

int rul_counter;

logic [512:0] mid_finder;
int data_counter;
int row_counter;

logic memory_we;
logic [31:0] memory_addr;
logic [7:0] memory_data_out;
logic [7:0] memory_data_in;

logic [7:0] rul_check_data;
logic rul_check_en;
logic rul_check_newline;
logic sort_done;
logic sort_go;

logic sorter_we;
logic [31:0] sorter_addr;
logic [7:0] sorter_data_out;
logic [7:0] sorter_data_in;
logic sorter_newline;
logic sorter_en;


memory #(8, 32*256) mem (
    .clk(clk),
    .data_in(memory_data_in),
    .addr(memory_addr),
    .we(memory_we),
    .data_out(memory_data_out)
);

sorter sorter_inst (
    .clk(clk),
    .rst_n(rst_n),
    .addr(sorter_addr),
    .we(sorter_we),
    .data_out(sorter_data_out),
    .rule_check_en(sorter_en),
    .X_index(X_index),
    .Y_index(Y_index),
    .rul_x(rul_X),
    .rul_y(rul_Y),
    .rule_broken(rule_broken),
    .lengths(data_lengths),
    .newline(sorter_newline),
    .done(sort_done),
    .go(sort_go),
    .num_lines(row_counter)
);

int sum_loc;
int sum_row_counter;


always_comb begin
    if(state == RUL_READ) begin
        memory_we = 0;
        memory_data_in = 0;
        memory_addr = 0;
        rul_check_data = data;
        rul_check_en = 0;
        rul_check_newline = 0;
    end
    else if(state == DATA_READ || state == FINISH_WRITE) begin
        memory_we = en;
        memory_data_in = data;
        memory_addr = row_counter*32 + data_counter;
        rul_check_data = data;
        rul_check_en = en;
        rul_check_newline = newline;
    end
    else if(state == SORT_BAD) begin
        memory_we = sorter_we;
        memory_data_in = sorter_data_out;
        memory_addr = sorter_addr;
        rul_check_data = memory_data_out;
        rul_check_en = 1;
        rul_check_newline = sorter_newline;
    end
    else if(state == SUM_BAD) begin
        memory_we = 0;
        memory_data_in = 0;
        memory_addr = sum_loc;
        rul_check_data = 0;
        rul_check_en = 0;
        rul_check_newline = 0;
    end
    else if(state == DONE) begin
        memory_we = 0;
        memory_data_in = 0;
        memory_addr = 0;
        rul_check_data = 0;
        rul_check_en = 0;
        rul_check_newline = 0;
    end else begin
        memory_we = 0;
        memory_data_in = 0;
        memory_addr = 0;
        rul_check_data = 0;
        rul_check_en = 0;
        rul_check_newline = 0;
    end
end

genvar i;
//set all data lengths to 0

generate
    for(i=0; i<512; i=i+1) begin : data_length_setter
        always_ff @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                data_lengths[i] <= 0;
            end
        end
    end
endgenerate


generate
    for(i=0; i<1500; i=i+1) begin : rule_tester
        rule_tester rule_tester_inst (
            .clk(clk),
            .rst_n(rst_n),
            .en(rul_check_en),
            .rul_X(rul_X[i]),
            .rul_Y(rul_Y[i]),
            .data(rul_check_data),
            .newline(rul_check_newline),
            .active(active[i]),
            .rule_broken(rule_broken[i]),
            .X_index(X_index[i]),
            .Y_index(Y_index[i])
        );
        always_ff @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                rul_X[i] <= 8'h00;
                rul_Y[i] <= 8'h00;
                active[i] <= 1'b0;
            end
    end
end
endgenerate

typedef enum { 
    RUL_READ,
    DATA_READ,
    FINISH_WRITE,
    SORT_BAD,
    SUM_BAD,
    DONE
 } state_t;

state_t state;
reg xy;
reg first_symbol;


wire [7:0] middle_value = {mid_finder[(512-8):0], data}[((data_counter)*4) +: 8];

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= RUL_READ;
        newline <= 1'b0;
        en <= 1'b0;
        rul_counter <= 0;
        xy <= 1'b0;
        first_symbol <= 1'b1;
        mid_finder <= 0;
        data_counter <= 0;
        row_counter <= 0;
        wrong_strings <= 0;
        sum_loc <= 0;
        sum_row_counter <= 0;
        
    end else begin
        case(state)
            RUL_READ: begin

                if(read_val_valid) begin
                    if (read_val >= "0" && read_val <= "9") begin
                        if(!xy) begin
                            if(first_symbol) begin
                                rul_X[rul_counter] <= (read_val - "0");
                                first_symbol <= 0;
                            end
                            else rul_X[rul_counter] <= rul_X[rul_counter]*10 + (read_val - "0");
                        end else begin
                            if(first_symbol) begin 
                                rul_Y[rul_counter] <= (read_val - "0");
                                first_symbol <= 0;
                            end
                            else rul_Y[rul_counter] <= rul_Y[rul_counter]*10 + (read_val - "0");
                        end
                    end else if (read_val == "|") xy <= 1;
                    else if (read_val == "\n") begin
                        if(xy) begin
                            rul_counter <= rul_counter + 1;
                            xy <= 0;
                            active[rul_counter] <= 1'b1;
                            first_symbol <= 1'b1;
                        end else begin
                            state <= DATA_READ;
                        end
                    end
                end
            end

            DATA_READ: begin
                if(read_val_valid) begin
                    if(newline) begin
                        newline <= 1'b0;
                        row_counter <= row_counter + 1;
                        data_counter <= 0;
                        en <= 1'b0;
                    end
                    if(en && !newline) begin
                        en <= 1'b0;
                        data_counter <= data_counter + 1;
                    end
                     if (read_val >= "0" && read_val <= "9") begin
                        if (en) data <= (read_val - "0");
                        else data <= data*10 + (read_val - "0");
                     end else if (read_val == ",") begin
                        mid_finder <= {mid_finder[(127-8):0], data};
                        en <= 1;
                     end
                     else if (read_val == "\n") begin
                        if(any_broken) begin
                            wrong_strings[row_counter] <= 1;
                        end
                        mid_finder <= 0;
                        newline <= 1;
                        en <= 1;
                        data_lengths[row_counter] <= data_counter+1;
                    end
                end
                if (read_val_done) begin
                    state <= FINISH_WRITE;
                    sort_go <= 1;
                    newline <= 1;
                    if(any_broken) begin
                        wrong_strings[row_counter] <= 1;
                    end
                    data_lengths[row_counter] <= data_counter+1;
                    en <= 1;
                end
            end

            FINISH_WRITE:begin
                state <= SORT_BAD;
                en <= 0;
            end

            SORT_BAD: begin
                en <= 0;
                sort_go <= 0;
                newline <= 0;
                //wait for the sort done signal
                if(sort_done) begin
                    state <= SUM_BAD;
                    sum_loc <= ((data_lengths[0])>>1);
                    sum_row_counter <= 0;
                    output_data <= 0;
                    p1_score <= 0;
                end
            end

            SUM_BAD: begin
                if(wrong_strings[sum_row_counter]) begin
                    output_data <= output_data + memory_data_out;
                end else begin
                    p1_score <= p1_score + memory_data_out;
                end

                sum_loc <= (sum_row_counter+1)*32 + ((data_lengths[sum_row_counter+1])>>1);

                if(sum_row_counter == row_counter) begin
                    state <= DONE;
                end else begin
                    sum_row_counter <= sum_row_counter + 1;
                end
            end

            DONE: begin
                output_data_valid <= 1;
            end
        endcase
    end
end





endmodule