require_relative './../instruction'
require_relative './../piston'

class PistonMeta < InstructionMeta
  class << self

    def reference_card
      puts %q{
        Meta Instruction
        Provides an interface for metaprogramming.

        0bCCCCMMMAAAAAAAAAAAAAAAAA
        C = Control Code (Instruction)    [4 bits]
        M = Meta Command                  [3 bits]
        A = Meta Command Arguments        [17 bits]
        }
    end
  end

  set_cc 0xD
  set_char ?P
  set_mc -1 # Set the code to -1 so it can never be called.

end

require_rel './13_piston_meta'
