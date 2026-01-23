module Waterfoul
  # Timer implementation matching real Game Boy hardware.
  #
  # On real hardware, there's a single internal 16-bit counter that drives
  # both DIV and TIMA:
  # - DIV (0xFF04) shows bits 8-15 of this counter (increments every 256 T-states)
  # - TIMA increments on the falling edge of a specific bit based on TAC frequency
  #
  # Bit positions for TIMA increment (TAC modes):
  # - Mode 0 (4096 Hz):   bit 9 of internal counter (every 1024 T-states)
  # - Mode 1 (262144 Hz): bit 3 of internal counter (every 16 T-states)
  # - Mode 2 (65536 Hz):  bit 5 of internal counter (every 64 T-states)
  # - Mode 3 (16384 Hz):  bit 7 of internal counter (every 256 T-states)
  class Timer
    # Bit masks for TIMA falling edge detection based on TAC frequency
    TIMA_BIT_MASK = {
      0 => 0x200,  # Bit 9 for 4096 Hz
      1 => 0x008,  # Bit 3 for 262144 Hz
      2 => 0x020,  # Bit 5 for 65536 Hz
      3 => 0x080   # Bit 7 for 16384 Hz
    }.freeze

    def initialize
      # Single internal 16-bit counter (0-65535)
      @internal_counter = 0
      # Track the previous state of the TIMA-triggering bit for falling edge detection
      @prev_tima_bit = false
    end

    def tick(cycles = 0)
      return if cycles == 0

      # Cache TAC once per batch
      tac = $mmu.read_memory_byte(0xFF07)
      timer_enabled = (tac & 0x04) != 0
      old_div = @internal_counter >> 8

      unless timer_enabled
        # Fast path: timer disabled, just advance counter directly
        @internal_counter = (@internal_counter + cycles) & 0xFFFF
        new_div = @internal_counter >> 8
        if new_div != old_div
          $mmu.write_byte(0xFF04, new_div & 0xFF, hardware_operation: true)
        end
        return
      end

      # Timer enabled - use per-cycle loop for falling edge detection
      bit_mask = TIMA_BIT_MASK[tac & 0x03]

      i = 0
      while i < cycles
        old_counter = @internal_counter
        @internal_counter = (@internal_counter + 1) & 0xFFFF

        old_bit = (old_counter & bit_mask) != 0
        new_bit = (@internal_counter & bit_mask) != 0
        inc_tima_register if old_bit && !new_bit

        i += 1
      end

      # Write DIV only if upper byte changed
      new_div = @internal_counter >> 8
      if new_div != old_div
        $mmu.write_byte(0xFF04, new_div & 0xFF, hardware_operation: true)
      end
    end

    # Called when DIV register (0xFF04) is written to - resets internal counter
    def reset_div
      old_counter = @internal_counter
      @internal_counter = 0
      update_div
      # Resetting can trigger TIMA if the selected bit was 1 and becomes 0
      update_tima(old_counter)
    end

    private

    def update_div
      div = (@internal_counter >> 8) & 0xFF
      $mmu.write_byte 0xFF04, div, hardware_operation: true
    end

    def update_tima(old_counter)
      tac = $mmu.read_memory_byte 0xFF07
      return unless tac & 0x04 != 0  # Timer not enabled

      # Get the bit mask for the selected frequency
      freq_mode = tac & 0x03
      bit_mask = TIMA_BIT_MASK[freq_mode]

      # Check for falling edge: old bit was 1, new bit is 0
      old_bit = (old_counter & bit_mask) != 0
      new_bit = (@internal_counter & bit_mask) != 0

      if old_bit && !new_bit
        inc_tima_register
      end
    end

    def inc_tima_register
      tima = $mmu.read_memory_byte 0xFF05
      if tima == 0xFF
        # Overflow: reload from TMA and request interrupt
        tima = $mmu.read_memory_byte 0xFF06
        Interrupt.request_interrupt(Interrupt::INTERRUPT_TIMER)
      else
        tima += 1
      end
      $mmu.write_byte 0xFF05, tima, hardware_operation: true
    end
  end
end
