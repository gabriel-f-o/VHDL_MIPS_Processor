library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity instReg is
	generic(
		OP_WIDTH	  : natural := 4; --OP width
		FS_WIDTH	  : natural := 3; --First segment width
		SS_WIDTH	  : natural := 3; --Second segment width
		LS_WIDTH   : natural := 6; --Last segment width
		DATA_WIDTH : natural := 16 --8Bits data
	);
	port(
		clock		 : in  std_logic;
		reset		 : in  std_logic;
		IRWrite   : in  std_logic;
		instIn    : in  std_logic_vector((DATA_WIDTH-1) downto 0);
		
		OP			 : out std_logic_vector((OP_WIDTH-1) downto 0);	
		firstSeg	 : out std_logic_vector((FS_WIDTH-1) downto 0);	--First 3 bits after OP
		secondSeg : out std_logic_vector((SS_WIDTH-1) downto 0);	--3 bits after first
		lastSeg	 : out std_logic_vector((LS_WIDTH-1) downto 0)		--Last 6 bits after OP
	);
end entity;

architecture ir of instReg is

	
begin
	process(clock, reset, IRWrite, instIn)
	begin
		if(reset = '1') then --Reset makes everything go to 0
			OP 		 <= (others => '0');
			firstSeg  <= (others => '0');
			secondSeg <= (others => '0');
			lastSeg 	 <= (others => '0');
	
		elsif(rising_edge(clock)) then --On clock
			if(IRWrite = '1') then --On IRWrite enabled, update output
				lastSeg 	 <= instIn((LS_WIDTH-1) downto 0); --0 to 5
				secondSeg <= instIn((SS_WIDTH-1 + LS_WIDTH) downto LS_WIDTH); -- 6 to 8
				firstSeg  <= instIn((FS_WIDTH-1 + SS_WIDTH + LS_WIDTH) downto (SS_WIDTH + LS_WIDTH)); -- 9 to 11
				OP 		 <= instIn((DATA_WIDTH-1) downto (DATA_WIDTH - OP_WIDTH)); --12 to 15
			end if;
		end if;
		
	end process;
end ir;