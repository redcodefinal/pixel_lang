# pixel_lang
A pixel based programming language with small numbers and threading! Based on Pixesoteric which is based off befunge.

## What is it?
pixel_lang is an esoteric language, meaning it's not meant to be a real language, it's meant to have fun and test your programming metal. There are lots of features and nuances in this language, you have to think a lot more about the overall picture than maybe with other languages.

## How does it work?
pixel\_lang reads in 24-bit bitmaps and turns each pixel into an instruction. These instructions are read and interpretted by readers called pistons(CPUs). The engine(computer) runs each piston one instruction at a time in a certain controllable order. The pistons act upon each instruction it reads. Total there are 16 commands whose names can be found in the basic directory. Since an instruction is really just a 24-bit integer we can see a couple things about it. First, the kind of instruction is denoted by the first hexadecimal digit in the color, this is called the control code or CC for short. For example, if the color was 0x100000 we would look at the first hexadecimal digit (1) and know it corresponds to the Start instruction. If the color was 0xA18828 the type of instruction would be (0xA/10) or an Arithmetic instruction. The last five hexadecimal digits correspond to the instructions arguments or color value (CV). For example in out 0x100000 example the color value would be 0x00000 and the control code would be 0x1. CV arguments are usually bitmasked and bitshifted around to get the right values. For example, the Start instruction has two arguments, a direction, and a priority. Direction is what way the piston will face when it spawns, and priority says what order compared to other pistons it will execute in. To make this command we want to have a look at the bit structure of the instruction. The structure is 0b0001\_DD\_PPPPPPPPPPPPPPPPPP, the first 0b0001 is the control code, D stands for direction and P stands for priority. To make the color we just toggle the bits we want, life if we wanted the reader to start in the up position with a priority of 0b111 we would write it like this 0b0001\_00\_000000000000000111 which would come out to 0x100007. If we wanted to change the direction to right, we would change DD to 0b01 which would then become 0x140007. Some instructions have up to 8 arguments.

## Holy shit thats complicated
Yeah, it ain't easy but it is rewarding. Luckily you aren't toally up shit creek without a paddle. There is a debugger that can help you debug your program, logs to help you, and the system will even help you make your colors! 

## Getting started
Install the dependencies in the GemFile (this included ImageMagick which needs to be installed)

Build and install the gem from source. (One day I'll release this public but right now I have so much to fix :< )

Go read the wiki (which i still need to write.)
