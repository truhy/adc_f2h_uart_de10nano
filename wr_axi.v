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
module wr_axi #(
	WR_AXI_ADDR_WIDTH = 32,
	WR_AXI_BUS_WIDTH = 32,
	WR_AXI_MAX_BURST_LEN = 1
)(
	input clock,
	input reset,
	
	input enable,
	input [WR_AXI_ADDR_WIDTH-1:0] addr,
	input [WR_AXI_BUS_WIDTH*WR_AXI_MAX_BURST_LEN-1:0] data,
	input [3:0] burst_len,
	input [2:0] burst_size,
	input [3:0] burst_mask,
	output reg [1:0] status,  // 0 = ready, 1 = wait, 2 = completed ok, 3 = completed error
	
	// Connection to the AXI interface slave..
	// Address write channel registers
	output reg [WR_AXI_ADDR_WIDTH-1:0] aw_addr,
	output reg [3:0] aw_len,
	output reg [2:0] aw_size,
	output reg [1:0] aw_burst,
	output reg [2:0] aw_prot,
	output reg aw_valid,
	input aw_ready,
	// Write data channel registers
	output reg [WR_AXI_BUS_WIDTH-1:0] w_data,
	output reg [3:0] w_strb,
	output reg w_last,
	output reg w_valid,
	input w_ready,
	// Response channel registers
	input [1:0] b_resp,
	input b_valid,
	output reg b_ready
);
	reg [3:0] burst_count;
	reg w_valid2;

	always @ (posedge clock or posedge reset) begin
		if(reset) begin
			aw_valid <= 0;
			w_valid <= 0;
			w_valid2 <= 0;
			b_ready <= 0;
			w_last <= 0;
			status <= 0;
		end
		else begin

			// ========================================================
			// When enabled, set the write address on the AXI interface
			// ========================================================

			if(enable && !status) begin
				burst_count <= 0;
				status <= 1;
				
				aw_addr <= addr;
				aw_len <= burst_len;  // Number of transfer beats = aw_len + 1 (aka burst length)
				aw_size <= burst_size;  // Per transfer size = 2^aw_size (in bytes)
				aw_burst <= 1;  // 1 = auto incrementing burst type
				aw_prot <= 3'b000;
				aw_valid <= 1;
			end

			// ===============================================
			// When ready and valid, start the write operation
			// ===============================================			

			if(aw_ready && aw_valid) begin
				aw_valid <= 0;

				w_strb <= burst_mask;  // Transfer write mask
				w_valid2 <= 1;
			end

			// =====================================================
			// When ready and valid, write data on the AXI interface
			// =====================================================			

			if(w_ready && w_valid2) begin
				// End of burst?
				if(burst_count >= aw_len) begin
					w_last <= 1;
					b_ready <= 1;
					w_valid2 <= 0;
				end

				w_data <= data[WR_AXI_BUS_WIDTH*burst_count +: WR_AXI_BUS_WIDTH];
				w_valid <= 1;
				burst_count <= burst_count + 1;
			end

			// =======================================================
			// When last data is transferred, stop the write operation
			// =======================================================

			if(b_ready && w_last) begin
				w_last <= 0;
				w_valid <= 0;
			end

			// =============================================
			// When ready and valid, read the burst response
			// =============================================

			if(b_ready && b_valid) begin
				status <= (b_resp >= 2) ? 3 : 2;  // Check for error (2'b10 or 2'b11). Set 3 = error, 2 = ok
				b_ready <= 0;
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
