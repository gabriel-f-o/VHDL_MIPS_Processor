library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity MIPSDataPath is
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
end entity;

architecture mdp of MIPSDataPath is 

	component PCRegister is
		generic(
			DATA_WIDTH : natural := 16 --16 Bits data
		);
		port(		
			clock     : in  std_logic; 
			reset     : in  std_logic;
			PCWrite   : in  std_logic;
			
			PCIn      : in  std_logic_vector((DATA_WIDTH-1) downto 0);
					
			PCOut     : out std_logic_vector((DATA_WIDTH-1) downto 0) --Output Data
		);
	end component;

	component mux2x16_to_1x16 is
		generic(
			DATA_WIDTH : natural := 16 --16 Bits data
		);
		port(		
			input0    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 0 : PC
			input1    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 1 : Reg 1 out
			
			Sel 	    : in  std_logic; --Selector is to be considered a natural (0+) number from 0 to 2^num - 1
			
			muxOut    : out std_logic_vector((DATA_WIDTH-1) downto 0) --Output Data
		);
	end component;
	component RamDataMemory is
		generic(
			DATA_WIDTH : natural := 16; --16 Bits data
			ADDR_WIDTH : natural := 6  --16 Bits Instruction address
		);
		port(
			clock		 : in  std_logic; --Clock
			reset		 : in  std_logic; --Reset 
			ReadEn    : in  std_logic; --Read from address
			WriteEn   : in  std_logic; --Write on address
			
			addrIn 	 : in  natural range 0 to (2**ADDR_WIDTH-1); --Address is to be considered a natural (0+) number from 0 to 2^num - 1
			WriteData : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Data to write
			
			DataOut   : out std_logic_vector((DATA_WIDTH-1) downto 0) --Output
		);
	end component;
	
	component instReg is
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
	end component;
	
	
	component mux2x3_to_1x3 is
		generic(
			RADD_WIDTH : natural := 3 --16 Bits data
		);
		port(		
			input0    : in  std_logic_vector((RADD_WIDTH-1) downto 0); --Input 0 : PC
			input1    : in  std_logic_vector((RADD_WIDTH-1) downto 0); --Input 1 : Reg 1 out
			
			Sel 	    : in  std_logic; --Selector is to be considered a natural (0+) number from 0 to 2^num - 1
			
			muxOut    : out std_logic_vector((RADD_WIDTH-1) downto 0) --Output Data
		);
	end component;

	component RegisterBank is
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
			DataOutR2 : out std_logic_vector((DATA_WIDTH-1) downto 0) --Register 2 out
		);
	end component;
	
	component customExtend is
		generic(
			DATA_WIDTH : natural := 16; --16 Bits data
			INPUT_WIDTH : natural := 6  --6 Bits input data
		);
		port(
			modeIn		 : in  std_logic;
			dataIn		 : in  std_logic_vector((INPUT_WIDTH-1) downto 0);
			extendedData : out std_logic_vector((DATA_WIDTH-1) downto 0)
		);
	end component;
	
	component mux4x16_to_1x16 is
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
	end component;

	component ALU is
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
	end component;

	signal PCInS : std_logic_vector((DATA_WIDTH-1) downto 0);
	signal PCOutS : std_logic_vector((DATA_WIDTH-1) downto 0);

	signal MemOutS: std_logic_vector((DATA_WIDTH-1) downto 0);
	signal DataMemoryAddrS: std_logic_vector((DATA_WIDTH-1) downto 0);

	signal firstSegS: std_logic_vector((FS_WIDTH-1) downto 0);
	signal secondSegS: std_logic_vector((SS_WIDTH-1) downto 0);
	signal lastSegS: std_logic_vector((LS_WIDTH-1) downto 0);

	signal lastSecExtendS : std_logic_vector((DATA_WIDTH-1) downto 0);

	signal WriteAddressS: std_logic_vector((RADD_WIDTH-1) downto 0);
	signal WriteDataS: std_logic_vector((DATA_WIDTH-1) downto 0);

	signal Reg1OutS: std_logic_vector((DATA_WIDTH-1) downto 0);
	signal Reg2OutS: std_logic_vector((DATA_WIDTH-1) downto 0);

	signal AluADataS: std_logic_vector((DATA_WIDTH-1) downto 0);

	signal always1S : std_logic_vector((DATA_WIDTH-1) downto 0) := ( 0 => '1', others => '0');
	signal inputExtendS: std_logic_vector((DATA_WIDTH-1) downto 0);
	
	signal AluBDataS: std_logic_vector((DATA_WIDTH-1) downto 0);

	signal AluResS: std_logic_vector((DATA_WIDTH-1) downto 0);
		
	signal DataMemoryAddrNatS : natural;
	signal firstSegNatS : natural;
	signal secondSegNatS : natural;
	signal WriteAddressNatS : natural;
	signal AluOpNatS : natural;
	
begin	
	PCInO <= PCInS;
	PCOutO <= PCOutS;

	MemOutO <= MemOutS;
	DataMemoryAddrO <= DataMemoryAddrS;

	firstSegO <= firstSegS;
	secondSegO <= secondSegS;
	lastSegO <= lastSegS;

	lastSecExtendO <= lastSecExtendS;

	WriteAddressO <= WriteAddressS;
	WriteDataO <= WriteDataS;

	Reg1OutO <= Reg1OutS;
	Reg2OutO <= Reg2OutS;

	AluADataO <= AluADataS;
	
	always1O <= always1S;
	inputExtendO <= inputExtendS;
	
	AluBDataO <= AluBDataS;

	AluResO <= AluResS;
	
	always1S <= ( 0 => '1', others => '0');

	PCReg : PCRegister port map(clock, reset, PCWriteEn, PCInS, PCOutS);

	DataMemoryAddrSelectMux : mux2x16_to_1x16 port map(PCOutS, lastSecExtendS, DataAddrSel, DataMemoryAddrS);
	
	DataMemoryAddrNatS <= to_integer(unsigned(DataMemoryAddrS));
	DataMemoryRegisterBank : RamDataMemory port map(clock, reset, MemReadEn, MemWriteEn, DataMemoryAddrNatS, Reg1OutS, MemOutS);

	InstructionRegister : instReg port map(clock, reset, IRWriteEn, MemOutS, OP, firstSegS, secondSegS, lastSegS);

	WriteAddressSelectMux : mux2x3_to_1x3 port map(secondSegS, lastSegS(RADD_WIDTH-1 downto 0), WriteAddressSel, WriteAddressS);

	WriteDataSelectMux : mux2x16_to_1x16 port map(AluResS, MemOutS, WriteDataSel, WriteDataS);

	lastSegmentExtend : customExtend port map(lastSegExtndMode, lastSegS, lastSecExtendS);
	
	firstSegNatS <= to_integer(unsigned(firstSegS));
	secondSegNatS <= to_integer(unsigned(secondSegS));
	WriteAddressNatS <= to_integer(unsigned(WriteAddressS));
	CacheRegisterBank : RegisterBank port map(clock, reset, CacheReadEn, CacheWriteEn, firstSegNatS, secondSegNatS, WriteAddressNatS, WriteDataS, Reg1OutS, Reg2OutS);

	AluInputASelectMux : mux2x16_to_1x16 port map(PCOutS, Reg1OutS, AluSelA, AluADataS);

	inputExtend : customExtend port map(inputExtndMode, usrIn, inputExtendS);

	AluInputBSelectMux : mux4x16_to_1x16 port map(always1S, Reg2OutS, lastSecExtendS, inputExtendS, AluSelB, AluBDataS);
	
	AluOpNatS <= to_integer(unsigned(AluOp));
	ArithmeticLogicUnit : ALU port map(AluADataS, AluBDataS, AluOpNatS, AluCompare, AluResS);

	PCSourceSelectMux : mux2x16_to_1x16 port map(AluResS, lastSecExtendS, PCSourceSel, PCInS);
	
	UserOutRegister : PCRegister port map(clock, reset, OutEnable, AluResS, usrOut);
end mdp;



