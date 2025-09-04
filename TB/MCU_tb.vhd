LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.cond_comilation_package.all;
USE work.aux_package.all;

ENTITY MCU_TB IS
END MCU_TB;

ARCHITECTURE behavior OF MCU_TB IS

    -- Clock periods
    CONSTANT CLK_PERIOD      : TIME := 20 ns;          -- 50 MHz
    CONSTANT CLK_DBG_PERIOD  : TIME := 17.935 ns;      -- 55.8 MHz
    CONSTANT FIRCLK_PERIOD   : TIME := 22.675 us;      -- 44.1 kHz

    -- Signals
    SIGNAL rst          : STD_LOGIC := '1';
    SIGNAL CLK          : STD_LOGIC := '0';
    SIGNAL CLK_i_dbg    : STD_LOGIC := '0';
    SIGNAL FIRCLK_dbg   : STD_LOGIC := '0';
    SIGNAL HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL LEDR         : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL SWs          : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000010";
    SIGNAL BTOUT        : STD_LOGIC;
    SIGNAL KEY1, KEY2, KEY3 : STD_LOGIC := '1';
    SIGNAL UART_RX      : STD_LOGIC := '1';
    SIGNAL UART_TX      : STD_LOGIC;

BEGIN

    -- Instantiate the MCU
    DUT: MCU
        GENERIC MAP (
            CtrlBusSize => 8,
            AddrBusSize => 32,
            DataBusSize => 32
        )
        PORT MAP (
            rst => rst,
            CLK => CLK,
            CLK_i_dbg => CLK_i_dbg,
            FIRCLK_dbg => FIRCLK_dbg,
            HEX0 => HEX0,
            HEX1 => HEX1,
            HEX2 => HEX2,
            HEX3 => HEX3,
            HEX4 => HEX4,
            HEX5 => HEX5,
            LEDR => LEDR,
            SWs => SWs,
            BTOUT => BTOUT,
            KEY1 => KEY1,
            KEY2 => KEY2,
            KEY3 => KEY3,
            UART_RX => UART_RX,
            UART_TX => UART_TX
        );

    -- 50 MHz clock
    CLK_process: PROCESS
    BEGIN
        LOOP
            CLK <= '0';
            WAIT FOR CLK_PERIOD / 2;
            CLK <= '1';
            WAIT FOR CLK_PERIOD / 2;
        END LOOP;
    END PROCESS;

    -- 55.8 MHz debug clock
    CLK_DBG_process: PROCESS
    BEGIN
        LOOP
            CLK_i_dbg <= '0';
            WAIT FOR CLK_DBG_PERIOD / 2;
            CLK_i_dbg <= '1';
            WAIT FOR CLK_DBG_PERIOD / 2;
        END LOOP;
    END PROCESS;

    -- 44.1 kHz FIR clock
    FIRCLK_process: PROCESS
    BEGIN
        LOOP
            FIRCLK_dbg <= '0';
            WAIT FOR FIRCLK_PERIOD / 2;
            FIRCLK_dbg <= '1';
            WAIT FOR FIRCLK_PERIOD / 2;
        END LOOP;
    END PROCESS;

    -- Reset process
    rst_process: PROCESS
    BEGIN
        rst <= '1';
        WAIT FOR 100 ns;      -- Hold reset for 100 ns
        rst <= '0';
        WAIT;
    END PROCESS;

    -- Stimulus process for KEY1/KEY2/KEY3 synchronized to CLK_i_dbg
    stim_process: PROCESS
    BEGIN
        -- Wait for reset to finish
	for i in 0 to 1000 loop
        	WAIT UNTIL rising_edge(CLK);
	end loop;

        -----------------------------------------------------------------
        -- Test KEY1
        -----------------------------------------------------------------
        SWs <= "00001111";   -- example switch value
        WAIT UNTIL rising_edge(CLK);
        KEY1 <= '0';         -- press KEY1
        WAIT UNTIL rising_edge(CLK);
        KEY1 <= '1';         -- release KEY1
	for i in 0 to 100 loop
        	WAIT UNTIL rising_edge(CLK);
	end loop;

        -----------------------------------------------------------------
        -- End simulation
        -----------------------------------------------------------------
        WAIT;  -- stop process
    END PROCESS;



END ARCHITECTURE;
