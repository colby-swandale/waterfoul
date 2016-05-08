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
        @halt = true
      end

      # DI
      # This instruction disables interrupts but not immediately. Interrupts are
      # disabled instruction after DI is executed.
      # @flags - - - -
      def di
        @ime = false
      end

      # PREFIX CB
      # @flags - - - -
      def prefix_cb
        ins = $mmu.read_byte @pc
        @pc += 1

        opcode = Waterfoul::CPU::CB_OPCODE[ins]
        #p "cb opcode: #{opcode}"
        self.public_send opcode
      end

      # EI
      # Enable interrupts. This intruction enables interrupts but not
      # immediately. Interrupts are enabled instruction after EI is
      # executed.
      # @flags - - - -
      def ei
        @ime = true
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
