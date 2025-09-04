aux_package - package file that contains the components.

BasicTimer - contains the Basic Timer component which has a register counter, IFG and PWM output.

cond_comilation_package - contains constant values that differentiate between MODELSIM and QUARTUS.

const_package - contains constant values that equals to the corresponding Opcodes values of the instructions.

CONTROL - the unit that chooses which control signals to turn on.

DMEMORY - the unit that contains the data memory of the cpu.

EXECUTE - the unit that contains the ALU and the unit that chooses which operation that the ALU should preform.

FIR - contains the file for the FIR Filter HW accelerator component.

PulseSynch - is Pulse synchronizer between to clocks of different frequencies.

FarwardingUnit - This VHDL code implements a forwarding unit that detects and resolves data hazards in a pipelined MIPS processor by selecting the correct forwarding paths for ALU and branch operands from later pipeline stages.

GPIO - connects between the LEDs, HEXs and SWs and the MCU.

HazardUnit - This VHDL code defines a Hazard Detection Unit for a MIPS pipeline that detects load-use and branch hazards and asserts stall and flush signals to manage pipeline control.

IDecode - contains the register file, and calculates the jump and branch address to pass them to IFetch

IFetch - responsible to fetch the next instruction, whether it is PC+4 or instruction that was jumped (or branched) to.

Int_Cont - contains the code for the Interrupt Controller.

MCU - contains the overall system, which contains MIPS cpu, Interrupt Controller, GPIO, UART, Basic Timer and FIR.

MIPS - the top level system that connects all the units together.

PLL_sub - switches the 50MHz clock to a more suitable clock in MHZ.

PLL_FIR + Counter_Env - switches the 50MHz clock to a more suitable clock in KHZ for FIR.

SevenSegDecoder - translates the inputed number for printing on HEX ports.

UART_TX - contains the component which transmits data to the connected device.

UART_RX - contains the component which receives data from the connected device.

UART - connects between UART_TX and UART_RX.

WriteBack - this unit is responsible for writing back to the register file and chooses if the memory value or the ALU result to pass to the RF.
