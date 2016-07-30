require_relative './../instruction'
require_relative './../piston'
class Conditional < Instruction
  # TODO: Utilize last 5 bits for other orientation types
  # :pass_through, :reverse_pass_through
  # :turn_left, :turn_right, :straight_or_left, :straight_or_right
  TYPES = [:vertical, :horizontal, :reverse_vertical, :reverse_horizontal]

  set_cc 7
  set_char ?C

  TYPE_BITS = 6
  TYPE_BITMASK = 0xFC000
  TYPE_BITSHIFT = 14

  SOURCE_1_BITS = 3
  SOURCE_1_BITMASK = 0x3800
  SOURCE_1_BITSHIFT = 11

  SOURCE_1_OPTIONS_BITS = 2
  SOURCE_1_OPTIONS_BITMASK = 0x600
  SOURCE_1_OPTIONS_BITSHIFT = 9

  OPERATION_BITS = 4
  OPERATION_BITMASK = 0x1e0
  OPERATIONS_BITSHIFT = 5

  SOURCE_2_BITS = 3
  SOURCE_2_BITMASK = 0x1c
  SOURCE_2_BITSHIFT = 2

  SOURCE_2_OPTIONS_BITS = 2
  SOURCE_2_OPTIONS_BITMASK = 0x3
  SOURCE_2_OPTIONS_BITSHIFT = 0

  def self.reference_card
    puts %q{
    Conditional Instruction
    Evaluates an arithmetic expression. If the result is zero, the piston moves one way, else, it moves another.

     0bCCCCTTTTTT111XXAAAA222YY
     C = Control Code (Instruction) [4 bits]
     T = Type [6 bit]
     1 = Source 1 Register [3 bits]
     X = Source 1 options [2 bits]
     A = Arithmatic Operation [4 bits] (See Arithmetic::OPERATIONS)
     2 = Source 2 Register [3 bits]
     Y = Source 2 options [2 bits]
    }
  end

  def self.make_color(*args)
    type = args[0]
    s1 = args[1]
    s1op = args[2] << SOURCE_1_OPTIONS_BITSHIFT
    op = args[3]
    s2 = args[4]
    s2op = args[5] << SOURCE_2_OPTIONS_BITSHIFT

    type = TYPES.index(type) << TYPE_BITSHIFT
    s1 = Piston::REGISTERS.index(s1) << SOURCE_1_BITSHIFT
    op = Arithmetic::OPERATIONS.index(op) << OPERATIONS_BITSHIFT
    s2 = Piston::REGISTERS.index(s2) << SOURCE_2_BITSHIFT

    ((cc << CONTROL_CODE_BITSHIFT) + type + s1 + s1op + op + s2 + s2op).to_s 16
  end

  def self.run(piston, *args)
    type = args[0]
    s1 = args[1]
    s1op = args[2]
    op = args[3]
    s2 = args[4]
    s2op = args[5]

    directions = []
    case type
      when :vertical
        directions = [:up, :down]
      when :horizontal
        directions = [:left, :right]
      when :reverse_vertical
        directions = [:down, :up]
      when :reverse_horizontal
        directions = [:right, :left]
      else
        fail "CONDITIONAL_ORIENTATION_ERROR"
    end

    v1 = piston.send(s1, s1op)
    v2 = piston.send(s2, s2op)

    result = v1.send(op, v2)

    if result == LOGICAL_FALSE || !result
      piston.change_direction directions[0]
    else
      piston.change_direction directions[1]
    end
  end

  def type
    TYPES[(cv>>TYPE_BITSHIFT) % TYPES.count]
  end

  def s1
    Piston::REGISTERS[((cv&SOURCE_1_BITMASK)>>SOURCE_1_BITSHIFT)]
  end

  def s1op
    (cv & SOURCE_1_OPTIONS_BITMASK) >> SOURCE_1_OPTIONS_BITSHIFT
  end

  def op
    Arithmetic::OPERATIONS[((cv&OPERATION_BITMASK)>>OPERATIONS_BITSHIFT)]
  end

  def s2
    Piston::REGISTERS[((cv&SOURCE_2_BITMASK)>>SOURCE_2_BITSHIFT)]
  end

  def s2op
    (cv & SOURCE_2_OPTIONS_BITMASK) >> SOURCE_2_OPTIONS_BITSHIFT
  end

  def run(piston)
    self.class.run(piston, type, s1, s1op, op, s2, s2op)
  end
end