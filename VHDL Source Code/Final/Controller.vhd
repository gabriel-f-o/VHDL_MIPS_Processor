library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity Controller is --MIPS controller
	generic(
		DATA_WIDTH  : natural := 16; --16 Bits data
		INPUT_WIDTH : natural := 6;  --6 Bits input data
		ADDR_WIDTH : natural := 4;   --4 Bits RAM address
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
end entity;

architecture ctr of Controller is 
	type FSMstate is (RESET_S, INSTRUCTION_FETCH_S, INSTRUCTION_DECODE_S, ADD_EXEC_S, ADDI_EXEC_S, NOR_EXEC_S, 
							AND_EXEC_S, BEQ_COMPARE_DATA_S, JUMP_S, LOAD_MEM_DATA_S, LOAD_WRITE_DATA_S, STORE_DATA_S, STORE_WRITE_S, SLT_COMPARE_DATA_S, 
							IN_LOAD_DATA_S, OUT_DATA_S, MOVE_DATA_S, BGT_COMPARE_DATA_S, WAIT_S); --Possible states
							
	signal current_state, next_state : FSMstate := RESET_S; --FSM begin at RESET state
		
begin	
	process(clock) --On each clock
	begin 
		if(rising_edge(clock)) then
			current_state <= next_state; --Goes to next state
		end if;
	end process;
	
	process(current_state, AluCompare) --Process to be called if current state or AluCompare changes (important because we set ALU to compare and use its return value in the same state)
	begin
		case current_state is
			when RESET_S => --Reset State
				--currentSTATE <= 0; --Debug
				reset <= '1'; --Reset registers

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '0';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '0';
				AluSelB <= "00";
				AluOp <= "000"; 
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when INSTRUCTION_FETCH_S => --Instruction Fetch
				--currentSTATE <= 1;
				reset <= '0';

				PCWriteEn <= '1'; --Set PC to be writen on next clock cycle (PC = PC+1)
				PCSourceSel <= '0'; --Source is ALU

				DataAddrSel <= '0';
				MemReadEn <= '0';
				MemWriteEn <= '0';
				
				IRWriteEn <= '1'; --Set instruction register to be written on next clock
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '0';
				AluSelB <= "00";
				AluOp <= "001"; --Set ALU to SUM PC+1 (not necessary but I don't want risks)
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_DECODE_S;
			
			when INSTRUCTION_DECODE_S => --Instruction decode
				--currentSTATE <= 2;
				reset <= '0';

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '0';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '1'; --Enables cache to update outputs on next clock
				CacheWriteEn <= '0';
				
				AluSelA <= '0';
				AluSelB <= "00";
				AluOp <= "000";
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				case OP is --Goes to next state according on the instruction ID
					when x"1" =>
						next_state <= ADD_EXEC_S; --ADD
					when x"2" =>
						next_state <= ADDI_EXEC_S; --ADDI
					when x"3" =>
						next_state <= NOR_EXEC_S; --NOR
					when x"4" =>
						next_state <= AND_EXEC_S; --AND
					when x"5" =>
						next_state <= BEQ_COMPARE_DATA_S; --BEQ
					when x"6" =>
						next_state <= JUMP_S; --JUMP
					when x"7" =>
						next_state <= LOAD_MEM_DATA_S; --LOAD
					when x"8" =>
						next_state <= STORE_DATA_S; --STORE
					when x"9" =>
						next_state <= SLT_COMPARE_DATA_S; --SLT
					when x"A" =>
						next_state <= IN_LOAD_DATA_S; --IN
					when x"B" =>
						next_state <= OUT_DATA_S; --OUT
					when x"C" =>
						next_state <= MOVE_DATA_S; --MOVE
					when x"D" =>
						next_state <= BGT_COMPARE_DATA_S; --BGT
					when others =>
						next_state <= INSTRUCTION_FETCH_S; --NOP

				end case;
			
			when ADD_EXEC_S => --ADD exec state
				--currentSTATE <= 3;
				reset <= '0';

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1'; --Enable RAM to update (to be ready on fetch)
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '1'; --Selects last segment as write address
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1'; --Enable writing on next clock
				
				AluSelA <= '1'; --Source = REG1
				AluSelB <= "01"; --Source = REG2
				AluOp <= "001"; --ADD
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when ADDI_EXEC_S => --ADDI exec state
				--currentSTATE <= 4;
				reset <= '0';

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1'; --Enable RAM to update (to be ready on fetch)
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0'; --Selects second segment as write address
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1'; --Enable writing on next clock
				
				AluSelA <= '1'; --Source REG1
				AluSelB <= "10"; --Source extended last segment
				AluOp <= "001"; --ADD
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '1'; --Do a sign extend
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when NOR_EXEC_S => --NOR state
				--currentSTATE <= 5;
				reset <= '0';

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1'; --Enable RAM to update (to be ready on fetch)
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '1'; --Selects last segment as write address
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1'; --Enable writing on next clock
				
				AluSelA <= '1'; --Source REG1
				AluSelB <= "01"; --Source REG2
				AluOp <= "010"; --NOR
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when AND_EXEC_S => --AND state
				--currentSTATE <= 6;
				reset <= '0';

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1'; --Enable RAM to update (to be ready on fetch)
				MemWriteEn <= '0'; 
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '1'; --Selects last segment as write address
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1'; --Enable writing on next clock
				
				AluSelA <= '1'; --Source REG1
				AluSelB <= "01"; --Source REG2
				AluOp <= "011"; --AND
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when BEQ_COMPARE_DATA_S => --BEQ
				--currentSTATE <= 7;
				reset <= '0';		

				DataAddrSel <= '0';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				OutEnable <= '0';
				
				AluSelA <= '1'; --Source REG1
				AluSelB <= "01"; --Source REG2
				AluOp <= "100"; -- "A == B"
				
				if(AluCompare = '1') then --If A == B
					PCSourceSel <= '1'; --PC source is last segment 
					PCWriteEn <= '1'; --PC write on next clock
					MemReadEn <= '0'; 
					
					next_state <= WAIT_S; --Wait
				else
					PCSourceSel <= '0'; --PC source remains ALU
					PCWriteEn <= '0'; --No need to write
					MemReadEn <= '1'; --Read from RAM
					
					next_state <= INSTRUCTION_FETCH_S;
				end if;
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
			when WAIT_S => --Wait state
				--currentSTATE <= 8;
				reset <= '0';
				
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1'; --Enables to read RAM on next clock
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '0';
				AluSelB <= "00";
				AluOp <= "000";
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when JUMP_S => --Jump
				--currentSTATE <= 9;
				reset <= '0';	
			
				PCWriteEn <= '1'; --Enable PC write on next clock
				PCSourceSel <= '1'; --Selects source as last segment

				DataAddrSel <= '0';
				MemReadEn <= '0';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '0';
				AluSelB <= "00";
				AluOp <= "000";
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= WAIT_S; --Wait
				
			when LOAD_MEM_DATA_S => --Load
				--currentSTATE <= 10;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '1'; --RAM Data address as last segment
				MemReadEn <= '1'; --Enable reading
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '0';
				AluSelB <= "00";
				AluOp <= "000";
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= LOAD_WRITE_DATA_S; --Write back
				
			when LOAD_WRITE_DATA_S => --Load write back
				--currentSTATE <= 11;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1'; --Enable RAM read on next clock
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0'; --Write on second segment address
				WriteDataSel <= '1'; --Cache data source as RAM
				CacheReadEn <= '0'; 
				CacheWriteEn <= '1'; --Enable writing
				
				AluSelA <= '0';
				AluSelB <= "00";
				AluOp <= "000";
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= INSTRUCTION_FETCH_S;
				
			when STORE_DATA_S => --Store
				--currentSTATE <= 12;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '1'; --RAM data address as last segment
				MemReadEn <= '0';
				MemWriteEn <= '1'; --Enable RAM write on next clock
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '1'; --REG1 (ZERO)
				AluSelB <= "01"; --REG2
				AluOp <= "001"; --ADD
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= STORE_WRITE_S; --Write back
				
			when STORE_WRITE_S => --Store write back
				--currentSTATE <= 13;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '1'; --Data address as last segment
				MemReadEn <= '1'; --Read enable on next clock
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0'; 
				WriteDataSel <= '0'; 
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '1'; --REG1 (ZERO)
				AluSelB <= "01"; --REG2
				AluOp <= "001"; --ADD
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= INSTRUCTION_FETCH_S;
				
			when SLT_COMPARE_DATA_S => --SLT
				--currentSTATE <= 14;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1'; --Enable RAM read on next clock
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '1'; --Write on last segment address 
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				
				AluSelA <= '1'; --REG1
				AluSelB <= "01"; --REG2
				AluOp <= "101"; -- "<"
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				if(AluCompare = '1') then --If REG1 < REG2
					CacheWriteEn <= '1'; --Write AluRes on cache
				else
					CacheWriteEn <= '0'; --Do nothing
				end if;
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when IN_LOAD_DATA_S => --Input
				--currentSTATE <= 15;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1'; --Enable RAM read on next clock
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0'; --Second segment address
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1'; --Enable Cache write on next clock
				
				AluSelA <= '1'; --REG1 (ZERO)
				AluSelB <= "11"; --Input extended
				AluOp <= "001"; --ADD
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '1'; --Sign extend

				next_state <= INSTRUCTION_FETCH_S;
			
			when OUT_DATA_S => --Output
				--currentSTATE <= 16;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1'; --Enable RAM read on next clock
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '1'; --REG1 (ZERO)
				AluSelB <= "01"; --REG2
				AluOp <= "001"; --ADD
				
				OutEnable <= '1'; --Enable output update

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= INSTRUCTION_FETCH_S;
				
			when MOVE_DATA_S => --Move
				--currentSTATE <= 17;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1'; --Enable RAM read on next clock
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '1'; --Last segment address
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1'; --Write enable
				
				AluSelA <= '1'; --REG1 (ZERO)
				AluSelB <= "01"; --REG2
				AluOp <= "001"; --ADD
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= INSTRUCTION_FETCH_S;
				
			when BGT_COMPARE_DATA_S => --BGT
				--currentSTATE <= 18;
				reset <= '0';		

				DataAddrSel <= '0';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				OutEnable <= '0';
				
				AluSelA <= '1'; --REG1
				AluSelB <= "01"; --REG2
				AluOp <= "110"; -- ">"
				
				if(AluCompare = '1') then --If REG1 > REG2
					PCSourceSel <= '1'; --PC source is last segment
					PCWriteEn <= '1'; --Write on next clock
					MemReadEn <= '0';
					
					next_state <= WAIT_S; --wait
				else
					PCSourceSel <= '0';
					PCWriteEn <= '0';
					MemReadEn <= '1';
					next_state <= INSTRUCTION_FETCH_S;
				end if;
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
			when others => --Just in case
				--currentSTATE <= 50;
				reset <= '1';

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '0';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '0';
				AluSelB <= "00";
				AluOp <= "000";
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
		end case;
	end process;
end ctr;



