library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity mux2x16_to_1x16 is
	generic(
		DATA_WIDTH : natural := 16 --16 Bits data
	);
	port(		
		input0    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 0 : PC
		input1    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 1 : Reg 1 out
		
		Sel 	    : in  std_logic; --Selector is to be considered a natural (0+) number from 0 to 2^num - 1
		
		muxOut    : out std_logic_vector((DATA_WIDTH-1) downto 0) --Output Data
	);
end entity;

architecture m2t1 of mux2x16_to_1x16 is 

begin
	with Sel select
		muxOut <= input0 when '0',
		          input1 when '1',
					 x"0000" when others;
		
end m2t1;