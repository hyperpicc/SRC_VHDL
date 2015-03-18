-- ************************************************************************
-- ISE Configuration Requirements
--		- Synthesis
--			- Register Balancing: Yes
--		- Map
--			- LUT Combining: Auto
-- ************************************************************************
-- SPI Register Format
-- 7		: Input Select
--			: 0 = SPDIF
--			: 1 = I2S
-- 6-5	: SPDIF Input Select
--			: 00 = Input 1
--			: 01 = Input 2
--			: 10 = Input 3
--			: 11 = Input 4
-- 4		: I2S Base Clock Select
--			: 0 = 22.5792 MHz (44.1 kHz Base)
--			: 1 = 24.576  MHz (48   kHz Base)
-- 3-2	: I2S Data Rate Select
--			: 00 =  44.1 kHz /  48 kHz
--			: 01 =  44.1 kHz /  48 kHz
--			: 10 =  88.2 kHz /  96 kHz
--			: 11 = 176.4 kHz / 192 kHz
-- 1		: Mute
-- 0		: Reset
-- ************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.audio.all;

entity audio_top is
	port (
		clk_24			: in  std_logic;
		clk_22			: in  std_logic;
		ctrl_rst			: in  std_logic;
		ctrl_lock		: out std_logic := '0';
		ctrl_rdy			: out std_logic := '0';
		
		spi_clk			: in  std_logic;
		spi_cs_n			: in  std_logic_vector( 2 downto 0 );
		spi_mosi			: in  std_logic;
		spi_miso			: out std_logic := '0';

		i2s_data			: in  std_logic;
		i2s_bclk			: out std_logic := '0';
		i2s_lrck			: out std_logic := '0';
		
		spdif_chan0		: in  std_logic;
		spdif_chan1		: in  std_logic;
		spdif_chan2		: in  std_logic;
		spdif_chan3		: in  std_logic;
		spdif_o			: out std_logic;
		
		-- **********************************************************s**************
		-- DSP 0 = Left Channel
		-- ************************************************************************
		dsp0_rst			: out std_logic := '0';
		dsp0_mute		: out std_logic := '0';
		
		dsp0_i2s_lrck	: out std_logic := '0';
		dsp0_i2s_bclk	: out std_logic := '0';
		dsp0_i2s_data0	: out std_logic := '0';
		dsp0_i2s_data1	: out std_logic := '0';
		
		dsp0_spi_clk	: out std_logic := '0';
		dsp0_spi_cs_n	: out std_logic := '0';
		dsp0_spi_mosi	: out	std_logic := '0';
		dsp0_spi_miso	: in  std_logic;
		
		-- ************************************************************************
		-- DSP 1 = Right Channel
		-- ************************************************************************
		dsp1_rst			: out std_logic := '0';
		dsp1_mute		: out std_logic := '0';
		
		dsp1_i2s_lrck	: out std_logic := '0';
		dsp1_i2s_bclk	: out std_logic := '0';
		dsp1_i2s_data0	: out std_logic := '0';
		dsp1_i2s_data1	: out std_logic := '0';
		
		dsp1_spi_clk	: out std_logic := '0';
		dsp1_spi_cs_n	: out std_logic := '0';
		dsp1_spi_mosi	: out std_logic := '0';
		dsp1_spi_miso	: in  std_logic

	);
end audio_top;

architecture rtl of audio_top is
	signal spi_register	: std_logic_vector( 7 downto 0 ) := ( others => '0' );
	signal spi_reg_buf	: std_logic_vector( 7 downto 0 ) := ( others => '0' );
	signal spi_change		: std_logic := '0';
	
	signal dac_rst			: std_logic := '0';
	signal pll_lock		: std_logic := '0';
	signal rst				: std_logic := '0';
	signal rst_buf			: std_logic_vector( 1 downto 0 ) := "00";
	signal clk				: std_logic := '0';
	signal clk_i2s			: std_logic := '0';
	
	signal i2s_data0		: signed( 23 downto 0 ) := ( others => '0' );
	signal i2s_data1		: signed( 23 downto 0 ) := ( others => '0' );
	signal i2s_data_en	: std_logic := '0';
	
	signal spdif_data0	: signed( 23 downto 0 ) := ( others => '0' );
	signal spdif_data1	: signed( 23 downto 0 ) := ( others => '0' );
	signal spdif_data_en	: std_logic := '0';
	
	signal mux_data0		: signed( 23 downto 0 ) := ( others => '0' );
	signal mux_data1		: signed( 23 downto 0 ) := ( others => '0' );
	signal mux_data_en	: std_logic := '0';
	
	signal src_lock		: std_logic := '0';
	signal src_data0		: signed( 23 downto 0 ) := ( others => '0' );
	signal src_data1		: signed( 23 downto 0 ) := ( others => '0' );
	signal src_data_en	: std_logic := '0';
	signal o_sample_en	: std_logic := '0';
	
	signal dsp_i2s_sclk	: std_logic := '0';
	signal dsp_i2s_lrck	: std_logic := '0';
	signal dsp_i2s_bclk	: std_logic := '0';
	signal dsp_i2s_data0	: std_logic := '0';
	signal dsp_i2s_data1	: std_logic := '0';

begin

	-- *******************************************************************
	-- ** SYSTEM RESET
	-- *******************************************************************
	
	ctrl_rdy  <= pll_lock;
	ctrl_lock <= src_lock;
	
	rst <= rst_buf( 1 );
	
	rst_process : process( clk )
	begin
		if rising_edge( clk ) then
			dac_rst <= rst or not( src_lock );
			rst_buf <= rst_buf( 0 ) & ( ctrl_rst or spi_register( 0 ) or spi_change or not( pll_lock ) );
		end if;
	end process rst_process;
	
	spi_change_process : process( clk )
	begin
		if rising_edge( clk ) then
			spi_reg_buf <= spi_register;
			if spi_change <= '1' then
				spi_change <= '0';
			elsif spi_reg_buf /= spi_register then
				spi_change <= '1';
			end if;
		end if;
	end process spi_change_process;
	
	-- *******************************************************************
	-- ** SYSTEM CONTROL
	-- *******************************************************************
	-- ** PLL Configuration
	-- *******************************************************************
	
	INST_PLL : pll_top
		port map (
			clk_sel		=> spi_register( 4 ),
			sys_lock		=> pll_lock,
			
			i_clk_22		=> clk_22,
			i_clk_24		=> clk_24,
			
			o_clk_src	=> clk,
			o_clk_i2s	=> clk_i2s
		);
	
	-- *******************************************************************
	-- ** S Configuration
	-- *******************************************************************
	dsp0_rst			<= spi_register( 0 );
	dsp0_mute		<= spi_register( 1 ) or spi_register( 0 );
	dsp0_spi_clk	<= spi_clk;
	dsp0_spi_cs_n	<= spi_cs_n( 1 );
	dsp0_spi_mosi	<= spi_mosi;
	
	dsp1_rst			<= spi_register( 0 );
	dsp1_mute		<= spi_register( 1 ) or spi_register( 0 );
	dsp1_spi_clk	<= spi_clk;
	dsp1_spi_cs_n	<= spi_cs_n( 2 );
	dsp1_spi_mosi	<= spi_mosi;
	
	spi_miso <= dsp0_spi_miso when spi_cs_n( 1 ) = '1' else
					dsp1_spi_miso when spi_cs_n( 2 ) = '1' else
					'0';
	
	INST_SPI : spi_top
		port map (
			clk			=> clk,
			
			spi_clk		=> spi_clk,
			spi_cs_n		=> spi_cs_n( 0 ),
			spi_mosi		=> spi_mosi,
			
			o_data		=> spi_register
		);
		
	-- *******************************************************************
	-- ** AUDIO INPUTS
	-- *******************************************************************
	
	INST_I2S : i2s_top
		port map (
			clk			=> clk,
			
			i2s_clk		=> clk_i2s,
			i2s_data		=> i2s_data,
			i2s_bclk		=> i2s_bclk,
			i2s_lrck		=> i2s_lrck,
			i2s_rate		=> spi_register( 3 downto 2 ),
			
			o_data0		=> i2s_data0,
			o_data1		=> i2s_data1,
			o_data_en	=> i2s_data_en
		);
	
	INST_SPDIF : spdif_top
		port map (
			clk			=> clk,
			sel			=> spi_register( 6 downto 5 ),
		
			i_data0		=> spdif_chan0,
			i_data1		=> spdif_chan1,
			i_data2		=> spdif_chan2,
			i_data3		=> spdif_chan3,
			
			o_data0		=> spdif_data0,
			o_data1		=> spdif_data1,
			o_data_en	=> spdif_data_en,
			
			spdif_o		=> spdif_o
		);
	
	INST_MUX : mux_top
		port map (
			clk			=> clk,
			rst			=> rst,
			sel			=> spi_register( 7 ),
			
			i_data0_0	=> spdif_data0,
			i_data0_1	=> spdif_data1,
			i_data0_en	=> spdif_data_en,
			
			i_data1_0	=> i2s_data0,
			i_data1_1	=> i2s_data1,
			i_data1_en	=> i2s_data_en,
			
			o_data0		=> mux_data0,
			o_data1		=> mux_data1,
			o_data_en	=> mux_data_en
		);
		
	-- *******************************************************************
	-- ** Sample Rate Converter
	-- *******************************************************************
	
	INST_SRC : src_top
		generic map (
			CLOCK_COUNT		=> CLOCK_COUNT
		)
		port map (
			clk				=> clk,
			rst				=> rst,
			
			ctrl_locked		=> src_lock,
			ctrl_ratio		=> open,
			
			i_sample_en_i	=> mux_data_en,
			i_sample_en_o	=> o_sample_en,
			i_data0			=> mux_data0,
			i_data1			=> mux_data1,
			
			o_data0			=> src_data0,
			o_data1			=> src_data1,
			o_data_en		=> src_data_en
		);
	
	-- *******************************************************************
	-- ** Audio Output
	-- *******************************************************************
	
	dsp0_i2s_lrck	<= dsp_i2s_lrck;
	dsp0_i2s_bclk	<= dsp_i2s_bclk;
	dsp0_i2s_data0	<= dsp_i2s_data0;
	dsp0_i2s_data1	<= dsp_i2s_data1;
	
	dsp1_i2s_lrck	<= dsp_i2s_lrck;
	dsp1_i2s_bclk	<= dsp_i2s_bclk;
	dsp1_i2s_data0	<= dsp_i2s_data0;
	dsp1_i2s_data1	<= dsp_i2s_data1;
	
	INST_DAC : dac_top
		generic map (
			DAC_IF		=> DAC_IF
		)
		port map (
			clk			=> clk,
			rst			=> dac_rst,
			
			i_data0		=> src_data0,
			i_data1		=> src_data1,
			i_data_en	=> src_data_en,
			
			o_sample_en	=> o_sample_en,
			o_lrck		=> dsp_i2s_lrck,
			o_bclk		=> dsp_i2s_bclk,
			o_data0		=> dsp_i2s_data0,
			o_data1		=> dsp_i2s_data1
		);
	
end rtl;
