module Waterfoul
  class Interrupt
    # IE register memory location
    IE_REG_MEM_LOC = 0xFFFF
    # IF register memory location
    IF_REG_MEM_LOC = 0xFF0F
    # interupt calls
    INTERRUPT_NONE    = 0x0
    INTERRUPT_VBLANK  = 0x1
    INTERRUPT_LCDSTAT = 0x2
    INTERRUPT_TIMER   = 0x4
    INTERRUPT_SERIAL  = 0x8
    INTERRUPT_JOYPAD  = 0x10

    #
    def self.request_interrupt(interrupt)
      if_reg = $mmu.read_byte IF_REG_MEM_LOC
      $mmu.write_byte IF_REG_MEM_LOC, (if_reg | interrupt)
    end

    def self.pending_interrupt
      ie_reg = $mmu.read_byte IE_REG_MEM_LOC
      if_reg = $mmu.read_byte IF_REG_MEM_LOC
      pending_interrupts = if_reg & ie_reg

      if pending_interrupts & INTERRUPT_VBLANK == INTERRUPT_VBLANK
        INTERRUPT_VBLANK
      elsif pending_interrupts & INTERRUPT_LCDSTAT == INTERRUPT_LCDSTAT
        INTERRUPT_LCDSTAT
      elsif pending_interrupts & INTERRUPT_TIMER == INTERRUPT_TIMER
        INTERRUPT_TIMER
      elsif pending_interrupts & INTERRUPT_SERIAL == INTERRUPT_SERIAL
        INTERRUPT_SERIAL
      elsif pending_interrupts & INTERRUPT_JOYPAD == INTERRUPT_JOYPAD
        INTERRUPT_JOYPAD
      else
        INTERRUPT_NONE
      end
    end
  end
end
