LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE work.aux_package.ALL;

ENTITY GPIO IS
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
END GPIO;

ARCHITECTURE struct OF GPIO IS
    SIGNAL CS_LEDR, CS_SW         : STD_LOGIC;
    SIGNAL CS_HEX0_1              : STD_LOGIC;
    SIGNAL CS_HEX2_3              : STD_LOGIC;
    SIGNAL CS_HEX4_5              : STD_LOGIC;
    SIGNAL LEDR_D_Latch           : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    SIGNAL HEX0_D_Latch           : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    SIGNAL HEX1_D_Latch           : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    SIGNAL HEX2_D_Latch           : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    SIGNAL HEX3_D_Latch           : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    SIGNAL HEX4_D_Latch           : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    SIGNAL HEX5_D_Latch           : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');

BEGIN
    -----------------------------------------------------------------
    -- Optimized Address Decoder
    -----------------------------------------------------------------
    CS_LEDR   <= '0' WHEN rst = '1' ELSE
                 '1' WHEN AddrBus(11 DOWNTO 0) = X"800" ELSE '0';
    CS_HEX0_1 <= '0' WHEN rst = '1' ELSE 
                 '1' WHEN (AddrBus(11 DOWNTO 0) = X"804" or AddrBus(11 DOWNTO 0) = X"805") ELSE '0';
    CS_HEX2_3 <= '0' WHEN rst = '1' ELSE 
                 '1' WHEN (AddrBus(11 DOWNTO 0) = X"808" or AddrBus(11 DOWNTO 0) = X"809") ELSE '0';
    CS_HEX4_5 <= '0' WHEN rst = '1' ELSE 
                 '1' WHEN (AddrBus(11 DOWNTO 0) = X"80C" or AddrBus(11 DOWNTO 0) = X"80D") ELSE '0';
    CS_SW     <= '0' WHEN rst = '1' ELSE 
                 '1' WHEN AddrBus(11 DOWNTO 0) = X"810" ELSE '0';

    -----------------------------------------------------------------
    -- GPO
    -----------------------------------------------------------------
    PROCESS(CLK, rst)
    BEGIN
        IF rst = '1' THEN
            LEDR_D_Latch <= (others => '0');
            HEX0_D_Latch <= (others => '0');
            HEX1_D_Latch <= (others => '0');
            HEX2_D_Latch <= (others => '0');
            HEX3_D_Latch <= (others => '0');
            HEX4_D_Latch <= (others => '0');
            HEX5_D_Latch <= (others => '0');
        ELSIF falling_edge(CLK) THEN
            IF MemWriteBus = '1' THEN
                IF  CS_LEDR = '1'                            THEN LEDR_D_Latch <= DataBus(7 DOWNTO 0); END IF;
                IF (CS_HEX0_1 = '1' and AddrBus(0) = '0')    THEN HEX0_D_Latch <= DataBus(7 DOWNTO 0); END IF;
                IF (CS_HEX0_1 = '1' and AddrBus(0) = '1')    THEN HEX1_D_Latch <= DataBus(7 DOWNTO 0); END IF;
                IF (CS_HEX2_3 = '1' and AddrBus(0) = '0')    THEN HEX2_D_Latch <= DataBus(7 DOWNTO 0); END IF;
                IF (CS_HEX2_3 = '1' and AddrBus(0) = '1')    THEN HEX3_D_Latch <= DataBus(7 DOWNTO 0); END IF;
                IF (CS_HEX4_5 = '1' and AddrBus(0) = '0')    THEN HEX4_D_Latch <= DataBus(7 DOWNTO 0); END IF;
                IF (CS_HEX4_5 = '1' and AddrBus(0) = '1')    THEN HEX5_D_Latch <= DataBus(7 DOWNTO 0); END IF;
            END IF;
        END IF;
    END PROCESS;

    -----------------------------------------------------------------
    -- GPI
    -----------------------------------------------------------------
    DataBus <= X"000000" & SWs           WHEN (MemReadBus = '1' AND CS_SW = '1') ELSE
               X"000000" & LEDR_D_Latch  WHEN (MemReadBus = '1' AND CS_LEDR = '1') ELSE
               X"000000" & HEX0_D_Latch  WHEN (MemReadBus = '1' AND CS_HEX0_1 = '1' and AddrBus(0) = '0') ELSE
               X"000000" & HEX1_D_Latch  WHEN (MemReadBus = '1' AND CS_HEX0_1 = '1' and AddrBus(0) = '1') ELSE
               X"000000" & HEX2_D_Latch  WHEN (MemReadBus = '1' AND CS_HEX2_3 = '1' and AddrBus(0) = '0') ELSE
               X"000000" & HEX3_D_Latch  WHEN (MemReadBus = '1' AND CS_HEX2_3 = '1' and AddrBus(0) = '1') ELSE
               X"000000" & HEX4_D_Latch  WHEN (MemReadBus = '1' AND CS_HEX4_5 = '1' and AddrBus(0) = '0') ELSE
               X"000000" & HEX5_D_Latch  WHEN (MemReadBus = '1' AND CS_HEX4_5 = '1' and AddrBus(0) = '1') ELSE
               (others => 'Z');

    -----------------------------------------------------------------
    -- HEX decoder
    -----------------------------------------------------------------
    LEDR <= LEDR_D_Latch;
    DecoderModuleXHex0: SevenSegDecoder port map(HEX0_D_Latch(3 DOWNTO 0), HEX0);
    DecoderModuleXHex1: SevenSegDecoder port map(HEX1_D_Latch(3 DOWNTO 0), HEX1);
    DecoderModuleXHex2: SevenSegDecoder port map(HEX2_D_Latch(3 DOWNTO 0), HEX2);
    DecoderModuleXHex3: SevenSegDecoder port map(HEX3_D_Latch(3 DOWNTO 0), HEX3);
    DecoderModuleXHex4: SevenSegDecoder port map(HEX4_D_Latch(3 DOWNTO 0), HEX4);
    DecoderModuleXHex5: SevenSegDecoder port map(HEX5_D_Latch(3 DOWNTO 0), HEX5);

END struct;

