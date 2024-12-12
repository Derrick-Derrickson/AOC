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
async def d5_test(dut):
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

    # Wait for nums_valid to be asserted
    #await RisingEdge(dut.output_data_valid)

    await Timer(500, units="ns")
    
    # Read and print the safe and unsafe amounts
    output_data = int(dut.output_data.value)
    print(f"Output data: {output_data}")
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"