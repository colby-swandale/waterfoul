require 'spec_helper'
require 'byebug'
describe Waterfoul::CPU do
  before { $mmu = Waterfoul::MMU.new }
  subject { Waterfoul::CPU.new }

  describe '#serve_interrupt' do
    before { $mmu[0x0] = 0x0 } # NOP Instruction
    before { $mmu[0xFFFF] = 0xFF } # Enable All Interrupts

    context 'when timer interrupt' do
      before { $Mmu[0xFF06] = 0x4 }
    end

    context 'when no interrupt to serve' do
      it 'does not move the program counter' do
        subject.step
        expect(subject.pc).to eq 0x1
      end

      it 'does not push onto the stack' do
        expect { subject.step }.to_not change { subject.sp }
      end
    end
  end

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
