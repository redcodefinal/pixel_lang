require_relative './../instruction'
require_relative './../piston'

# TODO: Explain and test swap and reverse.
class Move < Instruction
  set_cc 9
  set_char ?M

  SOURCE_BITS = 3
  SOURCE_BITMASK = 0xe0000
  SOURCE_BITSHIFT = 17

  SOURCE_OPTIONS_BITS = 2
  SOURCE_OPTIONS_BITMASK = 0x18000
  SOURCE_OPTIONS_BITSHIFT = 15


  DESTINATION_BITS = 3
  DESTINATION_BITMASK = 0x7000
  DESTINATION_BITSHIFT = 12

  DESTINATION_OPTIONS_BITS = 2
  DESTINATION_OPTIONS_BITMASK = 0xc00
  DESTINATION_OPTIONS_BITSHIFT = 10


  def s
    Piston::REGISTERS[(cv&SOURCE_BITMASK)>>SOURCE_BITSHIFT]
  end

  def sop
    (cv&SOURCE_OPTIONS_BITMASK)>>SOURCE_OPTIONS_BITSHIFT
  end

  def d
    Piston::REGISTERS[(cv&DESTINATION_BITMASK)>>DESTINATION_BITSHIFT]
  end

  def dop
    (cv&DESTINATION_OPTIONS_BITMASK) >> DESTINATION_OPTIONS_BITSHIFT
  end

  def run(piston)
    self.class.run(piston, s, sop, d, dop)
  end

  def self.reference_card
    puts %q{
    Move Instruction
    Moves the contents of one register into another. Can also swap values of regular registers.

    0bCCCCSSSXXDDDYY0000000000
    C = Control Code (Instruction) [4 bits]
    S = Source [3 bits]
    X = Source Options [2 bits]
    D = Destination [3 bits]
    Y = Destination Options [2 bits]
    0 = Free bit [10 bits]
    }
  end

  def self.make_color(*args)
    source = args[0]
    source_options = args[1] << SOURCE_OPTIONS_BITSHIFT
    destination = args[2]
    destination_options = args[3] << DESTINATION_OPTIONS_BITSHIFT

    source = Piston::REGISTERS.index(source) << SOURCE_BITSHIFT
    destination = Piston::REGISTERS.index(destination) << DESTINATION_BITSHIFT


    (cc << CONTROL_CODE_BITSHIFT) + source + source_options + destination + destination_options
  end

  def self.run(piston, *args)
    s = args[0]
    sop = args[1]
    d = args[2]
    dop = args[3]

    #decode swap and reverse options
    # if both of the registers are normal
    # to ensure i and o dont have their options mixed
    if Piston::REGULAR_REG.include?(s) and Piston::REGULAR_REG.include?(d)
      o = sop^dop
      swap = ((o>>1) != LOGICAL_FALSE)
      reverse = ((o&1) != LOGICAL_FALSE)
    elsif Piston::REGULAR_REG.include?(s)
      swap = ((sop>>1) != LOGICAL_FALSE)
      reverse = ((sop&1) != LOGICAL_FALSE)
    elsif Piston::REGULAR_REG.include?(d)
      swap = ((dop>>1) != LOGICAL_FALSE)
      reverse = ((dop&1) != LOGICAL_FALSE)
    end

    s, d = d, s if reverse

    if swap
      cs = piston.send(s, sop)
      cd = piston.send(d, dop)
      piston.send("set_#{s.to_s}", cd, sop)
      piston.send("set_#{d.to_s}", cs, dop)
    else
      piston.send("set_#{d.to_s}", piston.send(s, sop), dop)
    end
  end
end
