require 'ffi'

module Waterfoul
  module SDL
    extend FFI::Library
    ffi_lib "SDL2"

    INIT_TIMER = 0x01
    INIT_VIDEO = 0x20
    INIT_AUDIO = 0x10
    INIT_KEYBOARD = 0x200
    WINDOW_RESIZABLE = 0x20
    PIXELFORMAT_ARGB8888 = 0x16362004
    SDL_WINDOW_RESIZABLE = 0x20
    SDL_WINDOWPOS_UNDEFINED = 0x1FFF0000

    # Audio format constants
    AUDIO_S16LSB = 0x8010
    AUDIO_S16 = AUDIO_S16LSB

    # keyboard key maps
    SDL_SCANCODE_RETURN = 40 # start
    SDL_SCANCODE_RSHIFT = 229 # select
    SDL_SCANCODE_RIGHT = 79
    SDL_SCANCODE_LEFT = 80
    SDL_SCANCODE_DOWN = 81
    SDL_SCANCODE_UP = 82
    SDL_SCANCODE_A = 4 # A
    SDL_SCANCODE_Z = 29 # B

    attach_function :Init, 'SDL_Init', [:uint32], :int
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

    # Audio functions
    attach_function :OpenAudioDevice, 'SDL_OpenAudioDevice', [:string, :int, :pointer, :pointer, :int], :uint32
    attach_function :CloseAudioDevice, 'SDL_CloseAudioDevice', [:uint32], :void
    attach_function :PauseAudioDevice, 'SDL_PauseAudioDevice', [:uint32, :int], :void
    attach_function :QueueAudio, 'SDL_QueueAudio', [:uint32, :pointer, :uint32], :int
    attach_function :GetQueuedAudioSize, 'SDL_GetQueuedAudioSize', [:uint32], :uint32
    attach_function :ClearQueuedAudio, 'SDL_ClearQueuedAudio', [:uint32], :void
    attach_function :GetError, 'SDL_GetError', [], :string

    # SDL_AudioSpec structure
    class AudioSpec < FFI::Struct
      layout :freq, :int,
             :format, :uint16,
             :channels, :uint8,
             :silence, :uint8,
             :samples, :uint16,
             :padding, :uint16,
             :size, :uint32,
             :callback, :pointer,
             :userdata, :pointer
    end
  end
end
