module Waterfoul
  module Instructions
    module Logic
      ######################################
      ## 8 BIT LOGICAL INSTRUCTIONS
      ######################################

      # 8 bit arythmatic/logical instrucitons
      def inc_b
        result = @b + 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0x0 ? set_h_flag : reset_h_flag
        reset_n_flag

        @b = result & 0xFF
      end

      def dec_b
        result = @b - 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0xF ? set_h_flag : reset_h_flag
        set_n_flag

        @b = result & 0xFF
      end

      def inc_c
        result = @c + 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0x0 ? set_h_flag : reset_h_flag
        reset_n_flag

        @c = result & 0xFF
      end

      def dec_c
        result = @c - 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0xF ? set_h_flag : reset_h_flag
        set_n_flag

        @c = result & 0xFF
      end

      def inc_d
        result = @d + 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0x0 ? set_h_flag : reset_h_flag
        reset_n_flag

        @d = result & 0xFF
      end

      def dec_d
        result = @d - 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0xF ? set_h_flag : reset_h_flag
        set_n_flag

        @d = result & 0xFF
      end

      def inc_e
        result = @e + 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0x0 ? set_h_flag : reset_h_flag
        reset_n_flag

        @e = result & 0xFF
      end

      def dec_e
        result = @e - 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0xF ? set_h_flag : reset_h_flag
        set_n_flag

        @e = result & 0xFF
      end

      def inc_h
        result = @h + 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0x0 ? set_h_flag : reset_h_flag
        reset_n_flag

        @h = result & 0xFF
      end

      def dec_h
        result = @h - 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0xF ? set_h_flag : reset_h_flag
        set_n_flag

        @h = result & 0xFF
      end

      def inc_l
        result = @l + 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0x0 ? set_h_flag : reset_h_flag
        reset_n_flag

        @l = result & 0xFF
      end

      def dec_l
        result = @l - 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0xF ? set_h_flag : reset_h_flag
        set_n_flag

        @l = result & 0xFF
      end

      def dec_a
        result = @a - 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0xF ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def inc_a
        result = @a + 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0x0 ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def inc__hl
        val = $mmu.read_byte self.hl
        result = val + 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0x00 ? set_h_flag : reset_h_flag
        reset_n_flag

        $mmu.write_byte self.hl, (result & 0xFF)
      end

      def dec__hl
        val = $mmu.read_byte self.hl
        result = val - 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result & 0xF == 0xF ? set_h_flag : reset_h_flag
        set_n_flag

        $mmu.write_byte self.hl, (result & 0xFF)
      end

      def daa
        temp_a = @a

        if @f & N_FLAG == 0x00
          if @f & H_FLAG == H_FLAG || (temp_a & 0xF) > 0x9
            temp_a = temp_a + 0x06
          end

          if @f & C_FLAG == C_FLAG || (temp_a > 0x9F)
            temp_a = temp_a + 0x60
          end
        else
          if @f & H_FLAG == H_FLAG
            temp_a = (temp_a - 0x06) & 0xFF
          end

          if @f & C_FLAG == C_FLAG
            temp_a = temp_a - 0x60
          end
        end

        reset_flags H_FLAG, Z_FLAG

        if temp_a & 0x100 == 0x100
          set_flags C_FLAG
        end

        temp_a = temp_a & 0xFF

        set_flags Z_FLAG if temp_a == 0x0

        @a = temp_a
      end

      def scf
        set_c_flag
        reset_flags N_FLAG, H_FLAG
      end

      def cpl
        @a = @a ^ 0xFF
        set_flags N_FLAG, H_FLAG
      end

      # CCF
      # Complement carry flag. If C flag is set, then reset it.
      # If C flag is reset, then set it.
      # @flags - 0 0 C
      def ccf
        @f & C_FLAG == C_FLAG ? reset_c_flag : set_c_flag
        reset_flags N_FLAG, H_FLAG
      end

      def add_a_b
        result = @a + @b

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @b ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @b ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def add_a_c
        result = @a + @c

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @c ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @c ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def add_a_d
        result = @a + @d

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @d ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @d ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def add_a_e
        result = @a + @e

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @e ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @e ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def add_a_h
        result = @a + @h

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @h ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @h ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def add_a_l
        result = @a + @l

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @l ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @l ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def add_a_hl
        val = $mmu.read_byte self.hl
        result = @a + val

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ val ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ val ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def add_a_a
        result = @a + @a

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @a ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @a ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def adc_a_b
        carry = @f & C_FLAG == C_FLAG ? 1 : 0
        result = @a + @b + carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result > 0xFF ? set_c_flag : reset_c_flag
        (@a & 0xF) + (@b & 0xF) + carry > 0xF ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def adc_a_c
        carry = @f & C_FLAG == C_FLAG ? 1 : 0
        result = @a + @c + carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result > 0xFF ? set_c_flag : reset_c_flag
        (@a & 0xF) + (@c & 0xF) + carry > 0xF ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def adc_a_d
        carry = @f & C_FLAG == C_FLAG ? 1 : 0
        result = @a + @d + carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result > 0xFF ? set_c_flag : reset_c_flag
        (@a & 0xF) + (@d & 0xF) + carry > 0xF ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def adc_a_e
        carry = @f & C_FLAG == C_FLAG ? 1 : 0
        result = @a + @e + carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result > 0xFF ? set_c_flag : reset_c_flag
        (@a & 0xF) + (@e & 0xF) + carry > 0xF ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def adc_a_h
        carry = @f & C_FLAG == C_FLAG ? 1 : 0
        result = @a + @h + carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result > 0xFF ? set_c_flag : reset_c_flag
        (@a & 0xF) + (@h & 0xF) + carry > 0xF ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def adc_a_l
        carry = @f & C_FLAG == C_FLAG ? 1 : 0
        result = @a + @l + carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result > 0xFF ? set_c_flag : reset_c_flag
        (@a & 0xF) + (@l & 0xF) + carry > 0xF ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def adc_a_hl
        val = $mmu.read_byte self.hl
        carry = @f & C_FLAG == C_FLAG ? 1 : 0
        result = @a + val + carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result > 0xFF ? set_c_flag : reset_c_flag
        ((@a & 0xF) + (val & 0xF) + carry) > 0xF ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def adc_a_a
        carry = @f & C_FLAG == C_FLAG ? 1 : 0
        result = @a + @a + carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result > 0xFF ? set_c_flag : reset_c_flag
        (@a & 0xF) + (@a & 0xF) + carry > 0xF ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def sub_b
        result = @a - @b

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @b ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @b ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sub_c
        result = @a - @c

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @c ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @c ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sub_d
        result = @a - @d

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @d ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @d ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sub_e
        result = @a - @e

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @e ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @e ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sub_h
        result = @a - @h

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @h ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @h ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sub_l
        result = @a - @l

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @l ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @l ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sub_hl
        val = $mmu.read_byte self.hl
        result = @a - val

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ val ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ val ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sub_a
        result = @a - @a

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ @a ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ @a ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sbc_a_b
        carry = @f & C_FLAG == C_FLAG ? 0x1 : 0x0
        result = @a - @b - carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result < 0x0 ? set_c_flag : reset_c_flag
        (@a & 0xF) - (@b & 0xF) - carry < 0 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sbc_a_c
        carry = @f & C_FLAG == C_FLAG ? 0x1 : 0x0
        result = @a - @c - carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result < 0x0 ? set_c_flag : reset_c_flag
        (@a & 0xF) - (@c & 0xF) - carry < 0 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sbc_a_d
        carry = @f & C_FLAG == C_FLAG ? 0x1 : 0x0
        result = @a - @d - carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result < 0x0 ? set_c_flag : reset_c_flag
        (@a & 0xF) - (@d & 0xF) - carry < 0 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sbc_a_e
        carry = @f & C_FLAG == C_FLAG ? 0x1 : 0x0
        result = @a - @e - carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result < 0x0 ? set_c_flag : reset_c_flag
        (@a & 0xF) - (@e & 0xF) - carry < 0 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sbc_a_h
        carry = @f & C_FLAG == C_FLAG ? 0x1 : 0x0
        result = @a - @h - carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result < 0x0 ? set_c_flag : reset_c_flag
        (@a & 0xF) - (@h & 0xF) - carry < 0 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sbc_a_l
        carry = @f & C_FLAG == C_FLAG ? 0x1 : 0x0
        result = @a - @l - carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result < 0x0 ? set_c_flag : reset_c_flag
        (@a & 0xF) - (@l & 0xF) - carry < 0 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sbc_a_hl
        val = $mmu.read_byte self.hl
        carry = @f & C_FLAG == C_FLAG ? 0x1 : 0x0
        result = @a - val - carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result < 0x0 ? set_c_flag : reset_c_flag
        (@a & 0xF) - (val & 0xF) - carry < 0 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sbc_a_a
        carry = @f & C_FLAG == C_FLAG ? 0x1 : 0x0
        result = @a - @a - carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result < 0x0 ? set_c_flag : reset_c_flag
        (@a & 0xF) - (@a & 0xF) - carry < 0 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def and_b
        result = @a & @b

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, N_FLAG
        set_flags H_FLAG

        @a = result & 0xFF
      end

      def and_c
        result = @a & @c

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, N_FLAG
        set_flags H_FLAG

        @a = result & 0xFF
      end

      def and_d
        result = @a & @d

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, N_FLAG
        set_flags H_FLAG

        @a = result & 0xFF
      end

      def and_e
        result = @a & @e

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, N_FLAG
        set_flags H_FLAG

        @a = result & 0xFF
      end

      def and_h
        result = @a & @h

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, N_FLAG
        set_flags H_FLAG

        @a = result & 0xFF
      end

      def and_l
        result = @a & @l

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, N_FLAG
        set_flags H_FLAG

        @a = result & 0xFF
      end

      def and_hl
        val = $mmu.read_byte self.hl
        result = @a & val

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, N_FLAG
        set_flags H_FLAG

        @a = result & 0xFF
      end

      def and_a
        result = @a & @a

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, N_FLAG
        set_flags H_FLAG

        @a = result & 0xFF
      end

      def xor_b
        result = @a ^ @b

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def xor_c
        result = @a ^ @c

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def xor_d
        result = @a ^ @d

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def xor_e
        result = @a ^ @e

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def xor_h
        result = @a ^ @h

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def xor_l
        result = @a ^ @l

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def xor_hl
        val = $mmu.read_byte self.hl
        result = @a ^ val

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def xor_a
        result = @a ^ @a

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def or_b
        result = @a | @b

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def or_c
        result = @a | @c

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def or_d
        result = @a | @d

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def or_e
        result = @a | @e

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def or_h
        result = @a | @h

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def or_l
        result = @a | @l

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def or_hl
        val = $mmu.read_byte self.hl
        result = @a | val

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def or_a
        result = @a | @a

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def cp_b
        result = @a - @b

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        @a < @b ? set_c_flag : reset_c_flag
        (result & 0xF) > (@a & 0xF) ? set_h_flag : reset_h_flag
        set_n_flag
      end

      def cp_c
        result = @a - @c

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        @a < @c ? set_c_flag : reset_c_flag
        (result & 0xF) > (@a & 0xF) ? set_h_flag : reset_h_flag
        set_n_flag
      end

      def cp_d
        result = @a - @d

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        @a < @d ? set_c_flag : reset_c_flag
        (result & 0xF) > (@a & 0xF) ? set_h_flag : reset_h_flag
        set_n_flag
      end

      def cp_e
        result = @a - @e

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        @a < @e ? set_c_flag : reset_c_flag
        (result & 0xF) > (@a & 0xF) ? set_h_flag : reset_h_flag
        set_n_flag
      end

      def cp_h
        result = @a - @h

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        @a < @h ? set_c_flag : reset_c_flag
        (result & 0xF) > (@a & 0xF) ? set_h_flag : reset_h_flag
        set_n_flag
      end

      def cp_l
        result = @a - @l

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        @a < @l ? set_c_flag : reset_c_flag
        (result & 0xF) > (@a & 0xF) ? set_h_flag : reset_h_flag
        set_n_flag
      end

      def cp_hl
        val = $mmu.read_byte self.hl
        result = @a - val

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        @a < val ? set_c_flag : reset_c_flag
        (result & 0xF) > (@a & 0xF) ? set_h_flag : reset_h_flag
        set_n_flag
      end

      def cp_a
        result = @a - @a

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        @a < @a ? set_c_flag : reset_c_flag
        (result & 0xF) > (@a & 0xF) ? set_h_flag : reset_h_flag
        set_n_flag
      end

      def add_a_d8
        val = $mmu.read_byte @pc
        result = @a + val
        @pc += 1

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ val ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ val ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def adc_a_d8
        val = $mmu.read_byte @pc
        @pc += 1

        carry = @f & C_FLAG == C_FLAG ? 1 : 0
        result = @a + val + carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result > 0xFF ? set_c_flag : reset_c_flag
        (@a & 0xF) + (val & 0xF) + carry > 0xF ? set_h_flag : reset_h_flag
        reset_n_flag

        @a = result & 0xFF
      end

      def sub_d8
        val = $mmu.read_byte @pc
        @pc += 1
        result = @a - val

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        (@a ^ val ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@a ^ val ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def sbc_a_d8
        val = $mmu.read_byte @pc
        @pc += 1

        carry = @f & C_FLAG == C_FLAG ? 1 : 0
        result = @a - val - carry

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        result < 0 ? set_c_flag : reset_c_flag
        (@a & 0xF) - (val & 0xF) - carry < 0 ? set_h_flag : reset_h_flag
        set_n_flag

        @a = result & 0xFF
      end

      def and_d8
        val = $mmu.read_byte @pc
        @pc += 1

        result = @a & val

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, N_FLAG
        set_flags H_FLAG

        @a = result & 0xFF
      end

      def xor_d8
        val = $mmu.read_byte @pc
        @pc += 1

        result = @a ^ val

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def or_d8
        val = $mmu.read_byte @pc
        @pc += 1

        result = @a | val

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags C_FLAG, H_FLAG, N_FLAG

        @a = result & 0xFF
      end

      def cp_d8
        val = $mmu.read_byte @pc
        @pc += 1

        result = @a - val

        result & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        @a < val ? set_c_flag : reset_c_flag
        (result & 0xF) > (@a & 0xF) ? set_h_flag : reset_h_flag
        set_n_flag
      end


      ######################################
      ## 16 BIT LOGICAL INSTRUCTIONS
      ######################################

      def inc_bc
        self.bc = (self.bc + 1) & 0xFFFF
      end

      def inc_de
        self.de = (self.de + 1) & 0xFFFF
      end

      def inc_hl
        self.hl = (self.hl + 1) & 0xFFFF
      end

      def inc_sp
        @sp = @sp + 1 & 0xFFFF
      end

      def add_hl_bc
        result = self.hl + self.bc

        reset_n_flag
        result & 0x10000 == 0x10000 ? set_c_flag : reset_c_flag
        (self.hl ^ self.bc ^ (result & 0xFFFF)) & 0x1000 == 0x1000 ? set_h_flag : reset_h_flag

        self.hl = result & 0xFFFF
      end

      def add_hl_de
        result = self.hl + self.de

        reset_n_flag
        result & 0x10000 == 0x10000 ? set_c_flag : reset_c_flag
        (self.hl ^ self.de ^ (result & 0xFFFF)) & 0x1000 == 0x1000 ? set_h_flag : reset_h_flag

        self.hl = result & 0xFFFF
      end

      def add_hl_hl
        result = self.hl + self.hl

        reset_n_flag
        result & 0x10000 == 0x10000 ? set_c_flag : reset_c_flag
        (self.hl ^ self.hl ^ (result & 0xFFFF)) & 0x1000 == 0x1000 ? set_h_flag : reset_h_flag

        self.hl = result & 0xFFFF
      end

      def add_hl_sp
        result = self.hl + @sp

        reset_n_flag
        result & 0x10000 == 0x10000 ? set_c_flag : reset_c_flag
        (self.hl ^ @sp ^ (result & 0xFFFF)) & 0x1000 == 0x1000 ? set_h_flag : reset_h_flag

        self.hl = result & 0xFFFF
      end

      def dec_bc
        self.bc = (self.bc - 1) & 0xFFFF
      end

      def dec_de
        self.de = (self.de - 1) & 0xFFFF
      end

      def dec_hl
        self.hl = (self.hl - 1) & 0xFFFF
      end

      def dec_sp
        @sp = (@sp - 1) & 0xFFFF
      end

      def add_sp_r8
        val = signed_value $mmu.read_byte @pc
        @pc += 1

        result = @sp + val

        reset_flags Z_FLAG, N_FLAG
        (@sp ^ val ^ (result & 0xFFFF)) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@sp ^ val ^ (result & 0xFFFF)) & 0x10 == 0x10 ? set_h_flag : reset_h_flag

        @sp = result & 0xFFFF
      end
    end
  end
end
