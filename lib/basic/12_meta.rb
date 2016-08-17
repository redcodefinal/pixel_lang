require_relative './../instruction'
require_relative './../piston'

class Meta < Instruction
  attr_reader :mc

  def self.set_mc v
    @mc = v
  end

  set_cc 0xC
  set_char ?*
  set_mc -1 # Set the code to -1 so it can never be called.

  META_COMMAND_BITS = 2
  META_COMMAND_BITMASK = 0xc0000
  META_COMMAND_BITSHIFT = 18

  def self.match(color)
    meta_c = ((color.value & META_COMMAND_BITMASK) >> META_COMMAND_BITSHIFT) == @mc
    super and meta_c
  end

  def meta_command
    COMMANDS[(cv & META_COMMAND_BITMASK) >> META_COMMAND_BITSHIFT]
  end

  def self.reference_card
    puts %q{
    Meta Instruction
    Provides an interface for metaprogramming.

    0bCCCCMMAAAAAAAAAAAAAAAAAA
    C = Control Code (Instruction)    [4 bits]
    M = Meta Command                  [2 bits]
    A = Meta Command Arguments        [15 bits]
    }
  end
end

require_rel './meta_commands'
