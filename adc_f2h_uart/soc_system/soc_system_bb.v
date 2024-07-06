
module soc_system (
	clk_clk,
	hps_0_f2h_axi_clock_clk,
	hps_0_f2h_axi_slave_awid,
	hps_0_f2h_axi_slave_awaddr,
	hps_0_f2h_axi_slave_awlen,
	hps_0_f2h_axi_slave_awsize,
	hps_0_f2h_axi_slave_awburst,
	hps_0_f2h_axi_slave_awlock,
	hps_0_f2h_axi_slave_awcache,
	hps_0_f2h_axi_slave_awprot,
	hps_0_f2h_axi_slave_awvalid,
	hps_0_f2h_axi_slave_awready,
	hps_0_f2h_axi_slave_awuser,
	hps_0_f2h_axi_slave_wid,
	hps_0_f2h_axi_slave_wdata,
	hps_0_f2h_axi_slave_wstrb,
	hps_0_f2h_axi_slave_wlast,
	hps_0_f2h_axi_slave_wvalid,
	hps_0_f2h_axi_slave_wready,
	hps_0_f2h_axi_slave_bid,
	hps_0_f2h_axi_slave_bresp,
	hps_0_f2h_axi_slave_bvalid,
	hps_0_f2h_axi_slave_bready,
	hps_0_f2h_axi_slave_arid,
	hps_0_f2h_axi_slave_araddr,
	hps_0_f2h_axi_slave_arlen,
	hps_0_f2h_axi_slave_arsize,
	hps_0_f2h_axi_slave_arburst,
	hps_0_f2h_axi_slave_arlock,
	hps_0_f2h_axi_slave_arcache,
	hps_0_f2h_axi_slave_arprot,
	hps_0_f2h_axi_slave_arvalid,
	hps_0_f2h_axi_slave_arready,
	hps_0_f2h_axi_slave_aruser,
	hps_0_f2h_axi_slave_rid,
	hps_0_f2h_axi_slave_rdata,
	hps_0_f2h_axi_slave_rresp,
	hps_0_f2h_axi_slave_rlast,
	hps_0_f2h_axi_slave_rvalid,
	hps_0_f2h_axi_slave_rready,
	hps_0_h2f_reset_reset_n,
	hps_io_hps_io_emac1_inst_TX_CLK,
	hps_io_hps_io_emac1_inst_TXD0,
	hps_io_hps_io_emac1_inst_TXD1,
	hps_io_hps_io_emac1_inst_TXD2,
	hps_io_hps_io_emac1_inst_TXD3,
	hps_io_hps_io_emac1_inst_RXD0,
	hps_io_hps_io_emac1_inst_MDIO,
	hps_io_hps_io_emac1_inst_MDC,
	hps_io_hps_io_emac1_inst_RX_CTL,
	hps_io_hps_io_emac1_inst_TX_CTL,
	hps_io_hps_io_emac1_inst_RX_CLK,
	hps_io_hps_io_emac1_inst_RXD1,
	hps_io_hps_io_emac1_inst_RXD2,
	hps_io_hps_io_emac1_inst_RXD3,
	hps_io_hps_io_sdio_inst_CMD,
	hps_io_hps_io_sdio_inst_D0,
	hps_io_hps_io_sdio_inst_D1,
	hps_io_hps_io_sdio_inst_CLK,
	hps_io_hps_io_sdio_inst_D2,
	hps_io_hps_io_sdio_inst_D3,
	hps_io_hps_io_usb1_inst_D0,
	hps_io_hps_io_usb1_inst_D1,
	hps_io_hps_io_usb1_inst_D2,
	hps_io_hps_io_usb1_inst_D3,
	hps_io_hps_io_usb1_inst_D4,
	hps_io_hps_io_usb1_inst_D5,
	hps_io_hps_io_usb1_inst_D6,
	hps_io_hps_io_usb1_inst_D7,
	hps_io_hps_io_usb1_inst_CLK,
	hps_io_hps_io_usb1_inst_STP,
	hps_io_hps_io_usb1_inst_DIR,
	hps_io_hps_io_usb1_inst_NXT,
	hps_io_hps_io_spim1_inst_CLK,
	hps_io_hps_io_spim1_inst_MOSI,
	hps_io_hps_io_spim1_inst_MISO,
	hps_io_hps_io_spim1_inst_SS0,
	hps_io_hps_io_uart0_inst_RX,
	hps_io_hps_io_uart0_inst_TX,
	hps_io_hps_io_i2c0_inst_SDA,
	hps_io_hps_io_i2c0_inst_SCL,
	hps_io_hps_io_i2c1_inst_SDA,
	hps_io_hps_io_i2c1_inst_SCL,
	hps_io_hps_io_gpio_inst_GPIO09,
	hps_io_hps_io_gpio_inst_GPIO35,
	hps_io_hps_io_gpio_inst_GPIO53,
	hps_io_hps_io_gpio_inst_GPIO54,
	hps_io_hps_io_gpio_inst_GPIO61,
	memory_mem_a,
	memory_mem_ba,
	memory_mem_ck,
	memory_mem_ck_n,
	memory_mem_cke,
	memory_mem_cs_n,
	memory_mem_ras_n,
	memory_mem_cas_n,
	memory_mem_we_n,
	memory_mem_reset_n,
	memory_mem_dq,
	memory_mem_dqs,
	memory_mem_dqs_n,
	memory_mem_odt,
	memory_mem_dm,
	memory_oct_rzqin,
	pll_0_locked_export,
	pll_0_outclk0_clk,
	pll_0_outclk1_clk,
	reset_reset_n);	

	input		clk_clk;
	input		hps_0_f2h_axi_clock_clk;
	input	[7:0]	hps_0_f2h_axi_slave_awid;
	input	[31:0]	hps_0_f2h_axi_slave_awaddr;
	input	[3:0]	hps_0_f2h_axi_slave_awlen;
	input	[2:0]	hps_0_f2h_axi_slave_awsize;
	input	[1:0]	hps_0_f2h_axi_slave_awburst;
	input	[1:0]	hps_0_f2h_axi_slave_awlock;
	input	[3:0]	hps_0_f2h_axi_slave_awcache;
	input	[2:0]	hps_0_f2h_axi_slave_awprot;
	input		hps_0_f2h_axi_slave_awvalid;
	output		hps_0_f2h_axi_slave_awready;
	input	[4:0]	hps_0_f2h_axi_slave_awuser;
	input	[7:0]	hps_0_f2h_axi_slave_wid;
	input	[31:0]	hps_0_f2h_axi_slave_wdata;
	input	[3:0]	hps_0_f2h_axi_slave_wstrb;
	input		hps_0_f2h_axi_slave_wlast;
	input		hps_0_f2h_axi_slave_wvalid;
	output		hps_0_f2h_axi_slave_wready;
	output	[7:0]	hps_0_f2h_axi_slave_bid;
	output	[1:0]	hps_0_f2h_axi_slave_bresp;
	output		hps_0_f2h_axi_slave_bvalid;
	input		hps_0_f2h_axi_slave_bready;
	input	[7:0]	hps_0_f2h_axi_slave_arid;
	input	[31:0]	hps_0_f2h_axi_slave_araddr;
	input	[3:0]	hps_0_f2h_axi_slave_arlen;
	input	[2:0]	hps_0_f2h_axi_slave_arsize;
	input	[1:0]	hps_0_f2h_axi_slave_arburst;
	input	[1:0]	hps_0_f2h_axi_slave_arlock;
	input	[3:0]	hps_0_f2h_axi_slave_arcache;
	input	[2:0]	hps_0_f2h_axi_slave_arprot;
	input		hps_0_f2h_axi_slave_arvalid;
	output		hps_0_f2h_axi_slave_arready;
	input	[4:0]	hps_0_f2h_axi_slave_aruser;
	output	[7:0]	hps_0_f2h_axi_slave_rid;
	output	[31:0]	hps_0_f2h_axi_slave_rdata;
	output	[1:0]	hps_0_f2h_axi_slave_rresp;
	output		hps_0_f2h_axi_slave_rlast;
	output		hps_0_f2h_axi_slave_rvalid;
	input		hps_0_f2h_axi_slave_rready;
	output		hps_0_h2f_reset_reset_n;
	output		hps_io_hps_io_emac1_inst_TX_CLK;
	output		hps_io_hps_io_emac1_inst_TXD0;
	output		hps_io_hps_io_emac1_inst_TXD1;
	output		hps_io_hps_io_emac1_inst_TXD2;
	output		hps_io_hps_io_emac1_inst_TXD3;
	input		hps_io_hps_io_emac1_inst_RXD0;
	inout		hps_io_hps_io_emac1_inst_MDIO;
	output		hps_io_hps_io_emac1_inst_MDC;
	input		hps_io_hps_io_emac1_inst_RX_CTL;
	output		hps_io_hps_io_emac1_inst_TX_CTL;
	input		hps_io_hps_io_emac1_inst_RX_CLK;
	input		hps_io_hps_io_emac1_inst_RXD1;
	input		hps_io_hps_io_emac1_inst_RXD2;
	input		hps_io_hps_io_emac1_inst_RXD3;
	inout		hps_io_hps_io_sdio_inst_CMD;
	inout		hps_io_hps_io_sdio_inst_D0;
	inout		hps_io_hps_io_sdio_inst_D1;
	output		hps_io_hps_io_sdio_inst_CLK;
	inout		hps_io_hps_io_sdio_inst_D2;
	inout		hps_io_hps_io_sdio_inst_D3;
	inout		hps_io_hps_io_usb1_inst_D0;
	inout		hps_io_hps_io_usb1_inst_D1;
	inout		hps_io_hps_io_usb1_inst_D2;
	inout		hps_io_hps_io_usb1_inst_D3;
	inout		hps_io_hps_io_usb1_inst_D4;
	inout		hps_io_hps_io_usb1_inst_D5;
	inout		hps_io_hps_io_usb1_inst_D6;
	inout		hps_io_hps_io_usb1_inst_D7;
	input		hps_io_hps_io_usb1_inst_CLK;
	output		hps_io_hps_io_usb1_inst_STP;
	input		hps_io_hps_io_usb1_inst_DIR;
	input		hps_io_hps_io_usb1_inst_NXT;
	output		hps_io_hps_io_spim1_inst_CLK;
	output		hps_io_hps_io_spim1_inst_MOSI;
	input		hps_io_hps_io_spim1_inst_MISO;
	output		hps_io_hps_io_spim1_inst_SS0;
	input		hps_io_hps_io_uart0_inst_RX;
	output		hps_io_hps_io_uart0_inst_TX;
	inout		hps_io_hps_io_i2c0_inst_SDA;
	inout		hps_io_hps_io_i2c0_inst_SCL;
	inout		hps_io_hps_io_i2c1_inst_SDA;
	inout		hps_io_hps_io_i2c1_inst_SCL;
	inout		hps_io_hps_io_gpio_inst_GPIO09;
	inout		hps_io_hps_io_gpio_inst_GPIO35;
	inout		hps_io_hps_io_gpio_inst_GPIO53;
	inout		hps_io_hps_io_gpio_inst_GPIO54;
	inout		hps_io_hps_io_gpio_inst_GPIO61;
	output	[14:0]	memory_mem_a;
	output	[2:0]	memory_mem_ba;
	output		memory_mem_ck;
	output		memory_mem_ck_n;
	output		memory_mem_cke;
	output		memory_mem_cs_n;
	output		memory_mem_ras_n;
	output		memory_mem_cas_n;
	output		memory_mem_we_n;
	output		memory_mem_reset_n;
	inout	[31:0]	memory_mem_dq;
	inout	[3:0]	memory_mem_dqs;
	inout	[3:0]	memory_mem_dqs_n;
	output		memory_mem_odt;
	output	[3:0]	memory_mem_dm;
	input		memory_oct_rzqin;
	output		pll_0_locked_export;
	output		pll_0_outclk0_clk;
	output		pll_0_outclk1_clk;
	input		reset_reset_n;
endmodule
