require_relative './../instruction'
require_relative './../piston'
class OutputValueAsChar < Instruction
  set_cc 0xB
  set_char ?O

  def run(piston)
    self.class.run(piston, cv)
  end

  def self.run(piston, *args)
    piston.parent.write_output (args[0]%0x100).chr
  end
end