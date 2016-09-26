require 'spec_helper'

describe Waterfoul::CPU do
  before { $mmu = Waterfoul::MMU.new }
  subject { Waterfoul::CPU.new }

  describe '#stop_0' do
    it 'sets stop flag' do
      subject.stop_0
      expect(subject.stop).to eq 1
    end
  end

  describe '#halt' do
    it 'sets the halt flag' do
      subject.halt
      expect(subject.halt).to eq true
    end
  end

  describe '#di' do
    it 'resets the interupt flag' do
      subject.di
      expect(subject.ime).to eq false
    end
  end

  describe 'prefix_cb' do
    it 'increments pc by 1' do
      subject.prefix_cb
      expect(subject.pc).to eq 1
    end
  end

  describe '#ei' do
    it 'sets the interupt flag' do
      subject.ei
      expect(subject.ime).to eq true
    end
  end
end
