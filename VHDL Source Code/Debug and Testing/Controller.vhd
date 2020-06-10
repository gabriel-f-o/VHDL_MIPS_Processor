library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity Controller is
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
end entity;

architecture ctr of Controller is 
	type FSMstate is (RESET_S, INSTRUCTION_FETCH_S, INSTRUCTION_DECODE_S, ADD_EXEC_S, ADDI_EXEC_S, NOR_EXEC_S, 
							AND_EXEC_S, BEQ_COMPARE_DATA_S, JUMP_S, LOAD_MEM_DATA_S, LOAD_WRITE_DATA_S, STORE_DATA_S, STORE_WRITE_S, SLT_COMPARE_DATA_S, 
							IN_LOAD_DATA_S, OUT_DATA_S, MOVE_DATA_S, BGT_COMPARE_DATA_S, WAIT_S, NOTHING);	
							
	signal current_state, next_state : FSMstate := RESET_S;
		
begin	
	process(clock)
	begin 
		if(rising_edge(clock)) then
			current_state <= next_state;
		end if;
	end process;
	
	process(current_state, OP, AluCompare)
	begin
		case current_state is
			when RESET_S => 
				currentSTATE <= 0;
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
				AluOp <= "001";
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when INSTRUCTION_FETCH_S =>
				currentSTATE <= 1;
				reset <= '0';

				PCWriteEn <= '1'; --Set PC to be writen on next clock cycle
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '0';
				MemWriteEn <= '0';
				
				IRWriteEn <= '1';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '0';
				AluSelB <= "00";
				AluOp <= "001";
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_DECODE_S;
			
			when INSTRUCTION_DECODE_S =>
				currentSTATE <= 2;
				reset <= '0';

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '0';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '1';
				CacheWriteEn <= '0';
				
				AluSelA <= '0';
				AluSelB <= "00";
				AluOp <= "000";
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				case OP is
					when x"1" =>
						next_state <= ADD_EXEC_S;
					when x"2" =>
						next_state <= ADDI_EXEC_S;
					when x"3" =>
						next_state <= NOR_EXEC_S;
					when x"4" =>
						next_state <= AND_EXEC_S;
					when x"5" =>
						next_state <= BEQ_COMPARE_DATA_S;
					when x"6" =>
						next_state <= JUMP_S;
					when x"7" =>
						next_state <= LOAD_MEM_DATA_S;
					when x"8" =>
						next_state <= STORE_DATA_S;
					when x"9" =>
						next_state <= SLT_COMPARE_DATA_S;
					when x"A" =>
						next_state <= IN_LOAD_DATA_S;
					when x"B" =>
						next_state <= OUT_DATA_S;
					when x"C" =>
						next_state <= MOVE_DATA_S;
					when x"D" =>
						next_state <= BGT_COMPARE_DATA_S;
					when others =>
						next_state <= INSTRUCTION_FETCH_S;

				end case;
			
			when ADD_EXEC_S =>
				currentSTATE <= 3;
				reset <= '0';

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '1';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1';
				
				AluSelA <= '1';
				AluSelB <= "01";
				AluOp <= "001";
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when ADDI_EXEC_S =>
				currentSTATE <= 4;
				reset <= '0';

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1';
				
				AluSelA <= '1';
				AluSelB <= "10";
				AluOp <= "001";
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '1';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when NOR_EXEC_S =>
				currentSTATE <= 5;
				reset <= '0';

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '1';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1';
				
				AluSelA <= '1';
				AluSelB <= "01";
				AluOp <= "010";
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when AND_EXEC_S =>
				currentSTATE <= 6;
				reset <= '0';

				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '1';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1';
				
				AluSelA <= '1';
				AluSelB <= "01";
				AluOp <= "011";
				
				OutEnable <= '0';
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when BEQ_COMPARE_DATA_S =>
				currentSTATE <= 7;
				reset <= '0';		

				DataAddrSel <= '0';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				OutEnable <= '0';
				
				AluSelA <= '1';
				AluSelB <= "01";
				AluOp <= "100";
				
				if(AluCompare = '1') then
					PCSourceSel <= '1';
					PCWriteEn <= '1';
					MemReadEn <= '0';
					
					next_state <= WAIT_S;
				else
					PCSourceSel <= '0';
					PCWriteEn <= '0';
					MemReadEn <= '1';
					next_state <= INSTRUCTION_FETCH_S;
				end if;
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
			when WAIT_S =>
				currentSTATE <= 8;
				reset <= '0';
				
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1';
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
				
			when JUMP_S =>
				currentSTATE <= 9;
				reset <= '0';	
			
				PCWriteEn <= '1';
				PCSourceSel <= '1';

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

				next_state <= WAIT_S;
				
			when LOAD_MEM_DATA_S => 
				currentSTATE <= 10;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '1';
				MemReadEn <= '1';
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

				next_state <= LOAD_WRITE_DATA_S;
				
			when LOAD_WRITE_DATA_S =>
				currentSTATE <= 11;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '1';
				CacheReadEn <= '0';
				CacheWriteEn <= '1';
				
				AluSelA <= '0';
				AluSelB <= "00";
				AluOp <= "000";
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= INSTRUCTION_FETCH_S;
				
			when STORE_DATA_S =>
				currentSTATE <= 12;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '1';
				MemReadEn <= '0';
				MemWriteEn <= '1';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '1';
				AluSelB <= "01";
				AluOp <= "001";
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= STORE_WRITE_S;
				
			when STORE_WRITE_S =>
				currentSTATE <= 13;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '1';
				MemReadEn <= '1';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '1';
				AluSelB <= "01";
				AluOp <= "001";
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= INSTRUCTION_FETCH_S;
				
			when SLT_COMPARE_DATA_S =>
				currentSTATE <= 14;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '1';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				
				AluSelA <= '1';
				AluSelB <= "01";
				AluOp <= "101";
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
				if(AluCompare = '1') then
					CacheWriteEn <= '1';
				else
					CacheWriteEn <= '0';
				end if;
				
				next_state <= INSTRUCTION_FETCH_S;
				
			when IN_LOAD_DATA_S =>
				currentSTATE <= 15;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1';
				
				AluSelA <= '1';
				AluSelB <= "11";
				AluOp <= "001";
				
				OutEnable <= '0';

				lastSegExtndMode <= '0';
				inputExtndMode <= '1';

				next_state <= INSTRUCTION_FETCH_S;
			
			when OUT_DATA_S => 
				currentSTATE <= 16;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				AluSelA <= '1';
				AluSelB <= "01";
				AluOp <= "001";
				
				OutEnable <= '1';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= INSTRUCTION_FETCH_S;
				
			when MOVE_DATA_S =>
				currentSTATE <= 17;
				reset <= '0';	
			
				PCWriteEn <= '0';
				PCSourceSel <= '0';

				DataAddrSel <= '0';
				MemReadEn <= '1';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '1';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '1';
				
				AluSelA <= '1';
				AluSelB <= "01";
				AluOp <= "001";
				
				OutEnable <= '1';

				lastSegExtndMode <= '0';
				inputExtndMode <= '0';

				next_state <= INSTRUCTION_FETCH_S;
				
			when BGT_COMPARE_DATA_S =>
				currentSTATE <= 18;
				reset <= '0';		

				DataAddrSel <= '0';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				WriteAddressSel <= '0';
				WriteDataSel <= '0';
				CacheReadEn <= '0';
				CacheWriteEn <= '0';
				
				OutEnable <= '0';
				
				AluSelA <= '1';
				AluSelB <= "01";
				AluOp <= "110";
				
				if(AluCompare = '1') then
					PCSourceSel <= '1';
					PCWriteEn <= '1';
					MemReadEn <= '0';
					
					next_state <= WAIT_S;
				else
					PCSourceSel <= '0';
					PCWriteEn <= '0';
					MemReadEn <= '1';
					next_state <= INSTRUCTION_FETCH_S;
				end if;
				
				lastSegExtndMode <= '0';
				inputExtndMode <= '0';
				
			when NOTHING =>
				currentSTATE <= 49;
				reset <= '0';	

				PCWriteEn <= '0';

				MemReadEn <= '1';
				MemWriteEn <= '0';
				
				IRWriteEn <= '0';
				
				CacheReadEn <= '1';
				CacheWriteEn <= '0';
				
				OutEnable <= '0';
				
				next_state <= NOTHING;
				
			when others =>
				currentSTATE <= 50;
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



