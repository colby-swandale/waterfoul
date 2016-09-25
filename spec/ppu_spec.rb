require 'spec_helper'

describe Waterfoul::PPU do
  before { $mmu = Waterfoul::MMU.new }
  subject { Waterfoul::PPU.new }

  # enable screen for all specs
  before { $mmu.write_byte 0xFF40, 0x80 }

  describe '#initialize' do
    it 'initializes an empty framebuffer' do
      expect(subject.framebuffer).to_not be_nil
    end
  end

  describe 'vram' do
    before { subject.mode = Waterfoul::PPU::VRAM_SCANLINE_TIME }
    before { subject.modeclock = Waterfoul::PPU::VRAM_SCANLINE_TIME }

    it 'updates STAT register with HBLANK mode' do
      subject.step
      stat_mode = $mmu.read_byte(0xFF41) & 0x3
      expect(stat_mode).to eq 0
    end
  end

  describe 'oam' do
    before { subject.mode = Waterfoul::PPU::OAM_READ_STATE }
    before { subject.modeclock = Waterfoul::PPU::OAM_SCANLINE_TIME }

    it 'sets mode to vram' do
      subject.step
      expect(subject.mode).to eq Waterfoul::PPU::VMRAM_READ_STATE
    end

    it 'updates STAT register with VRAM mode' do
      subject.step
      stat_mode = $mmu.read_byte(0xFF41) & 0x3
      expect(stat_mode).to eq 3
    end
  end

  describe 'hblank' do
    before { subject.mode = Waterfoul::PPU::H_BLANK_STATE }
    before { subject.modeclock = Waterfoul::PPU::H_BLANK_TIME }

    it 'sets the new line' do
      subject.step
      expect($mmu.read_byte(0xFF44)).to eq 0x1
    end

    it 'sets OAM mode on STAT register' do
      subject.step
      stat_mode = $mmu.read_byte(0xFF41) & 0x3
      expect(stat_mode).to eq 2
    end

    context 'when on line 143' do
      before { $mmu.write_byte 0xFF44, 143 }
      it 'changes to VBLANK mode' do
        subject.step
        expect(subject.mode).to eq Waterfoul::PPU::V_BLANK_STATE
      end

      it 'performs a VBLANK interrupt' do
        expect(Waterfoul::Interrupt).to receive(:request_interrupt).with(Waterfoul::Interrupt::INTERRUPT_VBLANK)
        subject.step
      end

      it 'enables vblank' do
        subject.step
        expect(subject.vblank?).to eq true
      end

      it 'sets VBLANK mode in STAT register' do
        subject.step
        stat_mode = $mmu.read_byte(0xFF41) & 0x3
        expect(stat_mode).to eq 1
      end
    end
  end
end
