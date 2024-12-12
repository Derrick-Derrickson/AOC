module d5 (
    input logic clk,
    input logic rst_n,
    input logic [7:0] read_val,
    input logic read_val_valid,
    input logic read_val_done,
    output logic [31:0] output_data,
    output logic output_data_valid
);

logic [7:0] rul_X[2047:0];
logic [7:0] rul_Y[2047:0];
logic [7:0] data;
logic newline;
logic active[2047:0];
logic [2047:0] rule_broken;
logic en;

wire any_broken = |rule_broken; //this is a cool operator

int rul_counter;

logic [512:0] mid_finder;
int data_counter;

genvar i;
generate
    for(i=0; i<1536; i=i+1) begin : rule_tester
        rule_tester rule_tester_inst (
            .clk(clk),
            .rst_n(rst_n),
            .en(en),
            .rul_X(rul_X[i]),
            .rul_Y(rul_Y[i]),
            .data(data),
            .newline(newline),
            .active(active[i]),
            .rule_broken(rule_broken[i])
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
                    if(newline) newline <= 1'b0;
                    if(en) en <= 1'b0;
                     if (read_val >= "0" && read_val <= "9") begin
                        if (en) data <= (read_val - "0");
                        else data <= data*10 + (read_val - "0");
                     end else if (read_val == ",") begin
                        mid_finder <= {mid_finder[(127-8):0], data};
                        data_counter <= data_counter + 1;
                        en <= 1;
                     end
                     else if (read_val == "\n") begin
                        if(!any_broken) begin
                            output_data <= output_data + middle_value;
                        end
                        mid_finder <= 0;
                        data_counter <= 0;
                        newline <= 1;
                        en <= 1;
                    end
                end
                if (read_val_done) begin
                    state <= DONE;
                    if(!any_broken) begin
                        output_data <= output_data + middle_value;
                    end
                end
            end

            DONE: begin
                output_data_valid <= 1;
            end
        endcase
    end
end





endmodule