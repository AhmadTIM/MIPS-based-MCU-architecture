LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE work.aux_package.ALL;
----------------------------------------------------------------
ENTITY PulseSynch IS
	PORT ( 	FIFOCLK	: IN  std_logic := '0';
		FIRCLK	: IN  std_logic := '0';
		Ain 	: IN  std_logic := '0';
		Dout	: OUT std_logic := '0'
	     );
end PulseSynch; 
----------------------------------------------------------------
architecture struct of PulseSynch is
	Signal Din 	: std_logic := '0';
	Signal Ds 	: std_logic := '0';
begin
	Domain_A: process(FIRCLK)
	begin
		IF rising_edge(FIRCLK) then
			Din 	<= Ain;
		END IF;
	END process;

	Domain_B: process(FIFOCLK)
	begin
		IF rising_edge(FIFOCLK) then
			Ds 	<= Din;
			Dout 	<= Ds;
		END IF;
	END process;

end struct; 




