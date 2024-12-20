module rec_add_mul #(
    parameter DEPTH = 1
) (
    input logic clk,
    input logic rst_n,
    input logic [63:0] input_data[DEPTH-1:0],
    input logic [63:0] prev_step,
    input logic [DEPTH-1:0] enable,
    //answer logic
    input logic [63:0] answer,
    output logic [DEPTH-1:0] answer_valid
);
    logic [63:0] add_out;
    logic [63:0] mul_out;

generate
    //at the bottom of the recursion
    if(DEPTH == 1) begin

        assign answer_valid[0] = (add_out == answer) || (mul_out == answer);

        always_ff @(posedge clk) begin
            if(~rst_n) begin
                add_out <= 0;
                mul_out <= 0;
            end
            else if(enable[0]) begin
                add_out <= input_data[0] + prev_step;
                mul_out <= input_data[0] * prev_step;
            end
        end
    end else begin

        //recursively call the module, decrementing the depth
        
        always_ff @(posedge clk) begin
            if(~rst_n) begin
                add_out <= 0;
                mul_out <= 0;
            end
            else if(enable[0]) begin        
                    add_out <= input_data[0] + prev_step;
                    mul_out <= input_data[0] * prev_step;
            end
        end

        wire [DEPTH-2:0] add_ans;
        wire [DEPTH-2:0] mul_ans;
        assign answer_valid[0] = (add_out == answer) || (mul_out == answer);
        assign answer_valid[DEPTH-1:1] = add_ans | mul_ans;  

        rec_add_mul #(
            .DEPTH(DEPTH-1)
        ) rec_add_mul_inst(
            .clk(clk),
            .rst_n(rst_n),
            .input_data(input_data[DEPTH-1:1]),
            .enable(enable[DEPTH-1:1]),
            .prev_step(add_out),
            .answer(answer),
            .answer_valid(add_ans)
        );

        rec_add_mul #(
            .DEPTH(DEPTH-1)
        ) rec_mul_mul_inst(
            .clk(clk),
            .rst_n(rst_n),
            .input_data(input_data[DEPTH-1:1]),
            .enable(enable[DEPTH-1:1]),
            .prev_step(mul_out),
            .answer(answer),
            .answer_valid(mul_ans)
        );
    end
endgenerate
endmodule