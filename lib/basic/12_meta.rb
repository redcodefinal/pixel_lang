require_relative './../instruction'
require_relative './../piston'

class Meta < Instruction
  set_cc 0xC
  set_char ?*

  COMMANDS = [:get, :set, :save]
  COMMAND_OPTIONS = [:relative, :absolute]

  META_COMMAND_BITS = 2
  META_COMMAND_BITMASK = 0xc0000
  META_COMMAND_BITSHIFT = 18

  META_COMMAND_OPTIONS_BITS = 3
  META_COMMAND_OPTIONS_BITMASK = 0x38000
  META_COMMAND_OPTIONS_BITSHIFT = 15

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

    0bCCCCMMOOOAAAAAAAAAAAAAAA
    C = Control Code (Instruction)    [4 bits]
    M = Meta Command                  [2 bits]
    O = Meta Command Options          [3 bits]
    A = Meta Command Arguments        [15 bits]

    --Get
    Gets the instruction at Coord Register and
    places the color in Control Code Register and
    Color Value Register.

    0bWWW11XXX22YYY33
    W = Control Code Register         [3 bits]
    1 = Control Code Register Options [2 bits]
    Z = Color Value Register          [3 bits]
    2 = Color Value Register Options  [2 bits]
    X = Coord Register                [3 bits]
    3 = Coord Register Options        [2 bits]

    --Set
    Sets the instruction at Coord Register to
    Control Code Register and Color Value Register.

    0bWWW11XXX22YYY33
    W = Control Code Register         [3 bits]
    1 = Control Code Register Options [2 bits]
    Z = Color Value Register          [3 bits]
    2 = Color Value Register Options  [2 bits]
    X = Coord Register                [3 bits]
    3 = Coord Register Options        [2 bits]

    --Save
    Saves the current instructions to an image
    with the file name piston_id-cycle.bmp

    0b000000000000000
    0 = Control Code Register         [15 bits]
    }
  end

  def self.make_color(*args)
    meta_command = COMMANDS.index(args[0]) << META_COMMAND_BITSHIFT
    meta_command_options = COMMAND_OPTIONS.index(args[1] << META_COMMAND_OPTIONS_BITSHIFT)
    control_code_register = Piston::REGISTERS.index(args[2]) << CONTROL_CODE_REGISTER_BITSHIFT
    control_code_register_options = args[3] << CONTROL_CODE_REGISTER_OPTIONS_BITSHIFT
    color_value_register = Piston::REGISTERS.index(args[4]) << COLOR_VALUE_REGISTER_BITSHIFT
    color_value_register_options = args[5] << COLOR_VALUE_REGISTER_OPTIONS_BITSHIFT
    coord_register = Piston::REGISTERS.index(args[6]) << COORD_REGISTER_BITSHIFT
    coord_register_options = args[7] << COORD_REGISTER_OPTIONS_BITSHIFT

   ((cc << CONTROL_CODE_BITSHIFT) + meta_command + meta_command_options +
      control_code_register + control_code_register_options +
      color_value_register + color_value_register_options +
      coord_register + coord_register_options).to_s 16
  end

  def self.get_abs_coord(cv)
    xi = cv >> COORD_ABS_X_BITSHIFT
    yi = cv & COORD_ABS_Y_BITMASK

    [xi, yi]
  end

  def self.get_rel_coord(cv)
    x_sign = cv >> COORD_REL_X_SIGN_BITSHIFT
    xi     = (cv & COORD_REL_X_BITMASK) >> COORD_REL_X_BITSHIFT
    y_sign = (cv & COORD_REL_Y_SIGN_BITMASK) >> COORD_REL_Y_SIGN_BITSHIFT
    yi     = (cv & COORD_REL_Y_BITMASK) >> COORD_REL_Y_BITSHIFT

    x = ((x_sign == 0) ? xi : -xi)
    y = ((y_sign == 0) ? yi : -yi)

    [x,y]
  end

  def self.run(piston, *args)
    meta_command = args[0]
    meta_command_options = args[1]

    if meta_command == :get || meta_command == :set
      control_code_register = args[2]
      control_code_register_options = args[3]
      color_value_register = args[4]
      color_value_register_options = args[5]
      coord_register = args[6]
      coord_register_options = args[7]

      meta_x = -1
      meta_y = -1

      meta_coord_value = piston.send(coord_register, coord_register_options)
      if meta_command_options == :absolute
        coords = get_abs_coord(meta_coord_value)
        meta_x = coords.first
        meta_y = coords.last
      elsif meta_command_options == :relative
        coords = get_rel_coord(meta_coord_value)
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
        fail
      end
    end

    if meta_command == :get
      int = piston.parent.get_instruction(meta_x, meta_y)

      fail if int == nil #TODO: Write proper out of bounds check

      piston.send("set_#{control_code_register}", int.cc)
      piston.send("set_#{color_value_register}", int.cv)
    elsif meta_command == :set
      meta_control_code = (piston.send(control_code_register, control_code_register_options) % 0x10) << CONTROL_CODE_BITSHIFT
      meta_color_value = piston.send(color_value_register, color_value_register_options)
      meta_color = meta_control_code + meta_color_value
      #TODO: Write proper out of bounds check
      piston.parent.set_instruction(meta_color, meta_x, meta_y)
    elsif meta_command == :save
      # TODO:  Implement proper save
      # TODO: Implement save scaling
    end
  end

  def meta_command
    COMMANDS[(cv & META_COMMAND_BITMASK) >> META_COMMAND_BITSHIFT]
  end

  def meta_command_options
    COMMAND_OPTIONS[(cv & META_COMMAND_OPTIONS_BITMASK) >> META_COMMAND_OPTIONS_BITSHIFT]
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
    self.class.run(piston, meta_command, meta_command_options,
                   control_code_register, control_code_register_options,
                   coord_register, coord_register_options)
  end
end