require_relative './../instruction'
require_relative './../piston'

class Blank < Instruction
  set_cc 0xF
  set_char " "
end