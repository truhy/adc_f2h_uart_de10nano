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

	
	
    HDL    : Verilog
    Target : For the DE-10 Nano Development Kit board (SoC FPGA Cyclone V)
    Version: 2.1 public
	
    Transmit data using the HPS UART controller from the FPGA side - yes that's right from the FPGA side!
    This is achieved on the FPGA side by directly reading and writing the hard-IP UART controller registers using
    the AXI interface with the FPGA-to-HPS bridge.

    Note: string literals in Quartus Verilog are stored with the left most character in the highest byte
    position.  This code takes the input character string and transmits them in the reverse order, i.e.
    from lowest byte position first because I think this is more natural.
	 
    Input parameters:
        enable = 1 = start transmission, 0 = do nothing
        input_type = selects data source type: 0 = data buffer register, 1 = memory address offset
        data = register containing data to transmit.  Selected when input_type = 0
        addr = address of memory containing data to transmit.  Selected when input_type = 1.  Address must be 32-bit aligned, i.e. must be a multiple of 4
        len = length of transmit data in bytes
        hex = converts bytes into hex string: 0 = no, 1 = yes
        hex_start = start position to convert into hex string
        new_line = transmit new line at the end: 0 = no, 1 = yes
        
    Output parameters:
        status = 0 = none, 1 = busy, 2 = done
            
    References:
        - Cyclone V Hard Processor System Technical Reference Manual
        - Cyclone V Device Handbook Volume 1 Device Interfaces and Integration
*/
module uart_dev #(
	UART_BASE_ADDR = 32'hFFC02000,
	UART_DATA_BUF_LEN = 1,
	RD_AXI_ADDR_WIDTH = 32,
	RD_AXI_BUS_WIDTH = 32,
	RD_AXI_MAX_BURST_LEN = 1,
	WR_AXI_ADDR_WIDTH = 32,
	WR_AXI_BUS_WIDTH = 32,
	WR_AXI_MAX_BURST_LEN = 1
)(
	input clock,
	input reset,
	
	input enable,
	output reg [1:0] status,
	
	input input_type,
	input [8*UART_DATA_BUF_LEN-1:0] data,
	input [31:0] addr,
	input [7:0] len,
	input hex,
	input [7:0] hex_start,
	input new_line,
	
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
	localparam STATE_START                    = 1;
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
	localparam STATE_DONE                     = 19;
	localparam STATE_END                      = 20;

	reg [31:0] mem_data;
	reg [31:0] nxt_addr;
	reg [7:0] digit;
	reg [8:0] count;
	//reg [RD_AXI_BUS_WIDTH*RD_AXI_MAX_BURST_LEN-1:0] last_rd_axi_data;
	reg [31:0] last_rd_axi_data;
	reg [12:0] timer1;
	reg [4:0] state_after_timer1;
	reg [4:0] state_after_status_ready;
	reg [4:0] state_after_rd_empty;
	reg [4:0] state;
	always @ (posedge clock or posedge reset) begin

		if(reset) begin
			rd_axi_enable <= 1'b0;
			wr_axi_enable <= 1'b0;
			count <= 0;
			status <= 0;
			state <= 0;
		end
		else begin

			case(state)
				STATE_WAIT_ENABLE: begin
					if(enable) begin
						status <= 1;
						state <= STATE_START;
					end
				end
				
				STATE_START: begin
					count <= 0;
					nxt_addr <= addr + len - 1;
					
					state_after_rd_empty <= (hex && (hex_start == 0)) ? STATE_TX_HEX : STATE_TX_CHAR;
					
					state <= len ? (input_type ? STATE_RD_DATA_ADDR : STATE_CHK_UART_TX_EMPTY) : STATE_DECIDE_NL;
				end
				
				STATE_TIMER1: begin
					if(timer1 == { 13{1'b1} }) state <= state_after_timer1;
					timer1 <= timer1 + 1'b1;
				end
				
				STATE_RD_AXI_WAIT_STATUS_READY: begin
					case(rd_axi_status)
						0: begin
							rd_axi_enable <= 1'b1;
						end
						2: begin
							rd_axi_enable <= 1'b0;
							last_rd_axi_data[31:0] <= rd_axi_data[31:0];
							state <= state_after_status_ready;
						end
						3: begin
							rd_axi_enable <= 1'b0;
							timer1 <= 0;
							state_after_timer1 <= STATE_RD_AXI_WAIT_STATUS_READY;
							state <= STATE_TIMER1;
						end
					endcase
				end
				
				STATE_WR_AXI_WAIT_STATUS_READY: begin
					case(wr_axi_status)
						0: begin
							wr_axi_enable <= 1'b1;
						end
						2: begin
							wr_axi_enable <= 1'b0;
							state <= state_after_status_ready;
						end
						3: begin
							wr_axi_enable <= 1'b0;
							timer1 <= 0;
							state_after_timer1 <= STATE_WR_AXI_WAIT_STATUS_READY;
							state <= STATE_TIMER1;
						end
					endcase
				end
				
				STATE_RD_DATA_ADDR: begin
					rd_axi_addr <= nxt_addr / 4 * 4;
					rd_axi_burst_len <= 0;
					rd_axi_burst_size <= 2;
					state_after_status_ready <= STATE_RD_DATA_ADDR_2;
					state <= STATE_RD_AXI_WAIT_STATUS_READY;
				end
				
				STATE_RD_DATA_ADDR_2: begin
					mem_data[31:0] <= last_rd_axi_data[31:0];
					state <= STATE_CHK_UART_TX_EMPTY;
				end
				
				STATE_CHK_UART_TX_EMPTY: begin
					rd_axi_addr <= UART_BASE_ADDR + 20;
					rd_axi_burst_len <= 0;
					rd_axi_burst_size <= 2;
					state_after_status_ready <= STATE_CHK_UART_TX_EMPTY_2;
					state <= STATE_RD_AXI_WAIT_STATUS_READY;
				end
				
				STATE_CHK_UART_TX_EMPTY_2: begin
					if(last_rd_axi_data[5]) begin
					//if(last_rd_axi_data[6]) begin
						state <= state_after_rd_empty;
					end
					else begin
						timer1 <= 0;
						state_after_timer1 <= STATE_CHK_UART_TX_EMPTY;
						state <= STATE_TIMER1;
					end
				end
				
				STATE_TX_CHAR: begin
					wr_axi_addr <= UART_BASE_ADDR;
					wr_axi_data[31:0] <= input_type ? { 24'h000000, mem_data[8*((len-count-1)%4) +: 8] } : { 24'h000000, data[8*(len-count-1) +: 8] };
					wr_axi_burst_len <= 0;
					wr_axi_burst_size <= 2;
					wr_axi_burst_mask <= 4'b1111;
					state_after_status_ready <= STATE_TX_CHAR_2;
					state <= STATE_WR_AXI_WAIT_STATUS_READY;
				end
				
				STATE_TX_CHAR_2: begin
					if(count < (len - 1)) begin
						if(hex && ((count + 1) >= hex_start)) begin
							count <= 2 * (count + 1);
							state_after_rd_empty <= STATE_TX_HEX;
						end
						else begin
							count <= count + 1;
							state_after_rd_empty <= STATE_TX_CHAR;
						end
						nxt_addr <= nxt_addr - 1;
						
						state <= STATE_NEXT_DATA_ADDR;
					end
					else begin
						state <= STATE_DECIDE_NL;
					end
				end
				
				STATE_TX_HEX:begin
					digit <= input_type ? { 4'h0, mem_data[4*((2*len-count-1)%8) +: 4] } : { 4'h0, data[4*(2*len-count-1) +: 4] };
					state <= STATE_TX_HEX_2;
				end
				
				STATE_TX_HEX_2: begin
					wr_axi_addr <= UART_BASE_ADDR;
					//wr_axi_data[31:0] <= ((digit >= 0) && (digit <= 9)) ? { 24'h000000, digit + 8'd48 } : { 24'h000000, digit + 8'd87 };
					wr_axi_data[31:0] <= (digit <= 9) ? { 24'h000000, digit + 8'd48 } : { 24'h000000, digit + 8'd87 };
					wr_axi_burst_len <= 0;
					wr_axi_burst_size <= 2;
					wr_axi_burst_mask <= 4'b1111;
					state_after_status_ready <= STATE_TX_HEX_3;
					state <= STATE_WR_AXI_WAIT_STATUS_READY;
				end
				
				STATE_TX_HEX_3: begin
					if(count < (2 * len - 1)) begin
						count <= count + 1;
						nxt_addr <= nxt_addr - (count % 2);
						
						state <= STATE_NEXT_DATA_ADDR;
					end
					else begin
						state <= STATE_DECIDE_NL;
					end
				end
				
				STATE_NEXT_DATA_ADDR: begin
					if(input_type && (((nxt_addr + 1) % 4) == 0)) begin
						state <= STATE_RD_DATA_ADDR;
					end
					else begin
						state <= STATE_CHK_UART_TX_EMPTY;
					end
				end
				
				STATE_DECIDE_NL: begin
					if(new_line) begin
						state_after_rd_empty <= STATE_DECIDE_NL_2;
						state <= STATE_CHK_UART_TX_EMPTY;
					end
					else begin
						state <= STATE_DONE;
					end
				end
				
				STATE_DECIDE_NL_2: begin
					wr_axi_addr <= UART_BASE_ADDR;
					wr_axi_data[31:0] <= { 24'h000000, "\r" };
					wr_axi_burst_len <= 0;
					wr_axi_burst_size <= 2;
					wr_axi_burst_mask <= 4'b1111;
					state_after_status_ready <= STATE_DECIDE_NL_3;
					state <= STATE_WR_AXI_WAIT_STATUS_READY;
				end

				STATE_DECIDE_NL_3: begin
					state_after_rd_empty <= STATE_DECIDE_NL_4;
					state <= STATE_CHK_UART_TX_EMPTY;
				end
				
				STATE_DECIDE_NL_4: begin
					wr_axi_addr <= UART_BASE_ADDR;
					wr_axi_data[31:0] <= { 24'h000000, "\n" };
					wr_axi_burst_len <= 0;
					wr_axi_burst_size <= 2;
					wr_axi_burst_mask <= 4'b1111;
					state_after_status_ready <= STATE_DONE;
					state <= STATE_WR_AXI_WAIT_STATUS_READY;
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
