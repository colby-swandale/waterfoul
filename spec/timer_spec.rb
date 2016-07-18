require 'spec_helper'

describe Waterfoul::Timer do
  subject { Waterfoul::Timer.new }
  before { $mmu = Waterfoul::MMU.new }

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
