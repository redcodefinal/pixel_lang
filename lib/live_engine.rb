require 'io/console'
require 'io/wait'

require_relative './engine'

class LiveEngine < Engine
  def write_output(item)
    Kernel.print item
    super
  end

  def grab_input_number
    int = nil

    if input.length.zero?
      until int and int.to_s =~ /^[0-9]+$/
        int = gets("#{int.nil? ? '' : ?!}#:").chomp
      end
    else
      super
    end
    int.to_i % Piston::MAX_INTEGER
  end

  def grab_input_char
    if input.length.zero?
      int = gets("$:").chomp
      @input << int
    end
    super
  end

  def gets(prompt)
    print prompt
    chars = ""

    until ["\r", "\n", "\r\n", "\u0003"].any?{|c| chars.include?(c)}
      char = nil
      while char.nil?
        char = STDIN.getch
        if char == "\u007F"
          char = nil
          print "\r"
          (chars.length+prompt.length+1).times do
            print " "
          end
          chars.slice!(chars.length-1)
          print "\r#{prompt}#{chars}"
        end
      end
      chars << char
      STDOUT.print char
    end
    chars
  end
end