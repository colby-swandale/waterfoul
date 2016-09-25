require "waterfoul/version"
require "waterfoul/cli"
require "waterfoul/skip_boot"
require "waterfoul/helper"
require "waterfoul/interrupt"
require "waterfoul/mmu"
require "Waterfoul/timer"
require "waterfoul/cpu"
require "waterfoul/errors"
require "waterfoul/sdl"
require "waterfoul/screen"
require "waterfoul/ppu"
require "waterfoul/cartridge"
require "waterfoul/emulator"
require "waterfoul/input"

module Waterfoul
  BIT_0  = 0b0000_0001
  BIT_1  = 0b0000_0010
  BIT_2  = 0b0000_0100
  BIT_3  = 0b0000_1000
  BIT_4  = 0b0001_0000
  BIT_5  = 0b0010_0000
  BIT_6  = 0b0100_0000
  BIT_7  = 0b1000_0000
  BIT_8  = 0b0000_0001_0000_0000
  BIT_9  = 0b0000_0010_0000_0000
  BIT_10 = 0b0000_0100_0000_0000
  BIT_11 = 0b0000_1000_0000_0000
  BIT_12 = 0b0001_0000_0000_0000
  BIT_13 = 0b0010_0000_0000_0000
  BIT_14 = 0b0100_0000_0000_0000
  BIT_15 = 0b1000_0000_0000_0000
end
