
# UVM Testbench for APB Slave with DUT

This repository contains a UVM (Universal Verification Methodology) testbench developed for the AMBA APB protocol.
Unlike the “No DUT” version, this setup integrates an APB DUT (design.sv), which implements a 16x32-bit APB register file.
The testbench drives APB transactions to the DUT, monitors responses, and checks them against a reference model.

--
# Repository Structure

design.sv
APB DUT (register file with 16 x 32-bit registers).

apb_if.svh
Defines the APB SystemVerilog interface (signals, clocking blocks, modports for driver and monitor).

apb_rw.svh
Transaction class (apb_rw) defining APB read/write operations.

apb_sequences.svh
Sequence classes (for example, apb_base_seq) to generate randomized read/write transactions.

apb_master_drv.svh
Driver: drives APB read/write transactions onto the interface.

apb_monitor.svh
Monitor: observes DUT responses and publishes them to analysis ports.

apb_scoreboard.svh
Reference model using a memory map; checks read/write transactions for correctness against DUT responses.

apb_agent.svh / apb_env.svh
UVM agent and environment definitions. Connects driver, monitor, sequencer, and scoreboard.

apb_test.svh
UVM test classes to start sequences and run the environment (apb_base_test).

test_top.sv
Top-level testbench module. Instantiates the APB interface, DUT (design.sv), and starts the UVM test.
--
# How It Works

Sequences generate random or directed APB read/write transactions.

Driver drives these transactions to the DUT via the APB interface.

DUT (design.sv) stores data in its internal memory and responds with read data.

Monitor observes all transactions and forwards them to the scoreboard.

Scoreboard compares DUT responses with a reference model for correctness.

--

# Running the Test

Compile and run with any SystemVerilog simulator supporting UVM (for example, VCS, Questa, Xcelium):

vcs -sverilog -ntb_opts uvm-1.2 \
design.sv test_top.sv \
apb_if.svh apb_rw.svh apb_sequences.svh \
apb_master_drv.svh apb_monitor.svh apb_scoreboard.svh \
apb_agent.svh apb_env.svh apb_test.svh \
+incdir+.
./simv +UVM_TESTNAME=apb_base_test

--

# Features

UVM-compliant agent, monitor, driver, sequencer, and scoreboard

Integration with DUT (design.sv) implementing APB register file

Randomized read/write sequences with self-checking scoreboard

Reference memory model to validate DUT functionality

Support for protocol checks (psel/penable sequence correctness)
