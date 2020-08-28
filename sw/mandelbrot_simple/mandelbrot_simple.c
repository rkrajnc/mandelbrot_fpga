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
#define IMG_WIDTH     720
// height of the output image
#define IMG_HEIGHT    480
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
#define IMG_TO_MAN_X(coord) ({double _t = (double)coord/(double)IMG_WIDTH*(MANDELBROT_X1-MANDELBROT_X0) + MANDELBROT_X0; _t;})
#define IMG_TO_MAN_Y(coord) ({double _t = (double)coord/(double)IMG_HEIGHT*(MANDELBROT_Y1-MANDELBROT_Y0) + MANDELBROT_Y0; _t;})


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
  #pragma omp parallel for
  for (int i=0; i<NITERATIONS; i++) {
    palette[i].r = 255 - (double)i/NITERATIONS * 255.0;
    palette[i].g = 255 - (double)i/NITERATIONS * 255.0;
    palette[i].b = 255 - (double)i/NITERATIONS * 255.0;
  }
  #else
  #pragma omp parallel for
  for (int i=0; i<NITERATIONS; i++) {
    double t = (double)i/NITERATIONS;
    palette[i].r = (9.0*(1-t)*t*t*t*255.0);
    palette[i].g = (15.0*(1-t)*(1-t)*t*t*255.0);
    palette[i].b = (8.5*(1-t)*(1-t)*(1-t)*t*255.0);
  }
  #endif

  // create image array
  uint32_t* iterations = NULL;
  if ((iterations = (uint32_t*)malloc(IMG_WIDTH*IMG_HEIGHT * sizeof(uint32_t))) == NULL) {
    fprintf(stderr, "Can't allocate iterations array, exiting.\n");
    exit(EXIT_FAILURE);
  }

  // calculate the Mandelbrot set
  // iterate over all image rows
  #pragma omp parallel for ordered schedule(dynamic)
  for (uint32_t img_y=0; img_y<IMG_HEIGHT; img_y++) {
    double man_y = IMG_TO_MAN_Y(img_y);
    // iterate over all image columns
    for (uint32_t img_x=0; img_x<IMG_WIDTH; img_x++) {
      // convert image coordinates to Mandelbrot coordinates
      double man_x = IMG_TO_MAN_X(img_x);
      // initialize Zn to 0 + i0
      double zn_x = 0.0;
      double zn_y = 0.0;
      // initialize niterations to 0
      uint32_t niterations = 0;
      // initialize temporary variables
      double x2 = 0.0;
      double y2 = 0.0;
      while (x2 + y2 <= 4.0 && niterations < NITERATIONS-1) {
        zn_y = 2*zn_x*zn_y + man_y;
        zn_x = x2 - y2 + man_x;
        x2   = zn_x*zn_x;
        y2   = zn_y*zn_y;
        /*double xtemp = zn_x*zn_x - zn_y*zn_y + man_x;
        zn_y = 2*zn_x*zn_y + man_y;
        zn_x = xtemp;*/
        niterations++;
      }
      // save number of iterations to iterations array
      iterations[img_y*IMG_WIDTH+img_x] = niterations;
    }
  }

  // open output image file
  FILE* fp = NULL;
  if ((fp  = fopen(FILENAME, "wb")) == NULL) {
    fprintf(stderr, "Can't open output file " FILENAME ", exiting.\n");
    exit(EXIT_FAILURE);
  }

  // write ppm image header
  fprintf(fp, "P3\n%d %d\n255\n", IMG_WIDTH, IMG_HEIGHT);

  // convert number of iterations to a rgb value and write it to the output image file & collect statistics
  uint32_t min_iterations = UINT32_MAX;
  uint32_t max_iterations = 0;
  uint64_t sum_iterations = 0;
  for (uint32_t i=0; i<IMG_WIDTH*IMG_HEIGHT; i++) {
    uint32_t niterations = iterations[i];
    fprintf(fp, "%d %d %d\n", palette[niterations].r, palette[niterations].g, palette[niterations].b);
    min_iterations = niterations < min_iterations ? niterations : min_iterations;
    max_iterations = niterations > max_iterations ? niterations : max_iterations;
    sum_iterations += niterations;
  }   

  // close output file
  fclose(fp);

  // deallocate array
  free(iterations);

  // output stats
  printf("Mandelbrot set calculated for %d points with %d max iterations.\n", IMG_WIDTH*IMG_HEIGHT, NITERATIONS);
  printf("minimal iterations: %u\n", min_iterations);
  printf("maximal iterations: %u\n", max_iterations);
  printf("all iterations:     %lu\n", sum_iterations);
  printf("average iter/pixel: %f\n", (double)sum_iterations/(double)(IMG_WIDTH*IMG_HEIGHT));

  // exit
  exit(EXIT_SUCCESS);
}

