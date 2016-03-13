require_relative './color'
# Holds all the instructions and performs pattern checking on them.
# Instruction class subscribes itself to Instructions upon instancing.
# This is done at class level.
# Instances of Instructions are a set of instructions to run.
# Engine relies on this to run and match instructions.
class Instructions
  class << self
    # list of instructions that exist within the machine
    # uses this list to test if a read pattern in an instruction
    attr_reader :instructions

    def add_instruction(instruction)
      @instructions ||= []
      @instructions << instruction
    end

    # tests a pattern against all instructions until it finds a match
    def get_instruction(color)
      instructions.each do |i|
        # check the pattern to the instructions pattern
        if i.match(color)
          return i
        end
      end
      # the pattern was not recognized so we throw an error.
      fail
    end

    # clears the instructions array
    def clear
      @instructions = []
    end

    # find and run an instruction on a thread.
    def run_instruction(piston, color)
      instruction = get_instruction(color)
      instruction.run(piston)
    end
  end

  # internal 2d array of read instructions
  attr_reader :array
  # list of the thread entry points
  attr_reader :start_points


  def initialize(image_file)
    image = ImageList.new(File.absolute_path(image_file))

    # create array
    @array = Array.new(image.columns, Array.new(image.rows, 0))

    # fill patterns
    image.columns.times do |x|
      image.rows.times do |y|

        c = image.pixel_color(x,y)
        color = Color.new
        color.r = c.red / 0x100
        color.g = c.green / 0x100
        color.b = c.blue / 0x100
        @array[x][y] = Instructions.get_instruction(color).new color
      end
    end

    # find start points and list them so the machine can start program
    @start_points = []
    point_struct = Struct.new(:p, :x, :y)
    @array.each_with_index do |x_a, x|
      x_a.each_with_index do |int, y|
        if int.class.to_s.to_sym == :Start
          @start_points << point_struct.new(int, x, y)
        end
      end
    end

    # sort the array by priority
    @start_points.sort! { |l, r| l.p.cv <=> r.p.cv }
  end

  # grab an instruction at the location x, y
  def get_instruction(x, y)
    @array[x][y]
  end
end