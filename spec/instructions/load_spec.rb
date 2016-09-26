require 'spec_helper'

describe Waterfoul::CPU do
  before { $mmu = Waterfoul::MMU.new }
  subject { Waterfoul::CPU.new }

  before { subject.set_register :pc, 0x100 }
  before { subject.set_register :sp, 0x200 }

  describe '#ld_bc_a' do
    before { subject.set_register :bc, 0x100 }
    before { subject.set_register :a, 0x64 }

    it 'writes value of A register into (HL)' do
      subject.ld_bc_a
      expect($mmu.read_byte(0x100)).to eq 0x64
    end
  end

  [:b, :c, :d, :e, :a].each do |i|
    method = "ld_#{i}_hl"
    describe "##{method}" do
      before { subject.set_register :hl, 0x100 }
      before { $mmu.write_byte 0x100, 0x50 }

      it "loads value at (HL) into #{i} register" do
        subject.public_send method
        expect(subject.public_send(i)).to eq 0x50
      end
    end
  end

  describe '#ld_h_hl' do
    before { subject.set_register :hl, 0x100 }
    before { $mmu.write_byte 0x100, 0x65 }
    it 'loads value at (HL) into H register' do
      subject.ld_h_hl
      expect(subject.h).to eq 0x65
    end
  end

  describe '#ld_h_l' do
    before { subject.set_register :hl, 0x100 }
    before { $mmu.write_byte 0x100, 0xC1 }
    it 'loads value at (HL) into L register' do
      subject.ld_l_hl
      expect(subject.l).to eq 0xC1
    end
  end

  describe '#ld_dc_a' do
    before { subject.set_register :c, 0x12 }
    before { subject.set_register :a, 0x15 }
    it 'writes value in A register to 0xFF00 + (C)' do
      subject.ld_dc_a
      expect($mmu.read_byte(0xFF12)).to eq 0x15
    end
  end

  describe '#ld_a_dc' do
    before { subject.set_register :c, 0x12 }
    before { $mmu.write_byte 0xFF12, 0x51 }
    it 'loads value from 0xFF00 + (C) into A register' do
      subject.ld_a_dc
      expect(subject.a).to eq 0x51
    end
  end

  describe '#ldh_a_a8' do
    before { $mmu.write_byte 0xFFC1, 0x54 }
    before { $mmu.write_byte 0x100, 0xC1 }
    it 'loads value from 0xFF00 + a8 into A register' do
      subject.ldh_a_a8
      expect(subject.a).to eq 0x54
    end

    it 'increments the PC' do
      subject.ldh_a_a8
      expect(subject.pc).to eq 0x101
    end
  end

  describe '#ldh_a8_a' do
    before { subject.set_register :a, 0x51 }
    before { $mmu.write_byte 0x100, 0xC5 }
    it 'writes value of A register to 0xFF00 + a8' do
      subject.ldh_a8_a
      expect($mmu.read_byte(0xFFC5)).to eq 0x51
    end

    it 'increments the PC' do
      subject.ldh_a8_a
      expect(subject.pc).to eq 0x101
    end
  end

  describe '#ld_hl_sp_r8' do
    before { subject.set_register :sp, 0xFF12 }
    before { $mmu.write_byte 0x100, 0x51 }
    it 'loads address of SP + r8 into HL register' do
      subject.ld_hl_sp_r8
      expect(subject.hl).to eq 0xFF63
    end

    it 'increments the PC' do
      subject.ld_hl_sp_r8
      expect(subject.pc).to eq 0x101
    end
  end

  describe '#ld_a16_sp' do
    before { subject.set_register :sp, 0x12D5 }
    before { $mmu.write_word 0x100, 0xC451 }

    it 'stores value at SP into (a16)' do
      subject.ld_a16_sp
      expect($mmu.read_word(0xC451)).to eq 0x12D5
    end

    it 'increments the PC by 2 addresses' do
      subject.ld_a16_sp
      expect(subject.pc).to eq 0x102
    end
  end

  describe '#ld_de_a' do
    before { subject.set_register :a, 0x14 }
    before { subject.set_register :de, 0x8FFF }

    it 'writes value of A register into memory at (DE)' do
      subject.ld_de_a
      expect($mmu.read_byte(0x8FFF)).to eq 0x14
    end
  end

  describe '#ld_hl_plus_a' do
    before { subject.set_register :hl, 0x8FFF }
    before { subject.set_register :a, 0x58 }

    it 'writes value of A register into memory at (HL)' do
      subject.ld_hl_plus_a
      expect($mmu.read_byte(0x8FFF)).to eq 0x58
    end

    it 'increments the HL register' do
      subject.ld_hl_plus_a
      expect(subject.hl).to eq 0x9000
    end
  end

  describe '#ld_hl_minus_a' do
    before { subject.set_register :hl, 0x8FFF }
    before { subject.set_register :a, 0x12 }

    it 'puts register A into memory at (HL)' do
      subject.ld_hl_minus_a
      expect($mmu.read_byte(0x8FFF)).to eq 0x12
    end

    it 'decrements HL register' do
      subject.ld_hl_minus_a
      expect(subject.hl).to eq 0x8FFE
    end
  end

  # LD (HL), n
  [:a, :b, :c, :d, :e].each do |i|
    method = "ld_hl_#{i}"
    describe "##{method}" do
      before { subject.set_register :hl, 0xF812 }
      before { subject.set_register i, 0xDE }

      it "writes value of #{i.upcase} register into memory at HL" do
        subject.public_send method
        expect($mmu.read_byte(0xF812)).to eq 0xDE
      end
    end
  end

  describe '#ld_hl_l' do
    before { subject.set_register :hl, 0x8FFF }
    it 'writes value of L register into memory at HL' do
      subject.ld_hl_l
      expect($mmu.read_byte(0x8FFF)).to eq 0xFF
    end
  end

  describe '#ld_hl_h' do
    before { subject.set_register :hl, 0x8FFF }
    it 'writes value of H register into memory at HL' do
      subject.ld_hl_h
      expect($mmu.read_byte(0x8FFF)).to eq 0x8F
    end
  end

  # LD n,d8
  [:a, :b, :c, :d, :e, :h, :l].each do |i|
    method = "ld_#{i}_d8"
    describe "##{method}" do
      before { $mmu.write_byte 0x100, 0x54 }

      it "load value from d8 into #{i} register" do
        subject.public_send method
        expect(subject.public_send(i)).to eq 0x54
      end

      it 'increments the program counter' do
        subject.public_send method
        expect(subject.pc).to eq 0x101
      end
    end
  end

  # LD n,n
  [:a, :b, :c, :d, :e, :h, :l].each do |i|
    [:a, :b, :c, :d, :e, :h, :l].each do |v|

      method = "ld_#{i}_#{v}"
      describe "##{method}" do
        before { subject.set_register v, 0x14 }

        it "it loads value of #{v.upcase} register into #{i.upcase} register" do
          subject.public_send method
          expect(subject.public_send(i)).to eq 0x14
        end
      end
    end
  end

  describe '#pop_af' do
    before { $mmu.write_byte 0x200, 0x10 }
    before { $mmu.write_byte 0x201, 0xC6 }

    it 'decrements the stack pointer by 2 addresses' do
      subject.pop_af
      expect(subject.sp).to eq 0x202
    end

    it 'value from the stack into the A register' do
      subject.pop_af
      expect(subject.af).to eq 0xC610
    end
  end

  # POP nn
  [:bc, :de, :hl].each do |i|
    method = "pop_#{i}"
    describe "##{method}" do
      before { $mmu.write_byte 0x200, 0x2F }
      before { $mmu.write_byte 0x201, 0x21 }

      it 'decrements the stack pointer by 2 addresses' do
        subject.public_send method
        expect(subject.sp).to eq 0x202
      end

      it "loads value from stack into the #{i} register" do
        subject.public_send method
        expect(subject.public_send(i)).to eq 0x212F
      end
    end
  end

  describe '#push_af' do
    before { subject.set_register :af, 0x1E0 }

    it 'increments the stack pointer by 2 addresses' do
      subject.push_af
      expect(subject.sp).to eq 0x1FE
    end

    it "pushes value of the AF register onto the stack" do
      subject.push_af
      expect($mmu.read_word(0x1FE)).to eq 0x1E0
    end
  end

  # PUSH nn
  [:bc, :de, :hl].each do |i|
    method = "push_#{i}"
    describe "##{method}" do
      before { subject.set_register i, 0x105 }

      it 'increments the stack pointer by 2 addresses' do
        subject.public_send method
        expect(subject.sp).to eq 0x1FE
      end

      it "pushes value of the #{i} register onto the stack" do
        subject.public_send method
        expect($mmu.read_word(0x1FE)).to eq 0x105
      end
    end
  end

  # LD nn,d16
  [:bc, :de, :hl, :sp].each do |i|
    method = "ld_#{i}_d16"
    describe "##{method}" do
      before { $mmu.write_byte 0x100, 0x15 }
      before { $mmu.write_byte 0x101, 0x51 }

      it 'loads immediate value from memory into the #{i} register' do
        subject.public_send method
        expect(subject.public_send(i)).to eq 0x5115
      end

      it 'increments the program counter' do
        subject.public_send method
        expect(subject.pc).to eq 0x102
      end
    end
  end

  describe '#ld_a_a16' do
    before { $mmu.write_byte 0x100, 0x51 }
    before { $mmu.write_byte 0x101, 0xFC }
    before { $mmu.write_byte 0xFC51, 0x15 }

    it 'loads byte from immediate value in memory into the A register' do
      subject.ld_a_a16
      expect(subject.a).to eq 0x15
    end

    it 'increments the program counter' do
      subject.ld_a_a16
      expect(subject.pc).to eq 0x102
    end
  end

  describe '#ld_a_bc' do
    before { subject.set_register :bc, 0x61C2 }
    before { $mmu.write_byte 0x61C2, 0x1F }
    it 'loads value at (BC) into A register' do
      subject.ld_a_bc
      expect(subject.a).to eq 0x1F
    end
  end

  describe '#ld_a_de' do
    before { subject.set_register :de, 0x151B }
    before { $mmu.write_byte 0x151B, 0xC3 }
    it 'loads value at (DE) into A register' do
      subject.ld_a_de
      expect(subject.a).to eq 0xC3
    end
  end

  describe '#ld_a_hl_plus' do
    before { subject.set_register :hl, 0xC28F }
    before { $mmu.write_byte 0xC28F, 0x8F }

    it 'loads value at (HL) into A register' do
      subject.ld_a_hl_plus
      expect(subject.a).to eq 0x8F
    end

    it 'increments HL register' do
      subject.ld_a_hl_plus
      expect(subject.hl).to eq 0xC290
    end
  end

  describe '#ld_a_hl_minus' do
    before { subject.set_register :hl, 0x51D3 }
    before { $mmu.write_byte 0x51D3, 0xCC }

    it 'loads value at (HL) into A register' do
      subject.ld_a_hl_minus
      expect(subject.a).to eq 0xCC
    end

    it 'decrements the HL register' do
      subject.ld_a_hl_minus
      expect(subject.hl).to eq 0x51D2
    end
  end

  describe '#ld_hl_d8' do
    before { subject.set_register :hl, 0x516C }
    before { $mmu.write_byte 0x100, 0x51 }
    it 'loads immediate value from memory into memory at address (HL)' do
      subject.ld_hl_d8
      expect($mmu.read_byte(0x516C)).to eq 0x51
    end

    it 'increments the program counter' do
      subject.ld_hl_d8
      expect(subject.pc).to eq 0x101
    end
  end

  describe "ld_a16_a" do
    before { subject.set_register :a, 0xCA }
    before { $mmu.write_byte 0x100, 0x7F }
    before { $mmu.write_byte 0x101, 0xC6 }

    it 'loads value of register A into location from immediate value in memory' do
      subject.ld_a16_a
      expect($mmu.read_byte(0xC67F)).to eq 0xCA
    end

    it 'increments the program counter' do
      subject.ld_a16_a
      expect(subject.pc).to eq 0x102
    end
  end

  describe "ld_hl_sp_r8" do
    # TODO
  end

  describe "ld_sp_hl" do
    before { subject.set_register :hl, 0x78FA }

    it 'loads value of HL register into SP register' do
      subject.ld_sp_hl
      expect(subject.sp).to eq 0x78FA
    end
  end
end
