module d4 (
    input logic clk,
    input logic rst_n,
    input logic [7:0] read_val,
    input logic read_val_valid,
    input logic read_val_done,
    output logic [63:0] output_data,
    output logic output_data_valid
);

//S  S  S
// A A A
//  MMM
//SAMXMAS
//  MMM
// A A A
//S  S  S

//X   X
//  A 
//X   X

wire [31:0] mem_addr[4:0];

assign mem_addr[0] = mem_addr[2] - 1 - 1*(1+width_counter);
assign mem_addr[1] = mem_addr[2] + 1 - 1*(1+width_counter);
//2
assign mem_addr[3] = mem_addr[2] - 1 + 1*(1+width_counter);
assign mem_addr[4] = mem_addr[2] + 1 + 1*(1+width_counter);


//S  S  S
// A A A
//  MMM
//SAMXMAS
//  MMM
// A A A
//S  S  S

logic [7:0] mem_read_val[4:0];

logic load_mode;
int in_counter;
int width_counter;
int row_counter;
int y;
int x;

genvar i;

generate

for (i = 0; i < 5; i = i + 1) begin
 memory #(.WIDTH(8), .SIZE(256*256))  mem (
    .clk(clk),
    .data_in(read_val),
    .addr(load_mode ? in_counter : mem_addr[i]),
    .we(load_mode ? read_val_valid : 0),
    .data_out(mem_read_val[i]));
end

endgenerate

//0 1
// 2
//3 4

wire left_cross = (mem_read_val[0] == "M" && mem_read_val[4] == "S") || (mem_read_val[4] == "M" && mem_read_val[0] == "S");
wire right_cross = (mem_read_val[1] == "M" && mem_read_val[3] == "S") || (mem_read_val[3] == "M" && mem_read_val[1] == "S");

//S  S  S
// A A A
//  MMM
//SAMXMAS
//  MMM
// A A A
//S  S  S

wire total_valid = left_cross && right_cross &&(mem_read_val[2] == "A");

assign mem_addr[2] = x+y*(width_counter+1);

typedef enum { 
    LOAD,
    PRELOAD,
    SCAN,
    DONE
 } state_t;
 state_t state;

 assign load_mode = (state == LOAD);

 always_ff @(posedge clk) begin
    if (!rst_n) begin
        state <= LOAD;
        in_counter <= 0;
        output_data_valid <= 0;
        width_counter <= 0;
        output_data <= 0;
        x <= 0;
        y <= 0;
    end else begin
        case (state)
            LOAD: begin
                if (read_val_valid) begin
                    in_counter <= in_counter + 1;
                    if(read_val == "\n") begin
                        row_counter <= row_counter + 1;
                        if (width_counter == 0) begin
                            width_counter <= in_counter;
                        end
                    end
                end
                if (read_val_done) begin
                    row_counter <= row_counter;;
                    state <= PRELOAD;
                end
            end
            PRELOAD: begin
                state <= SCAN;
            end
            SCAN: begin
                //loop through x and y
                if(x >= (width_counter-1)) begin
                    if(y >= row_counter) begin
                        state <= DONE;
                    end
                    x <= 0;
                    y <= y + 1;
                end else begin
                    x <= x + 1;
                end
                output_data <= output_data + total_valid;
            end
            DONE: begin
                output_data_valid <= 1;
            end
        endcase
    end
 end




endmodule