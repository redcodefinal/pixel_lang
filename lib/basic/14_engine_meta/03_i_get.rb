class EMetaIGet < EngineMeta
  set_cc 0xE
  set_char ?E

  set_mc 3

  S_REGISTER_BITS = 3
  S_REGISTER_BITMASK = 0x1c000
  S_REGISTER_BITSHIFT = 15

  S_REGISTER_OPTIONS_BITS = 2
  S_REGISTER_OPTIONS_BITMASK = 0x3000
  S_REGISTER_OPTIONS_BITSHIFT = 12

  D_REGISTER_BITS = 3
  D_REGISTER_BITMASK = 0xe00
  D_REGISTER_BITSHIFT = 9

  D_REGISTER_OPTIONS_BITS = 2
  D_REGISTER_OPTIONS_BITMASK = 0x180
  D_REGISTER_OPTIONS_BITSHIFT = 7



  def self.reference_card
    puts %q{
        Engine Meta I Get
        Counts the number of chars in engine.input

        0bCCCCMMMRRROOAAAAAAAAAAAA
        C = Control Code (Instruction)    [4 bits]
        M = Meta Command                  [3 bits]
        R = Register                      [3 bits]
        O = Register Options              [2 bits]
        A = Meta Command Arguments        [12 bits]
        }
  end

  def self.run(piston, *args)
    s_register = args[0]
    s_register_options = [1]
    d_register = args[2]
    d_register_options = args[3]

    position = piston.send(s_register, s_register_options)
    piston.send("set_#{d_register}", piston.parent.input[position] || 0, d_register_options)
    end
end