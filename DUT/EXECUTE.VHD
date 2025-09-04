---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
--  Execute module (implements the data ALU and Branch Address Adder  
--  for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.aux_package.all;


ENTITY  Execute IS
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
END Execute;


ARCHITECTURE behavior OF Execute IS
SIGNAL a_input_w, b_input_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
SIGNAL alu_out_mux_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
SIGNAL forwardA_mux, forwardB_mux : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
SIGNAL alu_ctl_w		: STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL shamt_i			: STD_LOGIC_VECTOR(4 downto 0);
BEGIN
------------ Forwarding ----------------
	-- Forward A
	WITH ForwardA SELECT 
		forwardA_mux <= read_data1_i   WHEN "00",
				WrDataFW_WB    WHEN "01",
				WrDataFW_MEM   WHEN "10",
				X"00000000"    WHEN OTHERS;
	-- Forward B
	WITH ForwardB SELECT 
		forwardB_mux <= read_data2_i   WHEN "00",
				WrDataFW_WB    WHEN "01",
				WrDataFW_MEM   WHEN "10",
				X"00000000"    WHEN OTHERS;

	-- ALU B input mux after forwarding
	a_input_w <= forwardA_mux;
	-- ALU B input mux after forwarding
	b_input_w <= forwardB_mux WHEN ( ALUSrc_ctrl_i = '0' ) ELSE
		  Sign_extend_i(DATA_BUS_WIDTH-1 DOWNTO 0);		
	WriteData_EX <= forwardB_mux;
	shamt_i <= sign_extend_i(10 downto 6);
				
--------------------------------------------------------------------------------------------------------
--  Generate ALU control bits
--------------------------------------------------------------------------------------------------------
PROCESS (ALUOp_ctrl_i, funct_i)
begin
    case ALUop_ctrl_i is
        when "0000" =>  -- lw, sw, addi, addiu
            alu_ctl_w <= "0010"; -- ADD

        when "0001" =>  -- beq, bne
            alu_ctl_w <= "0110"; -- SUB

        when "0010" =>  -- andi
            alu_ctl_w <= "0000"; -- AND

        when "0011" =>  -- ori
            alu_ctl_w <= "0001"; -- OR

        when "0100" =>  -- xori
            alu_ctl_w <= "0011"; -- XOR

        when "0101" =>  -- slti
            alu_ctl_w <= "0111"; -- SLT

        when "1110" =>  -- mul
            alu_ctl_w <= "1010"; -- MUL

        when "0110" =>  -- lui
            alu_ctl_w <= "1100"; -- LUI

        when "0111" =>  -- R-type (opcode 000000)
            case funct_i is
                when "100000" => alu_ctl_w <= "0010"; -- add
                when "100010" => alu_ctl_w <= "0110"; -- sub
                when "100100" => alu_ctl_w <= "0000"; -- and
                when "100101" => alu_ctl_w <= "0001"; -- or
                when "100110" => alu_ctl_w <= "0011"; -- xor
                when "101010" => alu_ctl_w <= "0111"; -- slt
                when "000000" => alu_ctl_w <= "1000"; -- sll
                when "000010" => alu_ctl_w <= "1001"; -- srl
                when others   => alu_ctl_w <= "1111"; -- undefined
            end case;

        when others =>
            alu_ctl_w <= "1111"; -- undefined
    end case;
end process;
-------------------------------------------------------------------------------------------------------
	WrRegAddr   <=  "11111"		WHEN RegDst_ctrl_i = "10" ELSE -- jal
			WrRegAddr1 	WHEN RegDst_ctrl_i = "01" ELSE 
			WrRegAddr0;
	-- Generate Zero Flag
	zero_o <= 	'1' WHEN alu_out_mux_w(DATA_BUS_WIDTH-1 DOWNTO 0) = X"00000000" ELSE
			'0';    
	-- Select ALU output        
	alu_res_o <= 	X"0000000" & B"000"  & alu_out_mux_w(31) WHEN  alu_ctl_w = "0111" ELSE 
			alu_out_mux_w(DATA_BUS_WIDTH-1 DOWNTO 0);
					
-------------------------------------------------------------------------------------------------------
	PROCESS ( alu_ctl_w, a_input_w, b_input_w )
	    BEGIN
	    --------------- Select ALU operation ---------------------
	    CASE alu_ctl_w IS
	        -- ALU performs ALUresult = a_input_w AND b_input_w
	        WHEN "0000"     =>    alu_out_mux_w     <= a_input_w AND b_input_w; 
	        -- ALU performs ALUresult = a_input_w OR b_input_w
	        WHEN "0001"     =>    alu_out_mux_w     <= a_input_w OR b_input_w;
	        -- ALU performs ALUresult = a_input_w + b_input_w
	        WHEN "0010"     =>    alu_out_mux_w     <= a_input_w + b_input_w; 
	        -- ALU performs ALUresult = a_input_w * b_input_w
	        WHEN "1010"     =>    alu_out_mux_w <= std_logic_vector(ieee.numeric_std.unsigned(a_input_w(15 downto 0))*ieee.numeric_std.unsigned(b_input_w(15 downto 0)));
	        -- ALU performs ALUresult = a_input_w XOR b_input_w
	        WHEN "0011"     =>    alu_out_mux_w     <= a_input_w XOR b_input_w;
	        -- ALU performs ALUresult = a_input_w SLL b_input_w
	        WHEN "1000"     =>    alu_out_mux_w     <=    std_logic_vector(ieee.numeric_std.shift_left(ieee.numeric_std.unsigned(b_input_w),ieee.numeric_std.to_integer(ieee.numeric_std.unsigned(shamt_i))));
	        -- ALU performs ALUresult = a_input_w SRL b_input_w
	        WHEN "1001"     =>    alu_out_mux_w     <=    std_logic_vector(ieee.numeric_std.shift_right(ieee.numeric_std.unsigned(b_input_w),ieee.numeric_std.to_integer(ieee.numeric_std.unsigned(shamt_i))));
		-- ALU performs ALUresult = a_input_w -b_input_w
	        WHEN "0110"     =>    alu_out_mux_w     <= a_input_w - b_input_w;
        	-- ALU performs SLT
        	WHEN "0111"     =>    alu_out_mux_w     <= a_input_w - b_input_w; 
	        -- ALU performs LUI
	        WHEN "1100"     =>    alu_out_mux_w     <= b_input_w(15 DOWNTO 0) & "0000000000000000";
	        -- OUTPUT ZERO
	        WHEN OTHERS     =>    alu_out_mux_w     <= X"00000000" ;
	    END CASE;
	END PROCESS;
  
END behavior;

