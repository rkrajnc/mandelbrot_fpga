# mandelbrot_fpga
*A Mandelbrot set explorer implemented on an FPGA*

**... in development ...**


## Description
A Mandelbrot set engine running on a Terasic DE10-nano (MiSTer) FPGA board. Currently, only a CPU controlled slideshow in 800x600 resolution is implemented, but most of the parts are already there.

Read more about it here: https://somuch.guru/category/mandelbrot/

### TODOs
Create a proper MiSTer core with ability to be controlled (moved around, zoomed, etc) with the keyboard / joypad ...


## Features
* 256 iterations / pixel
* 54bit fixed-point precision
* 1.8G multiplications / sec
* text overlay
* OR1200 control CPU
* adjustable output resolution
* 32bit color output (VGA / HDMI)


## Latest version
[v0.6 release](https://github.com/rkrajnc/mandelbrot_fpga/releases/tag/v0.6 "v0.6 release")

A video of the core running can be seen on [Youtube](https://youtu.be/2KtTfBC60v0 "Youtube").

## Versions

### [v0.6](https://github.com/rkrajnc/mandelbrot_fpga/tree/v0.6 "v0.6")
more runtime configurability; calculation engine extended from 1 to 8 parallel modules; CPU firmware for a slideshow of interesting points around the Mandelbrot set

[Release files](https://github.com/rkrajnc/mandelbrot_fpga/releases/tag/v0.6 "Release files")

### [v0.5](https://github.com/rkrajnc/mandelbrot_fpga/tree/v0.5 "v0.5")
mandelbrot engine moved to separate (faster) clock; added control cpu; cpu can do basic slideshow

[Release files](https://github.com/rkrajnc/mandelbrot_fpga/releases/tag/v0.5 "Release files")

### [v0.4](https://github.com/rkrajnc/mandelbrot_fpga/tree/v0.4 "v0.4")
Mandelbrot engine working; single image generated on video output

### [v0.3](https://github.com/rkrajnc/mandelbrot_fpga/tree/v0.3 "v0.3")
basic FPGA scaffolding; video pipe working

### [v0.2](https://github.com/rkrajnc/mandelbrot_fpga/tree/v0.2 "v0.2")
added some interesting Mandelbrot set points

### [v0.1](https://github.com/rkrajnc/mandelbrot_fpga/tree/v0.1 "v0.1")
algorithm implementation with double type in C

