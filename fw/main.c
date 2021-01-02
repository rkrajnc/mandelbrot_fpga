// main.c
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


#include <inttypes.h>
#include "hardware.h"



typedef struct {
  int64_t x0;
  int64_t y0;
  int64_t xs;
  int64_t ys;
} man_coords_t;


#define NSTEPS  64L

man_coords_t coord_init = {0xfffbd55555555556LL, 0xfffe000000000000LL, 0x000001b4e81b4e81LL, 0x000001b4e81b4e81LL};

int ncoords = 4;
man_coords_t coords[] = {
                          {0xffffe8d62cccbd45LL, 0x0001f93ff3a4c1afLL, 0x00000000000502c3LL, 0x00000000000502c3LL},
                          {0xfffe7e7b272f6088LL, 0x000035dcc63f1412LL, 0x000000022f3d9397LL, 0x000000022f3d9397LL},
                          {0xfffe81f671529a49LL, 0x0000395e9e1b089aLL, 0x0000000048b38663LL, 0x0000000048b38663LL},
                          {0x0000859c953a1ce3LL, 0xfffffed068e6facdLL, 0x0000000021570148LL, 0x0000000021570148LL}
                        };


void main(void) __attribute__ ((noreturn));
void main(void)
{
  // endless loop
  while (1) {
    // loop over coords
    for (int coord=0; coord<ncoords; coord++) {
      // zoom in
      for (int step=0; step<NSTEPS; step++) {
        int64_t x0 = coord_init.x0 + (step*(coords[coord].x0 - coord_init.x0)) / NSTEPS;
        int64_t y0 = coord_init.y0 + (step*(coords[coord].y0 - coord_init.y0)) / NSTEPS;
        int64_t xs = coord_init.xs + (step*(coords[coord].xs - coord_init.xs)) / NSTEPS;
        int64_t ys = coord_init.ys + (step*(coords[coord].ys - coord_init.ys)) / NSTEPS;
        // wait for engine
        while(!(read32(REG_MAN_DONE_ADR)&0x1));
        // write new values
        write32(REG_MAN_X0_0_ADR, (x0 >>  0) & 0xffffffffUL);
        write32(REG_MAN_X0_1_ADR, (x0 >> 32) & 0xffffffffUL);
        write32(REG_MAN_Y0_0_ADR, (y0 >>  0) & 0xffffffffUL);
        write32(REG_MAN_Y0_1_ADR, (y0 >> 32) & 0xffffffffUL);
        write32(REG_MAN_XS_0_ADR, (xs >>  0) & 0xffffffffUL);
        write32(REG_MAN_XS_1_ADR, (xs >> 32) & 0xffffffffUL);
        write32(REG_MAN_YS_0_ADR, (ys >>  0) & 0xffffffffUL);
        write32(REG_MAN_YS_1_ADR, (ys >> 32) & 0xffffffffUL);
        // enable engine
        write32(REG_MAN_INIT_ADR, 0x1);
        for (volatile int i=0; i<100; i++);
        write32(REG_MAN_INIT_ADR, 0x0);
      }
      // zoom out
      for (int step=0; step<NSTEPS; step++) {
        int64_t x0 = coords[coord].x0 + (step*(coord_init.x0 - coords[coord].x0)) / NSTEPS;
        int64_t y0 = coords[coord].y0 + (step*(coord_init.y0 - coords[coord].y0)) / NSTEPS;
        int64_t xs = coords[coord].xs + (step*(coord_init.xs - coords[coord].xs)) / NSTEPS;
        int64_t ys = coords[coord].ys + (step*(coord_init.ys - coords[coord].ys)) / NSTEPS;
        // wait for engine
        while(!(read32(REG_MAN_DONE_ADR)&0x1));
        // write new values
        write32(REG_MAN_X0_0_ADR, (x0 >>  0) & 0xffffffffUL);
        write32(REG_MAN_X0_1_ADR, (x0 >> 32) & 0xffffffffUL);
        write32(REG_MAN_Y0_0_ADR, (y0 >>  0) & 0xffffffffUL);
        write32(REG_MAN_Y0_1_ADR, (y0 >> 32) & 0xffffffffUL);
        write32(REG_MAN_XS_0_ADR, (xs >>  0) & 0xffffffffUL);
        write32(REG_MAN_XS_1_ADR, (xs >> 32) & 0xffffffffUL);
        write32(REG_MAN_YS_0_ADR, (ys >>  0) & 0xffffffffUL);
        write32(REG_MAN_YS_1_ADR, (ys >> 32) & 0xffffffffUL);
        // enable engine
        write32(REG_MAN_INIT_ADR, 0x1);
        for (volatile int i=0; i<100; i++);
        write32(REG_MAN_INIT_ADR, 0x0);
      }
    }
  }

  while(1);
}

