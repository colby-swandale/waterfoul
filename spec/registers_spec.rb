require 'spec_helper'

describe Waterfoul::CPU do
  subject { Waterfoul::CPU.new }

  [[:a, :f], [:b, :c], [:d, :e], [:h, :l]].each do |i|
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
