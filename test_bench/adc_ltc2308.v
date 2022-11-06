/*
	MIT License

	Copyright (c) 2020 Truong Hy

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.



	Developer	: Truong Hy
	HDL		: Verilog
	Target		: For the DE-10 Nano Development Kit board (SoC FPGA Cyclone V)
	Version		: 1.0
	
	Description:
		A module for the ADC LTC2308 that is connected to the FPGA fabric on the DE-10 Nano.  For the
		DE series development boards there is an Altera ADC IP listed under the University Program but it has
		some limitations:
			1.	first, it is implemented using memory map which consists of a completely made up set of
				registers.  In my opinion is really only suited for the NIOS II softcore or an application
				on the SoC (ARM) side
			2.	data is stored and streamed using a custom FIFO & a ADC to FIFO IP that was created in
				Platform Designer as a custom IP
			3.	because the ADC to FIFO IP streams (writes) to the memory map registers the data samples
				is not readily accessible on the FPGA side
			4.	it appears there is a bug in their IP where the most significant bit is not readout
		In contrast my module is more basic and easier to understand for the beginner.  It simply outputs the data
		samples using an output register, and then you can do whatever you want with it.
	
	Timings:
		The timing values is set to the maximum so an input SPI clock of 40MHz and sampling rate of 500kHz
		is utilised. If you want other timings you will need to re-calculate and change the following defines:
			TCONV
			THCONVST
			TCYC
	
	User ports:
		start
			The acquisition process starts when start is set to 1
		channel
			Set this to one of the 8 available channels (0 to 7) to read out from
		ready
			Ready changes to a 1 to indicate when a 12-bit sample is available in the data output register.
		data
			12-bit ADC sample (valid when ready == 1)
	
	Limitations:
		-	For this version continuous mode is used, i.e. 12-bit samples is readout repeatedly, perhaps in the
			next version can add in a one-shot mode.
		-	For this version (to keep things simple) only single-ended mode is used.
		-	On the DE10-Nano the LT2308 ADC COM pin is wired to ground so we can only use unipolar mode, i.e. 0
			to 5V range. Bipolar e.g. -2.5V to 2.5V cannot be used.
			
	References:
		LTC2308 datasheet
*/
module adc_ltc2308
(
	input clock,  // Input clock to drive the ADC SPI clock (SCK) (default 40MHz)
	input reset,
	
	// Ports for the user..
	input start,
	input [2:0] channel,
	output ready,
	output reg [11:0] data,
	
	// Ports for ADC pins..
	output CONVST,
	output SCK,
	output reg SDI,
	input SDO
);
	// SPI clock and sampling timing..
	// Max input clock = 40MHz = 1 second / 40MHz = 0.025us = 25ns
	// Max sampling frequency = 500kHz.  1 / (500kHz / 1000) = 2us = 2000ns
	// With a 40MHz input clock, the period of 500kHz will span across 2000ns / 25ns = 80 ticks
	
	// Timing characteristics calculated using LTC2308 datasheet..
	`define TWHCONV 1      // For timing with a Short CONVST Pulse. Minimum CONVST high time = 20ns, ticks required: 20 / 25ns = 1 (rounded up)
	`define TCONV 64       // Worst case conversion time = 1.6us, ticks required: 1600ns / 25ns = 64
	`define THCONVST 1     // Hold Time CONVST Low After Last SCK = 20ns, ticks required: 25ns / 20ns = 1 (rounded up)
	`define TCYC 80        // TCYC = 2us for 500kHz

	// Sizes..
	`define ADC_RES 12  // ADC resolution (in bits)
	`define CFG_SIZE 6  // Size of the configuration command (in bits)

	// Begin and end sections in ticks of the input clock..
	`define CONVST_HI_BEGIN 0
	`define CONVST_HI_END (`CONVST_HI_BEGIN + `TWHCONV)
	`define SCK_BEGIN (`CONVST_HI_END + `TCONV)
	`define SCK_END (`SCK_BEGIN + `ADC_RES)
	`define CFG_BEGIN (`SCK_BEGIN)
	`define CFG_END (`CFG_BEGIN + `CFG_SIZE)

	// A periodic tick for each conversion and readout cycle..
	reg [6:0] tick;
	always @ (posedge clock or posedge reset) begin
		if(reset) begin
			tick <= -1;  // The reset is asynchronous to the clock so we should not use it for tick start.  A -1 dummy value as place holder
		end else if(!start || tick == (`TCYC - 1)) begin
			tick <= 0;
		end else begin
			tick <= tick + 1;
		end
	end

	assign CONVST = (tick >= `CONVST_HI_BEGIN && tick < `CONVST_HI_END) ? 1'b1 : 1'b0;  // CONVST pin is pulsed high to start a conversion, and stays low at other times

	// Enable SCK to start from a falling clock edge, because we want to toggle bits on the low edges..
	reg sck_enable;
	always @ (negedge clock or posedge reset) begin
		if(reset) begin
			sck_enable <= 1'b0;
		end else begin
			sck_enable <= (tick >= `SCK_BEGIN && tick < `SCK_END) ? 1'b1 : 1'b0;
		end
	end	
	assign SCK = sck_enable ? clock : 1'b0;  // SCK pin becomes input clock when enabled, else stays low
		
	// Read sample data bits from ADC SPI SDO on the rising clock edge..
	reg [3:0] data_index;
	always @ (posedge clock) begin
		if(sck_enable) begin
			data[data_index] <= SDO;
			data_index <= data_index - 1;
		end else begin
			data_index <= `ADC_RES - 1;
			data <= 0;
		end
	end

	assign ready = (tick == `SCK_END) ? 1'b1 : 1'b0;

	// Config command bits..
	`define UNI 1'b1  // 0 = Bipolar, 1 = Unipolar
	`define SLP 1'b0  // 0 = Disable sleep, 1 = Enable sleep

	// Setup ADC config command for the selected channel with single-ended input mode..
	reg [`CFG_SIZE-1:0] cfg_cmd;
	always @ (posedge clock) begin
		if(!sck_enable) begin
			case(channel)
				// Differential config..
				/*
				0 : cfg_cmd <= { 4'h0, `UNI, `SLP };  // Channels +0 with -1
				1 : cfg_cmd <= { 4'h1, `UNI, `SLP };  // Channels +2 with -3
				2 : cfg_cmd <= { 4'h2, `UNI, `SLP };  // Channels +4 with -5
				3 : cfg_cmd <= { 4'h3, `UNI, `SLP };  // Channels +6 with -7
				4 : cfg_cmd <= { 4'h4, `UNI, `SLP };  // Channels -0 with +1
				5 : cfg_cmd <= { 4'h5, `UNI, `SLP };  // Channels -2 with +3
				6 : cfg_cmd <= { 4'h6, `UNI, `SLP };  // Channels -4 with +5
				7 : cfg_cmd <= { 4'h7, `UNI, `SLP };  // Channels -6 with +7
				*/
				
				// Single-ended config..
				0 : cfg_cmd <= { 4'h8, `UNI, `SLP };  // Channel +0 with -COM
				1 : cfg_cmd <= { 4'hC, `UNI, `SLP };  // Channel +1 with -COM
				2 : cfg_cmd <= { 4'h9, `UNI, `SLP };  // Channel +2 with -COM
				3 : cfg_cmd <= { 4'hD, `UNI, `SLP };  // Channel +3 with -COM
				4 : cfg_cmd <= { 4'hA, `UNI, `SLP };  // Channel +4 with -COM
				5 : cfg_cmd <= { 4'hE, `UNI, `SLP };  // Channel +5 with -COM
				6 : cfg_cmd <= { 4'hB, `UNI, `SLP };  // Channel +6 with -COM
				7 : cfg_cmd <= { 4'hF, `UNI, `SLP };  // Channel +7 with -COM
			endcase
		end
	end

	// Write configuration command to SDI pin..
	reg [2:0] cfg_index;
	always @ (negedge clock) begin
		if(tick >= `CFG_BEGIN && tick < `CFG_END) begin
			SDI <= cfg_cmd[cfg_index];
			cfg_index <= cfg_index - 1;
		end else begin
			SDI <= 1'b0;
			cfg_index <= `CFG_SIZE - 1;
		end
	end
endmodule
