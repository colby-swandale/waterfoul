require 'spec_helper'

describe Waterfoul::MMU do
  subject { Waterfoul::MMU.new }

  describe '#write_byte' do
    context 'writing to 0xFFFFFF' do
      it 'raises an exception' do
        expect { subject.write_byte(0xFFFFFF, 0x1) }.to raise_error Waterfoul::MemoryOutOfBounds
      end
    end

    context 'when writing to -0x1' do
      it 'raises an exception' do
        expect { subject.write_byte(-0x1, 0x1) }.to raise_error Waterfoul::MemoryOutOfBounds
      end
    end
  end

  describe '#read_byte' do
    context 'reading from 0xFFFFFF' do
      it 'raises an exception' do
        expect { subject.read_byte(0xFFFFFF) }.to raise_error Waterfoul::MemoryOutOfBounds
      end
    end

    context 'reading from -0x1' do
      it 'raises an exception' do
        expect { subject.read_byte(-0x1) }.to raise_error Waterfoul::MemoryOutOfBounds
      end
    end
  end

  describe 'DIV register' do
    before { subject.write_byte 0xFF04, 0x25, hardware_operation: true }
    it 'resets when written to' do
      subject.write_byte 0xFF04, 0x35
      expect(subject.read_byte(0xFF04)).to eq 0
    end
  end

  describe '#read_word' do
    before do
      subject.write_byte 0xC001, 0x1
      subject.write_byte 0xC000, 0x1
    end

    it 'reads two bytes from memory into a word' do
      expect(subject.read_word(0xC000)).to eq 0x101
    end
  end

  describe '#write_word' do
    it 'writes 2 bytes into 2 1 byte parts' do
      subject.write_word 0xFF40, 0xFFAA
      expect(subject[0xFF40]).to eq 0xAA
      expect(subject[0xFF41]).to eq 0xFF
    end
  end
end
