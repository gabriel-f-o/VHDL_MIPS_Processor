library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity mux4x16_to_1x16 is --Mux to select 1 of 4 16-bit data
	generic(
		DATA_WIDTH : natural := 16 --16 Bits data
	);
	port(		
		input0    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 0
		input1    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 1 
		input2    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 2 
		input3    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 3 
		
		Sel 	    : in  std_logic_vector(1 downto 0); --Selector
		
		muxOut    : out std_logic_vector((DATA_WIDTH-1) downto 0) --Output Data
	);
end entity;

architecture m4t1 of mux4x16_to_1x16 is 

begin
	with Sel select
		muxOut <= input0 when "00", --Selects input 0 if select is 0
		          input1 when "01", --Selects input 1 if select is 1
		          input2 when "10", --Selects input 2 if select is 2
		          input3 when "11", --Selects input 3 if select is 3
					 (others => '0') when others;
		
end m4t1;