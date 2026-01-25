require 'spec_helper'

describe Waterfoul::MBC::MBC3 do
  let(:program) { Array.new(0x200000, 0) }  # 2MB ROM
  subject { Waterfoul::MBC::MBC3.new(program) }

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
    describe 'RAM/Timer enable (0x0000-0x1FFF)' do
      it 'enables RAM when writing 0x0A' do
        subject[0x0000] = 0x0A
        subject[0xA000] = 0x42
        expect(subject[0xA000]).to eq 0x42
      end

      it 'disables RAM when writing other values' do
        subject[0x0000] = 0x0A  # Enable first
        subject[0x0000] = 0x00  # Then disable
        expect(subject[0xA000]).to eq 0xFF
      end
    end

    describe 'ROM bank (0x2000-0x3FFF)' do
      it 'sets ROM bank with 7 bits' do
        subject[0x2000] = 0x7F
        expect(subject.rom_bank).to eq 0x7F
      end

      it 'maps bank 0 to bank 1' do
        subject[0x2000] = 0x00
        expect(subject.rom_bank).to eq 1
      end

      it 'masks to 7 bits' do
        subject[0x2000] = 0xFF
        expect(subject.rom_bank).to eq 0x7F
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

      it 'supports 4 RAM banks (0-3)' do
        subject[0x4000] = 0x03
        subject[0xA000] = 0x33

        subject[0x4000] = 0x03
        expect(subject[0xA000]).to eq 0x33
      end
    end

    describe 'external RAM write (0xA000-0xBFFF)' do
      context 'when RAM is disabled' do
        it 'does not write to RAM' do
          subject[0xA000] = 0x42
          subject[0x0000] = 0x0A  # Enable after attempted write
          expect(subject[0xA000]).to eq 0x00
        end
      end
    end
  end

  describe 'RTC functionality' do
    let(:rtc_subject) { Waterfoul::MBC::MBC3.new(program, has_rtc: true) }

    before { rtc_subject[0x0000] = 0x0A }  # Enable RAM/RTC

    describe 'RTC register selection (0x4000-0x5FFF)' do
      it 'selects seconds register with 0x08' do
        rtc_subject[0x4000] = 0x08
        rtc_subject[0x6000] = 0x00  # Latch
        rtc_subject[0x6000] = 0x01
        # Should read RTC, not RAM
        expect(rtc_subject[0xA000]).to eq 0  # Initial seconds
      end

      it 'switches back to RAM with 0x00-0x03' do
        rtc_subject[0x4000] = 0x08  # Select RTC
        rtc_subject[0x4000] = 0x00  # Back to RAM
        rtc_subject[0xA000] = 0x42
        expect(rtc_subject[0xA000]).to eq 0x42
      end
    end

    describe 'RTC latch mechanism (0x6000-0x7FFF)' do
      it 'requires 0x00 then 0x01 sequence to latch' do
        rtc_subject[0x4000] = 0x08  # Select seconds
        rtc_subject[0x6000] = 0x01  # Just 0x01, no latch
        # Values should still be readable (initial state)
        expect(rtc_subject[0xA000]).to eq 0
      end

      it 'latches with proper sequence' do
        rtc_subject[0x4000] = 0x08  # Select seconds
        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01
        expect(rtc_subject[0xA000]).to eq 0  # Latched seconds
      end
    end

    describe 'RTC register read/write' do
      before do
        rtc_subject[0x6000] = 0x00  # Latch sequence
        rtc_subject[0x6000] = 0x01
      end

      it 'reads and writes seconds (0x08)' do
        rtc_subject[0x4000] = 0x08
        rtc_subject[0xA000] = 30
        rtc_subject[0x6000] = 0x00  # Re-latch
        rtc_subject[0x6000] = 0x01
        expect(rtc_subject[0xA000]).to eq 30
      end

      it 'reads and writes minutes (0x09)' do
        rtc_subject[0x4000] = 0x09
        rtc_subject[0xA000] = 45
        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01
        expect(rtc_subject[0xA000]).to eq 45
      end

      it 'reads and writes hours (0x0A)' do
        rtc_subject[0x4000] = 0x0A
        rtc_subject[0xA000] = 23
        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01
        expect(rtc_subject[0xA000]).to eq 23
      end

      it 'reads and writes day low (0x0B)' do
        rtc_subject[0x4000] = 0x0B
        rtc_subject[0xA000] = 255
        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01
        expect(rtc_subject[0xA000]).to eq 255
      end

      it 'reads and writes day high with flags (0x0C)' do
        rtc_subject[0x4000] = 0x0C
        rtc_subject[0xA000] = 0xC1  # Day bit 8 + halt + carry
        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01
        expect(rtc_subject[0xA000]).to eq 0xC1
      end
    end

    describe 'RTC value constraints' do
      before do
        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01
      end

      it 'masks seconds to 6 bits (0-59)' do
        rtc_subject[0x4000] = 0x08
        rtc_subject[0xA000] = 0xFF
        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01
        expect(rtc_subject[0xA000]).to eq 0x3F
      end

      it 'masks hours to 5 bits (0-23)' do
        rtc_subject[0x4000] = 0x0A
        rtc_subject[0xA000] = 0xFF
        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01
        expect(rtc_subject[0xA000]).to eq 0x1F
      end
    end

    describe '9-bit day counter' do
      before do
        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01
      end

      it 'combines day low and day high bit 0' do
        # Set day to 256 (0x100)
        rtc_subject[0x4000] = 0x0B
        rtc_subject[0xA000] = 0x00  # Day low = 0
        rtc_subject[0x4000] = 0x0C
        rtc_subject[0xA000] = 0x01  # Day high bit 0 = 1

        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01

        rtc_subject[0x4000] = 0x0B
        expect(rtc_subject[0xA000]).to eq 0x00  # Low byte
        rtc_subject[0x4000] = 0x0C
        expect(rtc_subject[0xA000] & 0x01).to eq 0x01  # High bit
      end
    end

    describe 'halt flag' do
      it 'can be set via day high register' do
        rtc_subject[0x4000] = 0x0C
        rtc_subject[0xA000] = 0x40  # Set halt flag
        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01
        expect(rtc_subject[0xA000] & 0x40).to eq 0x40
      end
    end

    describe 'carry flag' do
      it 'can be set via day high register' do
        rtc_subject[0x4000] = 0x0C
        rtc_subject[0xA000] = 0x80  # Set carry flag
        rtc_subject[0x6000] = 0x00
        rtc_subject[0x6000] = 0x01
        expect(rtc_subject[0xA000] & 0x80).to eq 0x80
      end
    end
  end

  describe 'non-RTC MBC3' do
    it 'ignores RTC register selection' do
      subject[0x0000] = 0x0A  # Enable RAM
      subject[0x4000] = 0x08  # Try to select RTC
      subject[0xA000] = 0x42  # Should write to RAM, not RTC
      expect(subject[0xA000]).to eq 0x42
    end
  end
end
