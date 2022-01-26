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
	
	Developer: Truong Hy
	HDL      : Verilog
	Version  : 1.3
	
	Description:
		Implements writing of specified data and address to ARM AMBA AXI interconnect interface
		slave.
	
	Ports:
		addr = starting address to write AXI
		data = the data to write out to AXI
	
	AXI spec notes:
		aw_len = number of bursts (aka blocks) to transfer.  Formula: actual_length = aw_len + 1
		aw_size = size of a burst (aka block) transfer.  Formula: size_bytes = 2^aw_size
		The parameter WR_AXI_MAX_BURST_LEN is the maximum burst length allowed (number of burst
		transfers) a range 1 to 16 (AXI 3).
*/
module rd_axi #(
	RD_AXI_ADDR_WIDTH = 32,
	RD_AXI_BUS_WIDTH = 32,
	RD_AXI_MAX_BURST_LEN = 1
)(
	input clock,
	input reset,
	
	input enable,
	input [RD_AXI_ADDR_WIDTH-1:0] addr,
	output reg [RD_AXI_BUS_WIDTH*RD_AXI_MAX_BURST_LEN-1:0] data,
	input [3:0] burst_len,
	input [2:0] burst_size,
	output reg [1:0] status,  // 0 = ready, 1 = wait, 2 = completed ok, 3 = completed error
	// Connection to the AXI interface slave..
	// Address read channel registers
	output reg [RD_AXI_ADDR_WIDTH-1:0] ar_addr,
	output reg [3:0] ar_len,
	output reg [2:0] ar_size,
	output reg [1:0] ar_burst,
	output reg [2:0] ar_prot,
	output reg ar_valid,
	input ar_ready,
	// Read data channel registers
	input [RD_AXI_BUS_WIDTH-1:0] r_data,
	input r_last,
	input [1:0] r_resp,
	input r_valid,
	output reg r_ready
);
	reg [3:0] burst_count;
	reg error;

	always @ (posedge clock or posedge reset) begin
		if(reset) begin
			//data <= { (RD_AXI_BUS_WIDTH*RD_AXI_MAX_BURST_LEN){1'b0} };
			ar_valid <= 0;
			r_ready <= 0;
			status <= 0;
		end
		else begin

			// =======================================================
			// When enabled, set the read address on the AXI interface
			// =======================================================

			if(enable && !status) begin
				//data <= { (RD_AXI_BUS_WIDTH*RD_AXI_MAX_BURST_LEN){1'b0} };
				burst_count <= 0;
				error <= 0;
				status <= 1;
				
				// Setup the address and assert ar_valid so the receiver will read it
				ar_addr <= addr;
				ar_len <= burst_len; // Number of transfer beats = ar_len + 1 (aka burst length)
				ar_size <= burst_size;  // Per transfer size = 2^burst_size (in bytes)
				ar_burst <= 1;  // 1 = auto incrementing burst type
				ar_prot <= 0;
				ar_valid <= 1;
			end

			// ==============================================
			// When ready and valid, start the read operation
			// ==============================================

			if(ar_ready && ar_valid) begin
				ar_valid <= 0;
				r_ready <= 1;
			end

			// =======================================================
			// When ready and valid, store data from the AXI interface
			// =======================================================
		
			if(r_ready && r_valid) begin
				// Store a burst transfer to a register at the correct index
				data[RD_AXI_BUS_WIDTH*burst_count +: RD_AXI_BUS_WIDTH] <= r_data;
				
				// Not end of burst? (i.e. more data to processs?)
				//if(!r_last) begin
				if(burst_count < ar_len) begin
					if(r_resp >= 2) error <= 1;  // Check for error
				end
				else begin
					status <= (r_resp >= 2 || error) ? 3 : 2;  // Check for error. Set 3 = error, 2 = ok
					r_ready <= 0;
				end

				burst_count <= burst_count + 1;
			end
		
			// ==================
			// When done, restart
			// ==================
		
			if(status >= 2 && !enable) begin
				status <= 0;
			end
		end
	end
endmodule
