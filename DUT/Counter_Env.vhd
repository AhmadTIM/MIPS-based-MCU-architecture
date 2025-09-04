library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Counter_Env is
  port(
    clk_in  : in  std_logic;   -- 11.2896 MHz from PLL
    rst_n   : in  std_logic;   -- active-low reset
    clk_out : out std_logic    -- 44.1 kHz output
  );
end Counter_Env;

architecture rtl of Counter_Env is
  signal counter : unsigned(10 downto 0) := (others => '0');
begin
  process(clk_in, rst_n)
  begin
    if rst_n = '1' then
      counter <= (others => '0');
    elsif rising_edge(clk_in) then
      counter <= counter + 1;
    end if;
  end process;

  -- MSB of counter = clk_in / 256
  clk_out <= counter(10);
end architecture rtl;
