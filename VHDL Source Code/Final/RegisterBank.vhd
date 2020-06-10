library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity RegisterBank is --Cache memory (8 regiters wide)
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
		DataOutR2 : out std_logic_vector((DATA_WIDTH-1) downto 0)  --Register 2 out
	);
end entity;

architecture rb of RegisterBank is 

	type reg is array (0 to 2**RADD_WIDTH-1) of std_logic_vector((DATA_WIDTH-1) downto 0); --Typedef to define "reg" as an array of length 2^(addr)
	
	signal registerBank : reg;
	
begin
	process(clock, reset) --Process to be triggered only when clock or reset changes
	begin
		if(reset = '1') then --If reset is set
			registerBank <= (others => (others => '0')); --Set every bit of every register to 0
			DataOutR1 <= registerBank(0); --Outputs Data in register ZERO
			DataOutR2 <= registerBank(0);	--Outputs Data in register ZERO
			
		elsif(rising_edge(clock)) then --Clock rises
			if(WriteEn = '1') then --If write is enabled
				if(writeAddr /= 0) then --If address to write is not 0
					registerBank(writeAddr) <= WriteData; --Writes the content in the position indicated with writeAddr
				else
					registerBank(0) <= (others => '0'); --Otherwise, keep it 0

				end if;
			end if;
			
			if(ReadEn = '1') then --If read enable is on
				DataOutR1 <= registerBank(addrR1); --Update both outputs with the addresses indicated in addrR1 and addrR2
				DataOutR2 <= registerBank(addrR2);
			end if;
		end if;
	end process;
end rb;