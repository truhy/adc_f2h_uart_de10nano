// Each tick is 1ns
`timescale 1ns / 100ps

// Test bench
module tb_adc_ltc2308;
	reg clk;
	reg reset_n;
	reg tcyc;
	reg differential;
	reg ch0;
	reg ch1;
	reg ch2;
	reg ch3;
	reg ch4;
	reg ch5;
	reg ch6;
	reg ch7;
	reg start;
	wire ready;
	wire [11:0] data;
	wire [2:0] curr_ch;
	wire CONVST;
	wire SCK;
	wire SDI;
	reg SDO;

	// Create ADC module instance as DUT (Device Under Test)
	adc_ltc2308 adc0(
		.clock(clk),
		.reset_n(reset_n),
		.tcyc(tcyc),
		.differential(differential),
		.ch0(ch0),
		.ch1(ch1),
		.ch2(ch2),
		.ch3(ch3),
		.ch4(ch4),
		.ch5(ch5),
		.ch6(ch6),
		.ch7(ch7),
		.start(start),
		.ready(ready),
		.data(data),
		.curr_ch(curr_ch),
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
		tcyc <= 80;  // 500kHz sampling freq
		differential <= 1'b0;
		ch0 <= 1'b1;
		ch1 <= 1'b0;
		ch2 <= 1'b0;
		ch3 <= 1'b0;
		ch4 <= 1'b0;
		ch5 <= 1'b0;
		ch6 <= 1'b0;
		ch7 <= 1'b1;
		start <= 1'b0;
		SDO <= 1'b0;
		
		// After 1 period, set some values to test the reset and start
		#25
		reset_n <= 1'b1;  // Release reset
		start <= 1'b1;     // Set start ADC capture
		
		// Toggle port to simulate SPI output 12-bit sample value of 0x801
		#1612.5 SDO <= 1'b1;
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
		
		// Reset output to low
		#25 SDO <= 1'b0;
		
		// Toggle port to simulate SPI output 12-bit sample value of 0x911
		#1700 SDO <= 1'b1;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b1;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b1;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b0;
		#25   SDO <= 1'b1;
		
		// Reset output to low
		#25 SDO <= 1'b0;

		$display("%0d %0d", clk, SCK);  // Display values in monitor console
		#4100 $finish;  // Stop
	end
endmodule
