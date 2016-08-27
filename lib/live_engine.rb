require './engine'

class LiveEngine < Engine
  def write_output(item)
    Kernel.puts item
    super
  end

  def grab_input_number
    int = nil

    if input.length.zero?
      until int and int.to_s =~ /^[0-9]+$/
        print "#{int.nil? ? '' : ?!}N:"
        int = Kernel.gets.chomp
      end
    else
      super
    end
    int.to_i % Piston::MAX_INTEGER
  end

  def grab_input_char
    if input.length.zero?
      print "S:"
      int = Kernel.gets.chomp
      @input << int
    end
    super
  end
end