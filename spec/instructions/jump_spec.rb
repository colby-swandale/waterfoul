require 'spec_helper'

describe Waterfoul::CPU do
  before { $mmu = Waterfoul::MMU.new }
  subject { Waterfoul::CPU.new }

  before { subject.set_register :pc, 0x100 }
  before { subject.set_register :sp, 0x200 }

  describe '#jr_nz_r8' do
    before { $mmu.write_byte 0x100, 0x54 }

    context 'when Z flag is set' do
      before { subject.set_z_flag }
      it 'increments the pc' do
        subject.jr_nz_r8
        expect(subject.pc).to eq 0x101
      end
    end

    context 'when Z flag is reset' do
      before { subject.reset_z_flag }
      it 'adds immediate value from memory and 1 to pc' do
        subject.jr_nz_r8
        expect(subject.pc).to eq 0x155
      end
    end
  end

  describe '#jr_nc_r8' do
    before { $mmu.write_byte 0x100, 0x72 }

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'increments the pc' do
        subject.jr_nc_r8
        expect(subject.pc).to eq 0x101
      end
    end

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'adds immediate value from memory and 1 to pc' do
        subject.jr_nc_r8
        expect(subject.pc).to eq 0x173
      end
    end
  end

  describe '#jr_r8' do
    before { $mmu.write_byte 0x100, 0x56 }

    it 'increments pc by 1 and the value fetched from memory' do
      subject.jr_r8
      expect(subject.pc).to eq 0x157
    end
  end

  describe '#jr_z_r8' do
    before { $mmu.write_byte 0x100, 0x59 }

    context 'when Z flag is set' do
      before { subject.set_z_flag }
      it 'adds immediate value from memory and 1 to pc' do
        subject.jr_z_r8
        expect(subject.pc).to eq 0x15A
      end
    end

    context 'when Z flag is reset' do
      before { subject.reset_z_flag }
      it 'increments the pc' do
        subject.jr_z_r8
        expect(subject.pc).to eq 0x101
      end
    end
  end

  describe '#jr_c_r8' do
    before { $mmu.write_byte 0x100, 0x43 }

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'adds immediate value from memory and 1 to pc' do
        subject.jr_c_r8
        expect(subject.pc).to eq 0x144
      end
    end

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'increments pc by 1' do
        subject.jr_c_r8
        expect(subject.pc).to eq 0x101
      end
    end
  end

  describe '#ret_nz' do
    before { $mmu.write_byte 0x200, 0x30 }
    before { $mmu.write_byte 0x201, 0x40 }

    context 'when Z flag reset' do
      before { subject.reset_z_flag }
      it 'sets pc to the immediate value from memory' do
        subject.ret_nz
        expect(subject.pc).to eq 0x4030
      end

      it 'decrements the stack pointer by 2 addreses' do
        subject.ret_nz
        expect(subject.sp).to eq 0x202
      end
    end

    context 'when Z flag is set' do
      before { subject.set_z_flag }
      it 'does not increment the pc' do
        subject.ret_nz
        expect(subject.pc).to eq 0x100
      end
    end
  end

  describe '#ret_nc' do
    before { $mmu.write_byte 0x200, 0x40 }
    before { $mmu.write_byte 0x201, 0x30 }

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'sets pc to immediate value from memory' do
        subject.ret_nz
        expect(subject.pc).to eq 0x3040
      end

      it 'decrements the stack pointer by 2 addresses' do
        subject.ret_nz
        expect(subject.sp).to eq 0x202
      end
    end

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'does not increment the pc' do
        subject.ret_nc
        expect(subject.pc).to eq 0x100
      end
    end
  end

  describe '#jp_nz_a16' do
    before { $mmu.write_byte 0x100, 0x30 }

    context 'when Z flag is reset' do
      before { subject.reset_z_flag }
      it 'sets pc to immediate value from memory' do
        subject.jp_nz_a16
        expect(subject.pc).to eq 0x30
      end
    end

    context 'when Z flag is set' do
      before { subject.set_z_flag }
      it 'increments the pc by 2' do
        subject.jp_nz_a16
        expect(subject.pc).to eq 0x102
      end
    end
  end

  describe '#jp_nc_a16' do
    before { $mmu.write_byte 0x100, 0x40 }

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'sets pc to immediate value from memory' do
        subject.jp_nc_a16
        expect(subject.pc).to eq 0x40
      end
    end

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'increments the pc by 2' do
        subject.jp_nc_a16
        expect(subject.pc).to eq 0x102
      end
    end
  end

  %w(rst_00h rst_10h rst_20h rst_30h rst_08h rst_18h rst_28h rst_38h).each do |m|
    describe "##{m}" do
      it 'increments the sp by 2 addresses' do
        subject.public_send m
        expect(subject.sp).to eq 0x1FE
      end

      hex = /rst\_(\d+)h/.match(m)
      it "sets the pc to 0x#{hex[1]}" do
        subject.public_send m
        expect(subject.pc).to eq hex[1].to_i(16)
      end
    end
  end

  describe '#jp_a16' do
    before { $mmu.write_byte 0x100, 0x70 }

    it 'jumps to immediate value from memory' do
      subject.jp_a16
      expect(subject.pc).to eq 0x70
    end
  end

  describe '#call_nz_a16' do
    before { $mmu.write_byte 0x100, 0x80 }

    context 'when Z flag is set' do
      before { subject.set_z_flag }

      it 'increments the pc by 2' do
        subject.call_nz_a16
        expect(subject.pc).to eq 0x102
      end
    end

    context 'when Z flag is reset' do
      before { subject.reset_z_flag }

      it 'sets PC to immediate value from memory' do
        subject.call_nz_a16
        expect(subject.pc).to eq 0x80
      end

      it 'increments the stack pointer by 2 addresses' do
        subject.call_nz_a16
        expect(subject.sp).to eq 0x1FE
      end
    end
  end

  describe '#call_nc_a16' do
    before { $mmu.write_byte 0x100, 0x104 }

    context 'when C flag is set' do
      before { subject.set_c_flag }

      it 'increments the pc' do
        subject.call_nc_a16
        expect(subject.pc).to eq 0x102
      end
    end

    context 'when C flag is reset' do
      before { subject.reset_c_flag }

      it 'sets PC to immediate value from memory' do
        subject.call_nc_a16
        expect(subject.pc).to eq 0x104
      end

      it 'decrements the sp' do
        subject.call_nc_a16
        expect(subject.sp).to eq 0x1FE
      end
    end
  end

  describe '#ret_z' do
    before { $mmu.write_byte 0x200, 0x7A }
    before { $mmu.write_byte 0x201, 0xE }

    context 'when Z flag set' do
      before { subject.set_z_flag }
      it 'jumps to value from the stack' do
        subject.ret_z
        expect(subject.pc).to eq 0xE7A
      end

      it 'decrements stack pointer by 2 addresses' do
        subject.ret_z
        expect(subject.sp).to eq 0x202
      end
    end
  end

  describe '#ret_c' do
    before { $mmu.write_byte 0x200, 0xFF }
    before { $mmu.write_byte 0x201, 0x12 }

    context 'when C flag set' do
      before { subject.set_c_flag }
      it 'jumps to value from the stack' do
        subject.ret_c
        expect(subject.pc).to eq 0x12FF
      end

      it 'decrements stack pointer by 2 addresses' do
        subject.ret_c
        expect(subject.sp).to eq 0x202
      end
    end
  end

  describe '#ret' do
    before { $mmu.write_byte 0x200, 0xA }
    before { $mmu.write_byte 0x201, 0xF }

    it 'decrements the stack pointer by 2 addresses' do
      subject.ret
      expect(subject.sp).to eq 0x202
    end

    it 'jumps to value from from the sack' do
      subject.ret
      expect(subject.pc).to eq 0xF0A
    end
  end

  describe '#reti' do
    before { $mmu.write_byte 0x200, 0x1A }
    before { $mmu.write_byte 0x201, 0xF }

    it 'sets the ime flag' do
      subject.reti
      expect(subject.ime).to eq true
    end

    it 'decrements the stack pointer by 2 addresses' do
      subject.reti
      expect(subject.sp).to eq 0x202
    end

    it 'jumps to value from the stack' do
      subject.reti
      expect(subject.pc).to eq 0xF1A
    end
  end

  describe '#jp_dhl' do
    before { subject.set_register :hl, 0x1FA5 }

    it 'jumps to value from hl register' do
      subject.jp_dhl
      expect(subject.pc).to eq 0x1FA5
    end
  end

  describe '#jp_z_a16' do
    before { $mmu.write_byte 0x100, 0x56 }
    before { $mmu.write_byte 0x101, 0x64 }

    context 'when Z flag is set' do
      before { subject.set_z_flag }

      it 'jumps to instruction from immediate value in memory' do
        subject.jp_z_a16
        expect(subject.pc).to eq 0x6456
      end
    end

    context 'when Z flag is reset' do
      before { subject.reset_z_flag }
      it 'increments pc' do
        subject.jp_z_a16
        expect(subject.pc).to eq 0x102
      end
    end
  end

  describe '#jp_c_a16' do
    before { $mmu.write_byte 0x100, 0x51 }
    before { $mmu.write_byte 0x101, 0x65 }

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'jumps to instruction at immediate value from memory' do
        subject.jp_c_a16
        expect(subject.pc).to eq 0x6551
      end
    end

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'increments pc' do
        subject.jp_c_a16
        expect(subject.pc).to eq 0x102
      end
    end
  end

  describe '#call_z_a16' do
    before { $mmu.write_byte 0x100, 0x54 }
    before { $mmu.write_byte 0x101, 0xFF }

    context 'when Z flag is set' do
      before { subject.set_z_flag }
      it 'jumps to instruction at immediate value from memory' do
        subject.call_z_a16
        expect(subject.pc).to eq 0xFF54
      end

      it 'increments the stack pointer by 2 addresses' do
        subject.call_z_a16
        expect(subject.sp).to eq 0x1FE
      end
    end

    context 'when Z flag is reset' do
      it 'increments pc' do
        subject.call_z_a16
        expect(subject.pc).to eq 0x102
      end
    end
  end

  describe '#call_c_a16' do
    before { $mmu.write_byte 0x100, 0x65 }
    before { $mmu.write_byte 0x101, 0x1C }

    context 'when C flag is set' do
      before { subject.set_c_flag }
      it 'jumps to instruction at immediate value from memory' do
        subject.call_c_a16
        expect(subject.pc).to eq 0x1C65
      end

      it 'increments the stack pointer by 2 addresses' do
        subject.call_c_a16
        expect(subject.sp).to eq 0x1FE
      end
    end

    context 'when C flag is reset' do
      before { subject.reset_c_flag }
      it 'increments the program counter' do
        subject.call_c_a16
        expect(subject.pc).to eq 0x102
      end
    end
  end

  describe '#call_a16' do
    before { $mmu.write_byte 0x100, 0x10 }
    before { $mmu.write_byte 0x101, 0xC2 }

    it 'jumps to instruction at immediate value from memory' do
      subject.call_a16
      expect(subject.pc).to eq 0xC210
    end

    it 'inccrements the stack pointer by 2 addresses' do
      subject.call_a16
      expect(subject.sp).to eq 0x1FE
    end
  end
end
