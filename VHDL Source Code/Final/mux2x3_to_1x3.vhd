library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity mux2x3_to_1x3 is --Mux to select 1 of 2 3-bit data
	generic(
		RADD_WIDTH : natural := 3 --16 Bits data
	);
	port(		
		input0    : in  std_logic_vector((RADD_WIDTH-1) downto 0); --Input 0
		input1    : in  std_logic_vector((RADD_WIDTH-1) downto 0); --Input 1
		
		Sel 	    : in  std_logic; --Selector
		
		muxOut    : out std_logic_vector((RADD_WIDTH-1) downto 0) --Output Data
	);
end entity;

architecture m2x3t1 of mux2x3_to_1x3 is 

begin
	with Sel select
		muxOut <= input0 when '0', --Select input 0 if select is 0
		          input1 when '1', --Select input 1 if select is 1
					 (others => '0') when others;
		
end m2x3t1;