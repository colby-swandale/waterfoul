module Waterfoul
  module Instructions
    module Registers
      REGISTERS = %i{ a b c d e h l f sp pc}
      PAIRED_REGISTERS = %i{ bc de hl af }

      def af
        (@a << 8) | @f
      end

      def af=(val)
        @a = (val >> 8) & 0xFF
        @f = val & 0xF0
      end

      def bc
        (@b << 8) | @c
      end

      def bc=(val)
        @b = (val >> 8) & 0xFF
        @c = val & 0xFF
      end

      def de
        (@d << 8) | @e
      end

      def de=(val)
        @d = (val >> 8) & 0xFF
        @e = val & 0xFF
      end

      def hl
        (@h << 8) | @l
      end

      def hl=(val)
        @h = (val >> 8) & 0xFF
        @l = val & 0xFF
      end

      def sp=(val)
        @sp = val
      end

      def set_z_flag
        @f |= Z_FLAG
      end

      def set_c_flag
        @f |= C_FLAG
      end

      def set_n_flag
        @f |= N_FLAG
      end

      def set_h_flag
        @f |= H_FLAG
      end

      def reset_z_flag
        @f &= Z_FLAG ^ 0xFF
      end

      def reset_c_flag
        @f &= C_FLAG ^ 0xFF
      end

      def reset_n_flag
        @f &= N_FLAG ^ 0xFF
      end

      def reset_h_flag
        @f &= H_FLAG ^ 0xFF
      end

      def reset_flags(*flags)
        @f &= flags.inject(:|) ^ 0xFF
      end

      def set_flags(*flags)
        @f |= flags.inject(:|)
      end

      def set_stack_pointer(sp)
        @sp = sp
      end

      def set_program_counter(pc)
        @pc = pc
      end

      def set_register(register, val)
        if REGISTERS.include? register
          instance_variable_set "@#{register.to_sym}", val
        elsif PAIRED_REGISTERS.include? register
          self.send "#{register}=", val
        else
          false
        end
      end
    end
  end
end
