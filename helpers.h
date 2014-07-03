#ifndef COMHELP_H
#define COMHELP_H
useguid(%1) MACRO
	.DATA
	%1	GUID	GUID_%1
ENDM
// coinvoke(pInterface, Interface.Method, args...)
// note esi must not be used in args in any form
coinvoke(%1, %2, %3, %4, %5, %6, %7, %8, %9, %10) MACRO
push esi
mov esi, %1
mov esi,[esi]
#if	ARGCOUNT=2
	invoke	[esi + %2],%1
#elif ARGCOUNT=3
	invoke	[esi + %2],%1, %3
#elif ARGCOUNT=4
	invoke	[esi + %2],%1, %3,%4
#elif ARGCOUNT=5
	invoke	[esi + %2],%1, %3,%4,%5
#elif ARGCOUNT=6
	invoke	[esi + %2],%1, %3,%4,%5,%6
#elif ARGCOUNT=7
	invoke	[esi + %2],%1, %3,%4,%5,%6,%7
#elif ARGCOUNT=8
	invoke	[esi + %2],%1, %3,%4,%5,%6,%7,%8
#elif ARGCOUNT=9
	invoke	[esi + %2],%1, %3,%4,%5,%6,%7,%8,%9
#elif ARGCOUNT=10
	invoke	[esi + %2],%1, %3,%4,%5,%6,%7,%8,%9,%10
#endif
pop	esi
ENDM

writeln(%1,%2,%3,%4,%5,%6,%7,%8,%9) MACRO
	pusha
#if	ARGCOUNT=0
	invoke fprintf,[STDOUT],ADDR <0Dh,0Ah,00>
#elif ARGCOUNT=1
	invoke fprintf,[STDOUT],%1
#elif ARGCOUNT=2
	invoke fprintf,[STDOUT],%1,%2
#elif ARGCOUNT=3
	invoke fprintf,[STDOUT],%1,%2,%3
#elif ARGCOUNT=4
	invoke fprintf,[STDOUT],%1,%2,%3,%4
#elif ARGCOUNT=5
	invoke fprintf,[STDOUT],%1,%2,%3,%4,%5
#elif ARGCOUNT=6
	invoke fprintf,[STDOUT],%1,%2,%3,%4,%5,%6
#elif ARGCOUNT=7
	invoke fprintf,[STDOUT],%1,%2,%3,%4,%5,%6,%7
#elif ARGCOUNT=8
	invoke fprintf,[STDOUT],%1,%2,%3,%4,%5,%6,%7,%8
#elif ARGCOUNT=9
	invoke fprintf,[STDOUT],%1,%2,%3,%4,%5,%6,%7,%8,%9
#endif
#if ARGCOUNT>0
	ADD ESP,(ARGCOUNT+1)*4
#elif ARGCOUNT=0
	ADD	ESP, 8
#endif
	popa
ENDM

RGB(%1,%2,%3) MACRO
	((%1) | (%2 << 8) | (%3 << 16))
ENDM

abseax()	MACRO
	cdq
	xor eax,edx
	sub eax,edx
ENDM

#endif