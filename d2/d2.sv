module d2 (
    input logic clk,
    input logic rst_n,
    input logic [7:0] byte_in,
    input logic byte_in_valid,
    input logic bytes_done,
    output logic [15:0] num_safe,
    output logic [15:0] num_unsafe,
    output logic nums_valid,
    output logic [31:0] index,
    output logic pass_fail,
    output logic pf_valid
);

logic [7:0] read_val;
logic en_processor;
logic newline;
logic is_safe_skippy;
logic is_unsafe_skippy;
logic [7:0] is_safe;

genvar i;
generate
    for(i = 0; i < 8; i = i + 1) begin : processor_skippy
        processor_skippy #(
            .SKIP_INDEX(i)
        ) processor_skippy (
            .clk(clk),
            .rst_n(rst_n),
            .read_val(read_val),
            .en_processor(en_processor),
            .newline(newline),
            .is_safe(is_safe[i])
        );
    end
endgenerate


reg delayed_newline;

always_ff @(posedge clk) begin
    if(delayed_newline) begin
        index <= index + 1;
        if(is_safe != 0) begin
            pass_fail <= 1;
            pf_valid <= 1;
            num_safe <= num_safe + 1;
        end else begin
             num_unsafe <= num_unsafe + 1;
             pass_fail <= 0;
        end
    end
    if (pf_valid) pf_valid <= 0;
end


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            read_val <= 0;
            en_processor <= 0;
            index <= 0;
            pf_valid <= 0;
        end
        else if (!nums_valid && (byte_in_valid || bytes_done)) begin
            if (byte_in == " " && !bytes_done) begin
                en_processor <= 1;
            end
            else if (byte_in >= "0" && byte_in <= "9"  && !bytes_done) begin
                if(en_processor) read_val <= (byte_in - "0");
                else read_val <= read_val*10 + (byte_in - "0");
            end
            else if (byte_in == "\n" || bytes_done) begin
                newline <= 1;
                en_processor <= 1;
            end
            if (delayed_newline && bytes_done) begin
                nums_valid <= 1;
                newline <= 0;
            end
            else if (newline) newline <= 0;
            if (en_processor) en_processor <= 0;
        end
        delayed_newline <= newline;
    end
endmodule