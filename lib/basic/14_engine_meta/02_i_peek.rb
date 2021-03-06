class EMetaIPeek < EMetaILength
  set_cc 0xE
  set_char ?E

  set_mc 2

  def self.reference_card
    puts %q{
        Engine Meta I Peek
        Peeks at Engine#input's last character

        0bCCCCMMMRRROOAAAAAAAAAAAA
        C = Control Code (Instruction)    [4 bits]
        M = Meta Command                  [3 bits]
        R = Register                      [3 bits]
        O = Register Options              [2 bits]
        A = Meta Command Arguments        [12 bits]
        }
  end

  def self.run(piston, *args)
    register = args[0]
    register_options = [1]

    piston.send("set_#{register}", (piston.parent.input.slice(0) || 0) % Piston::MAX_INTEGER, register_options)
  end
end