module Waterfoul
  module Instructions
    module Jump
      # JR NZ,r8
      # if Z flag is reset then add immediate value to current address and jump
      # to it
      # @flags - - - -
      def jr_nz_r8
        if (@f & Z_FLAG) == 0x00
          jump = signed_value $mmu.read_byte(@pc)
          result = @pc + 1 + jump
          @pc = result & 0xFFFF
          @branched = true
        else
          @pc += 1
        end
      end

      # JR NC,r8
      # if C flag is reset then add immediate value to current address and jump
      # to it
      # @flags - - - -
      def jr_nc_r8
        if (@f & C_FLAG) == 0x00
          jump = signed_value $mmu.read_byte(@pc)
          result = @pc + 1 + jump
          @pc = result & 0xFFFF
          @branched = true
        else
          @pc += 1
        end
      end

      # JR n
      # Add immediate value to current address and jump to it.
      # flags - - - -
      def jr_r8
        jump = signed_value $mmu.read_byte(@pc)
        result = @pc + 1 + jump
        @pc = result & 0xFFFF
      end

      # JR Z,r8
      # If Z flag is set then add immediate value to current address and jump
      # to it
      # @flags - - - -
      def jr_z_r8
        if (@f & Z_FLAG) == Z_FLAG
          jump = signed_value $mmu.read_byte(@pc)
          result = @pc + 1 + jump
          @pc = result & 0xFFFF
          @branched = true
        else
          @pc += 1
        end
      end

      # JR C,r8
      # If C flag is set then add immediate value to current address and jump
      # to it
      # @flags - - - -
      def jr_c_r8
        if (@f & C_FLAG) == C_FLAG
          jump = signed_value $mmu.read_byte(@pc)
          result = @pc + 1 + jump
          @pc = result & 0xFFFF
          @branched = true
        else
          @pc += 1
        end
      end

      # RET NZ
      # Set PC to memory location stored in the stack if Z flag is reset
      # @flags - - - -
      def ret_nz
        if (@f & Z_FLAG) == 0x00
          @pc = pop_from_stack true
          @branched = true
        end
      end

      # RET NC
      # Set PC to memory location stored in the stack if C flag is reset
      # @flags - - - -
      def ret_nc
        if (@f & C_FLAG) == 0x00
          @pc = pop_from_stack
          @branched = true
        end
      end

      # JP NZ,a16
      # Jump to address from immediate value if Z flag is reset
      # @flags - - - -
      def jp_nz_a16
        if (@f & Z_FLAG) == 0x00
          @pc = $mmu.read_word @pc
          @branched = true
        else
          @pc += 2
        end
      end

      # JP NC,a6
      # Jump to address from immediate value if C flag is reset
      # @flags - - - -
      def jp_nc_a16
        if (@f & C_FLAG) == 0x00
          @pc = $mmu.read_word @pc
          @branched = true
        else
          @pc += 2
        end
      end

      # JP a16
      # Jump to address from immediate value
      # @flags - - - -
      def jp_a16
        @pc = $mmu.read_word @pc
      end

      # CALL NZ,a16
      # store the current PC value onto the stack and call the next address
      # from immediate value if Z flag is reset
      # @flags - - - -
      def call_nz_a16
        # branch if Z flag is reset
        if (@f & Z_FLAG) == 0x00
          new_pc = $mmu.read_word @pc
          @pc += 2
          push_onto_stack @pc
          @pc = new_pc
          @branched = true
        else
          @pc += 2
        end
      end


      # CALL NC,a16
      # Call address if C flag is reset
      # @flags - - - -
      def call_nc_a16
        if (@f & C_FLAG) == 0x00
          new_pc = $mmu.read_word @pc
          @pc += 2
          push_onto_stack @pc
          @pc = new_pc
          @branched = true
        else
          @pc += 2
        end
      end

      # RST 0x00
      # Push present address onto stack. Jump to address 0x00.
      # @flags - - - -
      def rst_00h
        push_onto_stack @pc
        @pc = 0x0
      end

      # RST 0x10
      # Push present address onto stack. Jump to address 0x10.
      # @flags - - - -
      def rst_10h
        push_onto_stack @pc
        @pc = 0x10
      end

      # RST 0x20
      # Push present address onto stack. Jump to address 0x20.
      # @flags - - - -
      def rst_20h
        push_onto_stack @pc
        @pc = 0x20
      end

      # RST 0x30
      # Push present address onto stack. Jump to address 0x30.
      # @flags - - - -
      def rst_30h
        push_onto_stack @pc
        @pc = 0x30
      end

      # RET Z
      # Return if Z flag is set
      def ret_z
        if (@f & Z_FLAG) == Z_FLAG
          @pc = pop_from_stack
          @branched = true
        end
      end

      def ret_c
        if (@f & C_FLAG) == C_FLAG
          @pc = pop_from_stack
          @branched = true
        end
      end

      def ret
        @pc = pop_from_stack
      end

      def reti
        @ime = true
        @pc = pop_from_stack
      end

      def jp_dhl
        @pc = self.hl
      end

      def jp_z_a16
        if (@f & Z_FLAG) == Z_FLAG
          @pc = $mmu.read_word @pc
          @branched = true
        else
          @pc += 2
        end
      end

      def jp_c_a16
        if (@f & C_FLAG) == C_FLAG
          @pc = $mmu.read_word @pc
          @branched = true
        else
          @pc += 2
        end
      end

      def call_z_a16
        if (@f & Z_FLAG) == Z_FLAG
          new_pc = $mmu.read_word @pc
          @pc += 2
          push_onto_stack @pc
          @pc = new_pc
          @branched = true
        else
          @pc += 2
        end
      end

      def call_c_a16
        if (@f & C_FLAG) == C_FLAG
          new_pc = $mmu.read_word @pc
          @pc += 2
          push_onto_stack @pc
          @pc = new_pc
          @branched = true
        else
          @pc += 2
        end
      end

      def call_a16
        new_pc = $mmu.read_word @pc
        @pc += 2
        push_onto_stack @pc
        @pc = new_pc
      end

      # RST 08h
      # Push present address onto stack. Jump to address 0x08
      # @flags - - - -
      def rst_08h
        push_onto_stack @pc
        @pc = 0x8
      end

      # RST 18h
      # Push present address onto stack. Jump to address 0x18
      # @flags - - - -
      def rst_18h
        push_onto_stack @pc
        @pc = 0x18
      end

      # RST 28h
      # Push present address onto stack. Jump to address 0x28
      # @flags - - - -
      def rst_28h
        push_onto_stack @pc
        @pc = 0x28
      end

      # RST 38h
      # Push present address onto stack. Jump to address 0x38
      # @flags - - - -
      def rst_38h
        push_onto_stack @pc
        @pc = 0x38
      end
    end
  end
end
