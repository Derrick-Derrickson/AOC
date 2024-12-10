module d3 (
    input logic clk,
    input logic rst_n,
    input logic [7:0] read_val,
    input logic read_val_valid,
    input logic read_val_done,
    output logic [63:0] output_data,
    output logic output_data_valid
);

    logic [63:0] total_data;
    logic [31:0] processor_data;
    logic processor_data_valid;
    logic delayed_data_valid;
    logic do_detected;
    logic dont_detected;
    logic add_enabled;

    do_det do_detector (
        .clk(clk),
        .rst_n(rst_n),
        .read_val(read_val),
        .en(read_val_valid),
        .detect(do_detected)
    );

    dont_det dont_detector (
        .clk(clk),
        .rst_n(rst_n),
        .read_val(read_val),
        .en(read_val_valid),
        .detect(dont_detected)
    );

    processor processor (
        .clk(clk),
        .rst_n(rst_n),
        .read_val(read_val),
        .en(read_val_valid),
        .data_out(processor_data),
        .data_out_valid(processor_data_valid)
    );

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            add_enabled <= 1;
        end else if (do_detected) begin
            add_enabled <= 1;
        end else if (dont_detected) begin
            add_enabled <= 0;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            total_data <= 0;
            add_enabled <= 1;
        end else if (processor_data_valid && add_enabled) begin
            total_data <= total_data + processor_data;
        end else if (read_val_done) begin
            output_data <= total_data;
            output_data_valid <= 1;
        end
    end

endmodule