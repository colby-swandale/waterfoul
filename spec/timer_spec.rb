require 'spec_helper'

describe Waterfoul::Timer do
  subject { Waterfoul::Timer.new }
  before { $mmu = Waterfoul::MMU.new }

  describe 'divider register' do
    it 'increments the divider register every 256 cycles' do
      subject.tick(256)
      expect($mmu[0xFF04]).to eq 1
    end
  end
end
