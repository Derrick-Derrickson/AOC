module d6 (
    input logic clk,
    input logic rst_n,
    input logic [7:0] read_val,
    input logic read_val_valid,
    input logic read_val_done,
    output logic [31:0] output_data,
    output logic output_data_valid
);

logic [31:0] map_data_in;
logic [31:0] map_addr; 
logic map_we;
logic [31:0] map_data_out;

logic [31:0] load_map_data_in;
logic [31:0] load_map_addr; 
logic load_map_we;

logic [31:0] visit_data_in;
logic [31:0] visit_addr;
logic visit_we;
logic [31:0] visit_data_out;

logic [31:0] run_map_addr; 

typedef enum {
    LOAD,
    LOAD_LAT,
    RUN,
    COUNT,
    DONE

} state_t;

always_comb begin : memory_mux
    if (state == LOAD || state == LOAD_LAT) begin
        map_data_in = load_map_data_in;
        map_addr = load_map_addr;
        map_we = load_map_we;
    end else if (state == RUN) begin
        map_data_in = 0;
        map_addr = run_map_addr;
        map_we = 0;
    end else begin
        map_data_in = 0;
        map_we = 0;
        map_addr = 0;
    end
end



memory #(8, 256*256) map (
    .clk(clk),
    .data_in(map_data_in),
    .addr(map_addr),
    .we(map_we),
    .data_out(map_data_out)
);

memory #(32, 256*256) visited_locations (
    .clk(clk),
    .data_in(visit_data_in),
    .addr(visit_addr),
    .we(visit_we),
    .data_out(visit_data_out)
);

state_t state;
int x;
int y;
int load_index;
int x_dim;
int y_dim;
int guard_x;
int guard_y;
reg [1:0] dir;
logic [7:0] obstruction_x;
logic [7:0] obstruction_y;

wire [1:0] next_dir = dir + (map_data_out || (obstruction_x == next_x && obstruction_y == next_y))? 1 : 0;
logic [31:0] next_x;
logic [31:0] next_y;
logic nex_is_oob;


assign run_map_addr = next_x*256 + next_y;

always_comb begin
    if((dir) == 0) begin
        next_x = guard_x;
        next_y = guard_y - 1;
    end else if((dir) == 1) begin
        next_x = guard_x + 1;
        next_y = guard_y;
    end else if((dir) == 2) begin
        next_x = guard_x;
        next_y = guard_y + 1;
    end else if((dir) == 3) begin
        next_x = guard_x - 1;
        next_y = guard_y;
    end else begin
        next_x = guard_x;
        next_y = guard_y;
    end
end

always_comb begin
    if(next_dir==0) begin
        nex_is_oob = (guard_y == 0);
    end else if(next_dir==1) begin
        nex_is_oob = (guard_x == x_dim);
    end else if(next_dir==2) begin
        nex_is_oob = (guard_y == y_dim);
    end else if(next_dir==3) begin
        nex_is_oob = (guard_x == 0);
    end else begin
        nex_is_oob = 1;
    end
end

always @(posedge clk) begin
    if(!rst_n) begin
        state <= LOAD;
        x <= 0;
        y <= 0;
        dir <= 0;
        guard_x <= 0;
        guard_y <= 0;
    end else begin
        case(state)
            LOAD: begin
                if(read_val_valid) begin
                    if(read_val == "\n") begin
                        if(x_dim == 0) begin
                            x_dim <= x-1;
                        end
                        x <= 0;
                        y <= y + 1;
                        load_map_we <= 0;
                    end else if(read_val == ".") begin
                        load_map_data_in <= 0;
                        load_map_addr <= x*256 + y;
                        load_map_we <= 1;
                        x <= x + 1;
                    end else if(read_val == "#") begin
                        load_map_data_in <= 1;
                        load_map_addr <= x*256 + y;
                        load_map_we <= 1;
                        x <= x + 1;
                    end else if(read_val == "^") begin
                        guard_x <= x;
                        guard_y <= y;
                        load_map_we <= 0;
                        x <= x + 1;
                    end
                end
                if(read_val_done) begin
                    load_map_we <= 0;
                    state <= LOAD_LAT;
                    load_index <= 0;
                    y_dim <= y;
                end
            end
            LOAD_LAT: begin
                state <= RUN;
            end
            RUN: begin
                visit_we <= 1;
                visit_data_in <= 1;
                if(nex_is_oob) begin
                    state <= COUNT;
                    output_data <=0;
                    x <=0;
                    y <=0;
                end
                    visit_addr <= guard_x*256 + guard_y;
                    if(dir == next_dir) begin
                        guard_x <= next_x;
                        guard_y <= next_y;
                    end
                    dir <= next_dir;
            end
            COUNT: begin
                visit_we <= 0;
                if(x==x_dim) begin
                    if(y==y_dim) begin
                        state <= DONE;
                    end else begin
                    x <= 0;
                    y <= y + 1;
                    end
                end else begin
                    x <= x + 1;
                end
                visit_addr <= x*256 + y;
                output_data <= output_data + visit_data_out;
            end
            DONE: begin
                output_data_valid <= 1;
            end

        endcase
    end
end

endmodule