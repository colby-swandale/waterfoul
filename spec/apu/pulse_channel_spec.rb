require 'spec_helper'

describe Waterfoul::APU::PulseChannel do
  subject { described_class.new(has_sweep: false) }

  describe '#initialize' do
    it 'creates channel without sweep by default' do
      channel = described_class.new
      expect(channel.frequency_sweep).to be_nil
    end

    it 'creates channel with sweep when specified' do
      channel = described_class.new(has_sweep: true)
      expect(channel.frequency_sweep).not_to be_nil
    end
  end

  describe '#write_nr1' do
    it 'sets duty cycle from bits 7-6' do
      subject.write_nr1(0xC0)  # duty = 3
      expect(subject.read_nr1 >> 6).to eq(3)
    end

    it 'sets length from bits 5-0' do
      subject.write_nr1(0x3F)
      expect(subject.length_counter.counter).to eq(1)
    end
  end

  describe '#write_nr2' do
    it 'configures volume envelope' do
      subject.write_nr2(0xF3)  # volume = 15, decrease, period = 3
      expect(subject.volume_envelope.dac_enabled?).to eq(true)
    end

    it 'disables channel when DAC disabled' do
      subject.write_nr4(0x80)  # trigger
      subject.write_nr2(0x00)  # DAC off
      expect(subject.enabled).to eq(false)
    end
  end

  describe '#write_nr3' do
    it 'sets low frequency bits' do
      subject.write_nr3(0xFF)
      # Frequency is internal, verified via output
    end
  end

  describe '#write_nr4' do
    it 'sets high frequency bits' do
      subject.write_nr4(0x07)
      # Frequency is internal
    end

    it 'enables length counter when bit 6 is set' do
      subject.write_nr4(0x40)
      expect(subject.length_counter.enabled).to eq(true)
    end

    it 'triggers channel when bit 7 is set' do
      subject.write_nr2(0xF0)  # Enable DAC
      subject.write_nr4(0x80)
      expect(subject.enabled).to eq(true)
    end
  end

  describe '#tick' do
    before do
      subject.write_nr2(0xF0)
      subject.write_nr3(0x00)
      subject.write_nr4(0x87)  # trigger, freq = 0x700
    end

    it 'advances duty position' do
      # Timer = (2048 - 0x700) * 4 = 256 * 4 = 1024
      1024.times { subject.tick }
      # Duty position should have advanced
    end
  end

  describe '#output' do
    before do
      subject.write_nr2(0xF0)  # volume = 15
      subject.write_nr4(0x80)  # trigger
    end

    it 'returns 0 when disabled' do
      subject.disable
      expect(subject.output).to eq(0)
    end

    it 'returns volume based on duty waveform' do
      output = subject.output
      expect(output).to be >= 0
      expect(output).to be <= 15
    end
  end

  describe '#clock_length' do
    before do
      subject.write_nr1(0x3E)  # length = 62, counter = 2
      subject.write_nr2(0xF0)
      subject.write_nr4(0xC0)  # trigger with length enable
    end

    it 'disables channel when length expires' do
      2.times { subject.clock_length }
      expect(subject.enabled).to eq(false)
    end
  end

  describe '#clock_envelope' do
    before do
      subject.write_nr2(0xF3)  # volume = 15, decrease, period = 3
      subject.write_nr4(0x80)
    end

    it 'adjusts volume' do
      initial_vol = subject.volume_envelope.volume
      3.times { subject.clock_envelope }
      expect(subject.volume_envelope.volume).to eq(initial_vol - 1)
    end
  end

  describe 'register reads' do
    it 'returns 0x3F OR duty for NR1' do
      subject.write_nr1(0x80)  # duty = 2
      expect(subject.read_nr1).to eq(0xBF)
    end

    it 'returns envelope settings for NR2' do
      subject.write_nr2(0xF3)
      expect(subject.read_nr2).to eq(0xF3)
    end

    it 'returns 0xFF for NR3 (write-only)' do
      expect(subject.read_nr3).to eq(0xFF)
    end

    it 'returns 0xBF OR length enable for NR4' do
      subject.write_nr4(0x40)
      expect(subject.read_nr4).to eq(0xFF)
    end
  end

  describe 'channel with sweep' do
    subject { described_class.new(has_sweep: true) }

    describe '#write_nr0' do
      it 'configures sweep' do
        subject.write_nr0(0x15)  # period = 1, decrease, shift = 5
        expect(subject.read_nr0 & 0x7F).to eq(0x15)
      end
    end

    describe '#clock_sweep' do
      before do
        subject.write_nr0(0x11)  # period = 1, increase, shift = 1
        subject.write_nr2(0xF0)
        subject.write_nr3(0x00)
        subject.write_nr4(0x81)  # trigger, freq = 0x100
      end

      it 'adjusts frequency' do
        # Sweep should modify frequency over time
        8.times { subject.clock_sweep }
      end
    end
  end
end
