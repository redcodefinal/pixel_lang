require_relative './../instruction'
require_relative './../piston'

class Insert < Instruction
  set_cc 8
  set_char ?I

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

  def run(piston)
    self.class.run(piston, cv)
  end
end