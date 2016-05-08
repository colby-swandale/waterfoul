require 'sdl2'
require 'waterfoul/io/lcd_status'

module Waterfoul
  class Screen

    SCREEN_WIDTH = 160
    SCREEN_HEIGHT = 144

    SCREEN_COLORS = {
      0 => [255, 255, 255], # white
      1 => [168, 168, 168], # 33% grey
      2 => [85, 85, 85],    # 66% grey
      3 => [0, 0, 0]        # black
    }

    def initialize
      SDL2.init SDL2::INIT_VIDEO
      @screen = SDL2::Window.create('main', 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 0)
      @renderer = @screen.create_renderer 1, 0
      @lcd_status = IO::LCDStatus.new
    end

    def render(framebuffer)
      0.upto(SCREEN_HEIGHT - 1) do |line|
        0.upto(SCREEN_WIDTH - 1) do |x|
          index = (SCREEN_WIDTH * line) + x
          pixel = framebuffer[index]
          # set pixel color
          @renderer.draw_color = SCREEN_COLORS[pixel]
          # draw pixel
          @renderer.draw_point x, line
        end
      end

      @renderer.present
    end
  end
end
