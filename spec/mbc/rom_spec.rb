require 'spec_helper'

describe Waterfoul::MBC::ROM do

  let(:game_program) { double :game_program }
  let(:eram) { double :eram }

  subject { Waterfoul::MBC::ROM.new game_program, eram }

  describe '#[]' do
    let(:addr) { 0xA1B }
    it 'reads byte at given addr' do
      expect(game_program).to receive(:[]).with(addr)
      subject[addr]
    end

    context 'reading from external address space' do
      let(:addr) { 0xA1FB }
      it 'reads byte from external memory' do
        expect(eram).to receive(:[]).with(addr)
        subject[addr]
      end

      context 'writing to addr 0x123' do
        let(:addr) { 0x1 }
        it 'raises an error writng to forbidden space' do
          allow(eram).to receive(:[]=)
          expect { subject[addr] = 5 }.to raise_error
        end
      end
    end
  end

  describe '#[]=' do
    it 'writes byte to external ram with 0xA000 offset' do
      expect(eram).to receive(:[]=).with(0x1BF, 5)
      subject[0xA1BF] = 5
    end
  end
end
