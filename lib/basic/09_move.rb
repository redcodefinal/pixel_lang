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

  SWAP_BITS = 1
  SWAP_BITMASK = 0x200
  SWAP_BITSHIFT = 9

  REVERSE_BITS = 1
  REVERSE_BITMASK = 0x100
  REVERSE_BITSHIFT = 8

  def self.reference_card
    puts %q{
    Move Instruction
    Moves the contents of one register into another. Can also swap values of regular registers.

    0bCCCCSSSXXDDDYYWE00000000
    C = Control Code (Instruction) [4 bits]
    S = Source                     [3 bits]
    X = Source Options             [2 bits]
    D = Destination                [3 bits]
    Y = Destination Options        [2 bits]
    W = Swap                       [1 bit]
    R = Reverse                    [1 bit]
    0 = Free bit                   [8 bits]
    }
  end

  def self.make_color(*args)
    source = args[0]
    source_options = args[1]
    destination = args[2]
    destination_options = args[3]
    swap = args[4]
    reverse = args[5]

    source_options <<= SOURCE_OPTIONS_BITSHIFT
    destination_options <<= DESTINATION_OPTIONS_BITSHIFT

    source = Piston::REGISTERS.index(source) << SOURCE_BITSHIFT

    destination = Piston::REGISTERS.index(destination) << DESTINATION_BITSHIFT


    swap = (swap ? LOGICAL_TRUE : LOGICAL_FALSE) << SWAP_BITSHIFT
    reverse = (reverse ? LOGICAL_TRUE : LOGICAL_FALSE) << REVERSE_BITSHIFT


    ((cc << CONTROL_CODE_BITSHIFT) + source + source_options + destination + destination_options + swap + reverse).to_s 16
  end

  def self.run(piston, *args)
    s = args[0]
    sop = args[1]
    d = args[2]
    dop = args[3]
    swap = args[4]
    reverse = args[5]

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

  def s
    Piston::REGISTERS[(cv&SOURCE_BITMASK)>>SOURCE_BITSHIFT]
  end

  def sop
    (cv & SOURCE_OPTIONS_BITMASK )>> SOURCE_OPTIONS_BITSHIFT
  end

  def d
    Piston::REGISTERS[(cv&DESTINATION_BITMASK)>>DESTINATION_BITSHIFT]
  end

  def dop
    (cv&DESTINATION_OPTIONS_BITMASK) >> DESTINATION_OPTIONS_BITSHIFT
  end

  def reverse
    ((cv & REVERSE_BITMASK) >> REVERSE_BITSHIFT) == LOGICAL_TRUE
  end

  def swap
    ((cv & SWAP_BITMASK) >> SWAP_BITSHIFT) == LOGICAL_TRUE
  end

  def run(piston)
    self.class.run(piston, s, sop, d, dop, swap, reverse)
  end
end
