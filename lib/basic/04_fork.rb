require_relative './../instruction'
require_relative './../piston'

class Fork < Instruction
  # kinds of pipes UpRightDown DownLeftRight etc.
  # TODO: TYPES TO ADD :r_urd, :r_dlr, :r_uld, :r_ulr, :r_ulrd
  TYPES = [:urd, :dlr, :uld, :ulr, :ulrd]

  set_cc 4
  set_char ?F

  def self.reference_card
    puts %q{
    Fork Instruction
    Forks a piston into multiple readers with different directions

    0bCCCC00000000000000000TTT
    C = Control Code (Instruction) [4 bits]
    0 = Free bit [17 bits]
    T = Type [3 bits] (See Fork::TYPES for order)
    }
  end

  def self.make_color(*args)
    type = Fork::TYPES.index(args.first)
    ((cc << CONTROL_CODE_BITSHIFT) + type).to_s 16
  end

  def self.run(piston, *args)
    case args[0]
      when :urd
        case (piston.direction)
          when :up
            piston.parent.fork(piston, :right)
          when :left
            piston.parent.fork(piston, :left)
            piston.turn_right
          when :down
            piston.parent.fork(piston, :left)
          when :right
            piston.reverse
          else
            raise Exception.new
        end
      when :dlr
        case (piston.direction)
          when :up
            piston.parent.fork(piston, :left)
            piston.turn_right
          when :left
            piston.parent.fork(piston, :left)
          when :down
            thread.reverse
          when :right
            piston.parent.fork(piston, :right)
          else
            raise Exception.new
        end
      when :uld
        case (piston.direction)
          when :up
            piston.parent.fork(piston, :left)
          when :left
            piston.reverse
          when :down
            piston.parent.fork(piston, :right)
          when :right
            piston.parent.fork(piston, :left)
            piston.turn_right
          else
            raise Exception.new
        end
      when :ulr
        case (piston.direction)
          when :up
            piston.reverse
          when :left
            piston.parent.fork(piston, :right)
          when :down
            piston.parent.fork(piston, :left)
            piston.turn_right
          when :right
            piston.parent.fork(piston, :left)
          else
            raise Exception.new
        end
      when :ulrd
        case (piston.direction)
          when :up
            piston.parent.fork(piston, :right)
            piston.parent.fork(piston, :left)
          when :left
            piston.parent.fork(piston, :right)
            piston.parent.fork(piston, :left)
          when :down
            piston.parent.fork(piston, :right)
            piston.parent.fork(piston, :left)
          when :right
            piston.parent.fork(piston, :right)
            piston.parent.fork(piston, :left)
          else
            raise Exception.new
        end
      else
        fail "FORK TYPE ERROR"
    end
  end

  def type
    TYPES[cv % TYPES.count]
  end

  def run(piston)
    self.class.run(piston, type)
  end
end
