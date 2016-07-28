require_relative './../instruction'
require_relative './../piston'

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