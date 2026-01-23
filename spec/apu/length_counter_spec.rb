require 'spec_helper'

describe Waterfoul::APU::LengthCounter do
  subject { described_class.new(64) }

  describe '#set_length' do
    it 'sets counter to max minus value' do
      subject.set_length(10)
      expect(subject.counter).to eq(54)
    end

    it 'sets counter to max when value is 0' do
      subject.set_length(0)
      expect(subject.counter).to eq(64)
    end
  end

  describe '#clock' do
    context 'when disabled' do
      it 'does not decrement counter' do
        subject.set_length(10)
        subject.enabled = false
        subject.clock
        expect(subject.counter).to eq(54)
      end
    end

    context 'when enabled' do
      before do
        subject.set_length(10)
        subject.enabled = true
      end

      it 'decrements counter' do
        subject.clock
        expect(subject.counter).to eq(53)
      end

      it 'returns true when counter reaches zero' do
        subject.set_length(63)  # counter = 1
        subject.enabled = true
        expect(subject.clock).to eq(true)
      end

      it 'returns false when counter is not zero' do
        expect(subject.clock).to eq(false)
      end
    end

    context 'when counter is already zero' do
      it 'returns false' do
        subject.enabled = true
        expect(subject.clock).to eq(false)
      end
    end
  end

  describe '#trigger' do
    it 'reloads counter with max when counter is zero' do
      expect(subject.counter).to eq(0)
      subject.trigger
      expect(subject.counter).to eq(64)
    end

    it 'does not change counter when not zero' do
      subject.set_length(10)
      subject.trigger
      expect(subject.counter).to eq(54)
    end
  end

  describe '#reset' do
    it 'resets counter and enabled state' do
      subject.set_length(10)
      subject.enabled = true
      subject.reset
      expect(subject.counter).to eq(0)
      expect(subject.enabled).to eq(false)
    end
  end

  describe 'wave channel length counter' do
    subject { described_class.new(256) }

    it 'uses max length of 256' do
      subject.set_length(0)
      expect(subject.counter).to eq(256)
    end
  end
end
