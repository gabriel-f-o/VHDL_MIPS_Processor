library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity MIPSProcessor is
	generic(
		DATA_WIDTH  : natural := 16; --16 Bits data
		INPUT_WIDTH : natural := 6;  --6 Bits input data
		ADDR_WIDTH : natural := 6;   --6 Bits Instruction address
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
		userIn : in std_logic_vector((INPUT_WIDTH-1) downto 0);
		
		userOut : out std_logic_vector((DATA_WIDTH-1) downto 0);
		
		--
		resetR : out std_logic;
		--
		PCInR : out std_logic_vector((DATA_WIDTH-1) downto 0);
		PCOutR : out std_logic_vector((DATA_WIDTH-1) downto 0);
		
		estadoAtual : out natural range 0 to 50;

		MemOutR: out std_logic_vector((DATA_WIDTH-1) downto 0);
		DataMemoryAddrR: out std_logic_vector((DATA_WIDTH-1) downto 0);

		OPR : out std_logic_vector((OP_WIDTH-1) downto 0);
		firstSegR : out std_logic_vector((FS_WIDTH-1) downto 0);
		secondSegR: out std_logic_vector((SS_WIDTH-1) downto 0);
		lastSegR: out std_logic_vector((LS_WIDTH-1) downto 0);

		lastSecExtendR : out std_logic_vector((DATA_WIDTH-1) downto 0);

		WriteAddressR: out std_logic_vector((RADD_WIDTH-1) downto 0);
		WriteDataR: out std_logic_vector((DATA_WIDTH-1) downto 0);

		Reg1OutR: out std_logic_vector((DATA_WIDTH-1) downto 0);
		Reg2OutR: out std_logic_vector((DATA_WIDTH-1) downto 0);

		AluADataR: out std_logic_vector((DATA_WIDTH-1) downto 0);

		always1R : out std_logic_vector((DATA_WIDTH-1) downto 0) := ( 0 => '1', others => '0');
		inputExtendR: out std_logic_vector((DATA_WIDTH-1) downto 0);
		
		AluBDataR: out std_logic_vector((DATA_WIDTH-1) downto 0);
		AluCompareR : out std_logic;

		AluResR: out std_logic_vector((DATA_WIDTH-1) downto 0)
	);
end entity;

architecture prss of MIPSProcessor is 

	--signal PCInR : std_logic_vector((DATA_WIDTH-1) downto 0);
	--signal PCOutR : std_logic_vector((DATA_WIDTH-1) downto 0);

	--signal MemOutR: std_logic_vector((DATA_WIDTH-1) downto 0);
	--signal DataMemoryAddrR: std_logic_vector((DATA_WIDTH-1) downto 0);

	--signal firstSegR : std_logic_vector((FS_WIDTH-1) downto 0);
	--signal secondSegR: std_logic_vector((SS_WIDTH-1) downto 0);
	--signal lastSegR: std_logic_vector((LS_WIDTH-1) downto 0);

	--signal lastSecExtendR : std_logic_vector((DATA_WIDTH-1) downto 0);

	--signal WriteAddressR: std_logic_vector((RADD_WIDTH-1) downto 0);
	--signal WriteDataR: std_logic_vector((DATA_WIDTH-1) downto 0);

	--signal Reg1OutR: std_logic_vector((DATA_WIDTH-1) downto 0);
	--signal Reg2OutR: std_logic_vector((DATA_WIDTH-1) downto 0);

	--signal AluADataR: std_logic_vector((DATA_WIDTH-1) downto 0);

	--signal always1R : std_logic_vector((DATA_WIDTH-1) downto 0) := ( 0 => '1', others => '0');
	--signal inputExtendR: std_logic_vector((DATA_WIDTH-1) downto 0);
	
	--signal AluBDataR: std_logic_vector((DATA_WIDTH-1) downto 0);

	--signal AluResR: std_logic_vector((DATA_WIDTH-1) downto 0);
		

	component Controller is
		generic(
			DATA_WIDTH  : natural := 16; --16 Bits data
			INPUT_WIDTH : natural := 6;  --6 Bits input data
			ADDR_WIDTH : natural := 6;   --6 Bits Instruction address
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
			
			AluCompare : in std_logic;
			OP : in std_logic_vector((OP_WIDTH-1) downto 0);
			
			reset : out std_logic;

			PCWriteEn : out std_logic;
			PCSourceSel : out std_logic;

			DataAddrSel : out std_logic;
			MemReadEn : out std_logic;
			MemWriteEn : out std_logic;
			
			IRWriteEn : out std_logic;
			
			WriteAddressSel : out std_logic;
			WriteDataSel : out std_logic;
			CacheReadEn : out std_logic;
			CacheWriteEn : out std_logic;
			
			AluSelA : out std_logic;
			AluSelB : out std_logic_vector((ALUB_WIDTH-1) downto 0);
			AluOp : out std_logic_vector((ALUOP_WIDTH-1) downto 0);
			
			OutEnable : out std_logic;
			
			lastSegExtndMode : out std_logic;
			inputExtndMode : out std_logic;
			

			currentSTATE : out natural range 0 to 50
			
		);
	end component;
	
	
	component MIPSDataPath is
		generic(
			DATA_WIDTH  : natural := 16; --16 Bits data
			INPUT_WIDTH : natural := 6;  --6 Bits input data
			ADDR_WIDTH : natural := 6;   --6 Bits Instruction address
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

			PCWriteEn : in std_logic;
			PCSourceSel : in std_logic;

			DataAddrSel : in std_logic;
			MemReadEn : in std_logic;
			MemWriteEn : in std_logic;
			
			IRWriteEn : in std_logic;
			
			WriteAddressSel : in std_logic;
			WriteDataSel : in std_logic;
			CacheReadEn : in std_logic;
			CacheWriteEn : in std_logic;
			
			AluSelA : in std_logic;
			AluSelB : in std_logic_vector((ALUB_WIDTH-1) downto 0);
			AluOp : in std_logic_vector((ALUOP_WIDTH-1) downto 0);

			usrIn : in std_logic_vector((INPUT_WIDTH-1) downto 0);
			
			OutEnable : in std_logic;
			
			lastSegExtndMode : in std_logic;
			inputExtndMode : in std_logic;
			
			usrOut : out std_logic_vector((DATA_WIDTH-1) downto 0);
			AluCompare : out std_logic;
			OP : out std_logic_vector((OP_WIDTH-1) downto 0);
			
			
			
			PCInO : out std_logic_vector((DATA_WIDTH-1) downto 0);
			PCOutO : out std_logic_vector((DATA_WIDTH-1) downto 0);

			MemOutO: out std_logic_vector((DATA_WIDTH-1) downto 0);
			DataMemoryAddrO: out std_logic_vector((DATA_WIDTH-1) downto 0);

			firstSegO : out std_logic_vector((FS_WIDTH-1) downto 0);
			secondSegO: out std_logic_vector((SS_WIDTH-1) downto 0);
			lastSegO: out std_logic_vector((LS_WIDTH-1) downto 0);

			lastSecExtendO : out std_logic_vector((DATA_WIDTH-1) downto 0);

			WriteAddressO: out std_logic_vector((RADD_WIDTH-1) downto 0);
			WriteDataO: out std_logic_vector((DATA_WIDTH-1) downto 0);

			Reg1OutO: out std_logic_vector((DATA_WIDTH-1) downto 0);
			Reg2OutO: out std_logic_vector((DATA_WIDTH-1) downto 0);

			AluADataO: out std_logic_vector((DATA_WIDTH-1) downto 0);

			always1O : out std_logic_vector((DATA_WIDTH-1) downto 0) := ( 0 => '1', others => '0');
			inputExtendO: out std_logic_vector((DATA_WIDTH-1) downto 0);
			
			AluBDataO: out std_logic_vector((DATA_WIDTH-1) downto 0);

			AluResO: out std_logic_vector((DATA_WIDTH-1) downto 0)
		);
	end component;
	
	signal resetS : std_logic;

	signal PCWriteEnS : std_logic;
	signal PCSourceSelS : std_logic;

	signal DataAddrSelS : std_logic;
	signal MemReadEnS : std_logic;
	signal MemWriteEnS : std_logic;

	signal IRWriteEnS : std_logic;

	signal WriteAddressSelS : std_logic;
	signal WriteDataSelS : std_logic;
	signal CacheReadEnS : std_logic;
	signal CacheWriteEnS : std_logic;

	signal AluSelAS : std_logic;
	signal AluSelBS : std_logic_vector((ALUB_WIDTH-1) downto 0);
	signal AluOpS : std_logic_vector((ALUOP_WIDTH-1) downto 0);

	signal lastSegExtndModeS : std_logic;
	signal inputExtndModeS : std_logic;

	signal AluCompareS :  std_logic;
	signal OPS : std_logic_vector((OP_WIDTH-1) downto 0);
	
	signal estadoAtualS : natural range 0 to 50;
	
	signal OutEnableS : std_logic;
	
begin	
	resetR <= resetS;
	estadoAtual <= estadoAtualS;
	OPR <= OPS;
	AluCompareR <= AluCompareS;
	
	MIPSProcessorDataPath : MIPSDataPath port map(clock, resetS, PCWriteEnS, PCSourceSelS, DataAddrSelS, MemReadEnS, MemWriteEnS, IRWriteEnS, WriteAddressSelS,
																 WriteDataSelS, CacheReadEnS, CacheWriteEnS, AluSelAS, AluSelBS, AluOpS, userIn, OutEnableS, lastSegExtndModeS, inputExtndModeS,
																 userOut, AluCompareS, OPS,
																 PCInR, PCOutR, MemOutR, DataMemoryAddrR, firstSegR, secondSegR, lastSegR, lastSecExtendR, WriteAddressR, WriteDataR,
																 Reg1OutR, Reg2OutR, AluADataR, always1R, inputExtendR, AluBDataR, AluResR);


	MIPSProcessorController : Controller port map(clock, AluCompareS, OPS, resetS, PCWriteEnS, PCSourceSelS, DataAddrSelS, MemReadEnS, MemWriteEnS, IRWriteEnS, WriteAddressSelS,
																 WriteDataSelS, CacheReadEnS, CacheWriteEnS, AluSelAS, AluSelBS, AluOpS, OutEnableS, lastSegExtndModeS, inputExtndModeS, estadoAtualS);
	
end prss;



