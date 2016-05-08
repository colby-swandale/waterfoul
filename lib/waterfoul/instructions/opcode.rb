module Waterfoul
  module Instructions
    ##
    # The opcode is the set of CPU instructions that can be performed. Each item in the
    # hash is made of its position in the OPCODE set and the name of the corresponding method that
    # implements the instruction
    #
    module Opcode
      OPCODE = [
        # 0x00
        :nop, :ld_bc_d16, :ld_bc_a, :inc_bc, :inc_b, :dec_b, :ld_b_d8, :rlca, :ld_a16_sp,
        :add_hl_bc, :ld_a_bc, :dec_bc, :inc_c, :dec_c, :ld_c_d8, :rrca,
        # 0x10
        :stop_0, :ld_de_d16, :ld_de_a, :inc_de, :inc_d, :dec_d, :ld_d_d8, :rla, :jr_r8,
        :add_hl_de, :ld_a_de, :dec_de, :inc_e, :dec_e, :ld_e_d8, :rra,
        # 0x20
        :jr_nz_r8, :ld_hl_d16, :ld_hl_plus_a, :inc_hl, :inc_h, :dec_h, :ld_h_d8, :daa,
        :jr_z_r8, :add_hl_hl, :ld_a_hl_plus, :dec_hl, :inc_l, :dec_l, :ld_l_d8, :cpl,
        # 0x30
        :jr_nc_r8, :ld_sp_d16, :ld_hl_minus_a, :inc_sp, :inc__hl, :dec__hl, :ld_hl_d8, :scf,
        :jr_c_r8, :add_hl_sp, :ld_a_hl_minus, :dec_sp, :inc_a, :dec_a, :ld_a_d8, :ccf,
        # 0x40
        :ld_b_b, :ld_b_c, :ld_b_d, :ld_b_e, :ld_b_h, :ld_b_l, :ld_b_hl, :ld_b_a, :ld_c_b,
        :ld_c_c, :ld_c_d, :ld_c_e, :ld_c_h, :ld_c_l, :ld_c_hl, :ld_c_a,
        # 0x50
        :ld_d_b, :ld_d_c, :ld_d_d, :ld_d_e, :ld_d_h, :ld_d_l, :ld_d_hl, :ld_d_a, :ld_e_b,
        :ld_e_c, :ld_e_d, :ld_e_e, :ld_e_h, :ld_e_l, :ld_e_hl, :ld_e_a,
        # 0x60
        :ld_h_b, :ld_h_c, :ld_h_d, :ld_h_e, :ld_h_h, :ld_h_l, :ld_h_hl, :ld_h_a, :ld_l_b,
        :ld_l_c, :ld_l_d, :ld_l_e, :ld_l_h, :ld_l_l, :ld_l_hl, :ld_l_a,
        # 0x70
        :ld_hl_b, :ld_hl_c, :ld_hl_d, :ld_hl_e, :ld_hl_h, :ld_hl_l, :halt, :ld_hl_a, :ld_a_b,
        :ld_a_c, :ld_a_d, :ld_a_e, :ld_a_h, :ld_a_l, :ld_a_hl, :ld_a_a,
        # 0x80
        :add_a_b, :add_a_c, :add_a_d, :add_a_e, :add_a_h, :add_a_l, :add_a_hl, :add_a_a, :adc_a_b,
        :adc_a_c, :adc_a_d, :adc_a_e, :adc_a_h, :adc_a_l, :adc_a_hl, :adc_a_a,
        # 0x90
        :sub_b, :sub_c, :sub_d, :sub_e, :sub_h, :sub_l, :sub_hl, :sub_a, :sbc_a_b, :sbc_a_c, :sbc_a_d,
        :sbc_a_e, :sbc_a_h, :sbc_a_l, :sbc_a_hl, :sbc_a_a,
        # 0xA0
        :and_b, :and_c, :and_d, :and_e, :and_h, :and_l, :and_hl, :and_a, :xor_b, :xor_c, :xor_d, :xor_e,
        :xor_h, :xor_l, :xor_hl, :xor_a,
        # 0xB0
        :or_b, :or_c, :or_d, :or_e, :or_h, :or_l, :or_hl, :or_a, :cp_b, :cp_c, :cp_d, :cp_e, :cp_h, :cp_l,
        :cp_hl, :cp_a,
        # 0xC0
        :ret_nz, :pop_bc, :jp_nz_a16, :jp_a16, :call_nz_a16, :push_bc, :add_a_d8, :rst_00h, :ret_z, :ret,
        :jp_z_a16, :prefix_cb, :call_z_a16, :call_a16, :adc_a_d8, :rst_08h,
        # 0xD0
        :ret_nc, :pop_de, :jp_nc_a16, :xx, :call_nc_a16, :push_de, :sub_d8, :rst_10h, :ret_c, :reti, :jp_c_a16, :xx,
        :call_c_a16, :xx, :sbc_a_d8, :rst_18h,
        # 0xE0
        :ldh_a8_a, :pop_hl, :ld_dc_a, :xx, :xx, :push_hl, :and_d8, :rst_20h, :add_sp_r8, :jp_dhl, :ld_a16_a,
        :xx, :xx, :xx, :xor_d8, :rst_28h,
        # 0xF0
        :ldh_a_a8, :pop_af, :ld_a_dc, :di, :xx, :push_af, :or_d8, :rst_30h, :ld_hl_sp_r8, :ld_sp_hl, :ld_a_a16, :ei,
        :xx, :xx, :cp_d8, :rst_38h
      ].freeze

      CB_OPCODE = [
        # 0x00
        :rlc_b, :rlc_c, :rlc_d, :rlc_e, :rlc_h, :rlc_l, :rlc_hl, :rlc_a, :rrc_b, :rrc_c, :rrc_d, :rrc_e, :rrc_h, :rrc_l, :rrc_hl, :rrc_a,
        # 0x10
        :rl_b, :rl_c, :rl_d, :rl_e, :rl_h, :rl_l, :rl_hl, :rl_a, :rr_b, :rr_c, :rr_d, :rr_e, :rr_h, :rr_l, :rr_hl, :rr_a,
        # 0x20
        :sla_b, :sla_c, :sla_d, :sla_e, :sla_h, :sla_l, :sla_hl, :sla_a, :sra_b, :sra_c, :sra_d, :sra_e, :sra_h, :sra_l, :sra_hl, :sra_a,
        # 0x30
        :swap_b, :swap_c, :swap_d, :swap_e, :swap_h, :swap_l, :swap_hl, :swap_a, :srl_b, :srl_c, :srl_d, :srl_e, :srl_h, :srl_l, :srl_hl, :srl_a,
        # 0x40
        :bit_0_b, :bit_0_c, :bit_0_d, :bit_0_e, :bit_0_h, :bit_0_l, :bit_0_hl, :bit_0_a, :bit_1_b, :bit_1_c, :bit_1_d, :bit_1_e, :bit_1_h,
        :bit_1_l, :bit_1_hl, :bit_1_a,
        # 0x50
        :bit_2_b, :bit_2_c, :bit_2_d, :bit_2_e, :bit_2_h, :bit_2_l, :bit_2_hl, :bit_2_a, :bit_3_b, :bit_3_c, :bit_3_d, :bit_3_e, :bit_3_h, :bit_3_l,
        :bit_3_hl, :bit_3_a,
        # 0x60
        :bit_4_b, :bit_4_c, :bit_4_d, :bit_4_e, :bit_4_h, :bit_4_l, :bit_4_hl, :bit_4_a, :bit_5_b, :bit_5_c, :bit_5_d, :bit_5_e, :bit_5_h, :bit_5_l,
        :bit_5_hl, :bit_5_a,
        # 0x70
        :bit_6_b, :bit_6_c, :bit_6_d, :bit_6_e, :bit_6_h, :bit_6_l, :bit_6_hl, :bit_6_a, :bit_7_b, :bit_7_c, :bit_7_d, :bit_7_e, :bit_7_h, :bit_7_l,
        :bit_7_hl, :bit_7_a,
        # 0x80
        :res_0_b, :res_0_c, :res_0_d, :res_0_e, :res_0_h, :res_0_l, :res_0_hl, :res_0_a, :res_1_b, :res_1_c, :res_1_d, :res_1_e, :res_1_h, :res_1_l,
        :res_1_hl, :res_1_a,
        # 0x90
        :res_2_b, :res_2_c, :res_2_d, :res_2_e, :res_2_h, :res_2_l, :res_2_hl, :res_2_a, :res_3_b, :res_3_c, :res_3_d, :res_3_e, :res_3_h, :res_3_l,
        :res_3_hl, :res_3_a,
        # 0xA0
        :res_4_b, :res_4_c, :res_4_d, :res_4_e, :res_4_h, :res_4_l, :res_4_hl, :res_4_a, :res_5_b, :res_5_c, :res_5_d, :res_5_e, :res_5_h, :res_5_l,
        :res_5_hl, :res_5_a,
        # 0xB0
        :res_6_b, :res_6_c, :res_6_d, :res_6_e, :res_6_h, :res_6_l, :res_6_hl, :res_6_a, :res_7_b, :res_7_c, :res_7_d, :res_7_e, :res_7_h, :res_7_l,
        :res_7_hl, :res_7_a,
        # 0xC0
        :set_0_b, :set_0_c, :set_0_d, :set_0_e, :set_0_h, :set_0_l, :set_0_hl, :set_0_a, :set_1_b, :set_1_c, :set_1_d, :set_1_e, :set_1_h, :set_1_l,
        :set_1_hl, :set_1_a,
        # 0xD0
        :set_2_b, :set_2_c, :set_2_d, :set_2_e, :set_2_h, :set_2_l, :set_2_hl, :set_2_a, :set_3_b, :set_3_c, :set_3_d, :set_3_e, :set_3_h, :set_3_l,
        :set_3_hl, :set_3_a,
        # 0xE0
        :set_4_b, :set_4_c, :set_4_d, :set_4_e, :set_4_h, :set_4_l, :set_4_hl, :set_4_a, :set_5_b, :set_5_c, :set_5_d, :set_5_e, :set_5_h, :set_5_l,
        :set_5_hl, :set_5_a,
        # 0xF0
        :set_6_b, :set_6_c, :set_6_d, :set_6_e, :set_6_h, :set_6_l, :set_6_hl, :set_6_a, :set_7_b, :set_7_c, :set_7_d, :set_7_e, :set_7_h, :set_7_l,
        :set_7_hl, :set_7_a
      ].freeze
    end
  end
end
