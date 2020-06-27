library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity ALU is
	generic(
		DATA_WIDTH : natural := 16; --16 Bits data
		ALUOP_WIDTH   : natural := 3   --3 Bits operation ID
	);
	port(		
		inputA    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input A
		inputB    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input B
		
		aluOP 	 : in  natural range 0 to (2**ALUOP_WIDTH-1); --Operation is to be considered a natural (0+) number from 0 to 2^num - 1
		
		aluComp   : out std_logic; --Input compare result
		aluRes    : out std_logic_vector((DATA_WIDTH-1) downto 0) --Output Data
	);
end entity;

architecture ula of ALU is 

begin
	process(inputA, inputB, aluOP)
	begin
		if(aluOP = 1) then --ADD
			aluRes <= (inputA + inputB);
			aluComp <= '0';
		elsif(aluOP = 2) then --NOR
			aluRes <= NOT (inputA OR inputB);
			aluComp <= '0';
		elsif(aluOP = 3) then --AND
			aluRes <= (inputA AND inputB);
			aluComp <= '0';
	   elsif(aluOP = 4) then --Equals
			aluRes <= (others => '0');
			if(inputA = inputB) then aluComp <= '1';
			else aluComp <= '0';
			end if;
		elsif(aluOP = 5) then --Less then
			if(signed(inputA) < signed(inputB)) then 
				aluComp <= '1';
				aluRes <= (others => '1');
			else 
				aluComp <= '0';
				aluRes <= (others => '0');
			end if;		
		elsif(aluOP = 6) then --Greater then
			aluRes <= (others => '0');
			if(signed(inputA) > signed(inputB)) then aluComp <= '1';
			else aluComp <= '0';
			end if;
		else --Else
			aluRes <= (others => '0');
			aluComp <= '0';
		end if;
	end process;
end ula;
