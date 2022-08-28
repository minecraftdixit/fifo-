# fifo-
synchronous  fifo  verification using system verilog 
In this repo synchronous fifo is being done alongwith the Testbench having the following components:
Generator: 	Generates different input stimulus to be driven to DUT
Interface :	Contains design signals that can be driven or monitored
Driver :	Drives the generated stimulus to the design
Monitor :	Monitor the design input-output ports to capture design activity
Scoreboard : 	Checks output from the design with expected behavior
Environment :	Contains all the verification components mentioned above
Test 	: Contains the environment that can be tweaked with different configuration settings
