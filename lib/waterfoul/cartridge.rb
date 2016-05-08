module Waterfoul
  class Cartridge
    extend Forwardable

    def_delegators :@mbc, :[], :[]=

    def initialize(rom)
      @mbc = MBC::MBC1.new rom
    end
  end
end
