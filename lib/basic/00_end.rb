require_relative './../instruction'
require_relative './../piston'
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