module Waterfoul
  module Instructions
    module Load

      def ldh_a8_a
        $mmu.write_byte(0xFF00 + $mmu.read_byte(@pc), @a)
        @pc += 1
      end

      def ldh_a_a8
        @a = $mmu.read_byte 0xFF00 + $mmu.read_byte(@pc)
        @pc += 1
      end

      # LD (BC),A
      # Put value A into (BC)
      # @flags - - - -
      def ld_bc_a
        $mmu.write_byte self.bc, @a
      end

      # LD A,(BC)
      # Put value (BC) into A
      # @flags - - - -
      def ld_a_bc
        @a = $mmu.read_byte self.bc
      end

      # LD (DE),A
      # Put value A into (DE)
      # @flags - - - -
      def ld_de_a
        $mmu.write_byte self.de, @a
      end

      # LD A,(DE)
      # Put value (DE) into A
      # @flags - - - -
      def ld_a_de
        @a = $mmu.read_byte self.de
      end

      # LD (HL+),A
      # @flags - - - -
      def ld_hl_plus_a
        $mmu.write_byte self.hl, @a
        self.hl = (self.hl + 1) & 0xFFFF
      end

      # LD (HL-),A
      # @flags - - - -
      def ld_hl_minus_a
        $mmu.write_byte self.hl, @a
        self.hl = (self.hl - 1) & 0xFFFF
      end

      # LD A,(HL+)
      # @flags - - - -
      def ld_a_hl_plus
        @a = $mmu.read_byte self.hl
        self.hl = (self.hl + 1) & 0xFFFF
      end

      # LD A,(HL-)
      # @flags - - - -
      def ld_a_hl_minus
        @a = $mmu.read_byte self.hl
        self.hl = (self.hl - 1) & 0xFFFF
      end

      # LD (HL),A
      # Put value A into (HL)
      # @flags - - - -
      def ld_hl_a
        $mmu.write_byte self.hl, @a
      end

      def ld_b_d8
        @b = $mmu.read_byte @pc
        @pc += 1
      end

      def ld_c_d8
        @c = $mmu.read_byte @pc
        @pc += 1
      end

      def ld_d_d8
        @d = $mmu.read_byte @pc
        @pc += 1
      end

      def ld_e_d8
        @e = $mmu.read_byte @pc
        @pc += 1
      end

      def ld_h_d8
        @h = $mmu.read_byte @pc
        @pc += 1
      end

      def ld_l_d8
        @l = $mmu.read_byte @pc
        @pc += 1
      end

      def ld_hl_d8
        val = $mmu.read_byte @pc
        $mmu.write_byte self.hl, val
        @pc += 1
      end

      def ld_a_d8
        @a = $mmu.read_byte @pc
        @pc += 1
      end

      def ld_b_b
        @b = @b
      end

      def ld_b_c
        @b = @c
      end

      def ld_b_d
        @b = @d
      end

      def ld_b_e
        @b = @e
      end

      def ld_b_h
        @b = @h
      end

      def ld_b_l
        @b = @l
      end

      def ld_b_hl
        @b = $mmu.read_byte self.hl
      end

      def ld_b_a
        @b = @a
      end

      def ld_c_b
        @c = @b
      end

      def ld_c_c
        @c = @c
      end

      def ld_c_d
        @c = @d
      end

      def ld_c_e
        @c = @e
      end

      def ld_c_h
        @c = @h
      end

      def ld_c_l
        @c = @l
      end

      def ld_c_hl
        @c = $mmu.read_byte self.hl
      end

      def ld_c_a
        @c = @a
      end

      def ld_dc_a
        loc = (0xFF00 + @c) & 0xFFFF
        $mmu.write_byte loc, @a
      end

      def ld_a_dc
        loc = (0xFF00 + @c) & 0xFFFF
        @a = $mmu.read_byte loc
      end

      def ld_d_b
        @d = @b
      end

      def ld_d_c
        @d = @c
      end

      def ld_d_d
        @d = @d
      end

      def ld_d_e
        @d = @e
      end

      def ld_d_h
        @d = @h
      end

      def ld_d_l
        @d = @l
      end

      def ld_d_hl
        @d = $mmu.read_byte self.hl
      end

      def ld_d_a
        @d = @a
      end

      def ld_e_b
        @e = @b
      end

      def ld_e_c
        @e = @c
      end

      def ld_e_d
        @e = @d
      end

      def ld_e_e
        @e = @e
      end

      def ld_e_h
        @e = @h
      end

      def ld_e_l
        @e = @l
      end

      def ld_e_hl
        @e = $mmu.read_byte self.hl
      end

      def ld_e_a
        @e = @a
      end

      def ld_h_b
        @h = @b
      end

      def ld_h_c
        @h = @c
      end

      def ld_h_d
        @h = @d
      end

      def ld_h_e
        @h = @e
      end

      def ld_h_h
        @h = @h
      end

      def ld_h_l
        @h = @l
      end

      def ld_h_hl
        @h = $mmu.read_byte self.hl
      end

      def ld_h_a
        @h = @a
      end

      def ld_l_b
        @l = @b
      end

      def ld_l_c
        @l = @c
      end

      def ld_l_d
        @l = @d
      end

      def ld_l_e
        @l = @e
      end

      def ld_l_h
        @l = @h
      end

      def ld_l_l
        @l = @l
      end

      def ld_l_hl
        @l = $mmu.read_byte self.hl
      end

      def ld_l_a
        @l = @a
      end

      def ld_hl_b
        $mmu.write_byte self.hl, @b
      end

      def ld_hl_c
        $mmu.write_byte self.hl, @c
      end

      def ld_hl_d
        $mmu.write_byte self.hl, @d
      end

      def ld_hl_e
        $mmu.write_byte self.hl, @e
      end

      def ld_hl_h
        $mmu.write_byte self.hl, @h
      end

      def ld_hl_l
        $mmu.write_byte self.hl, @l
      end

      def ld_a_b
        @a = @b
      end

      def ld_a_c
        @a = @c
      end

      def ld_a_d
        @a = @d
      end

      def ld_a_e
        @a = @e
      end

      def ld_a_h
        @a = @h
      end

      def ld_a_l
        @a = @l
      end

      def ld_a_hl
        @a = $mmu.read_byte self.hl
      end

      def ld_a_a
        @a = @a
      end

      def ld_a16_a
        addr = $mmu.read_word @pc
        @pc += 2

        $mmu.write_byte addr, @a
      end

      def ld_a_a16
        addr = $mmu.read_word @pc
        @pc += 2

        @a = $mmu.read_byte addr
      end

      def ld_bc_d16
        self.bc = $mmu.read_word @pc
        @pc += 2
      end

      def ld_de_d16
        self.de = $mmu.read_word @pc
        @pc += 2
      end

      def ld_hl_d16
        self.hl = $mmu.read_word @pc
        @pc += 2
      end

      def ld_sp_d16
        @sp = $mmu.read_word @pc
        @pc += 2
      end

      def push_bc
        push_onto_stack self.bc
      end

      def push_de
        push_onto_stack self.de
      end

      def push_hl
        push_onto_stack self.hl
      end

      def push_af
        push_onto_stack self.af
      end

      def ld_a16_sp
        addr = $mmu.read_word @pc
        @pc += 2
        $mmu.write_word addr, @sp
      end

      # LDHL SP,n.
      # @flags 0 0 H C
      def ld_hl_sp_r8
        n = signed_value $mmu.read_byte(@pc)
        @pc += 1
        result = @sp + n

        reset_flags Z_FLAG, N_FLAG
        (@sp ^ n ^ result) & 0x100 == 0x100 ? set_c_flag : reset_c_flag
        (@sp ^ n ^ result) & 0x10 == 0x10 ? set_h_flag : reset_h_flag

        self.hl = result & 0xFFFF
      end

      # LD SP,HL
      # @flags - - - -
      def ld_sp_hl
        @sp = self.hl
      end

      # POP BC
      # @flags - - - -
      def pop_bc
        self.bc = pop_from_stack
      end

      # POP DE
      # @flags - - - -
      def pop_de
        self.de = pop_from_stack
      end

      # POP HL
      # @flags - - - -
      def pop_hl
        self.hl = pop_from_stack
      end

      # POP AF
      # @flags - - - -
      def pop_af
        self.af = pop_from_stack
      end
    end
  end
end
