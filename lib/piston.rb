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

  attr_accessor :priority


  # clockwise list of instructions
  DIRECTIONS = [:up, :right, :down, :left]
  
  # Total list of resisters
  REGISTERS = [:ma, :mav, :mb, :mbv, :s, :sv, :i, :o]
  
  # List of the regular registers, which all  operate the same. 
  # Regular registers allow access to a memory wheel.
  # Registers MA and MB refer to the current memory address for a local piston.
  # Registers MAV and MBV refer to the value pointed to by MA and MB.
  # Registers S and SV refer to the global memory.
  # All six registers here act the same way, and allow input and output
  REGULAR_REG = REGISTERS[0..5]
  REGULAR_REG_S_OPTIONS = [:none, :random_max]
  REGULAR_REG_D_OPTIONS = [:none, :random_max]

  # List of the special registers, which have special meaning.
  # Register I is the input register. It allows access to the input buffer in the engine.
  # Register O is the output register. In allows access to the output buffer in the engine.
  # I and O work differently from each other and should be treated differently.
  # I grabs a char from the input buffer if gotten from (I is the/a source). For example using a AR IV + MAV -> OV instruction
  # IV grabs a value from memory, IC grabs only a char
  # Simply using the I register changes the input buffer.
  # The I register can also be written to, to be used as a stack. The stack is piston local and does not append the input.
  # The O register kind of works the opposite. 
  # When O is written to (is the destination) it writes to the output buffer. You can control whether it writes as a char, int, hex int, hex char.
  # If O is the/a source it will give back the last 20-bits that was given to output, this is globally shared between all pistons
  #TODO:  WRITE ABOUT SPECIAL RANDOM REGISTER OPTIONS
  #TODO: Replace random_int and random_char with non-pop versions
  SPECIAL_REG = REGISTERS[6..7]
  # Input options for register I
  INPUT_S_OPTIONS = [:int, :char, :no_pop_int, :no_pop_char]
  INPUT_D_OPTIONS = [:int, :char, :random_max, :null]
  OUTPUT_S_OPTIONS = [:int, :char, :random_max, :random]
  # Output options for register O
  OUTPUT_D_OPTIONS =  [:int, :char, :int_hex, :char_hex]
  # Maximum number allowed (20-bits) 2**20
  MAX_INTEGER = 0x100000

  def initialize(parent, position_x, position_y, direction)
    @parent = parent
    @position_x = position_x
    @position_y = position_y
    @direction = direction

    @paused = false
    @paused_counter = 0
    @ended = false
    @id = parent.make_id

    @priority = priority

    reset
  end

  # TODO: Add better options to regular registers

  def ma(*options)
    option = REGULAR_REG_S_OPTIONS[options.first || 0]
    case option
      when :none
        @ma
      when :random_max
        rand(@ma)
      else
        fail
    end
  end

  def set_ma(v, *options)
    option = REGULAR_REG_D_OPTIONS[options.first || 0]
    case option
      when :none
        @ma = v % MAX_INTEGER
      when :random_max
        @ma = rand(v % MAX_INTEGER)
      else
        fail
    end
  end

  def mav(*options)
    option = REGULAR_REG_S_OPTIONS[options.first || 0]
    case option
      when :none
        memory[@ma]
      when :random_max
        rand(memory[@ma])
      else
        fail
    end
  end

  def set_mav(v, *options)
    option = REGULAR_REG_D_OPTIONS[options.first || 0]
    case option
      when :none
        @memory[@ma] = v % MAX_INTEGER
      when :random_max
        @memory[@ma] = rand(v % MAX_INTEGER)
      else
        fail
    end
  end

  def mb(*options)
    option = REGULAR_REG_S_OPTIONS[options.first || 0]
    case option
      when :none
        @mb
      when :random_max
        rand(@mb)
      else
        fail
    end
  end

  def set_mb(v, *options)
    option = REGULAR_REG_D_OPTIONS[options.first || 0]
    case option
      when :none
        @mb = v % MAX_INTEGER
      when :random_max
        @mb = rand(v % MAX_INTEGER)
      else
        fail
    end
  end

  def mbv(*options)
    option = REGULAR_REG_S_OPTIONS[options.first || 0]
    case option
      when :none
        memory[@mb]
      when :random_max
        rand(memory[@mb])
      else
        fail
    end
  end

  def set_mbv(v, *options)
    option = REGULAR_REG_D_OPTIONS[options.first || 0]
    case option
      when :none
        @memory[@mb] = v % MAX_INTEGER
      when :random_max
        @memory[@mb] = rand(v % MAX_INTEGER)
      else
        fail
    end
  end

  def s(*options)
    option = REGULAR_REG_S_OPTIONS[options.first || 0]
    case option
      when :none
        @s
      when :random_max
        rand(@s)
      else
        fail
    end
  end

  def set_s(v, *options)
    option = REGULAR_REG_D_OPTIONS[options.first || 0]
    case option
      when :none
        @s = v % MAX_INTEGER
      when :random_max
        @s = rand(v % MAX_INTEGER)
      else
        fail
    end
  end

  def sv(*options)
    option = REGULAR_REG_S_OPTIONS[options.first || 0]
    case option
      when :none
        parent.memory[@s]
      when :random_max
        rand(parent.memory[@s])
      else
        fail
    end
  end

  def set_sv(v, *options)
    option = REGULAR_REG_D_OPTIONS[options.first || 0]
    case option
      when :none
        parent.memory[@s] = v % MAX_INTEGER
      when :random_max
        parent.memory[@s] = rand(v % MAX_INTEGER)
      else
        fail
    end
  end

  def i(*options)
    code = INPUT_S_OPTIONS[options.first]
    #if we put a number on the stack
    if @i.empty?
      return case code
        when :int
          parent.grab_input_number
        when :char
          parent.grab_input_char
        when :no_pop_int
          x = 0
          total = ''
          while x < engine.input.length and ('0'..'9').include?(engine.input[x])
            total << engine.input[x]
          end
          total.to_i
        when :no_pop_char
           parent.input[0]
        else
          fail
      end
    end

    case code
      when :int
        @i.pop
      when :char
        @i.pop % 0x100
      when :no_pop_int
        @i.last
      when :no_pop_char
        @i.last % 0x100
      else
        fail
    end
  end

  def set_i(v, *options)
    code = INPUT_D_OPTIONS[options.first]

    case code
      when :int
        @i << v
      when :char
        @i << v % 0x100
      when :null
        # Throw the value away
      when :random_max
        @i << rand(v)
      else
        fail
    end
  end

  def o(*options)
    code = OUTPUT_S_OPTIONS[options.first]
    case code
      when :int
        engine.last_output
      when :char
        engine.last_output % 0x100
      when :random_max
        rand engine.last_output
      when :random
        rand MAX_INTEGER
      else
        fail
    end
  end

  def set_o(v, *options)
    code = OUTPUT_D_OPTIONS[options.first]
    case code
      when :int
        parent.write_output v
      when :char
        parent.write_output((v % 0x100).chr)
      when :int_hex
        parent.write_output "0x#{v.to_s(16).rjust(5, ?0)}"
      when :char_hex
        parent.write_output "0x#{(v % 0x100).to_s(16).rjust(2, ?0)}"
      else
        fail
    end
  end

  # resets memory
  def reset
    #TODO: Test reset
    @memory = {}
    memory.default = 0

    @ma = 0
    @mb = 1
    @s = 0
    @i = []
  end

  def clone
    new_piston = Piston.new(parent, position_x, position_y, direction)
    new_piston.instance_variable_set("@memory", @memory.clone)
    new_piston.instance_variable_set("@ma", @ma)
    new_piston.instance_variable_set("@mb", @mb)
    new_piston.instance_variable_set("@s", @s)
    new_piston.instance_variable_set("@priority", @priority)

    new_piston.instance_variable_set("@i", @i.clone)
    new_piston
  end

  # runs a single instruction and moves
  def run_one_instruction
    #Wait if paused
    if paused
      @paused_counter -= 1
      if @paused_counter <= 0
        unpause
      end
      return
    end

    #wrap the reader around if it moves off screen.
    if position_x < 0
      @position_x = parent.instructions.width - (position_x.abs % parent.instructions.width)
    else
      @position_x %= parent.instructions.width
    end

    if position_y < 0
      @position_y = parent.instructions.height - (position_y.abs % parent.instructions.height)
    else
      @position_y %= parent.instructions.height
    end

    instruction = parent.instructions.get_instruction(position_x, position_y)

    unless instruction
      fail "AT POSITION #{position_x}   #{position_y}"
    end

    instruction.run(self)

    #move unless we called recently.
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
    change_direction(DIRECTIONS[index])
  end

  # turns the piston right
  def turn_left
    index = DIRECTIONS.index(direction) - 1
    index = DIRECTIONS.length-1 if index < 0
    change_direction(DIRECTIONS[index])
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
  def call(x, y)
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
