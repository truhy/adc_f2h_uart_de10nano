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
	Version		: 20221217
	
	Description:
		A Verilog module to setup and read-out samples of the ADC LTC2308 IC, connected to the FPGA fabric on the DE-10 Nano
		board.
		
		I do know that Quartus Prime Platform Designer already provides a free ADC IP for the Terasic DE series dev boards,
		it is listed under the "University Program" tree, but it does have some these limitations:
			1.	First, they've implemented a memory map which consists of a completely made up set of
				registers - not native to the ADC IC.  In my opinion is really only suited for the NIOS II
				softcore or an application on the SoC (ARM) side
			2.	Data is stored and streamed using a custom FIFO & an ADC to FIFO IP that was created in
				Platform Designer as a custom IP
			3.	It uses an ADC to FIFO IP which streams (writes) to the memory mapped registers, so the data
				samples is not readily accessible on the FPGA side
			4.	It appears there is a bug in their IP where the most significant bit is not read-out
			5.	It doesn't expose the sleep and channel options
		
		In contrast my module is more basic and easier to understand for the beginner.  It simply outputs the data
		samples using an output register, and then you can do whatever you want with it.
	
	Timings:
		The timing values is set to the maximum sampling rate of 500kHz and SPI clock of 40MHz. If you would like
		other timings you will need to re-calculate (see datasheet for formulas) and change the following defines:
			TCONV
			THCONVST
			TCYC
	
	Output sample format:
		Unipolar mode: 12 bit unsigned integer
		Bipolar mode : 12 bit, 2's complement signed integer
	
	User ports:
		start
			The acquisition process starts when start is set to 1.
		sleep
			Enable/disables sleep mode:
				0 = Disable sleep
				1 = Enable sleep
		channel
			Selects the channel mode to choose which ADC samples will be transferred over SPI:
			For single-ended input (Channel mode = Selected channels & polarity):
				0 = +0 with -COM
				1 = +1 with -COM
				2 = +2 with -COM
				3 = +3 with -COM
				4 = +4 with -COM
				5 = +5 with -COM
				6 = +6 with -COM
				7 = +7 with -COM
			For differential input (Channel mode = Selected channels & polarity):
				8  = +0 with -1
				9  = +2 with -3
				10 = +4 with -5
				11 = +6 with -7
				12 = -0 with +1
				13 = -2 with +3
				14 = -4 with +5
				15 = -6 with +7
		ready
			Ready changes to a 1 to indicate when a 12-bit sample is available in the data output register.
		data
			12-bit ADC sample (valid when ready == 1).
	
	Limitations:
		-	Only continuous mode is implemented, i.e. 12-bit samples is readout repeatedly, perhaps in the
			next version can add in a one-shot mode.
		-	On the DE10-Nano the LT2308 ADC COM pin (pin 6) is wired to ground so we can only use the unipolar mode,
			i.e. 0 to 4.096V (Vref) range. Bipolar mode is (+-0.5 * Vref), e.g. -2.048V to 2.048V and cannot be used,
			unless you physically modify the pin.
			
	References:
		LTC2308 datasheet
		SPI protocol
*/
module adc_ltc2308
(
	input clock,  // Input clock to drive the ADC SPI clock (SCK) (default 40MHz)
	input reset_n,
	
	// Ports for the user..
	input start,
	input sleep,
	input [3:0] channel,
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
	`define TCYC 80        // TCYC = 500kHz (sampling freq) and 40MHz (SPI clock) = 80 ticks

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
	
	// Constant config command
	`define UNI 1'b1  // 0 = Bipolar, 1 = Unipolar (This is always 1 because DE10-Nano circuit only supports unipolar, i.e. COM pin is wired to ground)

	// A counter for each conversion and readout cycle..
	reg [6:0] conv_span_counter;  // Conversion and readout span counter
	always @ (posedge clock or negedge reset_n) begin
		if(!reset_n) begin
			conv_span_counter <= -1;  // The reset is asynchronous to the clock so we should not use it for conv_span_counter start.  A -1 dummy value as place holder
		end else if(!start || conv_span_counter == (`TCYC - 1)) begin
			conv_span_counter <= 0;
		end else begin
			conv_span_counter <= conv_span_counter + 1;
		end
	end

	assign CONVST = (conv_span_counter >= `CONVST_HI_BEGIN && conv_span_counter < `CONVST_HI_END) ? 1'b1 : 1'b0;  // CONVST pin is pulsed high to start a conversion, and stays low at other times

	// Enable SCK to start from a falling clock edge, because we want to toggle bits on the falling clock edge (SPI protocol)..
	reg sck_enable;
	always @ (negedge clock or negedge reset_n) begin
		if(!reset_n) begin
			sck_enable <= 1'b0;
		end else begin
			sck_enable <= (conv_span_counter >= `SCK_BEGIN && conv_span_counter < `SCK_END) ? 1'b1 : 1'b0;
		end
	end	
	assign SCK = sck_enable ? clock : 1'b0;  // SCK pin becomes input clock when enabled, else stays low
		
	// Read sample data bits from ADC SPI SDO on the rising clock edge (SPI protocol)..
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

	assign ready = (conv_span_counter == `SCK_END) ? 1'b1 : 1'b0;

	// Setup ADC config command for the selected channel input mode..
	reg [`CFG_SIZE-1:0] cfg_cmd;
	always @ (posedge clock) begin
		if(!sck_enable) begin
			case(channel)
				// Single-ended input config..
				0 : cfg_cmd <= { 4'h8, `UNI, sleep };  // Selected channels & polarity: +0 with -COM
				1 : cfg_cmd <= { 4'hC, `UNI, sleep };  // Selected channels & polarity: +1 with -COM
				2 : cfg_cmd <= { 4'h9, `UNI, sleep };  // Selected channels & polarity: +2 with -COM
				3 : cfg_cmd <= { 4'hD, `UNI, sleep };  // Selected channels & polarity: +3 with -COM
				4 : cfg_cmd <= { 4'hA, `UNI, sleep };  // Selected channels & polarity: +4 with -COM
				5 : cfg_cmd <= { 4'hE, `UNI, sleep };  // Selected channels & polarity: +5 with -COM
				6 : cfg_cmd <= { 4'hB, `UNI, sleep };  // Selected channels & polarity: +6 with -COM
				7 : cfg_cmd <= { 4'hF, `UNI, sleep };  // Selected channels & polarity: +7 with -COM
				
				// Differential input config..
				8 : cfg_cmd <= { 4'h0, `UNI, sleep };   // Selected channels & polarity: +0 with -1
				9 : cfg_cmd <= { 4'h1, `UNI, sleep };   // Selected channels & polarity: +2 with -3
				10 : cfg_cmd <= { 4'h2, `UNI, sleep };  // Selected channels & polarity: +4 with -5
				11 : cfg_cmd <= { 4'h3, `UNI, sleep };  // Selected channels & polarity: +6 with -7
				12 : cfg_cmd <= { 4'h4, `UNI, sleep };  // Selected channels & polarity: -0 with +1
				13 : cfg_cmd <= { 4'h5, `UNI, sleep };  // Selected channels & polarity: -2 with +3
				14 : cfg_cmd <= { 4'h6, `UNI, sleep };  // Selected channels & polarity: -4 with +5
				15 : cfg_cmd <= { 4'h7, `UNI, sleep };  // Selected channels & polarity: -6 with +7
			endcase
		end
	end

	// Write configuration command to SDI pin on the falling clock edge (SPI protocol)..
	reg [2:0] cfg_index;
	always @ (negedge clock) begin
		if(conv_span_counter >= `CFG_BEGIN && conv_span_counter < `CFG_END) begin
			SDI <= cfg_cmd[cfg_index];
			cfg_index <= cfg_index - 1;
		end else begin
			SDI <= 1'b0;
			cfg_index <= `CFG_SIZE - 1;
		end
	end
endmodule
