class Instruction

  LOGICAL_FALSE = 0
  LOGICAL_TRUE = 1

  attr_reader :color

  def initialize(color)
    @color = color
  end

  def cc
    (color.value & 0xf00000) >> 20
  end

  def cv
    color.value & 0x0fffff
  end

  def run(piston)
    self.class.run(piston)
  end

  class << self
    attr_reader :control_code
    attr_reader :char

    def set_char(c)
      @char = c
    end

    def set_cc(cc)
      @control_code = cc
    end

    def match(color)
      ((color.value & 0xf00000) >> 20)  == control_code
    end

    def run(piston, *args)

    end

    def inherited(base)
      Instructions.add_instruction base
    end
  end
end