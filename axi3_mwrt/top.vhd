----------------------------------------------------------------------------
--  top.vhd (for axi3_mwrt)
--	ZedBoard simple VHDL example
--	Version 1.0
--
--  Copyright (C) 2013 H.Poetzl
--
--	This program is free software: you can redistribute it and/or
--	modify it under the terms of the GNU General Public License
--	as published by the Free Software Foundation, either version
--	2 of the License, or (at your option) any later version.
--
--  Vivado 2013.3:
--    mkdir -p build.vivado
--    (cd build.vivado && vivado -mode tcl -source ../vivado.tcl)
--    (cd build.vivado && promgen -w -b -p bin -u 0 axi3_mwrt.bit -data_width 32)
--
----------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.ALL;

library unisim;
use unisim.VCOMPONENTS.all;

library unimacro;
use unimacro.VCOMPONENTS.all;

use work.axi3s_pkg.all;		-- AXI3 Slave Interface
use work.vivado_pkg.all;	-- Vivado Attributes


entity top is
    port (
	clk_100 : in std_logic			-- input clock to FPGA
    );

end entity top;


architecture RTL of top is

    attribute KEEP_HIERARCHY of RTL : architecture is "TRUE";

    --------------------------------------------------------------------
    -- PS7 AXI Slave Signals
    --------------------------------------------------------------------

    signal s_axi_aclk : std_logic_vector(3 downto 0);
    signal s_axi_areset_n : std_logic_vector(3 downto 0);

    type axi3s_read_in_t is array (natural range <>) of
	axi3s_read_in_r;

    signal s_axi_ri : axi3s_read_in_t(3 downto 0);

    type axi3s_read_out_t is array (natural range <>) of
	axi3s_read_out_r;

    signal s_axi_ro : axi3s_read_out_t(3 downto 0);

    type axi3s_write_in_t is array (natural range <>) of
	axi3s_write_in_r;

    signal s_axi_wi : axi3s_write_in_t(3 downto 0);

    type axi3s_write_out_t is array (natural range <>) of
	axi3s_write_out_r;

    signal s_axi_wo : axi3s_write_out_t(3 downto 0);

    --------------------------------------------------------------------
    -- PLL Signals
    --------------------------------------------------------------------

    signal pll_clk : std_logic_vector(3 downto 0);

    signal pll_locked : std_logic;

    --------------------------------------------------------------------
    -- Writer Constants and Signals
    --------------------------------------------------------------------

    type waddr_t is array (natural range <>) of
	std_logic_vector (31 downto 0);

    constant WADDR_MASK : waddr_t(0 to 3) := 
	( x"000FFFFF", x"000FFFFF", x"000FFFFF", x"000FFFFF" );
    constant WADDR_BASE : waddr_t(0 to 3) := 
	( x"1B000000", x"1C000000", x"1D000000", x"1E000000" );

    type wdata_t is array (natural range <>) of
	std_logic_vector (63 downto 0);

    constant WDATA_MASK : wdata_t(0 to 3) := 
	( x"0FFC0FFC0FFC0FFC", x"0FFC0FFC0FFC0FFC",
	  x"0FFC0FFC0FFC0FFC", x"0FFC0FFC0FFC0FFC" );
    constant WDATA_MARK : wdata_t(0 to 3) := 
	( x"B003B002B001B000", x"C003C002C001C000",
	  x"D003D002D001D000", x"E003E002E001E000" );

    signal writer_enable : std_logic_vector(3 downto 0)
	:= (others => '0');

begin

    --------------------------------------------------------------------
    -- PS7 Interface
    --------------------------------------------------------------------

    ps7_stub_inst : entity work.ps7_stub
	port map (
	    s_axi0_aclk => s_axi_aclk(0),
	    s_axi0_areset_n => s_axi_areset_n(0),
	    --
	    s_axi0_arid => s_axi_ri(0).arid,
	    s_axi0_araddr => s_axi_ri(0).araddr,
	    s_axi0_arburst => s_axi_ri(0).arburst,
	    s_axi0_arlen => s_axi_ri(0).arlen,
	    s_axi0_arsize => s_axi_ri(0).arsize,
	    s_axi0_arprot => s_axi_ri(0).arprot,
	    s_axi0_arvalid => s_axi_ri(0).arvalid,
	    s_axi0_arready => s_axi_ro(0).arready,
	    s_axi0_racount => s_axi_ro(0).racount,
	    --
	    s_axi0_rid => s_axi_ro(0).rid,
	    s_axi0_rdata => s_axi_ro(0).rdata,
	    s_axi0_rlast => s_axi_ro(0).rlast,
	    s_axi0_rvalid => s_axi_ro(0).rvalid,
	    s_axi0_rready => s_axi_ri(0).rready,
	    s_axi0_rcount => s_axi_ro(0).rcount,
	    --
	    s_axi0_awid => s_axi_wi(0).awid,
	    s_axi0_awaddr => s_axi_wi(0).awaddr,
	    s_axi0_awburst => s_axi_wi(0).awburst,
	    s_axi0_awlen => s_axi_wi(0).awlen,
	    s_axi0_awsize => s_axi_wi(0).awsize,
	    s_axi0_awprot => s_axi_wi(0).awprot,
	    s_axi0_awvalid => s_axi_wi(0).awvalid,
	    s_axi0_awready => s_axi_wo(0).awready,
	    s_axi0_wacount => s_axi_wo(0).wacount,
	    --
	    s_axi0_wid => s_axi_wi(0).wid,
	    s_axi0_wdata => s_axi_wi(0).wdata,
	    s_axi0_wstrb => s_axi_wi(0).wstrb,
	    s_axi0_wlast => s_axi_wi(0).wlast,
	    s_axi0_wvalid => s_axi_wi(0).wvalid,
	    s_axi0_wready => s_axi_wo(0).wready,
	    s_axi0_wcount => s_axi_wo(0).wcount,
	    --
	    s_axi0_bid => s_axi_wo(0).bid,
	    s_axi0_bresp => s_axi_wo(0).bresp,
	    s_axi0_bvalid => s_axi_wo(0).bvalid,
	    s_axi0_bready => s_axi_wi(0).bready,
	    --
	    s_axi1_aclk => s_axi_aclk(1),
	    s_axi1_areset_n => s_axi_areset_n(1),
	    --
	    s_axi1_arid => s_axi_ri(1).arid,
	    s_axi1_araddr => s_axi_ri(1).araddr,
	    s_axi1_arburst => s_axi_ri(1).arburst,
	    s_axi1_arlen => s_axi_ri(1).arlen,
	    s_axi1_arsize => s_axi_ri(1).arsize,
	    s_axi1_arprot => s_axi_ri(1).arprot,
	    s_axi1_arvalid => s_axi_ri(1).arvalid,
	    s_axi1_arready => s_axi_ro(1).arready,
	    s_axi1_racount => s_axi_ro(1).racount,
	    --
	    s_axi1_rid => s_axi_ro(1).rid,
	    s_axi1_rdata => s_axi_ro(1).rdata,
	    s_axi1_rlast => s_axi_ro(1).rlast,
	    s_axi1_rvalid => s_axi_ro(1).rvalid,
	    s_axi1_rready => s_axi_ri(1).rready,
	    s_axi1_rcount => s_axi_ro(1).rcount,
	    --
	    s_axi1_awid => s_axi_wi(1).awid,
	    s_axi1_awaddr => s_axi_wi(1).awaddr,
	    s_axi1_awburst => s_axi_wi(1).awburst,
	    s_axi1_awlen => s_axi_wi(1).awlen,
	    s_axi1_awsize => s_axi_wi(1).awsize,
	    s_axi1_awprot => s_axi_wi(1).awprot,
	    s_axi1_awvalid => s_axi_wi(1).awvalid,
	    s_axi1_awready => s_axi_wo(1).awready,
	    s_axi1_wacount => s_axi_wo(1).wacount,
	    --
	    s_axi1_wid => s_axi_wi(1).wid,
	    s_axi1_wdata => s_axi_wi(1).wdata,
	    s_axi1_wstrb => s_axi_wi(1).wstrb,
	    s_axi1_wlast => s_axi_wi(1).wlast,
	    s_axi1_wvalid => s_axi_wi(1).wvalid,
	    s_axi1_wready => s_axi_wo(1).wready,
	    s_axi1_wcount => s_axi_wo(1).wcount,
	    --
	    s_axi1_bid => s_axi_wo(1).bid,
	    s_axi1_bresp => s_axi_wo(1).bresp,
	    s_axi1_bvalid => s_axi_wo(1).bvalid,
	    s_axi1_bready => s_axi_wi(1).bready,
	    --
	    s_axi2_aclk => s_axi_aclk(2),
	    s_axi2_areset_n => s_axi_areset_n(2),
	    --
	    s_axi2_arid => s_axi_ri(2).arid,
	    s_axi2_araddr => s_axi_ri(2).araddr,
	    s_axi2_arburst => s_axi_ri(2).arburst,
	    s_axi2_arlen => s_axi_ri(2).arlen,
	    s_axi2_arsize => s_axi_ri(2).arsize,
	    s_axi2_arprot => s_axi_ri(2).arprot,
	    s_axi2_arvalid => s_axi_ri(2).arvalid,
	    s_axi2_arready => s_axi_ro(2).arready,
	    s_axi2_racount => s_axi_ro(2).racount,
	    --
	    s_axi2_rid => s_axi_ro(2).rid,
	    s_axi2_rdata => s_axi_ro(2).rdata,
	    s_axi2_rlast => s_axi_ro(2).rlast,
	    s_axi2_rvalid => s_axi_ro(2).rvalid,
	    s_axi2_rready => s_axi_ri(2).rready,
	    s_axi2_rcount => s_axi_ro(2).rcount,
	    --
	    s_axi2_awid => s_axi_wi(2).awid,
	    s_axi2_awaddr => s_axi_wi(2).awaddr,
	    s_axi2_awburst => s_axi_wi(2).awburst,
	    s_axi2_awlen => s_axi_wi(2).awlen,
	    s_axi2_awsize => s_axi_wi(2).awsize,
	    s_axi2_awprot => s_axi_wi(2).awprot,
	    s_axi2_awvalid => s_axi_wi(2).awvalid,
	    s_axi2_awready => s_axi_wo(2).awready,
	    s_axi2_wacount => s_axi_wo(2).wacount,
	    --
	    s_axi2_wid => s_axi_wi(2).wid,
	    s_axi2_wdata => s_axi_wi(2).wdata,
	    s_axi2_wstrb => s_axi_wi(2).wstrb,
	    s_axi2_wlast => s_axi_wi(2).wlast,
	    s_axi2_wvalid => s_axi_wi(2).wvalid,
	    s_axi2_wready => s_axi_wo(2).wready,
	    s_axi2_wcount => s_axi_wo(2).wcount,
	    --
	    s_axi2_bid => s_axi_wo(2).bid,
	    s_axi2_bresp => s_axi_wo(2).bresp,
	    s_axi2_bvalid => s_axi_wo(2).bvalid,
	    s_axi2_bready => s_axi_wi(2).bready,
	    --
	    s_axi3_aclk => s_axi_aclk(3),
	    s_axi3_areset_n => s_axi_areset_n(3),
	    --
	    s_axi3_arid => s_axi_ri(3).arid,
	    s_axi3_araddr => s_axi_ri(3).araddr,
	    s_axi3_arburst => s_axi_ri(3).arburst,
	    s_axi3_arlen => s_axi_ri(3).arlen,
	    s_axi3_arsize => s_axi_ri(3).arsize,
	    s_axi3_arprot => s_axi_ri(3).arprot,
	    s_axi3_arvalid => s_axi_ri(3).arvalid,
	    s_axi3_arready => s_axi_ro(3).arready,
	    s_axi3_racount => s_axi_ro(3).racount,
	    --
	    s_axi3_rid => s_axi_ro(3).rid,
	    s_axi3_rdata => s_axi_ro(3).rdata,
	    s_axi3_rlast => s_axi_ro(3).rlast,
	    s_axi3_rvalid => s_axi_ro(3).rvalid,
	    s_axi3_rready => s_axi_ri(3).rready,
	    s_axi3_rcount => s_axi_ro(3).rcount,
	    --
	    s_axi3_awid => s_axi_wi(3).awid,
	    s_axi3_awaddr => s_axi_wi(3).awaddr,
	    s_axi3_awburst => s_axi_wi(3).awburst,
	    s_axi3_awlen => s_axi_wi(3).awlen,
	    s_axi3_awsize => s_axi_wi(3).awsize,
	    s_axi3_awprot => s_axi_wi(3).awprot,
	    s_axi3_awvalid => s_axi_wi(3).awvalid,
	    s_axi3_awready => s_axi_wo(3).awready,
	    s_axi3_wacount => s_axi_wo(3).wacount,
	    --
	    s_axi3_wid => s_axi_wi(3).wid,
	    s_axi3_wdata => s_axi_wi(3).wdata,
	    s_axi3_wstrb => s_axi_wi(3).wstrb,
	    s_axi3_wlast => s_axi_wi(3).wlast,
	    s_axi3_wvalid => s_axi_wi(3).wvalid,
	    s_axi3_wready => s_axi_wo(3).wready,
	    s_axi3_wcount => s_axi_wo(3).wcount,
	    --
	    s_axi3_bid => s_axi_wo(3).bid,
	    s_axi3_bresp => s_axi_wo(3).bresp,
	    s_axi3_bvalid => s_axi_wo(3).bvalid,
	    s_axi3_bready => s_axi_wi(3).bready );

    --------------------------------------------------------------------
    -- AXIHP PLL
    --------------------------------------------------------------------

    axihp_pll_inst : entity work.axihp_pll
	port map (
	    ref_clk_in => clk_100,
	    --
	    pll_clk => pll_clk,
	    pll_locked => pll_locked );

    --------------------------------------------------------------------
    -- Memory Writers
    --------------------------------------------------------------------

    GEN_MWRT: for I in 0 to 3 generate
    begin
	AXI_MWRT_inst : entity work.axi_mwrt
	    generic map (
		ADDR_MASK => WADDR_MASK(I),
		ADDR_BASE => WADDR_BASE(I),
		DATA_MASK => WDATA_MASK(I),
		DATA_MARK => WDATA_MARK(I) )
	    port map (
		m_axi_aclk => s_axi_aclk(I),
		m_axi_areset_n => s_axi_areset_n(I),
		enable => writer_enable(I),
		--
		m_axi_wo => s_axi_wi(I),
		m_axi_wi => s_axi_wo(I) );

	s_axi_aclk(I) <= pll_clk(I);

	delay_proc : process (pll_clk(I))
	    variable cnt_v : natural := 0;
	begin
	    if rising_edge(pll_clk(I)) then
		if cnt_v = I * 100 + 100 then
		    writer_enable(I) <= '1';
		else
		    cnt_v := cnt_v + 1;
		end if;
	    end if;
	end process;

    end generate;

end RTL;
