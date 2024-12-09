import cocotb
import cocotb.clock
from cocotb.triggers import FallingEdge, Timer, RisingEdge

async def do_reset(dut):
    dut.rst_n.value = 0
    await Timer(100,units="ns")
    dut.rst_n.value = 1

def read_input_file():
    input_data = []
    with open('../test_data.txt', 'r') as file:
        for line in file:
            numbers = line.split()
            input_data.append((int(numbers[0]), int(numbers[1])))
    return input_data


@cocotb.test()
async def d1_test(dut):
    clk_125Mhz = cocotb.clock.Clock(dut.clk, 4, units="ns")
    cocotb.start_soon(clk_125Mhz.start())
    cocotb.start_soon(do_reset(dut))
    dut.data_stream1.value = 0
    dut.data_stream2.value = 0
    dut.valid.value = 0
    dut.done.value = 0
    data = read_input_file()
    #wait for the rising edge of the reset signal
    await RisingEdge(dut.rst_n)

    for i in range(len(data)):
        #wait for the rising edge of the clock signal
        await RisingEdge(dut.clk)
        dut.data_stream1.value = data[i][0]
        dut.data_stream2.value = data[i][1]
        dut.valid.value = 1

    await RisingEdge(dut.clk)
    dut.valid.value = 0
    dut.done.value = 1

    while dut.output_valid.value == 0:
        await RisingEdge(dut.clk)
    
    output_data_int = int(dut.output_data.value)
    print("Output data (int): ", output_data_int)
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"