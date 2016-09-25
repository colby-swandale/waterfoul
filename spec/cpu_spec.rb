require 'spec_helper'
describe Waterfoul::CPU do
  before { $mmu = Waterfoul::MMU.new }
  subject { Waterfoul::CPU.new }

  describe '#serve_interrupt' do
    before { subject.ei } # master interrupt enable
    before { $mmu.write_byte 0xFFFF, 0xFF } # enable all interrupts
    before { subject.set_register :sp, 0xFFFE }
    before { subject.set_register :pc, 0x101 }

    context 'when no interrupt to serve' do
      it 'does alter the execution path' do
        subject.step
        expect(subject.pc).to eq 0x102
      end

      it 'does not push anything onto the stack' do
        subject.step
        expect(subject.sp).to eq 0xFFFE
      end
    end

    context 'when timer interrupt is served' do
      before { $mmu.write_byte 0xFF0F, 0x4 } # request timer interrupt

      it 'sets the program counter to 0x50' do
        subject.step
        expect(subject.pc).to eq 0x50
      end

      it 'saves the current program counter onto the stack' do
        subject.step
        expect($mmu.read_word(0xFFFC)).to eq 0x101
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
