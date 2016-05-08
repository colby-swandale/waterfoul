module Waterfoul
  module Instructions
    module Prefix
      def rlc_b
        @b = rotate_left @b

        @b & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rlc_c
        @c = rotate_left @c

        @c & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rlc_d
        @d = rotate_left @d

        @d & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rlc_e
        @e = rotate_left @e

        @e & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rlc_h
        @h = rotate_left @h

        @h & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rlc_l
        @l = rotate_left @l

        @l & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rlc_hl
        val = $mmu.read_byte(self.hl)
        val = rotate_left val

        val & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        $mmu.write_byte self.hl, val

        @m = 4
      end

      def rlc_a
        @a = rotate_left @a

        @a & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rrc_b
        @b = rotate_right @b

        @b & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rrc_c
        @c = rotate_right @c

        @c & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rrc_d
        @d = rotate_right @d

        @d & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rrc_e
        @e = rotate_right @e

        @e & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rrc_h
        @h = rotate_right @h

        @h & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rrc_l
        @l = rotate_right @l

        @l & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rrc_hl
        val = $mmu.read_byte(self.hl)
        new_val = rotate_right val

        new_val & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        $mmu.write_byte self.hl, new_val

        @m = 4
      end

      def rrc_a
        @a = rotate_right @a

        @a & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rl_b
        @b = rotate_left @b, true

        @b & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rl_c
        @c = rotate_left @c, true

        @c & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rl_d
        @d = rotate_left @d, true

        @d & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rl_e
        @e = rotate_left @e, true

        @e & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rl_h
        @h = rotate_left @h, true

        @h & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rl_l
        @l = rotate_left @l, true

        @l & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rl_hl
        val = $mmu.read_byte self.hl
        new_val = rotate_left val, true

        $mmu.write_byte self.hl, new_val

        new_val & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 4
      end

      def rl_a
        @a = rotate_left @a, true

        @a & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rr_b
        @b = rotate_right @b, true

        @b & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rr_c
        @c = rotate_right @c, true

        @c & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rr_d
        @d = rotate_right @d, true

        @d & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rr_e
        @e = rotate_right @e, true

        @e & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rr_h
        @h = rotate_right @h, true

        @h & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rr_l
        @l = rotate_right @l, true

        @l & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def rr_hl
        val = $mmu.read_byte self.hl
        new_val = rotate_right val, true

        $mmu.write_byte self.hl, new_val

        new_val & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 4
      end

      def rr_a
        @a = rotate_right @a, true

        @a & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def sla_b
        @b = cb_rotate_left @b

        @b & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def sla_c
        @c = cb_rotate_left @c

        @c & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def sla_d
        @d = cb_rotate_left @d

        @d & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def sla_e
        @e = cb_rotate_left @e

        @e & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def sla_h
        @h = cb_rotate_left @h

        @h & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def sla_l
        @l = cb_rotate_left @l

        @l & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def sla_hl
        val = $mmu.read_byte self.hl
        new_val = cb_rotate_left val

        $mmu.write_byte self.hl, new_val

        new_val & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 3
      end

      def sla_a
        @a = cb_rotate_left @a

        @a & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        @m = 2
      end

      def sra_b
        @b = cb_rotate_right @b, true

        @b & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def sra_c
        @c = cb_rotate_right @c, true

        @c & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def sra_d
        @d = cb_rotate_right @d, true

        @d & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def sra_e
        @e = cb_rotate_right @e, true

        @e & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def sra_h
        @h = cb_rotate_right @h, true

        @h & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def sra_l
        @l = cb_rotate_right @l, true

        @l & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def sra_hl
        val = $mmu.read_byte self.hl
        new_val = cb_rotate_right val, true

        new_val & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        $mmu.write_byte self.hl, new_val
        @m = 3
      end

      def sra_a
        @a = cb_rotate_right @a, true

        @a & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def swap_b
        @b = ((@b << 4) & 0xFF) | (@b >> 4)

        @b & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG, C_FLAG

        @m = 2
      end

      def swap_c
        @c = ((@c << 4) & 0xFF) | (@c >> 4)

        @c & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG, C_FLAG

        @m = 2
      end

      def swap_d
        @d = ((@d << 4) & 0xFF) | (@d >> 4)

        @d & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG, C_FLAG

        @m = 2
      end

      def swap_e
        @e = ((@e << 4) & 0xFF) | (@e >> 4)

        @e & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG, C_FLAG

        @m = 2
      end

      def swap_h
        @h = ((@h << 4) & 0xFF) | (@h >> 4)

        @h & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG, C_FLAG

        @m = 2
      end

      def swap_l
        @l = ((@l << 4) & 0xFF) | (@l >> 4)

        @l & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG, C_FLAG

        @m = 2
      end

      def swap_hl
        val = $mmu.read_byte self.hl
        new_val = ((val << 4) & 0xFF) | (val >> 4)

        new_val & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG, C_FLAG

        $mmu.write_byte self.hl, new_val

        @m = 4
      end

      def swap_a
        @a = ((@a << 4) & 0xFF) | (@a >> 4)

        @a & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG, C_FLAG

        @m = 2
      end

      def srl_b
        @b = cb_rotate_right @b

        @b & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def srl_c
        @c = cb_rotate_right @c

        @c & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def srl_d
        @d = cb_rotate_right @d

        @d & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def srl_e
        @e = cb_rotate_right @e

        @e & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def srl_h
        @h = cb_rotate_right @h

        @h & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def srl_l
        @l = cb_rotate_right @l

        @l & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def srl_hl
        val = $mmu.read_byte self.hl
        new_val = cb_rotate_right val

        new_val & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG

        $mmu.write_byte self.hl, new_val
        @m = 2
      end

      def srl_a
        @a = cb_rotate_right @a

        @a & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_flags N_FLAG, H_FLAG
        @m = 2
      end

      def bit_0_b
        bit = @b & BIT_0 == BIT_0 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_0_c
        bit = @c & BIT_0 == BIT_0 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_0_d
        bit = @d & BIT_0 == BIT_0 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_0_e
        bit = @e & BIT_0 == BIT_0 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_0_h
        bit = @h & BIT_0 == BIT_0 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_0_l
        bit = @l & BIT_0 == BIT_0 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_0_hl
        val = $mmu.read_byte self.hl
        bit = val & BIT_0 == BIT_0 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_0_a
        bit = @a & BIT_0 == BIT_0 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_1_b
        bit = @b & BIT_1 == BIT_1 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_1_c
        bit = @c & BIT_1 == BIT_1 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_1_d
        bit = @d & BIT_1 == BIT_1 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_1_e
        bit = @e & BIT_1 == BIT_1 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_1_h
        bit = @h & BIT_1 == BIT_1 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_1_l
        bit = @l & BIT_1 == BIT_1 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_1_hl
        val = $mmu.read_byte self.hl
        bit = val & BIT_1 == BIT_1 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_1_a
        bit = @a & BIT_1 == BIT_1 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_2_b
        bit = @b & BIT_2 == BIT_2 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_2_c
        bit = @c & BIT_2 == BIT_2 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_2_d
        bit = @d & BIT_2 == BIT_2 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_2_e
        bit = @e & BIT_2 == BIT_2 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_2_h
        bit = @h & BIT_2 == BIT_2 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_2_l
        bit = @l & BIT_2 == BIT_2 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_2_hl
        val = $mmu.read_byte self.hl
        bit = val & BIT_2 == BIT_2 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_2_a
        bit = @a & BIT_2 == BIT_2 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_3_b
        bit = @b & BIT_3 == BIT_3 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_3_c
        bit = @c & BIT_3 == BIT_3 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_3_d
        bit = @d & BIT_3 == BIT_3 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_3_e
        bit = @e & BIT_3 == BIT_3 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_3_h
        bit = @h & BIT_3 == BIT_3 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_3_l
        bit = @l & BIT_3 == BIT_3 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_3_hl
        val = $mmu.read_byte self.hl
        bit = val & BIT_3 == BIT_3 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_3_a
        bit = @a & BIT_3 == BIT_3 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_4_b
        bit = @b & BIT_4 == BIT_4 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_4_c
        bit = @c & BIT_4 == BIT_4 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_4_d
        bit = @d & BIT_4 == BIT_4 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_4_e
        bit = @e & BIT_4 == BIT_4 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_4_h
        bit = @h & BIT_4 == BIT_4 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_4_l
        bit = @l & BIT_4 == BIT_4 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_4_hl
        val = $mmu.read_byte self.hl
        bit = val & BIT_4 == BIT_4 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_4_a
        bit = @a & BIT_4 == BIT_4 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_5_b
        bit = @b & BIT_5 == BIT_5 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_5_c
        bit = @c & BIT_5 == BIT_5 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_5_d
        bit = @d & BIT_5 == BIT_5 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_5_e
        bit = @e & BIT_5 == BIT_5 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_5_h
        bit = @h & BIT_5 == BIT_5 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_5_l
        bit = @l & BIT_5 == BIT_5 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_5_hl
        val = $mmu.read_byte self.hl
        bit = val & BIT_5 == BIT_5 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_5_a
        bit = @a & BIT_5 == BIT_5 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_6_b
        bit = @b & BIT_6 == BIT_6 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_6_c
        bit = @c & BIT_6 == BIT_6 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_6_d
        bit = @d & BIT_6 == BIT_6 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_6_e
        bit = @e & BIT_6 == BIT_6 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_6_h
        bit = @h & BIT_6 == BIT_6 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_6_l
        bit = @l & BIT_6 == BIT_6 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_6_hl
        val = $mmu.read_byte self.hl
        bit = val & BIT_6 == BIT_6 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_6_a
        bit = @a & BIT_6 == BIT_6 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_7_b
        bit = @b & BIT_7 == BIT_7 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_7_c
        bit = @c & BIT_7 == BIT_7 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_7_d
        bit = @d & BIT_7 == BIT_7 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_7_e
        bit = @e & BIT_7 == BIT_7 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_7_h
        bit = @h & BIT_7 == BIT_7 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_7_l
        bit = @l & BIT_7 == BIT_7 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_7_hl
        val = $mmu.read_byte self.hl
        bit = val & BIT_7 == BIT_7 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def bit_7_a
        bit = @a & BIT_7 == BIT_7 ? 1 : 0

        bit & 0xFF == 0x0 ? set_z_flag : reset_z_flag
        reset_n_flag
        set_h_flag

        @m = 2
      end

      def res_0_b
        @b &= BIT_0 ^ 0xFF

        @m = 2
      end

      def res_0_c
        @c &= BIT_0 ^ 0xFF
        @m = 2
      end

      def res_0_d
        @d &= BIT_0 ^ 0xFF
        @m = 2
      end

      def res_0_e
        @e &= BIT_0 ^ 0xFF
        @m = 2
      end

      def res_0_h
        @h &= BIT_0 ^ 0xFF
        @m = 2
      end

      def res_0_l
        @l &= BIT_0 ^ 0xFF
        @m = 2
      end

      def res_0_hl
        val = $mmu.read_byte self.hl
        val &= BIT_0 ^ 0xFF
        $mmu.write_byte self.hl, val
        @m = 4
      end

      def res_0_a
        @a &= BIT_0 ^ 0xFF
        @m = 2
      end

      def res_1_b
        @b &= BIT_1 ^ 0xFF
        @m = 2
      end

      def res_1_c
        @c &= BIT_1 ^ 0xFF
        @m = 2
      end

      def res_1_d
        @d &= BIT_1 ^ 0xFF
        @m = 2
      end

      def res_1_e
        @e &= BIT_1 ^ 0xFF
        @m = 2
      end

      def res_1_h
        @h &= BIT_1 ^ 0xFF
        @m = 2
      end

      def res_1_l
        @l &= BIT_1 ^ 0xFF
        @m = 2
      end

      def res_1_hl
        val = $mmu.read_byte self.hl
        val &= BIT_1 ^ 0xFF
        $mmu.write_byte self.hl, val

        @m = 4
      end

      def res_1_a
        @a &= BIT_1 ^ 0xFF
        @m = 2
      end

      def res_2_b
        @b &= BIT_2 ^ 0xFF
        @m = 2
      end

      def res_2_c
        @c &= BIT_2 ^ 0xFF
        @m = 2
      end

      def res_2_d
        @d &= BIT_2 ^ 0xFF
        @m = 2
      end

      def res_2_e
        @e &= BIT_2 ^ 0xFF
        @m = 2
      end

      def res_2_h
        @h &= BIT_2 ^ 0xFF
        @m = 2
      end

      def res_2_l
        @l &= BIT_2 ^ 0xFF
        @m = 2
      end

      def res_2_hl
        val = $mmu.read_byte self.hl
        val &= BIT_2 ^ 0xFF
        $mmu.write_byte self.hl, val

        @m = 4
      end

      def res_2_a
        @a &= BIT_2 ^ 0xFF
        @m = 2
      end

      def res_3_b
        @b &= BIT_3 ^ 0xFF
        @m = 2
      end

      def res_3_c
        @c &= BIT_3 ^ 0xFF
        @m = 2
      end

      def res_3_d
        @d &= BIT_3 ^ 0xFF
        @m = 2
      end

      def res_3_e
        @e &= BIT_3 ^ 0xFF
        @m = 2
      end

      def res_3_h
        @h &= BIT_3 ^ 0xFF
        @m = 2
      end

      def res_3_l
        @l &= BIT_3 ^ 0xFF
        @m = 2
      end

      def res_3_hl
        val = $mmu.read_byte self.hl
        val &= BIT_3 ^ 0xFF
        $mmu.write_byte self.hl, val

        @m = 4
      end

      def res_3_a
        @a &= BIT_3 ^ 0xFF
        @m = 2
      end

      def res_4_b
        @b &= BIT_4 ^ 0xFF
        @m = 2
      end

      def res_4_c
        @c &= BIT_4 ^ 0xFF
        @m = 2
      end

      def res_4_d
        @d &= BIT_4 ^ 0xFF
        @m = 2
      end

      def res_4_e
        @e &= BIT_4 ^ 0xFF
        @m = 2
      end

      def res_4_h
        @h &= BIT_4 ^ 0xFF
        @m = 2
      end

      def res_4_l
        @l &= BIT_4 ^ 0xFF
        @m = 2
      end

      def res_4_hl
        val = $mmu.read_byte self.hl
        val &= BIT_4 ^ 0xFF
        $mmu.write_byte self.hl, val

        @m = 4
      end

      def res_4_a
        @a &= BIT_4 ^ 0xFF
        @m = 2
      end

      def res_5_b
        @b &= BIT_5 ^ 0xFF
        @m = 2
      end

      def res_5_c
        @c &= BIT_5 ^ 0xFF
        @m = 2
      end

      def res_5_d
        @d &= BIT_5 ^ 0xFF
        @m = 2
      end

      def res_5_e
        @e &= BIT_5 ^ 0xFF
        @m = 2
      end

      def res_5_h
        @h &= BIT_5 ^ 0xFF
        @m = 2
      end

      def res_5_l
        @l &= BIT_5 ^ 0xFF
        @m = 2
      end

      def res_5_hl
        val = $mmu.read_byte self.hl
        val &= BIT_5 ^ 0xFF
        $mmu.write_byte self.hl, val

        @m = 4
      end

      def res_5_a
        @a &= BIT_5 ^ 0xFF
        @m = 2
      end

      def res_6_b
        @b &= BIT_6 ^ 0xFF
        @m = 2
      end

      def res_6_c
        @c &= BIT_6 ^ 0xFF
        @m = 2
      end

      def res_6_d
        @d &= BIT_6 ^ 0xFF
        @m = 2
      end

      def res_6_e
        @e &= BIT_6 ^ 0xFF
        @m = 2
      end

      def res_6_h
        @h &= BIT_6 ^ 0xFF
        @m = 2
      end

      def res_6_l
        @l &= BIT_6 ^ 0xFF
        @m = 2
      end

      def res_6_hl
        val = $mmu.read_byte self.hl
        val &= BIT_6 ^ 0xFF
        $mmu.write_byte self.hl, val

        @m = 4
      end

      def res_6_a
        @a &= BIT_6 ^ 0xFF
        @m = 2
      end

      def res_7_b
        @b &= BIT_7 ^ 0xFF
        @m = 2
      end

      def res_7_c
        @c &= BIT_7 ^ 0xFF
        @m = 2
      end

      def res_7_d
        @d &= BIT_7 ^ 0xFF
        @m = 2
      end

      def res_7_e
        @e &= BIT_7 ^ 0xFF
        @m = 2
      end

      def res_7_h
        @h &= BIT_7 ^ 0xFF
        @m = 2
      end

      def res_7_l
        @l &= BIT_7 ^ 0xFF
        @m = 2
      end

      def res_7_hl
        val = $mmu.read_byte self.hl
        val &= BIT_7 ^ 0xFF
        $mmu.write_byte self.hl, val

        @m = 4
      end

      def res_7_a
        @a &= BIT_7 ^ 0xFF
        @m = 2
      end

      def set_0_b
        @b |= BIT_0
        @m = 2
      end

      def set_0_c
        @c |= BIT_0
        @m = 2
      end

      def set_0_d
        @d |= BIT_0
        @m = 2
      end

      def set_0_e
        @e |= BIT_0
        @m = 2
      end

      def set_0_h
        @h |= BIT_0
        @m = 2
      end

      def set_0_l
        @l |= BIT_0
        @m = 2
      end

      def set_0_hl
        val = $mmu.read_byte self.hl
        val |= BIT_0
        $mmu.write_byte self.hl, val

        @m = 4
      end

      def set_0_a
        @a |= BIT_0
        @m = 2
      end

      def set_1_b
        @b |= BIT_1
        @m = 2
      end

      def set_1_c
        @c |= BIT_1
        @m = 2
      end

      def set_1_d
        @d |= BIT_1
        @m = 2
      end

      def set_1_e
        @e |= BIT_1
        @m = 2
      end

      def set_1_h
        @h |= BIT_1
        @m = 2
      end

      def set_1_l
        @l |= BIT_1
        @m = 2
      end

      def set_1_hl
        val = $mmu.read_byte self.hl
        val |= BIT_1
        $mmu.write_byte self.hl, val

        @m = 4
      end

      def set_1_a
        @a |= BIT_1
        @m = 2
      end

      def set_2_b
        @b |= BIT_2
        @m = 2
      end

      def set_2_c
        @c |= BIT_2
        @m = 2
      end

      def set_2_d
        @d |= BIT_2
        @m = 2
      end

      def set_2_e
        @e |= BIT_2
        @m = 2
      end

      def set_2_h
        @h |= BIT_2
        @m = 2
      end

      def set_2_l
        @l |= BIT_2
        @m = 2
      end

      def set_2_hl
        val = $mmu.read_byte self.hl
        val |= BIT_2
        $mmu.write_byte self.hl, val

        @m = 4
      end

      def set_2_a
        @a |= BIT_2
        @m = 2
      end

      def set_3_b
        @b |= BIT_3
        @m = 2
      end

      def set_3_c
        @c |= BIT_3
        @m = 2
      end

      def set_3_d
        @d |= BIT_3
        @m = 2
      end

      def set_3_e
        @e |= BIT_3
        @m = 2
      end

      def set_3_h
        @h |= BIT_3
        @m = 2
      end

      def set_3_l
        @l |= BIT_3
        @m = 2
      end

      def set_3_hl
        val = $mmu.read_byte self.hl
        val |= BIT_3
        $mmu.write_byte self.hl, val
        @m = 4
      end

      def set_3_a
        @a |= BIT_3
        @m = 2
      end

      def set_4_b
        @b |= BIT_4
        @m = 2
      end

      def set_4_c
        @c |= BIT_4
        @m = 2
      end

      def set_4_d
        @d |= BIT_4
        @m = 2
      end

      def set_4_e
        @e |= BIT_4
        @m = 2
      end

      def set_4_h
        @h |= BIT_4
        @m = 2
      end

      def set_4_l
        @l |= BIT_4
        @m = 2
      end

      def set_4_hl
        val = $mmu.read_byte self.hl
        new_val = val | BIT_4
        $mmu.write_byte self.hl, new_val
        @m = 4
      end

      def set_4_a
        @a |= BIT_4
        @m = 2
      end

      def set_5_b
        @b |= BIT_5
        @m = 2
      end

      def set_5_c
        @c |= BIT_5
        @m = 2
      end

      def set_5_d
        @d |= BIT_5
        @m = 2
      end

      def set_5_e
        @e |= BIT_5
        @m = 2
      end

      def set_5_h
        @h |= BIT_5
        @m = 2
      end

      def set_5_l
        @l |= BIT_5
        @m = 2
      end

      def set_5_hl
        val = $mmu.read_byte self.hl
        val |= BIT_5
        $mmu.write_byte self.hl, val
        @m = 4
      end

      def set_5_a
        @a |= BIT_5
        @m = 2
      end

      def set_6_b
        @b |= BIT_6
        @m = 2
      end

      def set_6_c
        @c |= BIT_6
        @m = 2
      end

      def set_6_d
        @d |= BIT_6
        @m = 2
      end

      def set_6_e
        @e |= BIT_6
        @m = 2
      end

      def set_6_h
        @h |= BIT_6
        @m = 2
      end

      def set_6_l
        @l |= BIT_6
        @m = 2
      end

      def set_6_hl
        val = $mmu.read_byte self.hl
        val |= BIT_6
        $mmu.write_byte self.hl, val
        @m = 4
      end

      def set_6_a
        @a |= BIT_6
        @m = 2
      end

      def set_7_b
        @b |= BIT_7
        @m = 2
      end

      def set_7_c
        @c |= BIT_7
        @m = 2
      end

      def set_7_d
        @d |= BIT_7
        @m = 2
      end

      def set_7_e
        @e |= BIT_7
        @m = 2
      end

      def set_7_h
        @h |= BIT_7
        @m = 2
      end

      def set_7_l
        @l |= BIT_7
        @m = 2
      end

      def set_7_hl
        val = $mmu.read_byte self.hl
        val |= BIT_7
        $mmu.write_byte self.hl, val

        @m = 4
      end

      def set_7_a
        @a |= BIT_7
        @m = 2
      end
    end
  end
end
