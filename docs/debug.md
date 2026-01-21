# Waterfoul Debugger

The Waterfoul debugger allows you to execute Game Boy CPU instructions step-by-step and inspect the CPU state, flags, and memory after each instruction.

## Usage

```bash
waterfoul debug [options]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--hex HEX` | Hex bytes to execute (space-separated) | - |
| `--file FILE` | Binary file containing instructions | - |
| `--memory RANGE` | Memory range to display (e.g., `C000-C0FF`) | - |
| `--pc ADDRESS` | Starting program counter address | `0` |
| `--sp ADDRESS` | Starting stack pointer address | `0xFFFE` |

## Input Formats

### Hex String

Provide instructions as space-separated hex bytes:

```bash
waterfoul debug --hex "3E 42 06 10 80 76"
```

### Binary File

Load instructions from a binary file:

```bash
waterfoul debug --file program.bin
```

## Output Format

After each instruction, the debugger displays:

```
Step 1: LD A, $42  (0x3E 0x42)
──────────────────────────────────────────────────
Registers:
  A: 42   B: 00   C: 00   D: 00   E: 00   H: 00   L: 00   F: 00
  AF: 4200   BC: 0000   DE: 0000   HL: 0000
  SP: FFFE   PC: 0002

Flags: Z:0 N:0 H:0 C:0    Cycles: 8

Memory Changes: (none)
```

### Output Sections

- **Step Header**: Step number, disassembled instruction mnemonic, and raw bytes
- **Registers**: All 8-bit registers (A, B, C, D, E, H, L, F) and 16-bit pairs (AF, BC, DE, HL, SP, PC)
- **Flags**: Zero (Z), Subtract (N), Half-Carry (H), and Carry (C) flags
- **Cycles**: Number of CPU cycles consumed by the instruction
- **Memory Changes**: Any memory locations modified by the instruction

## Examples

### Basic Arithmetic

Load values into registers and add them:

```bash
waterfoul debug --hex "3E 42 06 10 80 76"
```

This executes:
1. `LD A, $42` - Load 0x42 into register A
2. `LD B, $10` - Load 0x10 into register B
3. `ADD A, B` - Add B to A (result: 0x52)
4. `HALT` - Stop execution

### Flag Changes

Demonstrate overflow and flag behavior:

```bash
waterfoul debug --hex "3E FF C6 01 76"
```

This executes:
1. `LD A, $FF` - Load 0xFF into A
2. `ADD A, $01` - Add 1 to A (overflows to 0x00)
3. `HALT` - Stop execution

After step 2, flags will show: `Z:1 N:0 H:1 C:1`
- Z=1: Result is zero
- H=1: Half-carry occurred (lower nibble overflow)
- C=1: Carry occurred (full byte overflow)

### Memory Operations

Write to memory and display a memory range:

```bash
waterfoul debug --hex "21 00 C0 36 42 76" --memory C000-C00F
```

This executes:
1. `LD HL, $C000` - Load address 0xC000 into HL
2. `LD (HL), $42` - Write 0x42 to memory at address HL
3. `HALT` - Stop execution

The memory display shows:
```
Memory [$C000 - $C00F]:
  C000: 42 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  B...............
```

### CB-Prefixed Instructions

Test bit manipulation instructions:

```bash
waterfoul debug --hex "3E 0F CB 37 76"
```

This executes:
1. `LD A, $0F` - Load 0x0F into A
2. `SWAP A` - Swap upper and lower nibbles (result: 0xF0)
3. `HALT` - Stop execution

### Custom Start Address

Start execution at a specific address (useful for testing code meant to run at 0x100):

```bash
waterfoul debug --hex "3E 42 76" --pc 0x100
```

## Supported Instructions

The debugger supports all Game Boy CPU instructions:

- **Load instructions**: LD, LDH, PUSH, POP
- **Arithmetic**: ADD, ADC, SUB, SBC, INC, DEC
- **Logic**: AND, OR, XOR, CP, CPL
- **Bit operations**: BIT, SET, RES (CB-prefixed)
- **Shifts/Rotates**: RLC, RRC, RL, RR, SLA, SRA, SRL, SWAP (CB-prefixed)
- **Jumps**: JP, JR, CALL, RET, RETI, RST
- **Misc**: NOP, HALT, STOP, DI, EI, DAA, SCF, CCF

## Termination

The debugger stops execution when it encounters:

- `HALT` instruction (0x76)
- `STOP` instruction (0x10)
- End of program (PC reaches beyond loaded bytes)

## Architecture

The debugger consists of three main components:

| File | Description |
|------|-------------|
| `lib/waterfoul/debugger.rb` | Main debugger class - manages CPU/MMU setup and step execution |
| `lib/waterfoul/debugger/disassembler.rb` | Decodes opcodes to human-readable mnemonics |
| `lib/waterfoul/debugger/state_printer.rb` | Formats and displays CPU state and memory |

## Memory Regions

The Game Boy memory map affects what addresses you can use:

| Range | Region | Notes |
|-------|--------|-------|
| `0000-7FFF` | ROM | Program code is loaded here |
| `8000-9FFF` | Video RAM | Tile data and maps |
| `A000-BFFF` | External RAM | Cartridge RAM |
| `C000-DFFF` | Work RAM | General purpose RAM |
| `FE00-FE9F` | OAM | Sprite attributes |
| `FF00-FF7F` | I/O Registers | Hardware control |
| `FF80-FFFE` | High RAM | Fast RAM area |
| `FFFF` | IE Register | Interrupt enable |

For memory write tests, use Work RAM (`C000-DFFF`) or High RAM (`FF80-FFFE`).
