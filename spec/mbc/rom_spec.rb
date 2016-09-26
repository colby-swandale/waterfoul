require 'spec_helper'

describe Waterfoul::MBC::ROM do

  let(:game_program) { Array.new 65_536, 0 }
  subject { Waterfoul::MBC::ROM.new game_program }

  describe '#[]' do
    before { game_program[0x151] = 0x51 }
    it 'reads byte at address from the game program' do
      expect(subject[0x151]).to eq 0x51
    end
  end

  describe '#[]=' do
    it 'stores byte in external ram' do
      subject[0xA001] = 0x8F
      expect(subject.ram[0x1]).to eq 0x8F
    end
  end
end
