--------------- MCU System Architecture Module 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE work.cond_comilation_package.all;
USE work.aux_package.all;
-------------- ENTITY --------------------
ENTITY MCU IS
	GENERIC(	CtrlBusSize		: integer := 8;
			AddrBusSize		: integer := 32;
			DataBusSize		: integer := 32
			);
	PORT( 
			rst, CLK		: IN	STD_LOGIC;
			CLK_i_dbg, FIRCLK_dbg	: IN	STD_LOGIC;
			HEX0, HEX1, HEX2	: OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX3, HEX4, HEX5	: OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			LEDR			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
			SWs			: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
			BTOUT			: OUT   STD_LOGIC;
			KEY1, KEY2, KEY3	: IN	STD_LOGIC;
			UART_RX			: IN 	STD_LOGIC := '1';
			UART_TX			: OUT	STD_LOGIC := '1'
		);
END MCU;
------------ ARCHITECTURE ----------------
ARCHITECTURE structure OF MCU IS
	SIGNAL rstSim		: 	STD_LOGIC := '0';
	SIGNAL CLK_i		:	STD_LOGIC := '0';
	SIGNAL FIRCLK		:	STD_LOGIC := '0';
	SIGNAL SUB_CLK		:	STD_LOGIC := '0';
	-- GPIO SIGNALS -- 
	SIGNAL MemReadBus	: 	STD_LOGIC := '0';
	SIGNAL MemWriteBus	:	STD_LOGIC := '0';
	SIGNAL ControlBus	: 	STD_LOGIC_VECTOR(CtrlBusSize-1 DOWNTO 0) := (others => '0');
	SIGNAL AddrBus		: 	STD_LOGIC_VECTOR(AddrBusSize-1 DOWNTO 0) := (others => '0');
	SIGNAL DataBus		: 	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0) := (others => '0');
	
	-- BASIC TIMER --
	SIGNAL BTCTL		:	STD_LOGIC_VECTOR(CtrlBusSize-1 DOWNTO 0) := (others => '0');
	SIGNAL BTCNT		:	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0) := (others => '0');
	SIGNAL BTCCR0		:	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0) := x"FFFFFFFF";
	SIGNAL BTCCR1		:	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0) := (others => '0');
	SIGNAL BTIFG		:	STD_LOGIC := '0';

	
	-- INTERRUPT MODULE --
	SIGNAL IntSrc		:	STD_LOGIC_VECTOR(6 DOWNTO 0) := (others => '0');
	SIGNAL IRQ_OUT		:	STD_LOGIC_VECTOR(6 DOWNTO 0) := (others => '0');
	SIGNAL FIREMPTY_IRQ	:	STD_LOGIC := '0';
	SIGNAL RXIFG		:	STD_LOGIC := '0';
	SIGNAL TXIFG		:	STD_LOGIC := '0';
	SIGNAL INTR		:	STD_LOGIC := '0';
	SIGNAL INTA		:	STD_LOGIC := '1';  
	SIGNAL GIE		:	STD_LOGIC := '0';
	SIGNAL INTR_Active	:	STD_LOGIC := '0';
	SIGNAL CLR_IRQ		:	STD_LOGIC_VECTOR(6 DOWNTO 0) := (others => '0');
	-- Uart
	SIGNAL UART_STATUS_ERROR: STD_LOGIC;
	-- FIR
	SIGNAL FIREMPTY_STATUS 	: STD_LOGIC := '0';
	SIGNAL FIRIFG		: STD_LOGIC := '0';
	SIGNAL FIRCTL		: STD_LOGIC_VECTOR(CtrlBusSize-1 DOWNTO 0) := (others => '0');
	SIGNAL FIRIN		: STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0) := (others => '0');
	SIGNAL FIROUT		: STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0) := (others => '0');
	SIGNAL COEF0		: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	SIGNAL COEF1		: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	SIGNAL COEF2		: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	SIGNAL COEF3		: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	SIGNAL COEF4		: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	SIGNAL COEF5		: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	SIGNAL COEF6		: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	SIGNAL COEF7		: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	
BEGIN	

	-------------------------- FPGA or ModelSim -----------------------
	rstSim 	<= rst WHEN G_MODELSIM = 1 ELSE not rst;
	------------------------------- clocks ----------------------------
	FPGA: if G_MODELSIM = 0 GENERATE
		f_MHz: PLL_sub port MAP(
						refclk	 => CLK,
						outclk_0 => CLK_i
						);
		SUB_KHz: PLL_FIR port MAP(
						refclk	 => CLK,
						outclk_0 => SUB_CLK
						);
		f_KHz: Counter_Env port MAP(
						clk_in  => CLK,
						rst_n	=> rstSim,
						clk_out => FIRCLK
						);
		end generate;

	ModelSim: process(CLK_i_dbg, FIRCLK_dbg)
	begin
		if G_MODELSIM /= 0 then
			CLK_i  <= CLK_i_dbg;
			FIRCLK <= FIRCLK_dbg;
		end if;
	end process;
	----------------------------- components --------------------------
	CPU: MIPS
		GENERIC MAP(		WORD_GRANULARITY=> G_WORD_GRANULARITY,
	        			MODELSIM 	=> G_MODELSIM,
					DATA_BUS_WIDTH 	=> 32,
					ITCM_ADDR_WIDTH => G_ADDRWIDTH,
					DTCM_ADDR_WIDTH => G_ADDRWIDTH,
					DATA_WORDS_NUM 	=> G_DATA_WORDS_NUM,
	        			CtrlBusSize	=> 8,
					AddrBusSize	=> 32,
					DataBusSize	=> 32
					)
		PORT MAP(		rst_i		=> rstSim, 
					clk_i		=> CLK,
					ControlBus	=> ControlBus,
					MemReadBus	=> MemReadBus,
					MemWriteBus	=> MemWriteBus,
					AddrBus		=> AddrBus,
					GIE		=> GIE,
					INTR		=> INTR,
					INTA		=> INTA,
					INTR_Active	=> INTR_Active,
					CLR_IRQ		=> CLR_IRQ,
					DataBus		=> DataBus
					);
		
	
	IO_system: GPIO
		PORT MAP(		CLK          	=> CLK,
	        			rst          	=> rstSim,
					MemWriteBus	=> MemWriteBus,
					MemReadBus	=> MemReadBus,
					AddrBus		=> AddrBus,
					DataBus		=> DataBus,
					HEX0		=> HEX0,
					HEX1		=> HEX1,
					HEX2		=> HEX2,
					HEX3		=> HEX3,
					HEX4		=> HEX4,
					HEX5		=> HEX5,
					LEDR		=> LEDR,
	        			SWs		=> SWs
		);

	PROCESS(CLK)
	BEGIN
		if (falling_edge(CLK)) then
			if(AddrBus(11 DOWNTO 0) = X"81C" AND MemWriteBus = '1') then
				BTCTL <= ControlBus;
			END IF;
			if(AddrBus(11 DOWNTO 0) = X"824" AND MemWriteBus = '1') then
				BTCCR0 <= DataBus;
			END IF;
			if(AddrBus(11 DOWNTO 0) = X"828" AND MemWriteBus = '1') then
				BTCCR1 <= DataBus;
			END IF;
			if(AddrBus(11 DOWNTO 0) = X"830" AND MemWriteBus = '1') then
				FIRIN <= DataBus;
			END IF;
			if(AddrBus(11 DOWNTO 0) = X"838" AND MemWriteBus = '1') then
				COEF0 <= DataBus(7 downto 0);
				COEF1 <= DataBus(15 downto 8);
				COEF2 <= DataBus(23 downto 16);
				COEF3 <= DataBus(31 downto 24);
			END IF;
			if(AddrBus(11 DOWNTO 0) = X"83C" AND MemWriteBus = '1') then
				COEF4 <= DataBus(7 downto 0);
				COEF5 <= DataBus(15 downto 8);
				COEF6 <= DataBus(23 downto 16);
				COEF7 <= DataBus(31 downto 24);
			END IF;
		END IF;
	END PROCESS;

	----
	BTCNT	<= DataBus			WHEN (AddrBus(11 DOWNTO 0) = X"820" AND MemWriteBus = '1') ELSE (OTHERS => 'Z'); -- INPUT
	FIRCTL	<= ControlBus			WHEN (AddrBus(11 DOWNTO 0) = X"82C" AND MemWriteBus = '1') ELSE (OTHERS => 'Z'); -- INPUT
	DataBus	<= BTCNT			WHEN (AddrBus(11 DOWNTO 0) = X"820" AND MemReadBus = '1')  ELSE 
		   BTCCR0			WHEN (AddrBus(11 DOWNTO 0) = X"824" AND MemReadBus = '1')  ELSE 
	           BTCCR1			WHEN (AddrBus(11 DOWNTO 0) = X"828" AND MemReadBus = '1')  ELSE 
	           X"000000" & BTCTL		WHEN (AddrBus(11 DOWNTO 0) = X"81C" AND MemReadBus = '1')  ELSE 
		   X"000000" & FIRCTL		WHEN (AddrBus(11 DOWNTO 0) = X"82C" AND MemReadBus = '1')  ELSE
		   FIRIN			WHEN (AddrBus(11 DOWNTO 0) = X"830" AND MemReadBus = '1')  ELSE
		   FIROUT			WHEN (AddrBus(11 DOWNTO 0) = X"834" AND MemReadBus = '1')  ELSE
		   COEF3&COEF2&COEF1&COEF0	WHEN (AddrBus(11 DOWNTO 0) = X"838" AND MemReadBus = '1')  ELSE
		   COEF7&COEF6&COEF5&COEF4	WHEN (AddrBus(11 DOWNTO 0) = X"83C" AND MemReadBus = '1')  ELSE
		   (OTHERS => 'Z');  -- OUTPUT

	
	Basic_Timer: BasicTimer
		PORT MAP(
			address	=> AddrBus(11 DOWNTO 0),
			BTrd	=> MemReadBus,
			BTWrt	=> MemWriteBus,
			MCLK	=> CLK,
			rst	=> rstSim,
			BTCTL	=> BTCTL,
			BTCCR0	=> BTCCR0,
			BTCCR1	=> BTCCR1,
			BTCNT   => BTCNT,
			IRQ_OUT => IRQ_OUT(2),
			BTIFG	=> BTIFG,
			BTOUT	=> BTOUT
		);

	FIR_Filter: FIR
		port MAP( 
			FIFOCLK		=> CLK,
			FIRCTL		=> FIRCTL,
			address		=> AddrBus(11 DOWNTO 0),
			FIRrd		=> MemReadBus,
			FIRwrt		=> MemWriteBus,	
			FIRCLK		=> FIRCLK,
			FIRIFG		=> FIRIFG,
			FIRIN		=> FIRIN,
			FIROUT		=> FIROUT,
			FIREMPTY_STATUS	=> FIREMPTY_STATUS,
			IRQ_OUT		=> IRQ_OUT(6),
			FIREMPTY_IRQ	=> FIREMPTY_IRQ,
			COEF0		=> COEF0,
			COEF1		=> COEF1,
			COEF2		=> COEF2,
			COEF3		=> COEF3,
			COEF4		=> COEF4,
			COEF5		=> COEF5,
			COEF6		=> COEF6,
			COEF7		=> COEF7
		);
	IntSrc	<=  FIRIFG & (NOT KEY3) & (NOT KEY2) & (NOT KEY1) & BTIFG & TXIFG & RXIFG;
	Intr_Controller: Int_Cont
		PORT MAP(
			rst		=> rstSim,
		    	CLK		=> CLK,
		   	MemReadBus	=> MemReadBus,
		    	MemWriteBus	=> MemWriteBus,
		   	AddrBus		=> AddrBus,
		    	DataBus		=> DataBus,
		    	IntSrc		=> IntSrc,
		    	CS		=> '0',
		    	INTR		=> INTR,
		    	INTA		=> INTA,
			IRQ_OUT		=> IRQ_OUT,
			FIREMPTY_IRQ	=> FIREMPTY_IRQ,
			INTR_Active	=> INTR_Active,
			CLR_IRQ_OUT	=> CLR_IRQ,
			UART_STATUS_ERROR=> UART_STATUS_ERROR,
			FIREMPTY_STATUS => FIREMPTY_STATUS,
		   	GIE		=> GIE
		);
		
		
	---- Uart Support
	UART_COM: UART
		PORT MAP(
			CLK	 		=> CLK,
			rst		 	=> rstSim,
			RXIFG			=> RXIFG,
			TXIFG			=> TXIFG,
			B_RX			=> UART_RX,
			B_TX			=> UART_TX,
			UART_STATUS_ERROR	=> UART_STATUS_ERROR,
			AddrBus			=> AddrBus(11 DOWNTO 0),
			DataBus			=> DataBus,
			ControlBus		=> ControlBus,
			MemReadBus		=> MemReadBus,
		    	MemWriteBus		=> MemWriteBus
		);
		
END structure;