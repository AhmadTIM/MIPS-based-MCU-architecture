LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE work.aux_package.ALL;
-------------- ENTITY --------------------
ENTITY BasicTimer IS
	PORT( 	
		address	: IN	STD_LOGIC_VECTOR(11 DOWNTO 0);
		BTrd	: IN	STD_LOGIC;
		BTwrt	: IN	STD_LOGIC;
		MCLK	: IN 	STD_LOGIC;
		rst	: IN 	STD_LOGIC;
		BTCTL	: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
		BTCCR0	: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0) := x"FFFFFFFF";
		BTCCR1	: IN	STD_LOGIC_VECTOR(31 DOWNTO 0);
		BTCNT   : INOUT	STD_LOGIC_VECTOR(31 DOWNTO 0);
		IRQ_OUT : IN	STD_LOGIC;
		BTIFG	: OUT STD_LOGIC;
		BTOUT	: OUT	STD_LOGIC
		);
END BasicTimer;
-------------------------------------------
architecture struct of BasicTimer is
	SIGNAL BTCNT_s	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL BTCL0	: STD_LOGIC_VECTOR(31 DOWNTO 0) := x"FFFFFFFF";
	SIGNAL BTCL1	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL PWMout	: STD_LOGIC;
	SIGNAL C_32	: std_logic := '0';
	SIGNAL HEU0	: STD_LOGIC := '0';
	SIGNAL Z_vector	: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
	SIGNAL CLK2, CLK4, CLK8, ChosenCLK : STD_LOGIC;
begin
	BTCNT <= BTCNT_s WHEN (address = X"820" AND BTrd = '1') ELSE (OTHERS => 'Z');	
-------------------------------------------------------------------------------------	input
	BTCCRx: PROCESS (MCLK)
	BEGIN
		IF (rising_edge(MCLK)) THEN
			IF (BTCNT_s = Z_vector) THEN
				BTCL0 <= BTCCR0;
				BTCL1 <= BTCCR1;
			END IF;
		END IF;
	END PROCESS;
--------------------------------------------------------------------------------------	PWM
	process(chosenCLK) 
	begin
	  	if rising_edge(chosenCLK) then
			if (unsigned(BTCNT_s) >= unsigned(BTCL0)) then
				HEU0 <= '1';
			else
				HEU0 <= '0';
			end if;
	  	end if;
	end process;


	PWM: PROCESS (chosenCLK, rst)
	BEGIN
		IF rst = '1' THEN
			PWMout <= '0';
		ELSIF (rising_edge(chosenCLK)) THEN
			IF (BTCTL(6) = '0') THEN
				PWMout	<= '0';
			ELSE
				IF (BTCTL(7) = '0') THEN
					IF (BTCNT_s < BTCL1) THEN
						PWMout <= '0';
					ELSE
						PWMout <= '1';
					END IF;
				ELSIF (BTCTL(7) = '1') THEN
					IF (BTCNT_s < BTCL1) THEN
						PWMout <= '1';
					ELSE
						PWMout <= '0';
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	BTOUT	<= PWMout;
--------------------------------------------------------------------------------------	CLK division
	chosenCLK <=  MCLK  WHEN BTCTL(4 DOWNTO 3) = "00"  OR BTCTL(5) = '1' ELSE
	              CLK2  WHEN BTCTL(4 DOWNTO 3) = "01" ELSE
	              CLK4  WHEN BTCTL(4 DOWNTO 3) = "10" ELSE
	              CLK8  WHEN BTCTL(4 DOWNTO 3) = "11" ELSE
	              MCLK;

	ClockDivider1: PROCESS (rst, MCLK)
	BEGIN
	    IF rst = '1' THEN
	        CLK2 <= '0';
	    ELSIF (MCLK'EVENT) AND (MCLK = '1') THEN
	        CLK2 <= NOT CLK2;
	    END IF;
	END PROCESS;
	
	ClockDivider2: PROCESS (rst, CLK2, MCLK)
	BEGIN
	    IF rst = '1' THEN
	        CLK4 <= '0';
	    ELSIF (CLK2'EVENT) AND (CLK2 = '1') THEN
	        CLK4 <= NOT CLK4;
	    END IF;
	END PROCESS;

	ClockDivider3: PROCESS (rst, CLK4, MCLK)
	BEGIN
	    IF rst = '1' THEN
	        CLK8 <= '0';
	    ELSIF (CLK4'EVENT) AND (CLK4 = '1') THEN
	        CLK8 <= NOT CLK8;
	    END IF;
	END PROCESS;
-------------------------------------------------------------------------------------- BTCNT
	BTCNT_REG: PROCESS (rst, ChosenCLk, BTCTL(2), IRQ_OUT)
	BEGIN
		IF (rst = '1' OR BTCTL(2) = '1' OR IRQ_OUT = '1') THEN
			BTCNT_s <= (others => '0');
			C_32	<= '0';
		ELSIF rising_edge(ChosenCLK) THEN
			IF BTCTL(5) = '0' THEN
				IF (HEU0 = '0') THEN
			                BTCNT_s <= BTCNT_s + 1;
			                if BTCNT_s = x"FFFFFFFE" then
						C_32 <= '1';
					end if;
				ELSE
					BTCNT_s <= (others => '0');
				END IF;
			ELSIF (BTCTL(5) = '1' AND (address = X"820" AND BTwrt = '1')) THEN
				BTCNT_s <= BTCNT;
			END IF;
		END IF;
	END PROCESS;
-------------------------------------------------------------------------------------- BTIFG
	with BTCTL(1 DOWNTO 0) select
	BTIFG <= HEU0 		when "00",
		 BTCNT_s(24) 	when "01",
		 BTCNT_s(28) 	when "10",
		 C_32	 	when "11",
		 '0'		when others;
end struct;




