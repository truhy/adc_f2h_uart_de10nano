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
	Version  : 20230921
	
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
		awlen = number of bursts (aka blocks) to transfer.  Formula: actual_length = awlen + 1
		awsize = size of a burst (aka block) transfer.  Formula: size_bytes = 2^awsize
		The parameter AXI_WR_MAX_BURST_LEN is the maximum burst length allowed (number of burst
		transfers), set to a value within the range 1 to 16 (AXI-3).
		
	References:
		AXI specifications:
			https://www.arm.com/architecture/system-architectures/amba/amba-specifications
		Version B is AXI-3:
			https://developer.arm.com/documentation/ihi0022/b
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
	input [1:0] burst_type,
	input [1:0] lock,
	input [3:0] cache,
	input [2:0] prot,
	input [4:0] user,
	input [AXI_WR_BUS_WIDTH/8-1:0] strb,
	output reg [1:0] status,  // 0 = ready, 1 = wait, 2 = completed ok, 3 = error
	
	// Connection to the AXI interface slave..
	// Address write channel registers
	output [AXI_WR_ID_WIDTH-1:0] awid,
	output [AXI_WR_ADDR_WIDTH-1:0] awaddr,
	output [3:0] awlen,
	output [2:0] awsize,
	output [1:0] awburst,
	output [1:0] awlock,
	output [3:0] awcache,
	output [2:0] awprot,
	output [4:0] awuser,
	output reg awvalid,
	input awready,
	// Write data channel registers
	output [AXI_WR_ID_WIDTH-1:0] wid,
	output [AXI_WR_BUS_WIDTH-1:0] wdata,
	output [AXI_WR_BUS_WIDTH/8-1:0] wstrb,
	output reg wlast,
	output reg wvalid,
	input wready,
	// Response channel registers
	input [AXI_WR_ID_WIDTH-1:0] bid,
	input [1:0] bresp,
	input bvalid,
	output reg bready
);
	`include "axi_def.vh"

	reg [3:0] burst_count;
	
	// Assign AXI master signals to slave signals
	assign awid = id;                         // Write transaction ID tag
	assign awaddr = addr;                     // Starting write address
	assign awlen = burst_len;                 // Number of bursts transfers. Formula: burst_len = number_of_transfers - 1
	assign awsize = burst_size;               // Burst transfer size. Formula: transfer_size = 2^burst_size (in bytes)
	assign awburst = burst_type;
	assign awlock = lock;
	assign awcache = cache;
	assign awprot = prot;
	assign awuser = user;
	assign wid = id;
	assign wstrb = strb;
	assign wdata = data[burst_count*AXI_WR_BUS_WIDTH +: AXI_WR_BUS_WIDTH];
	
	always @ (posedge clock or negedge reset_n) begin
		if(!reset_n) begin
			awvalid <= 0;
			wvalid <= 0;
			bready <= 0;
			wlast <= 0;
			status <= 0;
		end
		else begin

			// ================================
			// Address write transaction: start
			// ================================

			if(enable && !status) begin
				burst_count <= 0;
				status <= 1;
				awvalid <= 1;  // Master asserts awvalid to indicate the address value is valid and can be transferred
			end

			// ===========================================
			// Address write transaction: wait for ready
			// Write transaction: start
			// ===========================================

			if(awvalid && awready) begin  // Wait for the slave to assert awready, which indicates it is ready to receive the address value
				awvalid <= 0;
				
				// Write burst is at the last write?
				if(burst_count == awlen) begin  // Terminate on last burst count
					wlast <= 1;
					bready <= 1;
				end
				wvalid <= 1;  // Master asserts wvalid to indicate the data value is valid and can be transferred
			end

			// =================================
			// Write transaction: wait for ready
			// =================================

			if(wvalid && wready) begin  // Wait for the slave to assert wready, which indicates it is ready to receive the data value
				// Burst transfers completed? (i.e. no more data to write?)
				if(wlast && bready) begin
					// Stop the write operation
					wlast <= 0;
					wvalid <= 0;
				end
				else begin
					// Continue to write the next data
					// The next transfer is the last one?
					if((burst_count + 1) == awlen) begin  // Terminate on last burst count
						// We need to set these flags to indicate the last burst transfer
						wlast <= 1;
						bready <= 1;
					end
					burst_count <= burst_count + 1;
				end
			end
			
			// ==========================================
			// Write response transaction: Wait for valid
			// Note: b stands for buffered
			// ==========================================

			// No need to check bid, leave that to an arbiter to handle
			//if(bid == id && bready && bvalid) begin
			if(bready && bvalid) begin  // Wait for the slave to assert bvalid, which indicates response value is valid and can be transferred
				status <= (bresp >= `AXI_BRESP_SLVERR) ? 3 : 2;  // Check for error. Set 3 = error, 2 = ok
				bready <= 0;
			end
				
			// ==================
			// When done, restart
			// ==================

			if(status >= 2) begin
				status <= 0;
			end
		end
	end
endmodule
