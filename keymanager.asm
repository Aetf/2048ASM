#include "game.h"

	.DATA
KeyMgr_Map_Key		DD	VK_UP, \
						VK_RIGHT, \
						VK_DOWN, \
						VK_LEFT
KeyMgr_Map_Value	DD	0, 1, 2, 3

	.CODE
KeyMgrOnKeyDown:
	FRAME	hWnd, wParam
	USES	ebx,esi,edi
	;IF keycode is not found
		mov		eax,[wParam]	;LOWORD(wParam)=ID
		mov		edi,ADDR KeyMgr_Map_Key
		mov		ecx,SIZEOF(KeyMgr_Map_Key)/4
		repne	scasd
		je		>.Process

	;THEN we are not interested in it, return
		jmp		>.Return

	;ELSE process
	.Process
		; If the game is running
		invoke	GameRunning
		test	eax, eax
		; THEN we do nothing
		jnz		>.Return
		; ELSE pass to GameManager
		invoke	GameMove, [edi+SIZEOF(KeyMgr_Map_Key)-4]
	.Return
		ret
ENDF

KeyLButtonUp:
	FRAME	hWnd, xPos, yPos
	USES	ebx,esi,edi
		#ifdef MOUSE_DEBUG
			mov		eax, ADDR <'LClick at (%d,%d)',0Dh,0Ah,0>
			writeln(eax, [xPos], [yPos])
		#endif

		; If the game is running
		invoke	GameRunning
		test	eax, eax
		; THEN we do nothing
		jnz		>.Return
		; ELSE pass to GameManager
		invoke	ActuatorPointInRect, [Game_pActuator], [xPos], [yPos]
		cmp		eax, -1
		je		>
		invoke	GameClickAt, eax, edx, 0
		:
	.Return:
		ret
ENDF

KeyRButtonUp:
	FRAME	hWnd, xPos, yPos
	USES	ebx,esi,edi
		#ifdef MOUSE_DEBUG
			mov		eax, ADDR <'RClick at (%d,%d)',0Dh,0Ah,0>
			writeln(eax, [xPos], [yPos])
		#endif

		; If the game is running
		invoke	GameRunning
		test	eax, eax
		; THEN we do nothing
		jnz		>.Return
		; ELSE pass to GameManager
		invoke	ActuatorPointInRect, [Game_pActuator], [xPos], [yPos]
		cmp		eax, -1
		je		>
		invoke	GameClickAt, eax, edx, 1
		:
	.Return:
		ret
ENDF