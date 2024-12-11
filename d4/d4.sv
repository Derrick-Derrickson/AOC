module d4 (
    input logic clk,
    input logic rst_n,
    input logic [7:0] read_val,
    input logic read_val_valid,
    input logic read_val_done,
    output logic [63:0] output_data,
    output logic output_data_valid
);

wire [31:0] mem_addr[24:0];
wire [7:0] correct_val[24:0];
assign mem_addr[0] = mem_addr[12] - 3 - 3*(1+width_counter);
assign mem_addr[1] = mem_addr[12] - 0 - 3*(1+width_counter);
assign mem_addr[2] = mem_addr[12] + 3 - 3*(1+width_counter);

assign mem_addr[3] = mem_addr[12] - 2 - 2*(1+width_counter);
assign mem_addr[4] = mem_addr[12] - 0 - 2*(1+width_counter);
assign mem_addr[5] = mem_addr[12] + 2 - 2*(1+width_counter);

assign mem_addr[6] = mem_addr[12] - 1 - 1*(1+width_counter);
assign mem_addr[7] = mem_addr[12] - 0 - 1*(1+width_counter);
assign mem_addr[8] = mem_addr[12] + 1 - 1*(1+width_counter);

assign mem_addr[9] = mem_addr[12] - 3 - 0*(1+width_counter);
assign mem_addr[10] = mem_addr[12] - 2 - 0*(1+width_counter);
assign mem_addr[11] = mem_addr[12] - 1 - 0*(1+width_counter);
//12!
assign mem_addr[13] = mem_addr[12] + 1 - 0*(1+width_counter);
assign mem_addr[14] = mem_addr[12] + 2 - 0*(1+width_counter);
assign mem_addr[15] = mem_addr[12] + 3 - 0*(1+width_counter);

assign mem_addr[16] = mem_addr[12] - 1 + 1*(1+width_counter);
assign mem_addr[17] = mem_addr[12] - 0 + 1*(1+width_counter);
assign mem_addr[18] = mem_addr[12] + 1 + 1*(1+width_counter);

assign mem_addr[19] = mem_addr[12] - 2 + 2*(1+width_counter);
assign mem_addr[20] = mem_addr[12] - 0 + 2*(1+width_counter);
assign mem_addr[21] = mem_addr[12] + 2 + 2*(1+width_counter);

assign mem_addr[22] = mem_addr[12] - 3 + 3*(1+width_counter);
assign mem_addr[23] = mem_addr[12] - 0 + 3*(1+width_counter);
assign mem_addr[24] = mem_addr[12] + 3 + 3*(1+width_counter);

assign correct_val[0] = "S";
assign correct_val[1] = "S";
assign correct_val[2] = "S";

assign correct_val[3] = "A";
assign correct_val[4] = "A";
assign correct_val[5] = "A";

assign correct_val[6] = "M";
assign correct_val[7] = "M";
assign correct_val[8] = "M";

assign correct_val[9] = "S";
assign correct_val[10] = "A";
assign correct_val[11] = "M";
assign correct_val[12] = "X";
assign correct_val[13] = "M";
assign correct_val[14] = "A";
assign correct_val[15] = "S";

assign correct_val[16] = "M";
assign correct_val[17] = "M";
assign correct_val[18] = "M";

assign correct_val[19] = "A";
assign correct_val[20] = "A";
assign correct_val[21] = "A";

assign correct_val[22] = "S";
assign correct_val[23] = "S";
assign correct_val[24] = "S";


//S  S  S
// A A A
//  MMM
//SAMXMAS
//  MMM
// A A A
//S  S  S

logic [7:0] mem_read_val[24:0];
wire cell_correct[24:0];

logic load_mode;
int in_counter;
int width_counter;
int row_counter;
int y;
int x;

genvar i;

generate

for (i = 0; i < 25; i = i + 1) begin
 memory #(.WIDTH(8), .SIZE(256*256))  mem (
    .clk(clk),
    .data_in(read_val),
    .addr(load_mode ? in_counter : mem_addr[i]),
    .we(load_mode ? read_val_valid : 0),
    .data_out(mem_read_val[i]));

assign cell_correct[i] = (mem_read_val[i] == correct_val[i]);
end

endgenerate

wire N_valid = (y >= 3);
wire E_valid = (x <= width_counter - 3);
wire S_valid = (y <= row_counter - 3);
wire W_valid = (x >= 3);

//S  S  S
// A A A
//  MMM
//SAMXMAS
//  MMM
// A A A
//S  S  S

wire NW = cell_correct[12] && cell_correct[0] && cell_correct[3] && cell_correct[6] && N_valid && W_valid;
wire N =  cell_correct[12] && cell_correct[1] && cell_correct[4] && cell_correct[7] && N_valid;
wire NE = cell_correct[12] && cell_correct[2] && cell_correct[5] && cell_correct[8] && N_valid && E_valid;
wire E =  cell_correct[12] && cell_correct[13] && cell_correct[14] && cell_correct[15] && E_valid;
wire SE = cell_correct[12] && cell_correct[18] && cell_correct[21] && cell_correct[24] && S_valid && E_valid;
wire S =  cell_correct[12] && cell_correct[17] && cell_correct[20] && cell_correct[23] && S_valid;
wire SW = cell_correct[12] && cell_correct[16] && cell_correct[19] && cell_correct[22] && S_valid && W_valid;
wire W =  cell_correct[12] && cell_correct[9] && cell_correct[10] && cell_correct[11] && W_valid;

wire [7:0] total_valid = N + NE + E + SE + S + SW + W + NW;

assign mem_addr[12] = x+y*(width_counter+1);

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