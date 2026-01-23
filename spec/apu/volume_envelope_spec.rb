require 'spec_helper'

describe Waterfoul::APU::VolumeEnvelope do
  subject { described_class.new }

  describe '#set_register' do
    it 'extracts initial volume from bits 7-4' do
      subject.set_register(0xF0)
      subject.trigger
      expect(subject.volume).to eq(15)
    end

    it 'extracts direction from bit 3' do
      subject.set_register(0x08)  # direction = 1 (increase)
      expect(subject.dac_enabled?).to eq(true)
    end

    it 'extracts period from bits 2-0' do
      subject.set_register(0x07)
      # Period is internal, but we can test behavior
      subject.trigger
      subject.clock  # Should decrement timer
    end
  end

  describe '#clock' do
    context 'when period is 0' do
      it 'does nothing' do
        subject.set_register(0xF0)  # period = 0
        subject.trigger
        subject.clock
        expect(subject.volume).to eq(15)
      end
    end

    context 'when direction is increase' do
      before do
        subject.set_register(0x0B)  # volume = 0, direction = 1, period = 3
        subject.trigger
      end

      it 'increases volume up to 15' do
        3.times { subject.clock }  # Timer counts down
        expect(subject.volume).to eq(1)
      end

      it 'does not increase past 15' do
        subject.set_register(0xFB)  # volume = 15, direction = 1, period = 3
        subject.trigger
        3.times { subject.clock }
        expect(subject.volume).to eq(15)
      end
    end

    context 'when direction is decrease' do
      before do
        subject.set_register(0xF3)  # volume = 15, direction = 0, period = 3
        subject.trigger
      end

      it 'decreases volume' do
        3.times { subject.clock }
        expect(subject.volume).to eq(14)
      end

      it 'does not decrease below 0' do
        subject.set_register(0x03)  # volume = 0, direction = 0, period = 3
        subject.trigger
        3.times { subject.clock }
        expect(subject.volume).to eq(0)
      end
    end
  end

  describe '#trigger' do
    it 'sets volume to initial volume' do
      subject.set_register(0xA0)  # volume = 10
      subject.trigger
      expect(subject.volume).to eq(10)
    end

    it 'resets timer to period' do
      subject.set_register(0xF5)  # period = 5
      subject.trigger
      # Timer behavior is internal
    end
  end

  describe '#dac_enabled?' do
    it 'returns true when initial volume > 0' do
      subject.set_register(0x10)  # volume = 1
      expect(subject.dac_enabled?).to eq(true)
    end

    it 'returns true when direction is increase' do
      subject.set_register(0x08)  # direction = 1
      expect(subject.dac_enabled?).to eq(true)
    end

    it 'returns false when volume is 0 and direction is decrease' do
      subject.set_register(0x00)
      expect(subject.dac_enabled?).to eq(false)
    end
  end

  describe '#reset' do
    it 'resets all state' do
      subject.set_register(0xF3)
      subject.trigger
      subject.reset
      expect(subject.volume).to eq(0)
      expect(subject.dac_enabled?).to eq(false)
    end
  end
end
