#include "game.h"
	.DATA
	.CODE
AiConstruct:
	FRAME	pAI, pGrid
	USES	ebx,esi,edi
		mov		esi, [pAI]

		mov		eax, [pGrid]
		mov		[esi + AI.pGrid], eax
		mov		D[esi + AI.minSearchTime], 100
		ret
ENDF

AiDeconstruct:
	FRAME	pAI
	USES	ebx,esi,edi
		mov		esi, [pAI]
		ret
ENDF

NewAi:
	FRAME	pGrid
	USES	ebx,esi,edi
	; Allocate a new Tile object		
		invoke	Malloc, SIZEOF(AI)

		push	eax
		invoke	AiConstruct, eax, [pGrid]
		pop		eax
		ret
ENDF

DeleteAi:
	FRAME	pAI
	USES	ebx,esi,edi
		mov		eax, [pAI]
		test	eax, eax
		jz		>.return

		invoke	AiDeconstruct, eax

		invoke	Free, [pAI]
	.return:
		ret
ENDF

// returns float in eax
AiEval:
	FRAME	pAI
	USES	ebx,esi,edi
	LOCALS	emptyCells, smoothWeight, mono2Weight, emptyWeight, maxWeight, \
			smoothness, mono, maxValue, \
			result
		mov		esi, [pAI]
		invoke	GridAvaliableCellsCount, [esi + AI.pGrid]
		mov		[emptyCells], eax

		mov		D[smoothWeight], 0.1
		mov		D[mono2Weight], 1.0
		mov		D[emptyWeight], 2.7
		mov		D[maxWeight], 1.0

		invoke	GridSmoothness, [esi + AI.pGrid]
		mov		[smoothness], eax
		invoke	GridMonotonicity2, [esi + AI.pGrid]
		mov		[mono], eax
		invoke	GridMaxValue, [esi + AI.pGrid]
		mov		[maxValue], eax

		finit
		fild	D[smoothness]
		fmul	D[smoothWeight]

		fild	D[mono]
		fmul	D[mono2Weight]
		
		fldl2e
		fld1
		fild	D[emptyCells]
		fyl2x
		fdiv	st1
		fxch	st1
		fst		st0
		fmul	D[emptyWeight]

		fild	D[maxValue]
		fmul	D[maxWeight]

		fld		st0
		fadd	st2
		fadd	st3
		fadd	st4

		fstp	D[result]
		mov		eax, [result]
		ret
ENDF

// alpha-beta depth first search
AiSearch:
	FRAME	pAI, depth, alpha, beta, positions, cutoffs, pAiResult
	USES	ebx,esi,edi
	LOCALS	bestScore, bestMove, result:AI_RESULT, \
			direction, newGrid, moveRes:MOVE_RESULT, \
			newAI, CONST_9900, \
			scoreArray[32]:D, canditArray[32]:D, \
			posCnt, posBuffer[Grid_Cell_Count]:POS, \
			maxScore, posIdx, pTile
		mov		D[bestMove], -1

	// the maxing player
	.if1: ;(pAI->pGrid->playerTurn == 1)
		mov		esi, [pAI]
		mov		edi, [esi + AI.pGrid]
		mov		al, [edi + GRID.playerTurn]
		test	al, al
		jz		>>.else1
	.then1:
		mov		eax, [alpha]
		mov		[bestScore], eax

		mov		D[direction], 0
		.for1: ;(direction = 0; direction !=4; direction++)
			cmp		D[direction], 4
			je		>>.endfor1

			mov		esi, [pAI]
			invoke	GridClone, [esi + AI.pGrid]
			mov		[newGrid], eax

			invoke	GridMove, [newGrid], [direction], ADDR moveRes
			.if2: ;(moveRes.moved == 1)
				mov		al, [moveRes.moved]
				test	al, al
				jz		>>.endif2
			.then2:
				inc		D[positions]
				.if3: ;(moveRes.won == 1)
					mov		al, [moveRes.won]
					test	al, al
					jz		>.endif3
				.then3:
					mov		edi, [pAiResult]
					mov		eax, [direction]
					mov		[edi + AI_RESULT.move], eax
					mov		D[edi + AI_RESULT.score], 10000.0
					mov		eax, [positions]
					mov		[edi + AI_RESULT.positions], eax
					mov		eax, [cutoffs]
					mov		[edi + AI_RESULT.cutoffs], eax

					ret
				.endif3:

				invoke	NewAi, [newGrid]
				mov		[newAI], eax

				.if4: ;(depth == 0)
					cmp		D[depth], 0
					jnz		>.else4
				.then4:
					mov		edi, [pAiResult]
					mov		eax, [direction]
					mov		[result.move], eax
					invoke	AiEval, [newAI]
					mov		D[result.score], eax

					jmp		>.endif4
				.else4:
					mov		eax, [depth]
					dec		eax
					invoke	AiSearch, [newAI], eax, [bestScore], [beta], [positions], [cutoffs], ADDR result

					.if5: ;(result.score > 9900)
						mov		D[CONST_9900], 9900
						finit
						fild	D[CONST_9900]
						fld		D[result.score]
						fcomi
						jna		>.endif5
					.then5:
						fld1
						fld		D[result.score]
						fsub	st1
						fst		D[result.score]
					.endif5:

					mov		eax, [result.positions]
					mov		[positions], eax
					mov		eax, [result.cutoffs]
					mov		[cutoffs], eax
				.endif4:

				invoke	DeleteAi, [newAI]
				invoke	DeleteGrid, [newGrid]

				.if6: ;(result.score > bestScore)
					finit
					fld		D[bestScore]
					fld		D[result.score]
					fcomi
					jna		>.endif6
				.then6:
					mov		eax, D[result.score]
					mov		[bestScore], eax
					mov		eax, [direction]
					mov		[bestMove], eax
				.endif6:

				.if7: ;(result.score > beta)
					finit
					fld		D[beta]
					fld		D[result.score]
					fcomi
					jna		>.endif7
				.then7:
					inc		D[cutoffs]

					mov		edi, [pAiResult]
					mov		eax, [bestMove]
					mov		[edi + AI_RESULT.move], eax
					mov		eax, [beta]
					mov		D[edi + AI_RESULT.score], eax
					mov		eax, [positions]
					mov		[edi + AI_RESULT.positions], eax
					mov		eax, [cutoffs]
					mov		[edi + AI_RESULT.cutoffs], eax

					ret					
				.endif7:
			.endif2:
		.forcontinue1:
			inc		D[direction]
			jmp		<<.for1
		.endfor1:
		jmp		>>.endif1
	.else1: // computer's turn, we'll do heavy pruning to keep the branching factor low
		mov		eax, [beta]
		mov		[bestScore], eax

		// try a 2 and 4 in each cell and measure how annoying it is
    	// with metrics from eval
    	invoke	ArrayInit, ADDR scoreArray, 32
    	mov		D[maxScore], -1
    	mov		esi, [pAI]
    	invoke	GridAvaliableCells, [esi + AI.pGrid], ADDR posBuffer
    	mov		[posCnt], eax

    	mov		D[posIdx], 0
    	.for2: ;(posIdx = 0; posIdx != posCnt; posIdx++)
    		mov		eax, [posIdx]
    		cmp		eax, [posCnt]
    		je		>>.endfor2

    		// esi = pPos, edi = pGrid
    		mov		esi, ADDR posBuffer
    		mov		edx, [posIdx]
    		lea		esi, [esi + SIZEOF(POS)*edx]
    		mov		edi, [pAI]
    		mov		edi, [edi + AI.pGrid]

    		// eval tile 2
    		invoke	MakeTile, esi, 2
    		mov		[pTile], eax
    		invoke	GridInsertTile, edi, [pTile]
    		invoke	GridIslands, edi
    		mov		ebx, eax
    		invoke	GridSmoothness, edi
    		sub		ebx, eax
    		invoke	GridRemoveTile, edi, [pTile]
    		invoke	DeleteTile, [pTile]

    		invoke	Malloc, SIZEOF(POSVS)
    		mov		edx, [esi + POS.x]
    		mov		[eax + POSVS.x], edx
    		mov		edx, [esi + POS.y]
    		mov		[eax + POSVS.y], edx
    		mov		D[eax + POSVS.value], 2
    		mov		[eax + POSVS.score], ebx
    		invoke	ArrayAppend, ADDR scoreArray, eax

    		.if8: ;(score > maxScore)
    			cmp		ebx, [maxScore]
    			jng		>.endif8
    		.then8:
    			mov		[maxScore], ebx
    		.endif8:

    		// eval tile 4
    		invoke	MakeTile, esi, 4
    		mov		[pTile], eax
    		invoke	GridInsertTile, edi, [pTile]
    		invoke	GridIslands, edi
    		mov		ebx, eax
    		invoke	GridSmoothness, edi
    		sub		ebx, eax
    		invoke	GridRemoveTile, edi, [pTile]
    		invoke	DeleteTile, [pTile]

    		invoke	Malloc, SIZEOF(POSVS)
    		mov		edx, [esi + POS.x]
    		mov		[eax + POSVS.x], edx
    		mov		edx, [esi + POS.y]
    		mov		[eax + POSVS.y], edx
    		mov		D[eax + POSVS.value], 4
    		mov		[eax + POSVS.score], ebx
    		invoke	ArrayAppend, ADDR scoreArray, eax

    		.if11: ;(score > maxScore)
    			cmp		ebx, [maxScore]
    			jng		>.endif11
    		.then11:
    			mov		[maxScore], ebx
    		.endif11:
    	.forcontinue2:
    		inc		D[posIdx]
    		jmp		<<.for2
    	.endfor2:

    	// now just pick out the most annoying moves
    	invoke	ArrayInit, ADDR canditArray, 32
    	mov		esi, ADDR scoreArray
    	.while1: ;([esi] != 0)
	        mov     eax, [esi]
	        test    eax, eax
	        jz      >.endwhile1
	    .do1:
	    	mov		edi, [esi] // edi = pPosvs
	    	mov		eax, [edi + POSVS.score]
	    	cmp		eax, [maxScore]
	    	jne		>
	    		invoke	ArrayAppend, ADDR canditArray, edi
	    	:
	        add     esi, 4
	    .endwhile1:
	    invoke	ArrayClear, ADDR scoreArray, 32

	    // search on each candidate
	    mov		esi, ADDR canditArray
    	.while2: ;([esi] != 0)
	        mov     eax, [esi]
	        test    eax, eax
	        jz      >>.endwhile2
	    .do2:
	    	mov		edi, [esi] // edi = pPosvs
	    	
	    	mov		eax, [pAI]
	    	invoke	GridClone, [eax + AI.pGrid]
	    	mov		[newGrid], eax
	    	invoke	MakeTile, edi, [edi + POSVS.value]
	    	mov		[pTile], eax
	    	invoke	GridInsertTile, [newGrid], eax
	    	mov		edi, [newGrid]
	    	mov		B[edi + GRID.playerTurn], 1
	    	inc		D[positions]
	    	invoke	NewAi, [newGrid]
	    	mov		[newAI], eax
	    	invoke	AiSearch, [newAI], [depth], [alpha], [bestScore], [positions], [cutoffs], ADDR result
	    	mov		eax, [result.positions]
	    	mov		[positions], eax
	    	mov		eax, [result.cutoffs]
	    	mov		[cutoffs], eax

	    	invoke	DeleteAi, [newAI]
			invoke	DeleteGrid, [newGrid]

			.if9: ;(result.score < bestScore)
				finit
				fld		D[bestScore]
				fld		D[result.score]
				fcomi
				jnb		>.endif9
			.then9:
				mov		eax, D[result.score]
				mov		[bestScore], eax
			.endif9:

			.if10: ;(result.score < alpha)
				finit
				fld		D[alpha]
				fld		D[result.score]
				fcomi
				jna		>.endif10
			.then10:
				inc		D[cutoffs]

				mov		edi, [pAiResult]
				mov		D[edi + AI_RESULT.move], -1
				mov		eax, [alpha]
				mov		D[edi + AI_RESULT.score], eax
				mov		eax, [positions]
				mov		[edi + AI_RESULT.positions], eax
				mov		eax, [cutoffs]
				mov		[edi + AI_RESULT.cutoffs], eax

				ret			
			.endif10:
	    .whilecontinue2:
	        add     esi, 4
	    .endwhile2:
	.endif1:

		mov		edi, [pAiResult]
		mov		eax, [bestMove]
		mov		[edi + AI_RESULT.move], eax
		mov		eax, [bestScore]
		mov		D[edi + AI_RESULT.score], eax
		mov		eax, [positions]
		mov		[edi + AI_RESULT.positions], eax
		mov		eax, [cutoffs]
		mov		[edi + AI_RESULT.cutoffs], eax

		ret	
ENDF

// performs a search and returns the best move
AiGetBest:
	FRAME	pAI
	USES	ebx,esi,edi
		invoke	AiIterativeDeep, [pAI]
		ret
ENDF

// performs iterative deepening over the alpha-beta search
AiIterativeDeep:
	FRAME	pAI
	USES	ebx,esi,edi
	LOCALS	start, depth, best, result:AI_RESULT
		mov		D[depth], 0
		invoke	GetTickCount
		mov		[start], eax

	.do:
		invoke	AiSearch, [pAI], [depth], -10000.0, 10000.0, 0, 0, ADDR result
		.if1: ;(result.move == -1)
			cmp		D[result.move], -1
			jne		>.else1
		.then1:
			jmp		>.endwhile
		.else1:
			mov		eax, [result.move]
			mov		[best], eax
		.endif1:

		inc		D[depth]
	.while:
		invoke	GetTickCount
		mov		edx, eax
		sub		edx, [start]
		mov		esi, [pAI]
		cmp		edx, [esi + AI.minSearchTime]
		jb		<.do
	.endwhile:
		mov		eax, [best]
		ret
ENDF