edit : rob.v rob_testbench.v
	iverilog -o rob rob.v rob_testbench.v
	vvp rob

clean : rob
	rm rob
