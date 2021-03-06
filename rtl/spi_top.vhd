library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_top is
	port (
		clk			: in  std_logic;
		
		spi_clk		: in  std_logic;
		spi_cs_n		: in  std_logic;
		spi_mosi		: in  std_logic;
		
		o_data		: out std_logic_vector( 9 downto 0 ) := ( others => '0' )
	);
end spi_top;

-- ************************************************************************
-- SPI Register Format
-- ************************************************************************
-- 9-8	: Data bit length
--			: 00 = 24 bit ( default )
--			: 01 = 20 bit
--			: 10 = 18 bit
--			: 11 = 16 bit
-- 7		: Input Select
--			: 0 = SPDIF
--			: 1 = I2S
-- 6-5	: SPDIF Input Select
--			: 00 = Input 1
--			: 01 = Input 2
--			: 10 = Input 3
--			: 11 = Input 4
-- 4		: I2S Master Clock Select
--			: 0 = 22.5792 MHz (44.1 kHz)
--			: 1 = 24.576  MHz (48   kHz)
-- 3-2	: I2S Data Rate Select
--			: 00 =  44.1 kHz /  48 kHz
--			: 01 =  44.1 kHz /  48 kHz
--			: 10 =  88.2 kHz /  96 kHz
--			: 11 = 176.4 kHz / 192 kHz
-- 1		: Mute
-- 0		: Reset
-- ************************************************************************

architecture rtl of spi_top is
	signal spi_buf_en 	: std_logic_vector( 15 downto 0 ) := ( others => '0' );
	
	signal buf_clk			: std_logic_vector( 2 downto 0 ) := ( others => '0' );
	signal buf_cs_n		: std_logic_vector( 2 downto 0 ) := ( others => '0' );
	signal buf_mosi		: std_logic_vector( 1 downto 0 ) := ( others => '0' );
	
	signal buf_clk_edge	: std_logic;
	signal cs_edge_p		: std_logic;
	signal cs_edge_n		: std_logic;
	
	signal data				: std_logic_vector( 15 downto 0 ) := ( others => '0' );
	signal data_en			: std_logic := '0';
begin

	buf_clk_edge <= ( buf_clk( 2 ) xor buf_clk( 1 ) ) and not buf_clk( 1 );
	
	cs_edge_n <= ( buf_cs_n( 2 ) xor buf_cs_n( 1 ) ) and      buf_cs_n( 2 )  ;
	cs_edge_p <= ( buf_cs_n( 2 ) xor buf_cs_n( 1 ) ) and not( buf_cs_n( 2 ) );
	
	sync_process : process( clk )
	begin
		if rising_edge( clk ) then
			buf_clk <= buf_clk( 1 downto 0  ) & spi_clk;
			buf_cs_n <= buf_cs_n( 1 downto 0 ) & spi_cs_n;
			buf_mosi <= buf_mosi( 0 ) & spi_mosi;
		end if;
	end process sync_process;

	spi_process : process( clk )
	begin
		if rising_edge( clk ) then
			data_en <= '0';
		
			if cs_edge_n = '1' then
				spi_buf_en <= ( 15 => '1', others => '0' );
			elsif cs_edge_p = '1' then
				data_en <= '1';
			elsif buf_clk_edge = '1' then
				spi_buf_en <= '0' & spi_buf_en( 15 downto 1 );
				
				for i in 0 to 15 loop
					if spi_buf_en( i ) = '1' then
						data( i ) <= buf_mosi( 1 );
					end if;
				end loop;
			end if;
		end if;
	end process spi_process;
	
	data_process : process( clk )
	begin
		if rising_edge( clk ) then
			if data_en = '1' then
				o_data <= data( o_data'range );
			end if;
		end if;
	end process data_process;
	
end rtl;