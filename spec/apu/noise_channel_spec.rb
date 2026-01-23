require 'spec_helper'

describe Waterfoul::APU::NoiseChannel do
  subject { described_class.new }

  describe '#write_nr41' do
    it 'sets length counter' do
      subject.write_nr41(0x3F)  # length = 1
      expect(subject.length_counter.counter).to eq(1)
    end
  end

  describe '#write_nr42' do
    it 'configures volume envelope' do
      subject.write_nr42(0xF3)
      expect(subject.volume_envelope.dac_enabled?).to eq(true)
    end

    it 'disables channel when DAC disabled' do
      subject.write_nr44(0x80)  # trigger
      subject.write_nr42(0x00)  # DAC off
      expect(subject.enabled).to eq(false)
    end
  end

  describe '#write_nr43' do
    it 'sets clock shift' do
      subject.write_nr43(0xF0)  # shift = 15
      expect((subject.read_nr43 >> 4) & 0x0F).to eq(15)
    end

    it 'sets width mode' do
      subject.write_nr43(0x08)  # 7-bit mode
      expect(subject.read_nr43 & 0x08).to eq(0x08)
    end

    it 'sets divisor code' do
      subject.write_nr43(0x07)
      expect(subject.read_nr43 & 0x07).to eq(7)
    end
  end

  describe '#write_nr44' do
    it 'enables length counter when bit 6 is set' do
      subject.write_nr44(0x40)
      expect(subject.length_counter.enabled).to eq(true)
    end

    it 'triggers channel when bit 7 is set' do
      subject.write_nr42(0xF0)  # Enable DAC
      subject.write_nr44(0x80)
      expect(subject.enabled).to eq(true)
    end
  end

  describe '#tick' do
    before do
      subject.write_nr42(0xF0)
      subject.write_nr43(0x00)  # divisor = 8, shift = 0
      subject.write_nr44(0x80)
    end

    it 'clocks LFSR' do
      8.times { subject.tick }
      # LFSR should have shifted
    end
  end

  describe '#output' do
    before do
      subject.write_nr42(0xF0)  # volume = 15
      subject.write_nr44(0x80)
    end

    it 'returns 0 when disabled' do
      subject.disable
      expect(subject.output).to eq(0)
    end

    it 'returns value based on LFSR and volume' do
      output = subject.output
      expect(output).to be >= 0
      expect(output).to be <= 15
    end
  end

  describe '#clock_length' do
    before do
      subject.write_nr41(0x3E)  # length = 2
      subject.write_nr42(0xF0)
      subject.write_nr44(0xC0)  # trigger with length enable
    end

    it 'disables channel when length expires' do
      2.times { subject.clock_length }
      expect(subject.enabled).to eq(false)
    end
  end

  describe '#clock_envelope' do
    before do
      subject.write_nr42(0xF3)  # volume = 15, decrease, period = 3
      subject.write_nr44(0x80)
    end

    it 'adjusts volume' do
      initial_vol = subject.volume_envelope.volume
      3.times { subject.clock_envelope }
      expect(subject.volume_envelope.volume).to eq(initial_vol - 1)
    end
  end

  describe 'LFSR behavior' do
    before do
      subject.write_nr42(0xF0)
    end

    context '15-bit mode' do
      before do
        subject.write_nr43(0x00)  # 15-bit mode
        subject.write_nr44(0x80)
      end

      it 'generates pseudo-random output' do
        outputs = []
        1000.times do
          8.times { subject.tick }
          outputs << subject.output
        end
        # Should have some variation
        expect(outputs.uniq.size).to be > 1
      end
    end

    context '7-bit mode' do
      before do
        subject.write_nr43(0x08)  # 7-bit mode
        subject.write_nr44(0x80)
      end

      it 'generates pseudo-random output' do
        outputs = []
        100.times do
          8.times { subject.tick }
          outputs << subject.output
        end
        expect(outputs.uniq.size).to be > 1
      end
    end
  end

  describe 'register reads' do
    it 'returns 0xFF for NR41 (write-only)' do
      expect(subject.read_nr41).to eq(0xFF)
    end

    it 'returns envelope settings for NR42' do
      subject.write_nr42(0xF3)
      expect(subject.read_nr42).to eq(0xF3)
    end

    it 'returns polynomial settings for NR43' do
      subject.write_nr43(0xAB)
      expect(subject.read_nr43).to eq(0xAB)
    end

    it 'returns 0xBF OR length enable for NR44' do
      subject.write_nr44(0x40)
      expect(subject.read_nr44).to eq(0xFF)
    end
  end
end
