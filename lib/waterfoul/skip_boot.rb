module Waterfoul
  # Set the state of the emulator after it has finished running the bootloader and ready to execute
  # the game program. This lets us run the game program without needing to execute the boot rom every time
  # the emulator is started.
  class SkipBoot
    def self.set_state(cpu)
      # CPU registers
      cpu.set_register :pc, 0x100
      cpu.set_register :af, 0x1B0
      cpu.set_register :bc, 0x13
      cpu.set_register :de, 0xD8
      cpu.set_register :hl, 0x14D
      cpu.set_register :sp, 0xFFFE
      # IO registers
      $mmu.write_byte 0xFF10, 0x80
      $mmu.write_byte 0xFF11, 0xBF
      $mmu.write_byte 0xFF12, 0xF3
      $mmu.write_byte 0xFF14, 0xBF
      $mmu.write_byte 0xFF16, 0x3F
      $mmu.write_byte 0xFF19, 0xBF
      $mmu.write_byte 0xFF1A, 0x7F
      $mmu.write_byte 0xFF1B, 0xFF
      $mmu.write_byte 0xFF1C, 0x9F
      $mmu.write_byte 0xFF1E, 0xBF
      $mmu.write_byte 0xFF20, 0xFF
      $mmu.write_byte 0xFF23, 0xBF
      $mmu.write_byte 0xFF24, 0x77
      $mmu.write_byte 0xFF25, 0xF3
      $mmu.write_byte 0xFF26, 0xF1
      $mmu.write_byte 0xFF40, 0x91
      $mmu.write_byte 0xFF41, 0x5
      $mmu.write_byte 0xFF47, 0xFC
      $mmu.write_byte 0xFF48, 0xFF
      $mmu.write_byte 0xFF49, 0xFF
      # unmap the boot rom
      $mmu.write_byte 0xFF50, 0x1
      cpu
    end
  end
end
