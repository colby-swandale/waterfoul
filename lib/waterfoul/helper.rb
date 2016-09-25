module Waterfoul
  module Helper
    def pop_from_stack(word = true)
      if word
        val = $mmu.read_word @sp
        @sp += 2
        val
      else
        val = $mmu.read_byte @sp
        @sp += 1
        val
      end
    end

    def push_onto_stack(val, word = true)
      if word
        upper = (val >> 8) & 0xFF
        lower = val & 0xFF

        @sp -= 1
        $mmu.write_byte @sp, upper
        @sp -= 1
        $mmu.write_byte @sp, lower
      else
        @sp -= 1
        $mmu.write_byte @sp, val
      end
    end

    def signed_value(n)
      n > 127 ? (n & 0x7F) - 0x80 : n
    end

    def cb_rotate_right(byte, keep_msb = false)
      bit_out = byte & 0x1
      bit_out == 0x1 ? set_c_flag : reset_c_flag
      if keep_msb
        msb = byte & 0x80
        (byte >> 1) | msb
      else
        byte >> 1
      end
    end

    def cb_rotate_left(byte)
      bit_out = byte & 0x80
      bit_out == 0x80 ? set_c_flag : reset_c_flag
      (byte << 1) & 0xFF
    end

    def rotate_left(byte, through_carry = false)
      rotate :left, byte, through_carry
    end

    def rotate_right(byte, through_carry = false)
      rotate :right, byte, through_carry
    end

    def rotate(direction, byte, through_carry)
      if direction == :left && !through_carry
        bit_out = byte & 0x80 == 0x80 ? 0x1 : 0x0
        bit_out == 0x1 ? set_c_flag : reset_c_flag
        ((byte << 1) & 0xFF) + bit_out
      elsif direction == :left && through_carry
        carry = @f & 0x10 == 0x10 ? 0x1 : 0x0
        byte & 0x80 == 0x80 ? set_c_flag : reset_c_flag
        ((byte << 1) & 0xFF) + carry
      elsif direction == :right && !through_carry
        bit_out = byte & 0x1 == 0x1 ? 0x80 : 0x0
        bit_out == 0x80 ? set_c_flag : reset_c_flag
        (byte >> 1) + bit_out
      elsif direction == :right && through_carry
        carry = @f & 0x10 == 0x10 ? 0x80 : 0x0
        byte & 0x1 == 0x1 ? set_c_flag : reset_c_flag
        (byte >> 1) + carry
      end
    end
  end
end
