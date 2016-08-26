class MetaSave < Meta
  SCALES = [1, 2, 4, 8]
  ROTATIONS = [0, 90, 180, 270]

  set_cc 0xC
  set_char ?*

  set_mc 2

  def self.make_color(scale, bw, r, g, b, rotation)
    scale = SCALES.index scale
    rotation = ROTATIONS.index rotation
    bw = (bw ? LOGICAL_TRUE : LOGICAL_FALSE)
    r = (r ? LOGICAL_TRUE : LOGICAL_FALSE)
    g = (g ? LOGICAL_TRUE : LOGICAL_FALSE)
    b = (b ? LOGICAL_TRUE : LOGICAL_FALSE)
  end

  def self.reference_card
    puts %q{
    Meta Instruction
    Provides an interface for metaprogramming.

    0bCCCCMMAAAAAAAAAAAAAAAAAA
    C = Control Code (Instruction)    [4 bits]
    M = Meta Command                  [2 bits]
    A = Meta Command Arguments        [18 bits]

      --Save
      Saves the current instructions to an image
      with the file name piston_id-cycle.bmp

      0bSSWRGBABXXX11YYY11
      S = Scale
          - Scales the output image by (1x, 2x, 4x, 8x)
      W = Black and White
          - if a pixel is 0xFFFFFF display as white
            if a pixel is not 0xFFFFFF display as black
            This setting disables RGB
      R = Red
          - Allow Red channel
      B = Blue
          - Allow Blue channel
      G = Green
          - Allow Green channel
      A = Rotation
          - Rotates the image (0, 90, 180, 270)
      B = Range
      X = Range Start Register
      1 = Range Start Register Options
      Y = Range End Register
      2 = Range End Options
    }
  end

  #TODO: Finish MetaSave
end