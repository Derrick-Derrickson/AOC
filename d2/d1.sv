module d1 (
    input logic clk,
    input logic rst_n,
    input logic [31:0] data_stream1,
    input logic [31:0] data_stream2,
    input logic valid,
    input logic done,
    output logic [31:0] output_data,
    output logic output_valid
);

typedef enum { 
    IDLE,
    COLLECTING,
    SORTING,
    SUMMING,
    DONE
} state_t;

state_t state;
int input_count;

logic [31:0]  mem1_data_in;
logic [31:0]  mem1_data_out;
logic [31:0]  mem2_data_in;
logic [31:0]  mem2_data_out;
logic [31:0]  mem1_addr;
logic [31:0]  mem2_addr;
logic mem1_we;
logic mem2_we;


memory #(.WIDTH(32), .SIZE(2048)) mem1 (
    .clk(clk),
    .data_in(mem1_data_in),
    .addr(mem1_addr),
    .we(mem1_we),
    .data_out(mem1_data_out)
);

memory #(.WIDTH(32), .SIZE(2048)) mem2 (
    .clk(clk),
    .data_in(mem2_data_in),
    .addr(mem2_addr),
    .we(mem2_we),
    .data_out(mem2_data_out)
);

logic sort1_go;
logic sort1_done;
logic sort2_go;
logic sort2_done;
logic [31:0] sort1_addr;
logic [31:0] sort2_addr;
logic [31:0] sort1_data_in;
logic [31:0] sort2_data_in;
logic sort1_we;
logic sort2_we;

sorter sorter1 (
    .clk(clk),
    .reset(rst_n),
    .go(sort1_go),
    .done(sort1_done),
    .length(input_count),
    .addr(sort1_addr),
    .data_in(sort1_data_in),
    .data_out(mem1_data_out),
    .we(sort1_we)
);

sorter sorter2 (
    .clk(clk),
    .reset(rst_n),
    .go(sort2_go),
    .done(sort2_done),
    .length(input_count),
    .addr(sort2_addr),
    .data_in(sort2_data_in),
    .data_out(mem2_data_out),
    .we(sort2_we)
);

logic [31:0] summer_addr1;
logic [31:0] summer_addr2;
logic summer_go;
logic summer_done;
logic [31:0] summer_output;

summer summer1 (
    .clk(clk),
    .reset(rst_n),
    .go(summer_go),
    .done(summer_done),
    .length(input_count),
    .addr1(summer_addr1),
    .data1_out(mem1_data_out),
    .addr2(summer_addr2),
    .data2_out(mem2_data_out),
    .SUM(summer_output)
);

always_ff @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
        input_count <= 0;
        sort1_go <= 0;
        sort2_go <= 0;
        summer_go <= 0;
    end else begin

        case (state)
            IDLE: begin
                if (valid) begin
                    state <= COLLECTING;
                    input_count <= 1;
                    sort1_go <= 0;
                    sort2_go <= 0;
                    summer_go <= 0;
                end
            end
            COLLECTING: begin
                if (valid) begin
                    input_count <= input_count + 1;
                end
                if (done) begin
                    state <= SORTING;
                    sort1_go <= 1;
                    sort2_go <= 1;
                end
            end
            SORTING: begin
                sort1_go <= 0;
                sort2_go <= 0;
                if (sort1_done && sort2_done) begin
                    state <= SUMMING;
                    summer_go <= 1;
                end
            end
            SUMMING: begin
                summer_go <= 0;
                if (summer_done) begin
                    state <= DONE;
                    output_data <= summer_output;
                end
            end
            DONE: begin
                output_valid <= 1;
            end
        endcase

    end
end

always_comb begin : muxer
    case (state)
        IDLE: begin
            mem1_addr = input_count;
            mem1_data_in = data_stream1;
            mem1_we = valid;
            mem2_addr = input_count;
            mem2_data_in = data_stream2;
            mem2_we = valid;
        end
        COLLECTING: begin
            mem1_addr = input_count;
            mem1_data_in = data_stream1;
            mem1_we = valid;
            mem2_addr = input_count;
            mem2_data_in = data_stream2;
            mem2_we = valid;
        end
        SORTING: begin
            mem1_addr = sort1_addr;
            mem1_data_in = sort1_data_in;
            mem1_we = sort1_we;
            mem2_addr = sort2_addr;
            mem2_data_in = sort2_data_in;
            mem2_we = sort2_we;
        end
        SUMMING: begin
            mem1_addr = summer_addr1;
            mem1_data_in = 0;
            mem1_we = 0;
            mem2_addr = summer_addr2;
            mem2_data_in = 0;
            mem2_we = 0;
        end
        DONE: begin
            mem1_addr = 0;
            mem1_data_in = 0;
            mem1_we = 0;
            mem2_addr = 0;
            mem2_data_in = 0;
            mem2_we = 0;
        end
        default: begin
            mem1_addr = 0;
            mem1_data_in = 0;
            mem1_we = 0;
            mem2_addr = 0;
            mem2_data_in = 0;
            mem2_we = 0;
        end
    endcase
end

endmodule