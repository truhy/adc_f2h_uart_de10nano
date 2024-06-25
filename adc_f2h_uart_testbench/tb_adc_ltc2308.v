// Each tick is 1ns
`timescale 1ns / 100ps

// Test bench
module tb_adc_ltc2308;
	reg clk;
	reg reset_n;
	reg start;
	reg sleep;
	reg [3:0] channel;
	wire ready;
	wire [11:0] data;
	wire CONVST;
	wire SCK;
	wire SDI;
	reg SDO;

	// Create ADC module instance as DUT (Device Under Test)
	adc_ltc2308 adc0(
		.clock(clk),
		.reset_n(reset_n),
		.start(start),
		.sleep(sleep),
		.channel(channel),
		.ready(ready),
		.data(data),
		.CONVST(CONVST),
		.SCK(SCK),
		.SDI(SDI),
		.SDO(SDO)
	);

	// Toggle the clock every 12.5ns. This produces a period of 2*12.5ns = 25ns, giving a 40MHz clock for the ADC
	always #12.5 clk = ~clk;
	
	// Alternative way to create 40MHz clock
	//initial begin
	//	clk <= 1'b0;
	//	forever #12.5 clk = ~clk;
	//end

	// Create the test
	initial begin
		// Set values at start of tick (tick = 0)
		clk <= 1'b0;
		reset_n <= 1'b0;  // Hold reset (active low)
		channel <= 1'b0;
		SDO <= 1'b0;
		start <= 1'b0;
		sleep <= 1'b0;
		
		// After 1 period, set some values to test the reset and start
		#25
		reset_n <= 1'b1;  // Release reset
		start <= 1'b1;     // Set start ADC capture
		
		// Toggle port to simulate SPI output sample value of 0x801
		#1350 SDO <= 1'b1;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b1;
		#25 SDO <= 1'b0;
		
		// Toggle port to simulate SPI output sample value of 0x123
		#1700 SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b1;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b1;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b1;
		#25   SDO <= 1'b1;
		#25 SDO <= 1'b0;

		$display("%0d %0d", clk, SCK);  // Display values in monitor console
		#4100 $finish;  // Stop
	end
endmodule
