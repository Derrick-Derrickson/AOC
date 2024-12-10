//low latency memory, single cycle read, single cycle write

module memory #(parameter WIDTH = 8, parameter SIZE = 256) (
    input logic clk,
    input logic [WIDTH-1:0] data_in,
    input logic [31:0] addr,
    input logic we,
    output logic [WIDTH-1:0] data_out
);

    logic [WIDTH-1:0] mem [SIZE-1:0];

    always_ff @(posedge clk) begin
        if (we) begin
            mem[addr] <= data_in;
        end
    end

    assign data_out = mem[addr];

endmodule