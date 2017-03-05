require 'waterfoul/mbc/rom'
require 'waterfoul/mbc/mbc1'
require 'waterfoul/mbc/mbc2'
require 'waterfoul/mbc/mbc3'
require 'waterfoul/mbc/mbc4'
require 'waterfoul/mbc/mbc5'
require 'forwardable'

module Waterfoul
  # The cartridge is the removable cart containing the game program, some writable memory,
  # a battery and a real time clock. Not all cartrdiges have the features listed though,
  # there is 29 different types of game cartridges with slight variations between them.
  #
  # Each cartridge contains a subset of bytes called "The Cartridge Header"
  # (between 0x100 to 0x14F) which provides information about the type of cartridge, the
  # ninetndo logo, game title, manufacturer, rom size, ram size and more.
  #
  class Cartridge
    extend Forwardable
    # location byte in memory (physically located on cartrdige) that declares the type of cartrdige
    CARTRIDGE_TYPE_MEM_LOC = 0x147
    # delegate any reads/writes to the memory bank controller
    def_delegators :@mbc, :[], :[]=

    def initialize(rom)
      # get cartridge type byte from game program
      cartridge_type = rom[CARTRIDGE_TYPE_MEM_LOC]
      # assign memory bank controller to cartridge
      @mbc = cartrdige_controller cartridge_type, rom
    end

    private

    # initialize the memory bank controller given the game program and the controller type
    def cartrdige_controller type, rom
      controller_const(type).new rom
    end

    # return the class constant that implements the behavior of the memory bank controller
    # declared by the game cartridge
    def controller_const(type_byte)
      case type_byte
      when 0x00, 0x8, 0x9
        MBC::ROM
      when 0x1, 0x2, 0x3
        MBC::MBC1
      when 0x5, 0x6
        MBC::MBC2
      when 0xF, 0x10, 0x11, 0x12, 0x13
        MBC::MBC3
      when 0x15, 0x16, 0x17
        MBC::MBC4
      when 0x19, 0x1B, 0x1C, 0x1D, 0x1E
        MBC::MBC5
      end
    end

    def self.empty
      Array.new(0x8000, 0)
    end
  end
end
