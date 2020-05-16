edit : rob.v rob-testbench.v
	iverilog -o rob rob.v rob-testbench.v
	vvp rob

clean : rob
	rm rob