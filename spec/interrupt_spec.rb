require 'spec_helper'

describe Waterfoul::Interrupt do
  before :each do
    $mmu = double :mmu
  end

  subject { described_class }

  describe '.request_interupt' do
    before { allow($mmu).to receive(:read_byte).and_return(0x0) }
    context 'with INTERRUPT_VBLANK interrupt' do
      it 'writes interupt value into IF register' do
        expect($mmu).to receive(:write_byte).with(0xFF0F, 0x10)
        subject.request_interupt Waterfoul::Interrupt::INTERRUPT_JOYPAD
      end
    end
  end

  describe '.serve_interrupt' do
    before { allow($mmu).to receive(:read_byte).with(0xFFFF).and_return(0xFF) } # enable all interrupts
    context 'with all interrupts requested' do
      before { allow($mmu).to receive(:read_byte).with(0xFF0F).and_return(0xFF) }
      it 'resets the vblank interrupt' do
        expect($mmu).to receive(:write_byte).with(0xFF0F, 0xFE)
        subject.serve_interrupt
      end
    end

    context' with only joypad interrupt enabled' do
      before { allow($mmu).to receive(:read_byte).with(0xFF0F).and_return(0x10) }
      it 'resets the joypad interrupt' do
        expect($mmu).to receive(:write_byte).with(0xFF0F, 0x0)
        subject.serve_interrupt
      end
    end
  end
end
