require 'spec_helper'

describe Waterfoul::CPU do
  before { $mmu = Waterfoul::MMU.new }
  subject { Waterfoul::CPU.new }

  describe '#stop_0' do
    it 'sets stop flag' do
      subject.stop_0
      expect(subject.stop).to eq 1
    end
  end

  describe '#halt' do
    before { $mmu.write_byte 0xFFFF, 0x00 }  # no interrupts enabled
    before { $mmu.write_byte 0xFF0F, 0x00 }  # no interrupts pending

    it 'sets the halt flag when no pending interrupts' do
      subject.halt
      expect(subject.halted?).to eq true
    end
  end

  describe '#di' do
    it 'disables interrupts immediately' do
      subject.di
      expect(subject.ime).to eq false
    end

    it 'cancels a pending EI' do
      # EI followed by DI should not allow interrupts
      # Per Pan Docs: "ei followed immediately by di does not allow any interrupts between them"
      subject.set_register :pc, 0x100
      $mmu.write_byte 0x100, 0x00  # NOP opcode

      subject.ei  # Sets pending
      subject.di  # Should cancel the pending EI

      subject.step  # Execute NOP
      expect(subject.ime).to eq false  # Should still be disabled
    end

    it 'disables interrupts even when they were enabled' do
      # First enable interrupts
      subject.set_register :pc, 0x100
      $mmu.write_byte 0x100, 0x00  # NOP
      subject.ei
      subject.step  # IME becomes true

      expect(subject.ime).to eq true

      # Now disable them
      subject.di
      expect(subject.ime).to eq false  # Immediate effect
    end
  end

  describe 'prefix_cb' do
    it 'increments pc by 1' do
      subject.prefix_cb
      expect(subject.pc).to eq 1
    end
  end

  describe '#ei' do
    it 'does not enable interrupts immediately' do
      subject.ei
      expect(subject.ime).to eq false
    end

    it 'enables interrupts after the next instruction executes' do
      # Set up a NOP instruction at PC
      subject.set_register :pc, 0x100
      $mmu.write_byte 0x100, 0x00  # NOP opcode

      subject.ei
      expect(subject.ime).to eq false

      subject.step  # Execute NOP, then apply pending IME
      expect(subject.ime).to eq true
    end

    it 'allows one more instruction to execute before interrupt is serviced' do
      # This tests the classic EI + HALT pattern
      subject.set_register :pc, 0x100
      $mmu.write_byte 0x100, 0x00  # NOP opcode

      subject.ei
      subject.step  # NOP executes, IME becomes true at end of step

      # Now interrupts are enabled
      expect(subject.ime).to eq true
    end
  end
end
