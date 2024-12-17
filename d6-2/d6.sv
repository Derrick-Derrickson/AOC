module d6 (
    input logic clk,
    input logic rst_n,
    input logic [7:0] read_val,
    input logic read_val_valid,
    input logic read_val_done,
    output logic [31:0] output_data,
    output logic output_data_valid,
    output logic [31:0] current_index,
    output logic current_index_valid
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

logic rw;

typedef enum {
    LOAD,
    LOAD_LAT,
    DRY_RUN,
    COUNT_OBS,
    OBS_LAT,
    OBS_LOAD,
    RUN,
    COUNT,
    DONE

} state_t;

always_comb begin : memory_mux
    if (state == LOAD || state == LOAD_LAT) begin
        map_data_in = load_map_data_in;
        map_addr = load_map_addr;
        map_we = load_map_we;
    end else if (state == RUN || state==DRY_RUN) begin
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

logic [15:0] obs_data_in;
logic [31:0] obs_addr;
logic obs_we;
logic [15:0] obs_data_out;
int obs_index;
int num_of_obs;


memory #(16, 256*256) obstruction (
    .clk(clk),
    .data_in(obs_data_in),
    .addr(obs_addr),
    .we(obs_we),
    .data_out(obs_data_out)
);

memory #(32, 512*512) visited_locations (
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
int guard_init_x;
int guard_init_y;
reg [1:0] dir;
logic [7:0] obstruction_x;
logic [7:0] obstruction_y;
wire obs = (map_data_out || (obstruction_x == next_x && obstruction_y == next_y));

wire [1:0] next_dir = dir + (obs? 1 : 0);
logic [7:0] next_x;
logic [7:0] next_y;
logic nex_is_oob;

logic [31:0] loops_found;
logic [31:0] visit_vector;

assign run_map_addr = next_x*256 + next_y;
wire loop_detect = vis_vec_samesies && (visit_data_out != 0) && (guard_x != guard_init_x && guard_y != guard_init_y);

wire [3:0] dir_one_hot = (4'b0001 << (dir[1:0]));

logic vis_vec_samesies;

wire [3:0] other_dirs = ((visit_data_out[23:16] == obstruction_y[7:0]) && (visit_data_out[31:24] == obstruction_x[7:0]))? visit_data_out[3:0] : 4'b0000;

wire [3:0] output_dir = (other_dirs | dir_one_hot);

always_comb begin
    if((visit_data_out[31:16] == visit_vector[31:16])) begin
        vis_vec_samesies = |(visit_data_out[3:0] & visit_vector[3:0]);
    end
    else begin
        vis_vec_samesies = 0;
    end
end

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
        loops_found <= 0;
        obstruction_x <= 0;
        obstruction_y <= 0;
        visit_vector <= 0;
        current_index <= 0;
        current_index_valid <= 0;
        rw <= 0;
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
                        guard_init_x <= x;
                        guard_init_y <= y;
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
                state <= DRY_RUN;
            end

            DRY_RUN: begin
                visit_we <= 1;
                visit_data_in <= 1;
                if(nex_is_oob) begin
                    state <= COUNT_OBS;
                    visit_addr <= 0;
                    output_data <=0;
                    x <=0;
                    y <=0;
                    obs_addr <= 0;

                end
                    visit_addr[7:0] <= guard_x;
                    visit_addr[15:8] <= guard_y;
                    if(dir == next_dir) begin
                        guard_x <= next_x;
                        guard_y <= next_y;
                    end
                    dir <= next_dir;
            end
            COUNT_OBS: begin
            //loop through the visit data and record locations that have been visited
                visit_we <= 1;
                visit_data_in <= 0;
                if(x==x_dim) begin
                    if(y==y_dim) begin
                        state <= OBS_LAT;
                        num_of_obs <= obs_addr;
                    end else begin
                    x <= 0;
                    y <= y + 1;
                    end
                end else begin
                    x <= x + 1;
                end
                if(visit_data_out) begin
                    obs_data_in[7:0] <= visit_addr[7:0];
                    obs_data_in[15:8] <= visit_addr[15:8];
                    obs_we <= 1;
                end else begin
                    obs_we <= 0;
                end
                if(obs_we) obs_addr <= obs_addr + 1;
                visit_addr <= x*256 + y;
            end
            OBS_LAT: begin
                visit_we <= 0;
                state <= OBS_LOAD;
                obs_addr <= 0;
                obs_we <= 0;
                guard_x <= guard_init_x;
                guard_y <= guard_init_y;
                dir <= 0;
            end

            OBS_LOAD: begin
                obstruction_x <= obs_data_out[7:0];
                obstruction_y <= obs_data_out[15:8];
                obs_addr <= obs_addr + 1;
                state <= RUN;
                visit_addr <= guard_x*256 + guard_y;
            end
            RUN: begin

                if(current_index_valid) current_index_valid <= 0;
                //visit_data_in <= {{obstruction_x[7:0], obstruction_y[7:0],13'd0,dir[1:0],1}};
                //visit_vector <= {{obstruction_x[7:0], obstruction_y[7:0],13'd0,dir[1:0],1}};

                //expanding the above...
                visit_vector[3:0] <=  dir_one_hot;
                visit_vector[15:4] <= 12'd0;
                visit_vector[23:16] <= obstruction_y[7:0];
                visit_vector[31:24] <= obstruction_x[7:0];

                visit_data_in[3:0] <= output_dir;
                visit_data_in[15:4] <= 12'd0;
                visit_data_in[23:16] <= obstruction_y[7:0];
                visit_data_in[31:24] <= obstruction_x[7:0];

                visit_addr <= guard_x*256 + guard_y;
                dir <= next_dir;
                    if(rw) begin
                        if(dir == next_dir) begin
                            guard_x <= next_x;
                            guard_y <= next_y;
                            visit_we <= 1;
                        end else visit_we <= 0;
                    rw <= 0;
                    end else begin
                        rw <= 1;
                        visit_we <= 0;
                    end
                //handle the OOB case 
                if(nex_is_oob || loop_detect ||((obstruction_x == guard_init_x) && (obstruction_y == guard_init_y))) begin
                    if(obs_addr == num_of_obs) begin
                            state <= DONE;
                            output_data <= loops_found + (loop_detect? 1:0);
                            x <=0;
                            y <=0;
                    end else begin
                        obstruction_x <= obs_data_out[7:0];
                        obstruction_y <= obs_data_out[15:8];
                        obs_addr <= obs_addr + 1;
                        guard_x <= guard_init_x;
                        guard_y <= guard_init_y;
                        dir <= 0;
                        current_index <= obs_addr;
                        current_index_valid <= 1;
                    end
                end
                if(loop_detect) begin
                    loops_found <= loops_found + 1;
                end
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
                current_index_valid <= 1;
            end

        endcase
    end
end

endmodule