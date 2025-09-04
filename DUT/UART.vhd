-- Set Generic g_CLKS_PER_BIT as follows:
-- g_CLKS_PER_BIT = (Frequency of i_Clk)/(Frequency of UART)
-- Example: 10 MHz Clock, 115200 baud UART
-- (10000000)/(115200) = 87
-- 50 MHz Clock, 9600 baud UART - (50000000)/(9600) = 5208
-- In our case:
-- 50 MHz Clock, 115200 baud UART - (50000000)/(115200) = 434

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.aux_package.all;
 
entity UART is
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
end UART;
 
 
architecture struct of UART is

	SIGNAL UCTL				: STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "00001001";
	SIGNAL RXBUF				: STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "00000000";
	SIGNAL TXBUF				: STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := "00000000";
	SIGNAL g_CLKS_PER_BIT			: integer;

	SIGNAL RXIFG_s				: STD_LOGIC := '0';
	SIGNAL RX_BUSY				: STD_LOGIC := '0';
	SIGNAL TX_BUSY				: STD_LOGIC := '0';
	SIGNAL BUSY_s				: STD_LOGIC := '0';
	SIGNAL Data_RX				: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL Data_VLD_RX			: STD_LOGIC;	
	SIGNAL Data_VLD_TX			: STD_LOGIC;
	SIGNAL s_TX_Done			: STD_LOGIC;
	---- Error signals
	SIGNAL FRAMING_ERR			: STD_LOGIC;
	SIGNAL PARITY_ERR			: STD_LOGIC;
	SIGNAL OVERRUN_ERR			: STD_LOGIC;

	
 
begin
g_CLKS_PER_BIT <= 434 WHEN UCTL(3) = '1' ELSE 5208;
-- OUTPUT TO MCU -- 
DataBus <=	X"000000" & UCTL 	WHEN (AddrBus = X"818" AND MemReadBus = '1') ELSE
		X"000000" & RXBUF 	WHEN (AddrBus = X"819" AND MemReadBus = '1') ELSE
		X"000000" & TXBUF	WHEN (AddrBus = X"81A" AND MemReadBus = '1') ELSE
		(OTHERS => 'Z');		
	
	
----- Error -------
	UART_STATUS_ERROR <= FRAMING_ERR OR PARITY_ERR  OR OVERRUN_ERR ;
----- UCTL(7) --------
	BUSY_s <= RX_BUSY OR TX_BUSY ;
----- RX/TX Intr	
	RXIFG <= RXIFG_s;		
	TXIFG <= s_TX_Done;	

------------ RX PORT MAP	
    RX_RECEIVE : UART_RX
	PORT MAP (	i_Clk			=> CLK,
			i_RX_Serial		=> B_RX,
			o_RX_DV 		=> Data_VLD_RX,
			o_RX_Byte		=> Data_RX,	
			SWRST			=> UCTL(0),
			PENA			=> UCTL(1),
			PEV			=> UCTL(2),	
			FE			=> FRAMING_ERR,			
			PE			=> PARITY_ERR,
			OE			=> OVERRUN_ERR,
			BUSY			=> RX_BUSY,
			g_CLKS_PER_BIT 		=> g_CLKS_PER_BIT
		);

-------------- TX PORT MAP
    TX_TRANSMIT : UART_TX
	PORT MAP (	i_Clk		=> CLK,
			i_TX_DV		=> Data_VLD_TX,
			i_TX_Byte 	=> TXBUF,
			o_TX_Active	=> TX_BUSY,
			o_TX_Serial	=> B_TX,
			o_TX_Done	=> s_TX_Done,
			SWRST		=> UCTL(0),
			PENA		=> UCTL(1),
			g_CLKS_PER_BIT 	=> g_CLKS_PER_BIT
			); 
 
 
---- UCTL PROCESS

	PROCESS (CLK, rst)
	BEGIN
		IF rising_edge(CLK) THEN
			IF (rst = '1') THEN 
				UCTL <= "00001001";	
			ELSIF (AddrBus = X"818" AND MemWriteBus = '1') THEN
				--UCTL <= DataBus(7 DOWNTO 0);		
				UCTL <= ControlBus;			
			ELSIF UCTL(0) = '1' THEN
    				UCTL <= "00001001";	
			ELSE
				UCTL(4) 	<= FRAMING_ERR;
				UCTL(5)		<= PARITY_ERR;
				UCTL(6)		<= OVERRUN_ERR;	
				UCTL(7)  	<= BUSY_s;		
			END IF;
			
			-- RX BUFFER
			IF(rst = '1') THEN 
				RXBUF <= "00000000";
			ELSIF ( Data_VLD_RX = '1' AND NOT (AddrBus = X"819" AND MemReadBus = '1') ) THEN
				RXIFG_s <= '1';
				RXBUF <= Data_RX;
			ELSIF ( (AddrBus = X"819" AND MemReadBus = '1') AND NOT Data_VLD_RX = '1' ) THEN
				RXBUF <= "00000000";
				RXIFG_s <= '0';
			END IF;
			
			-- TX BUFFER
			IF(rst = '1') THEN 
				TXBUF <= "00000000";
			ELSIF ( AddrBus = X"81A" AND MemWriteBus = '1' ) THEN
				Data_VLD_TX <= '1';
				TXBUF 	<= DataBus(7 DOWNTO 0);
			ELSE
				Data_VLD_TX <= '0';
			END IF;
			
		END IF;
	END PROCESS;   
end struct;
