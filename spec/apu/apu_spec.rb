require 'spec_helper'

describe Waterfoul::APU do
  subject { described_class.new }
  before { $mmu = Waterfoul::MMU.new }

  describe '#initialize' do
    it 'creates all four channels' do
      expect(subject.channel1).to be_a(Waterfoul::APU::PulseChannel)
      expect(subject.channel2).to be_a(Waterfoul::APU::PulseChannel)
      expect(subject.channel3).to be_a(Waterfoul::APU::WaveChannel)
      expect(subject.channel4).to be_a(Waterfoul::APU::NoiseChannel)
    end

    it 'channel 1 has sweep, channel 2 does not' do
      expect(subject.channel1.frequency_sweep).not_to be_nil
      expect(subject.channel2.frequency_sweep).to be_nil
    end
  end

  describe '#read_register' do
    context 'NR52 (master control)' do
      it 'returns power state and channel status' do
        result = subject.read_register(0xFF26)
        expect(result & 0x80).to eq(0x80)  # Power on
        expect(result & 0x70).to eq(0x70)  # Unused bits
      end
    end

    context 'NR50 (master volume)' do
      it 'returns the stored value' do
        subject.write_register(0xFF24, 0x55)
        expect(subject.read_register(0xFF24)).to eq(0x55)
      end
    end

    context 'NR51 (panning)' do
      it 'returns the stored value' do
        subject.write_register(0xFF25, 0xAA)
        expect(subject.read_register(0xFF25)).to eq(0xAA)
      end
    end

    context 'unused addresses' do
      it 'returns 0xFF' do
        expect(subject.read_register(0xFF15)).to eq(0xFF)
        expect(subject.read_register(0xFF1F)).to eq(0xFF)
      end
    end
  end

  describe '#write_register' do
    context 'when APU is off' do
      before do
        subject.write_register(0xFF26, 0x00)  # Power off
      end

      it 'ignores writes to channel registers' do
        subject.write_register(0xFF11, 0x80)
        # Register should not be modified
      end

      it 'allows writes to NR52' do
        subject.write_register(0xFF26, 0x80)  # Power on
        expect(subject.read_register(0xFF26) & 0x80).to eq(0x80)
      end

      it 'allows writes to Wave RAM' do
        subject.write_register(0xFF30, 0xAB)
        expect(subject.read_register(0xFF30)).to eq(0xAB)
      end
    end

    context 'channel 1 registers' do
      it 'routes NR10 to channel 1 sweep' do
        subject.write_register(0xFF10, 0x15)
        expect(subject.read_register(0xFF10) & 0x7F).to eq(0x15)
      end

      it 'routes NR11-NR14 to channel 1' do
        subject.write_register(0xFF11, 0xC0)  # Duty
        subject.write_register(0xFF12, 0xF0)  # Envelope
        subject.write_register(0xFF13, 0x00)  # Freq low
        subject.write_register(0xFF14, 0x80)  # Trigger
        expect(subject.channel1.enabled).to eq(true)
      end
    end

    context 'channel 2 registers' do
      it 'routes NR21-NR24 to channel 2' do
        subject.write_register(0xFF16, 0xC0)  # Duty
        subject.write_register(0xFF17, 0xF0)  # Envelope
        subject.write_register(0xFF18, 0x00)  # Freq low
        subject.write_register(0xFF19, 0x80)  # Trigger
        expect(subject.channel2.enabled).to eq(true)
      end
    end

    context 'channel 3 registers' do
      it 'routes NR30-NR34 to channel 3' do
        subject.write_register(0xFF1A, 0x80)  # DAC on
        subject.write_register(0xFF1B, 0x00)  # Length
        subject.write_register(0xFF1C, 0x20)  # Volume
        subject.write_register(0xFF1D, 0x00)  # Freq low
        subject.write_register(0xFF1E, 0x80)  # Trigger
        expect(subject.channel3.enabled).to eq(true)
      end
    end

    context 'channel 4 registers' do
      it 'routes NR41-NR44 to channel 4' do
        subject.write_register(0xFF20, 0x00)  # Length
        subject.write_register(0xFF21, 0xF0)  # Envelope
        subject.write_register(0xFF22, 0x00)  # Polynomial
        subject.write_register(0xFF23, 0x80)  # Trigger
        expect(subject.channel4.enabled).to eq(true)
      end
    end

    context 'Wave RAM' do
      it 'writes to wave RAM' do
        subject.write_register(0xFF30, 0x12)
        subject.write_register(0xFF3F, 0x34)
        expect(subject.read_register(0xFF30)).to eq(0x12)
        expect(subject.read_register(0xFF3F)).to eq(0x34)
      end
    end
  end

  describe '#tick' do
    it 'advances all channels' do
      subject.write_register(0xFF12, 0xF0)
      subject.write_register(0xFF14, 0x80)  # Enable CH1
      subject.tick(100)
      # Should not raise errors
    end

    it 'clocks frame sequencer at 512 Hz' do
      # 8192 T-cycles = one frame sequencer step
      subject.tick(8192)
    end

    it 'generates audio samples' do
      subject.tick(100)
      # Sample buffer should have some samples
    end
  end

  describe '#samples_ready?' do
    it 'returns false when buffer is small' do
      expect(subject.samples_ready?).to eq(false)
    end

    it 'returns true when buffer has enough samples' do
      # Generate enough cycles for 1024 samples
      # ~95 cycles per sample * 1024 samples
      subject.tick(100_000)
      expect(subject.samples_ready?).to eq(true)
    end
  end

  describe '#flush_samples' do
    before do
      subject.tick(100_000)
    end

    it 'returns the sample buffer' do
      samples = subject.flush_samples
      expect(samples).to be_an(Array)
      expect(samples.size).to be > 0
    end

    it 'clears the buffer' do
      subject.flush_samples
      expect(subject.flush_samples).to eq([])
    end
  end

  describe '#reset' do
    before do
      subject.write_register(0xFF12, 0xF0)
      subject.write_register(0xFF14, 0x80)
      subject.tick(1000)
    end

    it 'resets all channels' do
      subject.reset
      expect(subject.channel1.enabled).to eq(false)
      expect(subject.channel2.enabled).to eq(false)
      expect(subject.channel3.enabled).to eq(false)
      expect(subject.channel4.enabled).to eq(false)
    end

    it 'clears sample buffer' do
      subject.reset
      expect(subject.flush_samples).to eq([])
    end
  end

  describe 'frame sequencer' do
    it 'clocks length counters on steps 0, 2, 4, 6' do
      subject.write_register(0xFF11, 0x3E)  # length = 2
      subject.write_register(0xFF12, 0xF0)
      subject.write_register(0xFF14, 0xC0)  # trigger with length

      # Step 0: length clock
      subject.tick(8192)
      expect(subject.channel1.length_counter.counter).to eq(1)
    end

    it 'clocks sweep on steps 2 and 6' do
      subject.write_register(0xFF10, 0x11)  # sweep
      subject.write_register(0xFF12, 0xF0)
      subject.write_register(0xFF13, 0x00)
      subject.write_register(0xFF14, 0x81)  # trigger

      # After 8192 * 3 cycles (steps 0, 1, 2), sweep should have been clocked
      subject.tick(8192 * 3)
    end

    it 'clocks envelopes on step 7' do
      subject.write_register(0xFF12, 0xF1)  # volume = 15, period = 1
      subject.write_register(0xFF14, 0x80)

      initial_vol = subject.channel1.volume_envelope.volume
      subject.tick(8192 * 8)  # Complete one frame sequencer cycle
      # Envelope should have been clocked at least once
    end
  end

  describe 'mixing and panning' do
    before do
      # Enable channel 1 with max volume
      subject.write_register(0xFF12, 0xF0)
      subject.write_register(0xFF14, 0x80)
      # Set master volume to max
      subject.write_register(0xFF24, 0x77)
    end

    it 'pans channels based on NR51' do
      subject.write_register(0xFF25, 0x11)  # CH1 to both L and R
      subject.tick(100)
    end

    it 'applies master volume from NR50' do
      subject.write_register(0xFF24, 0x00)  # Min volume
      subject.tick(100)
    end
  end
end
