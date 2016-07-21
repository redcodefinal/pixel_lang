# Single piston for an instruction reader and executor.
class Piston
  # parent of the piston, should be a machine
  attr_reader :parent
  # 2d array of instructions, is of type Instructions
  attr_reader :position_x, :position_y
  # direction of travel
  attr_reader :direction
  # Piston memory
  attr_reader :memory
  # is the piston paused?
  attr_reader :paused
  # how many more cycles should the piston pause for
  attr_reader :paused_counter
  # has the piston ended?
  attr_reader :ended
  # the identity of the piston, given by the parent machine
  attr_reader :id


  # clockwise list of instructions
  DIRECTIONS = [:up, :right, :down, :left]
  
  # Total list of resisters
  REGISTERS = [:ma, :mav, :mb, :mbv, :sa, :sv, :i, :o]
  
  # List of the regular registers, which all  operate the same. 
  # Regular registers allow access to a memory wheel.
  # Registers MA and MB refer to the current memory address for a local piston.
  # Registers MAV and MBV refer to the value pointed to by MA and MB.
  # Registers SA and SV refer to the global memory.
  # All six registers here act the same way, and allow input and output
  REGULAR_REG = REGISTERS[0..5]
  # List of the special registers, which have special meaning.
  # Register I is the input register. It allows access to the input buffer in the engine.
  # Register O is the output register. In allows access to the output buffer in the engine.
  # I and O work differently from each other and should be treated differently.
  # I grabs a char from the input buffer if gotten from (I is the/a source). For example using a AR IV + MAV -> OV insuction
  # Simply using the I register changes the input buffer.
  # The I register can also be written to, to be used as a one time variable. This appends the input buffer now (Although this may change as I could be thread local.)
  # The O register kind of works the opposite. 
  # When O is written to (is the destination) it writes to the output buffer. You can control whether it writes as a char, int, hex int, hex char.
  # If O is the/a source it will give back the last 20-bits that was given to it. 
  SPECIAL_REG = REGISTERS[6..7]
  # Input options for register I
  INPUT_OPTIONS = [:int, :char]
  # Output options for register O
  OUTPUT_OPTIONS =  [:int, :char, :int_hex, :char_hex]
  # Maximum number allowed (20-bits)
  MAX_INTEGER = 0xfffff

  def initialize(parent, position_x, position_y, direction)
    @parent = parent
    @position_x = position_x
    @position_y = position_y
    @direction = direction

    @paused = false
    @paused_counter = 0
    @ended = false
    @id = parent.make_id

    @ma = 0
    @mb = 0
    @sa = 0

    reset
  end

  def ma(*options)
    @ma
  end
  
  # TODO: Shouldn't this be MAX_INTEGER + 1?
  def set_ma(v, *options)
    @ma = v % MAX_INTEGER
  end

  def mav(*options)
    @memory[ma]
  end

  def set_mav(v, *options)
    @memory[ma] = v % MAX_INTEGER
  end

  def mb(*options)
    @mb
  end

  def set_mb(v, *options)
    @mb = v % MAX_INTEGER
  end

  def mbv(*options)
    @memory[mb]
  end

  def set_mbv(v, *options)
    @memory[mb] = v % MAX_INTEGER
  end

  def sa(*options)
    @sa
  end

  def set_sa(v, *options)
    @sa = v % MAX_INTEGER
  end

  def sv(*options)
    parent.memory[sa]
  end

  def set_sv(v, *options)
    parent.memory[sa] = v % MAX_INTEGER
  end

  # TODO: TEST AND POSSIBLY FIX THIS
  def i(*options)
    code = INPUT_OPTIONS[options.first]
    #if we put a number on the stack
    if @i
      i = @i
      @i = nil

      case code
        when :int
          i
        when :char
          i %= 0x100
      end
      return 
    end

    case code
      when :int
        parent.grab_input_number
      when :char
        parent.grab_input_char
      else
        fail
    end
  end

  def set_i(v, *options)
    parent.input.unshift @i if @i
    @i = v
  end

  def o(*options)
    code = INPUT_OPTIONS[options.first]
    case code
      when :int
        @o
      when :char
        @o % 0x100
      else
        fail
    end
  end

  def set_o(v, *options)
    code = OUTPUT_OPTIONS[options.first]
    @o = v
    case code
      when :int
        parent.write_output @o
      when :char
        parent.write_output((@o % 0x100).chr)
      when :int_hex
        parent.write_output "0x#{@o.to_s(16).rjust(5, ?0)}"
      when :char_hex
        parent.write_output "0x#{(@o%0x100).to_s(16).rjust(2, ?0)}"
      else
        fail
    end
  end

  # resets memory
  def reset
    @memory = {}
    memory.default = 0
  end

  def clone
    Piston.new(parent, position_x, position_y, direction)
  end

  # runs a single instruction and moves
  def run_one_instruction
    if paused
      @paused_counter -= 1
      parent.log.debug "^  T#{id} C:#{parent.cycles} is paused for #{@paused_counter} cycles"
      if @paused_counter <= 0
        parent.log.debug "^  T#{id} is unpaused"
        unpause
      end
      return
    end

    instruction = parent.instructions.get_instruction(position_x, position_y)
    fail unless instruction
    parent.log.info "T#{id} C:#{parent.cycles} Running #{instruction.class} @ #{position_x}, #{position_y} CV: #{instruction.cv.to_s 16}"
    instruction.run(self)
    parent.log.debug '^  Piston state:'
    parent.log.debug "^     d:#{direction}"
    parent.log.debug "^     ma:#{ma.to_s 16}"
    parent.log.debug "^     mav:#{mav.to_s 16}"
    parent.log.debug "^     mb:#{mb.to_s 16}"
    parent.log.debug "^     mbv:#{mbv.to_s 16}"
    parent.log.debug "^     sa:#{sa.to_s 16}"
    parent.log.debug "^     sv:#{sv.to_s 16}"
    parent.log.debug "^     i:#{@i.ord.to_s 16}" if @i
    parent.log.debug '^  Machine state:'
    parent.log.debug "^     static: #{parent.memory}"
    parent.log.debug "^     output: #{parent.output}"
    parent.log.debug "^     input: #{parent.input}"

    #move unless we called here recently.
    move 1 unless instruction.class == Call
  end

  # change the direction
  def change_direction(d)
    @direction = d
  end

  # turns the piston left
  def turn_right
    index = DIRECTIONS.index(direction) + 1
    index = 0 if index >= DIRECTIONS.length
    change_direction(index)
  end

  # turns the piston right
  def turn_left
    index = DIRECTIONS.index(direction) - 1
    index = DIRECTIONS.length-1 if index < 0
    change_direction(index)
  end

  # reverses the piston
  def reverse
    turn_left
    turn_left
  end

  # moves the instruction cursor amount units in a direction
  def move(amount)
    case direction
      when :up
        @position_y -= amount
      when :down
        @position_y += amount
      when :left
        @position_x -= amount
      when :right
        @position_x += amount
      else
        throw ArgumentError.new
    end
  end

  # jumps to a relative position
  def jump(x, y)
    @position_x += x
    @position_y += y
  end

  # pauses the piston for a certain amount of cycles
  def pause(cycles)
    @paused = true
    @paused_counter = cycles
  end

  # unpause the piston
  def unpause
    @paused = false
    @paused_counter = 0
  end

  # kill the piston
  def kill
    @ended = true
  end

  alias_method :paused?, :paused
  alias_method :ended?, :ended
  alias_method :killed?, :ended
end
