require_relative './instruction'
require_relative './piston'

# Instruction Composition
# 0bCCCCVVVVVVVVVVVVVVVVVVVV
# C = Control Code (Instruction) [4 bits]
# V = Value (Arguments) [20 bits]

class End < Instruction
  set_cc 0
  set_char ?E

  def self.reference_card
    puts %q{
    End Instruction
    Ends the piston

    0bCCCC00000000000000000000
    C = Control Code (Instruction) [4 bits]
    0 = Free bit [20 bits]
    }
  end

  def self.make_color(*args)
    cv = 0x00000

    unless args.first.nil?
      cv = args.first % 0x100000
    end

    (cc << CONTROL_CODE_BITSHIFT) + cv
  end

  def self.run(piston, *args)
    piston.kill
  end
end

# TODO: Fix Start instructions in all test programs
class Start < Instruction
  set_cc 1
  set_char ?S

  DIRECTION_BITS = 2
  DIRECTION_BITMASK = 0xC0000
  DIRECTION_BITSHIFT = 18

  PRIORITY_BITS = 18
  PRIORITY_BITMASK = 0x3FFFF

  def direction
    Piston::DIRECTIONS[((cv & DIRECTION_BITMASK) >> DIRECTION_BITSHIFT)]
  end

  def priority
    (cv & PRIORITY_BITMASK)
  end

  def run(piston)
    self.class.run(piston, direction, priority)
  end

  def self.reference_card
    puts %q{
    Start Instruction
    Tell the engine where to place a piston, what direction it should face, and what it's priority should be.

    0bCCCCDDPPPPPPPPPPPPPPPPPP
    C = Control Code (Instruction) [4 bits]
    D = Direction [2 bits] Direction where the piston should go
    P = Priority [18 bits] Order in which piston should run their cycles. 0 goes first.
    }
  end

  def self.make_color(*args)
    direction = Piston::DIRECTIONS.index(args.first) << DIRECTION_BITSHIFT
    priority = args.last

    if priority > PRIORITY_BITMASK
      fail "Priority #{priority.to_s 16} cannot be higher than #{PRIORITY_BITMASK} or #{PRIORITY_BITMASK.to_s 16}"
    end

    (cc << CONTROL_CODE_BITSHIFT) + direction + priority
  end

  def self.run(piston, *args)
    piston.change_direction(args.first)
  end
end

class Pause < Instruction
  set_cc 2
  set_char ?P

  def cycles
    cv
  end

  def run(piston)
    self.class.run(piston, cycles)
  end

  def self.reference_card
    puts %q{
    Pause Instruction
    Tells a piston to wait for Time + 1 cycles.

    0bCCCCTTTTTTTTTTTTTTTTTTTT
    C = Control Code (Instruction) [4 bits]
    T = Time (Cycles to wait) [20 bits]
    }
  end

  def self.make_color(*args)
    cycles = args.first

    if cycles > COLOR_VALUE_BITMASK
      fail "Cycles #{cycles.to_s 16} cannot be higher than #{COLOR_VALUE_BITMASK} or #{COLOR_VALUE_BITMASK.to_s 16}"
    end

    (cc << CONTROL_CODE_BITSHIFT) + cycles
  end

  def self.run(piston, *args)
    piston.pause args.first
  end
end


#TODO: FIX DIRECTION INSTRUCTIONS
class Direction < Instruction
  set_cc 3
  set_char ?D

  DIRECTION_BITMASK = 0x3

  #TODO: Add more directions (turn_left, turn_right, turn_around)

  def direction
    Piston::DIRECTIONS[(cv & DIRECTION_BITMASK)]
  end

  def run(piston)
    self.class.run(piston, direction)
  end

  def self.reference_card
    puts %q{
    Direction Instruction
    Tells a piston to change direction

    0bCCCC000000000000000000DD
    C = Control Code (Instruction) [4 bits]
    0 = Free bit [18 bits]
    D = Direction [2 bits] (See Pistion::DIRECTIONS for order)
    }
  end

  def self.make_color(*args)
    direction = Piston::DIRECTIONS.index(args.first)
    (cc << CONTROL_CODE_BITSHIFT) + direction
  end

  def self.run(piston, *args)
    piston.change_direction(args.first)
  end
end

class Fork < Instruction
  # kinds of pipes UpRightDown DownLeftRight etc.
  # TODO: Add :ulrd a 4way, and reverse versions (one enters 3 leave)
  TYPES = [:urd, :dlr, :uld, :ulr]

  set_cc 4
  set_char ?F

  def type
    TYPES[cv % TYPES.count]
  end

  def run(piston)
    self.class.run(piston, type)
  end

  def self.reference_card
    puts %q{
    Fork Instruction
    Forks a piston into multiple readers with different directions

    0bCCCC000000000000000000TT
    C = Control Code (Instruction) [4 bits]
    0 = Free bit [18 bits]
    T = Type [2 bits] (See Fork::TYPES for order)
    }
  end

  def self.make_color(*args)
    type = Fork::TYPES.index(args.first)
    (cc << CONTROL_CODE_BITSHIFT) + type
  end

  def self.run(piston, *args)
    case args[0]
      when :urd
        case (piston.direction)
          when :up
            piston.parent.fork(piston, :right)
          when :left
            piston.parent.fork(piston, :left)
            piston.turn_right
          when :down
            piston.parent.fork(piston, :left)
          when :right
            piston.reverse
          else
            raise Exception.new
        end
      when :dlr
        case (piston.direction)
          when :up
            piston.parent.fork(piston, :left)
            piston.turn_right
          when :left
            piston.parent.fork(piston, :left)
          when :down
            thread.reverse
          when :right
            piston.parent.fork(piston, :right)
          else
            raise Exception.new
        end
      when :uld
        case (piston.direction)
          when :up
            piston.parent.fork(piston, :left)
          when :left
            piston.reverse
          when :down
            piston.parent.fork(piston, :right)
          when :right
            piston.parent.fork(piston, :left)
            piston.turn_right
          else
            raise Exception.new
        end
      when :ulr
        case (piston.direction)
          when :up
            piston.reverse
          when :left
            piston.parent.fork(piston, :right)
          when :down
            piston.parent.fork(piston, :left)
            piston.turn_right
          when :right
            piston.parent.fork(piston, :left)
          else
            raise Exception.new
        end
      else
        fail "FORK TYPE ERROR"
    end
  end
end

class Jump < Instruction
  set_cc 5
  set_char ?J

  def jumps
    cv
  end

  def run(piston)
    self.class.run(piston, jumps+1)
  end

  def self.reference_card
    puts %q{
    Jump Instruction
    Piston jumps spaces+1 in the direction it's facing

    0bCCCCSSSSSSSSSSSSSSSSSSSS
    C = Control Code (Instruction) [4 bits]
    S = Spaces [20 bits] number of space beyond the first to jump
    }
  end

  def self.make_color(*args)
    (cc << CONTROL_CODE_BITSHIFT) + args.first
  end

  def self.run(piston, *args)
    piston.move args[0]
  end
end

class Call < Instruction
  set_cc 6
  set_char ?L

  X_SIGN_BITS = 1
  X_SIGN_BITMASK = 0x80000
  X_SIGN_BITSHIFT = 19

  X_BITS = 9
  X_BITMASK = 0x7fc000
  X_BITSHIFT = 10

  Y_SIGN_BITS = 1
  Y_SIGN_BITMASK = 0x200
  Y_SIGN_BITSHIFT = 9

  Y_BITS = 9
  Y_BITMASK = 0x1ff
  Y_BITSHIFT = 0


  def x_sign
    cv>>X_SIGN_BITSHIFT
  end

  def xi
    (cv & X_BITMASK)>>X_BITSHIFT
  end

  def y_sign
    (cv & Y_SIGN_BITMASK)>>Y_SIGN_BITSHIFT
  end

  def yi
    cv & Y_BITMASK
  end

  def x
    ((x_sign == 0) ? xi : -xi)
  end

  def y
    ((y_sign == 0) ? yi : -yi)
  end

  def run(piston)
    self.class.run(piston, x, y)
  end

  def self.reference_card
    puts %q{
    Call Instruction
    Jumps a piston to a nearby instruction by the offset coordinates.

    0bCCCCXWWWWWWWWWYZZZZZZZZZ
    C = Control Code (Instruction) [4 bits]
    X = X Sign [1 bit] Deterimines if X is negative or not
    W = X [9 bits] Number of X spaces to jump
    Y = Y Sign [1 bit] Deterimines if Y is negative or not
    Z = Y [9 bits] Number of Y spaces to jump
    }
  end

  def self.make_color(*args)
    x = args.first
    y = args.last

    x_sign = x < 0
    y_sign = y < 0

    x = x.abs
    y = y.abs

    (cc << CONTROL_CODE_BITSHIFT) + (x_sign << X_SIGN_BITSHIFT) + (x << X_BITSHIFT)+ (y_sign << Y_SIGN_BITSHIFT) + (y << Y_BITSHIFT)
  end

  def self.run(piston, *args)
    piston.jump(args.first, args.last)
  end
end

# Conditional Instruction
# 
# 0bCCCCTTTTTT111XXAAAA222YY
# C = Control Code (Instruction) [4 bits]
# T = Type [1 bit]
# 1 = Source 1 Register [3 bits]
# X = Source 1 options [2 bits]
# A = Arithmatic Operation [4 bits] (See Arithmetic::OPERATIONS)
# 2 = Source 2 Register [3 bits] 
# Y = Source 2 options [2 bits]
#TODO: FIX CONDITIONAL INSTRUCTIONS
class Conditional < Instruction
  # TODO: Utilize last 5 bits for other orientation types
  # :pass_through, :reverse_pass_through, :turn_left, :turn_right, :straight_or_left, :straight_or_right
  TYPES = [:vertical, :horizontal]

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

  def type
    TYPES[cv>>TYPE_BITSHIFT]
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
    s1o = args[2] << SOURCE_1_OPTIONS_BITSHIFT
    op = args[3]
    s2 = args[4]
    s2o = args[5] << SOURCE_2_OPTIONS_BITSHIFT

    type = TYPES.index(type) << TYPE_BITSHIFT
    s1 = Piston::REGISTERS.index(s1) << SOURCE_1_BITSHIFT
    op = Arithmetic::OPERATIONS.index(op) << OPERATIONS_BITSHIFT
    s2 = Piston::REGISTERS.index(s2) << SOURCE_2_BITSHIFT

    (cc << CONTROL_CODE_BITSHIFT) + type + s1 + s1o + op + s2 + s2o
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
end


class Insert < Instruction
  set_cc 8
  set_char ?I

  def run(piston)
    self.class.run(piston, cv)
  end

  def self.reference_card
    puts %q{
    Insert Instruction
    Inserts the color value into register i

    0bCCCCVVVVVVVVVVVVVVVVVVVV
    C = Control Code (Instruction) [4 bits]
    V = Value [20 bits]
    }
  end

  def self.make_color(*args)
    cv = 0x00000

    unless args.first.nil?
      cv = args.first % Piston::MAX_INTEGER
    end

    (cc << CONTROL_CODE_BITSHIFT) + cv
  end

  def self.run(piston, *args)
    piston.set_i args[0]
  end
end

# TODO: Explain and test swap and reverse.
class Move < Instruction
  set_cc 9
  set_char ?M

  SOURCE_BITS = 3
  SOURCE_BITMASK = 0xe0000
  SOURCE_BITSHIFT = 17

  SOURCE_OPTIONS_BITS = 2
  SOURCE_OPTIONS_BITMASK = 0x18000
  SOURCE_OPTIONS_BITSHIFT = 15


  DESTINATION_BITS = 3
  DESTINATION_BITMASK = 0x7000
  DESTINATION_BITSHIFT = 12

  DESTINATION_OPTIONS_BITS = 2
  DESTINATION_OPTIONS_BITMASK = 0xc00
  DESTINATION_OPTIONS_BITSHIFT = 10


  def s
    Piston::REGISTERS[(cv&SOURCE_BITMASK)>>SOURCE_BITSHIFT]
  end

  def sop
    (cv&SOURCE_OPTIONS_BITMASK)>>SOURCE_OPTIONS_BITSHIFT
  end

  def d
    Piston::REGISTERS[(cv&DESTINATION_BITMASK)>>DESTINATION_BITSHIFT]
  end

  def dop
    (cv&DESTINATION_OPTIONS_BITMASK) >> DESTINATION_OPTIONS_BITSHIFT
  end

  def run(piston)
    self.class.run(piston, s, sop, d, dop)
  end

  def self.reference_card
    puts %q{
    Move Instruction
    Moves the contents of one register into another. Can also swap values of regular registers.

    0bCCCCSSSXXDDDYY0000000000
    C = Control Code (Instruction) [4 bits]
    S = Source [3 bits]
    X = Source Options [2 bits]
    D = Destination [3 bits]
    Y = Destination Options [2 bits]
    0 = Free bit [10 bits]
    }
  end

  def self.make_color(*args)
    source = args[0]
    source_options = args[1] << SOURCE_OPTIONS_BITSHIFT
    destination = args[2]
    destination_options = args[3] << DESTINATION_OPTIONS_BITSHIFT

    source = Piston::REGISTERS.index(source) << SOURCE_BITSHIFT
    destination = Piston::REGISTERS.index(destination) << DESTINATION_BITSHIFT


    (cc << CONTROL_CODE_BITSHIFT) + source + source_options + destination + destination_options
  end

  def self.run(piston, *args)
    s = args[0]
    sop = args[1]
    d = args[2]
    dop = args[3]

    #decode swap and reverse options
    # if both of the registers are normal
    # to ensure i and o dont have their options mixed
    if Piston::REGULAR_REG.include?(s) and Piston::REGULAR_REG.include?(d)
      o = sop^dop
      swap = ((o>>1) != LOGICAL_FALSE)
      reverse = ((o&1) != LOGICAL_FALSE)
    elsif Piston::REGULAR_REG.include?(s)
      swap = ((sop>>1) != LOGICAL_FALSE)
      reverse = ((sop&1) != LOGICAL_FALSE)
    elsif Piston::REGULAR_REG.include?(d)
      swap = ((dop>>1) != LOGICAL_FALSE)
      reverse = ((dop&1) != LOGICAL_FALSE)
    end

    s, d = d, s if reverse

    if swap
      cs = piston.send(s, sop)
      cd = piston.send(d, dop)
      piston.send("set_#{s.to_s}", cd, sop)
      piston.send("set_#{d.to_s}", cs, dop)
    else
      piston.send("set_#{d.to_s}", piston.send(s, sop), dop)
    end
  end
end

class Arithmetic < Instruction
  OPERATIONS = [:+, :-, :*, :/, :**, :&, :|, :^, :%,
                :<, :>, :<=, :>=, :==, :!=]

  set_cc 0xA
  set_char ?A

  SOURCE_1_BITS = 3
  SOURCE_1_BITMASK = 0xe0000
  SOURCE_1_BITSHIFT = 17

  SOURCE_1_OPTIONS_BITS = 2
  SOURCE_1_OPTIONS_BITMASK = 0x18000
  SOURCE_1_OPTIONS_BITSHIFT = 15

  OPERATION_BITS = 4
  OPERATION_BITMASK = 0x7800
  OPERATIONS_BITSHIFT = 11

  SOURCE_2_BITS = 3
  SOURCE_2_BITMASK = 0x700
  SOURCE_2_BITSHIFT = 8

  SOURCE_2_OPTIONS_BITS = 2
  SOURCE_2_OPTIONS_BITMASK = 0xc0
  SOURCE_2_OPTIONS_BITSHIFT = 6

  DESTINATION_BITS = 3
  DESTINATION_BITMASK = 0x38
  DESTINATION_BITSHIFT = 3

  DESTINATION_OPTIONS_BITS = 2
  DESTINATION_OPTIONS_BITMASK = 0x6
  DESTINATION_OPTIONS_BITSHIFT = 1

  def s1
    Piston::REGISTERS[cv>>SOURCE_1_BITSHIFT]
  end

  def s1op
    (cv&SOURCE_1_OPTIONS_BITMASK)>>SOURCE_1_OPTIONS_BITSHIFT
  end

  def op
    Arithmetic::OPERATIONS[(cv&OPERATION_BITMASK)>>OPERATIONS_BITSHIFT]
  end

  def s2
    Piston::REGISTERS[(cv&SOURCE_2_BITMASK)>>SOURCE_2_BITSHIFT]
  end

  def s2op
    (cv&SOURCE_2_OPTIONS_BITMASK)>>SOURCE_2_OPTIONS_BITSHIFT
  end

  def d
    Piston::REGISTERS[(cv&DESTINATION_BITMASK)>>DESTINATION_BITSHIFT]
  end

  def dop
    (cv&DESTINATION_OPTIONS_BITMASK)>>DESTINATION_OPTIONS_BITSHIFT
  end

  def run(piston)
    self.class.run(piston, s1, s1op, op, s2, s2op, d, dop)
  end

  def self.reference_card
    puts %q{
    Arithmetic Instruction
    Performs an arithmatic operation and stores the output in a register

    0bCCCC111XXOOOO222YYDDDZZ0
    C = Control Code (Instruction) [4 bits]
    1 = Source 1 [3 bits]
    X = Source Options [2 bits]
    O = Operation [4 bits]
    2 = Source 2 [3 bits]
    Y = Source Options [2 bits
    D = Destination [3 bits]
    Z = Destination Options [2 bits]
    0 = Free bit [1 bit]
    }
  end

  def self.make_color(*args)
    s1 = args[0]
    s1op = args[1] << SOURCE_1_OPTIONS_BITSHIFT
    op = args[2]
    s2 = args[3]
    s2op = args[4] << SOURCE_2_OPTIONS_BITSHIFT
    d = args[5]
    dop = args[6] << DESTINATION_OPTIONS_BITSHIFT

    s1 = Piston::REGISTERS.index(s1) << SOURCE_1_BITSHIFT
    op = Arithmetic::OPERATIONS.index(op) << OPERATIONS_BITSHIFT
    s2 = Piston::REGISTERS.index(s2) << SOURCE_2_BITSHIFT
    d = Piston::REGISTERS.index(d) << DESTINATION_BITSHIFT

    (cc << CONTROL_CODE_BITSHIFT) + s1 + s1op + op + s2 + s2op + d + dop
  end

  def self.run(piston, *args)
    s1 = args[0]
    s1op = args[1]
    op = args[2]
    s2 = args[3]
    s2op = args[4]
    d = args[5]
    dop = args[6]

    v1 = piston.send(s1, s1op)
    v2 = piston.send(s2, s2op)
    result = v1.send(op, v2)

    piston.send("set_#{d.to_s}", result, dop)
  end
end

class OutputValueAsChar < Instruction
  set_cc 0xB
  set_char ?O

  def run(piston)
    self.class.run(piston, cv)
  end

  def self.run(piston, *args)
    piston.parent.write_output (args[0]%0x100).chr
  end
end

class UnusedInstruction < Instruction
  set_cc 0xC
end

class Reset < Instruction
  set_cc 0xD
  set_char ?R
  # TODO: Test piston reset
  def self.run(piston, *args)
    piston.reset
  end
end

class Kill < Instruction
  set_cc 0XE
  set_char ?K
  # TODO: Test engine kill switch
  def self.run(piston, *args)
    piston.parent.kill
  end
end

class Blank < Instruction
  set_cc 0xF
  set_char " "
end
