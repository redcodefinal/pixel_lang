require_relative './../instruction'
require_relative './../piston'

class Direction < Instruction
  set_cc 3
  set_char ?D

  DIRECTION_BITS = 4
  DIRECTION_BITMASK = 0xF
  DIRECTION_BITSHIFT = 0

  DIRECTIONS = Piston::DIRECTIONS + [:turn_left, :turn_right, :reverse, :random]

  def self.reference_card
    puts %q{
    Direction Instruction
    Tells a piston to change direction

    0bCCCC0000000000000000DDDD
    C = Control Code (Instruction) [4 bits]
    0 = Free bit [18 bits]
    D = Direction [2 bits] (See Pistion::DIRECTIONS for order)
    }
  end

  def self.make_color(*args)
    direction = DIRECTIONS.index(args.first)
    ((cc << CONTROL_CODE_BITSHIFT) + direction).to_s 16
  end

  def self.run(piston, *args)
    if Piston::DIRECTIONS.include? args.first
      piston.change_direction(args.first)
    elsif DIRECTIONS.include? args.first
      case args.first
        when :turn_left
          piston.turn_left
        when :turn_right
          piston.turn_right
        when :reverse
          piston.reverse
        when :random
          piston.change_direction Piston::DIRECTIONS.sample
      end
    else
      fail
    end
  end

  def direction
    DIRECTIONS[(cv & DIRECTION_BITMASK) >> DIRECTION_BITSHIFT]
  end

  def run(piston)
    self.class.run(piston, direction)
  end
end