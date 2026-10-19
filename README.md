# SystemVerilog FPGA 16-bit CPU

## Overview

A simple 16-bit processor implemented in SystemVerilog. It executes a program from `program.txt` one instruction per slow tick and shows the result of the last instruction in hexadecimal on a four-digit multiplexed seven-segment display. Execution can be paused and resumed with push buttons.

## Features

- 16-bit CPU, 8 registers (`R0` hardwired to zero), 256-word program memory
- Arithmetic, logic, shift, `MOVI`, `JMP`, `JZ`, `JNZ`, and `HALT` instructions
- Pause and resume buttons, active-low reset
- Button synchronization and debouncing
- Hexadecimal display with leading zero suppression
- Configurable timing parameters

## Hardware

Designed for an FPGA board with a 10 MHz clock, three push buttons, and four seven-segment displays.

| Signal | Description |
|---|---|
| `clk` | 10 MHz clock input |
| `KEY[0]` | Active-low reset |
| `KEY[1]` | Resume button |
| `KEY[2]` | Pause button |
| `SEGMENTS[7:0]` | Seven-segment control signals |
| `DS[3:0]` | Display digit selection |

## Parameters

| Parameter | Description |
|---|---|
| `CLK_HZ` | Clock cycles between CPU ticks (`10_000_000` = one instruction per second at 10 MHz) |
| `DISPLAY_REFRESH_COUNT` | Clock cycles between display digit switches |
| `DEBOUNCE_COUNT` | Clock cycles a button level must be stable to be accepted |

## Operation

- `KEY[0]` resets the CPU and restarts the program from address 0.
- `KEY[2]` pauses execution, `KEY[1]` resumes it.
- The CPU runs automatically after reset and stops at `HALT` until the next reset.
- The display shows the last value written to a register other than `R0` (negative values in two's complement).

## Instruction Set

16-bit instruction: `[15:12]` opcode, `[11:9]` rd, `[8:6]` rs1, `[5:3]` rs2. `MOVI` uses `[8:0]` as a sign-extended immediate; jumps use `[7:0]` as the target address and `JZ`/`JNZ` test `rd`.

| Opcode | Instruction | Opcode | Instruction |
|---|---|---|---|
| `0x0` | `ADD` | `0x7` | `SHR` |
| `0x1` | `SUB` | `0x8` | `INC` |
| `0x2` | `AND` | `0x9` | `DEC` |
| `0x3` | `OR` | `0xA` | `SAR` (arithmetic shift right) |
| `0x4` | `MOVI` | `0xB` | `JMP` |
| `0x5` | `NOT` | `0xC` | `JZ` |
| `0x6` | `SHL` | `0xD` | `JNZ` |
| | | `0xF` | `HALT` |

## Program

`program.txt` holds one 16-bit hex word per line; text after `//` is a comment. The included demo program covers all instruction groups and ends with `HALT` at address 29. It is loaded in `cpu.sv` with `$readmemh("../program.txt", ...)`, so the path is relative to the directory the tool is run from (e.g. `rtl/` or `tb/`).

## Project Structure

```text
.
├── program.txt
├── rtl
│   ├── alu.sv
│   ├── button_debouncer.sv
│   ├── clock_divider.sv
│   ├── control_unit.sv
│   ├── cpu.sv
│   ├── register_file.sv
│   └── top.sv
└── tb
    └── top_tb.sv
```

- `rtl/` — Design sources: top level (buttons, pause logic, display), CPU, control unit, ALU, register file, clock divider, and debouncer.
- `tb/top_tb.sv` — Self-checking testbench with shortened timing: tests pause/resume, reset, full program run, final register values, and display multiplexing. Prints `ALL TESTS PASSED` on success.
- `program.txt` — Program loaded into the CPU.
