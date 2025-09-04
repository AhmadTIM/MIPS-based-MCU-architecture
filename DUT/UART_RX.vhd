----------------------------------------------------------------------
-- UART Receiver with UCTL Register Features
-- Based on nandland.com UART RX + extended with:
--   - SWRST (software reset)
--   - PENA, PEV (parity enable/select)
--   - FE (framing error)
--   - PE (parity error)
--   - OE (overrun error)
--   - BUSY (module active flag)
-- Supports: 1 start bit, 8 data bits, optional parity, 1 stop bit
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity UART_RX is
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
end UART_RX;


architecture rtl of UART_RX is

  type t_SM_Main is (s_Idle, s_RX_Start_Bit, s_RX_Data_Bits, 
                     s_RX_Parity, s_RX_Stop_Bit, s_Cleanup);
  signal r_SM_Main   : t_SM_Main := s_Idle;

  signal r_RX_Data_R : std_logic := '1';
  signal r_RX_Data   : std_logic := '1';

  signal r_Clk_Count : integer := 0;
  signal r_Bit_Index : integer range 0 to 7 := 0;
  signal r_RX_Byte   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_RX_DV     : std_logic := '0';

  signal parity_check : std_logic := '0';

begin

  -- Double-register the input for metastability protection
  p_SAMPLE : process (i_Clk)
  begin
    if rising_edge(i_Clk) then
      r_RX_Data_R <= i_RX_Serial;
      r_RX_Data   <= r_RX_Data_R;
    end if;
  end process p_SAMPLE;


  -- RX State Machine
  p_UART_RX : process (i_Clk)
  begin
    if rising_edge(i_Clk) then

      -- Software reset
      if SWRST = '1' then
        r_SM_Main   <= s_Idle;
        r_RX_DV     <= '0';
        r_Clk_Count <= 0;
        r_Bit_Index <= 0;
        BUSY        <= '0';
      else

        case r_SM_Main is

          when s_Idle =>
            r_RX_DV     <= '0';
            r_Clk_Count <= 0;
            r_Bit_Index <= 0;
            BUSY        <= '0';

            if r_RX_Data = '0' then  -- Start bit detected
              r_SM_Main <= s_RX_Start_Bit;
              BUSY      <= '1';
            else
              r_SM_Main <= s_Idle;
            end if;

          when s_RX_Start_Bit =>
            if r_Clk_Count = (g_CLKS_PER_BIT-1)/2 then
              if r_RX_Data = '0' then
                r_Clk_Count <= 0;
                r_SM_Main   <= s_RX_Data_Bits;
              else
                r_SM_Main   <= s_Idle;
              end if;
            else
              r_Clk_Count <= r_Clk_Count + 1;
            end if;

          when s_RX_Data_Bits =>
            if r_Clk_Count < g_CLKS_PER_BIT-1 then
              r_Clk_Count <= r_Clk_Count + 1;
            else
              r_Clk_Count            <= 0;
              r_RX_Byte(r_Bit_Index) <= r_RX_Data;

              if r_Bit_Index < 7 then
                r_Bit_Index <= r_Bit_Index + 1;
              else
                r_Bit_Index <= 0;
                if PENA = '1' then
                  r_SM_Main <= s_RX_Parity;
                else
                  r_SM_Main <= s_RX_Stop_Bit;
                end if;
              end if;
            end if;

          when s_RX_Parity =>
            if r_Clk_Count < g_CLKS_PER_BIT-1 then
              r_Clk_Count <= r_Clk_Count + 1;
            else
              -- Check parity
              if (PEV = '0') then -- Odd parity
                PE <= parity_check XOR r_RX_Data; 
              else                -- Even parity
                PE <= NOT (parity_check XOR r_RX_Data);
              end if;
              r_Clk_Count <= 0;
              r_SM_Main   <= s_RX_Stop_Bit;
            end if;

          when s_RX_Stop_Bit =>
            if r_Clk_Count < g_CLKS_PER_BIT-1 then
              r_Clk_Count <= r_Clk_Count + 1;
            else
              r_Clk_Count <= 0;
              r_RX_DV     <= '1';
              r_SM_Main   <= s_Cleanup;

              -- Framing error if stop bit not high
              if r_RX_Data = '0' then
                FE <= '1';
              --else
              --  FE <= '0';
              end if;
            end if;

          when s_Cleanup =>
            r_SM_Main <= s_Idle;
            r_RX_DV   <= '0';
            BUSY      <= '0';

          when others =>
            r_SM_Main <= s_Idle;

        end case;

        -- Overrun error: new start bit while previous data not read
        if (i_RX_Serial = '0' and r_RX_DV = '1') then
          OE <= '1';
        else
          OE <= '0';
        end if;

      end if; -- SWRST
    end if; -- rising edge
  end process p_UART_RX;

  o_RX_DV   <= r_RX_DV;
  o_RX_Byte <= r_RX_Byte;

  -- Compute parity from received data
  parity_check <= r_RX_Byte(0) XOR r_RX_Byte(1) XOR r_RX_Byte(2) XOR r_RX_Byte(3) XOR
                  r_RX_Byte(4) XOR r_RX_Byte(5) XOR r_RX_Byte(6) XOR r_RX_Byte(7);

end rtl;

