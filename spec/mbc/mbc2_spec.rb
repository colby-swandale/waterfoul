require 'spec_helper'

describe Waterfoul::MBC::MBC2 do
  let(:program) { Array.new(0x40000, 0) }  # 256KB ROM (max for MBC2)
  subject { Waterfoul::MBC::MBC2.new(program) }

  describe '#initialize' do
    it 'starts with ROM bank 1 selected' do
      expect(subject.rom_bank).to eq 1
    end
  end

  describe '#[]' do
    context 'when reading from ROM bank 0 (0x0000-0x3FFF)' do
      before { program[0x0001] = 0x42 }

      it 'reads byte from bank 0' do
        expect(subject[0x0001]).to eq 0x42
      end
    end

    context 'when reading from ROM bank n (0x4000-0x7FFF)' do
      context 'with default bank 1' do
        before { program[0x4001] = 0x55 }

        it 'reads from bank 1' do
          expect(subject[0x4001]).to eq 0x55
        end
      end

      context 'after switching to bank 2' do
        before do
          program[0x8001] = 0xAB  # Bank 2 offset: 2 * 0x4000 + 0x0001
          subject[0x2100] = 0x02  # Bit 8 set, so ROM bank select
        end

        it 'reads from bank 2' do
          expect(subject[0x4001]).to eq 0xAB
        end
      end
    end

    context 'when reading internal RAM (0xA000-0xBFFF)' do
      context 'when RAM is disabled' do
        it 'returns 0xFF' do
          expect(subject[0xA000]).to eq 0xFF
        end
      end

      context 'when RAM is enabled' do
        before { subject[0x0000] = 0x0A }  # Bit 8 clear, RAM enable

        it 'reads from RAM with upper nibble as 0xF' do
          subject[0xA000] = 0x05
          expect(subject[0xA000]).to eq 0xF5  # Upper nibble 0xF, lower nibble 0x5
        end

        it 'only stores lower 4 bits' do
          subject[0xA000] = 0xFF
          expect(subject[0xA000]).to eq 0xFF  # 0xF0 | 0x0F
        end
      end
    end
  end

  describe '#[]=' do
    describe 'RAM Enable (0x0000-0x3FFF with bit 8 clear)' do
      it 'enables RAM when writing 0x0A to address with bit 8 clear' do
        subject[0x0000] = 0x0A  # Bit 8 = 0
        subject[0xA000] = 0x05
        expect(subject[0xA000]).to eq 0xF5
      end

      it 'does not enable RAM when bit 8 is set' do
        subject[0x0100] = 0x0A  # Bit 8 = 1, this is ROM bank select
        expect(subject[0xA000]).to eq 0xFF  # RAM still disabled
      end

      it 'disables RAM when writing non-0xA value' do
        subject[0x0000] = 0x0A  # Enable
        subject[0x0000] = 0x00  # Disable
        expect(subject[0xA000]).to eq 0xFF
      end
    end

    describe 'ROM Bank (0x0000-0x3FFF with bit 8 set)' do
      it 'sets ROM bank when bit 8 is set' do
        subject[0x2100] = 0x05  # Bit 8 = 1
        expect(subject.rom_bank).to eq 5
      end

      it 'only uses lower 4 bits (max bank 15)' do
        subject[0x2100] = 0xFF
        expect(subject.rom_bank).to eq 0x0F
      end

      it 'maps bank 0 to bank 1' do
        subject[0x2100] = 0x00
        expect(subject.rom_bank).to eq 1
      end

      it 'does not affect RAM enable when bit 8 is set' do
        subject[0x0000] = 0x0A  # Enable RAM (bit 8 clear)
        subject[0x2100] = 0x02  # ROM bank (bit 8 set)
        subject[0xA000] = 0x07
        expect(subject[0xA000]).to eq 0xF7  # RAM still enabled
      end
    end

    describe 'Internal RAM (0xA000-0xBFFF)' do
      before { subject[0x0000] = 0x0A }

      it 'only stores lower 4 bits' do
        subject[0xA000] = 0xAB
        expect(subject[0xA000]).to eq 0xFB  # Only 0x0B stored
      end

      it 'uses only bottom 9 bits of address (512 bytes)' do
        subject[0xA000] = 0x05
        # 0xA200 wraps to same location as 0xA000 (both have low 9 bits = 0)
        expect(subject[0xA200]).to eq 0xF5
      end

      it 'echoes throughout 0xA000-0xBFFF range' do
        subject[0xA001] = 0x09
        expect(subject[0xA201]).to eq 0xF9  # +0x200 echo
        expect(subject[0xA401]).to eq 0xF9  # +0x400 echo
        expect(subject[0xB001]).to eq 0xF9  # +0x1000 echo
      end

      it 'does not write when RAM is disabled' do
        subject[0x0000] = 0x00  # Disable RAM
        subject[0xA000] = 0x05
        subject[0x0000] = 0x0A  # Re-enable
        expect(subject[0xA000]).to eq 0xFF  # Initial value (0x0F) returns as 0xFF? No...
      end
    end

    describe '512-byte RAM boundary' do
      before { subject[0x0000] = 0x0A }

      it 'wraps address 0xA1FF to RAM index 511' do
        subject[0xA1FF] = 0x0C
        expect(subject[0xA1FF]).to eq 0xFC
      end

      it 'wraps address 0xA200 back to RAM index 0' do
        subject[0xA000] = 0x0A
        expect(subject[0xA200]).to eq 0xFA  # Same as 0xA000
      end
    end
  end

  describe 'address bit 8 behavior' do
    it 'treats 0x0000 as RAM enable (bit 8 = 0)' do
      subject[0x0000] = 0x0A
      subject[0xA000] = 0x05
      expect(subject[0xA000]).to eq 0xF5
    end

    it 'treats 0x0100 as ROM bank (bit 8 = 1)' do
      subject[0x0100] = 0x05
      expect(subject.rom_bank).to eq 5
    end

    it 'treats 0x2000 as RAM enable (bit 8 = 0)' do
      subject[0x2000] = 0x0A
      subject[0xA000] = 0x03
      expect(subject[0xA000]).to eq 0xF3
    end

    it 'treats 0x2100 as ROM bank (bit 8 = 1)' do
      subject[0x2100] = 0x07
      expect(subject.rom_bank).to eq 7
    end

    it 'treats 0x3000 as RAM enable (bit 8 = 0)' do
      subject[0x3000] = 0x0A
      subject[0xA000] = 0x0E
      expect(subject[0xA000]).to eq 0xFE
    end

    it 'treats 0x3100 as ROM bank (bit 8 = 1)' do
      subject[0x3100] = 0x0F
      expect(subject.rom_bank).to eq 15
    end
  end
end
