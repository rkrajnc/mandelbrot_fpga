// mandelbrot_simple.c
// 2020, Rok Krajnc <rok.krajnc@gmail.com>
// Mandelbrot set colored with the Escape time algorithm 


//// includes ////
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>


//// defines ////
// use grayscale palette
//#define PALETTE_GREYSCALE
// default output filename
#define FILENAME        "mandelbrot.ppm"
// default width of the output image
#define IMG_WIDTH       720U
// default height of the output image
#define IMG_HEIGHT      480U
// default maximum number of iterations
#define NITERATIONS     256U
// default Mandelbrot zoom
#define MANDELBROT_ZOOM 1.2
// default Mandelbrot cetner x coordinate
#define MANDELBROT_CX   ((1.0+(-2.5))/2.0)
// default Mandelbrot center y coordinate
#define MANDELBROT_CY   ((1.0+(-1.0))/2.0)


//// types ////
// rgb_t
// represents a RGB color value
typedef struct {
  uint8_t r;
  uint8_t g;
  uint8_t b;
} rgb_t;

typedef int64_t FP;


//// FP ////
#define MAX_MUL_WIDTH 54UL
#define FP_S 1UL
#define FP_I 4UL
#define FP_F (MAX_MUL_WIDTH-FP_S-FP_I)
#define DBL2FP(x) ((FP)((x)*(1UL<<FP_F)))
#define FP2DBL(x) (double(x)/(1UL<<FP_F))
#define FPMUL(x, y) ({__int128 v128 = (__int128)(x) * (__int128)(y); FP v64 = (FP)(v128>>FP_F); v64;})


//// usage() ////
void usage(char* progname)
{
  fprintf(stderr, "Usage: %s [-h] [-o mandelbrot.ppm] [-iw image_width] [-ih image_height] [-n niterations] [-cx x_coord] [-cy y_coord] [-z zoom]\n", progname);
  fprintf(stderr, "  -h               - show this help\n");
  fprintf(stderr, "  -iw image_width  - set output image width to image_width (default: %u)\n", IMG_WIDTH);
  fprintf(stderr, "  -ih image_height - set output image height to image_height (default: %u)\n", IMG_HEIGHT);
  fprintf(stderr, "  -n niterations   - set maximal iterations to niterations (default: %u)\n", NITERATIONS);
  fprintf(stderr, "  -cx x_coord      - set Mandelbrot center x coordinate to x_coord (default: %f)\n", MANDELBROT_CX);
  fprintf(stderr, "  -cy y_coord      - set Mandelbrot center y coordinate to y_coord (default: %f)\n", MANDELBROT_CY);
  fprintf(stderr, "  -z zoom          - set Mandelbrot zoom to zoom (default: %f)\n", MANDELBROT_ZOOM);
  exit(EXIT_FAILURE);
}


//// main() ////
int main(int argc, char*argv[])
{
  // default values
  char* filename  = FILENAME;
  uint32_t img_w  = IMG_WIDTH;
  uint32_t img_h  = IMG_HEIGHT;
  uint32_t niter  = NITERATIONS;
  double man_cx   = MANDELBROT_CX;
  double man_cy   = MANDELBROT_CY;
  double man_zoom = MANDELBROT_ZOOM;

  // parse cmd args
  int curpos = 1;
  while (curpos < argc) {
    if        (!strcmp(argv[curpos], "-h")) {
      usage(argv[0]);
    } else if (!strcmp(argv[curpos], "-o")) {\
      curpos++;
      filename = argv[curpos++];
    } else if (!strcmp(argv[curpos], "-iw")) {\
      curpos++;
      img_w = strtoul(argv[curpos++], NULL, 0);
    } else if (!strcmp(argv[curpos], "-ih")) {\
      curpos++;
      img_h = strtoul(argv[curpos++], NULL, 0);
    } else if (!strcmp(argv[curpos], "-n")) {\
      curpos++;
      niter = strtoul(argv[curpos++], NULL, 0);
    } else if (!strcmp(argv[curpos], "-cx")) {\
      curpos++;
      man_cx = strtod(argv[curpos++], NULL);
    } else if (!strcmp(argv[curpos], "-cy")) {\
      curpos++;
      man_cy = strtod(argv[curpos++], NULL);
    } else if (!strcmp(argv[curpos], "-z")) {\
      curpos++;
      man_zoom = strtod(argv[curpos++], NULL);
    } else {
      usage(argv[0]);
    }
  }

  // create a palette of colors
  rgb_t* palette = NULL;
  if ((palette = (rgb_t*)malloc(niter * sizeof(rgb_t))) == NULL) {
    fprintf(stderr, "Can't allocate palette array, exiting.\n");
    exit(EXIT_FAILURE);
  }
  #pragma omp parallel for
  for (int i=0; i<niter; i++) {
    #ifdef PALETTE_GREYSCALE
    palette[i].r = 255 - (double)i/NITERATIONS * 255.0;
    palette[i].g = 255 - (double)i/NITERATIONS * 255.0;
    palette[i].b = 255 - (double)i/NITERATIONS * 255.0;
    #else
    double t = (double)i/NITERATIONS;
    palette[i].r = (9.0*(1-t)*t*t*t*255.0);
    palette[i].g = (15.0*(1-t)*(1-t)*t*t*255.0);
    palette[i].b = (8.5*(1-t)*(1-t)*(1-t)*t*255.0);
    #endif
  }

  // dump clut
  FILE* clut_fp = NULL;
  if ((clut_fp  = fopen("clut.hex", "wb")) == NULL) {
    fprintf(stderr, "Can't open output file " "clut.hex" ", exiting.\n");
    exit(EXIT_FAILURE);
  }
  for (int i=0; i<NITERATIONS; i++) {
    fprintf(clut_fp, "%02x%02x%02x\n", palette[i].r, palette[i].g, palette[i].b);
  }
  fclose(clut_fp);

  //// Mandelbrot with FP ////
  // calculate Mandelbrot coordinates (TODO)
  double man_x0 = man_cx - (double)img_w/(double)img_h*man_zoom;
  double man_x1 = man_cx + (double)img_w/(double)img_h*man_zoom;
  double man_y0 = man_cy - 1.0*man_zoom;
  double man_y1 = man_cy + 1.0*man_zoom;
  FP man_cx_fp = DBL2FP(man_cx);
  FP man_x0_fp = DBL2FP(man_x0);
  FP man_x1_fp = DBL2FP(man_x1);
  FP man_cy_fp = DBL2FP(man_cy);
  FP man_y0_fp = DBL2FP(man_y0);
  FP man_y1_fp = DBL2FP(man_y1);

  // create image array
  uint32_t* iterations = NULL;
  if ((iterations = (uint32_t*)malloc(img_w*img_h * sizeof(uint32_t))) == NULL) {
    fprintf(stderr, "Can't allocate iterations array, exiting.\n");
    exit(EXIT_FAILURE);
  }

  // calculate the Mandelbrot set
  // iterate over all image rows
  #pragma omp parallel for ordered schedule(dynamic)
  for (uint32_t img_y=0; img_y<img_h; img_y++) {
    // convert y image coordinate to Mandelbrot coordinate
    double man_y = (double)(img_y)/(double)img_h*(man_y1-man_y0) + man_y0;
    FP man_y_fp = DBL2FP(man_y); // TODO
    // iterate over all image columns
    for (uint32_t img_x=0; img_x<img_w; img_x++) {
      // convert x image coordinate to Mandelbrot coordinate
      double man_x = (double)(img_x)/(double)img_w*(man_x1-man_x0) + man_x0;
      FP man_x_fp = DBL2FP(man_x); // TODO
      // initialize Zn to 0 + i0
      FP zn_x_fp = 0L;
      FP zn_y_fp = 0L;
      // initialize niterations to 0
      uint32_t niterations = 0;
      // initialize temporary variables
      FP x2_fp = 0L;
      FP y2_fp = 0L;
      while (x2_fp + y2_fp <= DBL2FP(4.0) && niterations < niter-1) {
        zn_y_fp = FPMUL(zn_x_fp, zn_y_fp);
        zn_y_fp <<= 1;
        zn_y_fp += man_y_fp;
        zn_x_fp = x2_fp - y2_fp + man_x_fp;
        x2_fp = FPMUL(zn_x_fp, zn_x_fp);
        y2_fp = FPMUL(zn_y_fp, zn_y_fp);
        niterations++;
      }
      // save number of iterations to iterations array
      iterations[img_y*img_w+img_x] = niterations;
    }
  }

  // open output image file
  FILE* fp = NULL;
  if ((fp  = fopen(filename, "wb")) == NULL) {
    fprintf(stderr, "Can't open output file " FILENAME ", exiting.\n");
    exit(EXIT_FAILURE);
  }

  // write ppm image header
  fprintf(fp, "P3\n%d %d\n255\n", img_w, img_h);

  // convert number of iterations to a rgb value and write it to the output image file & collect statistics
  uint32_t min_iterations = UINT32_MAX;
  uint32_t max_iterations = 0;
  uint64_t sum_iterations = 0;
  for (uint32_t i=0; i<img_w*img_h; i++) {
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
  printf("Mandelbrot set calculated with %d points & %d max iterations.\n", img_w*img_h, niter);
  printf("X coords: % 2.8e  -  % 2.8e  -  % 2.8e\n", man_x0, man_cx, man_x1);
  printf("Y coords: % 2.8e  -  % 2.8e  -  % 2.8e\n", man_y0, man_cy, man_y1);
  printf("Zoom:     % 2.8e\n", man_zoom);
  printf("minimal iterations: %u\n", min_iterations);
  printf("maximal iterations: %u\n", max_iterations);
  printf("all iterations:     %lu\n", sum_iterations);
  printf("average iter/pixel: %f\n", (double)sum_iterations/(double)(img_w*img_h));

  // exit
  exit(EXIT_SUCCESS);
}

