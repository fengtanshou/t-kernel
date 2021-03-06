/*
 *----------------------------------------------------------------------
 *    T-Kernel 2.0 Software Package
 *
 *    Copyright 2011 by Ken Sakamura.
 *    This software is distributed under the latest version of T-License 2.x.
 *----------------------------------------------------------------------
 *
 *    Released by T-Engine Forum(http://www.t-engine.org/) at 2011/05/17.
 *    Modified by TRON Forum(http://www.tron.org/) at 2015/06/01.
 *
 *----------------------------------------------------------------------
 */

/*
 *	eitentry.S
 *
 *       EM1D512 (ARM1176JZF-S) exception branch handling
 *
 *	monitor/hwdepend/arm/cpu/eitent-start.S
 *	Startup Code (reset vector) for T-Monitor
 *	rewrite but keep the most of orignal global symbol names.
 *	
 */

/*
 * Copyright (C) 2016  Du Huanpeng<u74147@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */



#include <machine.h>
#include <tk/sysdef.h>
#include <sys/sysinfo.h>

// see <sys/sysdepend/tef_em1d/sysinfo_depend.h>

#define EIT_DEFAULT	0		/* default handler */
#define EIT_UNDEF	1		/* undefined instruction */
#define EIT_IABORT	2		/* prefetch abort */
#define EIT_DABORT	3		/* data abort */
#define EIT_IDEBUG	29		/* debug abort instruction */
#define EIT_DDEBUG	30		/* debug abort data */
#define EIT_FIQ		31		/* fast interrupt FIQ */
#define EIT_IRQ(n)	(  32 + (n) )	/* interrupt		IRQ  0-95 */
#define EIT_IRQ(n)	( 128 + (n) )	/* GPIO interrupt	port 0-127 */

#define EIT_ENTRY(n)	(EIT_VECTBL+4*(n))


/*
 *       EIT entry
 */


/*
 * r0-r7, r8-r12, r13(sp), r14(lr), r15(pc)
 */

	.section eitbra
	.global  _start
	.global fiq_entry
	.global dabort_entry
	.global svc_entry
	.global iabort_entry
	.global undef_entry
	.global irq_entry
_start:
	b	startup_entry		@ 00 : reset
	b	undef_entry		@ 04 : undefined instruction
	b	svc_entry		@ 08 : software interrupt
	b	iabort_entry		@ 0C : prefetch abort
	b	dabort_entry		@ 10 : data abort
	b	.			@ 14 : reserved
	b	irq_entry		@ 18 : IRQ
fiq_entry:				@ 1C : FIQ
/*
 * fast interrupt
 *       calls the handler defined at FIQ interrupt vector unconditionally.
 *       no saving of registers to stack is performed.
 *       the content of R12_fiq(ip) register is overwritten.
 */
	push	{r0-r7, lr}

	mrs	lr, cpsr
	orr	lr, #(1<<6)	@ disable fiq
 	msr	cpsr, lr


	ldr	lr, =EIT_ENTRY(EIT_FIQ)
	ldr	lr, [lr]
	blx	lr

	pop	{r0-r7, lr}
	subs	pc, lr, #4
@ end of fiq

	.weak syscall
__syscall:
	.word	0xEFEFEFEF
	bx	lr
syscall:
	bic	r0, #0xFF000000
	orr	r0, #0xEF000000
	str	r0, __syscall
	b	__syscall

/*
 * interrupt
 *       ACPU interrupt mask status register of Interrupt controller (AINT)
 *      Judge the priority of interrupts using (IT0_MST0,1,2),
 *       the highest interrupt's handler is called by jumping into it.
 *       Interrupt priority is descending order of interrupt factor (INT 0-95) , and INT 95 (IRQ 95) is highest.
 *       INT 0 (IRQ 0) has the lowest priority.
 *       If there is no cause of the interrupt, the handler of INT 95 (IRQ95) is called.
 *		+---------------+
 *	sp  ->	|R3		|
 *		|R12=ip		|
 *              |R14=lr         | <- return address from interrupt
 *		|SPSR		|
 *		+---------------+
 *      registers upon handler invocation
 *       ip = vector table address
 *       lr = indeterminate
 */
irq_entry:
	push	{r0-r12, lr}

	mrs	lr, cpsr
	orr	lr, #(1<<7)
	msr	cpsr, lr

	str	lr, [lr]

	ldr	lr, =do_irq
	blx	lr

	pop	{r0-r12, lr}
	subs	pc, lr, #4
irqmsg:
.asciz "IRQ" 

/*
 * undefined instruction
 *		+---------------+
 *	sp  ->	|R12=ip		|
 *              |R14=lr         | <- the return address, i.e., the next address that follows the undefined instruction
 *		|SPSR		|
 *		+---------------+
 *      registers upon handler invocation
 *       ip = vector table address
 *       lr = indeterminate
 */
 	
undef_entry:
	push	{r0-r12, r14}

	ldr	lr, =EIT_ENTRY(EIT_UNDEF)
	ldr	lr, [lr]
	blx	lr

	pop	{r0-r12, r14}
	movs	pc, lr

/*
 * supervisor call(SVC)
 *      the valid range of supervisor call number is 0-255 (N_INTVEC - 1).
 *       if an out of range value is given, treat it as SVC 0, and invokes the default handler.
 *		+---------------+
 *	sp  ->	|R12=ip		|
 *              |R14=lr         | <- return address: the address that follows the SVC instruction
 *		|SPSR		|
 *		+---------------+
 *      registers upon handler invocation
 *       ip = vector table address
 *       lr = indeterminate
 *
 *	only the lowest byte of svc instruction handled, other bytes are ignored.
 *	hope it works with thumb mode.
 *	simply save all registers.
 *	  r0 = the vector number.
 *	+---------------+
 *	| r0-r12	|
 *	| lr		|
 *	+---------------+
 */

svc_entry:
	push	{r0-r12, lr}

	ldrb	r0, [lr]
	ldr	lr, =EIT_VECTBL

	ldr	lr, [lr, r0, lsl #2]
	blx	lr

	pop	{r0-r12, lr}
	movs	pc, lr

/*
 * prefetch abort
 *       in the case of debug event, debug abort (instruction) handler is called.
 *       Otherwise, prefetch abort handler is called.
 *		+---------------+
 *	sp  ->	|R12=ip		|
 *              |R14=lr         | <- return address: the address of aborted instruction
 *		|SPSR		|
 *		+---------------+
 *      registers upon handler invocation
 *       ip = vector table address
 *       lr = indeterminate
 */
iabort_entry:
	push	{r0-r12, lr}

	mov	r0, lr
	bl	printh

	pop	{r0-r12, lr}
	movs	pc, lr

/*
 * data abort
 *       in the case of debug event, debug abort (data) handler is called.
 *       Otherwise, data abort handler is called.
 *		+---------------+
 *	sp  ->	|R12=ip		|
 *              |R14=lr         | <- return address: the address of aborted instruction
 *		|SPSR		|
 *		+---------------+
 *      registers upon handler invocation
 *       ip = vector table address
 *       lr = indeterminate
 */
dabort_entry:
	push	{r0-r12}
	mrs	r7, spsr
	tst	r7, #(1<<5)
	subeq	lr, #4
	subne	lr, #6
	push	{lr}

	ldr	lr, =EIT_ENTRY(EIT_DABORT)
	ldr	lr, [lr]
	blx	lr

	pop	{lr}
	pop	{r0-r12}
	movs	pc, lr
	
	
/*
 * default handler
 *       stack contains the details of the generated exception.
 *      registers upon handler invocation
 *       ip = address of the vector table for the raised exception
 *       lr = indeterminate
 *
 *	Not used, waster some bytes to repeat similar code for every mode.
 */
default_entry:
	bx	lr
	.pool

