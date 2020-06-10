library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity RegisterBank is
	generic(
		DATA_WIDTH : natural := 16; --16 Bits data
		RADD_WIDTH : natural := 3   --3 Bits register bank address
	);
	port(
		clock		 : in  std_logic; --Clock
		reset		 : in  std_logic; --Reset 
		ReadEn    : in  std_logic; --Read from both addresses R1 and R2
		WriteEn   : in  std_logic; --Write on address in write address
		
		addrR1 	 : in  natural range 0 to (2**RADD_WIDTH-1); --Address is to be considered a natural (0+) number from 0 to 2^num - 1
		addrR2 	 : in  natural range 0 to (2**RADD_WIDTH-1); --Address is to be considered a natural (0+) number from 0 to 2^num - 1
		writeAddr : in  natural range 0 to (2**RADD_WIDTH-1); --Address is to be considered a natural (0+) number from 0 to 2^num - 1
		
		WriteData : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Data to write
		
		DataOutR1 : out std_logic_vector((DATA_WIDTH-1) downto 0); --Register 1 out
		DataOutR2 : out std_logic_vector((DATA_WIDTH-1) downto 0) --Register 2 out
	);
end entity;

architecture rb of RegisterBank is 

	type reg is array (0 to 2**RADD_WIDTH-1) of std_logic_vector((DATA_WIDTH-1) downto 0); --Typedef to define "reg" as an array of length 2^(addr)
	
	signal registerBank : reg;
	
begin
	process(clock, reset, ReadEn, WriteEn, addrR1, addrR2, writeAddr, WriteData)
	begin
		if(reset = '1') then
			registerBank <= (others => x"0000");
			DataOutR1 <= registerBank(0);
			DataOutR2 <= registerBank(0);	
			
		elsif(rising_edge(clock)) then
			if(WriteEn = '1') then
				if(writeAddr /= 0) then
					registerBank(writeAddr) <= WriteData;
				else
					registerBank(0) <= (others => '0');

				end if;
			end if;
			
			if(ReadEn = '1') then
				DataOutR1 <= registerBank(addrR1);
				DataOutR2 <= registerBank(addrR2);
			end if;
		end if;
	end process;
end rb;