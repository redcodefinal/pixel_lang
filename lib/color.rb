# Custom color class that will roll over 24-bit ints.
class Color
  # min byte
  MIN = 0
  # max byte
  MAX = 0x1000000

  # actual int value of the color (0xffffff is white)
  attr_reader :value

  def initialize(v = 0)
    self.value = v
  end

  # set the value and roll it over or backwards based on the result.
  def value=(x)
    x = (MAX - (x.abs % MAX) + 1) if x < 0
    x = x % MAX
    @value = x
  end

  # get the top byte (red)
  def r
    (value & 0xff0000) >> 16
  end

  # get the middle byte (green)
  def g
    (value & 0x00ff00) >> 8
  end

  # get the bottom byte (blue)
  def b
    (value & 0x0000ff)
  end

  # set the top byte (red)
  def r=(v)
    v = v % 0x1000
    @value = (v << 16) + (g << 8) + b
  end

  # set the middle byte (green)
  def g=(v)
    v = v % 0x1000
    @value = (r << 16) + (v << 8) + b
  end

  # set the bottom byte (blue)
  def b=(v)
    v = v % 0x1000
    @value = (r << 16) + (g << 8) + v
  end

  def to_i
    value
  end

  # outputs a hexadecimal value prefixed with 0x (0xffffff)
  def to_s
    '0x' << to_i.to_s(16)
  end

  def ==(other)
    value == other.to_i
  end
end

class Color
  WHITE = Color.new(0xffffff)
  BLACK = Color.new(0x000000)
  RED = Color.new (0xff0000)
  GREEN = Color.new (0x00ff00)
  BLUE = Color.new(0x0000ff)
end