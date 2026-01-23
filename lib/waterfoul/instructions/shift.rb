module Waterfoul
  module Instructions
    module Shift
      # RLA
      # Rotate A left through Carry flag.
      # @flags 0 0 0 C
      def rla
        @a = rotate_left @a, true
        reset_z_flag
        reset_lazy_n
        reset_lazy_h
      end

      # RLCA
      # Rotate A left. Old bit 7 to Carry flag.
      # @flags 0 0 0 C
      def rlca
        @a = rotate_left @a
        reset_z_flag
        reset_lazy_n
        reset_lazy_h
      end

      # RRCA
      # Rotate A right. Old bit 0 to Carry flag
      # @flags 0 0 0 C
      def rrca
        @a = rotate_right @a
        reset_z_flag
        reset_lazy_n
        reset_lazy_h
      end

      # RRA
      # Rotate A right through Carry flag.
      # @flags 0 0 0 C
      def rra
        @a = rotate_right @a, true
        reset_z_flag
        reset_lazy_n
        reset_lazy_h
      end
    end
  end
end
