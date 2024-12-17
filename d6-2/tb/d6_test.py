import cocotb
import cocotb.clock
from cocotb.triggers import FallingEdge, Timer, RisingEdge

async def do_reset(dut):
    dut.rst_n.value = 0
    await Timer(100,units="ns")
    dut.rst_n.value = 1


def read_input_file():
    with open('../test_data.txt', 'rb') as file:
        input_data = file.read()
    return input_data


@cocotb.test() 
async def d6_test(dut):
    clk_125Mhz = cocotb.clock.Clock(dut.clk, 4, units="ns")
    cocotb.start_soon(clk_125Mhz.start())
    cocotb.start_soon(do_reset(dut))
    dut.read_val_valid.value = 0
    data = read_input_file()
    #wait for the rising edge of the reset signal
    await RisingEdge(dut.rst_n)

    for byte in data:
        # wait for the rising edge of the clock signal
        await RisingEdge(dut.clk)
        dut.read_val.value = byte
        dut.read_val_valid.value = 1

    await RisingEdge(dut.clk)
    dut.read_val_valid.value = 0
    dut.read_val_done.value = 1
    if(True):
        while(True):
            await RisingEdge(dut.current_index_valid)
            current_index = int(dut.current_index.value)
            print(f"Current index: {current_index}")
            if(dut.output_data_valid.value == 1):
                break


    #Wait for nums_valid to be asserted
    #await RisingEdge(dut.output_data_valid)

    #await Timer(10000, units="ns")
    if(False):
        mem = dut.visited_locations.mem.value[::-1]
        mem_int = [int(byte) for byte in mem]
        x_dim = int(dut.x_dim.value)
        y_dim = int(dut.y_dim.value)
        for j in range(x_dim):
            for i in range(y_dim):
                if mem_int[(i*256+j)] != 0:
                    print(f"X", end="")
                else:
                    print(f".", end="")
            print("")
        
        print("")
        print("")

        map_data = dut.map.mem.value[::-1]
        map_int = [int(byte) for byte in map_data]
        for j in range(x_dim):
            for i in range(y_dim):
                if map_int[(i*256+j)] != 0:
                    print(f"X", end="")
                else:
                    print(f".", end="")
            print("")
    
    
    # Read and print the safe and unsafe amounts
    output_data = int(dut.output_data.value)
    print(f"Output data: {output_data}")
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"