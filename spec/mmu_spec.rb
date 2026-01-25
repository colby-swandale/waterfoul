require 'spec_helper'

describe Waterfoul::MMU do
  subject { Waterfoul::MMU.new }

  describe 'GBC mode' do
    subject { Waterfoul::MMU.new(Waterfoul::Cartridge.empty, gbc_mode: true) }

    describe '#initialize' do
      it 'enables GBC mode' do
        expect(subject.gbc_mode).to be true
      end
    end

    describe 'VRAM banking (VBK register 0xFF4F)' do
      it 'defaults to bank 0' do
        # VBK reads as bank | 0xFE
        expect(subject.read_byte(0xFF4F)).to eq 0xFE
      end

      it 'switches to bank 1 when written' do
        subject.write_byte(0xFF4F, 0x01)
        expect(subject.read_byte(0xFF4F)).to eq 0xFF
      end

      it 'writes to bank 0 by default' do
        subject.write_byte(0x8000, 0x42)
        expect(subject.read_byte(0x8000)).to eq 0x42
      end

      it 'writes to bank 1 when selected' do
        subject.write_byte(0xFF4F, 0x01)
        subject.write_byte(0x8000, 0x99)
        expect(subject.read_byte(0x8000)).to eq 0x99

        # Switch back and verify bank 0 is separate
        subject.write_byte(0xFF4F, 0x00)
        expect(subject.read_byte(0x8000)).to eq 0x00
      end
    end

    describe 'WRAM banking (SVBK register 0xFF70)' do
      it 'defaults to bank 1' do
        # SVBK reads as bank | 0xF8
        expect(subject.read_byte(0xFF70)).to eq 0xF9
      end

      it 'writing 0 maps to bank 1' do
        subject.write_byte(0xFF70, 0x00)
        expect(subject.read_byte(0xFF70)).to eq 0xF9
      end

      it 'switches banks correctly' do
        # Write to bank 1
        subject.write_byte(0xD000, 0x11)

        # Switch to bank 2
        subject.write_byte(0xFF70, 0x02)
        expect(subject.read_byte(0xFF70)).to eq 0xFA

        # Write to bank 2
        subject.write_byte(0xD000, 0x22)

        # Verify bank 2 has correct value
        expect(subject.read_byte(0xD000)).to eq 0x22

        # Switch back to bank 1
        subject.write_byte(0xFF70, 0x01)
        expect(subject.read_byte(0xD000)).to eq 0x11
      end

      it 'bank 0 (0xC000-0xCFFF) is not switchable' do
        subject.write_byte(0xC000, 0xAA)
        subject.write_byte(0xFF70, 0x03)
        expect(subject.read_byte(0xC000)).to eq 0xAA
      end
    end

    describe 'Background palette (BCPS/BCPD registers)' do
      it 'reads BCPS with auto-increment flag' do
        subject.write_byte(0xFF68, 0x80 | 0x10) # Index 16 with auto-increment
        expect(subject.read_byte(0xFF68)).to eq (0x80 | 0x10)
      end

      it 'writes palette data and auto-increments' do
        subject.write_byte(0xFF68, 0x80) # Index 0 with auto-increment
        subject.write_byte(0xFF69, 0x1F) # Low byte
        subject.write_byte(0xFF69, 0x7C) # High byte (auto-incremented)

        # Read back
        subject.write_byte(0xFF68, 0x00) # Index 0, no auto-increment
        expect(subject.read_byte(0xFF69)).to eq 0x1F
        subject.write_byte(0xFF68, 0x01) # Index 1
        expect(subject.read_byte(0xFF69)).to eq 0x7C
      end
    end

    describe 'Object palette (OCPS/OCPD registers)' do
      it 'reads OCPS with auto-increment flag' do
        subject.write_byte(0xFF6A, 0x80 | 0x20) # Index 32 with auto-increment
        expect(subject.read_byte(0xFF6A)).to eq (0x80 | 0x20)
      end

      it 'writes palette data and auto-increments' do
        subject.write_byte(0xFF6A, 0x80) # Index 0 with auto-increment
        subject.write_byte(0xFF6B, 0x00) # Low byte
        subject.write_byte(0xFF6B, 0x7C) # High byte

        # Read back
        subject.write_byte(0xFF6A, 0x00)
        expect(subject.read_byte(0xFF6B)).to eq 0x00
        subject.write_byte(0xFF6A, 0x01)
        expect(subject.read_byte(0xFF6B)).to eq 0x7C
      end
    end

    describe '#gbc_to_rgb' do
      it 'converts RGB555 to ARGB8888' do
        # White (31, 31, 31) -> 0xFFFFFFFF
        result = subject.gbc_to_rgb(0xFF, 0x7F)
        expect(result).to eq 0xFFFFFFFF

        # Red (31, 0, 0) -> 0xFFFF0000
        result = subject.gbc_to_rgb(0x1F, 0x00)
        expect(result).to eq 0xFFFF0000

        # Green (0, 31, 0) -> 0xFF00FF00
        result = subject.gbc_to_rgb(0xE0, 0x03)
        expect(result).to eq 0xFF00FF00

        # Blue (0, 0, 31) -> 0xFF0000FF
        result = subject.gbc_to_rgb(0x00, 0x7C)
        expect(result).to eq 0xFF0000FF

        # Black (0, 0, 0) -> 0xFF000000
        result = subject.gbc_to_rgb(0x00, 0x00)
        expect(result).to eq 0xFF000000
      end
    end

    describe '#bg_palette_color' do
      it 'returns color from background CRAM' do
        # Set palette 0, color 0 to red (31, 0, 0)
        subject.write_byte(0xFF68, 0x80) # Index 0 with auto-increment
        subject.write_byte(0xFF69, 0x1F) # Low byte
        subject.write_byte(0xFF69, 0x00) # High byte

        expect(subject.bg_palette_color(0, 0)).to eq 0xFFFF0000
      end
    end

    describe '#obj_palette_color' do
      it 'returns color from object CRAM' do
        # Set palette 0, color 1 to green
        subject.write_byte(0xFF6A, 0x80 | 0x02) # Index 2 (color 1 low byte)
        subject.write_byte(0xFF6B, 0xE0) # Low byte
        subject.write_byte(0xFF6B, 0x03) # High byte

        expect(subject.obj_palette_color(0, 1)).to eq 0xFF00FF00
      end
    end

    describe '#tile_attribute' do
      it 'reads from VRAM bank 1' do
        # Write attribute to VRAM bank 1
        subject.write_byte(0xFF4F, 0x01) # Select bank 1
        subject.write_byte(0x9800, 0x87) # Write attribute
        subject.write_byte(0xFF4F, 0x00) # Switch back to bank 0

        expect(subject.tile_attribute(0x9800)).to eq 0x87
      end
    end

    describe '#read_vram_bank1' do
      it 'reads tile data from VRAM bank 1' do
        subject.write_byte(0xFF4F, 0x01)
        subject.write_byte(0x8000, 0xAB)
        subject.write_byte(0xFF4F, 0x00)

        expect(subject.read_vram_bank1(0x8000)).to eq 0xAB
      end
    end
  end

  describe '#write_byte' do
    context 'writing to 0xFFFFFF' do
      it 'raises an exception' do
        expect { subject.write_byte(0xFFFFFF, 0x1) }.to raise_error Waterfoul::MemoryOutOfBounds
      end
    end

    context 'when writing to -0x1' do
      it 'raises an exception' do
        expect { subject.write_byte(-0x1, 0x1) }.to raise_error Waterfoul::MemoryOutOfBounds
      end
    end
  end

  describe '#read_byte' do
    context 'reading from 0xFFFFFF' do
      it 'raises an exception' do
        expect { subject.read_byte(0xFFFFFF) }.to raise_error Waterfoul::MemoryOutOfBounds
      end
    end

    context 'reading from -0x1' do
      it 'raises an exception' do
        expect { subject.read_byte(-0x1) }.to raise_error Waterfoul::MemoryOutOfBounds
      end
    end
  end

  describe 'DIV register' do
    before do
      $mmu = subject
      $timer = Waterfoul::Timer.new
      # Run the timer until DIV is non-zero
      $timer.tick(256 * 5)  # DIV should be 5
    end

    it 'resets when written to' do
      expect(subject.read_byte(0xFF04)).to eq 5  # Verify DIV is non-zero first
      subject.write_byte 0xFF04, 0x35  # Writing any value resets DIV
      expect(subject.read_byte(0xFF04)).to eq 0
    end
  end

  describe '#read_word' do
    before do
      subject.write_byte 0xC001, 0x1
      subject.write_byte 0xC000, 0x1
    end

    it 'reads two bytes from memory into a word' do
      expect(subject.read_word(0xC000)).to eq 0x101
    end
  end

  describe '#write_word' do
    it 'writes 2 bytes into 2 1 byte parts' do
      subject.write_word 0xFF40, 0xFFAA
      expect(subject[0xFF40]).to eq 0xAA
      expect(subject[0xFF41]).to eq 0xFF
    end
  end
end
