module Waterfoul
  class Screen

    SCREEN_WIDTH = 160
    SCREEN_HEIGHT = 144

    def initialize
      SDL.InitSubSystem SDL::INIT_VIDEO
      @buffer = FFI::MemoryPointer.new :uint32, SCREEN_WIDTH * SCREEN_HEIGHT
      @window = SDL.CreateWindow 'waterfoul', 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 0
      @renderer = SDL.CreateRenderer @window, -1, 0
      @texture = SDL.CreateTexture @renderer, SDL::PIXELFORMAT_ARGB8888, 1, SCREEN_WIDTH, SCREEN_HEIGHT
    end

    def render(framebuffer)
      @buffer.write_array_of_uint32 framebuffer
      SDL.UpdateTexture @texture, nil, @buffer, SCREEN_WIDTH * 4
      SDL.RenderClear @renderer
      SDL.RenderCopy @renderer, @texture, nil, nil
      SDL.RenderPresent @renderer
    end
  end
end
