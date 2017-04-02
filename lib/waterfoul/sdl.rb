require 'ffi'

module Waterfoul
  module SDL
    extend FFI::Library
    ffi_lib "SDL2"

    INIT_TIMER = 0x01
    INIT_VIDEO = 0x20
    INIT_KEYBOARD = 0x200
    WINDOW_RESIZABLE = 0x20
    PIXELFORMAT_ARGB8888 = 0x16362004
    SDL_WINDOW_RESIZABLE = 0x20

    # keyboard key maps
    SDL_SCANCODE_RETURN = 40 # start
    SDL_SCANCODE_RSHIFT = 229 # select
    SDL_SCANCODE_RIGHT = 79
    SDL_SCANCODE_LEFT = 80
    SDL_SCANCODE_DOWN = 81
    SDL_SCANCODE_UP = 82
    SDL_SCANCODE_A = 4 # A
    SDL_SCANCODE_Z = 29 # B

    attach_function :InitSubSystem, 'SDL_InitSubSystem', [ :uint32 ], :int
    attach_function :CreateWindow, 'SDL_CreateWindow', [ :string, :int, :int, :int, :int, :uint32 ], :pointer
    attach_function :CreateRenderer, 'SDL_CreateRenderer', [:pointer, :int, :uint32], :pointer
    attach_function :CreateTexture, 'SDL_CreateTexture', [:pointer, :uint32, :int, :int, :int], :pointer
    attach_function :UpdateTexture, 'SDL_UpdateTexture', [:pointer, :pointer, :pointer, :int], :int
    attach_function :LockTexture, 'SDL_LockTexture', [:pointer, :pointer, :pointer, :int], :int
    attach_function :UnlockTexture, 'SDL_UnlockTexture', [:pointer], :void
    attach_function :RenderClear, 'SDL_RenderClear', [:pointer], :int
    attach_function :RenderCopy, 'SDL_RenderCopy', [:pointer, :pointer, :pointer, :pointer], :int
    attach_function :RenderPresent, 'SDL_RenderPresent', [:pointer], :int
    attach_function :PumpEvents, 'SDL_PumpEvents', [], :void
    attach_function :GetKeyboardState, 'SDL_GetKeyboardState', [:pointer], :pointer
    attach_function :SetHint, 'SDL_SetHint', [:string, :string], :int
    attach_function :RenderSetLogicalSize, 'SDL_RenderSetLogicalSize', [:pointer, :int, :int], :int
    attach_function :SetWindowTitle, 'SDL_SetWindowTitle', [:pointer, :string], :void
  end
end
