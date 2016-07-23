require_relative './instruction'
require_relative './piston'

# Instruction Composition
# 0bCCCCVVVVVVVVVVVVVVVVVVVV
# C = Control Code (Instruction) [4 bits]
# V = Value (Arguments) [20 bits]

# End Instruction
#
# 0bCCCC00000000000000000000
# C = Control Code (Instruction) [4 bits]
# 0 = Free bit [20 bits]
class End < Instruction
  set_cc 0
  set_char ?E
  def self.run(piston, *args)
    piston.kill
  end
end

# Start Instruction
# 
# 0bCCCCDDPPPPPPPPPPPPPPPPPP
# C = Control Code (Instruction) [4 bits]
# D = Direction [2 bits] Direction where the piston should go
# P = Priority [18 bits] Order in which piston should run their cycles. 0 goes first.
class Start < Instruction
  set_cc 1
  set_char ?S

  def direction
    Piston::DIRECTIONS[((cv & 0xf0000) >> 16) % Piston::DIRECTIONS.count]
  end

  def priority
    (cv & 0x0ffff)
  end

  def run(piston)
    self.class.run(piston, direction, priority)
  end

  def self.run(piston, *args)
    piston.change_direction(args.first)
  end
end

# Pause Instruction
#  
# 0bCCCCTTTTTTTTTTTTTTTTTTTT
# C = Control Code (Instruction) [4 bits]
# T = Time (Cycles to wait) [20 bits]
class Pause < Instruction
  set_cc 2
  set_char ?P

  def cycles
    cv
  end

  def run(piston)
    self.class.run(piston, cycles)
  end

  def self.run(piston, *args)
    piston.pause args.first
  end
end

# Direction Instruction
# Instruction Composition
# 0bCCCCDD000000000000000000
# C = Control Code (Instruction) [4 bits]
# D = Direction [2 bits] (See Pistion::DIRECTIONS for order)
# 0 = Free bit [18 bits]
class Direction < Instruction
  set_cc 3
  set_char ?D

  def direction
    Piston::DIRECTIONS[(cv & 0xf0000) >> 16]
  end

  def run(piston)
    self.class.run(piston, direction)
  end

  def self.run(piston, *args)
    piston.change_direction(args.first)
  end
end

# Fork Instruction
#  
# 0bCCCCDD000000000000000000
# C = Control Code (Instruction) [4 bits]
# D = Direction [2 bits]
# 0 = Free bit [18 bits]
class Fork < Instruction
  # kinds of pipes UpRightDown DownLeftRight etc.
  # TODO: Add :ulrd a 4way
  TYPES = [:urd, :dlr, :uld, :ulr]

  set_cc 4
  set_char ?F

  def type
    TYPES[cv>>18]
  end

  def run(piston)
    self.class.run(piston, type)
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

# Jump Instruction
#  
# 0bCCCCSSSSSSSSSSSSSSSSSSSSSSSSSSSS
# C = Control Code (Instruction) [4 bits]
# S = Spaces [20 bits] number of space beyond the first to jump
class Jump < Instruction
  set_cc 5
  set_char ?J

  def jumps
    cv
  end

  def run(piston)
    self.class.run(piston, jumps+1)
  end

  def self.run(piston, *args)
    piston.move args[0]
  end
end

# Call Instruction
#  
# 0bCCCCXWWWWWWWWWYZZZZZZZZZ
# C = Control Code (Instruction) [4 bits]
# X = X Sign [1 bit] Deterimines if X is negative or not
# W = X [9 bits] Number of X spaces to jump
# Y = Y Sign [1 bit] Deterimines if Y is negative or not
# Z = X [9 bits] Number of Y spaces to jump
class Call < Instruction
  set_cc 6
  set_char ?L

  def x_sign
    cv>>19
  end

  def y_sign
    (cv & 0x200)>>9
  end

  def xi
    (cv & 0x7fc000)>>10
  end

  def yi
    cv & 0x1ff
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

  def self.run(piston, *args)
    piston.jump(args.first, args.last)
  end
end

# Conditional Instruction
# 
# 0bCCCCO111XXAAAA222YY00000
# C = Control Code (Instruction) [4 bits]
# 1 = Source 1 Register [3 bits]
# X = Source 1 options [2 bits]
# A = Arithmatic Operation [4 bits] (See Arithmetic::OPERATIONS)
# 2 = Source 2 Register [3 bits] 
# Y = Source 2 options [2 bits]
class Conditional < Instruction
  # TODO: Utilize last 5 bits for other orientation types
  # :pass_through, :reverse_pass_through, :turn_left, :turn_right, :straight_or_left, :straight_or_right
  ORIENTATIONS = [:vertical, :horizontal]

  set_cc 7
  set_char ?C

  def orientation
    ORIENTATIONS[cv>>19]
  end

  def s1
    Piston::REGISTERS[((cv&0x70000)>>16)]
  end

  def s1op
    (cv & 0xc000) >> 14
  end

  def op
    Arithmetic::OPERATIONS[((cv&0x3c00)>>10)]
  end

  def s2
    Piston::REGISTERS[((cv&0x380)>>7)]
  end

  def s2op
    (cv & 0x60) >> 5
  end

  def run(piston)
    self.class.run(piston, orientation, s1, s1op, op, s2, s2op)
  end

  def self.run(piston, *args)
    orient = args[0]
    s1 = args[1]
    s1op = args[2]
    op = args[3]
    s2 = args[4]
    s2op = args[5]

    directions = []
    case orient
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

    if result == 0 || !result
      piston.change_direction directions[0]
    else
      piston.change_direction directions[1]
    end
  end
end

# Insert Instruction
#    Inserts a value into I
#
# 0bCCCCVVVVVVVVVVVVVVVVVVVV
# C = Control Code (Instruction) [4 bits]
# V = Value [20 bits]
class Insert < Instruction
  set_cc 8
  set_char ?I

  def run(piston)
    self.class.run(piston, cv)
  end

  def self.run(piston, *args)
    piston.set_i args[0]
  end
end

# Move Instruction
#    Moves a value from one register to another.
#
# 0bCCCCSSSXXDDDYY0000000000
# C = Control Code (Instruction) [4 bits]
# S = Source [3 bits]
# X = Source Options [2 bits]
# D = Destination [3 bits]
# Y = Destination Options [2 bits]
# 0 = Free bit [10 bits]
# TODO: Explain and test swap and reverse.
class Move < Instruction
  set_cc 9
  set_char ?M

  def s
    Piston::REGISTERS[(cv&0xe0000)>>17]
  end

  def sop
    (cv&0x18000)>>15
  end

  def d
    Piston::REGISTERS[(cv&0x7000)>>12]
  end

  def dop
    (cv&0xc00) >> 10
  end

  def run(piston)
    self.class.run(piston, s, sop, d, dop)
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
      swap = ((sop>>1) != 0)
      reverse = ((sop&1) != LOGICAL_FALSE)
    elsif Piston::REGULAR_REG.include?(d)
      swap = ((dop>>1) != 0)
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

# Arithmetic Instruction
#    Performs an arithmatic operation and stores the output in a register
#
# 0bCCCC111XXOOOO222YYDDDZZ0
# C = Control Code (Instruction) [4 bits]
# 1 = Source 1 [3 bits]
# X = Source Options [2 bits]
# O = Operation [4 bits]
# 2 = Source 2 [3 bits]
# Y = Source Options [2 bits
# D = Destination [3 bits]
# Z = Destination Options [2 bits]
class Arithmetic < Instruction
  OPERATIONS = [:+, :-, :*, :/, :**, :&, :|, :^, :%,
                :<, :>, :<=, :>=, :==, :!=]

  set_cc 0xA
  set_char ?A

  def s1
    Piston::REGISTERS[cv>>17]
  end

  def s1op
    (cv&0x18000)>>15
  end

  def op
    Arithmetic::OPERATIONS[(cv&0x7800)>>11]
  end

  def s2
    Piston::REGISTERS[(cv&0x700)>>8]
  end

  def s2op
    (cv&0xc0)>>6
  end

  def d
    Piston::REGISTERS[(cv&0x38)>>3]
  end

  def dop
    (cv&0x6)>>1
  end

  def run(piston)
    self.class.run(piston, s1, s1op, op, s2, s2op, d, dop)
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
