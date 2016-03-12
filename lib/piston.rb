require_relative './memory'

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

  #registers
  attr_accessor :ma, :mb, :sa


  # clockwise list of instructions
  DIRECTIONS = [:up, :right, :down, :left]

  def initialize(parent, position_x, position_y, direction)
    @parent = parent
    @position_x = position_x
    @position_y = position_y
    @direction = direction

    @paused = false
    @paused_counter = 0
    @ended = false
    @id = parent.make_id

    @ma = Color::BLACK
    @mb = Color::BLACK
    @sa = Color::BLACK

    reset
  end

  def mav
    memory[ma]
  end

  def mbv
    memory[mb]
  end

  def sv
    parent.memory[sa]
  end

  # resets memory
  def reset
    @memory = {}
    memory.default = Color::BLACK
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
    parent.log.info "T#{id} C:#{parent.cycles} Running #{instruction.class} @ #{position_x}, #{position_y} CV: #{instruction.color_value.to_s 16}"
    instruction.run(self, instruction.color_value)
    parent.log.debug '^  Piston state:'
    parent.log.debug "^     d:#{direction}"
    parent.log.debug '^  Machine state:'
    parent.log.debug "^     static: #{parent.memory}"
    parent.log.debug "^     output: #{parent.output}"
    parent.log.debug "^     input: #{parent.input}"

    #move unless we called here recently.
    move 1 unless instruction.class == Call
  end

  # change the direction
  def change_direction(index)
    @direction = DIRECTIONS[index%4]
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