class PMetaISetPriority < PMetaICount
  set_cc 0xD
  set_char ?P

  set_mc 3


  def self.reference_card
    puts %q{
        Piston Meta Set Priority
        Sets this pistons priority from a register

        0bCCCCMMMRRROOAAAAAAAAAAAA
        C = Control Code (Instruction)    [4 bits]
        M = Meta Command                  [3 bits]
        R = Register                      [3 bits]
        O = Register Options              [2 bits]
        A = Meta Command Arguments        [17 bits]
        }
  end

  def self.run(piston, *args)
    register = args[0]
    register_options = [1]

    piston.priority = piston.send(register, register_options)

    piston.parent.priority_changed(piston)
    #TODO: Test this to ensure it inserts pistons correctly.
  end
end