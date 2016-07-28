require_relative './../instruction'
require_relative './../piston'

class Arithmetic < Instruction
  OPERATIONS = [:+, :-, :*, :/, :**, :&, :|, :^, :%,
                :<, :>, :<=, :>=, :==, :!=]

  set_cc 0xA
  set_char ?A

  SOURCE_1_BITS = 3
  SOURCE_1_BITMASK = 0xe0000
  SOURCE_1_BITSHIFT = 17

  SOURCE_1_OPTIONS_BITS = 2
  SOURCE_1_OPTIONS_BITMASK = 0x18000
  SOURCE_1_OPTIONS_BITSHIFT = 15

  OPERATION_BITS = 4
  OPERATION_BITMASK = 0x7800
  OPERATIONS_BITSHIFT = 11

  SOURCE_2_BITS = 3
  SOURCE_2_BITMASK = 0x700
  SOURCE_2_BITSHIFT = 8

  SOURCE_2_OPTIONS_BITS = 2
  SOURCE_2_OPTIONS_BITMASK = 0xc0
  SOURCE_2_OPTIONS_BITSHIFT = 6

  DESTINATION_BITS = 3
  DESTINATION_BITMASK = 0x38
  DESTINATION_BITSHIFT = 3

  DESTINATION_OPTIONS_BITS = 2
  DESTINATION_OPTIONS_BITMASK = 0x6
  DESTINATION_OPTIONS_BITSHIFT = 1

  def self.reference_card
    puts %q{
    Arithmetic Instruction
    Performs an arithmatic operation and stores the output in a register

    0bCCCC111XXOOOO222YYDDDZZ0
    C = Control Code (Instruction) [4 bits]
    1 = Source 1 [3 bits]
    X = Source Options [2 bits]
    O = Operation [4 bits]
    2 = Source 2 [3 bits]
    Y = Source Options [2 bits
    D = Destination [3 bits]
    Z = Destination Options [2 bits]
    0 = Free bit [1 bit]
    }
  end

  def self.make_color(*args)
    s1 = args[0]
    s1op = args[1] << SOURCE_1_OPTIONS_BITSHIFT
    op = args[2]
    s2 = args[3]
    s2op = args[4] << SOURCE_2_OPTIONS_BITSHIFT
    d = args[5]
    dop = args[6] << DESTINATION_OPTIONS_BITSHIFT

    s1 = Piston::REGISTERS.index(s1) << SOURCE_1_BITSHIFT
    op = Arithmetic::OPERATIONS.index(op) << OPERATIONS_BITSHIFT
    s2 = Piston::REGISTERS.index(s2) << SOURCE_2_BITSHIFT
    d = Piston::REGISTERS.index(d) << DESTINATION_BITSHIFT

    (cc << CONTROL_CODE_BITSHIFT) + s1 + s1op + op + s2 + s2op + d + dop
  end

  def self.run(piston, *args)
    s1 = args[0]
    s1op = args[1]
    op = args[2]
    s2 = args[3]
    s2op = args[4]
    d = args[5]
    dop = args[6]

    v1 = piston.send(s1, s1op)
    v2 = piston.send(s2, s2op)
    result = v1.send(op, v2).round

    piston.send("set_#{d.to_s}", result, dop)
  end

  def s1
    Piston::REGISTERS[cv>>SOURCE_1_BITSHIFT]
  end

  def s1op
    (cv&SOURCE_1_OPTIONS_BITMASK)>>SOURCE_1_OPTIONS_BITSHIFT
  end

  def op
    Arithmetic::OPERATIONS[(cv&OPERATION_BITMASK)>>OPERATIONS_BITSHIFT]
  end

  def s2
    Piston::REGISTERS[(cv&SOURCE_2_BITMASK)>>SOURCE_2_BITSHIFT]
  end

  def s2op
    (cv&SOURCE_2_OPTIONS_BITMASK)>>SOURCE_2_OPTIONS_BITSHIFT
  end

  def d
    Piston::REGISTERS[(cv&DESTINATION_BITMASK)>>DESTINATION_BITSHIFT]
  end

  def dop
    (cv&DESTINATION_OPTIONS_BITMASK)>>DESTINATION_OPTIONS_BITSHIFT
  end

  def run(piston)
    self.class.run(piston, s1, s1op, op, s2, s2op, d, dop)
  end
end