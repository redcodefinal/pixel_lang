require_relative './../instruction'
require_relative './../piston'
class Start < Instruction
  set_cc 1
  set_char ?S

  DIRECTION_BITS = 2
  DIRECTION_BITMASK = 0xC0000
  DIRECTION_BITSHIFT = 18

  PRIORITY_BITS = 18
  PRIORITY_BITMASK = 0x3FFFF

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

  def direction
    Piston::DIRECTIONS[((cv & DIRECTION_BITMASK) >> DIRECTION_BITSHIFT)]
  end

  def priority
    (cv & PRIORITY_BITMASK)
  end

  def run(piston)
    self.class.run(piston, direction, priority)
  end
end