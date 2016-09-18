require 'spec_helper'

describe Waterfoul::CPU do
  subject { Waterfoul::CPU.new }

  describe '#af=' do
    it 'doesnt overwrite the F register' do
      subject.af = 0x101
      expect(subject.f).to eq 0
    end

    it 'writes values into A register' do
      subject.af = 0x101
      expect(subject.a).to eq 0x1
    end
  end

  describe '#af' do
    it 'pairs the A, F register to form a 16 bit register' do
      subject.set_register :a, 0x5
      subject.set_register :f, 0x3
      expect(subject.af).to eq 0x503
    end
  end

  [[:b, :c], [:d, :e], [:h, :l]].each do |i|
    read_register_method = i.join
    write_register_method = i.join + '='

    describe "##{write_register_method}" do
      it "pairs the #{i[0]}, #{i[1]} register to form a 16bit register" do
        subject.public_send write_register_method, 0x501
        expect(subject.public_send(i[0])).to eq 0x5
        expect(subject.public_send(i[1])).to eq 0x1
      end
    end

    describe "##{read_register_method}" do
      it "pairs the #{i[0]}, #{i[1]} register to form a 16bit register" do
        subject.set_register i[0], 0x5
        subject.set_register i[1], 0x3
        expect(subject.public_send(read_register_method)).to eq 0x503
      end
    end
  end
end
