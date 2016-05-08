require 'spec_helper'

describe Waterfoul::CPU do
  before { $mmu = Waterfoul::MMU.new }
  subject { Waterfoul::CPU.new }

  describe '#rla' do
    before { subject.set_register :f, 0b0001_0000 }
    before { subject.set_register :a, 0b0111_0000 }

    it 'rotates A register left' do
      subject.rla
      expect(subject.a).to eq 0b1110_0001
    end

    it 'rotates A register through the carry flag' do
      subject.rla
      expect(subject.f).to eq 0b0000_0000
    end
  end

  describe '#rlca' do
    before { subject.set_register :f, 0b0000_0000 }
    before { subject.set_register :a, 0b1111_0000 }

    it 'rotates A register left' do
      subject.rlca
      expect(subject.a).to eq 0b1110_0001
    end

    it 'sets rotating bit to carry flag' do
      subject.rlca
      expect(subject.f).to eq 0b0001_0000
    end
  end

  describe '#rrca' do
    before { subject.set_register :f, 0b0001_0000 }
    before { subject.set_register :a, 0b1111_0001 }

    it 'rotates the A register right' do
      subject.rrca
      expect(subject.a).to eq 0b1111_1000
    end

    it 'sets rotating bit to the carry flag' do
      subject.rrca
      expect(subject.f).to eq 0b0001_0000
    end
  end

  describe '#rra' do
    before { subject.set_register :f, 0b0001_0000 }
    before { subject.set_register :a, 0b1111_0000 }

    it 'rotates A register right with carry bit' do
      subject.rra
      expect(subject.a).to eq 0b1111_1000
    end

    it 'sets new carry bit' do
      subject.rra
      expect(subject.f).to eq 0b0000_0000
    end
  end
end
