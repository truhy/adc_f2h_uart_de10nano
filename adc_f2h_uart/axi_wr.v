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
	Version  : 20221222
	
	Description:
		Helper module providing a simpler interface to write to an AXI-3 slave (ARM AMBA interconnect interface).
	
	User parameter ports:
		enable = 0 = idle, 1 = enable AXI transactions
		id = write transaction ID (write address ID, write ID and write response ID)
		addr = starting address to write to AXI
		data = the data to write to AXI
		burst_len = number of data transfers (number of writes) per AXI transaction, and is a value between 0 to 15:
			burst_len = number of transfer(s)
			0 = 1
			1 = 2
			2 = 3
			...
			14 = 15
			15 = 16
		burst_size = size of each data transfer, encoded as 2^burst_size, and is a value between 0 to 7:
			burst_size = bytes per transfer
			0 = 1
			1 = 2
			2 = 4
			3 = 8
			4 = 16
			5 = 32
			6 = 64
			7 = 128
		strb = each bit corresponds to each byte of the data transfer that will be transferred.
		       For each bit in the mask: 1 = byte will be transferred, 0 = byte will not be transferred
		status = 0 = ready, 1 = wait, 2 = completed ok, 3 = error
	
	AXI spec notes:
		aw_len = number of bursts (aka blocks) to transfer.  Formula: actual_length = aw_len + 1
		aw_size = size of a burst (aka block) transfer.  Formula: size_bytes = 2^aw_size
		The parameter AXI_WR_MAX_BURST_LEN is the maximum burst length allowed (number of burst
		transfers), set to a value within the range 1 to 16 (AXI-3).
*/
module axi_wr #(
	parameter AXI_WR_ID_WIDTH = 8,
	parameter AXI_WR_ADDR_WIDTH = 32,
	parameter AXI_WR_BUS_WIDTH = 32,
	parameter AXI_WR_MAX_BURST_LEN = 1
)(
	input clock,
	input reset_n,
	
	input enable,
	input [AXI_WR_ID_WIDTH-1:0] id,
	input [AXI_WR_ADDR_WIDTH-1:0] addr,
	input [AXI_WR_MAX_BURST_LEN*AXI_WR_BUS_WIDTH-1:0] data,
	input [3:0] burst_len,
	input [2:0] burst_size,
	input [AXI_WR_BUS_WIDTH/8-1:0] strb,
	output reg [1:0] status,  // 0 = ready, 1 = wait, 2 = completed ok, 3 = error
	
	// Connection to the AXI interface slave..
	// Address write channel registers
	output [AXI_WR_ID_WIDTH-1:0] aw_id,
	output [AXI_WR_ADDR_WIDTH-1:0] aw_addr,
	output [3:0] aw_len,
	output [2:0] aw_size,
	output [1:0] aw_burst,
	output [2:0] aw_prot,
	output reg aw_valid,
	input aw_ready,
	// Write data channel registers
	output [AXI_WR_ID_WIDTH-1:0] w_id,
	output [AXI_WR_BUS_WIDTH-1:0] w_data,
	output [AXI_WR_BUS_WIDTH/8-1:0] w_strb,
	output reg w_last,
	output reg w_valid,
	input w_ready,
	// Response channel registers
	input [AXI_WR_ID_WIDTH-1:0] b_id,
	input [1:0] b_resp,
	input b_valid,
	output reg b_ready
);
	reg [3:0] burst_count;
	
	`define WR_BURST_TYPE_FIXED 2'b00
	`define WR_BURST_TYPE_INCR  2'b01
	`define WR_BURST_TYPE_WRAP  2'b10
	`define WR_BURST_TYPE_RES   2'b11
	
	`define B_RESP_OKAY   2'b00
	`define B_RESP_EXOKAY 2'b01
	`define B_RESP_SLVERR 2'b10
	`define B_RESP_DECERR 2'b11
	
	// Assign AXI master signals to slave signals
	assign aw_id = id;                      // Write transaction ID tag
	assign aw_addr = addr;                  // Starting write address
	assign aw_len = burst_len;              // Number of transfers: aw_len = number_of_transfers - 1
	assign aw_size = burst_size;            // Transfer size: transfer_size = 2^aw_size (in bytes)
	assign aw_burst = `WR_BURST_TYPE_INCR;  // Auto incrementing burst type
	assign aw_prot = 0;
	assign w_id = id;
	assign w_strb = strb;
	assign w_data = data[(burst_count-1)*AXI_WR_BUS_WIDTH +: AXI_WR_BUS_WIDTH];
	
	always @ (posedge clock or negedge reset_n) begin
		if(!reset_n) begin
			aw_valid <= 0;
			w_valid <= 0;
			b_ready <= 0;
			w_last <= 0;
			status <= 0;
		end
		else begin

			// ==================================================================================================================
			// Address write transaction: When enabled, setup the write details and set address write valid so AXI will read them
			// ==================================================================================================================

			if(enable && !status) begin
				burst_count <= 0;
				status <= 1;
				aw_valid <= 1;  // Set ar_valid high so the receiver transfers the read details
			end

			// ==================================================================================================================================
			// Address write transaction: Wait for AXI to signal it got the write details, then set write valid to start a write data transaction
			// ==================================================================================================================================

			if(aw_ready && aw_valid) begin
				aw_valid <= 0;
				
				// Write burst is at the last write?
				if(burst_count == aw_len) begin
					w_last <= 1;
					b_ready <= 1;
				end
				burst_count <= burst_count + 1;
				w_valid <= 1;
			end

			// ================================================================================
			// Write transaction: Wait for AXI to signal write ready, then we assign write data
			// ================================================================================

			if(w_ready && w_valid) begin
				// Burst transfers completed? (i.e. no more data to write?) Note AXI-3 doesn't allow early burst termination
				if(w_last && b_ready) begin
					// Stop the write operation
					w_last <= 0;
					w_valid <= 0;
				end
				else begin
					// Continue to write the next data
					// The next transfer is the last one?
					if(burst_count == aw_len) begin
						// We need to set these flags to indicate the last burst transfer
						w_last <= 1;
						b_ready <= 1;
					end
					burst_count <= burst_count + 1;
				end
			end
			
			// ===============================================================================================
			// Write response transaction: Wait for AXI to signal response valid, then read and store response
			// ===============================================================================================

			// No need to check b_id, leave that to an arbiter to handle
			//if(b_id == id && b_ready && b_valid) begin
			if(b_ready && b_valid) begin
				status <= (b_resp >= `B_RESP_SLVERR) ? 3 : 2;  // Check for error. Set 3 = error, 2 = ok
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
