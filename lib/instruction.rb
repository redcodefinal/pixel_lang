# Instruction Composition
# 0bCCCCVVVVVVVVVVVVVVVVVVVV
# C = Control Code (Instruction) [4 bits]
# V = Value (Arguments) [20 bits]

class Instruction

  LOGICAL_FALSE = 0
  LOGICAL_TRUE = 1

  CONTROL_CODE_BITS = 4
  CONTROL_CODE_BITMASK = 0xF00000
  CONTROL_CODE_BITSHIFT = 20

  COLOR_VALUR_BITS = 20
  COLOR_VALUE_BITMASK = 0xFFFFF

  attr_reader :color

  def initialize(color)
    @color = color
  end

  def cc
    (color.value & CONTROL_CODE_BITMASK) >> CONTROL_CODE_BITSHIFT
  end

  def cv
    color.value & COLOR_VALUE_BITMASK
  end

  def run(piston)
    self.class.run(piston)
  end

  class << self
    attr_reader :cc
    attr_reader :char

    def set_char(c)
      @char = c
    end

    def set_cc(cc)
      @cc = cc
    end

    def match(color)
      ((color.value & CONTROL_CODE_BITMASK) >> CONTROL_CODE_BITSHIFT)  == @cc
    end

    def run(piston, *args)

    end

    def inherited(base)
      Instructions.add_instruction base
    end
  end
end