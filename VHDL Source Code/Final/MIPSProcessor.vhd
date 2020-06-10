library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity MIPSProcessor is
	generic(
		DATA_WIDTH  : natural := 16; --16 Bits data
		INPUT_WIDTH : natural := 6;  --6 Bits input data
		ADDR_WIDTH : natural := 4;   --6 Bits Instruction address
		RADD_WIDTH : natural := 3;   --3 Bits register bank address
		
		OP_WIDTH	  : natural := 4; --OP width
		FS_WIDTH	  : natural := 3; --First segment width
		SS_WIDTH	  : natural := 3; --Second segment width
		LS_WIDTH   : natural := 6; --Last segment width
		
		ALUB_WIDTH : natural := 2; --ALU B mux selector size
		
		ALUOP_WIDTH : natural := 3   --3 Bits operation ID
	);
	port(
		clock : in std_logic;
		userIn : in std_logic_vector((INPUT_WIDTH-1) downto 0);
		
		userOut : out std_logic_vector((DATA_WIDTH-1) downto 0)
	);
end entity;

architecture prss of MIPSProcessor is 	

	component Controller is --MIPS controller
		generic(
			DATA_WIDTH  : natural := 16; --16 Bits data
			INPUT_WIDTH : natural := 6;  --6 Bits input data
			ADDR_WIDTH : natural := 4;   --6 Bits RAM address
			RADD_WIDTH : natural := 3;   --3 Bits register bank address
			
			OP_WIDTH	  : natural := 4; --OP width
			FS_WIDTH	  : natural := 3; --First segment width
			SS_WIDTH	  : natural := 3; --Second segment width
			LS_WIDTH   : natural := 6; --Last segment width
			
			ALUB_WIDTH : natural := 2; --ALU B mux selector size
			
			ALUOP_WIDTH : natural := 3 --3 Bits operation ID
		);
		port(
			clock : in std_logic;
			
			AluCompare : in std_logic; --Used to BEQ, SLT and BGT
			OP : in std_logic_vector((OP_WIDTH-1) downto 0); --Instruction ID
			
			reset : out std_logic; --Reset every component

			PCWriteEn : out std_logic; --Enable PC write
			PCSourceSel : out std_logic; --Select PC source

			DataAddrSel : out std_logic; --Select RAM address source
			MemReadEn : out std_logic; --Enable RAM read
			MemWriteEn : out std_logic; --Enable RAM write
			
			IRWriteEn : out std_logic; --Inable Instruction register write
			
			WriteAddressSel : out std_logic; --Selecs cache write address source
			WriteDataSel : out std_logic; --Selects cache write data source
			CacheReadEn : out std_logic; --Enable read from cache
			CacheWriteEn : out std_logic; --Enable write on cache
			
			AluSelA : out std_logic; --Selecs ALU input A source
			AluSelB : out std_logic_vector((ALUB_WIDTH-1) downto 0); --Selects ALU input B source
			AluOp : out std_logic_vector((ALUOP_WIDTH-1) downto 0); --Choose operation
			
			OutEnable : out std_logic; --Enable output register update
			
			lastSegExtndMode : out std_logic; --Choose mode for signal extender
			inputExtndMode : out std_logic --Choose mode for signal extender
			
		);
	end component;
		
	
	component MIPSDataPath is --MIPS Datapath, has all the physical components and an interface to connect with the controller
		generic(
			DATA_WIDTH  : natural := 16; --16 Bits data
			INPUT_WIDTH : natural := 6;  --6 Bits input data
			ADDR_WIDTH : natural := 4;   --6 Bits RAM address
			RADD_WIDTH : natural := 3;   --3 Bits register bank address
			
			OP_WIDTH	  : natural := 4; --OP width
			FS_WIDTH	  : natural := 3; --First segment width
			SS_WIDTH	  : natural := 3; --Second segment width
			LS_WIDTH   : natural := 6; --Last segment width
			
			ALUB_WIDTH : natural := 2;
			
			ALUOP_WIDTH : natural := 3   --3 Bits operation ID
		);
		port(
			clock : in std_logic;
			reset : in std_logic;

			PCWriteEn : in std_logic; --Write to PC
			PCSourceSel : in std_logic; --Selects data to go to PC (ALU or JUMP instructions)

			DataAddrSel : in std_logic; --Selects the RAM address (PC or LOAD / STORE instructions)
			MemReadEn : in std_logic; --Updates output
			MemWriteEn : in std_logic; --Enable RAM writing
			
			IRWriteEn : in std_logic; --Enable instruction write
			
			WriteAddressSel : in std_logic; --Address to write in cache (Second segment or last -> ADD or ADDI instrcutions)
			WriteDataSel : in std_logic; --Select data to go to cache (AluRes or RAM)
			CacheReadEn : in std_logic; --Enable output update
			CacheWriteEn : in std_logic; --Enable cache writing
			
			AluSelA : in std_logic; --Selects ALU input A (PC or REG1)
			AluSelB : in std_logic_vector((ALUB_WIDTH-1) downto 0); --Selects ALU input B (1, REG2, last segment Extended or input extended)
			AluOp : in std_logic_vector((ALUOP_WIDTH-1) downto 0); --Selects ALU operation(NOP, ADD, NOR, AND, ==, <, >, NOP...)

			usrIn : in std_logic_vector((INPUT_WIDTH-1) downto 0); --User input data
			
			OutEnable : in std_logic; --Enable output register update
			
			lastSegExtndMode : in std_logic; --Mode to use custom extender for last segment
			inputExtndMode : in std_logic; --Mode to use custom extender for input
			
			usrOut : out std_logic_vector((DATA_WIDTH-1) downto 0); --Output
			AluCompare : out std_logic; --Control bit for ALU operations ==, < and >
			OP : out std_logic_vector((OP_WIDTH-1) downto 0) --Instruction ID
			
		);
	end component;
	
	signal resetS : std_logic; --reset signal

	signal PCWriteEnS : std_logic; --PC write enable
	signal PCSourceSelS : std_logic; --PC source mux selector (ALU or Last segment)

	signal DataAddrSelS : std_logic; --Data address mux selector (PC or Last segment)
	signal MemReadEnS : std_logic; --RAM read enable
	signal MemWriteEnS : std_logic; --RAM write enable

	signal IRWriteEnS : std_logic; --Instruction register write enable

	signal WriteAddressSelS : std_logic; --Write address mux select (second or last segment)
	signal WriteDataSelS : std_logic; --Write data mux select (ALU or RAM)
	signal CacheReadEnS : std_logic; --Cache read enable
	signal CacheWriteEnS : std_logic; --Cache write enable

	signal AluSelAS : std_logic; --Alu A select mux (PC or REG1)
	signal AluSelBS : std_logic_vector((ALUB_WIDTH-1) downto 0); --Alu B select mux (1, REG2, last segment or input)
	signal AluOpS : std_logic_vector((ALUOP_WIDTH-1) downto 0); --Alu operation

	signal lastSegExtndModeS : std_logic; --Custom extender modes
	signal inputExtndModeS : std_logic;

	signal AluCompareS :  std_logic; --Alu compare
	signal OPS : std_logic_vector((OP_WIDTH-1) downto 0); --Instruction ID
		
	signal OutEnableS : std_logic; --Output enable
	
begin		
	MIPSProcessorDataPath : MIPSDataPath port map(clock, resetS, PCWriteEnS, PCSourceSelS, DataAddrSelS, MemReadEnS, MemWriteEnS, IRWriteEnS, WriteAddressSelS,
																 WriteDataSelS, CacheReadEnS, CacheWriteEnS, AluSelAS, AluSelBS, AluOpS, userIn, OutEnableS, lastSegExtndModeS, inputExtndModeS,
																 userOut, AluCompareS, OPS); --Create datapath


	MIPSProcessorController : Controller port map(clock, AluCompareS, OPS, resetS, PCWriteEnS, PCSourceSelS, DataAddrSelS, MemReadEnS, MemWriteEnS, IRWriteEnS, WriteAddressSelS,
																 WriteDataSelS, CacheReadEnS, CacheWriteEnS, AluSelAS, AluSelBS, AluOpS, OutEnableS, lastSegExtndModeS, inputExtndModeS); --Connect with controller
	
end prss;



