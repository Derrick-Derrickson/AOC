module rule_tester (
    input logic clk,
    input logic rst_n,
    input logic en,
    input logic [7:0] rul_X,
    input logic [7:0] rul_Y,
    input logic [7:0] data,
    input logic newline,
    input logic active,
    output logic rule_broken
);
    reg Y_seen;
    reg X_seen;
    logic rule_broken_latch;
    assign rule_broken = rule_broken_latch || (Y_seen &&(data == rul_X));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n && active) begin
            rule_broken_latch <= 1'b0;
            Y_seen <=0;
            X_seen <=0;
        end else begin
            if(en) begin
                if(newline) begin
                    Y_seen <= 0;
                    X_seen <= 0;
                    rule_broken_latch <= 1'b0;
                end else if(!rule_broken_latch && !X_seen ) begin
                    if(data == rul_X) begin
                        X_seen <= 1;
                        if(Y_seen) begin
                            rule_broken_latch <= 1;
                        end
                    end
                    if(data == rul_Y) begin
                        Y_seen <= 1;
                    end
                end
            end
        
        end
    end

endmodule