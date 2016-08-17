class MetaSave < Meta
  set_mc 2

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

      0bSSWRGBA00000000
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
      0 = Free bits       [15 bits]
    }
  end
end