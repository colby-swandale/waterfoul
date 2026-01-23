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

    # Pre-computed priority lookup (highest to lowest priority)
    INTERRUPT_PRIORITY = [
      INTERRUPT_VBLANK,
      INTERRUPT_LCDSTAT,
      INTERRUPT_TIMER,
      INTERRUPT_SERIAL,
      INTERRUPT_JOYPAD
    ].freeze

    #
    def self.request_interrupt(interrupt)
      if_reg = $mmu.read_memory_byte IF_REG_MEM_LOC
      $mmu.write_byte IF_REG_MEM_LOC, (if_reg | interrupt)
    end

    def self.pending_interrupt
      ie_reg = $mmu.read_memory_byte IE_REG_MEM_LOC
      if_reg = $mmu.read_memory_byte IF_REG_MEM_LOC
      pending = ie_reg & if_reg

      return INTERRUPT_NONE if pending == 0

      INTERRUPT_PRIORITY.each do |interrupt|
        return interrupt if (pending & interrupt) != 0
      end

      INTERRUPT_NONE
    end
  end
end
