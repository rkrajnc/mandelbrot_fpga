// main.c
// 2021, Rok Krajnc <rok.krajnc@gmail.com>


//// includes ////
#include <inttypes.h>
#include "hardware.h"
#include "sprintf.h"


//// types ////
typedef struct {
  int64_t x0;
  int64_t y0;
  int64_t xs;
  int64_t ys;
} man_coords_t;

typedef struct {
  char xs;
  char ys;
  uint8_t xi;
  uint8_t yi;
  uint32_t xf;
  uint32_t yf;
} coord_conv_t;


//// defines ////
#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600
#define CONSOLE_WIDTH 100
#define CONSOLE_HEIGHT 3

#define FPW 54
#define FP_S 1
#define FP_I 4
#define FP_F (FPW-FP_S-FP_I)
#define CONV_BITS 16
#define CONV_MAGIC 15259UL

#define NSTEPS  64L

#define static
#define inline


//// globals ////
//man_coords_t coord_init = {0xfffbd55555555556LL, 0xfffe000000000000LL, 0x000001b4e81b4e81LL, 0x000001b4e81b4e81LL};

int ncoords = 30UL;
// 5, 16, 17, 22 (23, 24 iaste), 27, 29, 30, 31, 33, 34, 35, 37, 38, 40, 41, 42, 
man_coords_t coords[] = {
                          {0xfffbd55555555556LL, 0xfffe000000000000LL, 0x000001b4e81b4e81LL, 0x000001b4e81b4e81LL}, // 0
                          {0x00009279c6f0349aLL, 0x000006fd5e30b316LL, 0x0000000047032a37LL, 0x0000000047032a37LL}, // 1
                          {0xfffd3fc6bac88210LL, 0xfffff8f3b19df00bLL, 0x000000009e8a1dbbLL, 0x000000009e8a1dbbLL}, // 2
                          {0xffff1469fe4d01ceLL, 0x000123fbdfd63be4LL, 0x00000000008e7b4eLL, 0x00000000008e7b4eLL}, // 3
                          {0xfffe7e96634c6e94LL, 0xffffe01f2c368743LL, 0x0000000153b63f73LL, 0x0000000153b63f73LL}, // 4
//                          {0xffffff5555555556LL, 0xffffff8000000000LL, 0x000000006d3a06d3LL, 0x000000006d3a06d3LL}, // 5
                          {0xfffe7e7b272f6088LL, 0x000035dcc63f1412LL, 0x000000022f3d9397LL, 0x000000022f3d9397LL}, // 6
                          {0xfffe81f671529a49LL, 0x0000395e9e1b089aLL, 0x0000000048b38663LL, 0x0000000048b38663LL}, // 7
                          {0xfffe824f227d028bLL, 0x000039d14e3bcd35LL, 0x0000000010c6f7a0LL, 0x0000000010c6f7a0LL}, // 8
                          {0xfffe825204af922aLL, 0x000039d8622c4502LL, 0x00000000035afe53LL, 0x00000000035afe53LL}, // 9
                          {0xffff9c54a6921736LL, 0x0002076c8b439581LL, 0x0000000b5c0cff7bLL, 0x0000000b5c0cff7bLL}, // 10
                          {0xfffe108dfea27984LL, 0x000077ced916872bLL, 0x0000000dfb23b097LL, 0x0000000dfb23b097LL}, // 11
                          {0xfffd7f8bc8675414LL, 0x00000a36e2eb1c43LL, 0x000000001303a12dLL, 0x000000001303a12dLL}, // 12
                          {0xfffe801179ec9cbeLL, 0x0000327bb2fec56dLL, 0x000000009c965c86LL, 0x000000009c965c86LL}, // 13
                          {0xffff8796b49b360bLL, 0x0001a7837b4a2339LL, 0x0000000004795319LL, 0x0000000004795319LL}, // 14
                          {0xfffe815d867c3ecfLL, 0x000074395810624dLL, 0x000000084d1d30daLL, 0x000000084d1d30daLL}, // 15
//                          {0xffffafcb1e1b434dLL, 0x0002140899d78207LL, 0x0000000000000ea8LL, 0x0000000000000ea8LL}, // 16
//                          {0xffffadb88901544dLL, 0x0002133be736db5eLL, 0x000000000002dd01LL, 0x000000000002dd01LL}, // 17
                          {0x000088d31c3259adLL, 0xfffffe49398719e5LL, 0x00000000000000d7LL, 0x00000000000000d7LL}, // 18
                          {0xffffe8d62cccbd45LL, 0x0001f93ff3a4c1afLL, 0x00000000000502c3LL, 0x00000000000502c3LL}, // 19
                          {0xffffe8d6346ea9c2LL, 0x0001f93ff99e1149LL, 0x0000000000002040LL, 0x0000000000002040LL}, // 20
                          {0xffffe8d6349944eaLL, 0x0001f93ff9be05a7LL, 0x00000000000004fcLL, 0x00000000000004fcLL}, // 21
//                          {0xffffe8d6349df70cLL, 0x0001f93ff9c18b41LL, 0x00000000000001faLL, 0x00000000000001faLL}, // 22
                          {0xfffe517f79154dffLL, 0x000072dcd2d44dcaLL, 0x0000000008d6041fLL, 0x0000000008d6041fLL}, // 23
                          {0xfffe604a8da963ddLL, 0x000066fa74e26d5fLL, 0x00000000218def41LL, 0x00000000218def41LL}, // 24
                          {0xfffe607df3791324LL, 0x00006721013e30d5LL, 0x0000000000a8ef75LL, 0x0000000000a8ef75LL}, // 25
                          {0xfffe607ef96060a8LL, 0x00006721c5abaaf8LL, 0x000000000001512eLL, 0x000000000001512eLL}, // 26
//                          {0xfffe607efb5deeb7LL, 0x00006721c729d583LL, 0x0000000000000b11LL, 0x0000000000000b11LL}, // 27
                          {0x0000e7cb0d92f936LL, 0x0000cb014a655dd2LL, 0x00000000000013caLL, 0x00000000000013caLL}, // 28
//                          {0x0000e7cb0dad6e33LL, 0x0000cb014a793590LL, 0x00000000000002dbLL, 0x00000000000002dbLL}, // 29
//                          {0x0000e7cb0db04b35LL, 0x0000cb014a7b5b51LL, 0x0000000000000106LL, 0x0000000000000106LL}, // 30
//                          {0xfffdb17b195bf9e4LL, 0x00009d6eef34dfdcLL, 0x00000000000003e2LL, 0x00000000000003e2LL}, // 31
                          {0xfffdb1164fb961eaLL, 0x00009e17bf35b7cdLL, 0x00000000000016b9LL, 0x00000000000016b9LL}, // 32
//                          {0xfffdb1164fdc2d6dLL, 0x00009e17bf4fd06fLL, 0x0000000000000074LL, 0x0000000000000074LL}, // 33
//                          {0xfffdb1164fdcc75bLL, 0x00009e17bf5043e1LL, 0x0000000000000011LL, 0x0000000000000011LL}, // 34
//                          {0xfffdb1164fdcd85dLL, 0x00009e17bf5050a3LL, 0x0000000000000006LL, 0x0000000000000006LL}, // 35
                          {0x0000dd754e68681fLL, 0x000073c5685caa23LL, 0x00000000005ba03fLL, 0x00000000005ba03fLL}, // 36
//                          {0x0000ac8939b1a33cLL, 0x000018f975744a60LL, 0x0000000000000021LL, 0x0000000000000021LL}, // 37
//                          {0x0000ac8939b1cc93LL, 0x000018f975748587LL, 0x0000000000000007LL, 0x0000000000000007LL}, // 38
                          {0x0000960221e93b24LL, 0x0001393bc61442aaLL, 0x0000000000132f26LL, 0x0000000000132f26LL}, // 39
//                          {0x000096023fd90e5fLL, 0x0001393bdc882116LL, 0x000000000000064dLL, 0x000000000000064dLL}, // 40
//                          {0x000096023fe266e8LL, 0x0001393bdc8f237dLL, 0x0000000000000052LL, 0x0000000000000052LL}, // 41
//                          {0x000096023fe2ca99LL, 0x0001393bdc8f6e42LL, 0x0000000000000012LL, 0x0000000000000012LL}, // 42
                          {0xfffe207ecd962623LL, 0x000086d74f06ce50LL, 0x00000000000502c3LL, 0x00000000000502c3LL}, // 43
                          {0xfffe885fd3e15e10LL, 0x00007db4f267a07dLL, 0x0000000000000326LL, 0x0000000000000326LL}, // 44
                          {0x0000859c953a1ce3LL, 0xfffffed068e6facdLL, 0x0000000021570148LL, 0x0000000021570148LL}  // 45
                        };

char buf[128];
coord_conv_t coord_conv;
int64_t xc;
int64_t yc;


//// console_puts() ////
static inline void console_puts(const char* str, int position, int maxlen)
{
  int i=0;
  while ((str[i] != 0) && (i < maxlen) && ((position+i) < CONSOLE_WIDTH*CONSOLE_HEIGHT)) {
    write8(CONSOLE_START+position+i, str[i]);
    i++;
  }
}

/*
//// coord_to_str() ////
static inline void coord_to_str()
{
  uint64_t xun;
  uint64_t yun;

  if (xc < 0LL) {
    coord_conv.xs = '-';
    xun = -xc;
  } else {
    coord_conv.xs = ' ';
    xun = xc;
  }
  if (yc < 0LL) {
    coord_conv.ys = '-';
    yun = -yc;
  } else {
    coord_conv.ys = ' ';
    yun = yc;
  }
  coord_conv.xi = xun >> (FP_F);
  coord_conv.yi = yun >> (FP_F);
  uint32_t xt = (xun & 0x1FFFFFFFFFFFFULL) >> (FP_F-CONV_BITS);
  coord_conv.xf = xt * CONV_MAGIC / 10UL;
  uint32_t yt = (yun & 0x1FFFFFFFFFFFFULL) >> (FP_F-CONV_BITS);
  coord_conv.yf = yt * CONV_MAGIC / 10UL;
}
*/
/*
//// get_center_coord() ////
static inline void get_center_coord(man_coords_t* c)
{
  xc = c->x0;
  int64_t xst = c->xs;
  int32_t xinc = SCREEN_WIDTH>>1;
  for (int i=0; i<12; i++) {
    if (xinc&1) xc += xst;
    xinc >>= 1;
    xst <<= 1;
  }
  yc = c->y0;
  int64_t yst = c->xs;
  int32_t yinc = SCREEN_HEIGHT>>1;
  for (int i=0; i<12; i++) {
    if (yinc&1) yc += yst;
    yinc >>= 1;
    yst <<= 1;
  }
}
*/

//// mandelbrot_write_coords() ////
static inline void mandelbrot_write_coords(const man_coords_t* c)
{
  write32(REG_MAN_X0_0_ADR, (c->x0 >>  0) & 0xffffffffUL);
  write32(REG_MAN_X0_1_ADR, (c->x0 >> 32) & 0xffffffffUL);
  write32(REG_MAN_Y0_0_ADR, (c->y0 >>  0) & 0xffffffffUL);
  write32(REG_MAN_Y0_1_ADR, (c->y0 >> 32) & 0xffffffffUL);
  write32(REG_MAN_XS_0_ADR, (c->xs >>  0) & 0xffffffffUL);
  write32(REG_MAN_XS_1_ADR, (c->xs >> 32) & 0xffffffffUL);
  write32(REG_MAN_YS_0_ADR, (c->ys >>  0) & 0xffffffffUL);
  write32(REG_MAN_YS_1_ADR, (c->ys >> 32) & 0xffffffffUL);
}


//// mandelbrot_engine_wait() ////
static inline void mandelbrot_engine_wait()
{
  while(!(read32(REG_MAN_DONE_ADR)&0x1UL));
}


//// mandelbrot_stats_wait() ////
static inline void mandelbrot_stats_wait()
{
  while(!(read32(REG_MAN_ST_DONE_ADR)&0x1UL));
}


//// mandelbrot_engine_start() ////
static inline void mandelbrot_engine_start()
{
  write32(REG_MAN_INIT_ADR, 0x1UL);
  nop();
  write32(REG_MAN_INIT_ADR, 0x0UL);
}


//// video_fade_in() ////
static inline void video_fade_in()
{
  write32(REG_TIMER_EN_ADR, 0x1UL);
  for (int i=7; i>=0; i--) {
    write32(REG_TIMER_CLR_ADR, 0x1UL);
    while (read32(REG_TIMER_ADR) < 2000000UL);
    write32(REG_VID_FADER_ADR, i);
  }
}


//// video_fade_out() ////
static inline void video_fade_out()
{
  write32(REG_TIMER_EN_ADR, 0x1UL);
  for (int i=0; i<8; i++) {
    write32(REG_TIMER_CLR_ADR, 0x1UL);
    while (read32(REG_TIMER_ADR) < 2000000UL);
    write32(REG_VID_FADER_ADR, i);
  }
}


//// delay_us() ////
static inline void delay_us(unsigned int delay)
{
  write32(REG_TIMER_EN_ADR, 0x1UL);
  write32(REG_TIMER_CLR_ADR, 0x1UL);
  while (read32(REG_TIMER_ADR) < delay*50);
}


//// delay_ms() ////
static inline void delay_ms(unsigned int delay)
{
  write32(REG_TIMER_EN_ADR, 0x1UL);
  write32(REG_TIMER_CLR_ADR, 0x1UL);
  while (read32(REG_TIMER_ADR) < delay*50000);
}


//// main ////
void main(void) __attribute__ ((noreturn));
void main(void)
{
  // set initial video fade
  write32(REG_VID_FADER_ADR, 0x7);

  // banner
  console_puts("                   *** Mandelbrot FPGA  (Rok Krajnc <rok.krajnc@gmail.com>) ***", 0, 100);

  // loop forever
  while(1) {
    for (int coord=0; coord<ncoords; coord++) {
      mandelbrot_write_coords(&(coords[coord]));
      mandelbrot_engine_start();
      nop();
      mandelbrot_stats_wait();
      nop();
      uint32_t niters = read32(REG_MAN_NITERS_ADR);
      uint32_t time   = read32(REG_MAN_TIMER_ADR) * 66 / 10000000;
      //get_center_coord(&(coords[coord]));
      //coord_to_str();    
      sprintf(buf, "%02d : niters=%d  time=%dms        ", coord, niters, time);
      console_puts(buf, 100, 100);
      video_fade_in();
      delay_ms(15000);
      video_fade_out();    
    }
  }

  while(1);
}

