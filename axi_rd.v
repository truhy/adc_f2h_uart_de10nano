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
		Helper module providing a simpler interface to read from an AXI-3 slave (ARM AMBA interconnect interface).
	
	User parameter ports:
		enable = 0 = idle, 1 = enable AXI transactions
		id = read transaction ID (this will set the Read Address ID and Read ID)
		addr = starting address to read from AXI
		data = the data read from AXI
		burst_len = number of data transfers (number of reads) per AXI transaction, and is a value between 0 to 15:
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
		status = 0 = ready, 1 = wait, 2 = completed ok, 3 = error
	
	AXI spec notes:
		aw_len = number of bursts (aka blocks) to transfer.  Formula: actual_length = aw_len + 1
		aw_size = size of a burst (aka block) transfer.  Formula: size_bytes = 2^aw_size
		The parameter AXI_WR_MAX_BURST_LEN is the maximum burst length allowed (number of burst
		transfers), set to a value within the range 1 to 16 (AXI-3).
*/
module axi_rd #(
	parameter AXI_RD_ID_WIDTH = 8,
	parameter AXI_RD_ADDR_WIDTH = 32,
	parameter AXI_RD_BUS_WIDTH = 32,
	parameter AXI_RD_MAX_BURST_LEN = 1
)(
	input clock,
	input reset_n,
	
	input enable,
	input [AXI_RD_ID_WIDTH-1:0] id,
	input [AXI_RD_ADDR_WIDTH-1:0] addr,
	output reg [AXI_RD_MAX_BURST_LEN*AXI_RD_BUS_WIDTH-1:0] data,
	input [3:0] burst_len,
	input [2:0] burst_size,
	output reg [1:0] status,  // 0 = ready, 1 = wait, 2 = completed ok, 3 = error
	
	// Connection to the AXI interface slave..
	// Address read channel registers
	output [AXI_RD_ID_WIDTH-1:0] ar_id,
	output [AXI_RD_ADDR_WIDTH-1:0] ar_addr,
	output [3:0] ar_len,
	output [2:0] ar_size,
	output [1:0] ar_burst,
	output [2:0] ar_prot,
	output reg ar_valid,
	input ar_ready,
	// Read data channel registers
	input [AXI_RD_ID_WIDTH-1:0] r_id,
	input [AXI_RD_BUS_WIDTH-1:0] r_data,
	input r_last,
	input [1:0] r_resp,
	input r_valid,
	output reg r_ready
);
	reg [3:0] burst_count;
	reg error;

	`define RD_BURST_TYPE_FIXED 2'b00
	`define RD_BURST_TYPE_INCR  2'b01
	`define RD_BURST_TYPE_WRAP  2'b10
	`define RD_BURST_TYPE_RES   2'b11
	
	`define RD_RESP_OKAY   2'b00
	`define RD_RESP_EXOKAY 2'b01
	`define RD_RESP_SLVERR 2'b10
	`define RD_RESP_DECERR 2'b11

	// Assign AXI master signals to slave signals
	assign ar_id = id;                      // Read transaction ID tag
	assign ar_addr = addr;                  // Starting read address
	assign ar_len = burst_len;              // Number of transfers: ar_len = number_of_transfers - 1
	assign ar_size = burst_size;            // Transfer size: transfer_size = 2^ar_size (in bytes)
	assign ar_burst = `RD_BURST_TYPE_INCR;  // Auto incrementing burst type
	assign ar_prot = 0;

	always @ (posedge clock or negedge reset_n) begin
		if(!reset_n) begin
			//data <= 'b0;  // { (AXI_RD_MAX_BURST_LEN*AXI_RD_BUS_WIDTH){1'b0} };
			ar_valid <= 0;
			r_ready <= 0;
			status <= 0;
		end
		else begin

			// ===============================================================================================================
			// Address read transaction: When enabled, setup the read details and set address read valid so AXI will read them
			// ===============================================================================================================

			if(enable && !status) begin
				//data <= 'b0;  // { (AXI_RD_MAX_BURST_LEN*AXI_RD_BUS_WIDTH){1'b0} };
				burst_count <= 0;
				error <= 0;
				status <= 1;
				ar_valid <= 1;  // Set ar_valid high so the receiver transfers the read details
			end

			// ==============================================================================================================================
			// Address read transaction: Wait for AXI to signal it got the read details, then set read ready to start a read data transaction
			// ==============================================================================================================================

			if(ar_ready && ar_valid) begin
				ar_valid <= 0;
				r_ready <= 1;
			end

			// ====================================================================================
			// Read transaction: Wait for AXI to signal data ready, then we read and store the data
			// ====================================================================================
		
			// No need to check r_id, leave that to an arbiter to handle
			//if(r_id == id && r_ready && r_valid) begin
			if(r_ready && r_valid) begin
				// Store a burst transfer to a register at the correct index
				data[burst_count*AXI_RD_BUS_WIDTH +: AXI_RD_BUS_WIDTH] <= r_data;
				
				// Burst transfers completed? (i.e. no more data to read?) Note AXI-3 doesn't allow early burst termination
				if(r_last || burst_count >= ar_len) begin  // Check also burst_count incase AXI slaves don't implement r_last properly
					// Stop the read operation
					status <= (r_resp >= `RD_RESP_SLVERR || error) ? 3 : 2;  // Check for error. Set 3 = error, 2 = ok
					r_ready <= 0;
				end
				else begin
					// Continue to read the next data
					if(r_resp >= `RD_RESP_SLVERR) error <= 1;  // Check for error
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
