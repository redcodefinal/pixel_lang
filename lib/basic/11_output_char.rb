require_relative './../instruction'
require_relative './../piston'
class OutputChar < Instruction
  set_cc 0xB
  set_char ?O

  def self.make_color(*args)
    ((cc << CONTROL_CODE_BITSHIFT) + args[0].ord).to_s 16
  end

  def run(piston)
    self.class.run(piston, cv)
  end

  def self.run(piston, *args)
    piston.parent.write_output (args[0]%0x100).chr
  end
end