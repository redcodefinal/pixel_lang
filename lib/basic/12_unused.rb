require_relative './../instruction'
require_relative './../piston'
#TODO: Implement something
#  Command to change an instruction based on ma and mav?
#
class UnusedInstruction < Instruction
  set_cc 0xC
end