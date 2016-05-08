require 'spec_helper'

describe Waterfoul::CPU do
  subject { Waterfoul::CPU.new }

  before :each do
    $mmu = double :mmu
  end

  describe '#jr_nz_r8' do
    let(:jump_to) { 0x54 }
    before { allow($mmu).to receive(:read_byte).and_return(jump_to) }

    context 'when Z flag is set' do
      before { subject.set_z_flag }
      it 'increments the pc' do
        subject.jr_nz_r8
        expect(subject.pc).to eq 0x1
      end
    end

    context 'when Z flag is reset' do
      before { subject.reset_z_flag }
      it 'adds immediate value from memory and 1 to pc' do
        subject.jr_nz_r8
        expect(subject.pc).to eq (1 + jump_to)
      end
    end
  end

  describe '#jr_nc_r8' do
    let(:jump_to) { 0x55 }
    before { allow($mmu).to receive(:read_byte).and_return(jump_to) }

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'increments the pc' do
        subject.jr_nc_r8
        expect(subject.pc).to eq 1
      end
    end

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'adds immediate value from memory and 1 to pc' do
        subject.jr_nc_r8
        expect(subject.pc).to eq (1 + jump_to)
      end
    end
  end

  describe '#jr_r8' do
    let(:jump_to) { 0x56 }
    before { allow($mmu).to receive(:read_byte).and_return(jump_to) }

    it 'increments pc by 1 and the value fetched from memory' do
      subject.jr_r8
      expect(subject.pc).to eq (1 + jump_to)
    end
  end

  describe '#jr_z_r8' do
    let(:jump_to) { 0x57 }
    before { allow($mmu).to receive(:read_byte).and_return(jump_to) }

    context 'when Z flag is set' do
      before { subject.set_z_flag }
      it 'adds immediate value from memory and 1 to pc' do
        subject.jr_z_r8
        expect(subject.pc).to eq (1 + jump_to)
      end
    end

    context 'when Z flag is reset' do
      before { subject.reset_z_flag }
      it 'increments the pc' do
        subject.jr_z_r8
        expect(subject.pc).to eq 1
      end
    end
  end

  describe '#jr_c_r8' do
    let(:jump_to) { 0x58 }
    before { allow($mmu).to receive(:read_byte).and_return(jump_to) }

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'adds immediate value from memory and 1 to pc' do
        subject.jr_c_r8
        expect(subject.pc).to eq (1 + jump_to)
      end
    end

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'increments pc by 1' do
        subject.jr_c_r8
        expect(subject.pc).to eq 1
      end
    end
  end

  describe '#ret_nz' do
    let(:jump_to) { 0x59 }
    before { allow($mmu).to receive(:read_byte).and_return(jump_to) }

    context 'when Z flag reset' do
      before { subject.reset_z_flag }
      it 'sets pc to immediate value from memory' do
        subject.ret_nz
        expect(subject.pc).to eq 0x5959
      end

      it 'increments the stack pointer by 2' do
        subject.ret_nz
        expect(subject.sp).to eq 2
      end
    end

    context 'when Z flag is set' do
      before { subject.set_z_flag }
      it 'does not increment the pc' do
        subject.ret_nz
        expect(subject.pc).to eq 0
      end
    end
  end

  describe '#ret_nc' do
    let(:jump_to) { 0x60 }
    before { allow($mmu).to receive(:read_byte).and_return(jump_to) }

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'sets pc to immediate value from memory' do
        subject.ret_nz
        expect(subject.pc).to eq 0x6060
      end

      it 'increments the stack pointer by 2' do
        subject.ret_nz
        expect(subject.sp).to eq 2
      end
    end

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'does not increment the pc' do
        subject.ret_nc
        expect(subject.pc).to eq 0
      end
    end
  end

  describe '#jp_nz_a16' do
    let(:jump_to) { 0x61 }
    before { allow($mmu).to receive(:read_word).and_return(jump_to) }

    context 'when Z flag is reset' do
      before { subject.reset_z_flag }
      it 'sets pc to immediate value from memory' do
        subject.jp_nz_a16
        expect(subject.pc).to eq jump_to
      end
    end

    context 'when Z flag is set' do
      before { subject.set_z_flag }
      it 'increments the pc by 2' do
        subject.jp_nz_a16
        expect(subject.pc).to eq 2
      end
    end
  end

  describe '#jp_nc_a16' do
    let(:jump_to) { 0x62 }
    before { allow($mmu).to receive(:read_word).and_return(jump_to) }

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'sets pc to immediate value from memory' do
        subject.jp_nc_a16
        expect(subject.pc).to eq jump_to
      end
    end

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'increments the pc by 2' do
        subject.jp_nc_a16
        expect(subject.pc).to eq 2
      end
    end
  end

  %w(rst_00h rst_10h rst_20h rst_30h rst_08h rst_18h rst_28h rst_38h).each do |m|
    describe "##{m}" do
      let(:sp_pointer) { 0xFFDF }
      before { subject.set_stack_pointer sp_pointer }
      before { allow($mmu).to receive(:write_byte) }

      it 'deincrements the sp by -2' do
        subject.public_send m
        expect(subject.sp).to eq (sp_pointer - 2)
      end

      hex = /rst\_(\d+)h/.match(m)
      it "sets the pc to 0x#{hex[1]}" do
        subject.public_send m
        expect(subject.pc).to eq hex[1].to_i(16)
      end
    end
  end

  describe '#jp_a16' do
    let(:jump_to) { 0x63 }
    before { allow($mmu).to receive(:read_word).and_return(jump_to) }

    it 'jumps to immediate value from memory' do
      subject.jp_a16
      expect(subject.pc).to eq jump_to
    end
  end

  describe '#call_nz_a16' do
    before { allow($mmu).to receive(:write_byte) }
    before { allow($mmu).to receive(:read_word).and_return jump_to }
    let(:jump_to) { 0x64 }
    let(:stack_pointer) { 0xFFDF }

    context 'when Z flag is set' do
      before { subject.set_z_flag }

      it 'increments the pc' do
        subject.call_nz_a16
        expect(subject.pc).to eq 2
      end
    end

    context 'when Z flag is reset' do
      before { subject.reset_z_flag }
      before { subject.set_register :sp, stack_pointer }
      before { subject.set_register :pc, jump_to }

      xit 'pushes the value of PC into the stack' do
        subject.call_nz_a16
      end

      it 'sets PC to immediate value from memory' do
        subject.call_nz_a16
        expect(subject.pc).to eq jump_to
      end

      it 'decrements the sp' do
        subject.call_nz_a16
        expect(subject.sp).to eq (stack_pointer - 2)
      end
    end
  end

  describe '#call_nc_a16' do
    before { allow($mmu).to receive(:write_byte) }
    before { allow($mmu).to receive(:read_word).and_return jump_to }
    let(:jump_to) { 0x64 }
    let(:stack_pointer) { 0xFFDF }

    context 'when C flag is set' do
      before { subject.set_c_flag }

      it 'increments the pc' do
        subject.call_nc_a16
        expect(subject.pc).to eq 2
      end
    end

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      before { subject.set_register :sp, stack_pointer }
      before { subject.set_register :pc, jump_to }

      xit 'pushes the value of PC into the stack' do
        subject.call_nc_a16
      end

      it 'sets PC to immediate value from memory' do
        subject.call_nc_a16
        expect(subject.pc).to eq jump_to
      end

      it 'decrements the sp' do
        subject.call_nc_a16
        expect(subject.sp).to eq (stack_pointer - 2)
      end
    end
  end

  describe '#ret_z' do
    let(:jump_to) { 0x65 }
    before { allow($mmu).to receive(:read_byte).and_return jump_to }

    context 'when Z flag set' do
      before { subject.set_z_flag }
      it 'jumps to instruction at immediate value from memory' do
        subject.ret_z
        expect(subject.pc).to eq 0x6565
      end

      it 'increments stack pointer' do
        subject.ret_z
        expect(subject.sp).to eq 2
      end
    end
  end

  describe '#ret_c' do
    let(:jump_to) { 0x66 }
    before { allow($mmu).to receive(:read_byte).and_return jump_to }

    context 'when C flag set' do
      before { subject.set_c_flag }
      it 'jumps to value from memory' do
        subject.ret_c
        expect(subject.pc).to eq 0x6666
      end

      it 'increments stack pointer' do
        subject.ret_c
        expect(subject.sp).to eq 2
      end
    end
  end

  describe '#ret' do
    let(:jump_to) { 0x67 }
    before { allow($mmu).to receive(:read_byte).and_return jump_to }

    it 'increments the stack pointer' do
      subject.ret
      expect(subject.sp).to eq 2
    end

    it 'jumps to value from memory' do
      subject.ret
      expect(subject.pc).to eq 0x6767
    end
  end

  describe '#reti' do
    let(:jump_to) { 0x68 }
    before { allow($mmu).to receive(:read_byte).and_return jump_to }

    it 'sets the ime flag' do
      subject.reti
      expect(subject.ime).to eq 1
    end

    it 'increments the stack pointer' do
      subject.reti
      expect(subject.sp).to eq 2
    end

    it 'jumps to value from memory' do
      subject.reti
      expect(subject.pc).to eq 0x6868
    end
  end

  describe '#jp_dhl' do
    let(:jump_to) { 0x69 }
    before { subject.set_register :hl, jump_to }

    it 'jumps to value from hl register' do
      subject.jp_dhl
      expect(subject.pc).to eq jump_to
    end
  end

  describe '#jp_z_a16' do
    let(:jump_to) { 0x70 }
    context 'when Z flag is set' do
      before { subject.set_z_flag }
      before { expect($mmu).to receive(:read_word).and_return jump_to }

      it 'jumps to instruction from immediate value in memory' do
        subject.jp_z_a16
        expect(subject.pc).to eq jump_to
      end
    end

    context 'when Z flag is reset' do
      before { subject.reset_z_flag }
      it 'increments pc' do
        subject.jp_z_a16
        expect(subject.pc).to eq 2
      end
    end
  end

  describe '#jp_c_a16' do
    let(:jump_to) { 0x71 }
    before { allow($mmu).to receive(:read_word).and_return jump_to }

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'jumps to instruction at immediate value from memory' do
        subject.jp_c_a16
        expect(subject.pc).to eq jump_to
      end
    end

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'increments pc' do
        subject.jp_c_a16
        expect(subject.pc).to eq 2
      end
    end
  end

  describe '#call_z_a16' do
    let(:jump_to) { 0x72 }
    before { subject.set_register :sp, 2 }
    before { allow($mmu).to receive(:read_word).and_return jump_to }
    before { allow($mmu).to receive(:write_byte) }

    context 'when Z flag is set' do
      before { subject.set_z_flag }
      it 'jumps to instruction at immediate value from memory' do
        subject.call_z_a16
        expect(subject.pc).to eq jump_to
      end

      it 'decrements the stack pointer' do
        subject.call_z_a16
        expect(subject.sp).to eq 0
      end
    end

    context 'when Z flag is reset' do
      it 'increments pc' do
        subject.call_z_a16
        expect(subject.pc).to eq 2
      end
    end
  end

  describe '#call_c_a16' do
    let(:jump_to) { 0x73 }
    before { subject.set_register :sp, 2 }
    before { allow($mmu).to receive(:read_word).and_return jump_to }
    before { allow($mmu).to receive(:write_byte) }

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'jumps to instruction at immediate value from memory' do
        subject.call_c_a16
        expect(subject.pc).to eq jump_to
      end

      it 'decrements the stack pointer' do
        subject.call_c_a16
        expect(subject.sp).to eq 0
      end
    end

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'increments the program counter' do
        subject.call_c_a16
        expect(subject.pc).to eq 2
      end
    end
  end

  describe '#call_a16' do
    let(:jump_to) { 0x74 }
    before { subject.set_register :sp, 2 }
    before { allow($mmu).to receive(:read_word).and_return jump_to }
    before { allow($mmu).to receive(:write_byte) }

    it 'jumps to instruction at immediate value from memory' do
      subject.call_a16
      expect(subject.pc).to eq jump_to
    end

    it 'decrements the stack pointer' do
      subject.call_a16
      expect(subject.sp).to eq 0
    end
  end
end
