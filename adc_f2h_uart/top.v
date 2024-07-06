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
	Target   : For the DE10-Nano development kit board (SoC FPGA Cyclone V)
	Version  : 20240608

	A hardware design showing the FPGA portion reading the ADC LTC2308 and directly sending the sample value
	as a serial message to the HPS UART controller (DE10-Nano's UART-USB).

	See readme.md for more information.
*/
module top(
	// FPGA clock
	input FPGA_CLK1_50,
	input FPGA_CLK2_50,
	input FPGA_CLK3_50,
	
	// FPGA ADC. FPGA pins wired to LTC2308 (SPI)
	output ADC_CONVST,
	output ADC_SCK,
	output ADC_SDI,
	input  ADC_SDO,
	
	// FPGA Arduino IO. FPGA pins wired to female headers
	inout [15:0] ARDUINO_IO,
	inout        ARDUINO_RESET_N,
	
	// FPGA GPIO. FPGA pins wired to 2x male headers
	inout [35:0] GPIO_0,
	inout [35:0] GPIO_1,
	
	// FPGA HDMI. FPGA pins to HDMI transmitter chip (Analog Devices ADV7513BSWZ)
	inout          HDMI_I2C_SCL,
	inout          HDMI_I2C_SDA,
	inout          HDMI_I2S,
	inout          HDMI_LRCLK,
	inout          HDMI_MCLK,
	inout          HDMI_SCLK,
	output         HDMI_TX_CLK,
	output [23: 0] HDMI_TX_D,
	output         HDMI_TX_DE,
	output         HDMI_TX_HS,
	input          HDMI_TX_INT,
	output         HDMI_TX_VS,

	// FPGA push buttons, LEDs and slide switches
	input  [1:0] KEY,  // FPGA pins to tactile switches
	output [7:0] LED,  // FPGA pins to LEDs
	input  [3:0] SW,   // FPGA pins to slide switches
	
	// HPS user key and LED
	inout HPS_KEY,
	inout HPS_LED,

	// HPS DDR-3 SDRAM. HPS pins to DDR3 1GB = 2x512MB chips
	output [14:0] HPS_DDR3_ADDR,
	output [2:0]  HPS_DDR3_BA,
	output        HPS_DDR3_CAS_N,
	output        HPS_DDR3_CKE,
	output        HPS_DDR3_CK_N,
	output        HPS_DDR3_CK_P,
	output        HPS_DDR3_CS_N,
	output [3:0]  HPS_DDR3_DM,
	inout  [31:0] HPS_DDR3_DQ,
	inout  [3:0]  HPS_DDR3_DQS_N,
	inout  [3:0]  HPS_DDR3_DQS_P,
	output        HPS_DDR3_ODT,
	output        HPS_DDR3_RAS_N,
	output        HPS_DDR3_RESET_N,
	input         HPS_DDR3_RZQ,
	output        HPS_DDR3_WE_N,
	
	// HPS SD-CARD. HPS pins wired to micro SD card slot
	output      HPS_SD_CLK,
	inout       HPS_SD_CMD,
	inout [3:0] HPS_SD_DATA,

	// HPS UART (UART-USB). HPS pins wired to chip FTDI FT232R
	input  HPS_UART_RX,
	output HPS_UART_TX,
	inout  HPS_CONV_USB_N,
	
	// HPS USB OTG. HPS pins wired to the USB PHY chip (Microchip USB3300)
	input       HPS_USB_CLKOUT,
	inout [7:0] HPS_USB_DATA,
	input       HPS_USB_DIR,
	input       HPS_USB_NXT,
	output      HPS_USB_STP,
	
	// HPS EMAC. HPS pins wired to the gigabit ethernet PHY chip (Microchip KSZ9031RNX)
	output       HPS_ENET_GTX_CLK,
	output       HPS_ENET_MDC,
	inout        HPS_ENET_MDIO,
	input        HPS_ENET_RX_CLK,
	input [3:0]  HPS_ENET_RX_DATA,
	input        HPS_ENET_RX_DV,
	output [3:0] HPS_ENET_TX_DATA,
	output       HPS_ENET_TX_EN,
	inout        HPS_ENET_INT_N,

	// HPS SPI. HPS pins wired to the LTC 2x7 connector
	output HPS_SPIM_CLK,
	input  HPS_SPIM_MISO,
	output HPS_SPIM_MOSI,
	inout  HPS_SPIM_SS,

	// HPS GPIO. HPS pin wired to the LTC 2x7 connector (note, this cannot be used because the 0ohm resistor is not populated)
	//inout HPS_LTC_GPIO,
	
	// HPS I2C 1. HPS pins wired to the LTC 2x7 connector
	inout HPS_I2C1_SCLK,
	inout HPS_I2C1_SDAT,
	
	// HPS I2C 0. HPS pins wired to the ADXL345 accelerometer
	inout HPS_I2C0_SCLK,
	inout HPS_I2C0_SDAT,
	inout HPS_GSENSOR_INT  // ADXL345 interrupt 1 output (pin 9)
);
	// AXI parameters
	localparam F2H_AXI_BRIDGE_SLAVE_BUS_WIDTH = 32;  // Should match the HPS AXI bridge FPGA-to-HPS interface width in Platform Designer

	// ================
	// HPS (SoC) module
	// ================

	// Wires for the PLL clock and reset
	wire pll0_clock0;
	wire pll0_clock1;
	wire pll0_locked;
	wire hps_reset_n;
	wire master_reset_n = hps_reset_n;
	//wire master_reset_n = hps_reset_n | pll0_locked;  // Stay in reset if pll is not locked

	// Wires for the AXI interface to the FPGA-to-HPS Bridge (provides FPGA access to the HPS 4GB address map)
	wire [7:0]  f2h_axi_slave_awid;
	wire [31:0] f2h_axi_slave_awaddr;
	wire [3:0]  f2h_axi_slave_awlen;
	wire [2:0]  f2h_axi_slave_awsize;
	wire [1:0]  f2h_axi_slave_awburst;
	wire [1:0]  f2h_axi_slave_awlock;
	wire [3:0]  f2h_axi_slave_awcache;
	wire [2:0]  f2h_axi_slave_awprot;
	wire        f2h_axi_slave_awvalid;
	wire        f2h_axi_slave_awready;
	wire [4:0]  f2h_axi_slave_awuser;
	wire [7:0]  f2h_axi_slave_wid;
	wire [F2H_AXI_BRIDGE_SLAVE_BUS_WIDTH-1:0] f2h_axi_slave_wdata;
	wire [F2H_AXI_BRIDGE_SLAVE_BUS_WIDTH/8-1:0] f2h_axi_slave_wstrb;
	wire        f2h_axi_slave_wlast;
	wire        f2h_axi_slave_wvalid;
	wire        f2h_axi_slave_wready;
	wire [7:0]  f2h_axi_slave_bid;
	wire [1:0]  f2h_axi_slave_bresp;
	wire        f2h_axi_slave_bvalid;
	wire        f2h_axi_slave_bready;
	wire [7:0]  f2h_axi_slave_arid;
	wire [31:0] f2h_axi_slave_araddr;
	wire [3:0]  f2h_axi_slave_arlen;
	wire [2:0]  f2h_axi_slave_arsize;
	wire [1:0]  f2h_axi_slave_arburst;
	wire [1:0]  f2h_axi_slave_arlock;
	wire [3:0]  f2h_axi_slave_arcache;
	wire [2:0]  f2h_axi_slave_arprot;
	wire        f2h_axi_slave_arvalid;
	wire        f2h_axi_slave_arready;
	wire [4:0]  f2h_axi_slave_aruser;
	wire [7:0]  f2h_axi_slave_rid;
	wire [F2H_AXI_BRIDGE_SLAVE_BUS_WIDTH-1:0] f2h_axi_slave_rdata;
	wire [1:0]  f2h_axi_slave_rresp;
	wire        f2h_axi_slave_rlast;
	wire        f2h_axi_slave_rvalid;
	wire        f2h_axi_slave_rready;

	// HPS (SoC) instance
	soc_system u0(
		// Clock
		.clk_clk(FPGA_CLK1_50),
		.pll_0_outclk0_clk(pll0_clock0),
		.pll_0_outclk1_clk(pll0_clock1),
		.pll_0_locked_export(pll0_locked),

		// HPS DDR-3 SDRAM pin connections
		.memory_mem_a(HPS_DDR3_ADDR),
		.memory_mem_ba(HPS_DDR3_BA),
		.memory_mem_ck(HPS_DDR3_CK_P),
		.memory_mem_ck_n(HPS_DDR3_CK_N),
		.memory_mem_cke(HPS_DDR3_CKE),
		.memory_mem_cs_n(HPS_DDR3_CS_N),
		.memory_mem_ras_n(HPS_DDR3_RAS_N),
		.memory_mem_cas_n(HPS_DDR3_CAS_N),
		.memory_mem_we_n(HPS_DDR3_WE_N),
		.memory_mem_reset_n(HPS_DDR3_RESET_N),
		.memory_mem_dq(HPS_DDR3_DQ),
		.memory_mem_dqs(HPS_DDR3_DQS_P),
		.memory_mem_dqs_n(HPS_DDR3_DQS_N),
		.memory_mem_odt(HPS_DDR3_ODT),
		.memory_mem_dm(HPS_DDR3_DM),
		.memory_oct_rzqin(HPS_DDR3_RZQ),
		
		// HPS SD-card pin connections
		.hps_io_hps_io_sdio_inst_CMD(HPS_SD_CMD),
		.hps_io_hps_io_sdio_inst_D0(HPS_SD_DATA[0]),
		.hps_io_hps_io_sdio_inst_D1(HPS_SD_DATA[1]),
		.hps_io_hps_io_sdio_inst_CLK(HPS_SD_CLK),
		.hps_io_hps_io_sdio_inst_D2(HPS_SD_DATA[2]),
		.hps_io_hps_io_sdio_inst_D3(HPS_SD_DATA[3]),
		
		// HPS UART0 (UART-USB) pin connections
		.hps_io_hps_io_uart0_inst_RX(HPS_UART_RX),
		.hps_io_hps_io_uart0_inst_TX(HPS_UART_TX),
		
		// HPS EMAC1 (Ethernet) pin connections
		.hps_io_hps_io_emac1_inst_TX_CLK(HPS_ENET_GTX_CLK),
		.hps_io_hps_io_emac1_inst_TXD0(HPS_ENET_TX_DATA[0]),
		.hps_io_hps_io_emac1_inst_TXD1(HPS_ENET_TX_DATA[1]),
		.hps_io_hps_io_emac1_inst_TXD2(HPS_ENET_TX_DATA[2]),
		.hps_io_hps_io_emac1_inst_TXD3(HPS_ENET_TX_DATA[3]),
		.hps_io_hps_io_emac1_inst_RXD0(HPS_ENET_RX_DATA[0]),
		.hps_io_hps_io_emac1_inst_MDIO(HPS_ENET_MDIO),
		.hps_io_hps_io_emac1_inst_MDC(HPS_ENET_MDC),
		.hps_io_hps_io_emac1_inst_RX_CTL(HPS_ENET_RX_DV),
		.hps_io_hps_io_emac1_inst_TX_CTL(HPS_ENET_TX_EN),
		.hps_io_hps_io_emac1_inst_RX_CLK(HPS_ENET_RX_CLK),
		.hps_io_hps_io_emac1_inst_RXD1(HPS_ENET_RX_DATA[1]),
		.hps_io_hps_io_emac1_inst_RXD2(HPS_ENET_RX_DATA[2]),
		.hps_io_hps_io_emac1_inst_RXD3(HPS_ENET_RX_DATA[3]),

		// HPS USB1 2.0 OTG pin connections
		.hps_io_hps_io_usb1_inst_D0(HPS_USB_DATA[0]),
		.hps_io_hps_io_usb1_inst_D1(HPS_USB_DATA[1]),
		.hps_io_hps_io_usb1_inst_D2(HPS_USB_DATA[2]),
		.hps_io_hps_io_usb1_inst_D3(HPS_USB_DATA[3]),
		.hps_io_hps_io_usb1_inst_D4(HPS_USB_DATA[4]),
		.hps_io_hps_io_usb1_inst_D5(HPS_USB_DATA[5]),
		.hps_io_hps_io_usb1_inst_D6(HPS_USB_DATA[6]),
		.hps_io_hps_io_usb1_inst_D7(HPS_USB_DATA[7]),
		.hps_io_hps_io_usb1_inst_CLK(HPS_USB_CLKOUT),
		.hps_io_hps_io_usb1_inst_STP(HPS_USB_STP),
		.hps_io_hps_io_usb1_inst_DIR(HPS_USB_DIR),
		.hps_io_hps_io_usb1_inst_NXT(HPS_USB_NXT),
		
		// HPS SPI1 pin connections
		.hps_io_hps_io_spim1_inst_CLK(HPS_SPIM_CLK),
		.hps_io_hps_io_spim1_inst_MOSI(HPS_SPIM_MOSI),
		.hps_io_hps_io_spim1_inst_MISO(HPS_SPIM_MISO),
		.hps_io_hps_io_spim1_inst_SS0(HPS_SPIM_SS),
		
		// HPS I2C0 pin connections
		.hps_io_hps_io_i2c0_inst_SDA(HPS_I2C0_SDAT),
		.hps_io_hps_io_i2c0_inst_SCL(HPS_I2C0_SCLK),
		
		// HPS I2C1 pin connections
		.hps_io_hps_io_i2c1_inst_SDA(HPS_I2C1_SDAT),
		.hps_io_hps_io_i2c1_inst_SCL(HPS_I2C1_SCLK),
		
		// HPS GPIO pin connections
		.hps_io_hps_io_gpio_inst_GPIO09(HPS_CONV_USB_N),
		.hps_io_hps_io_gpio_inst_GPIO35(HPS_ENET_INT_N),
		//.hps_io_hps_io_gpio_inst_GPIO40(HPS_LTC_GPIO),
		.hps_io_hps_io_gpio_inst_GPIO53(HPS_LED),
		.hps_io_hps_io_gpio_inst_GPIO54(HPS_KEY),
		.hps_io_hps_io_gpio_inst_GPIO61(HPS_GSENSOR_INT),
		
		// AXI interface to FPGA-to-HPS Bridge (4GB address map via L3 Interconnect. See Interconnect Block Diagram in Cyclone V Tech Ref Man.)
		.hps_0_f2h_axi_clock_clk(pll0_clock0),
		.hps_0_f2h_axi_slave_awid(f2h_axi_slave_awid),
		.hps_0_f2h_axi_slave_awaddr(f2h_axi_slave_awaddr),
		.hps_0_f2h_axi_slave_awlen(f2h_axi_slave_awlen),
		.hps_0_f2h_axi_slave_awsize(f2h_axi_slave_awsize),
		.hps_0_f2h_axi_slave_awburst(f2h_axi_slave_awburst),
		.hps_0_f2h_axi_slave_awlock(f2h_axi_slave_awlock),
		.hps_0_f2h_axi_slave_awcache(f2h_axi_slave_awcache),
		.hps_0_f2h_axi_slave_awprot(f2h_axi_slave_awprot),
		.hps_0_f2h_axi_slave_awvalid(f2h_axi_slave_awvalid),
		.hps_0_f2h_axi_slave_awready(f2h_axi_slave_awready),
		.hps_0_f2h_axi_slave_awuser(f2h_axi_slave_awuser),
		.hps_0_f2h_axi_slave_wid(f2h_axi_slave_wid),
		.hps_0_f2h_axi_slave_wdata(f2h_axi_slave_wdata),
		.hps_0_f2h_axi_slave_wstrb(f2h_axi_slave_wstrb),
		.hps_0_f2h_axi_slave_wlast(f2h_axi_slave_wlast),
		.hps_0_f2h_axi_slave_wvalid(f2h_axi_slave_wvalid),
		.hps_0_f2h_axi_slave_wready(f2h_axi_slave_wready),
		.hps_0_f2h_axi_slave_bid(f2h_axi_slave_bid),
		.hps_0_f2h_axi_slave_bresp(f2h_axi_slave_bresp),
		.hps_0_f2h_axi_slave_bvalid(f2h_axi_slave_bvalid),
		.hps_0_f2h_axi_slave_bready(f2h_axi_slave_bready),
		.hps_0_f2h_axi_slave_arid(f2h_axi_slave_arid),
		.hps_0_f2h_axi_slave_araddr(f2h_axi_slave_araddr),
		.hps_0_f2h_axi_slave_arlen(f2h_axi_slave_arlen),
		.hps_0_f2h_axi_slave_arsize(f2h_axi_slave_arsize),
		.hps_0_f2h_axi_slave_arburst(f2h_axi_slave_arburst),
		.hps_0_f2h_axi_slave_arlock(f2h_axi_slave_arlock),
		.hps_0_f2h_axi_slave_arcache(f2h_axi_slave_arcache),
		.hps_0_f2h_axi_slave_arprot(f2h_axi_slave_arprot),
		.hps_0_f2h_axi_slave_arvalid(f2h_axi_slave_arvalid),
		.hps_0_f2h_axi_slave_arready(f2h_axi_slave_arready),
		.hps_0_f2h_axi_slave_aruser(f2h_axi_slave_aruser),
		.hps_0_f2h_axi_slave_rid(f2h_axi_slave_rid),
		.hps_0_f2h_axi_slave_rdata(f2h_axi_slave_rdata),
		.hps_0_f2h_axi_slave_rresp(f2h_axi_slave_rresp),
		.hps_0_f2h_axi_slave_rlast(f2h_axi_slave_rlast),
		.hps_0_f2h_axi_slave_rvalid(f2h_axi_slave_rvalid),
		.hps_0_f2h_axi_slave_rready(f2h_axi_slave_rready),

		// Reset
		.hps_0_h2f_reset_reset_n(hps_reset_n),
		.reset_reset_n(hps_reset_n)
	);
	
	// ==========
	// AXI helper
	// ==========
	
	// Helper AXI reader and writer parameters
	localparam AXI_RD_ID_WIDTH = 8;
	localparam AXI_RD_ADDR_WIDTH = 32;
	localparam AXI_RD_BUS_WIDTH = F2H_AXI_BRIDGE_SLAVE_BUS_WIDTH;
	localparam AXI_RD_MAX_BURST_LEN = 1;
	localparam AXI_WR_ID_WIDTH = 8;
	localparam AXI_WR_ADDR_WIDTH = 32;
	localparam AXI_WR_BUS_WIDTH = F2H_AXI_BRIDGE_SLAVE_BUS_WIDTH;
	localparam AXI_WR_MAX_BURST_LEN = 1;
	
	// ==========================
	// AXI helper reader instance
	// ==========================
	
	wire axi_rd_enable;
	reg [AXI_RD_ID_WIDTH-1:0] axi_rd_id;
	wire [AXI_RD_ADDR_WIDTH-1:0] axi_rd_addr;
	wire [AXI_RD_MAX_BURST_LEN*AXI_RD_BUS_WIDTH-1:0] axi_rd_data;
	wire [3:0] axi_rd_burst_len;
	wire [2:0] axi_rd_burst_size;
	wire [1:0] axi_rd_status;
	axi_rd
	#(
		.AXI_RD_ID_WIDTH(AXI_RD_ID_WIDTH),
		.AXI_RD_ADDR_WIDTH(AXI_RD_ADDR_WIDTH),
		.AXI_RD_BUS_WIDTH(AXI_RD_BUS_WIDTH),
		.AXI_RD_MAX_BURST_LEN(AXI_RD_MAX_BURST_LEN)
	)
	axi_rd_0(
		.clock(pll0_clock0),
		.reset_n(master_reset_n),
		
		.enable(axi_rd_enable),
		.id(axi_rd_id),
		.addr(axi_rd_addr),
		.data(axi_rd_data),
		.burst_len(axi_rd_burst_len),
		.burst_size(axi_rd_burst_size),
		.burst_type(`AXI_AXBURST_TYPE_INCR),  // Auto incrementing burst type
		.lock(`AXI_AXLOCK_NORMAL),            // Normal access
		.cache(`AXI_AXCACHE_C_B_A),           // Enable cache coherency support
		.prot(`AXI_AXPROT_D_SE_N),            // Access: Data, secure and normal
		.user(`AXI_AXUSER_SHARED),            // Enable cache coherency support
		.status(axi_rd_status),

		.arid(f2h_axi_slave_arid),
		.araddr(f2h_axi_slave_araddr),
		.arlen(f2h_axi_slave_arlen),
		.arsize(f2h_axi_slave_arsize),
		.arburst(f2h_axi_slave_arburst),
		.arlock(f2h_axi_slave_arlock),
		.arcache(f2h_axi_slave_arcache),
		.arprot(f2h_axi_slave_arprot),
		.aruser(f2h_axi_slave_aruser),
		.arvalid(f2h_axi_slave_arvalid),
		.arready(f2h_axi_slave_arready),
		.rid(f2h_axi_slave_rid),
		.rdata(f2h_axi_slave_rdata),
		.rlast(f2h_axi_slave_rlast),
		.rresp(f2h_axi_slave_rresp),
		.rvalid(f2h_axi_slave_rvalid),
		.rready(f2h_axi_slave_rready)
	);

	// ==========================
	// AXI helper writer instance
	// ==========================

	wire axi_wr_enable;
	reg [AXI_WR_ID_WIDTH-1:0] axi_wr_id;
	wire [AXI_WR_ADDR_WIDTH-1:0] axi_wr_addr;
	wire [AXI_WR_MAX_BURST_LEN*AXI_WR_BUS_WIDTH-1:0] axi_wr_data;
	wire [3:0] axi_wr_burst_len;
	wire [2:0] axi_wr_burst_size;
	wire [AXI_WR_BUS_WIDTH/8-1:0] axi_wr_strb;
	wire [1:0] axi_wr_status;
	axi_wr
	#(
		.AXI_WR_ID_WIDTH(AXI_WR_ID_WIDTH),
		.AXI_WR_ADDR_WIDTH(AXI_WR_ADDR_WIDTH),
		.AXI_WR_BUS_WIDTH(AXI_WR_BUS_WIDTH),
		.AXI_WR_MAX_BURST_LEN(AXI_WR_MAX_BURST_LEN)
	)
	axi_wr_0(
		.clock(pll0_clock0),
		.reset_n(master_reset_n),
		
		.enable(axi_wr_enable),
		.id(axi_wr_id),
		.addr(axi_wr_addr),
		.data(axi_wr_data),
		.burst_len(axi_wr_burst_len),
		.burst_size(axi_wr_burst_size),
		.burst_type(`AXI_AXBURST_TYPE_INCR),  // Auto incrementing burst type
		.lock(`AXI_AXLOCK_NORMAL),            // Normal access
		.cache(`AXI_AXCACHE_C_B_A),           // Enable cache coherency support
		.prot(`AXI_AXPROT_D_SE_N),            // Access: Data, secure and normal
		.user(`AXI_AXUSER_SHARED),            // Enable cache coherency support
		.strb(axi_wr_strb),
		.status(axi_wr_status),
		
		.awid(f2h_axi_slave_awid),
		.awaddr(f2h_axi_slave_awaddr),
		.awlen(f2h_axi_slave_awlen),
		.awsize(f2h_axi_slave_awsize),
		.awburst(f2h_axi_slave_awburst),
		.awlock(f2h_axi_slave_awlock),
		.awcache(f2h_axi_slave_awcache),
		.awprot(f2h_axi_slave_awprot),
		.awuser(f2h_axi_slave_awuser),
		.awvalid(f2h_axi_slave_awvalid),
		.awready(f2h_axi_slave_awready),
		.wid(f2h_axi_slave_wid),
		.wdata(f2h_axi_slave_wdata),
		.wstrb(f2h_axi_slave_wstrb),
		.wlast(f2h_axi_slave_wlast),
		.wvalid(f2h_axi_slave_wvalid),
		.wready(f2h_axi_slave_wready),
		.bid(f2h_axi_slave_bid),
		.bresp(f2h_axi_slave_bresp),
		.bvalid(f2h_axi_slave_bvalid),
		.bready(f2h_axi_slave_bready)
	);
	
	// AXI helper reader wires for passing to uart dev module
	wire axi_rd_enable_uart;
	wire [AXI_RD_ADDR_WIDTH-1:0] axi_rd_addr_uart;
	wire [AXI_RD_MAX_BURST_LEN*AXI_RD_BUS_WIDTH-1:0] axi_rd_data_uart;
	wire [3:0] axi_rd_burst_len_uart;
	wire [2:0] axi_rd_burst_size_uart;
	wire [1:0] axi_rd_status_uart;
	assign axi_rd_enable_uart = axi_rd_enable;
	assign axi_rd_addr_uart = axi_rd_addr;
	assign axi_rd_data_uart = axi_rd_data;
	assign axi_rd_burst_len_uart = axi_rd_burst_len;
	assign axi_rd_burst_size_uart = axi_rd_burst_size;
	assign axi_rd_status_uart = axi_rd_status;
	
	// AXI helper writer wires for passing to uart dev module
	wire axi_wr_enable_uart;
	wire [AXI_WR_ADDR_WIDTH-1:0] axi_wr_addr_uart;
	wire [AXI_WR_MAX_BURST_LEN*AXI_WR_BUS_WIDTH-1:0] axi_wr_data_uart;
	wire [3:0] axi_wr_burst_len_uart;
	wire [2:0] axi_wr_burst_size_uart;
	wire [AXI_WR_BUS_WIDTH/8-1:0] axi_wr_strb_uart;
	wire [1:0] axi_wr_status_uart;
	assign axi_wr_enable_uart = axi_wr_enable;
	assign axi_wr_addr_uart = axi_wr_addr;
	assign axi_wr_data_uart = axi_wr_data;
	assign axi_wr_burst_len_uart = axi_wr_burst_len;
	assign axi_wr_burst_size_uart = axi_wr_burst_size;
	assign axi_wr_strb_uart = axi_wr_strb;
	assign axi_wr_status_uart = axi_wr_status;

	// ===================================
	// HPS UART controller module instance
	// ===================================
	
	reg uart_enable;
	wire [1:0] uart_status;
	reg [7:0] uart_data;
	reg uart_input_type;
	reg [32:0] uart_addr;
	reg [7:0] uart_data_len;
	reg uart_hex;
	reg [7:0] uart_hex_start;
	reg uart_new_line;
	uart_dev #(
		.UART_BASE_ADDR(32'hFFC02000),
		.UART_TX_DATA_BUF_LEN(1),
		.UART_THRE_FIFO_MODE(0),
		.AXI_RD_ADDR_WIDTH(AXI_RD_ADDR_WIDTH),
		.AXI_RD_BUS_WIDTH(AXI_RD_BUS_WIDTH),
		.AXI_RD_MAX_BURST_LEN(AXI_RD_MAX_BURST_LEN),
		.AXI_WR_ADDR_WIDTH(AXI_WR_ADDR_WIDTH),
		.AXI_WR_BUS_WIDTH(AXI_WR_BUS_WIDTH),
		.AXI_WR_MAX_BURST_LEN(AXI_WR_MAX_BURST_LEN)
	) uart_dev_0(
		.clock(pll0_clock0),
		.reset_n(master_reset_n),
		
		.enable(uart_enable),
		.status(uart_status),
		.tx_input_type(uart_input_type),
		.tx_data(uart_data),
		.tx_addr(uart_addr),
		.tx_len(uart_data_len),
		.tx_hex(uart_hex),
		.tx_hex_start(uart_hex_start),
		.tx_new_line(uart_new_line),
		
		.axi_rd_enable(axi_rd_enable_uart),
		.axi_rd_addr(axi_rd_addr_uart),
		.axi_rd_data(axi_rd_data_uart),
		.axi_rd_burst_len(axi_rd_burst_len_uart),
		.axi_rd_burst_size(axi_rd_burst_size_uart),
		.axi_rd_status(axi_rd_status_uart),
		.axi_wr_enable(axi_wr_enable_uart),
		.axi_wr_addr(axi_wr_addr_uart),
		.axi_wr_data(axi_wr_data_uart),
		.axi_wr_burst_len(axi_wr_burst_len_uart),
		.axi_wr_burst_size(axi_wr_burst_size_uart),
		.axi_wr_strb(axi_wr_strb_uart),
		.axi_wr_status(axi_wr_status_uart)
	);
	
	// ==========================
	// ADC LT2308 module instance
	// ==========================
	
	// Formula:
	//   tcyc = spi_clock / samp_freq
	//   where tcyc is total cycles in ticks of the SPI clock, spi_clock is SPI clock in Hz, samp_freq is desired sampling frequency in Hz

	// Example tcyc values using 40MHz SPI clock:
	//   tcyc = 80       (500kHz sampling freq)
	//   tcyc = 100      (400kHz sampling freq)
	//   tcyc = 400      (100kHz sampling freq)
	//   tcyc = 800      (50kHz  sampling freq)
	//   tcyc = 4000     (10kHz  sampling freq)
	//   tcyc = 20000000 (2Hz    sampling freq)
	
	wire adc_ready;
	wire [11:0] adc_data;
	wire [2:0] adc_curr_ch;
	adc_ltc2308 adc_0(
		.clock(pll0_clock1),
		.reset_n(master_reset_n),
		.tcyc(20000000),
		.differential(0),
		.ch0(1),
		.ch1(1),
		.ch2(1),
		.ch3(1),
		.ch4(1),
		.ch5(1),
		.ch6(1),
		.ch7(1),
		.start(1),
		.ready(adc_ready),
		.data(adc_data),
		.curr_ch(adc_curr_ch),
		.CONVST(ADC_CONVST),
		.SCK(ADC_SCK),
		.SDI(ADC_SDI),
		.SDO(ADC_SDO)
	);
	
	// ========================================
	// Control loop to send ADC samples to UART
	// ========================================
	
	// UART messages, etc
	wire [7:0] curr_ch_ascii = adc_curr_ch + 48;
	localparam UART_MSG1_LEN = 6;
	wire [8*UART_MSG1_LEN-1:0] uart_msg1 = { "ch", curr_ch_ascii, "=0x" };
	localparam UART_ADC_DATA_LEN = 2;
	reg [15:0] uart_adc_data;
	reg [2:0] uart_msg_counter;  // Max value = 2^(2+1) = 8. Value must be equal or greater than longest message
	
	reg [3:0] state;
	always @ (posedge pll0_clock0 or negedge master_reset_n) begin
		// STATE: Reset?
		if(!master_reset_n) begin
			uart_enable <= 0;
			state <= 0;
			axi_rd_id <= 0;
			axi_wr_id <= 0;
		end else begin

			case(state)
				
				0: begin
						uart_msg_counter <= UART_MSG1_LEN - 1;
						state <= state + 1;
				end
				
				// Transmit uart_msg1 to UART
				1: begin
					case(uart_status)
						0: begin
							uart_data <= uart_msg1[8*uart_msg_counter +: 8];
							uart_input_type <= 0;
							uart_data_len <= 1;
							uart_hex <= 0;
							uart_new_line <= 0;
							uart_enable <= 1;
						end
						2: begin
							uart_enable <= 0;
							if(uart_msg_counter > 0) begin
								uart_msg_counter <= uart_msg_counter - 1;
							end else begin
								state <= state + 1;
							end
						end
					endcase
				end
				
				// Wait for ADC data sample ready
				2: begin
					if(adc_ready) begin
						uart_adc_data <= { 4'h0, adc_data };
						uart_msg_counter <= UART_ADC_DATA_LEN - 1;
						state <= state + 1;
					end
				end
				
				// Transmit ADC data sample as hex value to UART 
				3: begin
					case(uart_status)
						0: begin
							uart_data <= uart_adc_data[8*uart_msg_counter +: 8];
							uart_input_type <= 0;
							uart_data_len <= 1;
							uart_hex <= 1;
							uart_new_line <= 0;
							uart_enable <= 1;
						end
						2: begin
							uart_enable <= 0;
							if(uart_msg_counter > 0) begin
								uart_msg_counter <= uart_msg_counter - 1;
							end else begin
								state <= state + 1;
							end
						end
					endcase
				end
				
				// Transmit new line to UART and loop to state 0
				4: begin
					case(uart_status)
						0: begin
							uart_input_type <= 0;
							uart_data_len <= 0;
							uart_hex <= 0;
							uart_new_line <= 1;  // Display a new line
							uart_enable <= 1;
						end
						2: begin
							uart_enable <= 0;
							state <= 0;
						end
					endcase
				end

			endcase
		end
	end
endmodule
