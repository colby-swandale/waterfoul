module Waterfoul
  class Debugger
    class Disassembler
      # Instruction lengths: 1, 2, or 3 bytes
      # Based on operand types: d8/r8 = 2 bytes, d16/a16 = 3 bytes
      INSTRUCTION_LENGTHS = {
        # 1-byte instructions (most are 1 byte by default)
        # 3-byte instructions (d16/a16)
        0x01 => 3, 0x11 => 3, 0x21 => 3, 0x31 => 3,  # LD rr, d16
        0x08 => 3,  # LD (a16), SP
        0xC2 => 3, 0xC3 => 3, 0xCA => 3, 0xD2 => 3, 0xDA => 3,  # JP a16
        0xC4 => 3, 0xCC => 3, 0xCD => 3, 0xD4 => 3, 0xDC => 3,  # CALL a16
        0xEA => 3,  # LD (a16), A
        0xFA => 3,  # LD A, (a16)
        # 2-byte instructions (d8/r8/a8)
        0x06 => 2, 0x0E => 2, 0x16 => 2, 0x1E => 2, 0x26 => 2, 0x2E => 2, 0x36 => 2, 0x3E => 2,  # LD r, d8
        0xC6 => 2, 0xCE => 2, 0xD6 => 2, 0xDE => 2, 0xE6 => 2, 0xEE => 2, 0xF6 => 2, 0xFE => 2,  # ALU d8
        0x18 => 2, 0x20 => 2, 0x28 => 2, 0x30 => 2, 0x38 => 2,  # JR r8
        0xE0 => 2, 0xF0 => 2,  # LDH
        0xE8 => 2, 0xF8 => 2,  # ADD SP, r8 / LD HL, SP+r8
        0xCB => 2,  # CB prefix
      }.freeze

      # Opcode mnemonics mapping
      MNEMONICS = {
        # 0x00
        0x00 => 'NOP', 0x01 => 'LD BC, $%04X', 0x02 => 'LD (BC), A', 0x03 => 'INC BC',
        0x04 => 'INC B', 0x05 => 'DEC B', 0x06 => 'LD B, $%02X', 0x07 => 'RLCA',
        0x08 => 'LD ($%04X), SP', 0x09 => 'ADD HL, BC', 0x0A => 'LD A, (BC)', 0x0B => 'DEC BC',
        0x0C => 'INC C', 0x0D => 'DEC C', 0x0E => 'LD C, $%02X', 0x0F => 'RRCA',
        # 0x10
        0x10 => 'STOP', 0x11 => 'LD DE, $%04X', 0x12 => 'LD (DE), A', 0x13 => 'INC DE',
        0x14 => 'INC D', 0x15 => 'DEC D', 0x16 => 'LD D, $%02X', 0x17 => 'RLA',
        0x18 => 'JR $%02X', 0x19 => 'ADD HL, DE', 0x1A => 'LD A, (DE)', 0x1B => 'DEC DE',
        0x1C => 'INC E', 0x1D => 'DEC E', 0x1E => 'LD E, $%02X', 0x1F => 'RRA',
        # 0x20
        0x20 => 'JR NZ, $%02X', 0x21 => 'LD HL, $%04X', 0x22 => 'LD (HL+), A', 0x23 => 'INC HL',
        0x24 => 'INC H', 0x25 => 'DEC H', 0x26 => 'LD H, $%02X', 0x27 => 'DAA',
        0x28 => 'JR Z, $%02X', 0x29 => 'ADD HL, HL', 0x2A => 'LD A, (HL+)', 0x2B => 'DEC HL',
        0x2C => 'INC L', 0x2D => 'DEC L', 0x2E => 'LD L, $%02X', 0x2F => 'CPL',
        # 0x30
        0x30 => 'JR NC, $%02X', 0x31 => 'LD SP, $%04X', 0x32 => 'LD (HL-), A', 0x33 => 'INC SP',
        0x34 => 'INC (HL)', 0x35 => 'DEC (HL)', 0x36 => 'LD (HL), $%02X', 0x37 => 'SCF',
        0x38 => 'JR C, $%02X', 0x39 => 'ADD HL, SP', 0x3A => 'LD A, (HL-)', 0x3B => 'DEC SP',
        0x3C => 'INC A', 0x3D => 'DEC A', 0x3E => 'LD A, $%02X', 0x3F => 'CCF',
        # 0x40 - LD B, r
        0x40 => 'LD B, B', 0x41 => 'LD B, C', 0x42 => 'LD B, D', 0x43 => 'LD B, E',
        0x44 => 'LD B, H', 0x45 => 'LD B, L', 0x46 => 'LD B, (HL)', 0x47 => 'LD B, A',
        # LD C, r
        0x48 => 'LD C, B', 0x49 => 'LD C, C', 0x4A => 'LD C, D', 0x4B => 'LD C, E',
        0x4C => 'LD C, H', 0x4D => 'LD C, L', 0x4E => 'LD C, (HL)', 0x4F => 'LD C, A',
        # 0x50 - LD D, r
        0x50 => 'LD D, B', 0x51 => 'LD D, C', 0x52 => 'LD D, D', 0x53 => 'LD D, E',
        0x54 => 'LD D, H', 0x55 => 'LD D, L', 0x56 => 'LD D, (HL)', 0x57 => 'LD D, A',
        # LD E, r
        0x58 => 'LD E, B', 0x59 => 'LD E, C', 0x5A => 'LD E, D', 0x5B => 'LD E, E',
        0x5C => 'LD E, H', 0x5D => 'LD E, L', 0x5E => 'LD E, (HL)', 0x5F => 'LD E, A',
        # 0x60 - LD H, r
        0x60 => 'LD H, B', 0x61 => 'LD H, C', 0x62 => 'LD H, D', 0x63 => 'LD H, E',
        0x64 => 'LD H, H', 0x65 => 'LD H, L', 0x66 => 'LD H, (HL)', 0x67 => 'LD H, A',
        # LD L, r
        0x68 => 'LD L, B', 0x69 => 'LD L, C', 0x6A => 'LD L, D', 0x6B => 'LD L, E',
        0x6C => 'LD L, H', 0x6D => 'LD L, L', 0x6E => 'LD L, (HL)', 0x6F => 'LD L, A',
        # 0x70 - LD (HL), r
        0x70 => 'LD (HL), B', 0x71 => 'LD (HL), C', 0x72 => 'LD (HL), D', 0x73 => 'LD (HL), E',
        0x74 => 'LD (HL), H', 0x75 => 'LD (HL), L', 0x76 => 'HALT', 0x77 => 'LD (HL), A',
        # LD A, r
        0x78 => 'LD A, B', 0x79 => 'LD A, C', 0x7A => 'LD A, D', 0x7B => 'LD A, E',
        0x7C => 'LD A, H', 0x7D => 'LD A, L', 0x7E => 'LD A, (HL)', 0x7F => 'LD A, A',
        # 0x80 - ADD A, r
        0x80 => 'ADD A, B', 0x81 => 'ADD A, C', 0x82 => 'ADD A, D', 0x83 => 'ADD A, E',
        0x84 => 'ADD A, H', 0x85 => 'ADD A, L', 0x86 => 'ADD A, (HL)', 0x87 => 'ADD A, A',
        # ADC A, r
        0x88 => 'ADC A, B', 0x89 => 'ADC A, C', 0x8A => 'ADC A, D', 0x8B => 'ADC A, E',
        0x8C => 'ADC A, H', 0x8D => 'ADC A, L', 0x8E => 'ADC A, (HL)', 0x8F => 'ADC A, A',
        # 0x90 - SUB r
        0x90 => 'SUB B', 0x91 => 'SUB C', 0x92 => 'SUB D', 0x93 => 'SUB E',
        0x94 => 'SUB H', 0x95 => 'SUB L', 0x96 => 'SUB (HL)', 0x97 => 'SUB A',
        # SBC A, r
        0x98 => 'SBC A, B', 0x99 => 'SBC A, C', 0x9A => 'SBC A, D', 0x9B => 'SBC A, E',
        0x9C => 'SBC A, H', 0x9D => 'SBC A, L', 0x9E => 'SBC A, (HL)', 0x9F => 'SBC A, A',
        # 0xA0 - AND r
        0xA0 => 'AND B', 0xA1 => 'AND C', 0xA2 => 'AND D', 0xA3 => 'AND E',
        0xA4 => 'AND H', 0xA5 => 'AND L', 0xA6 => 'AND (HL)', 0xA7 => 'AND A',
        # XOR r
        0xA8 => 'XOR B', 0xA9 => 'XOR C', 0xAA => 'XOR D', 0xAB => 'XOR E',
        0xAC => 'XOR H', 0xAD => 'XOR L', 0xAE => 'XOR (HL)', 0xAF => 'XOR A',
        # 0xB0 - OR r
        0xB0 => 'OR B', 0xB1 => 'OR C', 0xB2 => 'OR D', 0xB3 => 'OR E',
        0xB4 => 'OR H', 0xB5 => 'OR L', 0xB6 => 'OR (HL)', 0xB7 => 'OR A',
        # CP r
        0xB8 => 'CP B', 0xB9 => 'CP C', 0xBA => 'CP D', 0xBB => 'CP E',
        0xBC => 'CP H', 0xBD => 'CP L', 0xBE => 'CP (HL)', 0xBF => 'CP A',
        # 0xC0
        0xC0 => 'RET NZ', 0xC1 => 'POP BC', 0xC2 => 'JP NZ, $%04X', 0xC3 => 'JP $%04X',
        0xC4 => 'CALL NZ, $%04X', 0xC5 => 'PUSH BC', 0xC6 => 'ADD A, $%02X', 0xC7 => 'RST 00H',
        0xC8 => 'RET Z', 0xC9 => 'RET', 0xCA => 'JP Z, $%04X', 0xCB => 'PREFIX CB',
        0xCC => 'CALL Z, $%04X', 0xCD => 'CALL $%04X', 0xCE => 'ADC A, $%02X', 0xCF => 'RST 08H',
        # 0xD0
        0xD0 => 'RET NC', 0xD1 => 'POP DE', 0xD2 => 'JP NC, $%04X', 0xD3 => 'ILLEGAL',
        0xD4 => 'CALL NC, $%04X', 0xD5 => 'PUSH DE', 0xD6 => 'SUB $%02X', 0xD7 => 'RST 10H',
        0xD8 => 'RET C', 0xD9 => 'RETI', 0xDA => 'JP C, $%04X', 0xDB => 'ILLEGAL',
        0xDC => 'CALL C, $%04X', 0xDD => 'ILLEGAL', 0xDE => 'SBC A, $%02X', 0xDF => 'RST 18H',
        # 0xE0
        0xE0 => 'LDH ($FF%02X), A', 0xE1 => 'POP HL', 0xE2 => 'LD (C), A', 0xE3 => 'ILLEGAL',
        0xE4 => 'ILLEGAL', 0xE5 => 'PUSH HL', 0xE6 => 'AND $%02X', 0xE7 => 'RST 20H',
        0xE8 => 'ADD SP, $%02X', 0xE9 => 'JP (HL)', 0xEA => 'LD ($%04X), A', 0xEB => 'ILLEGAL',
        0xEC => 'ILLEGAL', 0xED => 'ILLEGAL', 0xEE => 'XOR $%02X', 0xEF => 'RST 28H',
        # 0xF0
        0xF0 => 'LDH A, ($FF%02X)', 0xF1 => 'POP AF', 0xF2 => 'LD A, (C)', 0xF3 => 'DI',
        0xF4 => 'ILLEGAL', 0xF5 => 'PUSH AF', 0xF6 => 'OR $%02X', 0xF7 => 'RST 30H',
        0xF8 => 'LD HL, SP+$%02X', 0xF9 => 'LD SP, HL', 0xFA => 'LD A, ($%04X)', 0xFB => 'EI',
        0xFC => 'ILLEGAL', 0xFD => 'ILLEGAL', 0xFE => 'CP $%02X', 0xFF => 'RST 38H',
      }.freeze

      CB_MNEMONICS = {
        # 0x00 - RLC r
        0x00 => 'RLC B', 0x01 => 'RLC C', 0x02 => 'RLC D', 0x03 => 'RLC E',
        0x04 => 'RLC H', 0x05 => 'RLC L', 0x06 => 'RLC (HL)', 0x07 => 'RLC A',
        # RRC r
        0x08 => 'RRC B', 0x09 => 'RRC C', 0x0A => 'RRC D', 0x0B => 'RRC E',
        0x0C => 'RRC H', 0x0D => 'RRC L', 0x0E => 'RRC (HL)', 0x0F => 'RRC A',
        # 0x10 - RL r
        0x10 => 'RL B', 0x11 => 'RL C', 0x12 => 'RL D', 0x13 => 'RL E',
        0x14 => 'RL H', 0x15 => 'RL L', 0x16 => 'RL (HL)', 0x17 => 'RL A',
        # RR r
        0x18 => 'RR B', 0x19 => 'RR C', 0x1A => 'RR D', 0x1B => 'RR E',
        0x1C => 'RR H', 0x1D => 'RR L', 0x1E => 'RR (HL)', 0x1F => 'RR A',
        # 0x20 - SLA r
        0x20 => 'SLA B', 0x21 => 'SLA C', 0x22 => 'SLA D', 0x23 => 'SLA E',
        0x24 => 'SLA H', 0x25 => 'SLA L', 0x26 => 'SLA (HL)', 0x27 => 'SLA A',
        # SRA r
        0x28 => 'SRA B', 0x29 => 'SRA C', 0x2A => 'SRA D', 0x2B => 'SRA E',
        0x2C => 'SRA H', 0x2D => 'SRA L', 0x2E => 'SRA (HL)', 0x2F => 'SRA A',
        # 0x30 - SWAP r
        0x30 => 'SWAP B', 0x31 => 'SWAP C', 0x32 => 'SWAP D', 0x33 => 'SWAP E',
        0x34 => 'SWAP H', 0x35 => 'SWAP L', 0x36 => 'SWAP (HL)', 0x37 => 'SWAP A',
        # SRL r
        0x38 => 'SRL B', 0x39 => 'SRL C', 0x3A => 'SRL D', 0x3B => 'SRL E',
        0x3C => 'SRL H', 0x3D => 'SRL L', 0x3E => 'SRL (HL)', 0x3F => 'SRL A',
        # 0x40-0x7F - BIT n, r
        0x40 => 'BIT 0, B', 0x41 => 'BIT 0, C', 0x42 => 'BIT 0, D', 0x43 => 'BIT 0, E',
        0x44 => 'BIT 0, H', 0x45 => 'BIT 0, L', 0x46 => 'BIT 0, (HL)', 0x47 => 'BIT 0, A',
        0x48 => 'BIT 1, B', 0x49 => 'BIT 1, C', 0x4A => 'BIT 1, D', 0x4B => 'BIT 1, E',
        0x4C => 'BIT 1, H', 0x4D => 'BIT 1, L', 0x4E => 'BIT 1, (HL)', 0x4F => 'BIT 1, A',
        0x50 => 'BIT 2, B', 0x51 => 'BIT 2, C', 0x52 => 'BIT 2, D', 0x53 => 'BIT 2, E',
        0x54 => 'BIT 2, H', 0x55 => 'BIT 2, L', 0x56 => 'BIT 2, (HL)', 0x57 => 'BIT 2, A',
        0x58 => 'BIT 3, B', 0x59 => 'BIT 3, C', 0x5A => 'BIT 3, D', 0x5B => 'BIT 3, E',
        0x5C => 'BIT 3, H', 0x5D => 'BIT 3, L', 0x5E => 'BIT 3, (HL)', 0x5F => 'BIT 3, A',
        0x60 => 'BIT 4, B', 0x61 => 'BIT 4, C', 0x62 => 'BIT 4, D', 0x63 => 'BIT 4, E',
        0x64 => 'BIT 4, H', 0x65 => 'BIT 4, L', 0x66 => 'BIT 4, (HL)', 0x67 => 'BIT 4, A',
        0x68 => 'BIT 5, B', 0x69 => 'BIT 5, C', 0x6A => 'BIT 5, D', 0x6B => 'BIT 5, E',
        0x6C => 'BIT 5, H', 0x6D => 'BIT 5, L', 0x6E => 'BIT 5, (HL)', 0x6F => 'BIT 5, A',
        0x70 => 'BIT 6, B', 0x71 => 'BIT 6, C', 0x72 => 'BIT 6, D', 0x73 => 'BIT 6, E',
        0x74 => 'BIT 6, H', 0x75 => 'BIT 6, L', 0x76 => 'BIT 6, (HL)', 0x77 => 'BIT 6, A',
        0x78 => 'BIT 7, B', 0x79 => 'BIT 7, C', 0x7A => 'BIT 7, D', 0x7B => 'BIT 7, E',
        0x7C => 'BIT 7, H', 0x7D => 'BIT 7, L', 0x7E => 'BIT 7, (HL)', 0x7F => 'BIT 7, A',
        # 0x80-0xBF - RES n, r
        0x80 => 'RES 0, B', 0x81 => 'RES 0, C', 0x82 => 'RES 0, D', 0x83 => 'RES 0, E',
        0x84 => 'RES 0, H', 0x85 => 'RES 0, L', 0x86 => 'RES 0, (HL)', 0x87 => 'RES 0, A',
        0x88 => 'RES 1, B', 0x89 => 'RES 1, C', 0x8A => 'RES 1, D', 0x8B => 'RES 1, E',
        0x8C => 'RES 1, H', 0x8D => 'RES 1, L', 0x8E => 'RES 1, (HL)', 0x8F => 'RES 1, A',
        0x90 => 'RES 2, B', 0x91 => 'RES 2, C', 0x92 => 'RES 2, D', 0x93 => 'RES 2, E',
        0x94 => 'RES 2, H', 0x95 => 'RES 2, L', 0x96 => 'RES 2, (HL)', 0x97 => 'RES 2, A',
        0x98 => 'RES 3, B', 0x99 => 'RES 3, C', 0x9A => 'RES 3, D', 0x9B => 'RES 3, E',
        0x9C => 'RES 3, H', 0x9D => 'RES 3, L', 0x9E => 'RES 3, (HL)', 0x9F => 'RES 3, A',
        0xA0 => 'RES 4, B', 0xA1 => 'RES 4, C', 0xA2 => 'RES 4, D', 0xA3 => 'RES 4, E',
        0xA4 => 'RES 4, H', 0xA5 => 'RES 4, L', 0xA6 => 'RES 4, (HL)', 0xA7 => 'RES 4, A',
        0xA8 => 'RES 5, B', 0xA9 => 'RES 5, C', 0xAA => 'RES 5, D', 0xAB => 'RES 5, E',
        0xAC => 'RES 5, H', 0xAD => 'RES 5, L', 0xAE => 'RES 5, (HL)', 0xAF => 'RES 5, A',
        0xB0 => 'RES 6, B', 0xB1 => 'RES 6, C', 0xB2 => 'RES 6, D', 0xB3 => 'RES 6, E',
        0xB4 => 'RES 6, H', 0xB5 => 'RES 6, L', 0xB6 => 'RES 6, (HL)', 0xB7 => 'RES 6, A',
        0xB8 => 'RES 7, B', 0xB9 => 'RES 7, C', 0xBA => 'RES 7, D', 0xBB => 'RES 7, E',
        0xBC => 'RES 7, H', 0xBD => 'RES 7, L', 0xBE => 'RES 7, (HL)', 0xBF => 'RES 7, A',
        # 0xC0-0xFF - SET n, r
        0xC0 => 'SET 0, B', 0xC1 => 'SET 0, C', 0xC2 => 'SET 0, D', 0xC3 => 'SET 0, E',
        0xC4 => 'SET 0, H', 0xC5 => 'SET 0, L', 0xC6 => 'SET 0, (HL)', 0xC7 => 'SET 0, A',
        0xC8 => 'SET 1, B', 0xC9 => 'SET 1, C', 0xCA => 'SET 1, D', 0xCB => 'SET 1, E',
        0xCC => 'SET 1, H', 0xCD => 'SET 1, L', 0xCE => 'SET 1, (HL)', 0xCF => 'SET 1, A',
        0xD0 => 'SET 2, B', 0xD1 => 'SET 2, C', 0xD2 => 'SET 2, D', 0xD3 => 'SET 2, E',
        0xD4 => 'SET 2, H', 0xD5 => 'SET 2, L', 0xD6 => 'SET 2, (HL)', 0xD7 => 'SET 2, A',
        0xD8 => 'SET 3, B', 0xD9 => 'SET 3, C', 0xDA => 'SET 3, D', 0xDB => 'SET 3, E',
        0xDC => 'SET 3, H', 0xDD => 'SET 3, L', 0xDE => 'SET 3, (HL)', 0xDF => 'SET 3, A',
        0xE0 => 'SET 4, B', 0xE1 => 'SET 4, C', 0xE2 => 'SET 4, D', 0xE3 => 'SET 4, E',
        0xE4 => 'SET 4, H', 0xE5 => 'SET 4, L', 0xE6 => 'SET 4, (HL)', 0xE7 => 'SET 4, A',
        0xE8 => 'SET 5, B', 0xE9 => 'SET 5, C', 0xEA => 'SET 5, D', 0xEB => 'SET 5, E',
        0xEC => 'SET 5, H', 0xED => 'SET 5, L', 0xEE => 'SET 5, (HL)', 0xEF => 'SET 5, A',
        0xF0 => 'SET 6, B', 0xF1 => 'SET 6, C', 0xF2 => 'SET 6, D', 0xF3 => 'SET 6, E',
        0xF4 => 'SET 6, H', 0xF5 => 'SET 6, L', 0xF6 => 'SET 6, (HL)', 0xF7 => 'SET 6, A',
        0xF8 => 'SET 7, B', 0xF9 => 'SET 7, C', 0xFA => 'SET 7, D', 0xFB => 'SET 7, E',
        0xFC => 'SET 7, H', 0xFD => 'SET 7, L', 0xFE => 'SET 7, (HL)', 0xFF => 'SET 7, A',
      }.freeze

      def instruction_length(opcode)
        INSTRUCTION_LENGTHS[opcode] || 1
      end

      def decode(bytes)
        return { mnemonic: 'END', bytes: [], length: 0 } if bytes.empty?

        opcode = bytes[0]
        length = instruction_length(opcode)

        if opcode == 0xCB
          # CB-prefixed instruction
          cb_opcode = bytes[1] || 0x00
          mnemonic = CB_MNEMONICS[cb_opcode] || "CB #{format('%02X', cb_opcode)}"
          return { mnemonic: mnemonic, bytes: bytes[0, 2], length: 2 }
        end

        mnemonic_format = MNEMONICS[opcode] || format('DB $%02X', opcode)

        mnemonic = case length
                   when 3
                     operand = (bytes[2] || 0) << 8 | (bytes[1] || 0)
                     format(mnemonic_format, operand)
                   when 2
                     operand = bytes[1] || 0
                     format(mnemonic_format, operand)
                   else
                     mnemonic_format
                   end

        { mnemonic: mnemonic, bytes: bytes[0, length], length: length }
      end

      def format_bytes(bytes)
        bytes.map { |b| format('0x%02X', b) }.join(' ')
      end
    end
  end
end
