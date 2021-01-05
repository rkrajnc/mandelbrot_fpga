// hardware.h
// various hardware-related & helper functions and defines 
// 2020, Rok Krajnc <rok.krajnc@gmail.com>


#ifndef __HARDWARE_H__
#define __HARDWARE_H__


#include <inttypes.h>
#include "spr_defs.h"
#include "or32_defs.h"


//// make sure NULL is defined ////
#ifndef NULL
#define NULL 0
#endif


//// debug output ////
//#define DEBUG

#ifdef DEBUG
#define DBGPRINT(...)       printf(__VA_ARGS__)
#else
#define DBGPRINT(...)
#endif

#define STR(x)              #x
#define XSTR(x)             STR(x)

#define DEBUG_FUNC_IN()     DBGPRINT("* DEBUG : FUNC IN  : %s(), file " __FILE__ ", line " XSTR(__LINE__) "\r", __FUNCTION__)
#define DEBUG_FUNC_OUT()    DBGPRINT("* DEBUG : FUNC OUT : %s()\r", __FUNCTION__)
#define DEBUG_MSG(x)        DBGPRINT("* DEBUG : " x "\r")


//// memory read/write ////
#define read8(adr)          (*((volatile uint8_t  *)(adr)))
#define read16(adr)         (*((volatile uint16_t *)(adr)))
#define read32(adr)         (*((volatile uint32_t *)(adr)))
#define write8(adr, data)   (*((volatile uint8_t  *)(adr)) = (data))
#define write16(adr, data)  (*((volatile uint16_t *)(adr)) = (data))
#define write32(adr, data)  (*((volatile uint32_t *)(adr)) = (data))


//// system ////
#define SYS_CLOCK           50000000    // system clock in Hz
#define SYS_PERIOD_NS       20          // system period in ns
#define RAM_START           0x00000000
#define REG_START           0x00002000
#define REG_MAN_DONE_ADR    (REG_START + 0x00)
#define REG_MAN_INIT_ADR    (REG_START + 0x04)
#define REG_MAN_X0_0_ADR    (REG_START + 0x08)
#define REG_MAN_X0_1_ADR    (REG_START + 0x0c)
#define REG_MAN_Y0_0_ADR    (REG_START + 0x10)
#define REG_MAN_Y0_1_ADR    (REG_START + 0x14)
#define REG_MAN_XS_0_ADR    (REG_START + 0x18)
#define REG_MAN_XS_1_ADR    (REG_START + 0x1c)
#define REG_MAN_YS_0_ADR    (REG_START + 0x20)
#define REG_MAN_YS_1_ADR    (REG_START + 0x24)
#define REG_MAN_HRES_ADR    (REG_START + 0x28)
#define REG_MAN_VRES_ADR    (REG_START + 0x2c)
#define REG_MAN_NPIXELS_ADR (REG_START + 0x30)
#define REG_MAN_ST_DONE_ADR (REG_START + 0x34)
#define REG_MAN_NITERS_ADR  (REG_START + 0x38)
#define REG_MAN_TIMER_ADR   (REG_START + 0x3c)
#define REG_VID_FADER_ADR   (REG_START + 0x40)
#define REG_TIMER_EN_ADR    (REG_START + 0x80)
#define REG_TIMER_CLR_ADR   (REG_START + 0x84)
#define REG_TIMER_ADR       (REG_START + 0x88)
#define CONSOLE_START       (REG_START + 0x800)


//// system stuff ////
// nop
#define nop()               asm("l.nop\t3");

// align
#define ALIGN(addr,size)    ((addr + (size-1))&(~(size-1)))

// func pointer
#define FUNC(r,n,p...)      r _##n(p); r (*n)(p) = _##n; r _##n(p)

// atomic operation
#define ATOMIC(x...)        {unsigned val = disable_ints(); {x;} restore_ints(val);}

// read & write or1200 SPR
#define mtspr(spr, value)   { asm("l.mtspr\t\t%0,%1,0": : "r" (spr), "r" (value)); }
#define mfspr(spr)          ({ unsigned long __val;                                \
                            asm("l.mfspr\t\t%0,%1,0" : "=r" (__val) : "r" (spr));  \
                            __val; })

// enable & disable ints
#define disable_ints()      ({ unsigned __x = mfspr(SPR_SR);   \
                            mtspr(SPR_SR, __x & ~SPR_SR_IEE);  \
                            __x; })
#define restore_ints(x)     mtspr(SPR_SR, x)
#define enable_ints()       mtspr(SPR_SR, mfspr(SPR_SR) | SPR_SR_IEE)

#define report(val)         { asm("l.add r3,r0,%0": :"r" (val)); \
                            asm("l.nop\t2"); }


//// global variables ////


//// function declarations ////
void *hmalloc(int size);
void sys_jump(unsigned long addr);
void sys_load(uint32_t * origin, uint32_t * dest, uint32_t size, uint32_t * routine);


#endif // __HARDWARE_H__

