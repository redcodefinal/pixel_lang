require_relative './engine'

require 'tty'

class Debugger
  attr_reader :engine

  def initialize(program_file, input = '')
    @engine = Engine.new program_file, input
  end

  #go to next cycle
  def next
    engine.run_one_instruction
  end

  # go to the previous cycle
  def previous

  end

  def restart
    engine.reset
  end

  def show_info
    puts "Engine Info"
    puts "Cycles: #{engine.cycles}"
    puts "Input: #{engine.input}"
    puts "Output:#{engine.output}"
  end

  # show a map of instructions
  # TODO: Add coloring options
  def show_instructions(**options)
    default_options = {
      colorized: :none,
    }

    default_options.merge! options

    if default_options[:colorized] == :none
      engine.instructions.height.times do |y|
        engine.instructions.width.times do |x|
          print engine.instructions[x][y].class.char
        end
        print "\n"
      end
    elsif default_options[:colorized] == :std
      pastel = Pastel.new
      engine.instructions.height.times do |y|
        engine.instructions.width.times do |x|
          if engine.pistons.any? {|p| p.position_x == x and p.position_y == y}
            print pastel.red(engine.instructions[x][y].class.char)
          else
            print engine.instructions[x][y].class.char
          end
        end
        print "\n"
      end
    end

    nil
  end

  # shows the legend for show_instructions
  def show_legend(**options)
    int = Instructions.instructions.sort { |a, b| a.cc <=> b.cc}
    int.map! do |i|
      [i.cc, i.to_s]
    end
    table = TTY::Table.new header: ['cc', 'name'], rows: int
    puts table.render(:ascii)

    nil
  end

  def show_instruction(x, y, **options)
    int_methods = Instruction.new(Color.new(0)).methods
    int = get_instruction(x, y)

    int_methods = int.methods - int_methods

    int_methods.map! { |i| [i, int.send(i)]}

    table_data = []
    table_data << ["cv", int.cv.to_s(16)]
    table_data << ["cV", int.cv]
    table_data += int_methods


    puts int.class.to_s
    table = TTY::Table.new header: ['args', 'value'], rows: table_data
    puts table.render(:ascii)

    nil
  end

  def show_pistons(**options)
    registers_data = []

    engine.pistons.each do |piston|
      registers_data << ["id", piston.id]
      registers_data << ["x", piston.position_x]
      registers_data << ["y", piston.position_y]
      registers_data << ['-', '-']


      Piston::REGULAR_REG.each do |register|
        registers_data << [register, piston.send(register)]
      end

      Piston::SPECIAL_REG.each do |register|
        registers_data << [register, piston.instance_variable_get(?@ + register.to_s)]
      end

      table = TTY::Table.new header: ['register', 'value'], rows: registers_data
      puts table.render(:ascii)
    end

    nil
  end

  def show_changes

  end

  # gets an instruction from the engine and displays information about it
  # use custom fields in instructions to display info on it.
  def get_instruction(x, y)
    engine.instructions[x][y]
  end

  def get_piston(id)
    engine.pistons.find { |p| p.id == id}
  end

  # peeks at a threads register
  # TODO: Think about special case i! @i.is_a? Array == true
  def peek_piston_register(piston_id, register)
    piston = get_piston piston_id

    if Piston::REGULAR_REG.include? register
      piston.send register
    elsif Piston::SPECIAL_REG.include? register
      piston.instance_variable_get(?@ + register.to_s)
    end
  end

  #peeks at a threads memory address
  # TODO: Support ranges
  def peek_memory(piston_id, address)
    piston = get_piston piston_id

    piston.memory[address]
  end

  #peeks at a static memory address
  # TODO: Support ranges
  def peek_static_memory(address)
    engine.memory[address]
  end
end