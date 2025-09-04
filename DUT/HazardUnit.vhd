--------------- Top Level Structural Model for MIPS Processor Core
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.numeric_std.all;
USE work.aux_package.ALL;
-------------- ENTITY --------------------
ENTITY HazardUnit IS
	PORT( 
		MemtoReg_EX, MemtoReg_MEM	 		: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		WriteReg_EX, WriteReg_MEM			: IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
		RegRs_ID, RegRt_ID 				: IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
		RegRt_EX					: IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
		RegWr_EX				 	: IN  STD_LOGIC;
		Branch_ID	 				: IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
		Jump_ID						: IN STD_LOGIC;
		Stall_IF, Stall_ID, Flush_EX 	 	 	: OUT STD_LOGIC
		);
END 	HazardUnit; 
------------ ARCHITECTURE ----------------
ARCHITECTURE structure OF HazardUnit IS
SIGNAL LwStall, BranchStall : BOOLEAN;
BEGIN
----------- Stall and Flush -----------------------	
	LwStall <= MemtoReg_EX(0) = '1' AND ( RegRt_EX = RegRs_ID OR RegRt_EX = RegRt_ID );
	BranchStall <= ((Branch_ID(0) = '1' OR Branch_ID(1) = '1') AND RegWr_EX = '1' AND (WriteReg_EX = RegRs_ID OR WriteReg_EX = RegRt_ID)) OR (Branch_ID(0) = '1' AND MemtoReg_MEM(0) = '1' AND (WriteReg_MEM = RegRs_ID OR WriteReg_MEM = RegRt_ID));
	
	Stall_IF <= '1' WHEN (LwStall OR BranchStall) ELSE '0';
	Stall_ID <= '1' WHEN (LwStall OR BranchStall) ELSE '0';
	Flush_EX <= '1' WHEN (LwStall OR BranchStall) ELSE '0';
END Structure;