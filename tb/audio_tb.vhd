--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:28:04 11/18/2014
-- Design Name:   
-- Module Name:   /home/charlie/projects/SRC_V0.9.1/tb/audio_tb.vhd
-- Project Name:  SRC_V0.9.1
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: audio_top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library work;
use work.audio.all;
use work.utils.all;
use work.sig_gen_pkg.all;
 
ENTITY audio_tb IS
END audio_tb;
 
ARCHITECTURE behavior OF audio_tb IS 
	constant s_rate	: real := 44.1;
	constant s_scale	: real range 0.5 to 1.0 :=  0.99;
	signal ctrl_width : std_logic_vector( 1 downto 0 ) := "00"; -- 16 bits 
	
   signal clk_196 : std_logic := '0';
 
   --Inputs
   signal clk_24 : std_logic := '0';
   signal ctrl_rst : std_logic := '0';
   signal spi_clk : std_logic := '0';
   signal spi_cs_n : std_logic_vector(2 downto 0) := (others => '1');
   signal spi_mosi : std_logic := '0';
   signal i2s_data : std_logic := '0';
   signal spdif_chan0 : std_logic := '0';
   signal spdif_chan1 : std_logic := '0';
   signal spdif_chan2 : std_logic := '0';
   signal spdif_chan3 : std_logic := '0';
   signal dsp0_spi_miso : std_logic := '0';
   signal dsp1_spi_miso : std_logic := '0';

 	--Outputs
   signal ctrl_lock : std_logic;
	signal ctrl_rdy : std_logic;
   signal spi_miso : std_logic;
   signal i2s_bclk : std_logic;
   signal i2s_lrck : std_logic;
   signal spdif_o : std_logic;
   signal dsp0_rst : std_logic;
   signal dsp0_mute : std_logic;
   signal dsp0_i2s_lrck : std_logic;
   signal dsp0_i2s_bclk : std_logic;
   signal dsp0_i2s_data0 : std_logic;
   signal dsp0_i2s_data1 : std_logic;
   signal dsp0_spi_clk : std_logic;
   signal dsp0_spi_cs_n : std_logic;
   signal dsp0_spi_mosi : std_logic;
   signal dsp1_rst : std_logic;
   signal dsp1_mute : std_logic;
   signal dsp1_i2s_lrck : std_logic;
   signal dsp1_i2s_bclk : std_logic;
   signal dsp1_i2s_data0 : std_logic;
   signal dsp1_i2s_data1 : std_logic;
   signal dsp1_spi_clk : std_logic;
   signal dsp1_spi_cs_n : std_logic;
   signal dsp1_spi_mosi : std_logic;

   -- Clock period definitions
   constant clk_24_period : time := 40.69 ns;
	constant clk_196_period : time := 6.78 ns;
	
	signal spi_en		: std_logic := '0';
	signal spi_data	: std_logic_vector( 15 downto 0 ) := ( others => '0' );
 
	signal dac_data0	: signed( 23 downto 0 ) := ( others => '0' );
	signal dac_data1	: signed( 23 downto 0 ) := ( others => '0' );
	signal dac_data_en: std_logic := '0';
	
   signal spdif_data0 : signed(23 downto 0) := (others => '0');
   signal spdif_data1 : signed(23 downto 0) := (others => '0');
   signal spdif_data_en : std_logic := '0';
	
	procedure spi_write( 
		constant i_spi		: in  std_logic_vector( 15 downto 0 );
		signal o_spi		: out std_logic_vector( 15 downto 0 );
		signal o_spi_en	: out std_logic
	) is begin
		wait until rising_edge( clk_24 );
		o_spi <= i_spi;
		o_spi_en <= '1';
		
		wait until rising_edge( clk_24 );
		o_spi_en <= '0';
		
		wait for 500 us;
	end procedure;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: audio_top PORT MAP (
          clk_24 => clk_24,
          ctrl_rst => ctrl_rst,
          ctrl_lock => ctrl_lock,
			 ctrl_rdy  => ctrl_rdy,
          spi_clk => spi_clk,
          spi_cs_n => spi_cs_n,
          spi_mosi => spi_mosi,
          spi_miso => spi_miso,
          i2s_data => i2s_data,
          i2s_bclk => i2s_bclk,
          i2s_lrck => i2s_lrck,
          spdif_chan0 => spdif_chan0,
          spdif_chan1 => spdif_chan1,
          spdif_chan2 => spdif_chan2,
          spdif_chan3 => spdif_chan3,
          spdif_o => spdif_o,
          dsp0_rst => dsp0_rst,
          dsp0_mute => dsp0_mute,
          dsp0_i2s_lrck => dsp0_i2s_lrck,
          dsp0_i2s_bclk => dsp0_i2s_bclk,
          dsp0_i2s_data0 => dsp0_i2s_data0,
          dsp0_i2s_data1 => dsp0_i2s_data1,
          dsp0_spi_clk => dsp0_spi_clk,
          dsp0_spi_cs_n => dsp0_spi_cs_n,
          dsp0_spi_mosi => dsp0_spi_mosi,
          dsp0_spi_miso => dsp0_spi_miso,
          dsp1_rst => dsp1_rst,
          dsp1_mute => dsp1_mute,
          dsp1_i2s_lrck => dsp1_i2s_lrck,
          dsp1_i2s_bclk => dsp1_i2s_bclk,
          dsp1_i2s_data0 => dsp1_i2s_data0,
          dsp1_i2s_data1 => dsp1_i2s_data1,
          dsp1_spi_clk => dsp1_spi_clk,
          dsp1_spi_cs_n => dsp1_spi_cs_n,
          dsp1_spi_mosi => dsp1_spi_mosi,
          dsp1_spi_miso => dsp1_spi_miso
        );
	
	-- SPI
	spi_tb : spi_util_tb
		port map (
			clk		=> clk_24,
			spi_en	=> spi_en,
			spi_data	=> spi_data,
			
			spi_clk	=> spi_clk,
			spi_cs_n	=> spi_cs_n(0),
			spi_mosi	=> spi_mosi
		);
	
	-- i2s
	i2s_tb : i2s_util_tb
		port map (
			ctrl_width => ctrl_width,
			i2s_bclk => i2s_bclk,
			i2s_lrck => i2s_lrck,
			i2s_data => i2s_data
		);
	
	-- spdif
	spdif_tb : spdif_util_tb
		generic map (
			FREQ	=> 44100
		)
		port map (
			reset => ctrl_rst,
			spdif => spdif_chan0
		);
	
	-- dac
	dac_tb : dac_util_tb
		port map (
			i_lrck 		=> dsp0_i2s_lrck,
			i_bclk 		=> dsp0_i2s_bclk,
			i_data0 		=> dsp0_i2s_data0,
			i_data1 		=> dsp0_i2s_data1,
			
			o_data0 		=> dac_data0,
			o_data1 		=> dac_data1,
			o_data_en	=> dac_data_en
		);
	
	-- spdif
	rxer : spdif_rx_top
		port map (
			clk			=> clk_196,
			sel			=> "00",
		
			i_data0		=> spdif_o,
			i_data1		=> '0',
			i_data2		=> '0',
			i_data3		=> '0',
			
			o_data0		=> spdif_data0,
			o_data1		=> spdif_data1,
			o_data_en	=> spdif_data_en
		) ;

	dac_capture_process : process( dsp0_i2s_bclk )
		file		outfile0	: text is out "test/dac_channel_0.txt";
		variable outline0	: line;
		file		outfile1	: text is out "test/dac_channel_1.txt";
		variable outline1	: line;
	begin
		if rising_edge( dsp0_i2s_bclk ) then
			if dac_data_en = '1' then
				write( outline0, to_integer( dac_data0 ) );
				writeline( outfile0, outline0 );
				write( outline1, to_integer( dac_data1 ) );
				writeline( outfile1, outline1 );
			end if;
		end if;
	end process;

	spdif_capture_process : process( clk_196 )
		file		outfile0	: text is out "test/spdif_channel_0.txt";
		variable outline0	: line;
		file		outfile1	: text is out "test/spdif_channel_1.txt";
		variable outline1	: line;
	begin
		if rising_edge( clk_196 ) then
			if spdif_data_en = '1' then
				write( outline0, to_integer( spdif_data0 ) );
				writeline( outfile0, outline0 );
				write( outline1, to_integer( spdif_data1 ) );
				writeline( outfile1, outline1 );
			end if;
		end if;
	end process;

   -- Clock process definitions
   clk_24_process :process
   begin
		clk_24 <= '0';
		wait for clk_24_period/2;
		clk_24 <= '1';
		wait for clk_24_period/2;
   end process;
   
	clk_196_process :process
   begin
		clk_196 <= '0';
		wait for clk_196_period/2;
		clk_196 <= '1';
		wait for clk_196_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		set_rate( s_rate );
		set_scale( s_scale );
		wait until ctrl_rdy = '1';
		
		if		s_rate =  44.1 then spi_write( o"40" & ctrl_width & "10000000", spi_data, spi_en );
		elsif s_rate =  48.0 then spi_write( o"40" & ctrl_width & "10010000", spi_data, spi_en );
		elsif s_rate =  88.2 then spi_write( o"40" & ctrl_width & "10001000", spi_data, spi_en );
		elsif s_rate =  96.0 then spi_write( o"40" & ctrl_width & "10011000", spi_data, spi_en );
		elsif s_rate = 176.4 then spi_write( o"40" & ctrl_width & "10001100", spi_data, spi_en );
		elsif s_rate = 192.0 then spi_write( o"40" & ctrl_width & "10011110", spi_data, spi_en );
		end if;
		
		wait for 0.5 ms;
		
		--set_sig( s_freq, 96.0, s_width );
		--spi_write( "10011000", spi_data, spi_en );
		--wait until rising_edge(clk_24 );

      wait;
   end process;

END;
