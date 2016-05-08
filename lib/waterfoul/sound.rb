module Waterfoul
  class Sound
    def initialize
      @clock = 0
    end

    def step(cpu_time)
      @clock += cpu_time
    end
  end
end
