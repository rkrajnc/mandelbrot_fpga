// mandelbrot_calc_params.c
// 2021, Rok Krajnc <rok.krajnc@gmail.com>
// Calculates upper left corner coordinates and step sizes for requested position / zoom


//// includes ////
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>


//// defines ////
// default output filename
#define FILENAME        "mandelbrot_coords_params.vi"
// default width of the output image
#define IMG_WIDTH       800U
// default height of the output image
#define IMG_HEIGHT      600U
// default Mandelbrot zoom
#define MANDELBROT_ZOOM 1.0
// default Mandelbrot cetner x coordinate
#define MANDELBROT_CX   ((1.0+(-2.5))/2.0)
// default Mandelbrot center y coordinate
#define MANDELBROT_CY   ((1.0+(-1.0))/2.0)


//// types ////
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
  fprintf(stderr, "Usage: %s [-h] [-o filename] [-iw image_width] [-ih image_height] [-cx x_coord] [-cy y_coord] [-z zoom]\n", progname);
  fprintf(stderr, "  -h               - show this help\n");
  fprintf(stderr, "  -o filename      - output to file instead of stdout\n");
  fprintf(stderr, "  -iw image_width  - set output image width to image_width (default: %u)\n", IMG_WIDTH);
  fprintf(stderr, "  -ih image_height - set output image height to image_height (default: %u)\n", IMG_HEIGHT);
  fprintf(stderr, "  -cx x_coord      - set Mandelbrot center x coordinate to x_coord (default: %f)\n", MANDELBROT_CX);
  fprintf(stderr, "  -cy y_coord      - set Mandelbrot center y coordinate to y_coord (default: %f)\n", MANDELBROT_CY);
  fprintf(stderr, "  -z zoom          - set Mandelbrot zoom to zoom (default: %f)\n", MANDELBROT_ZOOM);
  exit(EXIT_FAILURE);
}


//// main() ////
int main(int argc, char*argv[])
{
  // default values
  uint8_t to_file = 0;
  char* filename  = FILENAME;
  uint32_t img_w  = IMG_WIDTH;
  uint32_t img_h  = IMG_HEIGHT;
  double man_cx   = MANDELBROT_CX;
  double man_cy   = MANDELBROT_CY;
  double man_zoom = MANDELBROT_ZOOM;

  // parse cmd args
  int curpos = 1;
  while (curpos < argc) {
    if        (!strcmp(argv[curpos], "-h")) {
      usage(argv[0]);
    } else if (!strcmp(argv[curpos], "-o")) {\
      to_file = 1;
      curpos++;
      filename = argv[curpos++];
    } else if (!strcmp(argv[curpos], "-iw")) {\
      curpos++;
      img_w = strtoul(argv[curpos++], NULL, 0);
    } else if (!strcmp(argv[curpos], "-ih")) {\
      curpos++;
      img_h = strtoul(argv[curpos++], NULL, 0);
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

  // calculate Mandelbrot coordinates (TODO)
  double man_x0 = man_cx - (double)img_w/(double)img_h*man_zoom;
  double man_x1 = man_cx + (double)img_w/(double)img_h*man_zoom;
  double man_y0 = man_cy - 1.0*man_zoom;
  double man_y1 = man_cy + 1.0*man_zoom;
  double man_xs = (man_x1 - man_x0) / img_w;
  double man_ys = (man_y1 - man_y0) / img_h;
  FP man_x0_fp = DBL2FP(man_x0);
  FP man_y0_fp = DBL2FP(man_y0);
  FP man_xs_fp = DBL2FP(man_xs);
  FP man_ys_fp = DBL2FP(man_ys);

  // generate output strings
  char man_x0_vs[128];
  char man_y0_vs[128];
  char man_xs_vs[128];
  char man_ys_vs[128];

  char man_x0_cs[128];
  char man_y0_cs[128];
  char man_xs_cs[128];
  char man_ys_cs[128];

  sprintf(man_x0_vs, "wire signed [%ld-1:0] man_x0 = %ld\'h%014lx;", MAX_MUL_WIDTH, MAX_MUL_WIDTH, man_x0_fp & 0x3FFFFFFFFFFFFFUL);
  sprintf(man_y0_vs, "wire signed [%ld-1:0] man_y0 = %ld\'h%014lx;", MAX_MUL_WIDTH, MAX_MUL_WIDTH, man_y0_fp & 0x3FFFFFFFFFFFFFUL);
  sprintf(man_xs_vs, "wire signed [%ld-1:0] man_xs = %ld\'h%014lx;", MAX_MUL_WIDTH, MAX_MUL_WIDTH, man_xs_fp & 0x3FFFFFFFFFFFFFUL);
  sprintf(man_ys_vs, "wire signed [%ld-1:0] man_ys = %ld\'h%014lx;", MAX_MUL_WIDTH, MAX_MUL_WIDTH, man_ys_fp & 0x3FFFFFFFFFFFFFUL);

  sprintf(man_x0_cs, "  int64_t man_x0 = 0x%016lxLL;", man_x0_fp);
  sprintf(man_y0_cs, "  int64_t man_y0 = 0x%016lxLL;", man_y0_fp);
  sprintf(man_xs_cs, "  int64_t man_xs = 0x%016lxLL;", man_xs_fp);
  sprintf(man_ys_cs, "  int64_t man_ys = 0x%016lxLL;", man_ys_fp);

  // output strings
  if (to_file) {
    // to file
    FILE* fp = NULL;
    if ((fp  = fopen(filename, "wb")) == NULL) {
      fprintf(stderr, "Can't open output file " FILENAME ", exiting.\n");
      exit(EXIT_FAILURE);
    }
    fprintf(fp, "%s\n", man_x0_vs);
    fprintf(fp, "%s\n", man_y0_vs);
    fprintf(fp, "%s\n", man_xs_vs);
    fprintf(fp, "%s\n", man_ys_vs);
    fclose(fp);
  } else {
    // to screen
    printf("%s\n", man_x0_vs);
    printf("%s\n", man_y0_vs);
    printf("%s\n", man_xs_vs);
    printf("%s\n", man_ys_vs);
    printf("%s\n", man_x0_cs);
    printf("%s\n", man_y0_cs);
    printf("%s\n", man_xs_cs);
    printf("%s\n", man_ys_cs);
    printf("                           {0x%016lxLL, 0x%016lxLL, 0x%016lxLL, 0x%016lxLL},\n", man_x0_fp, man_y0_fp, man_xs_fp, man_ys_fp);
  }

  // exit
  exit(EXIT_SUCCESS);
}

