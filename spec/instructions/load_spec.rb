require 'spec_helper'

describe Waterfoul::CPU do
  before :each do
    $mmu = double :mmu
  end

  subject { Waterfoul::CPU.new }

  describe '#ld_bc_a' do
    let(:store_loc) { 0x8FFF }
    before { subject.set_register :bc, store_loc }
    before { subject.set_register :a, 0x64 }

    it 'puts A register into (HL)' do
      expect($mmu).to receive(:write_byte).with(store_loc, 0x64)
      subject.ld_bc_a
    end
  end

  [:b, :c, :d, :e, :a].each do |i|
    method = "ld_#{i}_hl"
    describe "##{method}" do
      before { allow($mmu).to receive(:read_byte).and_return(0x12) }
      it "loads value at (HL) into #{i} register" do
        subject.public_send method
        expect(subject.public_send(i)).to eq 0x12
      end
    end
  end

  describe '#ld_h_hl' do
    before { allow($mmu).to receive(:read_byte).and_return(0x15) }
    it 'loads value at (HL) into H register' do
      subject.ld_h_hl
      expect(subject.h).to eq 0x15
    end
  end

  describe '#ld_h_l' do
    before { allow($mmu).to receive(:read_byte).and_return(0x65) }
    it 'loads value at (HL) into L register' do
      subject.ld_l_hl
      expect(subject.l).to eq 0x65
    end
  end

  describe '#ld_dc_a' do
    before { subject.set_register :c, 0x12 }
    before { subject.set_register :a, 0x15 }
    it 'writes A register to 0xFF00 + (C)' do
      expect($mmu).to receive(:write_byte).with(0xFF12, 0x15)
      subject.ld_dc_a
    end
  end

  describe '#ld_a_dc' do
    before { subject.set_register :c, 0x12 }
    before { allow($mmu).to receive(:read_byte).and_return(0x16) }
    it 'reads byte from 0xFF00 + (C) into A register' do
      subject.ld_a_dc
      expect(subject.a).to eq 0x16
    end
  end

  describe '#ldh_a_a8' do
    before { allow($mmu).to receive(:read_byte).and_return(0x15) }
    it 'loads value in memory at 0xFF00 + a8 from memory into A register' do
      expect($mmu).to receive(:read_byte).with(0xFF15)
      subject.ldh_a_a8
    end
  end

  describe '#ldh_a8_a' do
    before { subject.set_register :a, 0x51 }
    before { allow($mmu).to receive(:read_byte).and_return(0x65) }
    it 'writes A register to 0xFF00 + a8' do
      expect($mmu).to receive(:write_byte).with(0xFF65, 0x51)
      subject.ldh_a8_a
    end
  end

  describe '#ld_hl_sp_r8' do
  end

  describe '#ld_a16_sp' do
    before { subject.set_register :sp, 0x12D5 }
    before { allow($mmu).to receive(:read_word).and_return(0x1BF2) }
    it 'stores SP into (a16)' do
      expect($mmu).to receive(:write_word).with(0x1BF2, 0x12D5)
      subject.ld_a16_sp
    end
  end

  describe '#ld_de_a' do
    let(:store_loc) { 0x8FFF }
    before { subject.set_register :a, 0x14 }
    before { subject.set_register :de, store_loc }

    it 'puts register A into memory at (DE)' do
      expect($mmu).to receive(:write_byte).with(store_loc, 0x14)
      subject.ld_de_a
    end
  end

  describe '#ld_hl_plus_a' do
    let(:store_loc) { 0x8FFF }
    before { subject.set_register :hl, store_loc }
    before { subject.set_register :a, 0x58 }

    it 'puts register A into memory at (HL)' do
      expect($mmu).to receive(:write_byte).with(store_loc, 0x58)
      subject.ld_hl_plus_a
    end

    it 'increments the HL register' do
      allow($mmu).to receive(:write_byte)
      subject.ld_hl_plus_a
      expect(subject.hl).to eq 0x9000
    end
  end

  describe '#ld_hl_minus_a' do
    let(:store_loc) { 0x8FFF }
    before { subject.set_register :hl, store_loc }
    before { subject.set_register :a, 0x12 }

    it 'puts register A into memory at (HL)' do
      expect($mmu).to receive(:write_byte).with(store_loc, 0x12)
      subject.ld_hl_minus_a
    end

    it 'decrements HL register' do
      allow($mmu).to receive(:write_byte)
      subject.ld_hl_minus_a
      expect(subject.hl).to eq 0x8FFE
    end
  end

  # LD (HL), n
  [:a, :b, :c, :d, :e].each do |i|
    method = "ld_hl_#{i}"
    describe "##{method}" do
      let(:store_loc) { 0x8FFF }
      let(:store_val) { 0xDE }
      before { subject.set_register :hl, store_loc }
      before { subject.set_register i, 0xDE }

      it "sets value of #{i.upcase} register into memory at HL" do
        expect($mmu).to receive(:write_byte).with(store_loc, 0xDE)
        subject.public_send method
      end
    end
  end

  describe '#ld_hl_l' do
    let(:store_loc) { 0x8FFF }
    before { subject.set_register :hl, store_loc }
    it 'writes value of L register into memory at HL' do
      expect($mmu).to receive(:write_byte).with(store_loc, 0xFF)
      subject.ld_hl_l
    end
  end

  describe '#ld_hl_h' do
    let(:store_loc) { 0x8FFF }
    before { subject.set_register :hl, store_loc }
    it 'writes value of H register into memory at HL' do
      expect($mmu).to receive(:write_byte).with(store_loc, 0x8F)
      subject.ld_hl_h
    end
  end

  # LD n,d8
  [:a, :b, :c, :d, :e, :h, :l].each do |i|
    method = "ld_#{i}_d8"
    describe "##{method}" do
      let(:store_val) { 0x8 }
      before { allow($mmu).to receive(:read_byte).and_return store_val }

      it "load value d8 into #{i} register" do
        subject.public_send method
        expect(subject.public_send(i)).to eq store_val
      end

      it 'increments the program counter' do
        subject.public_send method
        expect(subject.pc).to eq 1
      end
    end
  end

  # LD n,n
  [:a, :b, :c, :d, :e, :h, :l].each do |i|
    [:a, :b, :c, :d, :e, :h, :l].each do |v|

      method = "ld_#{i}_#{v}"
      describe "##{method}" do
        let(:store_val) { 0x14 }
        before { subject.set_register v, store_val }

        it "it loads value of #{v.upcase} register into #{i.upcase} register" do
          subject.public_send method
          expect(subject.public_send(i)).to eq store_val
        end
      end
    end
  end

  describe '#pop_af' do
    before { allow($mmu).to receive(:read_byte).and_return 0xB4 }
    it 'increments the stack pointer' do
      subject.pop_af
      expect(subject.sp).to eq 2
    end

    it 'loads AF register with value read from stack' do
      subject.pop_af
      expect(subject.af).to eq 0xB4B0
    end
  end

  # POP nn
  [:bc, :de, :hl].each do |i|
    method = "pop_#{i}"
    describe "##{method}" do
      before { allow($mmu).to receive(:read_byte).and_return 0xB }

      it 'increments the stack pointer' do
        subject.public_send method
        expect(subject.sp).to eq 2
      end

      it "loads #{i} register with value read from the stack" do
        subject.public_send method
        expect(subject.public_send(i)).to eq 0xB0B
      end
    end
  end

  describe '#push_af' do
    before { subject.set_register :sp, 0x8FFF }
    before { subject.set_register :af, 0x1E0 }
    before { allow($mmu).to receive(:write_byte) }

    it 'decrements the stack pointer' do
      subject.push_af
      expect(subject.sp).to eq 0x8FFD
    end

    it "pushes value of the AF register onto the stack" do
      expect(subject).to receive(:push_onto_stack).with(0x1E0)
      subject.push_af
    end
  end

  # PUSH nn
  [:bc, :de, :hl].each do |i|
    method = "push_#{i}"
    describe "##{method}" do
      before { subject.set_register :sp, 0x8FFF }
      before { subject.set_register i, 0x105 }
      before { allow($mmu).to receive(:write_byte) }

      it 'decrements the stack pointer' do
        subject.public_send method
        expect(subject.sp).to eq 0x8FFD
      end

      it "pushes value of the #{i} register onto the stack" do
        expect(subject).to receive(:push_onto_stack).with(subject.public_send(i))
        subject.public_send method
      end
    end
  end

  # LD nn,d16
  [:bc, :de, :hl, :sp].each do |i|
    method = "ld_#{i}_d16"
    describe "##{method}" do
      let(:store_val) { 0xFF12 }
      before { allow($mmu).to receive(:read_word).and_return(store_val) }

      it 'loads immediate value from memory into DE register' do
        subject.public_send method
        expect(subject.public_send(i)).to eq store_val 
      end

      it 'increments the program counter' do
        subject.public_send method
        expect(subject.pc).to eq 2
      end
    end
  end

  describe '#ld_a_a16' do
    before { allow($mmu).to receive(:read_word).and_return(0xF125) }
    it 'loads byte from immediate value in memory' do
      expect($mmu).to receive(:read_byte).with(0xF125)
      subject.ld_a_a16
    end

    it 'increments the PC' do
      allow($mmu).to receive(:read_byte)
      subject.ld_a_a16
      expect(subject.pc).to eq 2
    end
  end

  describe '#ld_a_bc' do
    before { allow($mmu).to receive(:read_byte).and_return(0x12) }
    it 'loads value at (BC) into A register' do
      subject.ld_a_bc
      expect(subject.a).to eq 0x12
    end
  end

  describe '#ld_a_de' do
    before { allow($mmu).to receive(:read_byte).and_return(0xF1) }
    it 'loads value at (DE) into A register' do
      subject.ld_a_de
      expect(subject.a).to eq 0xF1
    end
  end

  describe '#ld_a_hl_plus' do
    before { allow($mmu).to receive(:read_byte).and_return(0xB7) }
    it 'loads value at (HL) into A register' do
      subject.ld_a_hl_plus
      expect(subject.a).to eq 0xB7
    end

    it 'increments HL register' do
      subject.ld_a_hl_plus
      expect(subject.hl).to eq 0x1
    end
  end

  describe '#ld_a_hl_minus' do
    before { subject.set_register :hl, 0x1 }
    before { allow($mmu).to receive(:read_byte).and_return(0x31) }

    it 'loads value at (HL) into A register' do
      subject.ld_a_hl_minus
      expect(subject.a).to eq 0x31
    end

    it 'decrements the HL register' do
      subject.ld_a_hl_minus
      expect(subject.hl).to eq 0
    end
  end

  describe '#ld_hl_d8' do
    before { allow($mmu).to receive(:read_byte).and_return(0x12) }
    before { subject.set_register :hl, 0x15 }
    it 'loads immediate value from memory into (HL)' do
      expect($mmu).to receive(:write_byte).with(0x15, 0x12)
      subject.ld_hl_d8
    end
  end



  describe "ld_a16_a" do
    let(:store_val) { 0x10 }
    before { subject.set_register :a, store_val }

    it 'loads value of register A into location from immediate value in memory' do
      expect($mmu).to receive(:read_word).and_return(0xB412)
      expect($mmu).to receive(:write_byte).with(0xB412, store_val)
      subject.ld_a16_a
    end

    it 'increments the program counter' do
      allow($mmu).to receive(:read_word)
      allow($mmu).to receive(:write_byte)
      subject.ld_a16_a
      expect(subject.pc).to eq 2
    end
  end

  describe "ld_hl_sp_r8" do
    # TODO
  end

  describe "ld_sp_hl" do
    let(:store_val) { 0x502 }
    before { subject.set_register :hl, store_val }

    it 'loads value of HL register into SP register' do
      subject.ld_sp_hl
      expect(subject.sp).to eq store_val
    end
  end
end
