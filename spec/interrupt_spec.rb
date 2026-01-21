require 'spec_helper'

describe Waterfoul::Interrupt do
  before { $mmu = Waterfoul::MMU.new }
  subject { described_class }

  describe '.request_interrupt' do
    # Note: IF register (0xFF0F) upper 3 bits always read as 1 on real hardware
    # So reads return value | 0xE0

    context 'with INTERRUPT_VBLANK interrupt' do
      it 'sets bit 0 in IF register' do
        subject.request_interrupt Waterfoul::Interrupt::INTERRUPT_VBLANK
        expect($mmu[0xFF0F]).to eq 0xE1  # 0x01 | 0xE0
      end
    end

    context 'with INTERRUPT_LCDSTAT interrupt' do
      it 'sets bit 1 in IF register' do
        subject.request_interrupt Waterfoul::Interrupt::INTERRUPT_LCDSTAT
        expect($mmu[0xFF0F]).to eq 0xE2  # 0x02 | 0xE0
      end
    end

    context 'with INTERRUPT_TIMER interrupt' do
      it 'sets bit 2 in IF register' do
        subject.request_interrupt Waterfoul::Interrupt::INTERRUPT_TIMER
        expect($mmu[0xFF0F]).to eq 0xE4  # 0x04 | 0xE0
      end
    end

    context 'with INTERRUPT_SERIAL interrupt' do
      it 'sets bit 3 in IF register' do
        subject.request_interrupt Waterfoul::Interrupt::INTERRUPT_SERIAL
        expect($mmu[0xFF0F]).to eq 0xE8  # 0x08 | 0xE0
      end
    end

    context 'with INTERRUPT_JOYPAD interrupt' do
      it 'sets bit 4 in IF register' do
        subject.request_interrupt Waterfoul::Interrupt::INTERRUPT_JOYPAD
        expect($mmu[0xFF0F]).to eq 0xF0  # 0x10 | 0xE0
      end
    end

    context 'when multiple interrupts are requested' do
      it 'preserves existing interrupt flags' do
        subject.request_interrupt Waterfoul::Interrupt::INTERRUPT_VBLANK
        subject.request_interrupt Waterfoul::Interrupt::INTERRUPT_TIMER
        expect($mmu[0xFF0F]).to eq 0xE5  # (0x01 | 0x04) | 0xE0
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

      it 'responds with higher priority interrupt (VBlank)' do
        expect(subject.pending_interrupt).to eq Waterfoul::Interrupt::INTERRUPT_VBLANK
      end
    end

    context 'when Timer and Joypad are both pending' do
      before { $mmu[0xFF0F] = 0x14 }  # bits 2 and 4
      before { $mmu[0xFFFF] = 0xFF }

      it 'responds with Timer (higher priority than Joypad)' do
        expect(subject.pending_interrupt).to eq Waterfoul::Interrupt::INTERRUPT_TIMER
      end
    end

    context 'when only lower priority interrupt is enabled' do
      before { $mmu[0xFF0F] = 0x1F }  # all interrupts requested
      before { $mmu[0xFFFF] = 0x10 }  # only Joypad enabled

      it 'responds with Joypad' do
        expect(subject.pending_interrupt).to eq Waterfoul::Interrupt::INTERRUPT_JOYPAD
      end
    end
  end
end
