require_relative './instruction'

class Blank < Instruction
  set_cc 0
end

class Start < Instructions
  attr_reader :direction, :priority

  set_cc 1

  def run(piston)
    @direction = (cv & 0xf0000) >> 16
    @priority = (cv & 0x0ffff)
    self.class.run(piston, direction, priority)
  end

  def self.run(piston, *args)
    piston.change_direction(args.first)
  end
end

class Pause < Instructions
  attr_reader :cycles

  set_cc 1

  def run(piston)
    @cycles
    self.class.run
  end
end

class Direction < Instructions
  set_cc 2
end

class Fork < Instructions
  set_cc 3
end

class Jump < Instruction
  set_cc 4
end

class Call < Instruction
  set_cc 5
end

class Conditional < Instructions
  set_cc 6
end

class Insert < Instructions
  set_cc 7
end

class Move < Instructions
  set_cc 8
end

class Arithmetic < Instructions
  set_cc 9
end

class End < Instruction
  set_cc 10
end