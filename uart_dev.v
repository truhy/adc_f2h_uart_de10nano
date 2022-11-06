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
	Start date: 07/10/2020
	HDL       : Verilog
	Target    : For the DE-10 Nano Development Kit board (SoC FPGA Cyclone V)
	Version   : 20221029
	
	Description:
		Transmit and receive data using the HPS UART controller from the FPGA side - yes that's right from the FPGA side!
		This is achieved on the FPGA side by directly reading and writing the hard-IP UART controller registers using
		the AXI interface with the FPGA-to-HPS bridge.
	
		This version uses polling method to read a register and check when the UART is ready to accept the next data, perhaps
		a better approach is to make use of interrupt signal (interrupt receiver) which I believe can be exposed in the
		Platform Designer with custom component.
		Note: string literals in Quartus verilog are stored with the left most character in the highest byte
		position.  This code takes the input character string and transmits them in the reverse order, i.e.
		from lowest byte position first because I think this is more natural.
	
	Input ports:
		enable = 1 = transmit, 2 = receive, 0 = do nothing
		tx_input_type = selects data source type: 0 = data buffer register, 1 = memory address offset
		tx_data = register containing data to transmit.  Selected when tx_input_type = 0
		tx_addr = address of memory containing data to transmit.  Selected when tx_input_type = 1.  Address must be 32-bit aligned, i.e. must be a multiple of 4
		tx_len = length of transmit data in bytes
		tx_hex = converts transmit bytes into hex string: 0 = no, 1 = yes
		tx_hex_start = transmit start position to convert into tx_hex string
		tx_new_line = transmit new line at the end: 0 = no, 1 = yes
		
	Output ports:
		rx_data = register containing byte received
		status = 0 = none, 1 = busy, 2 = done transmit or received data, 3 = done but no received data
		
	HPS UART0 controller registers used (see Cyclone V Hard Processor System Technical Reference Manual):
		UART0 base address: 0xFFC02000  
		rbr_thr_dll: 0xFFC02000
			bit 0 to 7 = data byte received or transmit (depends on LCR bits)
		ier_dlh: 0xFFC02004
		fcr: 0xFFC02008
		lsr: 0xFFC02014
			if bit 0 = 1 (Data Ready) then there is received data in the buffer,
			if ier_dlh[7] == 1 and fcr[0] == 1 then
				bit 5 == 0 means transmit is empty
			else
				bit 6 == 1 means transmit is empty
			
	References:
		-	Cyclone V Hard Processor System Technical Reference Manual
		-	Cyclone V Device Handbook Volume 1 Device Interfaces and Integration
*/
module uart_dev #(
	UART_BASE_ADDR = 32'hFFC02000,
	UART_TX_DATA_BUF_LEN = 1,	// For sizing the UART transmit data buffer register
	UART_THRE_FIFO_MODE = 0,	// Is UART in THREshold trigger level and FIFO mode?  If register bits ier_dlh[7] == 1 and fcr[0] == 1 then set this parameter to 1, else set to 0
	RD_AXI_ADDR_WIDTH = 32,
	RD_AXI_BUS_WIDTH = 32,
	RD_AXI_MAX_BURST_LEN = 1,
	WR_AXI_ADDR_WIDTH = 32,
	WR_AXI_BUS_WIDTH = 32,
	WR_AXI_MAX_BURST_LEN = 1
)(
	input clock,
	input reset,
	
	input [1:0] enable,
	output reg [1:0] status,
	
	input tx_input_type,
	input [8*UART_TX_DATA_BUF_LEN-1:0] tx_data,
	input [31:0] tx_addr,
	input [7:0] tx_len,
	input tx_hex,
	input [7:0] tx_hex_start,
	input tx_new_line,
	
	output reg [7:0] rx_data,
	
	// AXI interface stuff..
	output reg rd_axi_enable,
	output reg [RD_AXI_ADDR_WIDTH-1:0] rd_axi_addr,
	input [RD_AXI_BUS_WIDTH*RD_AXI_MAX_BURST_LEN-1:0] rd_axi_data,
	output reg [3:0] rd_axi_burst_len,
	output reg [2:0] rd_axi_burst_size,
	input [1:0] rd_axi_status,
	output reg wr_axi_enable,
	output reg [WR_AXI_ADDR_WIDTH-1:0] wr_axi_addr,
	output reg [WR_AXI_BUS_WIDTH*WR_AXI_MAX_BURST_LEN-1:0] wr_axi_data,
	output reg [3:0] wr_axi_burst_len,
	output reg [2:0] wr_axi_burst_size,
	output reg [3:0] wr_axi_burst_mask,
	input [1:0] wr_axi_status
);
	// This list should be an enum but Verilog doesn't have
	localparam STATE_WAIT_ENABLE              = 0;
	localparam STATE_INIT_TX                  = 1;
	localparam STATE_TIMER1                   = 2;
	localparam STATE_RD_AXI_WAIT_STATUS_READY = 3;
	localparam STATE_WR_AXI_WAIT_STATUS_READY = 4;
	localparam STATE_RD_DATA_ADDR             = 5;
	localparam STATE_RD_DATA_ADDR_2           = 6;
	localparam STATE_CHK_UART_TX_EMPTY        = 7;
	localparam STATE_CHK_UART_TX_EMPTY_2      = 8;
	localparam STATE_TX_CHAR                  = 9;
	localparam STATE_TX_CHAR_2                = 10;
	localparam STATE_TX_HEX                   = 11;
	localparam STATE_TX_HEX_2                 = 12;
	localparam STATE_TX_HEX_3                 = 13;
	localparam STATE_NEXT_DATA_ADDR           = 14;
	localparam STATE_DECIDE_NL                = 15;
	localparam STATE_DECIDE_NL_2              = 16;
	localparam STATE_DECIDE_NL_3              = 17;
	localparam STATE_DECIDE_NL_4              = 18;
	localparam STATE_CHK_UART_RX_RDY          = 19;
	localparam STATE_CHK_UART_RX_RDY_2        = 20;
	localparam STATE_RD_UART_RX_DATA          = 21;
	localparam STATE_CPY_UART_RX_DATA         = 22;
	localparam STATE_DONE                     = 23;
	localparam STATE_END                      = 24;

	wire tx_is_empty = (UART_THRE_FIFO_MODE) ? ~last_rd_axi_data[5] : last_rd_axi_data[6];  // If THRE and FIFO mode is enabled (i.e. register bits ier_dlh[7] == 1 and fcr[0] == 1) then bit5 == 0 means tx is empty, else bit6 == 1 means tx is empty
	reg [31:0] mem_data;
	reg [31:0] nxt_addr;
	reg [7:0] digit;
	reg [8:0] count;
	//reg [RD_AXI_BUS_WIDTH*RD_AXI_MAX_BURST_LEN-1:0] last_rd_axi_data;
	reg [31:0] last_rd_axi_data;
	reg [12:0] timer1;
	reg [4:0] state_after_timer1;
	reg [4:0] state_after_axi;
	reg [4:0] state_next;  // State to go when UART transmit buffer is empty
	reg [4:0] state;
	always @ (posedge clock or posedge reset) begin
		// Reset?
		if(reset) begin
			rd_axi_enable <= 0;
			wr_axi_enable <= 0;
			count <= 0;
			status <= 0;
			state <= 0;
		end
		else begin
			// -------------
			// State machine
			// -------------
			case(state)
				
				// Wait for enable
				STATE_WAIT_ENABLE: begin
					case(enable)
						1: begin
							status <= 1;
							state <= STATE_INIT_TX;
						end
						2: begin
							status <= 1;
							state <= STATE_CHK_UART_RX_RDY;
						end
					endcase
				end
				
				// Initialise for transmit
				STATE_INIT_TX: begin
					count <= 0;
					nxt_addr <= tx_addr + tx_len - 1;  // Start from the end
					
					// State to go to after transmit buffer is empty is decided by the mode sending as hex or as character?
					state_next <= (tx_hex && (tx_hex_start == 0)) ? STATE_TX_HEX : STATE_TX_CHAR;
					
					// State to go to is decided by the tx_len and tx_input_type
					state <= tx_len ? (tx_input_type ? STATE_RD_DATA_ADDR : STATE_CHK_UART_TX_EMPTY) : STATE_DECIDE_NL;
				end
				
				// Delay timer1
				STATE_TIMER1: begin
					if(timer1 == { 13{1'b1} }) state <= state_after_timer1;
					timer1 <= timer1 + 1;
				end
				
				// Start a read AXI request and wait for it to complete
				STATE_RD_AXI_WAIT_STATUS_READY: begin
					case(rd_axi_status)
						// Start
						0: begin
							rd_axi_enable <= 1;
						end
						// Status success?
						2: begin
							rd_axi_enable <= 0;
							last_rd_axi_data[31:0] <= rd_axi_data[31:0];
							state <= state_after_axi;
						end
						// On error yield a small amount of time
						3: begin
							rd_axi_enable <= 0;
							timer1 <= 0;
							state_after_timer1 <= STATE_RD_AXI_WAIT_STATUS_READY;
							state <= STATE_TIMER1;  // Go yield
						end
					endcase
				end
				
				// Start a write AXI request and wait for it to complete
				STATE_WR_AXI_WAIT_STATUS_READY: begin
					case(wr_axi_status)
						// Start
						0: begin
							wr_axi_enable <= 1;
						end
						// Status success?
						2: begin
							wr_axi_enable <= 0;
							state <= state_after_axi;
						end
						// On error yield a small amount of time
						3: begin
							wr_axi_enable <= 0;
							timer1 <= 0;
							state_after_timer1 <= STATE_WR_AXI_WAIT_STATUS_READY;
							state <= STATE_TIMER1;  // Go yield
						end
					endcase
				end
				
				// Read 32-bit (4 bytes) input data from memory address
				STATE_RD_DATA_ADDR: begin
					rd_axi_addr <= nxt_addr / 4 * 4;
					rd_axi_burst_len <= 0;  // Number of block transfers = len + 1 = 0 + 1
					rd_axi_burst_size <= 2;  // Block size = 2^size = 2^2 = 4 bytes
					state_after_axi <= STATE_RD_DATA_ADDR_2;
					state <= STATE_RD_AXI_WAIT_STATUS_READY;
				end
				
				STATE_RD_DATA_ADDR_2: begin
					mem_data[31:0] <= last_rd_axi_data[31:0];
					state <= STATE_CHK_UART_TX_EMPTY;
				end
				
				// Read UART register to find out if the transmit buffer is empty
				STATE_CHK_UART_TX_EMPTY: begin
					rd_axi_addr <= UART_BASE_ADDR + 20;  // The LSR register
					rd_axi_burst_len <= 0;  // Number of block transfers = len + 1 = 0 + 1
					rd_axi_burst_size <= 2;  // Block size = 2^size = 2^2 = 4 bytes
					state_after_axi <= STATE_CHK_UART_TX_EMPTY_2;
					state <= STATE_RD_AXI_WAIT_STATUS_READY;
				end
				
				// Check UART transmit buffer is empty
				STATE_CHK_UART_TX_EMPTY_2: begin
					if(tx_is_empty) begin  // UART transmit buffer is empty?
						state <= state_next;
					end
					else begin
						timer1 <= 0;
						state_after_timer1 <= STATE_CHK_UART_TX_EMPTY;
						state <= STATE_TIMER1;  // Go yield and then retry
					end
				end
				
				// Transmit a character
				STATE_TX_CHAR: begin
					wr_axi_addr <= UART_BASE_ADDR;  // The rbr_thr_dll register
					wr_axi_data[31:0] <= tx_input_type ? { 24'h000000, mem_data[8*((tx_len-count-1)%4) +: 8] } : { 24'h000000, tx_data[8*(tx_len-count-1) +: 8] };
					wr_axi_burst_len <= 0;  // Number of block transfers = len + 1 = 0 + 1
					wr_axi_burst_size <= 2;  // Block size = 2^size = 2^2 = 4 bytes
					wr_axi_burst_mask <= 4'b1111;
					state_after_axi <= STATE_TX_CHAR_2;
					state <= STATE_WR_AXI_WAIT_STATUS_READY;
				end
				
				// More data?
				STATE_TX_CHAR_2: begin
					// Is there more data to transmit?
					if(count < (tx_len - 1)) begin
						if(tx_hex && ((count + 1) >= tx_hex_start)) begin
							count <= 2 * (count + 1);
							state_next <= STATE_TX_HEX;  // When empty go to transmit hex
						end
						else begin
							count <= count + 1;
							state_next <= STATE_TX_CHAR;  // When empty go to transmit character
						end
						nxt_addr <= nxt_addr - 1;
						
						// Go to repeat again for next data
						state <= STATE_NEXT_DATA_ADDR;
					end
					else begin
						state <= STATE_DECIDE_NL;
					end
				end
				
				// Nibble hex digit
				STATE_TX_HEX:begin
					digit <= tx_input_type ? { 4'h0, mem_data[4*((2*tx_len-count-1)%8) +: 4] } : { 4'h0, tx_data[4*(2*tx_len-count-1) +: 4] };
					state <= STATE_TX_HEX_2;
				end
				
				// Transmit a character in hex format
				STATE_TX_HEX_2: begin
					wr_axi_addr <= UART_BASE_ADDR;  // The rbr_thr_dll register
					// Convert nibble to ASCII hex digit
					//wr_axi_data[31:0] <= ((digit >= 0) && (digit <= 9)) ? { 24'h000000, digit + 8'd48 } : { 24'h000000, digit + 8'd87 };
					wr_axi_data[31:0] <= (digit <= 9) ? { 24'h000000, digit + 8'd48 } : { 24'h000000, digit + 8'd87 };
					wr_axi_burst_len <= 0;  // Number of block transfers = len + 1 = 0 + 1
					wr_axi_burst_size <= 2;  // Block size = 2^size = 2^2 = 4 bytes
					wr_axi_burst_mask <= 4'b1111;
					state_after_axi <= STATE_TX_HEX_3;
					state <= STATE_WR_AXI_WAIT_STATUS_READY;
				end
				
				// More data?
				STATE_TX_HEX_3: begin
					// Is there more data to transmit?
					if(count < (2 * tx_len - 1)) begin
						count <= count + 1;
						nxt_addr <= nxt_addr - (count % 2);
						
						// Go to repeat again for next data
						state <= STATE_NEXT_DATA_ADDR;
					end
					else begin
						state <= STATE_DECIDE_NL;
					end
				end
				
				STATE_NEXT_DATA_ADDR: begin
					if(tx_input_type && (((nxt_addr + 1) % 4) == 0)) begin
						state <= STATE_RD_DATA_ADDR;
					end
					else begin
						state <= STATE_CHK_UART_TX_EMPTY;
					end
				end
				
				// Decide to transmit new line or not
				STATE_DECIDE_NL: begin
					if(tx_new_line) begin
						// Go to check UART tx buffer empty then transmit new line
						state_next <= STATE_DECIDE_NL_2;  // When empty go to transmit a new line
						state <= STATE_CHK_UART_TX_EMPTY;
					end
					else begin
						state <= STATE_DONE;
					end
				end
				
				// Transmit new line
				STATE_DECIDE_NL_2: begin
					wr_axi_addr <= UART_BASE_ADDR;  // The rbr_thr_dll register
					wr_axi_data[31:0] <= { 24'h000000, "\r" };
					wr_axi_burst_len <= 0;  // Number of block transfers = len + 1 = 0 + 1
					wr_axi_burst_size <= 2;  // Block size = 2^size = 2^2 = 4 bytes
					wr_axi_burst_mask <= 4'b1111;
					state_after_axi <= STATE_DECIDE_NL_3;
					state <= STATE_WR_AXI_WAIT_STATUS_READY;
				end

				STATE_DECIDE_NL_3: begin
					// Go to check UART tx buffer empty then transmit new line
					state_next <= STATE_DECIDE_NL_4;  // When empty go to transmit a new line
					state <= STATE_CHK_UART_TX_EMPTY;
				end
				
				// Transmit new line
				STATE_DECIDE_NL_4: begin
					wr_axi_addr <= UART_BASE_ADDR;  // The rbr_thr_dll register
					wr_axi_data[31:0] <= { 24'h000000, "\n" };
					wr_axi_burst_len <= 0;  // Number of block transfers = len + 1 = 0 + 1
					wr_axi_burst_size <= 2;  // Block size = 2^size = 2^2 = 4 bytes
					wr_axi_burst_mask <= 4'b1111;
					state_after_axi <= STATE_DONE;
					state <= STATE_WR_AXI_WAIT_STATUS_READY;
				end
				
				// Check reception for available data received
				STATE_CHK_UART_RX_RDY: begin
					rd_axi_addr <= UART_BASE_ADDR + 20;
					rd_axi_burst_len <= 0;
					rd_axi_burst_size <= 2;
					state_after_axi <= STATE_CHK_UART_RX_RDY_2;
					state <= STATE_RD_AXI_WAIT_STATUS_READY;
				end
				
				STATE_CHK_UART_RX_RDY_2: begin
					if(last_rd_axi_data[0]) begin
						state <= STATE_RD_UART_RX_DATA;
					end
					else begin
						status <= 3;
						state <= STATE_END;
					end
				end
				
				// Read reception data into temporary register
				STATE_RD_UART_RX_DATA: begin
					rd_axi_addr <= UART_BASE_ADDR;
					rd_axi_burst_len <= 0;
					rd_axi_burst_size <= 2;
					state_after_axi <= STATE_CPY_UART_RX_DATA;
					state <= STATE_RD_AXI_WAIT_STATUS_READY;
				end
				
				// Copy reception data to output port register
				STATE_CPY_UART_RX_DATA: begin
					rx_data <= last_rd_axi_data[7:0];
					state <= STATE_DONE;
				end
				
				STATE_DONE: begin
					status <= 2;
					state <= STATE_END;
				end
				
				STATE_END: begin
					status <= 0;
					state <= STATE_WAIT_ENABLE;
				end
			endcase
		end
	end
endmodule
