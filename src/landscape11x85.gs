# Gist work.gs drawing style
# $Id$ 

# Derived by W. Wright from work.gs 


# A single coordinate system on a portrait page
# Legends: two columns below viewport, contours in single column to right

#   Xwindow dims Width: 1108 Height: 844

# See the header file gist.h for a more complete description of the
# meanings of the various keywords set in this file; they coincide with the
# values of the corresponding C data structure members defined in gist.h.
# Here is a brief description:

# Units and coordinate systems:
#   viewport, tickOff, labelOff, tickLen, xOver, yOver, height (of text)
#   legends.(x,y,dx,dy)
#     Coordinates are in Gist's "NDC" coordinate system.  In this system,
#     0.0013 unit is 1.000 point, and there are 72.27 points per inch.
#     The lower left hand corner of the sheet of paper is at (0,0).
#     For landscape=0, the 8.5 inch edge of the paper is horizontal;
#     for landscape=1, the 11 inch edge of the paper is horizontal.
#   width
#     Line width is measured in relative units, with 1.0 being 1/2 point.

# Ticks flags (add together the ones you want):
#   0x001  Draw ticks on bottom or left edge of viewport
#   0x002  Draw ticks on top or right edge of viewport
#   0x004  Draw ticks centered on origin in middle of viewport
#   0x008  Ticks project inward into viewport
#   0x010  Ticks project outward away from viewport (0x18 for both)
#   0x020  Draw tick label numbers on bottom or left edge of viewport
#   0x040  Draw tick label numbers on top or right edge of viewport
#   0x080  Draw all grid lines down to gridLevel
#   0x100  Draw single grid line at origin

# Line types:
#   solid        1
#   dash         2
#   dot          3
#   dash-dot     4
#   dash-dot-dot 5

# Font numbers:
#   Courier    0x00
#   Times      0x04
#   Helvetica  0x08
#   Symbol     0x0c
#   Schoolbook 0x10
# Add 0x01 for bold, 0x02 for italic

# This actually repeats the default values in gread.c

landscape= 1

default = {
  legend= 0,

# to convert inches to the numbers you need here, 
# multiply inches by 0.093951
#inches	       .5 	10.5	  .5	   8.0
  viewport= { 0.07897, 0.986485, 0.07697, 0.731608 },

  ticks= {

    horiz= {
      nMajor= 7.5,  nMinor= 50.0,  logAdjMajor= 1.2,  logAdjMinor= 1.2,
      nDigits= 6,  gridLevel= 1,  flags= 0x033,
      tickOff= 0.0007,  labelOff= 0.0182,
      tickLen= { 0.01, 0.0005, 0.0052, 0.0026, 0.0013 },
      tickStyle= { color= -2,  type= 1,  width= 1.0 },
      gridStyle= { color= -2,  type= 3,  width= 1.0 },
      textStyle= { color= -2,  font= 0x08,  height= 0.015,
        orient= 0,  alignH= 0,  alignV= 0,  opaque= 0 },
      xOver= 0.395,  yOver= 0.03 },

    vert= {
      nMajor= 7.5,  nMinor= 50.0,  logAdjMajor= 1.2,  logAdjMinor= 1.2,
      nDigits= 7,  gridLevel= 1,  flags= 0x033,
      tickOff= 0.0007,  labelOff= 0.0182,
      tickLen= { 0.0123, 0.0091, 0.0052, 0.0026, 0.0013 },
      tickStyle= { color= -2,  type= 1,  width= 1.0 },
      gridStyle= { color= -2,  type= 3,  width= 1.0 },
      textStyle= { color= -2,  font= 0x08,  height= 0.015,
        orient= 0,  alignH= 0,  alignV= 0,  opaque= 0 },
      xOver= 0.001,  yOver= 0.03 },

    frame= 0,
    frameStyle= { color= -2,  type= 1,  width= 1.0 }}}

# The one coordinate system matches the default template exactly
system= { legend= "System 0" }

legends= {
  x= 0.04698,  y= 0.360,  dx= 0.3758,  dy= 0.0,
  textStyle= { color= -2,  font= 0x00,  height= 0.0156,
    orient= 0,  alignH= 1,  alignV= 1,  opaque= 0 },
  nchars= 36,  nlines= 20,  nwrap= 2 }

clegends= {
  x= 0.6182,  y= 0.8643,  dx= 0.0,  dy= 0.0,
  textStyle= { color= -2,  font= 0x00,  height= 0.0156,
    orient= 0,  alignH= 1,  alignV= 1,  opaque= 0 },
  nchars= 14,  nlines= 28,  nwrap= 1 }
