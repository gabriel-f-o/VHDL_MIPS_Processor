library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity PCRegister is
	generic(
		DATA_WIDTH : natural := 16 --16 Bits data
	);
	port(		
		clock     : in  std_logic; 
		reset     : in  std_logic;
		PCWrite   : in  std_logic;
		
		PCIn      : in  std_logic_vector((DATA_WIDTH-1) downto 0);
				
		PCOut     : out std_logic_vector((DATA_WIDTH-1) downto 0) --Output Data
	);
end entity;

architecture pcr of PCRegister is 

begin
	process(clock, reset, PCWrite, PCin)
	begin
		if(reset = '1') then
			PCout <= (others => '0');	
		elsif(rising_edge(clock)) then
			if(PCWrite = '1') then
				PCout <= PCIn;
			end if;
		end if;
	end process;
end pcr;