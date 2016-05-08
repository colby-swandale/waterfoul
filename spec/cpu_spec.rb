require 'spec_helper'
require 'byebug'
describe Waterfoul::CPU do
  before { $mmu = Waterfoul::MMU.new }
  subject { Waterfoul::CPU.new }

  describe '#step' do
    context 'when instruction is NOP' do
      before { expect($mmu).to receive(:read_byte).and_return 0x00 }
      it 'increments the program counter each step' do
        expect { subject.step }.to change { subject.pc }.by 1
      end
    end

    context 'when instruction is RRCA' do
      before { expect($mmu).to receive(:read_byte).and_return 0x0F }

      it 'calls next instruction' do
        expect(subject).to receive(:rrca)
        subject.step
      end
    end
  end

  describe '#pending_interupt' do

  end

  describe 'halt' do
    before { subject.halt }
    context 'without any interupts pending' do
    end

    context 'with interupts pending' do
    end
  end
end
