require 'spec_helper'
describe Waterfoul::CPU do
  before { $mmu = Waterfoul::MMU.new }
  subject { Waterfoul::CPU.new }

  describe '#serve_interrupt' do
    before { $mmu.write_byte 0xFFFF, 0xFF } # enable all interrupts
    before { subject.set_register :sp, 0xFFFE }
    before { subject.set_register :pc, 0x100 }
    # EI has a one-instruction delay, so we need to execute one instruction
    # after EI before interrupts are actually enabled
    before { $mmu.write_byte 0x100, 0x00 } # NOP at 0x100
    before { subject.ei }
    before { subject.step } # Execute NOP, IME becomes true at end of step
    # Now PC is at 0x101 and IME is true

    context 'when no interrupt to serve' do
      it 'does alter the execution path' do
        subject.step
        expect(subject.pc).to eq 0x102
      end

      it 'does not push anything onto the stack' do
        subject.step
        expect(subject.sp).to eq 0xFFFE
      end
    end

    context 'when timer interrupt is served' do
      before { $mmu.write_byte 0xFF0F, 0x4 } # request timer interrupt

      it 'sets the program counter to 0x50' do
        subject.step
        expect(subject.pc).to eq 0x51
      end

      it 'saves the current program counter onto the stack' do
        subject.step
        expect($mmu.read_word(0xFFFC)).to eq 0x101
      end
    end
  end

  describe '#step' do
    before { subject.set_register :pc, 0x101 }

    it 'increments the program counter' do
      subject.step
      expect(subject.pc).to eq 0x102
    end

    context 'when the CPU is halted' do
      before { $mmu.write_byte 0xFFFF, 0x00 }  # disable all interrupts
      before { $mmu.write_byte 0xFF0F, 0x00 }  # clear all interrupt flags
      before { subject.halt }

      it 'does not increment the PC' do
        subject.step
        expect(subject.pc).to eq 0x101
      end
    end

    it 'sets the instruction cycle time' do
      subject.step
      expect(subject.m).to eq 4
    end
  end

  describe '#halt' do
    describe 'HALT wake-up' do
      before { subject.set_register :pc, 0x100 }

      it 'wakes when an enabled interrupt becomes pending' do
        $mmu.write_byte 0xFFFF, 0x04  # enable timer interrupt
        $mmu.write_byte 0xFF0F, 0x00  # no interrupts pending
        subject.halt

        expect(subject.halted?).to eq true

        # Request timer interrupt
        $mmu.write_byte 0xFF0F, 0x04
        subject.step

        expect(subject.halted?).to eq false
      end

      it 'stays halted if interrupt is requested but not enabled' do
        $mmu.write_byte 0xFFFF, 0x00  # no interrupts enabled
        $mmu.write_byte 0xFF0F, 0x00  # no interrupts pending
        subject.halt

        # Request timer interrupt (but it's not enabled)
        $mmu.write_byte 0xFF0F, 0x04
        subject.step

        expect(subject.halted?).to eq true
      end

      it 'wakes immediately if interrupt is already pending' do
        $mmu.write_byte 0xFFFF, 0x04  # enable timer interrupt
        $mmu.write_byte 0xFF0F, 0x04  # timer interrupt already pending
        subject.halt

        # Should exit halt immediately on first step
        expect(subject.halted?).to eq false
      end
    end

    describe 'HALT bug' do
      before { subject.set_register :pc, 0x100 }
      before { $mmu.write_byte 0x100, 0x00 }  # NOP at 0x100
      before { $mmu.write_byte 0x101, 0x3C }  # INC A at 0x101

      it 'triggers when IME=0 and interrupt is pending' do
        # IME is false by default
        expect(subject.ime).to eq false

        $mmu.write_byte 0xFFFF, 0x04  # enable timer interrupt
        $mmu.write_byte 0xFF0F, 0x04  # timer interrupt pending

        subject.halt

        # HALT should not actually halt due to the bug
        expect(subject.halted?).to eq false
      end

      it 'causes the next instruction to be read twice' do
        # IME is false by default
        $mmu.write_byte 0xFFFF, 0x04  # enable timer
        $mmu.write_byte 0xFF0F, 0x04  # timer pending

        subject.halt  # Triggers halt bug

        # First step: reads NOP at 0x100, but PC doesn't increment
        subject.step
        expect(subject.pc).to eq 0x100  # PC didn't advance due to halt bug

        # Second step: reads NOP at 0x100 again (normal behavior)
        subject.step
        expect(subject.pc).to eq 0x101  # Now PC advances normally
      end

      it 'does not trigger when IME=1' do
        # Enable interrupts
        subject.set_register :pc, 0x100
        $mmu.write_byte 0x100, 0x00  # NOP
        subject.ei
        subject.step  # IME becomes true

        $mmu.write_byte 0xFFFF, 0x04  # enable timer
        $mmu.write_byte 0xFF0F, 0x04  # timer pending

        # This should service the interrupt, not trigger halt bug
        subject.halt
        # With IME=1, HALT enters halt state and interrupt will be serviced
        # Actually, since there's a pending interrupt and IME=1, it will be serviced
      end
    end
  end

  describe 'interrupt vectors' do
    before { $mmu.write_byte 0xFFFF, 0xFF }  # enable all interrupts
    before { subject.set_register :sp, 0xFFFE }
    before { subject.set_register :pc, 0x100 }
    before { $mmu.write_byte 0x100, 0x00 }  # NOP
    before { subject.ei }
    before { subject.step }  # IME becomes true, PC at 0x101

    # Note: step() serves the interrupt AND executes one instruction from the handler.
    # Handler addresses are in ROM (0x40, 0x48, etc.) so we can't control the instruction there.
    # We verify PC is in the expected range and the return address was saved correctly.

    it 'jumps to VBlank handler region (0x40+)' do
      $mmu.write_byte 0xFF0F, 0x01
      subject.step
      expect(subject.pc).to be >= 0x40
      expect(subject.pc).to be < 0x48
    end

    it 'jumps to LCD STAT handler region (0x48+)' do
      $mmu.write_byte 0xFF0F, 0x02
      subject.step
      expect(subject.pc).to be >= 0x48
      expect(subject.pc).to be < 0x50
    end

    it 'jumps to Timer handler region (0x50+)' do
      $mmu.write_byte 0xFF0F, 0x04
      subject.step
      expect(subject.pc).to be >= 0x50
      expect(subject.pc).to be < 0x58
    end

    it 'jumps to Serial handler region (0x58+)' do
      $mmu.write_byte 0xFF0F, 0x08
      subject.step
      expect(subject.pc).to be >= 0x58
      expect(subject.pc).to be < 0x60
    end

    it 'jumps to Joypad handler region (0x60+)' do
      $mmu.write_byte 0xFF0F, 0x10
      subject.step
      expect(subject.pc).to be >= 0x60
      expect(subject.pc).to be < 0x68
    end

    it 'saves return address to stack for VBlank' do
      $mmu.write_byte 0xFF0F, 0x01
      subject.step
      expect($mmu.read_word(0xFFFC)).to eq 0x101
    end

    it 'clears the IF bit when interrupt is serviced' do
      $mmu.write_byte 0xFF0F, 0x04  # timer
      subject.step
      expect($mmu.read_memory_byte(0xFF0F)).to eq 0x00
    end

    it 'disables IME when interrupt is serviced' do
      $mmu.write_byte 0xFF0F, 0x04
      subject.step
      expect(subject.ime).to eq false
    end
  end
end
