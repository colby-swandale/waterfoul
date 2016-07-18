require 'spec_helper'

describe Waterfoul::Timer do
  subject { Waterfoul::Timer.new }
  before { $mmu = Waterfoul::MMU.new }

  describe 'tima register' do
    context 'when tima is disabled' do
      before { $mmu.write_byte 0xFF07, 0b011 }
      it 'does not increment the counter register' do
        subject.tick(1024)
        expect($mmu[0xFF05]).to eq 0
      end
    end

    context 'when tima is enabled' do
      before { $mmu.write_byte 0xFF07, 0b111 }
      it 'increments the counter register' do
        subject.tick(256)
        expect($mmu[0xFF05]).to be > 0
      end
    end

    context 'with modulo set' do
      before { $mmu.write_byte 0xFF07, 0b111 }
      before { $mmu.write_byte 0xFF06, 0x25 }
      before { $mmu.write_byte 0xFF05, 0xFF }
      it 'resets counter regsiter to modulo value' do
        subject.tick(256)
        expect($mmu[0xFF05]).to eq 0x25
      end
    end
  end

  xdescribe 'timer interrupt' do
    context 'when counter timer overflows' do
      before { $mmu.write_byte 0xFF07, 0b111 }
      before { $mmu.write_byte 0xFF05, 0xFF }
      it 'triggers timer interrupt' do
        expect(Interrupt).to receive(:request_interrupt)
        subject.tick(256)
      end
    end
  end

  describe 'divider register' do
    it 'increments the divider register every 256 cycles' do
      subject.tick(256)
      expect($mmu[0xFF04]).to eq 1
    end

    context 'when DIV register is 255' do
      before { $mmu.write_byte 0xFF04, 0xFF, hardware_operation: true }
      it 'resets register to 0 on next increment' do
        subject.tick(256)
        expect($mmu[0xFF04]).to eq 0
      end
    end
  end
end
