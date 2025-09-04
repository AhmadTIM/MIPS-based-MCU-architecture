#--------------------------------------------------------------
#		    		MEMORY Mapped I/O addresses
#--------------------------------------------------------------
#define PORT_LEDR[7-0] 	0x800 - LSB byte address (Output Mode)
.eqv PORT_LEDR 0x800     # Define a constant named PORT_LEDR
#------------------- PORT_HEX0_HEX1 ---------------------------
#define PORT_HEX0[7-0] 	0x804 - LSB byte address (Output Mode)
#define PORT_HEX1[7-0] 	0x805 - LSB byte address (Output Mode)
.eqv PORT_HEX0 0x804     # Define a constant named PORT_HEX0
.eqv PORT_HEX1 0x805     # Define a constant named PORT_HEX1
#------------------- PORT_HEX2_HEX3 ---------------------------
#define PORT_HEX2[7-0] 	0x808 - LSB byte address (Output Mode)
#define PORT_HEX3[7-0] 	0x809 - LSB byte address (Output Mode)
.eqv PORT_HEX2 0x808     	# Define a constant named PORT_HEX2
.eqv PORT_HEX3 0x809     	# Define a constant named PORT_HEX3
#------------------- PORT_HEX4_HEX5 ---------------------------
#define PORT_HEX4[7-0] 	0x80C - LSB byte address (Output Mode)
#define PORT_HEX5[7-0] 	0x80D - LSB byte address (Output Mode)
.eqv PORT_HEX4 0x80C		# Define a constant named PORT_HEX4
.eqv PORT_HEX5 0x80D     	# Define a constant named PORT_HEX5
#--------------------------------------------------------------
#define PORT_SW[7-0] 	0x810 - LSB byte address (Input Mode)
.eqv PORT_SW 0x810			# Define a constant named PORT_SW
#--------------------------------------------------------------
#define PORT_KEY[3-1]  	0x814 - LSB nibble address (3 push-buttons - Input Mode)
.eqv PORT_KEY 0x814			# Define a constant named PORT_KEY
#--------------------------------------------------------------
#define UTCL           	0x818 - Byte address 
#define RXBF           	0x819 - Byte address 
#define TXBF           	0x81A - Byte address 
.eqv UTCL 0x818			# Define a constant named UTCL
.eqv RXBF 0x819			# Define a constant named RXBF
.eqv TXBF 0x81A			# Define a constant named TXBF
#--------------------------------------------------------------
#define BTCTL          	0x81C - LSB byte address 
#define BTCNT          	0x820 - Word address 
#define BTCCR0         	0x824 - Word address 
#define BTCCR1         	0x828 - Word address 
.eqv BTCTL 0x81C			# Define a constant named BTCTL
.eqv BTCNT 0x820			# Define a constant named BTCNT
.eqv BTCCR0 0x824			# Define a constant named BTCCR0
.eqv BTCCR1 0x828			# Define a constant named BTCCR1
#--------------------------------------------------------------
#define FIRCTL       	0x82C - Word address 
#define FIRIN        	0x830 - Word address 
#define FIROUT       	0x834 - Word address 
#define COEF3_0      	0x838 - Word address 
#define COEF7_4      	0x83C - Word address 
.eqv FIRCTL 0x82C			# Define a constant named FIRCTL
.eqv FIRIN 0x830			# Define a constant named FIRIN
.eqv FIROUT 0x834			# Define a constant named FIROUT
.eqv COEF3_0 0x838			# Define a constant named COEF3_0
.eqv COEF7_4 0x83C			# Define a constant named COEF7_4
#--------------------------------------------------------------
#define IE             	0x840 - LSB byte address 
#define IFG            	0x841 - LSB byte address 
#define TYPE           	0x842 - LSB byte address 
.eqv IE 0x840			# Define a constant named IE
.eqv IFG 0x841			# Define a constant named IFG
.eqv TYPE 0x842			# Define a constant named TYPE
#---------------------- Data Segment --------------------------
.data 
	IV: 	.word main            # Start of Interrupt Vector Table
		.word UartRX_ISR
		.word UartRX_ISR
		.word UartTX_ISR
	        .word BT_ISR
		.word KEY1_ISR
		.word KEY2_ISR
		.word KEY3_ISR
		.word FIR_ISR
		.word FIR_ISR
		
	msg:	.word 0x49 0x20 0x6C 0x6F 0x76 0x65 0x20 0x6D 0x79 0x20 0x4E 0x65 0x67 0x65 0x76 0x0A
	#  	      'I'       'l'  'o'  'v'  'e'       'm'  'y'       'N'  'e'  'g'  'e'  'v' '\n'		
#---------------------- Code Segment --------------------------	
.text
main:	addi $sp,$0,0x800 # $sp=0x800
	addi $s0,$0,0     # clear option 4 pressed flag
	addi $s1,$0, 0    # counting up/down flag
	
	addi $t5, $0, 0
	addi $t6, $0, 0
	addi $t7, $0, 0
	
	addi $t0,$0,0x21  
	sw   $t0,BTCTL    # BTCTL=0x26(BTIP=6, BTSSEL=0, BTHOLD=1)
	sw   $zero,BTCNT  # BTCNT=0
	addi $t0,$0,0x3B   
	sw   $t0,IE       # IE=0x3B (BTIE is disabled, all others enabled)
	sw   $zero,IFG    # IFG=0
	addi $t0,$0,0x09  
	sw   $t0,BTCTL    #  BTCTL=0x0E (BTIP=6, BTSSEL=1, BTHOLD=0 - 50MHz/2^25)
	addi $t0,$0,0x09
	sw   $t0,UTCL     # UTCL=0x09 (SWRST=1,115200 BR)
	addi $t0,$0,0x08
	sw   $t0,UTCL     # UTCL=0x08 (SWRST=0,115200 BR)
	ori  $k0,$k0,0x01 # EINT, $k0[0]=1 uses as GIE

L:	j    L		    # infinite loop

ClrLEDs: 	# get '1' from PC
	addi $t0,$0,0x3B  	# BTIE is disabled
	sw   $t0,IE       
	sw   $0, PORT_LEDR
	jr   $k1
	
CntUp:	 # get '2' from PC
	addi $t2, $0, 0		# init timer
	addi $s1, $0, 0		# 0 when count up (1 when down)
	addi $t0,$0,0x3F  	# BTIE is enabled
	sw   $t0,IE
	jr   $k1
	
CntDown:	# get '3' from PC
	addi $t2, $0, 0xFF	# init timer
	addi $s1, $0, 1		# 1 when count down (0 when up)
	addi $t0,$0,0x3F  	# BTIE is enabled
	sw   $t0,IE 
	jr   $k1

Transmit_Msg:	# get '4' from PC
	addi $t0,$0,0x3B  	# BTIE is disabled
	sw   $t0,IE
	addi $s0, $0, 1		# 1 when send msg (0 when inside funcs)	
	jr   $k1

KEY1_ISR: 
	lw   $t0,IFG # read IFG
	andi $t0,$t0,0xFFF7 
	sw   $t0,IFG # clr KEY1IFG
	beq  $s0, $0, Exit_ISR
	addi $t3,$0,0  		# index = 0
	la   $t4, msg		# get pointer
	lw   $t0, 0($t4)	
	sw   $t0,TXBF 		# write to trig TxIntr
Exit_ISR:
	jr   $k1
	
KEY2_ISR:
	lw   $t0,IFG # read IFG
	andi $t0,$t0,0xFFEF 
	sw   $t0,IFG # clr KEY1IFG
	jr   $k1

KEY3_ISR:
	lw   $t0,IFG # read IFG
	andi $t0,$t0,0xFFDF 
	sw   $t0,IFG # clr KEY1IFG
	jr   $k1

BT_ISR:
	bne  $s1, $0, BT_down
	addi $t2, $t2, 1
	j    SetLEDs
BT_down:addi $t2, $t2, -1
SetLEDs:sw   $t2,PORT_LEDR
	jr   $k1

FIR_ISR:	
	jr   $k1

UartRX_ISR:
	addi $s0, $0, 0
	lw   $t0, RXBF
	addi $t1, $0, 0x31
	beq  $t0, $t1, ClrLEDs
	addi $t1, $0, 0x32
	beq  $t0, $t1, CntUp
	addi $t1, $0, 0x33
	beq  $t0, $t1, CntDown
	addi $t1, $0, 0x34
	beq  $t0, $t1, Transmit_Msg
	jr   $k1

UartTX_ISR:
	addi $t3, $t3, 1
	addi $t4, $t4, 4
	slti $t0, $t3, 16
	beq  $t0, $0, Exit_ISR2
	lw   $t0, 0($t4)
	sw   $t0, TXBF
Exit_ISR2:
	jr   $k1
