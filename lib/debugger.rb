require_relative './engine'

class Debugger
  attr_reader :engine

  def initialize(program_file, input = '')
    @engine = Engine.new program_file, input
  end

  #go to next cycle
  def next

  end

  # go to the previous cycle
  def previous

  end

  # show a map of instructions
  # TODO: Add coloring options
  def show_instructions(**options)

  end

  # shows the legend for show_instructions
  def show_legend(**options)

  end

  # gets an instruction from the engine and displays information about it
  # use custom fields in instructions to display info on it.
  def get_instruction(x, y)

  end

  # peeks at a threads register
  # TODO: Think about special case i! @i.is_a? Array == true
  def peek_thread_register(thread_id, register)

  end

  #peeks at a threads memory address
  # TODO: Support ranges
  def peek_memory(thread_id, address)

  end

  #peeks at a static memory address
  # TODO: Support ranges
  def peek_static_memory(address)

  end

  #List active threads and quick register and memory info.
  #TODO: Limit thread memory
  def threads

  end
end