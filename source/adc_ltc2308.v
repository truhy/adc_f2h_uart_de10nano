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

	Developer : Truong Hy
	HDL       : Verilog
	Target    : For the DE-10 Nano Development Kit board (SoC FPGA Cyclone V)
	Version   : 20240703

	Description:
		A Verilog module to setup and read-out samples from the ADC LTC2308 IC,
		connected to the FPGA fabric on the DE-10 Nano board.

		I know Quartus Prime Platform Designer already provides a free ADC IP for
		the Terasic DE series dev boards, it is listed under the "University
		Program" tree, but it hides the actual ADC IC logic:
			1. First, they've implemented a memory map which consists of a completely
			   made up set of registers - not native to the ADC IC.  In my opinion is
			   really only suited for the NIOS II softcore or an application on the
			   SoC (ARM) side
			2. Data is stored and streamed using a custom FIFO & an ADC to FIFO IP
			   that was created in Platform Designer as a custom IP
			3. Uses an ADC to FIFO IP which streams (writes) to the memory mapped
			   registers, so data samples is not readily accessible on the FPGA side
			4. Doesn't expose channel options
		
		My module is more basic and easier to understand for the beginner.  It
		simply outputs the data samples to an output register.
	
	Timing
		The constant timing parameters are calculated for the maximum 40MHz SPI
		input clock, if you want to use another frequency you will need to
		recalculate and change the following parameters:
			TACQ
			TWHCONV
			TCONV
	
	Output sample format:
		Unipolar mode: 12 bit unsigned integer
		Bipolar mode : 12 bit, 2's complement signed integer
	
	User ports:
		tcyc
			Total cycle time in ticks of the SPI clock.  This sets the sampling
			frequency.  For 40MHz SPI clock a value between (inclusive) 1 and 80
			To keep within the specification accuracy you must respect the maximum
			sampling frequency of 500kHz.
			
		differential
			Input mode
				0 = single ended input mode
				1 = differential input mode
				
		ch0 to ch7
			Enable for each of the eight channels, which will be included in the
			multiplex read.
				0 = disable
				1 = enable
				
		start
			The acquisition process starts when this is set to 1
				0 = stop reading samples
				1 = start reading samples
			Once initiated, a new conversion cannot be restarted or stopped until the
			current conversion is complete
			
		ready
			Ready changes to a 1 to indicate when a 12-bit sample is available in the
			data output register
			
		data
			12-bit ADC sample (valid when ready == 1)
			
		curr_ch
			The current ADC sample channel number

	Sampling frequency formula:
	  tcyc = spi_clock / samp_freq
	  where tcyc is total cycles in ticks of the SPI clock, spi_clock is SPI clock
		in Hz, samp_freq is desired sampling frequency in Hz
		 
		Example tcyc values using 40MHz SPI clock:
			tcyc = 80       (500kHz sampling freq)
			tcyc = 100      (400kHz sampling freq)
			tcyc = 400      (100kHz sampling freq)
			tcyc = 800      (50kHz  sampling freq)
			tcyc = 4000     (10kHz  sampling freq)
			tcyc = 20000000 (2Hz    sampling freq)
	
	Notes:
		The sampling frequency will affect the input impedance, so if you're not
		using a buffer in front of the ADC input, e.g. wiring a potentiometer
		directly onto the input, then the readings would differ when comparing
		readings from different sampling frequencies.
		
		Also, because there is no shielding between the ADC input pins you may see
		some cross talk.
		
		The ADC actually delays the sample output with respect to the configuration
		command, i.e. the current sample read is set by the previous configuration
		command, and the current configuration will effect the next sample read.
		
	Limitations:
		On the DE10-Nano the LT2308 ADC COM pin (pin 6) is wired to ground so we
		can only use the unipolar mode, i.e. 0 to 4.096V (Vref) range. Bipolar
		mode is (+-0.5 * Vref), e.g. -2.048V to 2.048V which cannot be used unless
		you physically modify the pin.
	
	References:
		LTC2308 datasheet
		SPI protocol
*/

// This define will use TACQ instead of TCONV for the span section calculations.  If enabled maximises TCONV (conversion time), else maximises TACQ (aquisition time)
`define USE_TACQ

module adc_ltc2308 #(
	parameter TACQ = 10,    // Min acquisition time = 240ns = 240ns / 25ns = 10 ticks (rounded up)
	parameter TWHCONV = 1,  // For timing with a Short CONVST Pulse (no nap or sleep). Minimum CONVST high time = 20ns, ticks required: 20 / 25ns = 1 tick (rounded up)
	parameter TCONV = 64    // Worst case conversion time = 1.6us, ticks required: 1600ns / 25ns = 64 ticks
	//parameter TCONV = 52    // Typical conversion time = 1.3us, ticks required: 1300ns / 25ns = 52 ticks
)(
	input clock,  // Input clock to drive the ADC SPI clock (SCK) (40MHz)
	input reset_n,
	
	// Module ports for the user..
	input [31:0] tcyc,
	input differential,
	input ch0,
	input ch1,
	input ch2,
	input ch3,
	input ch4,
	input ch5,
	input ch6,
	input ch7,
	input start,
	output ready,
	output reg [11:0] data,
	output reg [2:0] curr_ch,
	
	// Module ports for ADC pins..
	output CONVST,
	output SCK,
	output reg SDI,
	input SDO
);
	// =========
	// Constants
	// =========
	
	localparam ADC_RES  = 12;  // ADC resolution (in bits)
	localparam CFG_SIZE = 6;   // Size of the configuration command (in bits)

	localparam CONVST_HI_BEGIN = 0;
	localparam CONVST_HI_END   = CONVST_HI_BEGIN + TWHCONV;

	localparam [0:0] UNI   = 1'b1;  // 0 = Bipolar, 1 = Unipolar (This is always 1 because DE10-Nano circuit only supports unipolar, i.e. COM pin is wired to ground)
	localparam [0:0] SLEEP = 1'b0;  // Sleep mode is not supported - I don't have time to implement it, but whenever sleep is enabled we must wait 200ms after wakeup

	// =========================
	// Span section calculations
	// =========================
	
	// Units in ticks of the input clock
	
	// For SCK begin:
	// USE_TACQ:
	//     The specified TACQ is used and TCONV is calculated for the longest duration.
	//     This supports all sampling rates upto 500kHz
	// else:
	//		 The specified TCONV is used and TACQ is calculated for the longest duration.
	//		 Because we are using 25ns as our span calculation unit (40MHz clock),
	//     the maximum 500kHz sampling with the worse case TCONV of 1.6us is not possible,
	//     for 500kHz you would need to use the typical 1.3us, or use specified TACQ above
`ifdef USE_TACQ
	wire [31:0] sck_begin = curr_tcyc - ADC_RES - (ADC_RES - TACQ) - 3;  // Use specified TACQ and maximises TCONV (converstion time)
`else
	wire [31:0] sck_begin = CONVST_HI_END + TCONV;  // Use specified TCONV and maximises TACQ (acquisition time)
`endif	
	wire [31:0] sck_end = sck_begin + ADC_RES;
	wire [31:0] cfg_begin = sck_begin - 1;
	wire [31:0] cfg_end = cfg_begin + CFG_SIZE;

	// ===============================================
	// A counter for each conversion and readout cycle
	// ===============================================
	
	reg [31:0] curr_tcyc;
	reg [31:0] conv_span_counter;  // Conversion and readout span counter
	always @ (negedge clock or negedge reset_n) begin
		if(!reset_n) begin
			curr_tcyc <= tcyc;
			conv_span_counter <= -1;  // The reset is asynchronous to the clock so we should not use it for conv_span_counter start, we will set it with a negative value before the start value
		end else if(!start && (conv_span_counter == (curr_tcyc - 1) || conv_span_counter < 0)) begin  // Stop counter
			// Stop counting only when not in the process of a conversion
			// Datasheet quote: Once initiated, a new conversion cannot be restarted until the current conversion is complete
			curr_tcyc <= tcyc;
			conv_span_counter <= -1;
		end else if(conv_span_counter == (curr_tcyc - 1)) begin  // Restart counter
			curr_tcyc <= tcyc;
			conv_span_counter <= 0;
		end else if(start) begin  // Increase count
			conv_span_counter <= conv_span_counter + 1;
		end
	end

	// =============================
	// Span section continuous logic
	// =============================

	wire sck_enable = (conv_span_counter >= sck_begin && conv_span_counter < sck_end) ? 1'b1 : 1'b0;
	assign ready = (conv_span_counter == sck_end) ? 1'b1 : 1'b0;
	assign SCK = (sck_enable) ? clock : 1'b0;  // SCK pin becomes input clock when enabled, else stays low
	assign CONVST = (conv_span_counter >= CONVST_HI_BEGIN && conv_span_counter < CONVST_HI_END) ? 1'b1 : 1'b0;  // CONVST pin is pulsed high to start a conversion, and stays low at other times

	// ================================================================
	// Read sample data bits from ADC SPI SDO on the falling clock edge
	// ================================================================
	
	// Thanks to javadtaghia for finding this out, it seems there is a mistake in
	// the timing diagrams Figure 8 and 9 in LTC2308 datasheet.  Data bits are
	// actually updated on the rising edge and so we read on the falling edge
	// instead.  Also, the first MSB is not available until after the first rising
	// edge!
	
	reg [3:0] data_index;
	always @ (negedge clock or negedge reset_n) begin
		if(!reset_n) begin
			data_index <= 0;
		end else if(sck_enable) begin
			data[data_index] <= SDO;
			data_index <= data_index - 1;
		end else begin
			//data <= 0;
			data_index <= ADC_RES - 1;
		end
	end

	// =====================================================
	// Multiplexor for enabling channels for the next sample
	// =====================================================
	
	wire [7:0] channels = { ch7, ch6, ch5, ch4, ch3, ch2, ch1, ch0 };
	reg [2:0] mux_index;
	wire [2:0] next_ch =
		channels[mux_index] ? mux_index :
		channels[(mux_index + 1) % 8] ? (mux_index + 1) % 8 :
		channels[(mux_index + 2) % 8] ? (mux_index + 2) % 8 :
		channels[(mux_index + 3) % 8] ? (mux_index + 3) % 8 :
		channels[(mux_index + 4) % 8] ? (mux_index + 4) % 8 :
		channels[(mux_index + 5) % 8] ? (mux_index + 5) % 8 :
		channels[(mux_index + 6) % 8] ? (mux_index + 6) % 8 :
		channels[(mux_index + 7) % 8] ? (mux_index + 7) % 8 :
		0;

	// =================================================
	// Set ADC configuration command for the next sample
	// =================================================
	
	reg [CFG_SIZE-1:0] cfg_cmd;
	always @ (posedge clock or negedge reset_n) begin
		if(!reset_n) begin
			curr_ch <= 0;
			mux_index <= 1;
		end else begin
			if(CONVST) begin
				if(differential) begin
					case(next_ch)
						// Differential input config
						0 : cfg_cmd <= { 4'h0, UNI, SLEEP };  // Selected channels & polarity: +0 with -1
						1 : cfg_cmd <= { 4'h1, UNI, SLEEP };  // Selected channels & polarity: +2 with -3
						2 : cfg_cmd <= { 4'h2, UNI, SLEEP };  // Selected channels & polarity: +4 with -5
						3 : cfg_cmd <= { 4'h3, UNI, SLEEP };  // Selected channels & polarity: +6 with -7
						4 : cfg_cmd <= { 4'h4, UNI, SLEEP };  // Selected channels & polarity: -0 with +1
						5 : cfg_cmd <= { 4'h5, UNI, SLEEP };  // Selected channels & polarity: -2 with +3
						6 : cfg_cmd <= { 4'h6, UNI, SLEEP };  // Selected channels & polarity: -4 with +5
						7 : cfg_cmd <= { 4'h7, UNI, SLEEP };  // Selected channels & polarity: -6 with +7
					endcase
				end else begin
					case(next_ch)
						// Single-ended input config
						0 : cfg_cmd <= { 4'h8, UNI, SLEEP };  // Selected channel & polarity: +0 with -COM
						1 : cfg_cmd <= { 4'hC, UNI, SLEEP };  // Selected channel & polarity: +1 with -COM
						2 : cfg_cmd <= { 4'h9, UNI, SLEEP };  // Selected channel & polarity: +2 with -COM
						3 : cfg_cmd <= { 4'hD, UNI, SLEEP };  // Selected channel & polarity: +3 with -COM
						4 : cfg_cmd <= { 4'hA, UNI, SLEEP };  // Selected channel & polarity: +4 with -COM
						5 : cfg_cmd <= { 4'hE, UNI, SLEEP };  // Selected channel & polarity: +5 with -COM
						6 : cfg_cmd <= { 4'hB, UNI, SLEEP };  // Selected channel & polarity: +6 with -COM
						7 : cfg_cmd <= { 4'hF, UNI, SLEEP };  // Selected channel & polarity: +7 with -COM
					endcase
				end
			end
			
			if(ready) begin
				curr_ch <= next_ch;
				mux_index <= next_ch + 1;
			end
		end
	end

	// ===============================================
	// Write configuration command for the next sample
	// ===============================================
	
	// Output to the SDI pin on the falling clock edge, because the ADC will read
	// them on the rising edge (see Figure 8 and 9 in LTC2308 datasheet)
	
	reg [2:0] cfg_index;
	always @ (negedge clock or negedge reset_n) begin
		if(!reset_n) begin
			cfg_index <= 0;
		end else if(conv_span_counter >= cfg_begin && conv_span_counter < cfg_end) begin
			SDI <= cfg_cmd[cfg_index];
			cfg_index <= cfg_index - 1;
		end else begin
			SDI <= 1'b0;
			cfg_index <= CFG_SIZE - 1;
		end
	end
endmodule
