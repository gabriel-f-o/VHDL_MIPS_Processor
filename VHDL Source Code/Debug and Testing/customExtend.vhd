library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity customExtend is
	generic(
		DATA_WIDTH : natural := 16; --16 Bits data
		INPUT_WIDTH : natural := 6  --6 Bits input data
	);
	port(
		modeIn		 : in  std_logic;
		dataIn		 : in  std_logic_vector((INPUT_WIDTH-1) downto 0);
		extendedData : out std_logic_vector((DATA_WIDTH-1) downto 0)
	);
end entity;

architecture ce of customExtend is 
	
begin
	process(dataIn, modeIn)
	begin
		if(modeIn = '0') then
			extendedData((DATA_WIDTH-1) downto INPUT_WIDTH) <= (others => '0');
			extendedData((INPUT_WIDTH-1) downto 0) <= dataIn;
		else
			if(dataIn(INPUT_WIDTH-1) = '1') then
				extendedData((DATA_WIDTH-1) downto INPUT_WIDTH) <= (others => '1');
			else
				extendedData((DATA_WIDTH-1) downto INPUT_WIDTH) <= (others => '0');
			end if;
			extendedData((INPUT_WIDTH-1) downto 0) <= dataIn;
		end if;
	end process;
end ce;