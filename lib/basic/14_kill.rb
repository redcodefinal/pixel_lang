require_relative './../instruction'
require_relative './../piston'

class Kill < Instruction
  set_cc 0XE
  set_char ?K
  # TODO: Test engine kill switch
  def self.run(piston, *args)
    piston.parent.kill
  end
end