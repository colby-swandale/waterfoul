module Waterfoul
  class Map
    MAP_0_START_ADDR = 0x0
    MAP_1_START_ADDR = 0x0

    def initialize(map_no = 0)
      map_number map_no
    end

    def map_number(map_no)
      raise 'unknown map number' unless [0, 1].include? map_no
    end

    def tiles
    end
  end
end
