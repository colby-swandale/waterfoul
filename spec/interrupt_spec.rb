require 'spec_helper'

describe Waterfoul::Interrupt do
  before :each do
    $mmu = Waterfoul::MMU.new
  end

  subject { described_class }

  describe '.request_interupt' do
    context 'with INTERRUPT_VBLANK interrupt' do
      it 'sets bit for VBLANK interupt in IF register' do
        subject.request_interrupt Waterfoul::Interrupt::INTERRUPT_JOYPAD
        expect($mmu[0xFF0F]).to eq 0x10
      end
    end

    context 'with INTERRUPT_TIMER set' do
      it 'sets bit for timer interrupt in IF register' do
        subject.request_interrupt Waterfoul::Interrupt::INTERRUPT_TIMER
        expect($mmu[0xFF0F]).to eq 0x4
      end
    end
  end

  describe '.pending_interrupt' do
    context 'when bit 2 of IE and IF register is set' do
      before { $mmu[0xFF0F] = 0x4 }
      before { $mmu[0xFFFF] = 0x4 }
      it 'marks timer interrupt as pending' do
        expect(subject.pending_interrupt).to eq Waterfoul::Interrupt::INTERRUPT_TIMER
      end
    end

    context 'when bit 2 of IE register is 0' do
      before { $mmu[0xFF0F] = 0x4 }
      before { $mmu[0xFFFF] = 0x0 }

      it 'responds with no interrupts pending' do
        expect(subject.pending_interrupt).to eq Waterfoul::Interrupt::INTERRUPT_NONE
      end
    end

    context 'when 2 interrupts are pending' do
      before { $mmu[0xFF0F] = 0x3 }
      before { $mmu[0xFFFF] = 0xFF }

      it 'responds with higher priority interrupt' do
        expect(subject.pending_interrupt).to eq Waterfoul::Interrupt::INTERRUPT_VBLANK
      end
    end
  end
end
