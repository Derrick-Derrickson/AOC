module sorter (
    input logic clk,
    input logic rst_n,
    output logic [31:0] addr,
    output logic we,
    output logic [31:0] data_out,
    output logic rule_check_en,
    input logic [7:0] X_index[2047:0],
    input logic [7:0] Y_index[2047:0],
    input logic [7:0] rul_x[2047:0],
    input logic [7:0] rul_y[2047:0],
    input logic [2047:0] rule_broken,
    input logic [7:0] lengths[511:0],
    output logic newline,
    output logic done,
    input logic go,
    input logic [16:0] num_lines
);

function automatic int find_first_one(input logic [2047:0] vector);
    for (int i = 0; i < 2048; i++) begin
        if (vector[i] == 1) begin
            return i;
        end
    end
    return 0;
endfunction

int col;
int row;
wire [15:0] addr_scan = row * 32 + col;
int rul_index;
wire [7:0] current_length = lengths[row]; 

wire any_broken = |rule_broken; //this is a cool operator

logic compliant;
//the structure of this code:
//start with first line, stream it out to the rule checkers, If a rule is broken, swap the x and y values
//record if any swaps were made, if they were, do it again.
//if no swaps were made, move to the next line
//if all lines are sorted, set done to 1
//after each sorting attempt, we need to set newline as to reset the rule checkers

typedef enum {
    IDLE,
    RESET,
    RULE_CHECK,
    RUL_SWAPA,
    RUL_SWAPB,
    NEWLINE,
    DONE
} state_t;

state_t state;

always @(posedge clk) begin
    if(!rst_n) begin
        state <= IDLE;
        col <= 0;
        row <= 0;
        compliant <= 1;
        we <= 0;
        addr <= 0;
        data_out <= 0;
        newline <= 0;
        done <= 0;
    end else begin
        case(state)
            IDLE: begin
                if(go) begin
                    state <= RESET;
                    newline <= 1;
                end
            end
            RESET: begin
                state <= RULE_CHECK;
                    addr <= addr_scan;
                    compliant <= 1;
                    newline <= 0;
                    col <= col + 1;
            end
            RULE_CHECK: begin
                if(any_broken) begin
                    int rul_index_temp = find_first_one(rule_broken);
                    addr <= row*32 + Y_index[rul_index_temp];
                    data_out <= rul_x[rul_index_temp];
                    we <= 1;
                    state <= RUL_SWAPA;
                    rul_index <= rul_index_temp;
                    compliant <= 0;
                end else begin
                    //increment col, if col == length of line, increment row and reset col
                    if(col == current_length) begin
                        col <= 0;
                        if(compliant) begin
                            row <= row + 1;
                            if(row == num_lines) begin
                                state <= DONE;
                            end else begin
                            state <= NEWLINE;
                            newline <= 1;
                        end
                        end else begin
                            col <= 0;
                            state <= NEWLINE;
                            newline <= 1;
                            compliant <= 1;
                        end
                    end else begin
                        addr <= addr_scan;
                        col <= col + 1;
                        state <= RULE_CHECK;
                    end
                end
            end
            RUL_SWAPA: begin
                we <= 1;
                addr <= row*32 + X_index[rul_index];
                data_out <= rul_y[rul_index];
                state <= NEWLINE;
                compliant <= 1;
                col <= 0;
                newline <= 1;
            end
            RUL_SWAPB: begin //unused
                state <= NEWLINE;
                newline <= 1;
            end
            NEWLINE: begin
                we <= 0;
                state <= RULE_CHECK;
                addr <= addr_scan;
                newline <= 0;
                col <= col + 1;
            end
            DONE: begin
                state <= IDLE;
                done <= 1;
            end
        endcase

    end
end



endmodule