class MetaRandom < Meta
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

      --Random
      Stores a random value defined by the arguments into
      a register

      0bTTRRROO00000000000
      T = Type
          - The type of random number you'd like to get
            0 = Random # (0-0x100000)
            1 = Random char (0-0x100)
            2 = Random printable (a-zA-Z0-9[symbols])
            3 = Random direction (Gives the piston a random direction to go in)
                - Ignores R and O args
      R = Register
          - Register to input random value into
      O = Register options
    }
  end

  #TODO: Finish random
end