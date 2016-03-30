require_relative './instruction'
require_relative './piston'

class End < Instruction
  set_cc 0

  def self.run(piston, *args)
    piston.kill
  end
end

class Start < Instruction
  attr_reader :direction, :priority

  set_cc 1
  set_char ?S

  def initialize(color)
    super color
    @direction = Piston::DIRECTIONS[((cv & 0xf0000) >> 16) % Piston::DIRECTIONS.count]
    @priority = (cv & 0x0ffff)
  end

  def run(piston)
    self.class.run(piston, direction, priority)
  end

  def self.run(piston, *args)
    piston.change_direction(args.first)
  end
end

class Pause < Instruction
  attr_reader :cycles

  set_cc 2
  set_char ?P

  def initialize(color)
    super color
    @cycles = cv
  end

  def run(piston)

    self.class.run(piston, cycles)
  end

  def self.run(piston, *args)
    piston.pause args.first
  end
end

class Direction < Instruction
  attr_reader :direction

  set_cc 3
  set_char ?D

  def initialize(color)
    super color
    @direction = Piston::DIRECTIONS[(cv & 0xf0000) >> 16]
  end

  def run(piston)
    self.class.run(piston, direction)
  end

  def self.run(piston, *args)
    piston.change_direction(args.first)
  end
end

class Fork < Instruction
  TYPES = [:urd, :dlr, :uld, :ulr]
  attr_reader :type

  set_cc 4
  set_char ?F

  def initialize(color)
    super color
    @type = TYPES[cv>>18]
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

class Jump < Instruction
  attr_reader :spaces

  set_cc 5
  set_char ?J

  def initialize(color)
    super color
    @jumps = cv
  end

  def run(piston)
    self.class.run(piston, jumps+1)
  end

  def self.run(piston, *args)
    piston.move args[0]
  end
end

class Call < Instruction
  attr_reader :x, :y

  set_cc 6
  set_char ?L

  def initialize(color)
    super color

    x_sign = cv>>19
    xi = (cv & 0x7fc000)>>10
    y_sign = (cv & 0x200)>>9
    yi = cv & 0x1ff

    @x = ((x_sign == 0) ? xi : -xi)
    @y = ((y_sign == 0) ? yi : -yi)
  end

  def run(piston)
    self.class.run(piston, x, y)
  end

  def self.run(piston, *args)
    piston.jump(args.first, args.last)
  end
end

class Conditional < Instruction
  ORIENTATIONS = [:vertical, :horizontal]
  attr_reader :orientation, :s1, :s1o, :op, :s2, :s2o

  set_cc 7
  set_char ?C


  def initialize(color)
    super color

    @orientation = ORIENTATIONS[cv>>19]
    @s1 = Piston::REGISTERS[((cv&0x70000)>>16)]
    @s1o = (cv & 0xc000) >> 14
    @op = Arithmetic::OPERATIONS[((cv&0x3c00)>>10)]
    @s2 = Piston::REGISTERS[((cv&0x380)>>8)]
    @s2o = (cv & 0x60) >> 6
  end

  def run(piston)
    self.class.run(piston, orientation, s1, s1o, op, s2, s2o)
  end

  def self.run(piston, *args)
    orient = args[0]
    s1 = args[1]
    s1o = args[2]
    op = args[3]
    s2 = args[4]
    s2o = args[5]

    directions = []
    case orient
      when :vertical
        directions = [:up, :down]
      when :horizontal
        directions = [:left, :right]
      else
        fail "CONDITIONAL_ORIENTATION_ERROR"
    end

    v1 = piston.send(s1, s1o)
    v2 = piston.send(s2, s2o)

    result = v1.send(op, v2)

    if result == 0 || !result
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

  def self.run(piston, *args)
    piston.set_i args[0]
  end
end

class Move < Instruction
  attr_reader :s, :sop, :d, :dop

  set_cc 9
  set_char ?M

  def initialize(color)
    super(color)

    @s = Piston::REGISTERS[(cv&0xe0000)>>17]
    @sop = (cv&0x18000)>>15
    @d = Piston::REGISTERS[(cv&0x7000)>>12]
    @dop = (cv&0xc00) >> 10
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

class Arithmetic < Instruction
  OPERATIONS = [:+, :-, :*, :/, :**, :&, :|, :^, :%,
                :<, :>, :<=, :>=, :==, :!=]

  attr_reader :s1, :s1o, :op, :s2, :s2o, :d, :dop

  set_cc 0xA
  set_char ?A

  def initialize(color)
    super(color)

    @s1 = Piston::REGISTERS[cv>>17]
    @s1o = (cv&0x18000)>>15
    @op = Arithmetic::OPERATIONS[(cv&0x7800)>>11]
    @s2 = Piston::REGISTERS[(cv&0x700)>>8]
    @s2o = (cv&0xc0)>>6
    @d = Piston::REGISTERS[(cv&0x38)>>3]
    @dop = (cv&0x6)>>1
  end

  def run(piston)
    self.class.run(piston, s1, s1o, op, s2, s2o, d, dop)
  end

  def self.run(piston, *args)
    s1 = args[0]
    s1o = args[1]
    op = args[2]
    s2 = args[3]
    s2o = args[4]
    d = args[5]
    dop = args[6]

    v1 = piston.send(s1, s1o)
    v2 = piston.send(s2, s2o)
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
    piston.parent.write_output (args[0]%256).chr
  end
end

class OutputValue <Instruction
  set_cc 0xC
  set_char ?O

  def run(piston)
    self.class.run(piston, cv)
  end

  def self.run(piston, *args)
    piston.parent.write_output args[0]
  end
end

class Blank < Instruction
  set_cc 0xf
  set_char ?B
end
