require_relative './../instruction'
require_relative './../piston'

class Call < Instruction
  set_cc 6
  set_char ?L

  X_SIGN_BITS = 1
  X_SIGN_BITMASK = 0x80000
  X_SIGN_BITSHIFT = 18

  X_BITS = 9
  X_BITMASK = 0x7fc000
  X_BITSHIFT = 9

  Y_SIGN_BITS = 1
  Y_SIGN_BITMASK = 0x200
  Y_SIGN_BITSHIFT = 8

  Y_BITS = 9
  Y_BITMASK = 0x1ff
  Y_BITSHIFT = 0


  def x_sign
    cv>>X_SIGN_BITSHIFT
  end

  def xi
    (cv & X_BITMASK)>>X_BITSHIFT
  end

  def y_sign
    (cv & Y_SIGN_BITMASK)>>Y_SIGN_BITSHIFT
  end

  def yi
    cv & Y_BITMASK
  end

  def x
    ((x_sign == 0) ? xi : -xi)
  end

  def y
    ((y_sign == 0) ? yi : -yi)
  end

  def run(piston)
    self.class.run(piston, x, y)
  end

  def self.reference_card
    puts %q{
    Call Instruction
    Jumps a piston to a nearby instruction by the offset coordinates.

    0bCCCCXWWWWWWWWWYZZZZZZZZZ
    C = Control Code (Instruction) [4 bits]
    X = X Sign [1 bit] Deterimines if X is negative or not
    W = X [9 bits] Number of X spaces to jump
    Y = Y Sign [1 bit] Deterimines if Y is negative or not
    Z = Y [9 bits] Number of Y spaces to jump
    }
  end

  def self.make_color(*args)
    x = args.first
    y = args.last

    x_sign = x < 0
    y_sign = y < 0

    x = x.abs
    y = y.abs

    (cc << CONTROL_CODE_BITSHIFT) + (((x_sign)?1:0) << X_SIGN_BITSHIFT) + (x << X_BITSHIFT) + (((y_sign)?1:0) << Y_SIGN_BITSHIFT) + (y << Y_BITSHIFT)
  end

  def self.run(piston, *args)
    piston.jump(args.first, args.last)
  end
end
