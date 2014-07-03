#include "game.h"

	.DATA
Game_pActuator	DD  ?
Game_pGrid		DD	?
Game_pAI		DD	?
// Sounds related
Game_pSECtrl	DD  ?
Game_pBGMCtrl	DD  ?
// Game state
Game_Score		DD	?
Game_Won		DB	?
Game_Over		DB	?
Game_Wait_Add_Tile	DB	?
Game_Thinking	DB	?
// Game options
Game_Mannully_Add_Tiles	DD ?
Game_Enable_AI	DD ?
Game_Enable_BGM	DD ?
Game_Enable_SE	DD ?

	.CODE
GameInitialize:
	FRAME	hWnd
	USES	ebx,esi,edi
		#ifdef MY_DEBUG
			mov		eax, ADDR <'Entered GameInitialize(hWnd=%X)',0Dh,0Ah,0>
			writeln(eax, [hWnd])
		#endif
	// For game options
		mov		D[Game_Mannully_Add_Tiles], 0
		mov		D[Game_Enable_AI], 0
		mov		D[Game_Enable_BGM], 1
		mov		D[Game_Enable_SE], 1
	// For sounds
		invoke	DSInitialize, [hWnd], ADDR Game_pBGMCtrl, ADDR Game_pSECtrl
		test	eax, eax
		jz		>.Error
		// start bgm
		invoke	DSPlay, [Game_pBGMCtrl]
	// For gui
		invoke	Malloc, SIZEOF(CWinActuator)
		mov		[Game_pActuator], eax
		invoke	ActuatorConstruct, eax, [hWnd], NULL, 10
	// For game logic
		invoke	GameSetup

		mov		eax, 1
		ret
	.Error:
		xor		eax, eax
		ret
ENDF

GameUninitialize:
	FRAME	hWnd
	USES	ebx,esi,edi
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GameUninitialize(hWnd=%X)',0Dh,0Ah,0>
		writeln(eax, [hWnd])
		#endif
	// For game logic
		invoke	GameUnSetup
	// For gui
		invoke	ActuatorDeconstruct, [Game_pActuator]
		invoke	Free, [Game_pActuator]
	// For sounds
		invoke	DSUninitialize, [Game_pBGMCtrl], [Game_pSECtrl]
		ret
ENDF

GameSetup:
	FRAME
	USES	ebx,esi,edi
	LOCALS	__fix	; a goasm bug
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GameSetup()',0Dh,0Ah,0>
		writeln(eax)
		#endif

		invoke	NewGrid
		mov		[Game_pGrid], eax
		invoke	GridAddStartTiles, eax
	/*
		invoke	NewTile
		mov		D[eax + TILE.x], 0
		mov		D[eax + TILE.y], 0
		mov		D[eax + TILE.value], 9
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 1
		mov		D[eax + TILE.y], 0
		mov		D[eax + TILE.value], 8
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 2
		mov		D[eax + TILE.y], 0
		mov		D[eax + TILE.value], 7
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 3
		mov		D[eax + TILE.y], 0
		mov		D[eax + TILE.value], 6
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 0
		mov		D[eax + TILE.y], 1
		mov		D[eax + TILE.value], 2
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 1
		mov		D[eax + TILE.y], 1
		mov		D[eax + TILE.value], 3
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 2
		mov		D[eax + TILE.y], 1
		mov		D[eax + TILE.value], 4
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 3
		mov		D[eax + TILE.y], 1
		mov		D[eax + TILE.value], 5
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 0
		mov		D[eax + TILE.y], 2
		mov		D[eax + TILE.value], 1
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 1
		mov		D[eax + TILE.y], 2
		mov		D[eax + TILE.value], 0
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 2
		mov		D[eax + TILE.y], 2
		mov		D[eax + TILE.value], 0
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 3
		mov		D[eax + TILE.y], 2
		mov		D[eax + TILE.value], 6
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 0
		mov		D[eax + TILE.y], 3
		mov		D[eax + TILE.value], 6
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 1
		mov		D[eax + TILE.y], 3
		mov		D[eax + TILE.value], 6
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 2
		mov		D[eax + TILE.y], 3
		mov		D[eax + TILE.value], 6
		invoke	GridInsertTile, [Game_pGrid], eax
		invoke	NewTile
		mov		D[eax + TILE.x], 3
		mov		D[eax + TILE.y], 3
		mov		D[eax + TILE.value], 6
		invoke	GridInsertTile, [Game_pGrid], eax
	*/

		invoke	NewAi, [Game_pGrid]
		mov		D[Game_pAI], eax

		mov		D[Game_Score], 0
		mov		B[Game_Over], 0
		mov		B[Game_Won], 0
		mov		B[Game_Wait_Add_Tile], 0
		mov		B[Game_Thinking], 0

		invoke	GameActuate
		ret
ENDF

GameUnSetup:
	FRAME
	USES	ebx,esi,edi
	LOCALS	__fix	; a goasm bug
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GameUnSetup()',0Dh,0Ah,0>
		writeln(eax)
		#endif

		invoke	DeleteAi, [Game_pAI]
		invoke	DeleteGrid, [Game_pGrid]
		ret
ENDF

GameOnPaint:
	FRAME	hDC
	USES	ebx,esi,edi
		invoke	ActuatorOnPaint, [Game_pActuator], [hDC]
		ret
ENDF

GameOnKillTimer:
	FRAME
	USES	ebx,esi,edi
	LOCALS	__fix	; a goasm bug
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GameOnKillTimer()',0Dh,0Ah,0>
		writeln(eax)
		#endif

		invoke	ActuatorKillTimer, [Game_pActuator] 
		ret
ENDF

GameOnTimer:
	FRAME	timerId
	USES	ebx,esi,edi
		cmp		D[timerId], ACTUATOR_TIMER
		jne		>
			invoke	ActuatorOnTimer, [Game_pActuator]
			jmp		>.return
		:
		invoke	GameAutoMove

	.return:
		ret
ENDF

GameActuate:
	FRAME
	USES	ebx,esi,edi
	LOCALS	__fix ; due to a goasm bug
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GameActuate()',0Dh,0Ah,0>
		writeln(eax)
		#endif

		#ifdef CLI
		mov		eax, ADDR <'******************************************************',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridPrint, [Game_pGrid]
		mov		eax, ADDR <'******************************************************',0Dh,0Ah,0>
		writeln(eax)
		#endif

		#ifdef GUI
		invoke	ActuatorDoActuate, [Game_pActuator], [Game_pGrid], \
									[Game_Score], [Game_Over], [Game_Won]
		#endif
	ret
ENDF

GameMove:
	FRAME	direction
	USES	ebx,esi,edi
	LOCALS	res:MOVE_RESULT
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GameMove(direction=%d)',0Dh,0Ah,0>
		writeln(eax, [direction])
		#endif

		mov		al, [Game_Over]
		add		al, [Game_Won]
		test	al, al
		jnz		>>.overreturn

		invoke	GridMove, [Game_pGrid], [direction], ADDR res

		#ifdef CLI
			mov		eax, ADDR <'score += %d',0Dh,0Ah,0>
			writeln(eax, [res.score])
		#endif

		mov		eax, [res.score]
		add		[Game_Score], eax

	.if1: ;(!res.won)
		mov		al, [res.won]
		test	al, al
		jnz		>.else1
	.then1:
		.if2: ;(res.moved)
			mov		al, [res.moved]
			test	al, al
			jz		>.else2
		.then2:
			mov		eax, [Game_Enable_SE]
			test	eax, eax
			jz		>
			invoke	DSPlay, [Game_pSECtrl]
			:
			invoke	GameComputerMove
		.else2:
		.fi2:
		jmp		>.fi1
	.else1:
		mov		B[Game_Won], 1
		#ifdef CLI
			mov		eax, ADDR <'You win!!',0Dh,0Ah,0>
			writeln(eax)
		#endif
	.fi1:

		invoke	GridMovesAvaliable, [Game_pGrid]
		test	eax, eax
		jnz		>
		mov		B[Game_Over], 1
		#ifdef CLI
			mov		eax, ADDR <'No more moves avaliable!!',0Dh,0Ah,0>
			writeln(eax)
		#endif
		:

		invoke	GameActuate
		jmp		>.return
		
	.overreturn:
		#ifdef CLI
			mov		eax, ADDR <'GameMove: Game ended!!!',0Dh,0Ah,0>
			writeln(eax)
		#endif
	.return:
		ret
ENDF

GameAutoMove:
	FRAME
	USES	ebx,esi,edi
	LOCALS	aaa
		invoke	GameRunning
		test	eax, eax
		jnz		>.return

		mov		al, [Game_Wait_Add_Tile]
		test	al, al
		jnz		>.return

		mov		al, [Game_Thinking]
		test	al, al
		jnz		>.return

		mov		B[Game_Thinking], 1
		invoke	AiGetBest, [Game_pAI]
		mov		B[Game_Thinking], 0

		invoke	GameMove, eax

	.return:
		ret
ENDF

GameClickAt:
	FRAME	posx, posy, isRight
	USES	ebx,esi,edi
	LOCALS	pTile
		mov		eax, [Game_Mannully_Add_Tiles]
		test	eax, eax
		jz		>.Return

		invoke	GridCellContent, [Game_pGrid], [posx], [posy]
		test	eax, eax
		jnz		>.Return
		invoke	NewTile
		mov		[pTile], eax
		mov		esi, eax
		mov		eax, [posx]
		mov		[esi + TILE.x], eax
		mov		eax, [posy]
		mov		[esi + TILE.y], eax
		mov		eax, [isRight]
		test	eax, eax
		jz		>.false
	.true:
		mov		D[esi + TILE.value], 1
		jmp		>
	.false:
		mov		D[esi + TILE.value], 0
	:

		invoke	GridPrepareTiles, [Game_pGrid]
		invoke	GridInsertTile, [Game_pGrid], [pTile]
		mov		esi, [Game_pGrid]
		mov		B[esi + GRID.playerTurn], 1

		invoke	GameActuate
		
		mov		B[Game_Wait_Add_Tile], 0
	.Return:
		ret
ENDF

GameRestart:
	FRAME
		invoke	GameUnSetup
		invoke	GameSetup
		ret
ENDF

GameComputerMove:
	FRAME
		mov		B[Game_Wait_Add_Tile], 1
		mov		eax, [Game_Mannully_Add_Tiles]
		test	eax, eax
		jnz		>
		invoke	GridComputerMove, [Game_pGrid]
		mov		B[Game_Wait_Add_Tile], 0
		:
		ret
ENDF

GameRunning:
	FRAME
	USES	esi
	LOCALS	__fix ; due to a goasm bug
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GameRunning()',0Dh,0Ah,0>
		writeln(eax)
		#endif

		mov		esi, [Game_pActuator]
		xor		eax, eax
		mov		al, [esi + CWinActuator.animating]
		ret
ENDF

GameSwitchBGM:
	FRAME
		mov		eax, 1
		sub		eax, [Game_Enable_BGM]
		mov		[Game_Enable_BGM], eax

	pusha
		test	eax, eax
		jz		>.false
	.true:
		invoke	DSPlay, [Game_pBGMCtrl]
		jmp		>
	.false:
		invoke	DSStop, [Game_pBGMCtrl]
	:
	popa

		ret
ENDF

GameSwitchSE:
	FRAME
		mov		eax, 1
		sub		eax, [Game_Enable_SE]
		mov		[Game_Enable_SE], eax
		ret
ENDF

GameSwitchAI:
	FRAME
		mov		eax, 1
		sub		eax, [Game_Enable_AI]
		mov		[Game_Enable_AI], eax

		pusha
		test	eax, eax
		jz		>.false
	.true:
			mov		esi, [Game_pActuator]
			mov		edi, [Game_pAI]
			mov		edx, [edi + AI.minSearchTime]
			add		edx, ANIMA_DELAY
			invoke	SetTimer, [esi + CWinActuator.hWndGrid], \
							AUTORUN_TIMER, \
							edx, NULL
			jmp		>.return
	.false:
		mov		esi, [Game_pActuator]
		invoke	KillTimer, [esi + CWinActuator.hWndGrid], AUTORUN_TIMER

	.return:
		popa
		ret
ENDF

GameSwitchManuallyAddTiles:
	FRAME
		mov		eax, 1
		sub		eax, [Game_Mannully_Add_Tiles]
		mov		[Game_Mannully_Add_Tiles], eax
		ret
ENDF
