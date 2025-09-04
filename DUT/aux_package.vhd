---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
USE work.cond_comilation_package.all;


package aux_package is

	component MIPS is
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
	end component;
---------------------------------------------------------  
	component control is
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
	end component;
---------------------------------------------------------	
	component dmemory is
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
	end component;
---------------------------------------------------------		
	component Execute is
	generic(
		DATA_BUS_WIDTH : integer := 32;
		FUNCT_WIDTH : integer := 6;
		PC_WIDTH : integer := 10
	);
	PORT(	read_data1_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			sign_extend_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			funct_i 	: IN 	STD_LOGIC_VECTOR(5 DOWNTO 0);
			ALUOp_ctrl_i 	: IN 	STD_LOGIC_VECTOR(3 DOWNTO 0);
			RegDst_ctrl_i	: IN    STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			ALUSrc_ctrl_i 	: IN 	STD_LOGIC;
			ForwardA 	: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);		
			ForwardB	: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			WrDataFW_WB	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			WrDataFW_MEM	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			WrRegAddr0	: IN    STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			WrRegAddr1	: IN    STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			WrRegAddr       : OUT   STD_LOGIC_VECTOR( 4 DOWNTO 0 );
			WriteData_EX    : OUT   STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			zero_o	 	: OUT	STD_LOGIC;
			alu_res_o 	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
	);
	end component;
---------------------------------------------------------		
	component Idecode is
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
			GIE				: OUT 	STD_LOGIC;
			ISR_PC_RD			: IN	STD_LOGIC;
			EPC				: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
			INTR				: IN	STD_LOGIC;
			INTR_Active			: IN	STD_LOGIC;
			CLR_IRQ				: IN	STD_LOGIC_VECTOR(6 DOWNTO 0);
			sign_extend_o 			: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)		 
	);
	end component;
---------------------------------------------------------		
	component Ifetch is
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
	end component;
---------------------------------------------------------
	component WriteBack is
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
	end component;
---------------------------------------------------------
	component ForwardingUnit is
	PORT( 
		WriteReg_MEM, WriteReg_WB	: IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
		RegRs_EX, RegRt_EX 		: IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
		RegRs_ID, RegRt_ID 		: IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
		RegWr_MEM, RegWr_WB		: IN  STD_LOGIC;
		ForwardA, ForwardB		: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		ForwardA_ID, ForwardB_ID	: OUT STD_LOGIC
		);
	end component;
---------------------------------------------------------
	component HazardUnit is
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
	end component;
---------------------------------------------------------
	component SevenSegDecoder IS
  		GENERIC (n: INTEGER := 4;
	   		 Size: integer := 7);
  		PORT (input: in STD_LOGIC_VECTOR (n-1 DOWNTO 0);
			output: out STD_LOGIC_VECTOR (Size-1 downto 0));
	END component;
---------------------------------------------------------
	component BasicTimer IS
	PORT( 	
		address	: IN	STD_LOGIC_VECTOR(11 DOWNTO 0);
		BTrd	: IN	STD_LOGIC;
		BTwrt	: IN	STD_LOGIC;
		MCLK	: IN 	STD_LOGIC;
		rst	: IN 	STD_LOGIC;
		BTCTL	: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
		BTCCR0	: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
		BTCCR1	: IN	STD_LOGIC_VECTOR(31 DOWNTO 0);
		BTCNT   : INOUT	STD_LOGIC_VECTOR(31 DOWNTO 0);
		IRQ_OUT : IN	STD_LOGIC;
		BTIFG	: OUT 	STD_LOGIC;
		BTOUT	: OUT	STD_LOGIC
		);
	END component;
----------------------------------------------------------
	component GPIO IS
	    PORT (
	        CLK          : IN  STD_LOGIC;
	        rst          : IN  STD_LOGIC;
	        MemReadBus   : IN  STD_LOGIC;
	        MemWriteBus  : IN  STD_LOGIC;
	        AddrBus      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
	        DataBus      : INOUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	        HEX0, HEX1   : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	        HEX2, HEX3   : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	        HEX4, HEX5   : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	        LEDR         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	        SWs          : IN  STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	END component;
----------------------------------------------------------
	component PulseSynch IS
		PORT ( 	FIFOCLK	: IN  std_logic;
			FIRCLK	: IN  std_logic;
			Ain 	: IN  std_logic;
			Dout	: OUT std_logic
		     );
	end component;
----------------------------------------------------------
	component FIR IS
	PORT ( 	FIFOCLK		: IN  std_logic;
		FIRCTL		: INOUT  std_logic_vector(7 downto 0) := (others => '0');
		address		: IN	STD_LOGIC_VECTOR(11 DOWNTO 0);
		FIRrd		: IN std_logic;
		FIRwrt		: IN std_logic;
		FIRCLK		: IN  std_logic;
		FIRIFG		: OUT  std_logic;
		FIRIN		: IN  std_logic_vector(31 downto 0);
		FIROUT		: OUT  std_logic_vector(31 downto 0);
		FIREMPTY_STATUS	: OUT std_logic;
		IRQ_OUT		: IN  std_logic;
		FIREMPTY_IRQ	: IN	STD_LOGIC;
		COEF0		: IN  std_logic_vector(7 downto 0);
		COEF1		: IN  std_logic_vector(7 downto 0);
		COEF2		: IN  std_logic_vector(7 downto 0);
		COEF3		: IN  std_logic_vector(7 downto 0);
		COEF4		: IN  std_logic_vector(7 downto 0);
		COEF5		: IN  std_logic_vector(7 downto 0);
		COEF6		: IN  std_logic_vector(7 downto 0);
		COEF7		: IN  std_logic_vector(7 downto 0)
	     );
	end component;
----------------------------------------------------------
	component Int_Cont IS
	PORT(   rst		: IN	STD_LOGIC;
		CLK		: IN	STD_LOGIC;
		MemReadBus	: IN	STD_LOGIC;
		MemWriteBus	: IN	STD_LOGIC;
		AddrBus		: IN	STD_LOGIC_VECTOR(31 DOWNTO 0);
		DataBus		: INOUT	STD_LOGIC_VECTOR(31 DOWNTO 0);
		IntSrc		: IN	STD_LOGIC_VECTOR(6 DOWNTO 0); -- IRQ
		CS		: IN	STD_LOGIC;
		INTR		: OUT	STD_LOGIC;
		INTA		: IN	STD_LOGIC;
		IRQ_OUT		: OUT   STD_LOGIC_VECTOR(6 DOWNTO 0);
		FIREMPTY_IRQ	: OUT	STD_LOGIC;
		INTR_Active	: OUT	STD_LOGIC;
		CLR_IRQ_OUT	: OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);		
		UART_Status_Error : IN STD_LOGIC;
		FIREMPTY_STATUS : IN STD_LOGIC;
		GIE		: IN	STD_LOGIC
		);
	END component;
----------------------------------------------------------
	component UART_RX is
	  port (
	    	i_Clk       : in  std_logic;
	    	i_RX_Serial : in  std_logic := '1';
	    	o_RX_DV     : out std_logic;
	    	o_RX_Byte   : out std_logic_vector(7 downto 0);
	
	    	-- UCTL register bits
	    	SWRST       : in  std_logic := '0';  -- Software reset
	    	PENA        : in  std_logic := '0';  -- Parity enable
	    	PEV         : in  std_logic := '0';  -- Parity select (0=odd, 1=even)
		
	    	FE          : out std_logic := '0';  -- Framing error
	    	PE          : out std_logic := '0';  -- Parity error
	    	OE          : out std_logic := '0';  -- Overrun error
	    	BUSY        : out std_logic := '0';   -- Busy flag
		g_CLKS_PER_BIT : integer
	  	);
	end component;
----------------------------------------------------------
	component UART_TX is
	  port (
	    	i_Clk       	: in  std_logic;
	    	i_TX_DV     	: in  std_logic;
	   	i_TX_Byte   	: in  std_logic_vector(7 downto 0);
	    	o_TX_Active 	: out std_logic; -- BUSY
	    	o_TX_Serial 	: out std_logic;
	    	o_TX_Done   	: out std_logic;
	   	SWRST       	: in  std_logic := '0'; -- Software reset enable
	   	PENA        	: in  std_logic := '0'; -- Parity enable
	    	g_CLKS_PER_BIT 	: in integer
	    	);
	end component;
----------------------------------------------------------
	component UART is
	PORT(
		CLK, rst      		: in  	std_logic;
		RXIFG 			: out  	std_logic := '0';
		TXIFG			: out	std_logic := '0';
		B_RX			: in	std_logic := '1';
		B_TX     		: out 	std_logic := '1';
		UART_STATUS_ERROR	: out	std_logic;
		AddrBus			: IN	STD_LOGIC_VECTOR(11 DOWNTO 0);	
		DataBus			: INOUT	STD_LOGIC_VECTOR(31 DOWNTO 0);
		ControlBus		: IN	STD_LOGIC_VECTOR(7 downto 0);
		MemReadBus		: IN	STD_LOGIC := '0';
		MemWriteBus		: IN	STD_LOGIC := '0'
		);
	end component;
----------------------------------------------------------
	component MCU IS
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
	END component;
----------------------------------------------------------
	component Counter_Env is
	 	port(
    			clk_in  : in  std_logic;   -- 11.2896 MHz from PLL
    			rst_n   : in  std_logic;   -- active-low reset
    			clk_out : out std_logic    -- 44.1 kHz output
  			);
	end component;
----------------------------------------------------------
	 component PLL_sub is
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		locked   : out std_logic         --  locked.export
	);
	end component;
----------------------------------------------------------
	component PLL_FIR is
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		locked   : out std_logic         --  locked.export
	);
	end component;
----------------------------------------------------------
end aux_package;




















