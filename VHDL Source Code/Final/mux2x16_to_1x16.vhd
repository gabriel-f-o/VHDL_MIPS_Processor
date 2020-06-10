library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity mux2x16_to_1x16 is --Mux to select 1 from 2 16-bit data
	generic(
		DATA_WIDTH : natural := 16 --16 Bits data
	);
	port(		
		input0    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 0
		input1    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 1
		
		Sel 	    : in  std_logic; --Selector
		
		muxOut    : out std_logic_vector((DATA_WIDTH-1) downto 0) --Output Data
	);
end entity;

architecture m2t1 of mux2x16_to_1x16 is 

begin
	with Sel select
		muxOut <= input0 when '0', --Select input 0 if selector is 0
		          input1 when '1', --Select input 1 if selector is 1
					 (others => '0') when others;
		
end m2t1;