--------------- Interrupt Controller Module 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE work.aux_package.ALL;
-------------- ENTITY --------------------
ENTITY Int_Cont IS
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
END Int_Cont;
------------ ARCHITECTURE ----------------
ARCHITECTURE struct OF Int_Cont IS
	SIGNAL IRQ				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL CLR_IRQ				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	-- UART 
	SIGNAL IRQ_SE, CLR_IRQ_SE 		: STD_LOGIC;
	SIGNAL IRQ_FIFOEMPTY, CLR_IRQ_FIFOEMPTY : STD_LOGIC;
	--
	SIGNAL IE				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL IFG				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL TypeReg				: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL INTA_Delayed 			: STD_LOGIC;
	
	
	
BEGIN
--------------------------- IO MCU ---------------------------
-- OUTPUT TO MCU -- 
DataBus <=	X"000000" 	& TypeReg 	WHEN ((AddrBus(11 DOWNTO 0) = X"842" AND MemReadBus = '1') OR (INTA = '0' AND MemReadBus = '0')) ELSE
		X"000000"&"0" 	& IE 		WHEN (AddrBus(11 DOWNTO 0) = X"840" AND MemReadBus = '1') ELSE
		X"000000"&"0" 	& IFG		WHEN (AddrBus(11 DOWNTO 0) = X"841" AND MemReadBus = '1') ELSE
		(OTHERS => 'Z');

--INPUT FROM MCU -- 

PROCESS(CLK) 
BEGIN
	IF (rst = '1') then
		IE <= (others => '0');
	ELSIF (falling_edge(CLK)) THEN
		IF (AddrBus(11 DOWNTO 0) = X"840" AND MemWriteBus = '1') THEN
			IE 	<= DataBus(6 DOWNTO 0);
		END IF;		
	END IF;
END PROCESS;

IFG 	<=	DataBus(6 DOWNTO 0) WHEN (AddrBus(11 DOWNTO 0) = X"841" AND MemWriteBus = '1') ELSE
		IRQ AND IE;		

-------------------------------------------------------------

-- Find the INTR output
PROCESS (CLK, IFG) BEGIN 
	IF (rising_edge(CLK)) THEN
		IF (IFG(0) = '1' OR IFG(1) = '1' OR IFG(2) = '1' OR
		    IFG(3) = '1' OR IFG(4) = '1' OR IFG(5) = '1' or
		    IFG(6) = '1' OR (IRQ_FIFOEMPTY = '1' AND IE(6) = '1')
		    OR (IRQ_SE = '1' AND IE(0) = '1')) THEN
			INTR <= GIE;
		ELSE 
			INTR <= '0';
		END IF;
	END IF;
END PROCESS;
-- UART STATUS (special case, not in IRQ vector)
PROCESS (rst, CLR_IRQ_SE, UART_Status_Error)
BEGIN
    IF (rst = '1') THEN
        IRQ_SE <= '0';
    ELSIF CLR_IRQ_SE = '0' THEN
        IRQ_SE <= '0';
    ELSIF rising_edge(UART_Status_Error) THEN
        IRQ_SE <= '1';
    END IF;
END PROCESS;

-- FIREMPTY (special case, not in IRQ vector)
PROCESS (rst, CLR_IRQ_FIFOEMPTY, FIREMPTY_STATUS)
BEGIN
    IF (rst = '1') THEN
        IRQ_FIFOEMPTY <= '0';
    ELSIF CLR_IRQ_FIFOEMPTY = '0' THEN
        IRQ_FIFOEMPTY <= '0';
    ELSIF rising_edge(FIREMPTY_STATUS) THEN
        IRQ_FIFOEMPTY <= '1';
    END IF;
END PROCESS;

-- General IRQs (RX, TX, BTIMER, KEY1, KEY2, KEY3, FIROUT)
IRQ_PROC: FOR i IN 0 TO 6 GENERATE
    IRQ_PROC_i: PROCESS(rst, CLR_IRQ(i), IntSrc(i))
    BEGIN
        IF (rst = '1') THEN
            IRQ(i) <= '0';
        ELSIF CLR_IRQ(i) = '0' THEN
            IRQ(i) <= '0';
        ELSIF rising_edge(IntSrc(i)) THEN
            IRQ(i) <= '1';
        END IF;
    END PROCESS;
END GENERATE;

IRQ_OUT <= IRQ;
FIREMPTY_IRQ <= IRQ_FIFOEMPTY;
PROCESS (CLK) BEGIN
	IF (rst = '1') THEN
		INTA_Delayed <= '1';
	ELSIF (falling_edge(CLK)) THEN
		INTA_Delayed <= INTA;
	END IF;
END PROCESS;

-- Clear IRQ When Interrupt Ack recv
CLR_IRQ(0) <= '0' WHEN (TypeReg = X"08" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(1) <= '0' WHEN (TypeReg = X"0C" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(2) <= '0' WHEN (TypeReg = X"10" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(3) <= '0' WHEN (TypeReg = X"14" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(4) <= '0' WHEN (TypeReg = X"18" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(5) <= '0' WHEN (TypeReg = X"1C" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(6) <= '0' WHEN (TypeReg = X"24" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ_SE <= '0' WHEN (TypeReg = X"04" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ_FIFOEMPTY  <= '0' WHEN (TypeReg = X"20" AND INTA = '1' AND INTA_Delayed = '0') ELSE '1';


CLR_IRQ_OUT <= CLR_IRQ;

-- Determinate if interrupt is currently active
INTR_Active	<= 	IFG(0) OR IFG(1) OR IFG(2) OR IFG(3) OR IFG(4) OR IFG(5) or IFG(6);

-- Interrupt Vectors
TypeReg	<= 	X"00" WHEN rst  = '1' ELSE -- main
		X"04" WHEN (IRQ_SE = '1' AND IE(0) = '1') ELSE  -- Uart Status Error
		X"08" WHEN IFG(0) = '1' ELSE  	-- Uart RX
		X"0C" WHEN IFG(1) = '1' ELSE  	-- Uart TX
		X"10" WHEN IFG(2) = '1' ELSE  	-- Basic timer
		X"14" WHEN IFG(3) = '1' ELSE  	-- KEY1
		X"18" WHEN IFG(4) = '1' ELSE	-- KEY2
		X"1C" WHEN IFG(5) = '1' ELSE	-- KEY3
		X"20" WHEN (IRQ_FIFOEMPTY = '1' AND IE(6) = '1') ELSE  -- FIREMPTY
		X"24" WHEN IFG(6) = '1' ELSE	-- FIROUT
		(OTHERS => 'Z');

END struct;

