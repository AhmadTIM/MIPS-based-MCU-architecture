onerror {resume}
add list -width 14 /mcu_tb/KEY1
add list /mcu_tb/KEY2
add list /mcu_tb/KEY3
add list /mcu_tb/DUT/CPU/ControlBus
add list /mcu_tb/DUT/CPU/AddrBus
add list /mcu_tb/DUT/CPU/DataBus
add list /mcu_tb/DUT/CPU/IR_IF
add list /mcu_tb/DUT/CPU/IR_ID
add list /mcu_tb/DUT/CPU/IR_EX
add list /mcu_tb/DUT/CPU/IR_MEM
add list /mcu_tb/DUT/CPU/IR_WB
add list /mcu_tb/DUT/CPU/EPC
add list /mcu_tb/DUT/CPU/Int_Flush_IF
add list /mcu_tb/DUT/CPU/Int_Flush_ID
add list /mcu_tb/DUT/CPU/Int_Flush_EX
add list /mcu_tb/DUT/CPU/INTA_s
add list /mcu_tb/DUT/CPU/ISR_PC_RD
add list /mcu_tb/DUT/CPU/is_Branch
add list /mcu_tb/DUT/CPU/INTR_Single
add list /mcu_tb/DUT/CPU/PC_HOLD
add list /mcu_tb/DUT/IO_system/CLK
add list /mcu_tb/DUT/IO_system/rst
add list /mcu_tb/DUT/IO_system/MemReadBus
add list /mcu_tb/DUT/IO_system/MemWriteBus
add list /mcu_tb/DUT/IO_system/HEX0
add list /mcu_tb/DUT/IO_system/HEX1
add list /mcu_tb/DUT/IO_system/HEX2
add list /mcu_tb/DUT/IO_system/HEX3
add list /mcu_tb/DUT/IO_system/HEX4
add list /mcu_tb/DUT/IO_system/HEX5
add list /mcu_tb/DUT/IO_system/LEDR
add list /mcu_tb/DUT/IO_system/SWs
add list /mcu_tb/DUT/IO_system/CS_LEDR
add list /mcu_tb/DUT/IO_system/CS_SW
add list /mcu_tb/DUT/IO_system/CS_HEX0_1
add list /mcu_tb/DUT/IO_system/CS_HEX2_3
add list /mcu_tb/DUT/IO_system/CS_HEX4_5
add list /mcu_tb/DUT/IO_system/LEDR_D_Latch
add list /mcu_tb/DUT/IO_system/HEX0_D_Latch
add list /mcu_tb/DUT/IO_system/HEX1_D_Latch
add list /mcu_tb/DUT/IO_system/HEX2_D_Latch
add list /mcu_tb/DUT/IO_system/HEX3_D_Latch
add list /mcu_tb/DUT/IO_system/HEX4_D_Latch
add list /mcu_tb/DUT/IO_system/HEX5_D_Latch
add list /mcu_tb/DUT/Intr_Controller/IntSrc
add list /mcu_tb/DUT/Intr_Controller/INTR
add list /mcu_tb/DUT/Intr_Controller/INTA
add list /mcu_tb/DUT/Intr_Controller/IRQ_OUT
add list /mcu_tb/DUT/Intr_Controller/INTR_Active
add list /mcu_tb/DUT/Intr_Controller/GIE
add list /mcu_tb/DUT/Intr_Controller/IRQ
add list /mcu_tb/DUT/Intr_Controller/TypeReg
add list /mcu_tb/DUT/Intr_Controller/INTA_Delayed
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta collapse
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
