---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
--  Dmemory module (implements the data memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY dmemory IS
	generic(
		DATA_BUS_WIDTH : integer := 32;
		DTCM_ADDR_WIDTH : integer := 10;
		WORDS_NUM : integer := 1024;
		G_WORD_GRANULARITY	: BOOLEAN := FALSE
	);
	PORT(	clk_i,rst_i			: IN 	STD_LOGIC;
			dtcm_addr_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MemRead_ctrl_i  	: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			dtcm_data_rd_o 		: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
	);
END dmemory;


ARCHITECTURE behavior OF dmemory IS
SIGNAL wrclk_w : STD_LOGIC;
Signal dMemAddr : STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 downto 0);
Signal wr_en	: STD_LOGIC;
BEGIN
	data_memory : altsyncram
	GENERIC MAP  (
		operation_mode => "SINGLE_PORT",
		width_a => DATA_BUS_WIDTH,
		widthad_a => DTCM_ADDR_WIDTH,
		numwords_a => WORDS_NUM,
		lpm_hint => "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = DTCM",
		lpm_type => "altsyncram",
		outdata_reg_a => "UNREGISTERED",
		init_file => "C:\Users\ahmad\OneDrive\Desktop\Final Project RTtest-20250828T080922Z-1-001\Final Project RTtest\RTlevel4\M9K\DTCM.hex",
		intended_device_family => "Cyclone"
	)
	PORT MAP (
		wren_a => wr_en,
		clock0 => wrclk_w,
		address_a => dMemAddr,
		data_a => dtcm_data_wr_i,
		q_a => dtcm_data_rd_o	
	);
	ModelSim: IF (G_WORD_GRANULARITY = TRUE) GENERATE
			dMemAddr <= dtcm_addr_i(9 DOWNTO 2);
		END GENERATE ModelSim;
		
	FPGA: 	  IF (G_WORD_GRANULARITY = FALSE) GENERATE
				dMemAddr <= dtcm_addr_i(9 DOWNTO 2) & "00";
		END GENERATE FPGA;
	
	wr_en <= '1' WHEN (dtcm_addr_i(11) = '0' AND MemWrite_ctrl_i = '1') ELSE '0';


	wrclk_w <= NOT clk_i;	-- Load memory address register with write clock
END behavior;

