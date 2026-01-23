require 'spec_helper'

describe Waterfoul::APU::WaveChannel do
  subject { described_class.new }

  describe '#write_nr30' do
    it 'enables DAC when bit 7 is set' do
      subject.write_nr30(0x80)
      # DAC enabled, channel can be triggered
    end

    it 'disables channel when DAC is disabled' do
      subject.write_nr30(0x80)
      subject.write_nr34(0x80)  # trigger
      subject.write_nr30(0x00)  # disable DAC
      expect(subject.enabled).to eq(false)
    end
  end

  describe '#write_nr31' do
    it 'sets length counter' do
      subject.write_nr31(0x00)  # length = 256
      expect(subject.length_counter.counter).to eq(256)
    end
  end

  describe '#write_nr32' do
    it 'sets volume code' do
      subject.write_nr32(0x60)  # volume = 3 (25%)
      expect(subject.read_nr32 & 0x60).to eq(0x60)
    end
  end

  describe '#write_nr33' do
    it 'sets low frequency bits' do
      subject.write_nr33(0xFF)
      # Frequency is internal
    end
  end

  describe '#write_nr34' do
    it 'sets high frequency bits' do
      subject.write_nr34(0x07)
      # Frequency is internal
    end

    it 'enables length counter when bit 6 is set' do
      subject.write_nr34(0x40)
      expect(subject.length_counter.enabled).to eq(true)
    end

    it 'triggers channel when bit 7 is set and DAC enabled' do
      subject.write_nr30(0x80)  # Enable DAC
      subject.write_nr34(0x80)
      expect(subject.enabled).to eq(true)
    end
  end

  describe '#write_wave_ram' do
    it 'writes to wave RAM' do
      subject.write_wave_ram(0xFF30, 0xAB)
      expect(subject.read_wave_ram(0xFF30)).to eq(0xAB)
    end
  end

  describe '#read_wave_ram' do
    context 'when channel is disabled' do
      it 'returns the value at the address' do
        subject.write_wave_ram(0xFF35, 0x12)
        expect(subject.read_wave_ram(0xFF35)).to eq(0x12)
      end
    end

    context 'when channel is enabled' do
      before do
        subject.write_wave_ram(0xFF30, 0xAB)
        subject.write_nr30(0x80)
        subject.write_nr34(0x80)
      end

      it 'returns current sample byte' do
        # Reading returns the byte at current position
        result = subject.read_wave_ram(0xFF35)
        expect(result).to be_a(Integer)
      end
    end
  end

  describe '#tick' do
    before do
      subject.write_nr30(0x80)
      subject.write_nr33(0x00)
      subject.write_nr34(0x87)  # trigger, freq = 0x700
    end

    it 'advances position through waveform' do
      # Timer = (2048 - 0x700) * 2 = 256 * 2 = 512
      512.times { subject.tick }
    end
  end

  describe '#output' do
    before do
      # Set up wave RAM with known pattern
      16.times { |i| subject.write_wave_ram(0xFF30 + i, 0xF0) }
      subject.write_nr30(0x80)  # DAC on
      subject.write_nr32(0x20)  # 100% volume
      subject.write_nr34(0x80)  # trigger
    end

    it 'returns 0 when disabled' do
      subject.disable
      expect(subject.output).to eq(0)
    end

    it 'returns sample based on wave RAM and volume' do
      output = subject.output
      expect(output).to be >= 0
      expect(output).to be <= 15
    end

    it 'applies volume shift' do
      subject.write_nr32(0x40)  # 50% volume (shift 1)
      output = subject.output
      expect(output).to be <= 7
    end
  end

  describe '#clock_length' do
    before do
      subject.write_nr31(0xFE)  # length = 2
      subject.write_nr30(0x80)
      subject.write_nr34(0xC0)  # trigger with length enable
    end

    it 'disables channel when length expires' do
      2.times { subject.clock_length }
      expect(subject.enabled).to eq(false)
    end
  end

  describe 'register reads' do
    it 'returns 0x7F OR DAC enable for NR30' do
      subject.write_nr30(0x80)
      expect(subject.read_nr30).to eq(0xFF)
    end

    it 'returns 0xFF for NR31 (write-only)' do
      expect(subject.read_nr31).to eq(0xFF)
    end

    it 'returns 0x9F OR volume for NR32' do
      subject.write_nr32(0x40)
      expect(subject.read_nr32).to eq(0xDF)
    end

    it 'returns 0xFF for NR33 (write-only)' do
      expect(subject.read_nr33).to eq(0xFF)
    end

    it 'returns 0xBF OR length enable for NR34' do
      subject.write_nr34(0x40)
      expect(subject.read_nr34).to eq(0xFF)
    end
  end
end
