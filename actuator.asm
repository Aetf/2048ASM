#include "game.h"

	.CONST
lineWidth		DD	16
cellWidth		DD	105
fullCellWidth	DD	121
IDENTITY		XFORM	<1.0,0.0,0.0,1.0,0.0,0.0>
; Colors
colorBg			DD	RGB(187,173,160),\
					RGB(205,192,180)

colorCellBg		DD	RGB(0EEh, 0E4h, 0DAh),\ ; 2
					RGB(0EDh, 0E0h, 0C8h),\ ; 4
					RGB(0F2h, 0B1h, 79h),\ ; 8
					RGB(0F5h, 95h, 63h),\ ; 16
					RGB(0F6h, 7Ch, 5Fh),\ ; 32
					RGB(0F6h, 5Eh, 3Bh),\ ; 64
					RGB(0EDh, 0CFh, 72h),\ ; 128
					RGB(0EDh, 0CCh, 61h),\ ; 256
					RGB(0EDh, 0C8h, 50h),\ ; 512
					RGB(0EDh, 0C5h, 3Fh),\ ; 1024
					RGB(0EDh, 0C2h, 2Eh) ; 2048
colorCellFg		DD	RGB(77h, 6Eh, 65h),\ ; 2
					RGB(77h, 6Eh, 65h),\ ; 4
					RGB(0F9h, 0F6h, 0F2h),\ ; 8
					RGB(0F9h, 0F6h, 0F2h),\ ; 16
					RGB(0F9h, 0F6h, 0F2h),\ ; 32
					RGB(0F9h, 0F6h, 0F2h),\ ; 64
					RGB(0F9h, 0F6h, 0F2h),\ ; 128
					RGB(0F9h, 0F6h, 0F2h),\ ; 256
					RGB(0F9h, 0F6h, 0F2h),\ ; 512
					RGB(0F9h, 0F6h, 0F2h),\ ; 1024
					RGB(0F9h, 0F6h, 0F2h) ; 2048
; Font
fontFamily		DB	'Clear Sans', 0
fontSizeCell	DD	75, 75, \ ; 2, 4
					75, 75, \ ; 8, 16
					75, 75, \ ; 32, 64
					65, 65, \ ; 128, 256
					65, 55, \ ; 512, 1024
					55		  ; 2048
fontSizeScore		DD  20
fontSizeScoreTitle	DD	30
fontSizeMessage		DD	85

// Static datas
	.DATA
__actuator_static	DB	0
hBrushBg		DD	SIZEOF(colorBg)/4 dup ?
hBrushCellBg	DD	SIZEOF(colorCellBg)/4 dup ?
hBrushCellFg	DD	SIZEOF(colorCellFg)/4 dup ?

fontCell		DD	SIZEOF(fontSizeCell)/4 dup ?
fontScoreTitle	DD	?
fontScore		DD	?
fontMessage		DD	?

cellContents	DD	11 dup ?
msgContents		DD	3	dup ?

	.CODE
ActuatorStaticConstruct:
	FRAME
	USES	ebx,esi,edi
	LOCALS	logFont:LOGFONT
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered ActuatorStaticConstruct()',0Dh,0Ah,0>
		writeln(eax)
		#endif

		mov		al, [__actuator_static]
		test	al, al
		jnz		>>.return
	; Create background brushes
		mov		esi, ADDR colorBg
		mov		edi, ADDR hBrushBg
		mov		ecx, SIZEOF(hBrushBg)/4
	:
		push	ecx
		invoke	CreateSolidBrush, [esi + 4*ecx - 4]
		pop		ecx
		mov		[edi + 4*ecx - 4], eax
		loop	<
	; Create cell background brushes
		mov		esi, ADDR colorCellBg
		mov		edi, ADDR hBrushCellBg
		mov		ecx, SIZEOF(hBrushCellBg)/4
	:
		push	ecx
		invoke	CreateSolidBrush, [esi + 4*ecx - 4]
		pop		ecx
		mov		[edi + 4*ecx - 4], eax
		loop	<
	; Create cell foreground brushes
		mov		esi, ADDR colorCellFg
		mov		edi, ADDR hBrushCellFg
		mov		ecx, SIZEOF(hBrushCellFg)/4
	:
		push	ecx
		invoke	CreateSolidBrush, [esi + 4*ecx - 4]
		pop		ecx
		mov		[edi + 4*ecx - 4], eax
		loop	<
	; Create cell font
		mov		D[logFont.lfWidth], 0
		mov		D[logFont.lfEscapement], 0
		mov		D[logFont.lfOrientation], 0
		mov		D[logFont.lfWeight], FW_BOLD
		mov		B[logFont.lfItalic], FALSE
		mov		B[logFont.lfUnderline], FALSE
		mov		B[logFont.lfStrikeOut], FALSE
		mov		B[logFont.lfCharSet], DEFAULT_CHARSET
		mov		B[logFont.lfOutPrecision], OUT_DEFAULT_PRECIS
		mov		B[logFont.lfClipPrecision], CLIP_DEFAULT_PRECIS
		mov		B[logFont.lfQuality], DEFAULT_QUALITY
		mov		B[logFont.lfPitchAndFamily], FF_DONTCARE | DEFAULT_PITCH
		invoke	MemCpy, ADDR logFont.lfFaceName, ADDR fontFamily, SIZEOF(fontFamily)
		
		mov		esi, ADDR fontSizeCell
		mov		edi, ADDR fontCell
		mov		ecx, SIZEOF(fontSizeCell)/4
	:
		mov		eax, [esi + 4*ecx -4]
		mov		D[logFont.lfHeight], eax
		push	ecx
		invoke	CreateFontIndirect, ADDR logFont
		pop		ecx
		mov		[edi + 4*ecx - 4], eax
		loop	<
	; Create scoreboard font
		mov		eax, [fontSizeScore]
		mov		D[logFont.lfHeight], eax
		invoke	CreateFontIndirect, ADDR logFont
		mov		[fontScore], eax

		mov		eax, [fontSizeScoreTitle]
		mov		D[logFont.lfHeight], eax
		invoke	CreateFontIndirect, ADDR logFont
		mov		[fontScoreTitle], eax
	; Create message font
		mov		eax, [fontSizeMessage]
		mov		D[logFont.lfHeight], eax
		invoke	CreateFontIndirect, ADDR logFont
		mov		[fontMessage], eax
	; Initialize message content table
		mov		edi, ADDR msgContents
		xor		ecx, ecx

		mov		eax, ADDR <0>
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR <'You win!!', 0>
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR <'Game over!!', 0>
		mov		D[edi + 4*ecx], eax
	; Initialize cell content table
		mov		edi, ADDR cellContents
		xor		ecx, ecx

		mov		eax, ADDR '2'
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR '4'
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR '8'
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR '16'
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR '32'
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR '64'
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR '128'
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR '256'
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR '512'
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR '1024'
		mov		D[edi + 4*ecx], eax
		inc		ecx
		mov		eax, ADDR '2048'
		mov		D[edi + 4*ecx], eax

	; Set flag
		mov		B[__actuator_static], 1
	.return:
		ret
ENDF

ActuatorStaticDeconstruct:
	FRAME
	USES	ebx,esi,edi
	LOCALS	__fix	; due to a goasm bug
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered ActuatorStaticDeconstruct()',0Dh,0Ah,0>
		writeln(eax)
		#endif

		mov		al, [__actuator_static]
		test	al, al
		jz		>>.return

		mov		esi, ADDR hBrushBg
		mov		ecx, SIZEOF(hBrushBg)/4
	:
		push	ecx
		invoke	DeleteObject, [esi + 4*ecx - 4]
		pop		ecx
		loop	<

		mov		esi, ADDR hBrushCellBg
		mov		ecx, SIZEOF(hBrushCellBg)/4
	:
		push	ecx
		invoke	DeleteObject, [esi + 4*ecx - 4]
		pop		ecx
		loop	<

		mov		esi, ADDR hBrushCellFg
		mov		ecx, SIZEOF(hBrushCellFg)/4
	:
		push	ecx
		invoke	DeleteObject, [esi + 4*ecx - 4]
		pop		ecx
		loop	<

		mov		esi, ADDR fontCell
		mov		ecx, SIZEOF(fontCell)/4
	:
		push	ecx
		invoke	DeleteObject, [esi + 4*ecx - 4]
		pop		ecx
		loop	<

		invoke	DeleteObject, [fontScore]
		invoke	DeleteObject, [fontScoreTitle]
		invoke	DeleteObject, [fontMessage]

		mov		B[__actuator_static], 0
	.return:
		ret
ENDF

ActuatorConstruct:
	FRAME	pActuator, hWndGrid, hWndScore, animResolution
	USES	ebx,esi,edi
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered ActuatorConstruct(pActuator=%X,hWndGrid=%X,hWndScore=%X,animReso=%d)',0Dh,0Ah,0>
		writeln(eax, [pActuator], [hWndGrid], [hWndScore], [animResolution])
		#endif

		invoke	ActuatorStaticConstruct

		mov		esi, [pActuator]

		mov		eax, [hWndGrid]
		mov		[esi + CWinActuator.hWndGrid], eax

		mov		eax, [hWndScore]
		mov		[esi + CWinActuator.hWndScore], eax

		mov		eax, [animResolution]
		mov		[esi + CWinActuator.animResolution], eax

		mov		B[esi + CWinActuator.animating], 0

		mov		D[esi + CWinActuator.pCurrSnap], 0

		mov		D[esi + CWinActuator.dwScore], 0
		mov		D[esi + CWinActuator.dwFlgMsg], MESSAGE_FLAG_NONE

		ret
ENDF

ActuatorDeconstruct:
	FRAME	pActuator
	USES	ebx,esi,edi
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered ActuatorDeconstruct(pActuator=%X)',0Dh,0Ah,0>
		writeln(eax, [pActuator])
		#endif

		mov		esi, [pActuator]
		invoke	DeleteCDispSnapshot, [esi + CWinActuator.pCurrSnap]

		ret
ENDF

// Set current snapshot to pNewSnap, update window, delete the old one
ActuatorSwapAndUpdate:
	FRAME	pActuator, pNewSnap
	USES	ebx,esi,edi
	LOCALS	pOldSnap
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered ActuatorSwapAndUpdate(pActuator=%X,pNewSnap=%X)',0Dh,0Ah,0>
		writeln(eax, [pActuator], [pNewSnap])
		#endif

		mov		esi, [pActuator]
		mov		eax, [esi + CWinActuator.pCurrSnap]
		mov		[pOldSnap], eax
		mov		edx, [pNewSnap]
		mov		[esi + CWinActuator.pCurrSnap], edx
		invoke	InvalidateRect, [esi + CWinActuator.hWndGrid], NULL, FALSE
		invoke	UpdateWindow, [esi + CWinActuator.hWndGrid]
		invoke	DeleteCDispSnapshot, [pOldSnap]
		ret
ENDF

// Draw the given snapshot on screen
ActuatorDraw:
	FRAME	pActuator, hDC, pDispSnap, score, flgmsg
	USES	ebx,esi,edi
		#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered ActuatorDraw(pActuator=%X,hDC=%X,pDispSnap=%X)',0Dh,0Ah,0>
		writeln(eax, [pActuator], [hDC], [pDispSnap])
		#endif

		// if (pDispSnap == NULL) return;
		mov		eax, [pDispSnap]
		test	eax, eax
		jz		>>.Return


		mov		esi, [pActuator]
	// Draw grid
		// setups
		invoke	SaveDC, [hDC]
		invoke	SetGraphicsMode, [hDC], GM_ADVANCED
		invoke	SetBkMode, [hDC], TRANSPARENT
		// draw background
		invoke	DrawGridBackground, [hDC], [pDispSnap]
		// draw tiles
		invoke	DrawTiles, [hDC], [pDispSnap]
		// clean up
		invoke	RestoreDC, [hDC], -1
		

	// Draw scoreboard
		
		// setups
		invoke	SaveDC, [hDC]
		invoke	SetGraphicsMode, [hDC], GM_ADVANCED
		invoke	SetBkMode, [hDC], TRANSPARENT
		// draw
		invoke	DrawScoreboard, [hDC], [score]
		// clean up
		invoke	RestoreDC, [hDC], -1
		
	// Draw message
		// setups
		invoke	SaveDC, [hDC]
		invoke	SetGraphicsMode, [hDC], GM_ADVANCED
		invoke	SetBkMode, [hDC], TRANSPARENT
		// draw
		invoke	DrawMessage, [hDC], [flgmsg]
		// clean up
		invoke	RestoreDC, [hDC], -1
	.Return
		ret
ENDF

// Render a grid to a snapshot
// returns a new dispSnapshot, which need to be deleted explicitly
ActuatorRenderGrid:
	FRAME	pActuator, pGrid
	USES	ebx,esi,edi
	LOCALS	pDispSnap
		#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered ActuatorRenderGrid(pActuator=%X,pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pActuator], [pGrid])
		#endif

		invoke	NewCDispSnapshot
		mov		[pDispSnap], eax
		mov		esi, eax
		// set grid position
		mov		D[esi + CDispSnapshot.gridRect + RECT.left], 0
		mov		D[esi + CDispSnapshot.gridRect + RECT.top], 70
		mov		D[esi + CDispSnapshot.gridRect + RECT.right], 500
		mov		D[esi + CDispSnapshot.gridRect + RECT.bottom], 570
		// foreach tile in pGrid->cells
		invoke	GridEachTile, [pGrid], ADDR RenderGrid_CallBack, [pDispSnap]

		mov		eax, esi
		ret
ENDF

// Render a disp transition to a snapshot
// returns a new CDispSnapshot, which need to be deleted explicitly
// CDispTransition*  pTransition: the transition to render
// nowtick: the passed millionseconds of the animation
ActuatorRenderTransition:
	FRAME	pActuator, pTransition, nowtick
	USES	ebx,esi,edi
	LOCALS	pDispSnap, parameter[2]:D
		#ifdef TRANSITION_DEBUG
		mov		eax, ADDR <'Entered ActuatorRenderTransition(pActuator=%X,pTransition=%X,nowtick=%d)',0Dh,0Ah,0>
		writeln(eax, [pActuator], [pTransition], [nowtick])
		#endif

		invoke	NewCDispSnapshot
		mov		[pDispSnap], eax
		mov		esi, eax
		// set grid position
		mov		D[esi + CDispSnapshot.gridRect + RECT.left], 0
		mov		D[esi + CDispSnapshot.gridRect + RECT.top], 70
		mov		D[esi + CDispSnapshot.gridRect + RECT.right], 500
		mov		D[esi + CDispSnapshot.gridRect + RECT.bottom], 570

		mov		edi, ADDR parameter
		mov		eax, [nowtick]
		mov		[edi], eax
		mov		eax, [pDispSnap]
		mov		[edi + 4], eax

		invoke	CDispTransitionEachAnimTile, [pTransition], \
								ADDR RenderTransition_Callback, \
								edi

		mov		eax, esi
		ret
ENDF

// Create a new disp transition according to the state of pGrid
// Return a new CDispTransition, which must be deleted explicitly
ActuatorCreateTransition:
	FRAME	pActuator, pGrid
	USES	ebx,esi,edi
	LOCALS	pTransition
		#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered ActuatorCreateTransition(pActuator=%X,pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pActuator],[pGrid])
		#endif

		invoke	NewCDispTransition
		mov		[pTransition], eax
		mov		esi, eax
		// render a target snapshot for acuracy
		invoke	ActuatorRenderGrid, [pActuator], [pGrid]
		mov		[esi + CDispTransition.pTargetSnap], eax

		#ifdef ANIMATION_DEBUG5
		pusha
		mov		eax, ADDR <'     Created target snapshot:',0Dh,0Ah,0>
		writeln(eax)
		invoke	CDispSnapshotWriteln, [esi + CDispTransition.pTargetSnap]
		writeln()
		popa
		#endif

		// determine each tile's animation parameters
		invoke	GridEachTile, [pGrid], ADDR CreateTransition_Callback, [pTransition]

		mov		eax, [pTransition]
		ret
ENDF

// Actuate ui after the grid has any changes
ActuatorDoActuate:
	FRAME	pActuator, pGrid, nSocre, bOver, bWon
	USES	ebx,esi,edi
	LOCALS	pOldSnap
	#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered ActuatorDoActuate(pActuator=%X,pGrid=%X,nSocre=%d,bOver=%X,bWon=%X)',0Dh,0Ah,0>
		writeln(eax, [pActuator], [pGrid], [nSocre], [bOver], [bWon])
		mov		eax, ADDR <'Before DoActuate:',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
	#endif

		// Test if we are animating, if so, do nothing
		mov		esi, [pActuator]
		mov		eax, [esi + CWinActuator.animating]
		test	eax, eax
		jz		>
		ret
		:

		// Update score
		mov		eax, [nSocre]
		mov		[esi + CWinActuator.dwScore], eax
		// Update message state
		xor		edx, edx
		mov		al, B[bOver]
		test	al, al
		jz		>
		mov		edx, MESSAGE_FLAG_OVER
		:
		mov		al, B[bWon]
		test	al, al
		jz		>
		mov		edx, MESSAGE_FLAG_WIN
		:
		mov		[esi + CWinActuator.dwFlgMsg], edx

	.doanimation:
	#ifndef NO_TRANSITION

		#ifdef TRANSITION_DEBUG
				mov		eax, ADDR <'Before CreateTransition,pGrid:',0Dh,0Ah,0>
				writeln(eax)
				invoke	GridWriteln, [pGrid]
		#endif
	
		// delete previous transition and create new transition
		invoke	DeleteCDispTransition, [esi + CWinActuator.pTransition]
		invoke	ActuatorCreateTransition, [pActuator], [pGrid]
		mov		[esi + CWinActuator.pTransition], eax

		#ifdef TRANSITION_DEBUG
				mov		eax, ADDR <'After CreateTransition,pGrid:',0Dh,0Ah,0>
				writeln(eax)
				invoke	GridWriteln, [pGrid]
		#endif

		// animating = true
		mov		B[esi + CWinActuator.animating], 1

		// start animation timer
		invoke	GetTickCount
		mov		D[esi + CWinActuator.timestamp], eax
		mov		D[esi + CWinActuator.hTimer], ACTUATOR_TIMER
		invoke	SetTimer, [esi + CWinActuator.hWndGrid], \
							[esi + CWinActuator.hTimer], \
							10, NULL
		/*
		invoke	CreateTimerQueueTimer, eax, NULL, \
								ADDR ActuatorOnTimer, [pActuator], \
								0, [esi + CWinActuator.animResolution], \
								WT_EXECUTEDEFAULT
		*/
	#else
		invoke	ActuatorAnimComplete, [pActuator]
	#endif

	.return:
		
	#ifdef ACTUATOR_DEBUG
		pusha
		mov		eax, ADDR <'After DoActuate:',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		mov		eax, ADDR <'**********************************',0Dh,0Ah,0>
		writeln(eax)
		popa
	#endif

		ret
ENDF

ActuatorAnimComplete:
	FRAME	pActuator
	USES	ebx,esi,edi
		#ifdef ANIMATION_DEBUG5
		pusha
		mov		esi, [pActuator]
		mov		edi, [esi + CWinActuator.pTransition]
		mov		ebx, [edi + CDispTransition.pTargetSnap]
		mov		eax, ADDR <'Entered ActuatorAnimComplete(pActuator=%X) pTargetSnap=%X',0Dh,0Ah,0>
		writeln(eax, [pActuator], ebx)
		popa
		#endif

		// draw target snapshot
		mov		esi, [pActuator]
		mov		edi, [esi + CWinActuator.pTransition]
		mov		eax, [edi + CDispTransition.pTargetSnap]
		mov		D[edi + CDispTransition.pTargetSnap], 0
		invoke	ActuatorSwapAndUpdate, [pActuator], eax

		mov		B[esi + CWinActuator.animating], 0
		ret
ENDF

ActuatorOnTimer:
	FRAME	pActuator
	USES	ebx,esi,edi
	LOCALS	pTransition, nowtick, progress
		// extract parameter
		mov		esi, [pActuator]
		mov		edi, [esi + CWinActuator.pTransition]
		mov		[pTransition], edi

		#ifdef TRANSITION_DEBUG
		mov		eax, ADDR <'Entered ActuatorOnTimer(pActuator=%X) pTransition=%X',0Dh,0Ah,0>
		writeln(eax, [pActuator], [pTransition])
		#endif

		// check if we should end
		invoke	GetTickCount
		sub		eax, [esi + CWinActuator.timestamp]
		mov		[nowtick], eax
		cmp		[edi + CDispTransition.endTime], eax
		jb		>.endtimer
		// render transition
		; calculate progress
		invoke	ActuatorRenderTransition, esi, edi, [nowtick]
		invoke	ActuatorSwapAndUpdate, esi, eax
		// return
		jmp		>.return

	.endtimer:
		invoke	PostMessage, [esi + CWinActuator.hWndGrid], WM_KILLTIMER, 0, 0
		invoke	GetLastError
	.return:
		ret
ENDF

// Handle WM_PAINT message
// always draw according to current disp snapshot
ActuatorOnPaint:
	FRAME	pActuator, hDC
	USES	ebx,esi,edi
		#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered ActuatorOnPaint(pActuator=%X,hDC=%X)',0Dh,0Ah,0>
		writeln(eax, [pActuator], [hDC])
		#endif

		mov		esi, [pActuator]
		invoke	ActuatorDraw, [pActuator], [hDC], \
								[esi + CWinActuator.pCurrSnap], \
								[esi + CWinActuator.dwScore], \
								[esi + CWinActuator.dwFlgMsg]
		ret
ENDF

ActuatorKillTimer:
	FRAME	pActuator
	USES	ebx,esi,edi
	LOCALS	pOldSnap
		#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered ActuatorKillTimer(pActuator=%X)',0Dh,0Ah,0>
		writeln(eax, [pActuator])
		#endif

		mov		esi, [pActuator]
		// kill timer
		invoke	KillTimer, [esi + CWinActuator.hWndGrid], [esi + CWinActuator.hTimer]
		;invoke	DeleteTimerQueueTimer, NULL, [esi + CWinActuator.hTimer], INVALID_HANDLE_VALUE
		
		// animation complete
		invoke	ActuatorAnimComplete, [pActuator]
		ret
ENDF

// Given a (x,y) in client coordinate
// return the grid idx in edx:eax
// edx=y
// eax=x
ActuatorPointInRect:
	FRAME	pActuator, xPos, yPos
	USES	ebx,esi,edi
	LOCALS	rect:RECT, idxX, idxY
		mov		D[idxX], -1
		mov		D[idxY], -1

		mov		esi, [pActuator]
		mov		edi, [esi + CWinActuator.pCurrSnap]
		add		edi, CDispSnapshot.gridRect

		mov		ecx, Grid_Size
	.l2:
		mov		ebx, ecx
		dec		ebx
		mov		ecx, Grid_Size
	.l1:
		push	ecx
		dec		ecx
		invoke	CalcCellRect, edi, \	; pGridRect
							  ebx, ecx, \	; posx, posy
							  ADDR rect
		
		push	ecx
		invoke	PtInRect, ADDR rect, [xPos], [yPos]
		pop		ecx
		test	eax, eax
		jz		>
		mov		D[idxX], ebx
		mov		D[idxY], ecx
		jmp		>.break
		:

		pop		ecx
		loop	<.l1
		inc		ebx
		mov		ecx, ebx
		loop	<.l2
	.break:

		mov		eax, [idxX]
		mov		edx, [idxY]
		ret
ENDF


; Calculate a Rect
CalcCellRect:
	FRAME	pGridRect, posX, posY, pResRect
	USES	ebx,esi,edi
		#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered CalcCellRect(pGridRect=%X,posX=%d,posY=%d,pResRect=%X)',0Dh,0Ah,0>
		writeln(eax, [pGridRect], [posX], [posY], [pResRect])
		#endif

		mov		esi, [pGridRect]
		mov		edi, [pResRect]

		mov		eax, [fullCellWidth]
		mul		D[posX]
		add		eax, [lineWidth]
		add		eax, [esi + RECT.top]
		mov		[edi + RECT.top], eax

		add		eax, [cellWidth]
		mov		[edi + RECT.bottom], eax

		mov		eax, [fullCellWidth]
		mul		D[posY]
		add		eax, [lineWidth]
		add		eax, [esi + RECT.left]
		mov		[edi + RECT.left], eax

		add		eax, [cellWidth]
		mov		[edi + RECT.right], eax

		ret
ENDF

// Draw grid background on given gridrect
// hDC: a configured DC to draw on
DrawGridBackground:
	FRAME	hDC, pDispSnap
	USES	ebx,esi,edi
	LOCALS	rect:RECT
		#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered DrawGridBackground(hDC=%X,pDispSnap=%X)',0Dh,0Ah,0>
		writeln(eax, [hDC], [pDispSnap])
		#endif

	// Setups
		mov		esi, [pDispSnap]
		add		esi, CDispSnapshot.gridRect
		invoke	GetStockObject, NULL_PEN
		invoke	SelectObject, [hDC], eax

	// Background
		invoke	SelectObject, [hDC], [hBrushBg]
		invoke	RoundRect, [hDC], \
				[esi + RECT.left], [esi + RECT.top], \
				[esi + RECT.right], [esi + RECT.bottom], \
				15, 15

	// Cells background
		invoke	SelectObject, [hDC], [hBrushBg+4]

		mov		ecx, Grid_Size
	.l2:
		mov		ebx, ecx
		dec		ebx
		mov		ecx, Grid_Size
	.l1:
		push	ecx
		dec		ecx
		invoke	CalcCellRect, esi, \	; pGridRect
							  ebx, ecx, \	; posx, posy
							  ADDR rect
									
		invoke	RoundRect, [hDC], \
				[rect.left], [rect.top], \
				[rect.right], [rect.bottom], \
				5, 5
		pop		ecx
		loop	<.l1
		inc		ebx
		mov		ecx, ebx
		loop	<.l2

		ret
ENDF

// Draw tiles in the snapshot
// hDC: a configured DC to draw on
DrawTiles:
	FRAME	hDC, pDispSnap
	USES	ebx,esi,edi
		#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered DrawTiles(hDC=%X,pDispSnap=%X)',0Dh,0Ah,0>
		writeln(eax, [hDC], [pDispSnap])
		#endif

		mov		edi, [pDispSnap]
		add		edi, CDispSnapshot.dispTiles

		invoke	CDispSnapshotEachDispTile, [pDispSnap], \
											ADDR DrawSingleTile, \
											[hDC]
		
		#ifdef ACTUATOR_DEBUG
		pusha
		mov		eax, ADDR <'DrawTiles done',0Dh,0Ah,0>
		writeln(eax, [hDC], [pDispSnap])
		popa
		#endif
		ret
ENDF

// Draw a single tile on given DC
DrawSingleTile:
	FRAME	pDispTile, hDC
	USES	ebx,esi,edi
	LOCALS	value, fgcolor, font, content
		#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered DrawSingleTile(pDispTile=%X,hDC=%X)',0Dh,0Ah,0>
		writeln(eax, [pDispTile], [hDC])
		mov		eax, ADDR <'        with CDispTile:',0>
		writeln(eax)
		invoke	CDispTileWriteln, [pDispTile]
		#endif

		; local variables
		mov		esi, [pDispTile]
		mov		edi, esi
		add		edi, CDispTile.rect
		mov		eax, [esi + CDispTile.value]
		mov		[value], eax
		mov		esi, ADDR colorCellFg
		mov		ebx, [esi + 4*eax]
		mov		[fgcolor], ebx
		mov		esi, ADDR fontCell
		mov		ebx, [esi + 4*eax]
		mov		[font], ebx
		mov		esi, ADDR cellContents
		mov		ebx, [esi + 4*eax]
		mov		[content], ebx

		; Set background
		mov		esi, ADDR hBrushCellBg
		invoke	SelectObject, [hDC], [esi + 4*eax]
		; draw background
		invoke	RoundRect, [hDC], \
				[edi + RECT.left], [edi + RECT.top], \
				[edi + RECT.right], [edi + RECT.bottom], \
				5, 5
		
		; Set foreground
		invoke	SetTextColor, [hDC], [fgcolor]
		; Set font
		invoke	SelectObject, [hDC], [font]
		; draw text
		invoke	DrawText, [hDC], [content], -1, \
				edi, DT_CENTER | DT_VCENTER | DT_SINGLELINE
		
		mov		eax, 1  // return true to continue
		ret
ENDF

DrawScoreboard:
	FRAME	hDC, score
	USES	ebx,esi,edi
	LOCALS	rc:RECT, scoreBuf[12]:D
		; Setups
		invoke	GetStockObject, NULL_PEN
		invoke	SelectObject, [hDC], eax
		; Set background
		mov		esi, ADDR hBrushBg
		invoke	SelectObject, [hDC], [esi]
		; draw background
		invoke	RoundRect, [hDC], \
				20, 10, \  ; left, top
				90, 64, \ ; right, bottom
				5, 5
		
		; Set foreground
		invoke	SetTextColor, [hDC], RGB(0EEh, 0E4h, 0DAh)
		; Set font
		invoke	SelectObject, [hDC], [fontScoreTitle]
		; text rect
		mov		D[rc.left], 20
		mov		D[rc.top], 10
		mov		D[rc.right], 90
		mov		D[rc.bottom], 64
		; draw title
		invoke	DrawText, [hDC], ADDR <'Score', 0> , -1, \
				ADDR rc, DT_CENTER | DT_TOP | DT_SINGLELINE
		; draw score
		invoke	sprintf,ADDR scoreBuf, ADDR <'%d',0>, [score]
		add		esp, 0Ch

		invoke	SetTextColor, [hDC], RGB(255, 255, 255)
		invoke	DrawText, [hDC], ADDR scoreBuf , -1, \
				ADDR rc, DT_CENTER | DT_BOTTOM | DT_SINGLELINE
		ret
ENDF

DrawMessage:
	FRAME	hDC, flgmsg
	USES	ebx,esi,edi
	LOCALS	rc:RECT
		; Setups
		invoke	GetStockObject, NULL_PEN
		invoke	SelectObject, [hDC], eax
		
		; Set foreground
		invoke	SetTextColor, [hDC], RGB(077h, 06Eh, 065h)
		; Set font
		invoke	SelectObject, [hDC], [fontMessage]
		; text rect
		mov		D[rc.left], 100
		mov		D[rc.top], 10
		mov		D[rc.right], 480
		mov		D[rc.bottom], 64

		; draw title
		mov		eax, [flgmsg]
		mov		esi, ADDR msgContents
		invoke	DrawText, [hDC], [esi + 4*eax] , -1, \
				ADDR rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE
		ret
ENDF

RenderGrid_CallBack:
	FRAME	posx, posy, pTile, pParameter ; pParameter = pDispSnap
	USES	ebx,esi,edi
	LOCALS	pDispTile
		#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered RenderGrid_CallBack(posx=%d,posy=%d,pTile=%X,pDispSnap=%X)',0Dh,0Ah,0>
		writeln(eax, [posx], [posy], [pTile], [pParameter])
		#endif

		mov		esi, [pTile]
		test	esi, esi
		jz		>.return
		// pDispTile = new CDispTile();
		invoke	NewCDispTile
		mov		[pDispTile], eax
		// pDispTile->rect = CalcCellRect(pDispSnap->gridRect, posx, posy)
		mov		edi, [pParameter]
		add		edi, CDispSnapshot.gridRect
		add		eax, CDispTile.rect
		invoke	CalcCellRect, edi, \
							[posx], [posy], \
							eax
		// pDispTile->value = pTile->value
		mov		eax, [esi + TILE.value]
		mov		esi, [pDispTile]
		mov		[esi + CDispTile.value], eax
		// pDispSnap->AppendTile(pDispTile)
		mov		edi, [pParameter]
		invoke	CDispSnapshotAppendTile, edi, esi
	.return:
		ret
ENDF

RenderTransition_Callback:
	FRAME	pTile, pMeta, pParameter  // pParameter[0] = nowtick, pParameter[1] = pDispSnap
	USES	ebx,esi,edi
	LOCALS	nowtick, pDispSnap, \ // parameters
			progress, \ // FLOAT, between 0 and 1
			duration, \
			pDispTile, rect1:RECT, rect2:RECT
		// extract parameters
		mov		esi, [pParameter]
		mov		eax, [esi]
		mov		[nowtick], eax
		mov		eax, [esi + 4]
		mov		[pDispSnap], eax

		#ifdef ANIMATION_DEBUG2
		mov		esi, [pMeta]
		mov		eax, ADDR <'Entered RenderTransition_Callback(pTile=%X,pMeta=%X,pParameter=%X) nowtick=%f,animType=%X)',0Dh,0Ah,0>
		writeln(eax, [pTile], [pMeta], [pParameter], [nowtick], [esi + CAnimMeta.type])
		#endif

		// calc progress
		mov		esi, [pMeta]
		mov		eax, [esi + CAnimMeta.startTime]
		cmp		[nowtick], eax
		jbe		>>.notnow
		mov		ebx, [esi + CAnimMeta.endTime]
		cmp		[nowtick], ebx
		ja		>>.ended
		sub		[nowtick], eax
		mov		[duration], ebx
		sub		[duration], eax
		finit
		fild	D[duration]
		fild	D[nowtick]
		fdiv	st1
		fstp	D[progress]

	.switch_type:
		// switch pMeta->type
		mov		esi, [pMeta]
		mov		eax, [esi + CAnimMeta.type]
		cmp		eax, ANIMATION_TYPE_NONE
		je		>.none
		cmp		eax, ANIMATION_TYPE_ZOOM_IN_BOUNCE
		je		>.zoominbounce
		cmp		eax, ANIMATION_TYPE_ZOOM_IN
		je		>>.zoomin
		cmp		eax, ANIMATION_TYPE_TRANSLATION
		je		>>.trans
		jmp		>>.return

	.ended:
		// the animation has ended
		mov		esi, [pMeta]
		mov		eax, [esi + CAnimMeta.endBehavior]
		cmp		eax, ANIMATION_BEHAVIOR_KEEP_FINAL
		je		>.ended_keep
		cmp		eax, ANIMATION_BEHAVIOR_NOT_SHOW
		je		>.ended_none
		jmp		>>.return

		.ended_keep:
		finit
		fld1
		fstp	D[progress]
		jmp		<<.switch_type
		.ended_none:
		jmp		>>.return
	.notnow:
		// the animation should not begin yet
		jmp		>>.return
	.none:
		// pDispTile = new CDispTile();
		invoke	NewCDispTile
		mov		[pDispTile], eax
		add		eax, CDispTile.rect
		mov		esi, [pDispSnap]
		add		esi, CDispSnapshot.gridRect
		mov		edi, [pTile]
		// pDispTile->rect = CalcCellRect(&pDispSnap->gridRect, pTile->x, pTile->y)		
		invoke	CalcCellRect, esi, \
							[edi + TILE.x], [edi + TILE.y], \
							eax
		// pDispTile->value = pTile->value
		mov		edi, [pTile]
		mov		eax, [edi + TILE.value]
		mov		esi, [pDispTile]
		mov		[esi + CDispTile.value], eax
		// pDispSnap->AppendTile(pDispTile)
		invoke	CDispSnapshotAppendTile, [pDispSnap], [pDispTile]
		jmp		>>.return
	.zoominbounce:
		// pDispTile = new CDispTile();
		invoke	NewCDispTile
		mov		[pDispTile], eax
		// rect1 = CalcCellRect(&pDispSnap->gridRect, pTile->x, pTile->y)	
		mov		esi, [pDispSnap]
		add		esi, CDispSnapshot.gridRect
		mov		edi, [pTile]
		invoke	CalcCellRect, esi, \
							[edi + TILE.x], [edi + TILE.y], \
							ADDR rect1
		// calculate intermediate rect
		mov		esi, [pDispTile]
		add		esi, CDispTile.rect
		invoke	BounceRectScaleInterpolator, esi, ADDR rect1, [progress]
		// pDispTile->value = pTile->value
		mov		edi, [pTile]
		mov		eax, [edi + TILE.value]
		mov		esi, [pDispTile]
		mov		[esi + CDispTile.value], eax
		// pDispSnap->AppendTile(pDispTile)
		invoke	CDispSnapshotAppendTile, [pDispSnap], [pDispTile]
		jmp		>>.return
	.zoomin:
		// pDispTile = new CDispTile();
		invoke	NewCDispTile
		mov		[pDispTile], eax
		// rect1 = CalcCellRect(&pDispSnap->gridRect, pTile->x, pTile->y)	
		mov		esi, [pDispSnap]
		add		esi, CDispSnapshot.gridRect
		mov		edi, [pTile]
		invoke	CalcCellRect, esi, \
							[edi + TILE.x], [edi + TILE.y], \
							ADDR rect1
		// calculate intermediate rect
		mov		esi, [pDispTile]
		add		esi, CDispTile.rect
		invoke	LinearRectScaleInterpolator, esi, ADDR rect1, [progress]
		// pDispTile->value = pTile->value
		mov		edi, [pTile]
		mov		eax, [edi + TILE.value]
		mov		esi, [pDispTile]
		mov		[esi + CDispTile.value], eax
		// pDispSnap->AppendTile(pDispTile)
		invoke	CDispSnapshotAppendTile, [pDispSnap], [pDispTile]
		jmp		>>.return
	.trans:
		// pDispTile = new CDispTile();
		invoke	NewCDispTile
		mov		[pDispTile], eax
		mov		esi, [pDispSnap]
		add		esi, CDispSnapshot.gridRect
		mov		edi, [pMeta]
		// rect1 = CalcCellRect(pDispSnap->gridRect, (pMeta->fromPos).x, (pMeta->fromPos).y)
		invoke	CalcCellRect, esi, \
								[edi + CAnimMeta.fromPos + POS.x], \
								[edi + CAnimMeta.fromPos + POS.y], \
								ADDR rect1
		// rect2 = CalcCellRect(pDispSnap->gridRect, (pMeta->toPos).x, (pMeta->toPos).y)
		invoke	CalcCellRect, esi, \
								[edi + CAnimMeta.toPos + POS.x], \
								[edi + CAnimMeta.toPos + POS.y], \
								ADDR rect2
		mov		edi, [pDispTile]
		add		edi, CDispTile.rect
		// calculate intermediate rect
		invoke	LinearRectTranslationInterpolator, edi, ADDR rect1, ADDR rect2, [progress]
		// pDispTile->value = pTile->value
		mov		esi, [pTile]
		mov		edi, [pDispTile]
		mov		eax, [esi + TILE.value]
		mov		[edi + CDispTile.value], eax
		// pDispSnap->AppendTile(pDispTile)
		invoke	CDispSnapshotAppendTile, [pDispSnap], [pDispTile]
		jmp		>.return
	
	.return:
		ret
ENDF

CreateTransition_Callback:
	FRAME	posx, posy, pTile, pParameter ; pParameter = pTransition
	USES	ebx,esi,edi
	LOCALS	pTransition, pMeta, pMerged
		#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered CreateTransition_Callback(posx=%d,posy=%d,pTile=%X,pTransition=%X)',0Dh,0Ah,0>
		writeln(eax, [posx], [posy], [pTile], [pParameter])
		invoke	TileWriteln, [pTile]
		writeln()
		#endif

		mov		esi, [pTile]
		test	esi, esi
		jz		>>.return

		// extract parameters
		mov		eax, [pParameter]
		mov		[pTransition], eax

	.if: ; (pTile->mergedFrom != NULL)
		mov		eax, [esi + TILE.mergedFrom]
		test	eax, eax
		jz		>>.elif1

		#ifdef ACTUATOR_DEBUG
			mov		eax, ADDR <'    CreateTransition_Callback: Tile: ',0>
			writeln(eax)
			invoke	TileWriteln, esi
			writeln()
			mov		eax, ADDR <'                               merged from',0>
			writeln(eax)
			invoke	TileWriteln, [esi + TILE.mergedFrom]
			writeln()
			invoke	TileWriteln, [esi + TILE.mergedFrom+4]
			writeln()
		#endif

		// pTile->mergedFrom[0], translation
		invoke	CAnimMetaFromMovedTile, [esi + TILE.mergedFrom], \
										ANIMATION_TYPE_TRANSLATION, \
										0, TRANS_DURA ; start, duration
		mov		[pMeta], eax
		mov		D[eax + CAnimMeta.endBehavior], ANIMATION_BEHAVIOR_NOT_SHOW
		; clone the tile
		invoke	TileClone, [esi + TILE.mergedFrom]
		; append to transition
		invoke	CDispTransitionAppendAnimTile, [pTransition], \
											eax, [pMeta]

		// pTile->mergedFrom[1], translation
		invoke	CAnimMetaFromMovedTile, [esi + TILE.mergedFrom + 4], \
										ANIMATION_TYPE_TRANSLATION, \
										0, TRANS_DURA ; start, duration
		mov		[pMeta], eax
		mov		D[eax + CAnimMeta.endBehavior], ANIMATION_BEHAVIOR_NOT_SHOW
		; clone the tile
		invoke	TileClone, [esi + TILE.mergedFrom + 4]
		; append to transition
		invoke	CDispTransitionAppendAnimTile, [pTransition], \
											eax, [pMeta]

		// pTile, bounce in
		invoke	CAnimMetaFromNoMoveTile, esi, \
										ANIMATION_TYPE_ZOOM_IN_BOUNCE, \
										TRANS_DURA, MERGE_DURA ; start, duration
		mov		[pMeta], eax
		; clone the tile
		invoke	TileClone, esi
		; append to transition
		invoke	CDispTransitionAppendAnimTile, [pTransition], \
											eax, [pMeta]
		jmp		>>.endif
	.elif1: ; (pTile->previousPos.x == -1)
		mov		eax, [esi + TILE.previousPos + POS.x]
		cmp		eax, -1
		jne		>.elif2

		#ifdef ACTUATOR_DEBUG
			mov		eax, ADDR <'    CreateTransition_Callback: Tile:%X new created with value %d',0Dh,0Ah,0>
			writeln(eax, esi, [esi+TILE.value])
		#endif

		// pTile, zoom in
		invoke	CAnimMetaFromNoMoveTile, esi, \
										ANIMATION_TYPE_ZOOM_IN, \
										TRANS_END, NEW_DURA ; start, duration
		mov		[pMeta], eax
		; clone the tile
		invoke	TileClone, esi
		; append to transition
		invoke	CDispTransitionAppendAnimTile, [pTransition], \
											eax, [pMeta]
		jmp		>>.endif
	.elif2: ; (pTile->x == pTile->previousPos.x && pTile->y == pTile->previousPos.y)
		mov		eax, [esi + TILE.previousPos + POS.x]
		mov		edx, [esi + TILE.x]
		cmp		eax, edx
		jne		>.else
		mov		eax, [esi + TILE.previousPos + POS.y]
		mov		edx, [esi + TILE.y]
		cmp		eax, edx
		jne		>.else

		#ifdef ACTUATOR_DEBUG
			mov		eax, ADDR <'    CreateTransition_Callback: Tile:%X untouched',0Dh,0Ah,0>
			writeln(eax, esi)
		#endif

		// ptile, none
		invoke	CAnimMetaFromNoMoveTile, esi, \
										ANIMATION_TYPE_NONE, \
										0, 0 ; start, duration
		mov		[pMeta], eax
		; clone the tile
		invoke	TileClone, esi
		; append to transition
		invoke	CDispTransitionAppendAnimTile, [pTransition], \
											eax, [pMeta]
		jmp		>.endif
	.else:

		#ifdef ACTUATOR_DEBUG
			mov		eax, ADDR <'    CreateTransition_Callback: Tile:%X moved from (%d,%d) to (%d,%d)',0Dh,0Ah,0>
			writeln(eax, esi, [esi+TILE.previousPos + POS.x], [esi+TILE.previousPos + POS.x], [esi+TILE.x], [esi+TILE.y])
		#endif

		// ptile, translation
		invoke	CAnimMetaFromMovedTile, esi, \
										ANIMATION_TYPE_TRANSLATION, \
										0, TRANS_DURA ; start, duration
		mov		[pMeta], eax
		; clone the tile
		invoke	TileClone, esi
		; append to transition
		invoke	CDispTransitionAppendAnimTile, [pTransition], \
											eax, [pMeta]
	.endif:

	.return:
		ret
ENDF