# Waterfoul
Waterfoul is a Gameboy emulator written in Ruby-lang. It is a casual excersize by myself to learn the internals
of the device and how it works.

## Getting Started
To start the emulator:

`bundle exec exe/waterfoul start <path to rom>`

Make sure to `bundle install` first and install required libraries.

By default the emulator will run the boot rom, if you wish to skip it then add `--skip-boot` as an option.

## Requirements
The [sdl2](https://www.libsdl.org/download-2.0.php) library is currenty used to render pixels. Most platforms have packages avaliable, else see [here](https://wiki.libsdl.org/Installation). This library is required and needs to be installed before you can run the emulator.

## Can it play roms?
Yes! but the list of roms that i know work is very limited to just Tetris, Super Mario Land and Pokemon Red. But a lot of work is being put into making other games compatable. The device does run the internal boot program succesfully and is passing test programs sucesfully (barggs).

## Controls
The following shows the mapped keys to control the game.
![gameboy key mapping](https://raw.githubusercontent.com/colby-swandale/waterfoul/master/documentation/keymap.png)

## Testing
If you wish to run the test suite, download the source code (make sure to run `bundle install`) and run `bundle exec rspec`

