library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity MIPSDataPath is --MIPS Datapath, has all the physical components and an interface to connect with the controller
	generic(
		DATA_WIDTH  : natural := 16; --16 Bits data
		INPUT_WIDTH : natural := 6;  --6 Bits input data
		ADDR_WIDTH : natural := 4;   --4 Bits RAM address
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
end entity;

architecture mdp of MIPSDataPath is 

	component BasicRegister is --Normal register (sensible to rising clock edge)
		generic(
			DATA_WIDTH : natural := 16 --16 Bits data
		);
		port(		
			clock     : in  std_logic; 
			reset     : in  std_logic;
			RegWrite   : in  std_logic;
			
			RegIn      : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input data
					
			RegOut     : out std_logic_vector((DATA_WIDTH-1) downto 0)  --Output Data
		);
	end component;

	component mux2x16_to_1x16 is --Mux to select 1 from 2 16-bit data
		generic(
			DATA_WIDTH : natural := 16 --16 Bits data
		);
		port(		
			input0    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 0
			input1    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input 1
			
			Sel 	    : in  std_logic; --Selector
			
			muxOut    : out std_logic_vector((DATA_WIDTH-1) downto 0) --Output Data
		);
	end component;

		
	component RamDataMemory is --Ram memory, for simplicity sake, we'll keep only 2^6 regiters
		generic(
			DATA_WIDTH : natural := 16; --16 Bits data
			ADDR_WIDTH : natural := 4   --4 Bits RAM address
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
		
	component InstructionRegister is --Instruction register, special to cut the instruction into parts
		generic(
			OP_WIDTH	  : natural := 4; --OP width
			FS_WIDTH	  : natural := 3; --First segment width
			SS_WIDTH	  : natural := 3; --Second segment width
			LS_WIDTH   : natural := 6; --Last segment width
			DATA_WIDTH : natural := 16 --16 Bits data
		);
		port(
			clock		 : in  std_logic;
			reset		 : in  std_logic;
			IRWrite   : in  std_logic;
			instIn    : in  std_logic_vector((DATA_WIDTH-1) downto 0);
			
			OP			 : out std_logic_vector((OP_WIDTH-1) downto 0);	--4 bits operation ID
			firstSeg	 : out std_logic_vector((FS_WIDTH-1) downto 0);	--First 3 bits after OP
			secondSeg : out std_logic_vector((SS_WIDTH-1) downto 0);	--3 bits after first
			lastSeg	 : out std_logic_vector((LS_WIDTH-1) downto 0)	--Last 6 bits
		);
	end component;
		
		
	component mux2x3_to_1x3 is --Mux to select 1 of 2 3-bit data
		generic(
			RADD_WIDTH : natural := 3 --16 Bits data
		);
		port(		
			input0    : in  std_logic_vector((RADD_WIDTH-1) downto 0); --Input 0
			input1    : in  std_logic_vector((RADD_WIDTH-1) downto 0); --Input 1
			
			Sel 	    : in  std_logic; --Selector
			
			muxOut    : out std_logic_vector((RADD_WIDTH-1) downto 0) --Output Data
		);
	end component;

	component RegisterBank is --Cache memory (8 regiters wide)
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
			DataOutR2 : out std_logic_vector((DATA_WIDTH-1) downto 0)  --Register 2 out
		);
	end component;
		
	component customExtend is --Custom extend, if mode = 0 -> zero extend, if mode = 1 -> sign extend
		generic(
			DATA_WIDTH : natural := 16; --16 Bits data
			INPUT_WIDTH : natural := 6  --6 Bits input data
		);
		port(
			modeIn		 : in  std_logic; --Mode
			dataIn		 : in  std_logic_vector((INPUT_WIDTH-1) downto 0); --Input data
			extendedData : out std_logic_vector((DATA_WIDTH-1) downto 0) 	--Output data
		);
	end component;
		
	component mux4x16_to_1x16 is --Mux to select 1 of 4 16-bit data
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
	end component;

	component ALU is --Arithmetic Logic Unit
		generic(
			DATA_WIDTH : natural := 16;  --16 Bits data
			ALUOP_WIDTH   : natural := 3 --3 Bits operation ID
		);
		port(		
			inputA    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input A
			inputB    : in  std_logic_vector((DATA_WIDTH-1) downto 0); --Input B
			
			aluOP 	 : in  std_logic_vector((ALUOP_WIDTH-1) downto 0); --Operation
			
			aluComp   : out std_logic; --Input compare result
			aluRes    : out std_logic_vector((DATA_WIDTH-1) downto 0) --Output Data
		);
	end component;

	signal PCInS : std_logic_vector((DATA_WIDTH-1) downto 0); --PC input signal
	signal PCOutS : std_logic_vector((DATA_WIDTH-1) downto 0); --PC output signal

	signal MemOutS: std_logic_vector((DATA_WIDTH-1) downto 0); --RAM output signal
	signal DataMemoryAddrS: std_logic_vector((DATA_WIDTH-1) downto 0); --RAM input address signal

	signal firstSegS: std_logic_vector((FS_WIDTH-1) downto 0); --First segment signal
	signal secondSegS: std_logic_vector((SS_WIDTH-1) downto 0); --Second segment signal
	signal lastSegS: std_logic_vector((LS_WIDTH-1) downto 0); --Last segment signal

	signal lastSecExtendS : std_logic_vector((DATA_WIDTH-1) downto 0); --Last segment extended signal

	signal WriteAddressS: std_logic_vector((RADD_WIDTH-1) downto 0); --Cache input address (to write) signal
	signal WriteDataS: std_logic_vector((DATA_WIDTH-1) downto 0); --Cache input data (to write) signal

	signal Reg1OutS: std_logic_vector((DATA_WIDTH-1) downto 0); --Reg 1 cache output signal
	signal Reg2OutS: std_logic_vector((DATA_WIDTH-1) downto 0); --Reg 2 cache output signal

	signal AluADataS: std_logic_vector((DATA_WIDTH-1) downto 0); --ALU input A signal
	signal AluBDataS: std_logic_vector((DATA_WIDTH-1) downto 0); --ALU input B signal

	signal always1S : std_logic_vector((DATA_WIDTH-1) downto 0) := ( 0 => '1', others => '0'); --Always 1 to increment PC
	signal inputExtendS: std_logic_vector((DATA_WIDTH-1) downto 0); --Input extended signal

	signal AluResS: std_logic_vector((DATA_WIDTH-1) downto 0); --ALU result signal
		
	signal DataMemoryAddrNatS : natural range 0 to (2**ADDR_WIDTH-1); --RAM Input address as natural
	
	signal firstSegNatS : natural range 0 to (2**RADD_WIDTH-1) ; --First segment as natural
	signal secondSegNatS : natural range 0 to (2**RADD_WIDTH-1); --Second segment as natural
	signal WriteAddressNatS : natural range 0 to (2**RADD_WIDTH-1); --Last segment as natural
	
begin	
	always1S <= ( 0 => '1', others => '0');

	PCRegister : BasicRegister port map(clock, reset, PCWriteEn, PCInS, PCOutS); --Form PC register

	DataMemoryAddrSelectMux : mux2x16_to_1x16 port map(PCOutS, lastSecExtendS, DataAddrSel, DataMemoryAddrS); --RAM Mux
	
	DataMemoryAddrNatS <= to_integer(unsigned(DataMemoryAddrS((ADDR_WIDTH-1) downto 0)));
	DataMemoryRegisterBank : RamDataMemory port map(clock, reset, MemReadEn, MemWriteEn, DataMemoryAddrNatS, Reg1OutS, MemOutS); --RAM

	InstRegister : InstructionRegister port map(clock, reset, IRWriteEn, MemOutS, OP, firstSegS, secondSegS, lastSegS); --Instruction register

	WriteAddressSelectMux : mux2x3_to_1x3 port map(secondSegS, lastSegS(RADD_WIDTH-1 downto 0), WriteAddressSel, WriteAddressS); --Cache addr Mux

	WriteDataSelectMux : mux2x16_to_1x16 port map(AluResS, MemOutS, WriteDataSel, WriteDataS); --Cache data source Mux

	lastSegmentExtend : customExtend port map(lastSegExtndMode, lastSegS, lastSecExtendS); --Extend last segment
	
	firstSegNatS <= to_integer(unsigned(firstSegS));
	secondSegNatS <= to_integer(unsigned(secondSegS));
	WriteAddressNatS <= to_integer(unsigned(WriteAddressS));
	CacheRegisterBank : RegisterBank port map(clock, reset, CacheReadEn, CacheWriteEn, firstSegNatS, secondSegNatS, WriteAddressNatS, WriteDataS, Reg1OutS, Reg2OutS); --Cache

	AluInputASelectMux : mux2x16_to_1x16 port map(PCOutS, Reg1OutS, AluSelA, AluADataS); --ALU A Mux

	inputExtend : customExtend port map(inputExtndMode, usrIn, inputExtendS); --Input extend

	AluInputBSelectMux : mux4x16_to_1x16 port map(always1S, Reg2OutS, lastSecExtendS, inputExtendS, AluSelB, AluBDataS); --ALU B mux

	ArithmeticLogicUnit : ALU port map(AluADataS, AluBDataS, AluOp, AluCompare, AluResS); --ALU

	PCSourceSelectMux : mux2x16_to_1x16 port map(AluResS, lastSecExtendS, PCSourceSel, PCInS); --PC source Mux
	
	UserOutRegister : BasicRegister port map(clock, reset, OutEnable, AluResS, usrOut); --Output register
end mdp;



