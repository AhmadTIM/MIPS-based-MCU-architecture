LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.aux_package.ALL;

----------------------------------------------------------
ENTITY FIR IS
    PORT (
        FIFOCLK          : IN  std_logic;
        FIRCTL           : INOUT  std_logic_vector(7 downto 0) := (others => '0');
        address          : IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
        FIRrd            : IN  std_logic;
        FIRwrt           : IN  std_logic;
        FIRCLK           : IN  std_logic;
        FIRIFG           : OUT std_logic;
        FIRIN            : IN  std_logic_vector(31 downto 0);
        FIROUT           : OUT std_logic_vector(31 downto 0);
        FIREMPTY_STATUS  : OUT std_logic;
        IRQ_OUT          : IN  std_logic;
	FIREMPTY_IRQ	 : IN  STD_LOGIC;
        COEF0            : IN  std_logic_vector(7 downto 0);
        COEF1            : IN  std_logic_vector(7 downto 0);
        COEF2            : IN  std_logic_vector(7 downto 0);
        COEF3            : IN  std_logic_vector(7 downto 0);
        COEF4            : IN  std_logic_vector(7 downto 0);
        COEF5            : IN  std_logic_vector(7 downto 0);
        COEF6            : IN  std_logic_vector(7 downto 0);
        COEF7            : IN  std_logic_vector(7 downto 0)
    );
END FIR;

-----------------------------------------------------------
ARCHITECTURE struct OF FIR IS
    TYPE mem  IS ARRAY (0 TO 7) OF std_logic_vector(31 downto 0);
    TYPE mem2 IS ARRAY (0 TO 7) OF std_logic_vector(23 downto 0);

    SIGNAL SynchroFIFO   : mem := (others => (others => '0'));
    SIGNAL w_ptr         : integer := 0;
    SIGNAL r_ptr         : integer := 0;
    SIGNAL FIFOIN        : std_logic_vector(31 downto 0) := (others => '0');
    SIGNAL FIFOREN       : std_logic := '0';
    --SIGNAL DATAOUT       : std_logic_vector(31 downto 0);
    SIGNAL X_n           : mem2 := (others => (others => '0'));
    --SIGNAL mul_res       : mem := (others => (others => '0'));
    --SIGNAL FIRCTL_out    : std_logic_vector(7 downto 0) := (others => '0');
    SIGNAL FIRCTL_in     : std_logic_vector(7 downto 0) := (others => '0');
    --SIGNAL firwen_reg    : std_logic := '0';
    --SIGNAL sum_res       : std_logic_vector(31 downto 0) := (others => '0');
    SIGNAL Y_n           : std_logic_vector(31 downto 0) := (others => '0');
    SIGNAL fifoempty_s   : std_logic := '0';
    SIGNAL fifoempty_irq   : std_logic := '0';
    SIGNAL fifofull_s    : std_logic := '0';
    SIGNAL write_count   : integer := 0;
    SIGNAL read_count    : integer := 0;
BEGIN

    ---------------------------------------------------
    -- FIRCTL register read/write logic
    ---------------------------------------------------
    process(FIFOCLK, FIRwrt)
    begin
        if (FIRwrt = '1' AND address = x"82C") then
                FIRCTL_in <= FIRCTL;
        elsif falling_edge(FIFOCLK) then
                if FIRCTL_in(5) = '1' then
                    FIRCTL_in(5) <= '0';
                end if;
        end if;
    end process;

    -- Readback of FIRCTL register
    FIRCTL <= FIRCTL_in(7 downto 4)&fifofull_s&fifoempty_s&FIRCTL_in(1 downto 0) WHEN (FIRrd = '1' AND address = x"82C") ELSE (others => 'Z');

    FIFOIN <= x"00" & FIRIN(23 downto 0);

    ---------------------------------------------------
    -- FIFO write process
    ---------------------------------------------------
    process(FIFOCLK, FIRCTL_in(4))
    begin
        if FIRCTL_in(4) = '1' then
            w_ptr <= 0;
            write_count <= 0;
        elsif rising_edge(FIFOCLK) then
            if FIRCTL_in(5) = '1' and fifofull_s = '0' then
                SynchroFIFO(w_ptr) <= FIFOIN;
                w_ptr <= (w_ptr + 1) mod 8;
                write_count <= write_count + 1;
            end if;
        end if;
    end process;

    ---------------------------------------------------
    -- FIFO read process
    ---------------------------------------------------
    process(FIRCLK, FIRCTL_in(4), IRQ_OUT)
    	TYPE mem_v  IS ARRAY (0 TO 7) OF std_logic_vector(31 downto 0);
	variable mul_res : mem_v := (others => (others => '0'));
	variable dly	 : integer := 1;
	variable nxt	 : integer := 1;
    begin
	if FIRCTL_in(1) = '1' or IRQ_OUT = '1' then
	    FIRIFG <= '0';
	elsif falling_edge(FIRCLK) then
	    if dly > 0 then
		dly := dly - 1;
	    else
		if (FIRCTL_in(0) = '1') then
			if r_ptr > 0 then
				FIRIFG <= '1';
			else
				if  nxt = 0 then
					FIRIFG <= '1';
					nxt := 1;
				else
					nxt := nxt - 1;
				end if;
			end if;
		end if;
	    end if;
	end if;
        if FIRCTL_in(1) = '1' then
            r_ptr <= 0;
            read_count <= 0;
            X_n <= (others => (others => '0'));
            Y_n <= (others => '0');
	    mul_res := (others => (others => '0'));
	    dly     := 1;
	    nxt     := 1;
        elsif rising_edge(FIRCLK) then
	    if FIFOREN = '1' and fifoempty_s = '0' then
	        X_n(0) <= SynchroFIFO(r_ptr)(23 downto 0);
                r_ptr <= (r_ptr + 1) mod 8;
                read_count <= read_count + 1;
            end if;
            if FIRCTL_in(0) = '1' then
		if (fifoempty_s = '0') then
                        for i in 0 to 6 loop
	                    	X_n(i+1) <= X_n(i);
                	end loop;
		end if;
		mul_res(0) := std_logic_vector(ieee.numeric_std.unsigned(SynchroFIFO(r_ptr)(23 downto 0))*ieee.numeric_std.unsigned(COEF0));
		mul_res(1) := std_logic_vector(ieee.numeric_std.unsigned(X_n(0))*ieee.numeric_std.unsigned(COEF1));
		mul_res(2) := std_logic_vector(ieee.numeric_std.unsigned(X_n(1))*ieee.numeric_std.unsigned(COEF2));
		mul_res(3) := std_logic_vector(ieee.numeric_std.unsigned(X_n(2))*ieee.numeric_std.unsigned(COEF3));
		mul_res(4) := std_logic_vector(ieee.numeric_std.unsigned(X_n(3))*ieee.numeric_std.unsigned(COEF4));
		mul_res(5) := std_logic_vector(ieee.numeric_std.unsigned(X_n(4))*ieee.numeric_std.unsigned(COEF5));
		mul_res(6) := std_logic_vector(ieee.numeric_std.unsigned(X_n(5))*ieee.numeric_std.unsigned(COEF6));
		mul_res(7) := std_logic_vector(ieee.numeric_std.unsigned(X_n(6))*ieee.numeric_std.unsigned(COEF7));

		Y_n <= std_logic_vector(
			ieee.numeric_std.unsigned(mul_res(0))+ieee.numeric_std.unsigned(mul_res(1))+
			ieee.numeric_std.unsigned(mul_res(2))+ieee.numeric_std.unsigned(mul_res(3))+
			ieee.numeric_std.unsigned(mul_res(4))+ieee.numeric_std.unsigned(mul_res(5))+
			ieee.numeric_std.unsigned(mul_res(6))+ieee.numeric_std.unsigned(mul_res(7)));
	    end if;
        end if;
    end process;

    fifofull_s  <= '1' when ((write_count - read_count) = 8) else '0';
    fifoempty_s <= '1' when ((write_count - read_count) = 0) and (read_count mod 8 = 0) else '0';
    ---------------------------------------------------
    -- FIRCTL outputs
    ---------------------------------------------------
    
    process(FIRCLK, FIRCTL_in(1), FIREMPTY_IRQ)
    begin
	if FIRCTL_in(1) = '1' or FIREMPTY_IRQ = '1' then
	   fifoempty_irq <= '0';
	elsif rising_edge(FIRCLK) then
		if fifoempty_s = '1' then
			fifoempty_irq <= '1';
		else
			fifoempty_irq <= '0';
		end if;
	end if;
    end process;

    FIREMPTY_STATUS <= fifoempty_irq;
    ---------------------------------------------------
    -- Synchronizer
    ---------------------------------------------------
    EnaSynch: PulseSynch port map(
        FIFOCLK => FIFOCLK,
        FIRCLK  => FIRCLK,
        Ain     => FIRCTL_in(0),
        Dout    => FIFOREN
    );
    FIROUT <= x"00" & Y_n(31 downto 8);

END struct;
