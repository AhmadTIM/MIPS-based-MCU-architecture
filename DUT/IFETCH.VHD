---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
-- Ifetch module (provides the PC and instruction 
--memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE work.cond_comilation_package.all;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;


ENTITY Ifetch IS
	generic(
		WORD_GRANULARITY : boolean 	:= False;
		DATA_BUS_WIDTH : integer 	:= 32;
		PC_WIDTH : integer 		:= 10;
		NEXT_PC_WIDTH : integer 	:= 8; -- NEXT_PC_WIDTH = PC_WIDTH-2
		ITCM_ADDR_WIDTH : integer 	:= 8;
		WORDS_NUM : integer 		:= 256
	);
	PORT(	
		clk_i, rst_i			: IN 	STD_LOGIC;
		Stall_IF			: IN 	STD_LOGIC;
		add_result_i 			: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
        	PCSrc 				: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		JumpAddr			: IN	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
		pc_o 				: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		pc_plus4_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		instruction_o 			: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		ISR_PC_RD			: IN	STD_LOGIC;
		PC_HOLD				: IN 	STD_LOGIC;
		ISRAddr				: IN	STD_LOGIC_VECTOR(31 DOWNTO 0)	
	);
END Ifetch;


ARCHITECTURE behavior OF Ifetch IS
	SIGNAL pc_q				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL pc_plus4_r 			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL itcm_addr_w 			: STD_LOGIC_VECTOR(ITCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL next_pc_w  			: STD_LOGIC_VECTOR(NEXT_PC_WIDTH-1 DOWNTO 0) := (others => '0');
	SIGNAL rst_flag_q			: STD_LOGIC;
	SIGNAL break_halt			: STD_LOGIC;
	signal clk_i_inv 			: std_logic;
BEGIN

--ROM for Instruction Memory
	inst_memory: altsyncram
	GENERIC MAP (
		operation_mode => "ROM",
		width_a => DATA_BUS_WIDTH,
		widthad_a => ITCM_ADDR_WIDTH,
		numwords_a => WORDS_NUM,
		lpm_hint => "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = ITCM",
		lpm_type => "altsyncram",
		outdata_reg_a => "UNREGISTERED",
		init_file => "C:\Users\ahmad\OneDrive\Desktop\Final Project RTtest-20250828T080922Z-1-001\Final Project RTtest\RTlevel4\M9K\ITCM.hex",
		intended_device_family => "Cyclone"
	)
	PORT MAP (
		clock0     => clk_i_inv,
		address_a  => itcm_addr_w, 
		q_a 	   => instruction_o 
	);
	clk_i_inv <= not clk_i;
	----------------------------------------------------------------------------------------------
	-- Instructions always start on word address - not byte
	pc_q(1 DOWNTO 0) 	<= "00";

	-- send address to inst. memory address register
	process(next_pc_w)
	begin
	    if WORD_GRANULARITY = true then
	        itcm_addr_w <= next_pc_w;
	    else
	        itcm_addr_w <= next_pc_w & "00";
	    end if;
	end process;
		
	-- Adder to increment PC by 4
	pc_plus4_r(1 DOWNTO 0) <= "00";
    	pc_plus4_r(PC_WIDTH-1 DOWNTO 2) <= pc_q(PC_WIDTH-1 DOWNTO 2) + 1;
								

	next_pc_w <= X"00" 	  	WHEN rst_flag_q = '1' 	ELSE	-- rst
           	     next_pc_w		WHEN Stall_IF   = '1'	ELSE	-- Stall
		     ISRAddr(9 DOWNTO 2)WHEN ISR_PC_RD  = '1'   ELSE	-- interrupt
		     add_result_i 	WHEN PCSrc      = "01" 	ELSE   	-- branch
		     JumpAddr	  	WHEN PCSrc      = "10"	ELSE	-- jump
		     pc_plus4_r( 9 DOWNTO 2 );
	------------------------------------------------------
	process (clk_i)
	BEGIN
		IF(clk_i'EVENT  AND clk_i='1') THEN
			rst_flag_q <= rst_i;
		end if;
	end process;
	-------------------------------------------------------------------------------------
	PROCESS (clk_i, rst_i)
	BEGIN
		IF rst_i = '1' THEN
			pc_q(PC_WIDTH-1 DOWNTO 2) <= (OTHERS => '0') ; 
		ELSIF(clk_i'EVENT  AND clk_i='0') THEN
			IF ((Stall_IF = '0') AND PC_HOLD = '0') THEN
				pc_q(PC_WIDTH-1 DOWNTO 2) <= next_pc_w;
			END IF;
		END IF;
	END PROCESS;
	-----------------------------------------------------------------------------------------
	-- copy output signals - allows read inside module
	pc_o 				<= 	pc_q;
	pc_plus4_o 			<= 	pc_plus4_r;
END behavior;


