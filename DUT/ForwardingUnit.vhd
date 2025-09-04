--------------- 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE work.aux_package.ALL;
-------------- ENTITY --------------------
ENTITY ForwardingUnit IS
	PORT( 
		WriteReg_MEM, WriteReg_WB	: IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
		RegRs_EX, RegRt_EX 		: IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
		RegRs_ID, RegRt_ID 		: IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
		RegWr_MEM, RegWr_WB		: IN  STD_LOGIC;
		ForwardA, ForwardB		: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		ForwardA_ID, ForwardB_ID	: OUT STD_LOGIC
		);
END 	ForwardingUnit;
------------ ARCHITECTURE ----------------
ARCHITECTURE structure OF ForwardingUnit IS
BEGIN
	PROCESS (WriteReg_MEM, WriteReg_WB, RegRs_EX, RegRt_EX, RegWr_MEM, RegWr_WB)
	BEGIN
	--------------------- Register Forwarding -----------------------
		IF (RegWr_MEM = '1' AND WriteReg_MEM /= "00000" AND WriteReg_MEM = RegRs_EX)  THEN -- EX Hazard take from MEM
			ForwardA <= "10";
		ELSIF (RegWr_WB = '1' AND WriteReg_WB /= "00000" AND (NOT (RegWr_MEM = '1' AND WriteReg_MEM /= "00000" AND (WriteReg_MEM = RegRs_EX))) AND WriteReg_WB = RegRs_EX) THEN -- MEM Hazard take from WB
			ForwardA <= "01";
		ELSE 
			ForwardA <= "00";	
		END IF;
		
		IF (RegWr_MEM = '1' AND WriteReg_MEM /= "00000" AND WriteReg_MEM = RegRt_EX)  THEN -- EX Hazard take from MEM
			ForwardB <= "10";
		ELSIF (RegWr_WB = '1' AND WriteReg_WB /= "00000" AND (NOT (RegWr_MEM = '1' AND WriteReg_MEM /= "00000" AND (WriteReg_MEM = RegRt_EX))) AND WriteReg_WB = RegRt_EX) THEN -- MEM Hazard take from WB
			ForwardB <= "01";
		ELSE 
			ForwardB <= "00";
		END IF;
	-------------- Branch Forwarding --------------------
		IF ((RegRs_ID /= "00000") AND (RegRs_ID = WriteReg_MEM) AND RegWr_MEM = '1') THEN 
			ForwardA_ID <= '1';
		ELSE 
			ForwardA_ID <= '0';
		END IF;
		
		IF ((RegRt_ID /= "00000") AND (RegRt_ID = WriteReg_MEM) AND RegWr_MEM = '1') THEN 
			ForwardB_ID <= '1';
		ELSE 
			ForwardB_ID <= '0';
		END IF;		
	END PROCESS;

END Structure;