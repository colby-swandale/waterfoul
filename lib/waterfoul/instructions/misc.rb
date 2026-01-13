module Waterfoul
  module Instructions
    module Misc
      # NOP
      # No operation.
      # @flags - - - -
      def nop
      end

      # STOP 0
      # Power down CPU until an interrupt occurs. Use this when ever possible
      # to reduce energy consumption.
      # @flags - - - -
      def stop_0
        @stop = 1
      end

      # HALT
      # Halt CPU & LCD display until button pressed.
      # @flags - - - -
      def halt
        @pre_halt_interrupt = $mmu.read_memory_byte(0xFF0F)
        @halt = true
      end

      # DI
      # This instruction disables interrupts immediately (unlike EI which has
      # a one-instruction delay). This also cancels any pending EI.
      # @flags - - - -
      def di
        @ime = false
        @ime_pending = false
      end

      # PREFIX CB
      # @flags - - - -
      def prefix_cb
        ins = $mmu.read_byte @pc
        @prefix_cb = ins
        @pc += 1

        opcode = Waterfoul::CPU::CB_OPCODE[ins]
        self.public_send opcode
      end

      # EI
      # Enable interrupts. This intruction enables interrupts but not
      # immediately. Interrupts are enabled after the next instruction
      # is executed.
      # @flags - - - -
      def ei
        @ime_pending = true
      end

      # XX
      # This represents instructions that have been removed and are never
      # suppose to be called.
      def xx
        raise InvalidInstruction
      end
    end
  end
end
