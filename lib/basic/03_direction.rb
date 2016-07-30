require_relative './../instruction'
require_relative './../piston'

class Direction < Instruction
  set_cc 3
  set_char ?D

  DIRECTION_BITMASK = 0x3

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
    ((cc << CONTROL_CODE_BITSHIFT) + direction).to_s 16
  end

  def self.run(piston, *args)
    piston.change_direction(args.first)
  end

  #TODO: Add more directions (turn_left, turn_right, turn_around)

  def direction
    Piston::DIRECTIONS[(cv & DIRECTION_BITMASK)]
  end

  def run(piston)
    self.class.run(piston, direction)
  end
end