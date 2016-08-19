class MetaResize < Meta
  set_cc 0xC
  set_char ?*

  set_mc 3

  def self.reference_card
    puts %q{
    Meta Instruction
    Provides an interface for metaprogramming.

    0bCCCCMMAAAAAAAAAAAAAAAAAA
    C = Control Code (Instruction)    [4 bits]
    M = Meta Command                  [2 bits]
    A = Meta Command Arguments        [18 bits]

      --Resize
      Resizes the instructions array

      0bX11111111Y22222222
      X = X sign
      1 = X value
      Y = Y sign
      2 = Y value
    }
  end
  #TODO: Finish MetaResize
end