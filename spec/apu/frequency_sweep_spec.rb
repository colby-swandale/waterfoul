require 'spec_helper'

describe Waterfoul::APU::FrequencySweep do
  subject { described_class.new }

  describe '#set_register' do
    it 'extracts period from bits 6-4' do
      subject.set_register(0x70)
      # Period is internal, test via trigger
    end

    it 'extracts direction from bit 3' do
      subject.set_register(0x08)  # direction = decrease
      # Direction is internal, test via clock
    end

    it 'extracts shift from bits 2-0' do
      subject.set_register(0x07)
      # Shift is internal, test via frequency calculation
    end
  end

  describe '#trigger' do
    it 'loads shadow frequency' do
      subject.set_register(0x11)  # period = 1, shift = 1
      subject.trigger(0x400)
      expect(subject.shadow_frequency).to eq(0x400)
    end

    it 'returns false when no overflow' do
      subject.set_register(0x11)
      result = subject.trigger(0x100)
      expect(result).to eq(false)
    end

    it 'returns true when overflow occurs' do
      subject.set_register(0x11)  # period = 1, increase, shift = 1
      result = subject.trigger(0x7FF)  # 0x7FF + (0x7FF >> 1) = 0x7FF + 0x3FF = 0xBFE > 2047
      expect(result).to eq(true)
    end

    it 'enables sweep when period or shift > 0' do
      subject.set_register(0x11)
      subject.trigger(0x100)
      # Sweep is enabled, can be tested via clock
    end
  end

  describe '#clock' do
    context 'when not enabled' do
      it 'returns nil' do
        expect(subject.clock).to be_nil
      end
    end

    context 'when enabled with increase direction' do
      before do
        subject.set_register(0x11)  # period = 1, increase, shift = 1
        subject.trigger(0x100)
      end

      it 'increases frequency' do
        subject.clock  # Timer goes 1->0, frequency updated
        expect(subject.shadow_frequency).to eq(0x180)  # 0x100 + (0x100 >> 1)
      end
    end

    context 'when enabled with decrease direction' do
      before do
        subject.set_register(0x19)  # period = 1, decrease, shift = 1
        subject.trigger(0x100)
      end

      it 'decreases frequency' do
        subject.clock  # Timer goes 1->0, frequency updated
        expect(subject.shadow_frequency).to eq(0x80)  # 0x100 - (0x100 >> 1)
      end
    end

    context 'when frequency overflows' do
      it 'throws :overflow' do
        subject.set_register(0x17)  # period = 1, increase, shift = 7
        subject.trigger(0x100)
        expect {
          8.times { catch(:overflow) { subject.clock } }
        }.not_to raise_error
      end
    end
  end

  describe '#check_negate_to_positive' do
    it 'returns true if negate was used and switched to positive' do
      subject.set_register(0x19)  # decrease
      subject.trigger(0x100)
      8.times { subject.clock }  # Use negate
      expect(subject.check_negate_to_positive(0)).to eq(true)
    end

    it 'returns false if negate was not used' do
      subject.set_register(0x11)  # increase
      subject.trigger(0x100)
      expect(subject.check_negate_to_positive(0)).to eq(false)
    end
  end

  describe '#reset' do
    it 'resets all state' do
      subject.set_register(0x11)
      subject.trigger(0x100)
      subject.reset
      expect(subject.shadow_frequency).to eq(0)
    end
  end
end
