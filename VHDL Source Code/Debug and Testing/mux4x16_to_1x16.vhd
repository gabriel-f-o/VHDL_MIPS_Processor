library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity mux4x16_to_1x16 is
	generic(
		DATA_WIDTH : natural := 16 --16 Bits data
	);
	port(		
		input0    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 0 : constant 1
		input1    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 1 : Reg2 out
		input2    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 2 : instruction last section extended
		input3    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 3 : Input extended
		
		Sel 	    : in  std_logic_vector(1 downto 0); --Selector is to be considered a natural (0+) number from 0 to 2^num - 1
		
		muxOut    : out std_logic_vector((DATA_WIDTH-1) downto 0) --Output Data
	);
end entity;

architecture m4t1 of mux4x16_to_1x16 is 

begin
	with Sel select
		muxOut <= input0 when "00",
		          input1 when "01",
		          input2 when "10",
		          input3 when "11",
					 x"0000" when others;
		
end m4t1;