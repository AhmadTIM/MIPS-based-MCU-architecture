LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.aux_package.all;


ENTITY WriteBack IS
	generic(
		DATA_BUS_WIDTH : integer := 32
	);
	PORT(	dtcm_data_rd_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		alu_result_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		MemtoReg_ctrl_i 	: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0); 
		PC_plus_4_S		: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		write_data_o		: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		write_data_mux		: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END WriteBack;
 
ARCHITECTURE behavior OF WriteBack IS
	SIGNAL write_data_sig : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
begin
	write_data_sig	<= alu_result_i WHEN MemtoReg_ctrl_i(0) = '0' ELSE dtcm_data_rd_i;
	write_data_o 	<= write_data_sig;
	write_data_mux 	<= write_data_sig WHEN MemtoReg_ctrl_i(1) = '0' ELSE X"000000" & PC_plus_4_S;
end behavior;

