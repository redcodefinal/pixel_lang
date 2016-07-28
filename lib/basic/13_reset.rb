require_relative './../instruction'
require_relative './../piston'

class Reset < Instruction
  set_cc 0xD
  set_char ?R
  # TODO: Test piston reset
  def self.run(piston, *args)
    piston.reset
  end
end