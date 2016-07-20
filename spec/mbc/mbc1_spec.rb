require 'spec_helper'

describe Waterfoul::MBC::MBC1 do
  let(:program) { double :program }
  subject { Waterfoul::MBC::MBC1.new program }

  describe '#[]' do
    context 'when reading at 0x0001' do
      it 'reads byte from bank 0' do
        expect(program).to receive(:[]).with(0x0001)
        subject[0x0001]
      end
    end

    context 'when reading at 0x4001' do
      it 'reads from bank 1' do
        expect(program).to receive(:[]).with(0x4001)
        subject[0x4001]
      end
    end
  end

  describe '#[]=' do
    context 'when writing to 0x1' do
      it 'enables the external ram' do
        subject[0x1] = 0xA
        expect(subject.ram_enabled).to eq true
      end
    end

    context 'when writing to 4001' do
      it 'sets rom bank from 5 bits' do
        subject[0x2000] = 0xFF
        expect(subject.rom_bank).to eq 0x1F
      end
    end

    context 'when writing to 0x4000' do
      context 'with mode set to 1' do
        before { subject[0x6000] = 0x1 }
        it 'sets ram bank' do
          subject[0x4000] = 0x3
          expect(subject.ram_bank).to eq 0x3
        end
      end

      context 'with mode set to 0' do
        before { subject[0x6000] = 0x0 }
        before { subject[0x2000] = 0x1F }
        it 'sets upper 3 bits of rom bank' do
          subject[0x4000] = 0x3
          expect(subject.rom_bank).to eq 0x7F
        end
      end
    end

    context 'when writing to 0xA001' do
      context 'when RAM is enabled' do
        before { subject[0x1] = 0xA }
        it 'saves the value to external memory' do
          subject[0xA001] = 0x1
          expect(subject[0xA001]).to eq 0x1
        end
      end

      context 'when ram is disabled' do
        it 'raises an error' do
          expect { subject[0xA001] = 0x1 }.to raise_error RuntimeError
        end
      end
    end

    context 'writing to 0x6001' do
      it 'sets the ROM mode to 1' do
        subject[0x6001] = 0x1
        expect(subject.mode).to eq 1
      end
    end
  end
end
