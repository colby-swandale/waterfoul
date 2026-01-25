require 'spec_helper'

describe Waterfoul::MBC::MBC5 do
  let(:program) { Array.new(0x800000, 0) }  # 8MB ROM (max MBC5 size)
  subject { Waterfoul::MBC::MBC5.new program }

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
          subject[0x2000] = 0x02
        end

        it 'reads from bank 2' do
          expect(subject[0x4001]).to eq 0xAB
        end
      end

      context 'with 9-bit bank number (bank 256)' do
        before do
          # Bank 256 offset: 256 * 0x4000 = 0x400000
          program[0x400001] = 0xCD
          subject[0x2000] = 0x00  # Lower 8 bits = 0
          subject[0x3000] = 0x01  # 9th bit = 1
        end

        it 'reads from bank 256' do
          expect(subject[0x4001]).to eq 0xCD
        end
      end
    end

    context 'when reading external RAM (0xA000-0xBFFF)' do
      context 'when RAM is disabled' do
        it 'returns 0xFF' do
          expect(subject[0xA001]).to eq 0xFF
        end
      end

      context 'when RAM is enabled' do
        before { subject[0x0000] = 0x0A }

        it 'reads from RAM' do
          subject[0xA001] = 0x77
          expect(subject[0xA001]).to eq 0x77
        end
      end
    end
  end

  describe '#[]=' do
    describe 'RAM enable (0x0000-0x1FFF)' do
      it 'enables RAM when writing 0x0A' do
        subject[0x0000] = 0x0A
        subject[0xA000] = 0x42
        expect(subject[0xA000]).to eq 0x42
      end

      it 'enables RAM when lower nibble is 0xA' do
        subject[0x0000] = 0xFA
        subject[0xA000] = 0x42
        expect(subject[0xA000]).to eq 0x42
      end

      it 'disables RAM when writing other values' do
        subject[0x0000] = 0x0A  # Enable first
        subject[0x0000] = 0x00  # Then disable
        expect(subject[0xA000]).to eq 0xFF
      end
    end

    describe 'ROM bank lower bits (0x2000-0x2FFF)' do
      it 'sets lower 8 bits of ROM bank' do
        subject[0x2000] = 0xFF
        expect(subject.rom_bank).to eq 0xFF
      end

      it 'allows bank 0 (unlike MBC1)' do
        subject[0x2000] = 0x00
        expect(subject.rom_bank).to eq 0x00
      end
    end

    describe 'ROM bank 9th bit (0x3000-0x3FFF)' do
      it 'sets 9th bit of ROM bank' do
        subject[0x2000] = 0x00
        subject[0x3000] = 0x01
        expect(subject.rom_bank).to eq 0x100
      end

      it 'only uses bit 0' do
        subject[0x2000] = 0x00
        subject[0x3000] = 0xFF
        expect(subject.rom_bank).to eq 0x100
      end

      it 'combines with lower 8 bits' do
        subject[0x2000] = 0x23
        subject[0x3000] = 0x01
        expect(subject.rom_bank).to eq 0x123
      end
    end

    describe 'RAM bank (0x4000-0x5FFF)' do
      before { subject[0x0000] = 0x0A }  # Enable RAM

      it 'switches RAM bank' do
        subject[0x4000] = 0x01
        subject[0xA000] = 0x11  # Write to bank 1

        subject[0x4000] = 0x00
        subject[0xA000] = 0x00  # Write to bank 0

        subject[0x4000] = 0x01  # Switch back to bank 1
        expect(subject[0xA000]).to eq 0x11
      end

      it 'only uses lower 4 bits (0-15)' do
        subject[0x4000] = 0xFF
        subject[0xA000] = 0x42

        subject[0x4000] = 0x0F  # Same as 0xFF & 0x0F
        expect(subject[0xA000]).to eq 0x42
      end
    end

    describe 'external RAM write (0xA000-0xBFFF)' do
      context 'when RAM is enabled' do
        before { subject[0x0000] = 0x0A }

        it 'writes to RAM' do
          subject[0xA000] = 0x42
          expect(subject[0xA000]).to eq 0x42
        end

        it 'writes across the full RAM range' do
          subject[0xBFFF] = 0x99
          expect(subject[0xBFFF]).to eq 0x99
        end
      end

      context 'when RAM is disabled' do
        it 'does not write to RAM' do
          subject[0xA000] = 0x42
          subject[0x0000] = 0x0A  # Enable after attempted write
          expect(subject[0xA000]).to eq 0x00  # Should be unmodified
        end
      end
    end
  end

  describe 'rumble variant' do
    let(:rumble_subject) { Waterfoul::MBC::MBC5.new(program, has_rumble: true) }

    describe 'RAM bank with rumble (0x4000-0x5FFF)' do
      before { rumble_subject[0x0000] = 0x0A }  # Enable RAM

      it 'only uses bits 0-2 for RAM bank (max 8 banks)' do
        rumble_subject[0x4000] = 0x0F  # All bits set
        rumble_subject[0xA000] = 0x42

        rumble_subject[0x4000] = 0x07  # Only lower 3 bits = same bank
        expect(rumble_subject[0xA000]).to eq 0x42
      end

      it 'uses bit 3 for rumble motor control' do
        rumble_subject[0x4000] = 0x08  # Rumble on, bank 0
        # We can't test actual rumble, but verify RAM bank is 0
        rumble_subject[0xA000] = 0x55

        rumble_subject[0x4000] = 0x00  # Rumble off, bank 0
        expect(rumble_subject[0xA000]).to eq 0x55  # Same bank
      end

      it 'separates rumble control from bank selection' do
        rumble_subject[0x4000] = 0x01  # Bank 1, no rumble
        rumble_subject[0xA000] = 0xAA

        rumble_subject[0x4000] = 0x09  # Bank 1, rumble on
        expect(rumble_subject[0xA000]).to eq 0xAA  # Still bank 1
      end
    end
  end
end
