class MetaGet < Meta
  set_cc 0xC
  set_char ?*

  set_mc 0

  COORD_OPTIONS = [:relative, :absolute]

  COORD_OPTIONS_BITS = 3
  COORD_OPTIONS_BITMASK = 0x38000
  COORD_OPTIONS_BITSHIFT = 15

  CONTROL_CODE_REGISTER_BITS = 3
  CONTROL_CODE_REGISTER_BITMASK = 0x7000
  CONTROL_CODE_REGISTER_BITSHIFT = 12

  CONTROL_CODE_REGISTER_OPTIONS_BITS = 2
  CONTROL_CODE_REGISTER_OPTIONS_BITMASK = 0xc00
  CONTROL_CODE_REGISTER_OPTIONS_BITSHIFT = 10

  COLOR_VALUE_REGISTER_BITS = 3
  COLOR_VALUE_REGISTER_BITMASK = 0x380
  COLOR_VALUE_REGISTER_BITSHIFT = 7

  COLOR_VALUE_REGISTER_OPTIONS_BITS = 2
  COLOR_VALUE_REGISTER_OPTIONS_BITMASK = 0x60
  COLOR_VALUE_REGISTER_OPTIONS_BITSHIFT = 5

  COORD_REGISTER_BITS = 3
  COORD_REGISTER_BITMASK = 0x1c
  COORD_REGISTER_BITSHIFT = 2

  COORD_REGISTER_OPTIONS_BITS = 2
  COORD_REGISTER_OPTIONS_BITMASK = 0x3
  COORD_REGISTER_OPTIONS_BITSHIFT = 0

  COORD_ABS_X_BITS = 10
  COORD_ABS_X_BITMASK = 0xffc000
  COORD_ABS_X_BITSHIFT = 10

  COORD_ABS_Y_BITS = 10
  COORD_ABS_Y_BITMASK = 0x3ff
  COORD_ABS_Y_BITSHIFT = 0

  COORD_REL_X_SIGN_BITS = 1
  COORD_REL_X_SIGN_BITMASK = 0x80000
  COORD_REL_X_SIGN_BITSHIFT = 19

  COORD_REL_X_BITS = 9
  COORD_REL_X_BITMASK = 0x7fc000
  COORD_REL_X_BITSHIFT = 10

  COORD_REL_Y_SIGN_BITS = 1
  COORD_REL_Y_SIGN_BITMASK = 0x200
  COORD_REL_Y_SIGN_BITSHIFT = 9

  COORD_REL_Y_BITS = 9
  COORD_REL_Y_BITMASK = 0x1ff
  COORD_REL_Y_BITSHIFT = 0

  def self.reference_card
    puts %q{
    Meta Instruction
    Provides an interface for metaprogramming.

    0bCCCCMMAAAAAAAAAAAAAAAAAA
    C = Control Code (Instruction)    [4 bits]
    M = Meta Command                  [2 bits]
    A = Meta Command Arguments        [18 bits]

       --Get
       Gets the instruction at Coord Register and
       places the color in Control Code Register and
       Color Value Register.

       0bOOOWWW11XXX22YYY33
       O = Coord Options                 [3 bits]
       W = Control Code Register         [3 bits]
           - Register to push CC
       1 = Control Code Register Options [2 bits]
       X = Color Value Register          [3 bits]
           - Register to push CV
       2 = Color Value Register Options  [2 bits]
       Y = Coord Register                [3 bits]
           - Register containing the coords of the instruction
       3 = Coord Register Options        [2 bits]
    }
  end

  # gets coords from a register using ABS.
  def self.get_abs_coord(cv)
    xi = cv >> COORD_ABS_X_BITSHIFT
    yi = cv & COORD_ABS_Y_BITMASK

    [xi, yi]
  end

  # Gets the coords from a register relative to the current reader.
  def self.get_rel_coord(cv)
    x_sign = cv >> COORD_REL_X_SIGN_BITSHIFT
    xi     = (cv & COORD_REL_X_BITMASK) >> COORD_REL_X_BITSHIFT
    y_sign = (cv & COORD_REL_Y_SIGN_BITMASK) >> COORD_REL_Y_SIGN_BITSHIFT
    yi     = (cv & COORD_REL_Y_BITMASK) >> COORD_REL_Y_BITSHIFT

    x = ((x_sign == 0) ? xi : -xi)
    y = ((y_sign == 0) ? yi : -yi)

    [x,y]
  end

  def self.get_coords(option, value)

    meta_x = -1
    meta_y = -1

    case option
      when :absolute
        coords = get_abs_coord(value)
        meta_x = coords.first % parent.instructions.width
        meta_y = coords.last % parent.instructions.height
      when :relative
        coords = get_rel_coord(value)
        meta_x = piston.position_x + coords.first
        meta_y = piston.position_y + coords.last

        if meta_x < 0
          meta_x= parent.instructions.width - (meta_x.abs % parent.instructions.width)
        else
          meta_x %= parent.instructions.width
        end

        if meta_y < 0
          meta_y = parent.instructions.height - (meta_y.abs % parent.instructions.height)
        else
          meta_y %= parent.instructions.height
        end
      else
        fail "Coord options not right"
    end
    [meta_x, meta_y]
  end

  def self.make_color(coord_options,
                 control_code_register, control_code_register_options,
                 color_value_register, color_value_register_options,
                 coord_register, coord_register_options)

    coord_options = COORD_OPTIONS.index(coord_options) << COORD_OPTIONS_BITSHIFT
    control_code_register = Piston::REGISTERS.index(control_code_register) << CONTROL_CODE_REGISTER_BITSHIFT
    control_code_register_options <<= CONTROL_CODE_REGISTER_OPTIONS_BITSHIFT
    color_value_register = Piston::REGISTERS.index(color_value_register) << COLOR_VALUE_REGISTER_BITSHIFT
    color_value_register_options <<= COLOR_VALUE_REGISTER_OPTIONS_BITSHIFT
    coord_register = Piston::REGISTERS.index(coord_register) << COORD_REGISTER_BITSHIFT
    coord_register_options <<= COORD_REGISTER_OPTIONS_BITSHIFT

    ((cc << CONTROL_CODE_BITSHIFT) + coord_options + control_code_register + control_code_register_options+
        color_value_register + color_value_register_options +
        coord_register + coord_register_options).to_s 16
  end

  def self.run(piston, *args)
    coord_options = args[0]
    control_code_register = args[1]
    control_code_register_options = args[2]
    color_value_register = args[3]
    color_value_register_options = args[4]
    coord_register = args[5]
    coord_register_options = args[6]

    meta_x, meta_y = *get_coords(coord_options, piston.send(coord_register, coord_register_options))

    int = piston.parent.get_instruction(meta_x, meta_y)

    fail unless int

    piston.send("set_#{control_code_register}", int.cc, control_code_register_options)
    piston.send("set_#{color_value_register}", int.cv, color_value_register_options)
  end

  def coord_options
    COORD_OPTIONS[(cv & COORD_OPTIONS_BITMASK) >> COORD_OPTIONS_BITSHIFT]
  end

  def control_code_register
    Piston::REGISTERS[(cv & CONTROL_CODE_REGISTER_BITMASK) >> CONTROL_CODE_REGISTER_BITSHIFT]
  end

  def control_code_register_options
    (cv & CONTROL_CODE_REGISTER_OPTIONS_BITMASK) >> CONTROL_CODE_REGISTER_OPTIONS_BITS
  end

  def color_value_register
    Piston::REGISTERS[(cv & COLOR_VALUE_REGISTER_BITMASK) >> COLOR_VALUE_REGISTER_BITSHIFT]
  end

  def color_value_register_options
    (cv & COLOR_VALUE_REGISTER_OPTIONS_BITMASK) >> COLOR_VALUE_REGISTER_OPTIONS_BITSHIFT
  end

  def coord_register
    Piston::REGISTERS[(cv & COORD_REGISTER_BITMASK) >> COORD_REGISTER_BITSHIFT]
  end

  def coord_register_options
    (cv & COORD_REGISTER_OPTIONS_BITMASK) >> COORD_REGISTER_OPTIONS_BITSHIFT
  end

  def run(piston)
    self.class.run(piston, coord_options,
                   control_code_register, control_code_register_options,
                   coord_register, coord_register_options)
  end
end