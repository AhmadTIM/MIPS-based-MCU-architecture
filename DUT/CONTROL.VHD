---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
-- control module (implements MIPS control unit)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.const_package.all;


ENTITY control IS
   PORT( 	
		opcode_i 		: IN 	STD_LOGIC_VECTOR(5 DOWNTO 0);
		funct_i			: IN	STD_LOGIC_VECTOR(5 DOWNTO 0);
		RegDst_ctrl_o 		: OUT 	STD_LOGIC_VECTOR(1 DOWNTO 0);
		ALUSrc_ctrl_o 		: OUT 	STD_LOGIC;
		MemtoReg_ctrl_o 	: OUT 	STD_LOGIC_VECTOR(1 DOWNTO 0);
		RegWrite_ctrl_o 	: OUT 	STD_LOGIC;
		MemRead_ctrl_o 		: OUT 	STD_LOGIC;
		MemWrite_ctrl_o	 	: OUT 	STD_LOGIC;
		Branch_ctrl_o 		: OUT 	STD_LOGIC_VECTOR(1 DOWNTO 0);
		jump_ctrl_o 		: OUT 	STD_LOGIC;
		-----
		INTR			: IN	STD_LOGIC;
		IF_FLUSH		: OUT 	STD_LOGIC;
		ID_FLUSH		: OUT 	STD_LOGIC;
		EX_FLUSH		: OUT 	STD_LOGIC;
		PC_HOLD			: IN 	STD_LOGIC;
		ISR_PC_RD		: IN 	STD_LOGIC;
		-----
		ALUOp_ctrl_o	 	: OUT 	STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END control;

ARCHITECTURE behavior OF control IS

	SIGNAL  rtype_w, lw_w, sw_w, beq_w, bne_w, mul_w, j_w, jal_w, jr_w 	: STD_LOGIC := '0';
	SIGNAL  addi_w, addiu_w, ori_w, andi_w, slti_w, xori_w, lui_w 		: STD_LOGIC := '0';
BEGIN           
				-- Code to generate control signals using opcode bits
	rtype_w 		<=  '1'	WHEN	(opcode_i = R_TYPE_OPC and funct_i /= "001000") ELSE '0';
	lw_w          		<=  '1'	WHEN  	opcode_i = LW_OPC  				ELSE '0';
 	sw_w          		<=  '1'	WHEN  	opcode_i = SW_OPC  				ELSE '0';
 	mul_w          		<=  '1'	WHEN  	opcode_i = MUL_OPC  				ELSE '0';
   	beq_w         		<=  '1'	WHEN  	opcode_i = BEQ_OPC 				ELSE '0';
   	bne_w         		<=  '1'	WHEN  	opcode_i = BNE_OPC 				ELSE '0';
   	j_w         		<=  '1'	WHEN  	opcode_i = J_OPC 				ELSE '0';
   	jal_w         		<=  '1'	WHEN  	opcode_i = JAL_OPC 				ELSE '0';
	jr_w			<=  '1' WHEN	(opcode_i = R_TYPE_OPC and funct_i = "001000") 	ELSE '0';
   	addi_w         		<=  '1'	WHEN  	opcode_i = addi_OPC 				ELSE '0';
   	addiu_w         	<=  '1'	WHEN  	opcode_i = addiu_OPC 				ELSE '0';
   	ori_w         		<=  '1'	WHEN  	opcode_i = ori_OPC 				ELSE '0';
   	andi_w         		<=  '1'	WHEN  	opcode_i = andi_OPC 				ELSE '0';
   	slti_w         		<=  '1'	WHEN  	opcode_i = slti_OPC 				ELSE '0';
   	xori_w         		<=  '1'	WHEN  	opcode_i = xori_OPC 				ELSE '0';
   	lui_w         		<=  '1'	WHEN  	opcode_i = lui_OPC 				ELSE '0';					
							
  	RegDst_ctrl_o(0)    	<=  rtype_w or mul_w;
	RegDst_ctrl_o(1)	<=  jal_w;
 	ALUSrc_ctrl_o  		<=  lw_w or sw_w or xori_w or lui_w or slti_w or andi_w or ori_w or addi_w or addiu_w;
	MemtoReg_ctrl_o(0) 	<=  lw_w;
	MemtoReg_ctrl_o(1)	<=  jal_w;
  	RegWrite_ctrl_o 	<=  rtype_w or mul_w OR lw_w or xori_w or lui_w or slti_w or andi_w or ori_w or addi_w or jal_w or addiu_w;
  	MemRead_ctrl_o 		<=  lw_w;
   	MemWrite_ctrl_o 	<=  sw_w; 
 	Branch_ctrl_o(0)      	<=  beq_w;
 	Branch_ctrl_o(1)      	<=  bne_w;
 	jump_ctrl_o      	<=  j_w or jal_w or jr_w;
	ALUOp_ctrl_o(0) 	<=  rtype_w or bne_w or beq_w or ori_w or slti_w;
	ALUOp_ctrl_o(1) 	<=  rtype_w or mul_w or andi_w or ori_w or lui_w;
	ALUop_ctrl_o(2)		<=  rtype_w or mul_w or xori_w or lui_w or slti_w;
	ALUop_ctrl_o(3)		<=  mul_w;


	-------
	IF_FLUSH 	<= '1' WHEN INTR = '1' OR PC_HOLD = '1' OR ISR_PC_RD = '1' ELSE '0';
	ID_FLUSH 	<= '1' WHEN INTR = '1' OR PC_HOLD = '1' OR ISR_PC_RD = '1' ELSE '0';
	EX_FLUSH 	<= '1' WHEN INTR = '1' OR PC_HOLD = '1' OR ISR_PC_RD = '1' ELSE '0';
	-------
   END behavior;


