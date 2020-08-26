// mandelbrot_simple.c
// 2020, Rok Krajnc <rok.krajnc@gmail.com>
// Mandelbrot set colored with the Escape time algorithm, 


//// includes ////
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>


//// defines ////
// use grayscale palette
//#define PALETTE_GREYSCALE
// output filename
#define FILENAME      "mandelbrot.ppm"
// width of the output image
#define WIDTH         1920
// height of the output image
#define HEIGHT        1200
// left coordinate of the Mandelbrot set
#define MANDELBROT_X0 -2.5
// right coordinate of the Mandelbrot set
#define MANDELBROT_X1 1.0
// top coordinate of the Mandelbrot set
#define MANDELBROT_Y0 1.0
// bottom coordinate of the Mandelbrot set
#define MANDELBROT_Y1 -1.0
// maximum number of iterations
#define NITERATIONS   256


//// macros ////
#define IMG_TO_MAN_X(coord) ({double _t = (double)coord/(double)WIDTH*(MANDELBROT_X1-MANDELBROT_X0) + MANDELBROT_X0; _t;})
#define IMG_TO_MAN_Y(coord) ({double _t = (double)coord/(double)HEIGHT*(MANDELBROT_Y1-MANDELBROT_Y0) + MANDELBROT_Y0; _t;})
#define MAN_TO_IMG_X(coord) ({int32_t _t = ((double)coord-MANDELBROT_X0)/(MANDELBROT_X1-MANDELBROT_X0); _t;})
#define MAN_TO_IMG_Y(coord) ({int32_t _t = ((double)coord-MANDELBROT_Y0)/(MANDELBROT_Y1-MANDELBROT_Y0); _t;})


//// types ////
// rgb_t
// represents a RGB color value
typedef struct {
  uint8_t r;
  uint8_t g;
  uint8_t b;
} rgb_t;


//// main() ////
int main()
{
  // create a palette of colors
  rgb_t palette[NITERATIONS];
  #ifdef PALETTE_GREYSCALE
  for (int i=0; i<NITERATIONS; i++) {
    palette[i].r = 255 - (double)i/NITERATIONS * 255.0;
    palette[i].g = 255 - (double)i/NITERATIONS * 255.0;
    palette[i].b = 255 - (double)i/NITERATIONS * 255.0;
  }
  #else
  for (int i=0; i<NITERATIONS; i++) {
    double t = (double)i/NITERATIONS;
    palette[i].r = (9.0*(1-t)*t*t*t*255.0);
    palette[i].g = (15.0*(1-t)*(1-t)*t*t*255.0);
    palette[i].b = (8.5*(1-t)*(1-t)*(1-t)*t*255.0);
  }
  #endif

  // open output image file
  FILE* fp = NULL;
  if ((fp  = fopen(FILENAME, "wb")) == NULL) {
    fprintf(stderr, "Can't open output file " FILENAME ", exiting.\n");
    exit(EXIT_FAILURE);
  }

  // write ppm image header
  fprintf(fp, "P3\n%d %d\n255\n", WIDTH, HEIGHT);

  // calculate and color the Mandelbrot set
  // iterate over all image rows
  for (uint32_t img_y=0; img_y<HEIGHT; img_y++) {
    // iterate over all image columns
    for (uint32_t img_x=0; img_x<WIDTH; img_x++) {
      // convert image coordinates to Mandelbrot coordinates
      double man_x = IMG_TO_MAN_X(img_x);
      double man_y = IMG_TO_MAN_Y(img_y);
      // initialize Zn to 0 + i0
      double zn_x = 0.0;
      double zn_y = 0.0;
      // initialize niterations to 0
      uint32_t niterations = 0;
      while (zn_x*zn_x + zn_y*zn_y <= 2*2 && niterations < NITERATIONS-1) {
        double xtemp = zn_x*zn_x - zn_y*zn_y + man_x;
        zn_y = 2*zn_x*zn_y + man_y;
        zn_x = xtemp;
        niterations++;
      }
      // write color to output image
      fprintf(fp, "%d %d %d\n", palette[niterations].r, palette[niterations].g, palette[niterations].b);
    }
  }

  // close output file
  fclose(fp);

  exit(EXIT_SUCCESS);
}

