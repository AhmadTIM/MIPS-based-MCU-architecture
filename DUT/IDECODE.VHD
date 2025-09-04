---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
--  Idecode module (implements the register file for the MIPS computer
LIBRARY IEEE; 		
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.all;

ENTITY Idecode IS
	generic(
		DATA_BUS_WIDTH : integer := 32
	);
	PORT(	clk_i,rst_i				: IN 	STD_LOGIC;
			instruction_i 			: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			RegWrite_ctrl_i 		: IN 	STD_LOGIC;
			Jump_ctrl_i	 		: IN 	STD_LOGIC;
			WrRegAddr 			: IN   STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			Branch_ctrl_i 			: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			PC_plus_4_S			: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
			Stall_ID			: IN    STD_LOGIC;
			write_data_i			: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0); 
			ForwardA_ID, ForwardB_ID	: IN 	STD_LOGIC;
			BrRdData_FW			: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			WrRegAddr0 			: OUT   STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			WrRegAddr1 			: OUT   STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			PCSrc		 		: OUT 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			read_data1_o			: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o			: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			JumpAddr			: OUT   STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			BranchAddr 			: OUT 	STD_LOGIC_VECTOR(7 DOWNTO 0);
			GIE				: OUT 	STD_LOGIC := '0';
			ISR_PC_RD			: IN	STD_LOGIC;
			EPC				: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
			INTR				: IN	STD_LOGIC;
			INTR_Active			: IN	STD_LOGIC;
			CLR_IRQ				: IN	STD_LOGIC_VECTOR(6 DOWNTO 0);
			sign_extend_o 			: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)		 
	);
END Idecode;


ARCHITECTURE behavior OF Idecode IS
TYPE register_file IS ARRAY (0 TO 31) OF STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	SIGNAL RF_q					: register_file;
	SIGNAL opcode					: STD_LOGIC_VECTOR( 5 DOWNTO 0 );
	SIGNAL rs_register_w				: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL rt_register_w				: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL imm_value_w				: STD_LOGIC_VECTOR( 15 DOWNTO 0 );
	SIGNAL read_data1_sig, read_data2_sig		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL Sign_extend_sig				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data_comp_1, read_data_comp_2	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

BEGIN
	opcode				<= instruction_i(DATA_BUS_WIDTH-1 DOWNTO 26);
	rs_register_w 			<= instruction_i(25 DOWNTO 21);
   	rt_register_w 			<= instruction_i(20 DOWNTO 16);
	WrRegAddr0			<= instruction_i(20 DOWNTO 16);
	WrRegAddr1			<= instruction_i(15 DOWNTO 11);
   	imm_value_w 			<= instruction_i(15 DOWNTO 0);

-------------- Read Register 1 Operation ---------------------------
	read_data_comp_1  <= read_data1_sig WHEN ForwardA_ID = '0' ELSE BrRdData_FW;
	read_data1_sig	  <= RF_q(CONV_INTEGER(rs_register_w));
	read_data1_o 	  <= read_data1_sig;
-------------- Read Register 2 Operation ---------------------------
	read_data_comp_2  <= read_data2_sig WHEN ForwardB_ID = '0' ELSE BrRdData_FW;
	read_data2_sig	  <= RF_q(CONV_INTEGER(rt_register_w));
	read_data2_o 	  <= read_data2_sig;
-------------- PCSrc from Read Register Comp -----------------------
	PCSrc(1) <= Jump_ctrl_i;
	PCSrc(0) <= Branch_ctrl_i(0) WHEN ((read_data_comp_1 = read_data_comp_2) AND Stall_ID = '0') ELSE 
		    Branch_ctrl_i(1) WHEN ((read_data_comp_1 /= read_data_comp_2) AND Stall_ID = '0') ELSE '0';
--------------------------------------------------------------------
	BranchAddr <= PC_plus_4_S + Sign_extend_sig(7 DOWNTO 0);
	JumpAddr   <= Sign_extend_sig(7 DOWNTO 0) WHEN Opcode(1 DOWNTO 0) = "10" OR Opcode(1 DOWNTO 0) = "11" ELSE
		      read_data1_sig(7 DOWNTO 0);
-- Sign Extend 16-bits to 32-bits
    	Sign_extend_sig <=  X"0000" & imm_value_w WHEN (imm_value_w(15) = '0' or Opcode = "001101") ELSE
			    X"FFFF" & imm_value_w;
	sign_extend_o	<= Sign_extend_sig;
-------------- Global interrupt enable GIE ------------------------
	GIE <= RF_q(26)(0);
--------------------------------------------------------------------
	process(clk_i,rst_i)
	begin
		if (rst_i='1') then
			FOR i IN 0 TO 31 LOOP
				-- RF_q(i) <= CONV_STD_LOGIC_VECTOR(i,32);
				RF_q(i) <= CONV_STD_LOGIC_VECTOR(0,32);
			END LOOP;
		elsif (clk_i'event and clk_i='0') then
			if (RegWrite_ctrl_i = '1' AND WrRegAddr /= 0) then
				RF_q(CONV_INTEGER(WrRegAddr)) <= write_data_i;
				-- index is integer type so we must use conv_integer for type casting
			end if;
		end if;
		----- $k0
		IF (INTR = '1') THEN
		    RF_q(26)(0) <= '0';  -- clr GIE in $k0
		ELSIF (rs_register_w = "11011" AND Jump_ctrl_i = '1') THEN
		    RF_q(26)(0) <= '1';  -- set GIE in $k0
		END IF;
		----- $k1
		IF (ISR_PC_RD = '1') THEN
		    RF_q(27) <= X"000000" & EPC;
		END IF;
	end process;
END behavior;





