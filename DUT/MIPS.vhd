---------------------------------------------------------------------------------------------
-- Top Level Structural Model for MIPS Processor Core
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_comilation_package.all;
USE work.aux_package.all;

ENTITY MIPS IS
	generic( 
		WORD_GRANULARITY: boolean := G_WORD_GRANULARITY;
	        MODELSIM 	: integer := G_MODELSIM;
		DATA_BUS_WIDTH 	: integer := 32;
		ITCM_ADDR_WIDTH : integer := G_ADDRWIDTH;
		DTCM_ADDR_WIDTH : integer := G_ADDRWIDTH;
		DATA_WORDS_NUM 	: integer := G_DATA_WORDS_NUM;
	        CtrlBusSize	: integer := 8;
		AddrBusSize	: integer := 32;
		DataBusSize	: integer := 32
	);
	PORT(rst_i, clk_i				: IN 	STD_LOGIC;
		ControlBus			        : OUT	STD_LOGIC_VECTOR(CtrlBusSize-1 DOWNTO 0);
		MemReadBus			        : OUT 	STD_LOGIC;
		MemWriteBus			        : OUT 	STD_LOGIC;
		AddrBus				        : OUT	STD_LOGIC_VECTOR(AddrBusSize-1 DOWNTO 0);
		GIE					: OUT	STD_LOGIC;
		INTR				        : IN	STD_LOGIC;
		INTA				        : OUT	STD_LOGIC;
		INTR_Active			        : IN	STD_LOGIC;
		CLR_IRQ				        : IN	STD_LOGIC_VECTOR(6 DOWNTO 0);
		DataBus				        : INOUT	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0) 
	);		
END MIPS;

-------------------------------------------------------------------------------------
ARCHITECTURE structure OF MIPS IS
        ---- MCU BUS ----
	SIGNAL DataInBus		: STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0);
	-- declare signals used to connect VHDL components
	SIGNAL IFpc		: STD_LOGIC_VECTOR( 9 DOWNTO 0 ) := (others => '0');
	------ Control Registers ------
	-- WB -- 
	SIGNAL MemtoReg_WB, MemtoReg_MEM, MemtoReg_EX, MemtoReg_ID 			: STD_LOGIC_VECTOR(1 downto 0);
	SIGNAL RegWrite_WB, RegWrite_MEM, RegWrite_EX, RegWrite_ID 			: STD_LOGIC := '0';
	
	-- MEM --
	SIGNAL Zero_MEM, Zero_EX 					: STD_LOGIC := '0';
	SIGNAL Branch_MEM, Branch_EX, Branch_ID 			: STD_LOGIC := '0';
	SIGNAL MemWrite_MEM, MemWrite_EX, MemWrite_ID 			: STD_LOGIC := '0';
	SIGNAL MemRead_MEM, MemRead_EX, MemRead_ID 			: STD_LOGIC := '0';
	SIGNAL Branch_ctrl_MEM, Branch_ctrl_EX, Branch_ctrl_ID		: STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
	SIGNAL Jump_MEM, Jump_EX, Jump_ID				: STD_LOGIC := '0';
	
	-- Forwarding Unit
	SIGNAL ForwardA, ForwardB					: STD_LOGIC_VECTOR(1 DOWNTO 0) := (others => '0');
	SIGNAL ForwardA_ID, ForwardB_ID					: STD_LOGIC := '0'; -- Branch Forwarding
	
	-- EXEC -- 
	SIGNAL RegDst_EX, RegDst_ID 					: STD_LOGIC_VECTOR(1 DOWNTO 0) := (others => '0');
	SIGNAL ALUSrc_EX, ALUSrc_ID 					: STD_LOGIC := '0';
	SIGNAL ALUOp_EX, ALUOp_ID 					: STD_LOGIC_VECTOR(3 DOWNTO 0) := (others => '0');
	
	-- Hazard Unit -- Stall AND Flush
	SIGNAL Stall_IF, Stall_ID, Flush_EX				: STD_LOGIC := '0';
	
	-- Instruction Decode --
	SIGNAL PCSrc_ID							: STD_LOGIC_VECTOR(1 DOWNTO 0) := (others => '0');

	-------- States Registers ------
	-- Instruction Fetch
	SIGNAL PC_plus_4_IF						: STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
	SIGNAL IR_IF		  					: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');

	-- Instruction Decode
	SIGNAL PC_plus_4_ID				     		: STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
	SIGNAL IR_ID		    			  		: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0'); 
	SIGNAL read_data1_ID, read_data2_ID 		 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL Sign_extend_ID				 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL WrRegAddr0_ID, WrRegAddr1_ID	 			: STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := (others => '0');
	SIGNAL BranchAddr_ID						: STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	SIGNAL JumpAddr_ID						: STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	

	-- Execute                                                  
	SIGNAL PC_plus_4_EX				      		: STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
	SIGNAL IR_EX		    			  		: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0'); 
	SIGNAL read_data1_EX, read_data2_EX 				: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL Sign_extend_EX				  		: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL WrRegAddr0_EX, WrRegAddr1_EX, WrRegAddr_EX		: STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := (others => '0');
	SIGNAL write_data_EX						: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL Add_Result_EX						: STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := (others => '0');
	SIGNAL ALU_Result_EX					   	: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL Opcode_EX						: STD_LOGIC_VECTOR( 5 DOWNTO 0 ) := (others => '0');
																
	-- Memory     
	SIGNAL IR_MEM		  					: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL PC_plus_4_MEM			      			: STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');	
	SIGNAL Add_Result_MEM						: STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := (others => '0');
	SIGNAL ALU_Result_MEM						: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL write_data_MEM, read_data_MEM				: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL WrRegAddr_MEM						: STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := (others => '0');									    
	SIGNAL JumpAddr_MEM						: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	
	-- WriteBack
	SIGNAL IR_WB		  					: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL PC_plus_4_WB				      		: STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
	SIGNAL read_data_WB						: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL ALU_Result_WB						: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL WrRegAddr_WB						: STD_LOGIC_VECTOR( 4 DOWNTO 0 ) := (others => '0'); 
	SIGNAL write_data_WB						: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	SIGNAL write_data_mux_WB					: STD_LOGIC_VECTOR( 31 DOWNTO 0 ) := (others => '0');
	------------------------------------------------------
	-- Interrupt Signals
	SIGNAL Addr_MEM						: STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0);
	SIGNAL ISR_Addr						: STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0);
	SIGNAL EPC						: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL Int_Flush_IF, Int_Flush_ID, Int_Flush_EX 	: STD_LOGIC;
	SIGNAL INTA_s						: STD_LOGIC;
	SIGNAL ISR_PC_RD					: STD_LOGIC;
	SIGNAL is_Branch					: STD_LOGIC;
	SIGNAL INTR_Single					: STD_LOGIC;
	SIGNAL PC_HOLD						: STD_LOGIC;

BEGIN
-----------------------------------------------------------------------------------------------------
	------ MCU ------
	ControlBus	<= write_data_MEM(CtrlBusSize-1 DOWNTO 0) WHEN ((ALU_Result_MEM(11 DOWNTO 0) = X"81C") OR    -- BTCTL
										(ALU_Result_MEM(11 DOWNTO 0) = X"82C") OR    -- FIRCTL
										(ALU_Result_MEM(11 DOWNTO 0) = X"818")) ELSE -- UCTL
			   X"00";	 
	MemReadBus	<= MemRead_MEM;
	MemWriteBus	<= MemWrite_MEM;
	AddrBus		<= X"00000" & ALU_Result_MEM(11 DOWNTO 0) WHEN (MemRead_MEM = '1' OR MemWrite_MEM = '1') ELSE (OTHERS => '0');
	DataInBus	<= DataBus WHEN (ALU_Result_MEM(11) = '1' AND MemRead_MEM = '1') ELSE read_data_MEM; 	-- GPIO INPUT
	DataBus		<= write_data_MEM WHEN (ALU_Result_MEM(11) = '1' AND MemWrite_MEM = '1') ELSE (OTHERS => 'Z');	-- GPIO OUTPUT
	
	Addr_MEM 	<= DataBus WHEN (INTA_s = '0') ELSE ALU_Result_MEM;

	---------- INTERRUPT ----------
	------ INTA and ISR Addr ------
	INTA	<= INTA_s;
	INTR_Single	<= 	'1' WHEN INTR = '1' ELSE
				'0' WHEN rising_edge(clk_i) ELSE
				'0' WHEN rst_i = '1' ELSE
				unaffected;
	
	PROCESS (clk_i, INTR, rst_i)
		VARIABLE INTR_STATE : STD_LOGIC_VECTOR(1 DOWNTO 0);

	BEGIN
		IF rst_i = '1' THEN
			INTR_STATE 	:= "00";
			INTA_s 		<= '1';
			ISR_PC_RD	<= '0';
			PC_HOLD		<= '0';
		
		ELSIF (falling_edge(clk_i)) THEN
			IF (INTR_STATE = "00") THEN
				IF (INTR = '1') THEN
					INTA_s		<= '0';
					INTR_STATE	:= "01";
					PC_HOLD		<= '1';
				END IF;
				ISR_PC_RD	<= '0';
				
			ELSIF (INTR_STATE = "01") THEN		
				INTA_s		<= '1';
				INTR_STATE 	:= "10";
								
			ELSE 
				ISR_Addr	<= read_data_MEM;
				INTR_STATE 	:= "00";
				ISR_PC_RD	<= '1';
				PC_HOLD		<= '0';
			END IF;
		
		END IF;
	END PROCESS;
	
	------ EPC (Exception Program Counter) PROCESS ------
	PROCESS (clk_i, INTR, rst_i) BEGIN	
		IF rst_i = '1' THEN
			EPC	<= (OTHERS => '0');
			
		ELSIF (rising_edge(clk_i)) THEN
			IF (INTR = '1') THEN
				IF (is_Branch = '0') THEN
					EPC	<= PC_plus_4_IF(9 DOWNTO 2) - 2;
				ELSE 
					EPC	<= PC_plus_4_IF(9 DOWNTO 2) - 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	is_Branch	<= Jump_EX OR Branch_ctrl_EX(0) OR Branch_ctrl_EX(1);

	------------------------------------------------------------------------
	-- connect the 5 MIPS components   
	IFE : Ifetch
	generic map(
		WORD_GRANULARITY	=> 	WORD_GRANULARITY,
		DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
		PC_WIDTH		=>	10,
		ITCM_ADDR_WIDTH		=>	ITCM_ADDR_WIDTH,
		WORDS_NUM		=>	DATA_WORDS_NUM
	)
	PORT MAP (	
		clk_i			=>	clk_i,
		rst_i			=>	rst_i,
		Stall_IF		=>	Stall_IF,
		add_result_i		=>	BranchAddr_ID(7 downto 0),
        	PCSrc			=>	PCSrc_ID,
		JumpAddr		=>	JumpAddr_ID,
		pc_o			=>	IFpc,
		pc_plus4_o		=>	PC_plus_4_IF,
		instruction_o		=>	IR_IF,
		ISR_PC_RD		=> 	ISR_PC_RD,
		PC_HOLD			=> 	PC_HOLD,
		ISRAddr			=> 	ISR_Addr
	);	

	ID : Idecode
   	generic map(
		DATA_BUS_WIDTH		=>  DATA_BUS_WIDTH
	)
	PORT MAP (	
			clk_i 			 => clk_i,  
			rst_i 			 => rst_i,
        		instruction_i            => IR_ID,
			RegWrite_ctrl_i          => RegWrite_WB,
			Jump_ctrl_i              => Jump_ID,
			WrRegAddr 		 => WrRegAddr_WB,
			Branch_ctrl_i 		 => Branch_ctrl_ID,
			PC_plus_4_S		 => PC_plus_4_ID(9 DOWNTO 2),
			Stall_ID		 => Stall_ID,		
			write_data_i		 => write_data_mux_WB, 
			ForwardA_ID		 => ForwardA_ID,
			ForwardB_ID              => ForwardB_ID,
			BrRdData_FW		 => ALU_Result_MEM,
			WrRegAddr0 		 => WrRegAddr0_ID,
			WrRegAddr1 		 => WrRegAddr1_ID,
			PCSrc		 	 => PCSrc_ID,	
			read_data1_o		 => read_data1_ID,
			read_data2_o		 => read_data2_ID,
			JumpAddr		 => JumpAddr_ID,	
			BranchAddr 		 => BranchAddr_ID,
			sign_extend_o 		 => sign_extend_ID,
	                GIE			 => GIE,
			ISR_PC_RD		 => ISR_PC_RD,
			EPC			 => EPC,
			INTR			 => INTR,
			INTR_Active		 => INTR_Active,
			CLR_IRQ			 => CLR_IRQ	 
	);

	WB: WriteBack
   	generic map(
		DATA_BUS_WIDTH		=>  DATA_BUS_WIDTH
	)
	PORT MAP (	
			dtcm_data_rd_i 		=> read_data_WB,
			alu_result_i		=> ALU_Result_WB,
			MemtoReg_ctrl_i 	=> MemtoReg_WB,
			pc_plus_4_S 		=> pc_plus_4_WB(9 downto 2),
			write_data_o		=> write_data_WB,
			write_data_mux		=> write_data_mux_WB
	);

	-- Control connection update
	CTL:   control
	PORT MAP ( 	
			opcode_i 		=> IR_ID(DATA_BUS_WIDTH-1 DOWNTO 26),
			funct_i			=> IR_ID(5 DOWNTO 0),
			RegDst_ctrl_o 		=> RegDst_ID,
			ALUSrc_ctrl_o 		=> ALUSrc_ID,
			MemtoReg_ctrl_o 	=> MemtoReg_ID,
			RegWrite_ctrl_o 	=> RegWrite_ID,
			MemRead_ctrl_o 		=> MemRead_ID,
			MemWrite_ctrl_o	 	=> MemWrite_ID,
			Branch_ctrl_o 		=> branch_ctrl_ID,
			jump_ctrl_o 		=> jump_ID,
			ALUOp_ctrl_o 		=> ALUOP_ID,
                        INTR			=> INTR,
			IF_FLUSH		=> Int_Flush_IF,
		        ID_FLUSH		=> Int_Flush_ID,
			EX_FLUSH		=> Int_Flush_EX,
			PC_HOLD			=> PC_HOLD,
			ISR_PC_RD		=> ISR_PC_RD
	);

	EXE:  Execute
   	generic map(
		DATA_BUS_WIDTH 		=> 	DATA_BUS_WIDTH,
		FUNCT_WIDTH 		=>	6,
		PC_WIDTH 		=>	10
	)
	PORT MAP (	
		read_data1_i 	=> read_data1_EX,
        	read_data2_i 	=> read_data2_EX,
		sign_extend_i 	=> Sign_extend_EX,
        	funct_i		=> Sign_extend_EX(5 DOWNTO 0),
		ALUOp_ctrl_i 	=> ALUOp_EX,
		RegDst_ctrl_i   => RegDst_EX,
		ALUSrc_ctrl_i 	=> ALUSRC_EX,
		ForwardA 	=> ForwardA,
		ForwardB	=> ForwardB,
		WrDataFW_WB	=> write_data_WB,
		WrDataFW_MEM	=> ALU_Result_MEM,
		WrRegAddr0	=> WrRegAddr0_EX,
		WrRegAddr1	=> WrRegAddr1_EX,
		WrRegAddr       => WrRegAddr_EX,
		WriteData_EX	=> write_data_EX,
		zero_o 		=> Zero_EX,
        	alu_res_o	=> ALU_Result_EX
	);

	--addr_select_proc : process(ALU_Result_MEM)
	--begin
	--    if WORD_GRANULARITY = true then
	        -- Word-addressed memory: shift right by 2
	--        dtcm_addr_sel <= ALU_Result_MEM((DTCM_ADDR_WIDTH)-1 downto 2);
	--    else
	        -- Byte-addressed memory: align by 4 (append "00")
	--        dtcm_addr_sel <= ALU_Result_MEM(DTCM_ADDR_WIDTH-1 downto 2) & "00";
	--    end if;
	--end process;

	-- Memory instantiation
	MEM: dmemory
	    generic map(
	        DATA_BUS_WIDTH   => DATA_BUS_WIDTH,
	        DTCM_ADDR_WIDTH  => DTCM_ADDR_WIDTH,
	        WORDS_NUM        => DATA_WORDS_NUM,
		G_WORD_GRANULARITY => G_WORD_GRANULARITY
	    )
	    port map(
	        clk_i           => clk_i,
	        rst_i           => rst_i,
		dtcm_addr_i     => Addr_MEM,
	        dtcm_data_wr_i  => write_data_MEM,
	        MemRead_ctrl_i  => MemRead_MEM,
	        MemWrite_ctrl_i => MemWrite_MEM,
	        dtcm_data_rd_o  => read_data_MEM
	    );

	HU: HazardUnit
		port map(
			MemtoReg_EX 			=> MemtoReg_EX,
			MemtoReg_MEM 			=> MemtoReg_MEM,
			WriteReg_EX 			=> WrRegAddr_EX,
			WriteReg_MEM 			=> WrRegAddr_MEM,
			RegRs_ID 			=> IR_ID(25 downto 21),
			RegRt_ID 			=> IR_ID(20 downto 16),
			RegRt_EX 			=> IR_EX(20 downto 16),
			RegWr_EX 			=> RegWrite_EX,
			Branch_ID 			=> Branch_ctrl_ID,
			Jump_ID	 			=> Jump_ID,
			Stall_IF 			=> Stall_IF,
			Stall_ID 			=> Stall_ID,
			Flush_EX 			=> Flush_EX
		);

	FU: ForwardingUnit
		port map(
			WriteReg_MEM 			=> WrRegAddr_MEM,
			WriteReg_WB 			=> WrRegAddr_WB,
			RegRs_EX 			=> IR_EX(25 downto 21),
			RegRt_EX 			=> IR_EX(20 downto 16),
			RegRs_ID 			=> IR_ID(25 downto 21),
			RegRt_ID 			=> IR_ID(20 downto 16),
			RegWr_MEM 			=> RegWrite_MEM,
			RegWr_WB 			=> RegWrite_WB,
			ForwardA 			=> ForwardA,
			ForwardB 			=> ForwardB,
			ForwardA_ID 			=> ForwardA_ID,
			ForwardB_ID 			=> ForwardB_ID
		);
---------------------------------------------------------------------------------------
----------------------- Connect Pipeline Registers ------------------------
	PROCESS BEGIN
		WAIT UNTIL clk_i'EVENT AND clk_i = '1';
		-------------- Instruction Fetch TO Instruction Decode ---------------- 
		IF Stall_ID = '0' THEN 
			PC_plus_4_ID <= PC_plus_4_IF;
			IR_ID <= IR_IF;		
		END IF;
		IF (((PCSrc_ID(0) = '1' OR (PCSrc_ID(1) = '1')) AND (IFpc = PC_plus_4_IF)) OR Int_Flush_IF = '1')  THEN 
			PC_plus_4_ID <= "0000000000";
			IR_ID 	     <= X"00000000";			
		END IF;
		-------------------- Instruction Decode TO Execute -------------------- 
		IF (Flush_EX = '1' OR Int_Flush_ID = '1') THEN -- CLR ID_IF register
			----- Control Reg ----
			Branch_EX 	 <= '0';
			MemtoReg_EX      <= "00";
			RegWrite_EX      <= '0';
			MemWrite_EX      <= '0';
			MemRead_EX	 <= '0';
			RegDst_EX 	 <= "00";  
			ALUSrc_EX	 <= '0';
			ALUOp_EX 	 <= "0000";
			Branch_ctrl_EX	 <= "00";
			Jump_EX	         <= '0';  
			----- State Reg -----
			PC_plus_4_EX     <= "0000000000";
			IR_EX		 <= X"00000000";
			read_data1_EX    <= X"00000000";
			read_data2_EX    <= X"00000000";
			Sign_extend_EX   <= X"00000000";
			WrRegAddr0_EX 	 <= "00000";
			WrRegAddr1_EX 	 <= "00000";
		ELSE 
			----- Control Reg -----
			Branch_EX 	 <= Branch_ID;
			MemtoReg_EX      <= MemtoReg_ID;
			RegWrite_EX      <= RegWrite_ID;
			MemWrite_EX      <= MemWrite_ID;
			MemRead_EX	 <= MemRead_ID;		
			RegDst_EX 	 <= RegDst_ID;
			ALUSrc_EX	 <= ALUSrc_ID;
			ALUOp_EX 	 <= ALUOp_ID;
			Opcode_EX	 <= IR_ID(31 DOWNTO 26);
			Branch_ctrl_EX	 <= Branch_ctrl_ID;
			Jump_EX		 <= Jump_ID; 
			-- EPC		<= PC_plus_4_ID;
			----- State Reg -----
			PC_plus_4_EX     <= PC_plus_4_ID;	
			IR_EX		 <= IR_ID;
			read_data1_EX    <= read_data1_ID;
			read_data2_EX    <= read_data2_ID;
			Sign_extend_EX   <= Sign_extend_ID;
			WrRegAddr0_EX    <= WrRegAddr0_ID;
			WrRegAddr1_EX    <= WrRegAddr1_ID;
		END IF;
		
		-------------------------- Execute TO Memory --------------------------- 
		IF (Int_Flush_EX = '1') THEN 
			----- Control Reg -----
			Branch_MEM	<= '0';
			Zero_MEM	<= '0';
			MemtoReg_MEM    <= "00";
			RegWrite_MEM    <= '0';
			MemWrite_MEM    <= '0';
			MemRead_MEM	<= '0';	
			Branch_ctrl_MEM	<= "00";
			Jump_MEM	<= '0';
			----- State Reg -----
			PC_plus_4_MEM	<= "0000000000";
			Add_Result_MEM  <= X"00";
			ALU_Result_MEM  <= X"00000000";
			write_data_MEM	<= X"00000000";   -- was read_data_2_EX
			WrRegAddr_MEM	<= "00000";
		ELSE
			----- Control Reg -----
		----- Control Reg -----
		Branch_MEM	<= Branch_EX;
		Zero_MEM	<= Zero_EX;
		MemtoReg_MEM    <= MemtoReg_EX;
		RegWrite_MEM    <= RegWrite_EX;
		MemWrite_MEM    <= MemWrite_EX;
		MemRead_MEM	<= MemRead_EX;	
		Branch_ctrl_MEM	<= Branch_ctrl_EX;
		Jump_MEM	<= Jump_EX;
		----- State Reg ----- 
		IR_MEM		<= IR_EX;
		PC_plus_4_MEM	<= PC_plus_4_EX;
		Add_Result_MEM  <= Add_Result_EX;
		ALU_Result_MEM  <= ALU_Result_EX;
		write_data_MEM	<= write_data_EX;
		WrRegAddr_MEM	<= WrRegAddr_EX;

		------------------------- Memory TO WriteBack ------------------------- 
		----- Control Reg -----
		MemtoReg_WB	<= MemtoReg_MEM;
		RegWrite_WB	<= RegWrite_MEM;
		----- State Reg -----
		IR_WB		<= IR_MEM;
		PC_plus_4_WB	<= PC_plus_4_MEM;
		read_data_WB	<= DataInBus;
		ALU_Result_WB	<= ALU_Result_MEM;
		WrRegAddr_WB	<= WrRegAddr_MEM;
		END IF;
	END PROCESS;		
	---------------------------------------------------------------------------
END structure;
