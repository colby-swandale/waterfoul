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
        expect(subject.pc).to eq 0x51
      end

      it 'saves the current program counter onto the stack' do
        subject.step
        expect($mmu.read_word(0xFFFC)).to eq 0x101
      end
    end
  end

  describe '#step' do
    before { subject.set_register :pc, 0x101 }

    it 'increments the program counter' do
      subject.step
      expect(subject.pc).to eq 0x102
    end

    context 'when the CPU is halted' do
      before { subject.halt }

      it 'does not increment the PC' do
        subject.step
        expect(subject.pc).to eq 0x101
      end
    end

    it 'sets the instruction cycle time' do
      subject.step
      expect(subject.m).to eq 4
    end
  end
end
