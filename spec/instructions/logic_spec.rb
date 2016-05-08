require 'spec_helper'

describe Waterfoul::CPU do
  subject { Waterfoul::CPU.new }
  before :each do
    $mmu = double :mmu
  end

  describe '#ccf' do
    context 'with carry flag set' do
      before { subject.set_c_flag }
      it 'resets the carry flag' do
        subject.ccf
        expect(subject.f).to eq 0b0000_0000
      end
    end

    context 'with carry flag reset' do
      before { subject.reset_c_flag }
      it 'sets the carry flag' do
        subject.ccf
        expect(subject.f).to eq 0b0001_0000
      end
    end
  end

  describe '#cpl' do
    before { subject.set_register :a, 0b0000_1111 }
    it 'flips all bits in the A register' do
      subject.cpl
      expect(subject.a).to eq 0b1111_0000
    end
  end

  describe '#scf' do
    it 'sets the carry flag' do
      subject.scf
      expect(subject.f).to eq 0b0001_0000
    end
  end

  # DEC n
  [:a, :b, :c, :d, :e, :h, :l].each do |i|
    method = "dec_#{i}"
    describe "##{method}" do
      before { subject.set_register i, 5 }

      it "decrements #{i.upcase} register" do
        subject.public_send method
        expect(subject.public_send(i)).to eq 4
      end

      it 'sets the zero flag' do
        subject.public_send method
        expect(subject.f).to eq 0b0100_0000
      end

      context 'when register is set to 0x01' do
        before { subject.set_register i, 0x1 }
        it 'sets Z status flag' do
          subject.public_send method
          expect(subject.f).to eq 0b1100_0000
        end
      end

      context 'when register is set to 0x00' do
        before { subject.set_register i, 0x00 }
        it "value is set to 0xFF" do
          subject.public_send method
          expect(subject.public_send(i)).to eq 0xFF
        end
      end
    end
  end

  # DEC nn
  [:bc, :de, :hl, :sp].each do |i|
    method = "dec_#{i}"
    describe "##{method}" do
      before { subject.public_send "#{i}=", 0xFFFF }
      it "decrements value in #{i.upcase}" do
        subject.public_send method
        expect(subject.public_send(i)).to eq 0xFFFE
      end

      context 'when register is set to 0x00' do
        before { subject.set_register i, 0x0 }
        it 'resets to 0xFFFF' do
          subject.public_send method
          expect(subject.public_send(i)).to eq 0xFFFF
        end
      end
    end
  end

  # INC nn
  [:bc, :de, :hl, :sp].each do |i|
    method = "inc_#{i}"
    describe "##{method}" do
      it "increments value in #{i.upcase}" do
        subject.public_send method
        expect(subject.public_send(i)).to eq 0x1
      end

      context 'register set to 0xFFFF' do
        before { subject.set_register i, 0xFFFF }
        it 'resets the register' do
          subject.public_send method
          expect(subject.public_send(i)).to eq 0x0
        end
      end
    end
  end

  # DEC (HL)
  describe '#dec__hl' do
    let(:mem_loc) { 0x8FFF }
    before { allow($mmu).to receive(:read_byte).and_return(0x12) }
    before { subject.set_register :hl, mem_loc }

    it 'decrements value in memory at HL' do
      expect($mmu).to receive(:write_byte).with(mem_loc, 0x11)
      subject.dec__hl
    end

    it 'sets N flag' do
      allow($mmu).to receive(:write_byte)
      subject.dec__hl
      expect(subject.f).to eq 0b0100_0000
    end
  end

  # INC (HL)
  describe '#inc__hl' do
    let(:mem_loc) { 0x8FFF }
    before { allow($mmu).to receive(:read_byte).and_return(0x15) }
    before { subject.set_register :hl, mem_loc }

    it 'increments value in memory at HL' do
      expect($mmu).to receive(:write_byte).with(mem_loc, 0x16)
      subject.inc__hl
    end
  end

  # INC n
  [:a, :b, :c, :d, :e, :h, :l].each do |i|
    method = "inc_#{i}"
    describe "##{method}" do
      it "increments #{i.upcase} register" do
        subject.public_send method
        expect(subject.public_send(i)).to eq 1
      end

      context 'when register value is 0xFF' do
        before { subject.set_register i, 0xFF }

        it 'resets to 0x00' do
          subject.public_send method
          expect(subject.public_send(i)).to eq 0x00
        end
      end
    end
  end

  describe '#add_hl_hl' do
    before { subject.set_register :hl, 0x122 }
    it 'adds HL to HL' do
      subject.add_hl_hl
      expect(subject.hl).to eq 0x244
    end

    context 'when set to 0xFFFF' do
      before { subject.set_register :hl, 0xFFFF }
      it 'handles overflow' do
        subject.add_hl_hl
        expect(subject.hl).to eq 0xFFFE
      end
    end
  end

  # ADD HL,nn
  [:bc, :de, :sp].each do |i|
    method = "add_hl_#{i}"
    describe "##{method}" do
      before { subject.set_register :hl, 0x112 }
      before { subject.set_register i, 0x534 }

      it "adds register #{i} to HL" do
        subject.public_send method
        expect(subject.hl).to eq 0x646
      end

      context 'registers set to 0xFFFF' do
        before { subject.set_register i, 0xFFFF }
        before { subject.set_register :hl, 0xFFFF }

        it 'handles overflow' do
          subject.public_send method
          expect(subject.hl).to eq 0xFFFE
        end
      end
    end
  end

  # ADD A,n
  [:b ,:c, :d, :e, :h, :l].each do |i|
    method = "add_a_#{i}"
    describe "##{method}" do
      before { subject.set_register :a, 0x1 }
      before { subject.set_register i, 0x1 }

      it "adds #{i.upcase} to A" do
        subject.public_send method
        expect(subject.a).to eq 0x2
      end

      context "when A and #{i} registes are set to 0xFF" do
        before { subject.set_register :a, 0xFF }
        before { subject.set_register i, 0x2 }

        it 'sets carry flag' do
          subject.public_send method
          expect(subject.f).to eq 0b0011_0000
        end

        it 'masks result to single byte' do
          subject.public_send method
          expect(subject.a).to eq 0x1
        end
      end
    end
  end

  describe '#add_a_a' do
    before { subject.set_register :a, 0x2 }
    it 'adds A register to A register' do
      subject.add_a_a
      expect(subject.a).to eq 0x4
    end

    context 'set register to 0xFF' do
      before { subject.set_register :a, 0xFF }
      it 'equals 0xFE' do
        subject.add_a_a
        expect(subject.a).to eq 0xFE
      end

      it 'sets C + H flag' do
        subject.add_a_a
        expect(subject.f).to eq 0b0011_0000
      end
    end
  end

  describe '#add_a_hl' do
    let(:mem_loc) { 0x8FFF }

    before { subject.set_register :a, 0x1 }
    before { subject.set_register :hl, mem_loc }
    before { allow($mmu).to receive(:read_byte).and_return(0x2) }

    it 'adds immediate value from memory to A' do
      subject.add_a_hl
      expect(subject.a).to eq 0x3
    end

    context 'when additon results in carry' do
      before { subject.set_register :a, 0xFF }

      it 'equals 0x1' do
        subject.add_a_hl
        expect(subject.a).to eq 0x1
      end

      it 'sets carry flag' do
        subject.add_a_hl
        expect(subject.f).to eq 0b0011_0000
      end
    end
  end

  # ADC n
  [:b ,:c, :d, :e, :h, :l].each do |i|
    method = "adc_a_#{i}"
    describe "##{method}" do
      context "without carry set" do
        before { subject.reset_c_flag }
        before { subject.set_register :a, 0x1 }
        before { subject.set_register i, 0x2 }

        it "adds #{i.upcase} to A" do
          subject.public_send method
          expect(subject.a).to eq 0x3
        end
      end

      context 'with carry set' do
        before { subject.set_c_flag }
        before { subject.set_register i, 0x1 }
        before { subject.set_register :a, 0x1 }

        it "adds #{i.upcase} to A" do
          subject.public_send method
          expect(subject.a).to eq 0x3
        end
      end

      context 'when operation results in a carry' do
        before { subject.set_register :a, 0xFF }
        before { subject.set_register i, 0x5 }

        it 'sets carry flag' do
          subject.public_send method
          expect(subject.f).to eq 0b0001_0000
        end
      end
    end
  end

  describe '#adc_a_a' do
    context 'without carry set' do
      before { subject.set_register :a, 0x10 }
      it 'adds A to A' do
        subject.adc_a_a
        expect(subject.a).to eq 0x20
      end
    end

    context 'with carry set' do
      before { subject.set_c_flag }
      before { subject.set_register :a, 0x10 }
      it 'adds A to A with carry' do
        subject.adc_a_a
        expect(subject.a).to eq 0x21
      end
    end

    context 'when operation results in a carry' do
      before { subject.set_register :a, 0xFF }
      it 'sets carry flag' do
        subject.adc_a_a
        expect(subject.f).to eq 0b0001_0000
      end
    end
  end

  describe '#adc_a_hl' do
    before { expect($mmu).to receive(:read_byte).and_return 0x54 }

    context 'with carry set' do
      before { subject.set_c_flag }
      before { subject.set_register :a, 0x5 }

      it 'adds immediate value from memory to A register with carry' do
        subject.adc_a_hl
        expect(subject.a).to eq 0x5A
      end
    end

    context 'without carry set' do
      before { subject.set_register :a, 0x11 }

      it 'adds immediate value from memory to a' do
        subject.adc_a_hl
        expect(subject.a).to eq 0x65
      end
    end

    context 'when operation results in a carry' do
      before { subject.set_register :a, 0xFF }
      it 'sets carry flag' do
        subject.adc_a_hl
        expect(subject.f).to eq 0b0001_0000
      end
    end
  end

  # SUB n
  [:b ,:c, :d, :e, :h, :l].each do |i|
    method = "sub_#{i}"
    describe "##{method}" do
      before { subject.set_register :a, 0x55 }
      before { subject.set_register i, 0x51 }

      it "substracts #{i.upcase} from A" do
        subject.public_send method
        expect(subject.a).to eq 0x04
      end

      it 'sets C+N flag' do
        subject.public_send method
        expect(subject.f).to eq 0b0101_0000
      end
    end
  end

  describe '#sub_a' do
    before { subject.set_register :a, 0x55 }
    it 'subtracts A from A' do
      subject.sub_a
      expect(subject.a).to eq 0x00
    end
  end

  describe '#sub_hl' do
    before { subject.set_register :a, 0xFF }
    before { expect($mmu).to receive(:read_byte).and_return 0x51 }

    it 'subtracts immediate value from memory from A' do
      subject.sub_hl
      expect(subject.a).to eq 0xAE
    end

    it 'sets C+N flag' do
      subject.sub_hl
      expect(subject.f).to eq 0b0101_0000
    end
  end

  # SBC n
  [:b ,:c, :d, :e, :h, :l].each do |i|
    method = "sbc_a_#{i}"
    describe "##{method}" do
      before { subject.set_register :a, 0xFF }
      before { subject.set_register i, 0xF }

      it "subtracts #{i.upcase} from A" do
        subject.public_send method
        expect(subject.a).to eq 0xF0
      end

      it 'sets N flag' do
        subject.public_send method
        expect(subject.f).to eq 0b0100_0000
      end

      context 'with carry flag set' do
        before { subject.set_c_flag }
        it "subtracts #{i.upcase} and carry bit from A" do
          subject.public_send method
          expect(subject.a).to eq 0xEF
        end
      end

      context 'when result results in 0' do
        before { subject.set_register :a, 0xF }
        before { subject.set_register i, 0xF }

        it 'sets N+Z flag' do
          subject.public_send method
          expect(subject.f).to eq 0b1100_0000
        end
      end

      context 'when no borrow on bit 4' do
        before { subject.set_register :a, 0x2 }
        before { subject.set_register i, 0x1 }

        it 'sets H+N flag' do
          subject.public_send method
          expect(subject.f).to eq 0b0110_0000
        end
      end

      context 'when no borrow' do
        before { subject.set_register :a, 0x3 }
        before { subject.set_register i, 0xF }

        it 'sets C+N flag' do
          subject.public_send method
          expect(subject.f).to eq 0b0101_0000
        end
      end
    end
  end

  describe '#sbc_a_a' do
    before { subject.set_register :a, 0xFF }

    context 'when carry bit set' do
      before { subject.set_c_flag }
      it 'sets C+N flag' do
        subject.sbc_a_a
        expect(subject.f).to eq 0b0101_0000
      end

      it 'subtracts A from A + Carry bit' do
        subject.sbc_a_a
        expect(subject.a).to eq 0x1
      end
    end

    context 'with carry bit reset' do
      before { subject.reset_c_flag }
      it 'sets the Z+N flag with no carry flag' do
        subject.sbc_a_a
        expect(subject.f).to eq 0b1100_0000
      end

      it 'substracts A from A' do
        subject.sbc_a_a
        expect(subject.a).to eq 0x00
      end
    end
  end

  describe '#sbc_a_hl' do
    before { subject.set_register :a, 0xFF }
    before { allow($mmu).to receive(:read_byte).and_return(0xF) }

    it "subtracts (HL) from A" do
      subject.sbc_a_hl
      expect(subject.a).to eq 0xF0
    end

    it 'sets N flag' do
      subject.sbc_a_hl
      expect(subject.f).to eq 0b0100_0000
    end

    context 'with carry flag set' do
      before { subject.set_c_flag }
      it "subtracts (HL) and carry bit from A" do
        subject.sbc_a_hl
        expect(subject.a).to eq 0xEF
      end
    end

    context 'when result results in 0' do
      before { subject.set_register :a, 0xF }

      it 'sets N+Z flag' do
        subject.sbc_a_hl
        expect(subject.f).to eq 0b1100_0000
      end
    end

    context 'when no borrow on bit 4' do
      before { subject.set_register :a, 0x2 }
      before { allow($mmu).to receive(:read_byte).and_return(0x1) }

      it 'sets H+N flag' do
        subject.sbc_a_hl
        expect(subject.f).to eq 0b0110_0000
      end
    end

    context 'when no borrow' do
      before { subject.set_register :a, 0x3 }

      it 'sets C+N flag' do
        subject.sbc_a_hl
        expect(subject.f).to eq 0b0101_0000
      end
    end
  end

  # AND n
  [:b ,:c, :d, :e, :h, :l].each do |i|
    method = "and_#{i}"
    describe "##{i}" do
      before { subject.set_register :a, 0xF0 }
      before { subject.set_register i, 0xF0 }

      it "performs an AND #{i.upcase} with A" do
        subject.public_send method
        expect(subject.public_send(i)).to eq 0xF0
      end
    end
  end

  describe '#and_a' do
    before { subject.set_register :a, 0xFA }

    it 'performs an AND on A and A' do
      subject.and_a
      expect(subject.a).to eq 0xFA
    end
  end

  describe '#and_d8' do
    before { subject.set_register :f, 0b0101_0000 }
    before { subject.set_register :a, 0x99 }
    before { allow($mmu).to receive(:read_byte).and_return 0x51 }

    it 'performs an AND on value from memory and A' do
      subject.and_d8
      expect(subject.a).to eq 0x11
    end

    it 'resets N+C flag and sets H flag' do
      subject.and_d8
      expect(subject.f).to eq 0b0010_0000
    end
  end

  describe '#and_hl' do
    before { subject.set_register :f, 0b0101_0000 }
    before { subject.set_register :a, 0x99 }
    before { allow($mmu).to receive(:read_byte).and_return 0x51 }

    it 'performs an AND on value from memory and A' do
      subject.and_hl
      expect(subject.a).to eq 0x11
    end

    it 'resets N+C flag and sets H flag' do
      subject.and_hl
      expect(subject.f).to eq 0b0010_0000
    end
  end

  # XOR n
  [:b ,:c, :d, :e, :h, :l].each do |i|
    method = "xor_#{i}"
    describe "##{method}" do
      before { subject.set_register :f, 0b0111_0000 }
      before { subject.set_register :a, 0xFF }
      before { subject.set_register i, 0x5 }

      it "performs and XOR operation from #{i} to A" do
        subject.public_send method
        expect(subject.a).to eq 0xFA
      end

      it 'resets H+C+N flags' do
        subject.public_send method
        expect(subject.f).to eq 0x0
      end
    end
  end

  describe '#xor_a' do
    before { subject.set_register :f, 0b0111_0000 }
    before { subject.set_register :a, 0xFF }

    it 'performs XOR operation on A register' do
      subject.xor_a
      expect(subject.a).to eq 0x00
    end

    it 'resets H+C+N flags' do
      subject.xor_hl
      expect(subject.f).to eq 0x0
    end
  end

  describe '#xor_d8' do
    before { subject.set_register :f, 0b0111_0000 }
    before { allow($mmu).to receive(:read_byte).and_return 0x36 }
    before { subject.set_register :a, 0xFF }

    it 'performs XOR operation on immediate value from memory to A' do
      subject.xor_d8
      expect(subject.a).to eq 0xC9
    end

    it 'resets H+C+N flags' do
      subject.xor_d8
      expect(subject.f).to eq 0x0
    end
  end

  describe '#xor_hl' do
    before { subject.set_register :f, 0b0111_0000 }
    before { allow($mmu).to receive(:read_byte).and_return 0x36 }
    before { subject.set_register :a, 0xFF }

    it 'performs XOR operation on immediate value from memory to A' do
      subject.xor_hl
      expect(subject.a).to eq 0xC9
    end

    it 'resets H+C+N flags' do
      subject.xor_hl
      expect(subject.f).to eq 0x0
    end
  end

  # OR n
  [:b ,:c, :d, :e, :h, :l].each do |i|
    method = "or_#{i}"
    describe "##{method}" do
      before { subject.set_register :f, 0b0111_0000 }
      before { subject.set_register :a, 0xF0 }
      before { subject.set_register i, 0x0F }

      it "performs OR operation on #{i} and A" do
        subject.public_send method
        expect(subject.a).to eq 0xFF
      end

      it 'resets H+C+N flags' do
        subject.public_send method
        expect(subject.f).to eq 0x0
      end
    end
  end

  describe '#or_a' do
    before { subject.set_register :f, 0b0111_0000 }
    before { subject.set_register :a, 0xF0 }

    it 'performs OR operation on A' do
      subject.or_a
      expect(subject.a).to eq 0xF0
    end

    it 'resets H+C+N flags' do
      subject.or_a
      expect(subject.f).to eq 0x0
    end
  end

  describe '#or_d8' do
    before { subject.set_register :f, 0b0111_0000 }
    before { allow($mmu).to receive(:read_byte).and_return(0x0F) }
    before { subject.set_register :a, 0xF0 }

    it 'performs OR operation on immediate value from memory and A' do
      subject.or_d8
      expect(subject.a).to eq 0xFF
    end

    it 'resets H+C+N flags' do
      subject.or_d8
      expect(subject.f).to eq 0x0
    end
  end

  describe '#or_hl' do
    before { subject.set_register :f, 0b0111_0000 }
    before { allow($mmu).to receive(:read_byte).and_return(0x0F) }
    before { subject.set_register :a, 0xF0 }

    it 'performs OR operation on immediate value from memory and A' do
      subject.or_hl
      expect(subject.a).to eq 0xFF
    end

    it 'resets H+C+N flags' do
      subject.or_hl
      expect(subject.f).to eq 0x0
    end
  end

  # CP n
  [:b ,:c, :d, :e, :h, :l].each do |i|
    method = "cp_#{i}"
    describe "##{method}" do
      before { subject.set_register :a, 0xF }
      before { subject.set_register i, 0x1 }

      it 'does not alter A register' do
        subject.public_send method
        expect(subject.a).to eq 0xF
      end

      it 'sets N flag' do
        subject.public_send method
        expect(subject.f).to eq 0b0100_0000
      end

      context 'when operation results to 0' do
        before { subject.set_register i, 0xF }
        it 'sets the Z flag' do
          subject.public_send method
          expect(subject.f).to eq 0b1100_0000
        end
      end

      context 'when no borrow on bit 4' do
        before { subject.set_register :a, 0x3 }
        before { subject.set_register i, 0xFF }

        it 'sets the H flag' do
          subject.public_send method
          expect(subject.f).to eq 0b0111_0000
        end
      end

      context 'when no borrow occurs' do
        before { subject.set_register :a, 0xCF }
        before { subject.set_register i, 0xFD }

        it 'sets the C flag' do
          subject.public_send method
          expect(subject.f).to eq 0b0101_0000
        end
      end
    end
  end

  describe '#cp_a' do
    before { subject.set_register :a, 0xF }

    it 'sets Z+N flag' do
      subject.cp_a
      expect(subject.f).to eq 0b1100_0000
    end
  end

  describe '#cp_d8' do
    let(:pc) { 0x8FFF}
    before { subject.set_register :pc, pc }
    before { subject.set_register :a, 0xF }
    before { allow($mmu).to receive(:read_byte).and_return(0x3) }

    it 'does not alter A register' do
      expect { subject.cp_d8 }.to_not change { subject.a }
    end

    it 'sets N flag' do
      subject.cp_d8
      expect(subject.f).to eq 0b0100_0000
    end

    context 'when operation results to 0' do
      before { allow($mmu).to receive(:read_byte).and_return(0xF) }
      it 'sets N+Z flag' do
        subject.cp_d8
        expect(subject.f).to eq 0b1100_0000
      end
    end

    context 'when no borrow on bit 4' do
      before { subject.set_register :a, 0x3 }
      before { allow($mmu).to receive(:read_byte).and_return(0xFF) }

      it 'sets the H flag' do
        subject.cp_d8
        expect(subject.f).to eq 0b0111_0000
      end
    end

    context 'when no borrow occurs' do
      before { subject.set_register :a, 0xCF }
      before { allow($mmu).to receive(:read_byte).and_return(0xFD) }

      it 'sets the C flag' do
        subject.cp_d8
        expect(subject.f).to eq 0b0101_0000
      end
    end
  end

  describe '#cp_hl' do
    before { subject.set_register :a, 0x5 }
    before { allow($mmu).to receive(:read_byte).and_return(0x1) }

    it 'does not change A register' do
      expect { subject.cp_hl }.to_not change { subject.a }
    end

    it 'sets N flag' do
      subject.cp_hl
      expect(subject.f).to eq 0b0100_0000
    end

    context 'when operation results to 0' do
      before { allow($mmu).to receive(:read_byte).and_return(0x5) }
      it 'sets the N+Z flag' do
        subject.cp_hl
        expect(subject.f).to eq 0b1100_0000
      end
    end

    context 'when result first nibbles - carry is less then 0' do
      before { allow($mmu).to receive(:read_byte).and_return(0x5) }

      it 'sets the N+H flag' do
        subject.cp_hl
        expect(subject.f).to eq 0b0110_0000
      end
    end

    context 'when A register is less then the result' do
      before { subject.set_register :a, 0x3 }
      before { allow($mmu).to receive(:read_byte).and_return(0x4) }

      it 'sets the N+C flag' do
        subject.cp_hl
        expect(subject.f).to eq 0b0101_0000
      end
    end
  end
end
