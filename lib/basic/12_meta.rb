require_relative './../instruction'
require_relative './../piston'

class Meta < Instruction
  class << self
    attr_reader :mc

    def set_mc v
      @mc = v
    end

    def match(color)
      meta_c = ((color.value & META_COMMAND_BITMASK) >> META_COMMAND_BITSHIFT) == @mc
      Instruction.match(color) and meta_c
    end

    def reference_card
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

  set_cc 0xC
  set_char ?*
  set_mc -1 # Set the code to -1 so it can never be called.

  META_COMMAND_BITS = 2
  META_COMMAND_BITMASK = 0xc0000
  META_COMMAND_BITSHIFT = 18

  def meta_command
    (cv & META_COMMAND_BITMASK) >> META_COMMAND_BITSHIFT
  end
end

require_rel './meta_commands'
