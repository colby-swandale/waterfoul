require 'spec_helper'

describe Waterfoul::Cartridge do
  describe '.gbc_compatible?' do
    it 'returns true for GBC-compatible cartridge (0x80)' do
      rom = Array.new(0x8000, 0)
      rom[0x143] = 0x80
      expect(Waterfoul::Cartridge.gbc_compatible?(rom)).to be true
    end

    it 'returns true for GBC-only cartridge (0xC0)' do
      rom = Array.new(0x8000, 0)
      rom[0x143] = 0xC0
      expect(Waterfoul::Cartridge.gbc_compatible?(rom)).to be true
    end

    it 'returns false for DMG-only cartridge' do
      rom = Array.new(0x8000, 0)
      rom[0x143] = 0x00
      expect(Waterfoul::Cartridge.gbc_compatible?(rom)).to be false
    end
  end
end
