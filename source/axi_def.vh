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
	Version  : 20240423
	
	Description:
		AXI-3 definitions.
		
	References:
		AXI specifications:
			https://www.arm.com/architecture/system-architectures/amba/amba-specifications
		Version B is AXI-3:
			https://developer.arm.com/documentation/ihi0022/b
*/

`ifndef AXI_DEF_VH
`define AXI_DEF_VH

// Burst type
`define AXI_AXBURST_TYPE_FIXED 2'b00
`define AXI_AXBURST_TYPE_INCR  2'b01
`define AXI_AXBURST_TYPE_WRAP  2'b10
`define AXI_AXBURST_TYPE_RES   2'b11

// Burst len
`define AXI_AXBURST_LEN_1  0
`define AXI_AXBURST_LEN_2  1
`define AXI_AXBURST_LEN_3  2
`define AXI_AXBURST_LEN_4  3
`define AXI_AXBURST_LEN_5  4
`define AXI_AXBURST_LEN_6  5
`define AXI_AXBURST_LEN_7  6
`define AXI_AXBURST_LEN_8  7
`define AXI_AXBURST_LEN_9  8
`define AXI_AXBURST_LEN_10 9
`define AXI_AXBURST_LEN_11 10
`define AXI_AXBURST_LEN_12 11
`define AXI_AXBURST_LEN_13 12
`define AXI_AXBURST_LEN_14 13
`define AXI_AXBURST_LEN_15 14
`define AXI_AXBURST_LEN_16 15

// Burst size
`define AXI_AXBURST_SIZE_8    0
`define AXI_AXBURST_SIZE_16   1
`define AXI_AXBURST_SIZE_32   2
`define AXI_AXBURST_SIZE_64   3
`define AXI_AXBURST_SIZE_128  4
`define AXI_AXBURST_SIZE_256  5
`define AXI_AXBURST_SIZE_512  6
`define AXI_AXBURST_SIZE_1024 7

// Write strobe
`define AXI_WSTRB_SIZE_8    {  1{1'b1}}
`define AXI_WSTRB_SIZE_16   {  2{1'b1}}
`define AXI_WSTRB_SIZE_32   {  4{1'b1}}
`define AXI_WSTRB_SIZE_64   {  8{1'b1}}
`define AXI_WSTRB_SIZE_128  { 16{1'b1}}
`define AXI_WSTRB_SIZE_256  { 32{1'b1}}
`define AXI_WSTRB_SIZE_512  { 64{1'b1}}
`define AXI_WSTRB_SIZE_1024 {128{1'b1}}

// Atomic access lock
// Cyclone V SoC supports only normal and exclusive
// Exclusive is only supported with non-coherent accesses, i.e. non-cacheable accesses
`define AXI_AXLOCK_NORMAL    2'b00
`define AXI_AXLOCK_EXCLUSIVE 2'b01
`define AXI_AXLOCK_LOCKED    2'b10
`define AXI_AXLOCK_RESERVED  2'b11

// If using the ACP these must match with the MMU attributes used the HPS application
// Outer cache (L2) support
// Bufferable, bit[0]: interconnect can delay transaction before reaching its destination; most relevant to writes
// Cacheable, bit[1]: cacheable transaction indicator
// Read Allocate, bit[2]: a cache miss allocates space for the read data from system memory
// Write Allocate, bit[3]: a cache miss allocates space for the write data from the initiator
// Legend:
//   NONE = NonCacheable and NonBufferable (no cache)
//   C = Cacheable
//   B = Bufferable
//   WB = Write Back
//   WT = Write Through
//   RA = Read Allocation
//   WA = Write Allocation
//   A = Read and Write Allocation
`define AXI_AXCACHE_NONE    4'b0000
`define AXI_AXCACHE_B       4'b0001
`define AXI_AXCACHE_C       4'b0010
`define AXI_AXCACHE_C_B     4'b0011
`define AXI_AXCACHE_C_WT_RA 4'b0110
`define AXI_AXCACHE_C_WB_RA 4'b0111
`define AXI_AXCACHE_C_WT_WA 4'b1010
`define AXI_AXCACHE_C_WB_WA 4'b1011
`define AXI_AXCACHE_C_WT_A  4'b1110
`define AXI_AXCACHE_C_WB_A  4'b1111

// If using the ACP these must match with the MMU attributes used the HPS application
// User bits:
// Contains the Inner cache (L1) attributes and Shared attribute
// Shared attribute is bit 0:
//   ARUSER[0] = 0 = Not shared
//   ARUSER[0] = 1 = Shared
// Inner attributes, ARUSER[4:1] (bits 1 to 4):
//   SO    = b0000 = Strongly Ordered
//   DE    = b0001 = Device
//   NM_NC = b0011 = Normal Memory NonCacheable
//   WT    = b0110 = Write Through
//   WB    = b0111 = Write Back
//   WB_WA = b1111 = Write Back and Write Allocate
// Note: When the processors cache is on, if AXCACHE[1] == 1 && AXUSER[0] == 1 then coherent request, else non-coherent request.
//       If processors cache is off, above has no effect because without cache memory content is coherent anyway
// For more info, see Cortex-A9 MPCore Technical Reference Manual: https://developer.arm.com/documentation/ddi0407/i/?lang=en
// In the manual search for aruser or awuser
`define AXI_AXUSER_NOTSHARED    5'b00000
`define AXI_AXUSER_SHARED_SO    5'b00001
`define AXI_AXUSER_SHARED_DE    5'b00011
`define AXI_AXUSER_SHARED_NM_NC 5'b00111
`define AXI_AXUSER_SHARED_WT    5'b01101
`define AXI_AXUSER_SHARED_WB    5'b01111
`define AXI_AXUSER_SHARED_WB_WA 5'b11111

// If using the ACP these must match with the MMU attributes used the HPS application
// Protection unit support:
// Must match with the MMU attributes
//   D  = Data access
//   I  = Instruction access
//   SE = Secure access
//   NS = Non-Secure access
//   N  = Normal access
//   P  = Privilege access
`define AXI_AXPROT_D_SE_N 3'b000
`define AXI_AXPROT_D_SE_P 3'b001
`define AXI_AXPROT_D_NS_N 3'b010
`define AXI_AXPROT_D_NS_P 3'b011
`define AXI_AXPROT_I_SE_N 3'b100
`define AXI_AXPROT_I_SE_P 3'b101
`define AXI_AXPROT_I_NS_N 3'b110
`define AXI_AXPROT_I_NS_P 3'b111

// Read response
`define AXI_RRESP_OKAY   2'b00
`define AXI_RRESP_EXOKAY 2'b01
`define AXI_RRESP_SLVERR 2'b10
`define AXI_RRESP_DECERR 2'b11

// Write response
`define AXI_BRESP_OKAY   2'b00
`define AXI_BRESP_EXOKAY 2'b01
`define AXI_BRESP_SLVERR 2'b10
`define AXI_BRESP_DECERR 2'b11

`endif
