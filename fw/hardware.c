// hardware.c
// various hardware-related & helper functions and defines 
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


#include "hardware.h"


//// heap management() ////
extern int *_heap_start;
extern int *_heap_end;
static int *__heap_cur = 0;

void *hmalloc(int size)
{
  int *new, *old;

  if(__heap_cur == NULL) __heap_cur = (int *)&_heap_start;

  new = (int *)((int)__heap_cur + size);
  if(new > (int *)&_heap_end) return NULL;

  old = __heap_cur;
  __heap_cur = new;

  return old;
}


//// sys jump() ////
void sys_jump(unsigned long addr)
{
//  disable_ints();
  __asm__("l.sw  0x4(r1),r9");
  __asm__("l.jalr  %0" : : "r" (addr));
  __asm__("l.nop");
//  __asm__("l.lwz r9,0x4(r1)");
}


//// sys_load() ////
void sys_load(uint32_t * origin, uint32_t * dest, uint32_t size, uint32_t * routine)
{
  disable_ints();
  __asm__ __volatile__ ("l.add r4,r0,%0" : : "r" (origin)   : "r4");
  __asm__ __volatile__ ("l.add r2,r0,%0" : : "r" (dest)     : "r2");
  __asm__ __volatile__ ("l.add r3,r0,%0" : : "r" (size)     : "r3");
  __asm__ __volatile__ ("l.jr  %0"       : : "r" (routine)        );
}

