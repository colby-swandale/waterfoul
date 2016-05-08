require 'spec_helper'

describe Waterfoul::CPU do
  before do
    $mmu = double :mmu
  end

  subject { Waterfoul::CPU.new }

  # SWAP n
  [:b, :c, :d, :e, :h, :l, :a].each do |i|
    method = "swap_#{i}"
    describe "##{method}" do
      before { subject.set_register i, 0b1111_0000 }
      it 'swaps the lower nibble with the higher nibble' do
        subject.public_send method
        expect(subject.public_send(i)).to eq 0b0000_1111
      end
    end
  end

  # BIT n,n
  [:b, :c, :d, :e, :h, :l, :a].each do |i|
    (0..7).each do |v|
      method = "bit_#{v}_#{i}"
      describe "##{method}" do
        context 'when all register bits are set' do
          before { subject.set_register :f, 0x00 }
          before { subject.set_register i, 0xFF }
          it 'does not set the Z flag' do
            subject.public_send method
            expect(subject.f).to eq 0b0010_0000
          end
        end

        context 'when all register bits are reset' do
          before { subject.set_register :f, 0b1111_0000 }
          before { subject.set_register i, 0x00 }
          it 'sets the Z flag' do
            subject.public_send method
            expect(subject.f).to eq 0b1011_0000
          end
        end
      end
    end
  end

  # TODO BIT (HL),n

  # RES n,n
  [:b, :c, :d, :e, :h, :l, :a].each do |i|
    (0..7).each do |v|
      method = "res_#{v}_#{i}"
      describe "##{method}" do
        before { subject.set_register i, 0xFF }
        it "resets bit #{v} in #{i} register" do
          subject.public_send method
          bit = subject.public_send(i) >> v
          expect(bit & 1).to eq 0
        end
      end
    end
  end

  # TODO RES (HL), n

  [:b, :c, :d, :e, :h, :l, :a].each do |i|
    (0..7).each do |v|
      method = "set_#{v}_#{i}"
      describe "##{method}" do
        before { subject.set_register i, 0xFF }
        it "sets bit #{v} in #{i} register" do
          subject.public_send method
          bit = subject.public_send(i) >> v
          expect(bit & 1).to eq 1
        end
      end
    end
  end

  # TODO SET (HL), n
end
