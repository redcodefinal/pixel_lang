class EMetaILength < EngineMeta
  set_cc 0xE
  set_char ?E

  set_mc 0

  REGISTER_BITS = 3
  REGISTER_BITMASK = 0x1c000
  REGISTER_BITSHIFT = 14

  REGISTER_OPTIONS_BITS = 2
  REGISTER_OPTIONS_BITMASK = 0x3000
  REGISTER_OPTIONS_BITSHIFT = 12


  def self.reference_card
    puts %q{
        Engine Meta Length
        Counts the number of chars in engine.input

        0bCCCCMMMMMRRROOAAAAAAAAAA
        C = Control Code (Instruction)    [4 bits]
        M = Meta Command                  [5 bits]
        R = Register                      [3 bits]
        O = Register Options              [2 bits]
        A = Meta Command Arguments        [17 bits]
        }
  end

  def self.run(piston, *args)
    register = args[0]
    register_options = [1]

    piston.send("set_#{register}", piston.parent.input.length % Piston::MAX_INTEGER, register_options)
  end

  def register
    (cv & REGISTER_BITMASK) >> REGISTER_BITSHIFT
  end

  def register_options
    (cv & REGISTER_OPTIONS_BITMASK) >> REGISTER_OPTIONS_BITSHIFT
  end

  def run(piston)
    self.class.run(piston, register, register_options)
  end
end