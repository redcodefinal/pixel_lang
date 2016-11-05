class PMetaChangePos < PistonMeta
  set_cc 0xD
  set_char ?P

  set_mc 6

  X_REGISTER_BITS = 3
  X_REGISTER_BITMASK = 0x1c000
  X_REGISTER_BITSHIFT = 14

  X_REGISTER_OPTIONS_BITS = 2
  X_REGISTER_OPTIONS_BITMASK = 0x3000
  X_REGISTER_OPTIONS_BITSHIFT = 12

  Y_REGISTER_BITS = 3
  Y_REGISTER_BITMASK = 0xe00
  Y_REGISTER_BITSHIFT = 9

  Y_REGISTER_OPTIONS_BITS = 2
  Y_REGISTER_OPTIONS_BITMASK = 0x180
  Y_REGISTER_OPTIONS_BITSHIFT = 7

  def self.reference_card
    puts %q{
        Piston Meta Change Position
        sets the pistons position to x_reg and y_reg

        0bCCCCMMMXXX11YYY22AAAAAAA
        C = Control Code (Instruction)    [4 bits]
        M = Meta Command                  [3 bits]
        X = X Register                    [3 bits]
        1 = X Register Options            [2 bits]
        Y = Y Register                    [3 bits]
        2 = Y Register Options            [2 bits]
        A = Meta Command Arguments        [17 bits]
        }
  end

  def self.run(piston, *args)
    x_register = args[0]
    x_register_options = [1]
    y_register = args[2]
    y_register_options = [3]

    piston.instance_variable_set(:@pos_x, piston.send(x_register, x_register_options))
    piston.instance_variable_set(:@pos_y, piston.send(y_register, y_register_options))
  end


  def x_register
    (cv & X_REGISTER_BITMASK) >> X_REGISTER_BITSHIFT
  end

  def x_register_options
    (cv & X_REGISTER_OPTIONS_BITMASK) >> X_REGISTER_OPTIONS_BITSHIFT
  end

  def y_register
    (cv & Y_REGISTER_BITMASK) >> Y_REGISTER_BITSHIFT
  end

  def y_register_options
    (cv & Y_REGISTER_OPTIONS_BITMASK) >> Y_REGISTER_OPTIONS_BITSHIFT
  end

  def run(piston)
    self.class.run(piston, x_register, x_register_options, y_register, y_register_options)
  end
end