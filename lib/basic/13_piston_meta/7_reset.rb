class PMetaReset < PistonMeta
  set_cc 0xD
  set_char ?P

  set_mc 7

  def self.reference_card
    puts %q{
        Piston Meta Reset
        Runs piston.reset

        0bCCCCMMMRRROOAAAAAAAAAAAA
        C = Control Code (Instruction)    [4 bits]
        M = Meta Command                  [3 bits]
        }
  end

  def self.run(piston, *args)
    piston.reset
  end
end