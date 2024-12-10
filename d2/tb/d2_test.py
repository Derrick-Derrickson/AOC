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
async def d2_test(dut):
    clk_125Mhz = cocotb.clock.Clock(dut.clk, 4, units="ns")
    cocotb.start_soon(clk_125Mhz.start())
    cocotb.start_soon(do_reset(dut))
    dut.byte_in_valid.value = 0
    data = read_input_file()
    #wait for the rising edge of the reset signal
    await RisingEdge(dut.rst_n)

    for byte in data:
        # wait for the rising edge of the clock signal
        await RisingEdge(dut.clk)
        dut.byte_in.value = byte
        dut.byte_in_valid.value = 1

    await RisingEdge(dut.clk)
    dut.byte_in_valid.value = 0
    dut.bytes_done.value = 1

    # Wait for nums_valid to be asserted
    await RisingEdge(dut.nums_valid)
    
    # Read and print the safe and unsafe amounts
    safe_amount = int(dut.num_safe.value)
    unsafe_amount = int(dut.num_unsafe.value)
    print(f"Safe amount: {safe_amount}, Unsafe amount: {unsafe_amount}")
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"