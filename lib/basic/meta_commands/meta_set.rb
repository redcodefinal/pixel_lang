class MetaSet < MetaGet
  set_mc 1

  def self.reference_card
    puts %q{
    Meta Instruction
    Provides an interface for metaprogramming.

    0bCCCCMMAAAAAAAAAAAAAAAAAA
    C = Control Code (Instruction)    [4 bits]
    M = Meta Command                  [2 bits]
    A = Meta Command Arguments        [18 bits]

       --Set
       Sets the instruction at Coord Register to
       Control Code Register and Color Value Register.

       0bOOOWWW11XXX22YYY33
       O = Coord Options                 [3 bits]
       W = Control Code Register         [3 bits]
           - Register to grab CC
       1 = Control Code Register Options [2 bits]
       X = Color Value Register          [3 bits]
           - Register to grab CV
       2 = Color Value Register Options  [2 bits]
       Y = Coord Register                [3 bits]
           - Register containing the coords of the instruction
       3 = Coord Register Options        [2 bits]
    }
  end

  def self.run(piston)
    coord_options = args[0]
    control_code_register = args[1]
    control_code_register_options = args[2]
    color_value_register = args[3]
    color_value_register_options = args[4]
    coord_register = args[5]
    coord_register_options = args[6]

    meta_x, meta_y = *get_coords(coord_options, piston.send(coord_register, coord_register_options))

    meta_control_code = (piston.send(control_code_register, control_code_register_options) % Instructions.count) << CONTROL_CODE_BITSHIFT
    meta_color_value = piston.send(color_value_register, color_value_register_options)
    meta_color = meta_control_code + meta_color_value
    piston.parent.set_instruction(meta_color, meta_x, meta_y)
  end
end