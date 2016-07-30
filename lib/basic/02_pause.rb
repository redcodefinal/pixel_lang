require_relative './../instruction'
require_relative './../piston'

class Pause < Instruction
  set_cc 2
  set_char ?P

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

    ((cc << CONTROL_CODE_BITSHIFT) + cycles).to_s 16
  end

  def self.run(piston, *args)
    piston.pause args.first
  end

  def cycles
    cv
  end

  def run(piston)
    self.class.run(piston, cycles)
  end
end
