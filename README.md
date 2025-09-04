# Pipelined MIPS Based MCU Architecture – VHDL Implementation

## Introduction
This repository features a 5-stage pipelined MIPS CPU implemented in VHDL, designed for the Altera DE10 FPGA platform. The system integrates core MIPS functionalities along with GPIO, a basic timer, FIR filter hardware accelerator, an interrupt controller, and UART communication, providing a complete microcontroller environment on the FPGA.  

## Contents
1. [Project Objective and System Overview](#project-objective-and-system-overview)  
2. [Verification and Testing](#verification-and-testing)  
3. [GPIO Module](#gpio-module)  
4. [Interrupt Handling](#interrupt-handling)  
5. [Basic Timer](#basic-timer)  
6. [FIR Filter HW-Accelerator](#fir-filter-hw-accelerator)  
7. [UART Interface](#uart-interface)  

## Project Objective and System Overview
The goal of this project was to implement a MIPS-based CPU capable of handling memory-mapped peripherals, processing external interrupts, and executing interrupt service routines (ISRs). Hazard detection and forwarding units resolve data dependencies, ensuring smooth pipelined operation on the FPGA.  

### System Architecture
The CPU consists of multiple interconnected modules working together in a pipelined configuration. Each module is encapsulated within the top-level microcontroller design, making the system modular and easier to debug.  

## Verification and Testing
Functional verification was performed using assembly programs covering arithmetic operations, memory access, and peripheral interactions. Simulations were conducted using ModelSim and FPGA-specific debugging tools to ensure correct CPU operation.  

## GPIO Module
The General-Purpose Input/Output (GPIO) module allows the CPU to interface with external devices such as LEDs and switches. It supports both input and output, enabling versatile hardware interaction.  

## Interrupt Handling
The interrupt controller manages external interrupts, prioritizes events, and triggers the appropriate ISRs. This ensures real-time responsiveness while maintaining smooth pipeline operation.  

## Basic Timer
The hardware timer module provides precise timing for the CPU. It supports periodic interrupts, PWM signal generation, and scheduling of recurring tasks.  

## FIR Filter HW-Accelerator
A dedicated module for fast digital filtering. It uses an 8-word FIFO and dual clocks to apply configurable coefficients to incoming data, producing filtered outputs for signal processing tasks.  

## UART Interface
The UART module enables serial communication between the CPU and external devices such as PCs or sensors, essential for debugging and real-time data exchange.  

## FPGA Configuration
Project files include pin assignments and constraints for proper operation on the Altera DE10 board, ensuring correct mapping of CPU signals and peripheral connections.  

## Project Components
The system is composed of several functional blocks:  

- **Top-Level Integration** – Connects all modules and manages overall CPU operation.  
- **CPU Core** – Implements the pipelined MIPS processor with fetch, decode, execute, memory access, and write-back stages.  
- **Control Unit** – Directs instruction flow and manages pipeline control.  
- **Data Hazard Management** – Detects and resolves dependencies using forwarding and hazard detection logic.  
- **Memory Interfaces** – Provide access to instruction and data memory.  
- **GPIO Interface** – Supports digital input/output operations with peripherals.  
- **Timer Module** – Provides precise timing for tasks and interrupts.  
- **FIR Filter Module** – Performs fast digital filtering.  
- **Interrupt Controller** – Handles external interrupts and ISR execution.  
- **UART Communication** – Enables serial data transfer.  
- **Utility Modules** – Support data conversion, peripheral interfacing, and general CPU functionality.  

## Supplementary Materials
- Simulation waveforms and logs demonstrating CPU operation  
- Test programs showcasing pipeline and peripheral functionality  

## Reference
For detailed explanations of module functionality and internal processes, consult the provided PDF:  
[MIPS-based-MCU-architecture.pdf](https://github.com/AhmadTIM/MIPS-based-MCU-architecture/blob/main/DOC/MIPS-based-MCU-architecture.pdf)
