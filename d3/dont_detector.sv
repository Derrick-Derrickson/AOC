    module dont_det (
        input logic clk,
        input logic rst_n,
        input logic [7:0] read_val,
        input logic en,
        output logic detect
    );

    localparam byte phrase[0:6] = "don't()";

    int index;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            index <= 0;
        end else if(en) begin
            if (detect) detect <= 0;
            if(read_val == phrase[0]) begin
                index <= 1;
                detect <= 0;
            end else begin
                if (read_val == phrase[index]) begin
                    if (index == 6) begin
                        detect <= 1;
                    end else index <= index + 1;
                end else index <= 0;
            end
        end
    end
    endmodule