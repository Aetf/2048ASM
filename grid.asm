#include "game.h"
#include "wincrypt.h"

	.CODE
GridConstruct:
	FRAME	pGrid
	USES	ebx,esi,edi
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridConstruct(pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid])
		#endif

		mov	esi, [pGrid]

		mov	D[esi + GRID.startTiles], 2
		mov	B[esi + GRID.playerTurn], 1
		ret
ENDF

GridDeconstruct:
	FRAME	pGrid
	USES	ebx,esi,edi
	LOCALS	posx, posy
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridDeconstruct(pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid])
		#endif

		mov		esi, [pGrid]
		mov		ecx, Grid_Cell_Count
	.l1:
		push	ecx
		dec		ecx
		invoke	IdxToXY, ecx
		; eax = x, edx = y
		mov		[posx], eax
		mov		[posy], edx
		invoke	GridCellContent, [pGrid], eax, edx
		test	eax, eax
		jz		>.continue
		invoke	DeleteTile, eax
	.continue:
		pop		ecx
		loop	<.l1
		
		ret
ENDF

NewGrid:
	FRAME
	USES	ebx,esi,edi
	LOCALS	__fix ; due to a goasm bug
	; Allocate a new Tile object		
		invoke	Malloc, SIZEOF(GRID)

		push	eax
		invoke	GridConstruct, eax
		pop		eax
		ret
ENDF

DeleteGrid:
	FRAME	pGrid
	USES	ebx,esi,edi
	LOCALS	__fix ; due to a goasm bug
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered DeleteGrid(pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid])
		#endif

		mov		eax, [pGrid]
		test	eax, eax
		jz		>.return

		invoke	GridDeconstruct, eax

		invoke	Free, [pGrid]
	.return:
		ret
ENDF

GridClone:
	FRAME	pGrid
	USES	ebx,esi,edi
	LOCALS	pNewGrid, posx, posy
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridClone(pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid])
		#endif

		invoke	NewGrid
		mov		[pNewGrid], eax
		mov		edi, eax
		mov		esi, [pGrid]

		mov		eax, [esi + GRID.startTiles]
		mov		[edi + GRID.startTiles], eax
		mov		al, [esi + GRID.playerTurn]
		mov		[edi + GRID.playerTurn], al

		mov		ecx, Grid_Cell_Count
	.l1:
		push	ecx
		dec		ecx
		invoke	IdxToXY, ecx
		; eax = x, edx = y
		mov		[posx], eax
		mov		[posy], edx
		invoke	GridCellContent, esi, eax, edx
		test	eax, eax
		jz		>.continue
		invoke	TileClone, eax
		invoke	GridInsertTile, edi, eax
	.continue:
		pop		ecx
		loop	<.l1

		mov		eax, edi
		ret
ENDF

// Find the first available random position
// return: true if succeed
GridRandomAvailableCell:
	FRAME	pGrid, pPos
	USES	ebx,esi,edi
	LOCALS	posBuffer[Grid_Cell_Count]:POS
		#ifdef GRID_DEBUG
		mov		eax, ADDR <'Entered GridRandomAvailableCell(pGrid=%X,pPos=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid], [pPos])
		#endif
		#ifdef GRID_DUMP
		pusha
		mov		eax, ADDR <'    Before GridRandomAvailableCell :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		popa
		#endif

		mov		esi, ADDR posBuffer
		invoke	GridAvaliableCells, [pGrid], esi
		test	eax, eax
		jz		>
		invoke	RandomNumber, eax
		mov		edi, [pPos]
		mov		ebx, [esi + SIZEOF(POS)*eax + POS.x]
		mov		[edi + POS.x], ebx
		mov		ebx, [esi + SIZEOF(POS)*eax + POS.y]
		mov		[edi + POS.y], ebx
		mov		eax, 1
	:

		#ifdef GRID_DEBUG
		pusha
		mov		edi, [pPos]
		mov		eax, ADDR <'GridRandomAvailableCell retruned (x=%d,y=%d)',0Dh,0Ah,0>
		writeln(eax, [edi + POS.x], [edi + POS.y])
		popa
		#endif
		#ifdef GRID_DUMP
		pusha
		mov		eax, ADDR <'    After GridRandomAvailableCell :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		popa
		#endif

		ret
ENDF

// Put avaliable cells in the buffer of POS, return the number of avaliable cells
GridAvaliableCells:
	FRAME	pGrid, pPosBuffer
	USES	ebx,esi,edi
	LOCALS	nCount
		#ifdef GRID_DEBUG
		mov		eax, ADDR <'Entered GridAvaliableCells(pGrid=%X,pPosBuffer=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid], [pPosBuffer])
		#endif

		#ifdef GRID_DUMP
		mov		eax, ADDR <'    Before GridAvaliableCells :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		#endif

		mov		D[nCount], 0

		mov		esi, [pGrid]
		add		esi, GRID.cells
		mov		edi, [pPosBuffer]
		mov		ecx, Grid_Cell_Count
	:
		mov		eax, [esi + 4*ecx - 4]
	; If eax == NULL
		test	eax, eax
		jnz		>.continue
		mov		ebx, [nCount]
		push	ecx
		dec		ecx
		invoke	IdxToXY, ecx
		pop		ecx
		mov		[edi + SIZEOF(POS)*ebx + POS.x], eax
		mov		[edi + SIZEOF(POS)*ebx + POS.y], edx
		inc		D[nCount]
	.continue
		loop	<


	#ifdef GRID_DEBUG
		mov		eax, ADDR <'GridAvaliableCells returned:',0Dh,0Ah,'    ',0>
		writeln(eax)
		mov		esi, [pPosBuffer]
		mov		eax, [nCount]
		lea		edi, [esi + SIZEOF(POS)*eax]
		.grid_debug_while:
		cmp		esi, edi
		jae		>.grid_debug_endwhile
		.grid_debug_do:
		mov		eax, ADDR <'(%d,%d) ',0>
		writeln(eax, [esi+POS.x], [esi+POS.y])
		.grid_debug_continue:
		add		esi, SIZEOF(POS)
		jmp		<.grid_debug_while
		.grid_debug_endwhile:
		writeln()
	#endif

		#ifdef GRID_DUMP
		mov		eax, ADDR <'    After GridAvaliableCells :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		#endif

		mov		eax, [nCount]
		ret
ENDF

GridEachTile:
	FRAME	pGrid, pCallback, pParameter
	USES	ebx,esi,edi
	LOCALS	posx, posy
		#ifdef GRID_DEBUG
		mov		eax, ADDR <'Entered GridEachTile(pGrid=%X,pCallback=%X,pParameter=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid], [pCallback], [pParameter])
		invoke	GridWriteln, [pGrid]
		#endif

		mov		esi, [pGrid]
		add		esi, GRID.cells
		mov		edi, esi
		add		edi, Grid_Cell_Count*4
		xor		ecx, ecx
	.while:
		cmp		esi,edi
		jae		>.endwhile

		invoke	IdxToXY, ecx
		pusha
		invoke	[pCallback], eax, edx, [esi], [pParameter]
		popa
		
		inc		ecx
		add		esi, 4
		jmp		<.while
	.endwhile:

		#ifdef GRID_DEBUG
		pusha
		mov		eax, ADDR <'    After GridEachTile :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		popa
		#endif

		ret
ENDF

GridAvaliableCellsCount:
	FRAME	pGrid
	LOCALS	posBuffer[Grid_Cell_Count]:POS
		invoke	GridAvaliableCells, [pGrid], ADDR posBuffer
		ret
ENDF

GridCellAvaliable:
	FRAME	pGrid, posx, posy
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridCellAvaliable(pGrid=%X,posx=%d,posy=%d)',0Dh,0Ah,0>
		writeln(eax, [pGrid], [posx], [posy])
		#endif
		#ifdef GRID_DUMP
		mov		eax, ADDR <'    Before GridCellAvaliable :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		#endif

		invoke	GridCellContent, [pGrid], [posx], [posy]
		test	eax, eax
		jnz		>.else
		mov		eax, 1
		jmp		>.fi
	.else:
		xor		eax, eax
	.fi:
		ret
ENDF

GridCellOccupied:
	FRAME	pGrid, posx, posy
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridCellOccupied(pGrid=%X,posx=%d,posy=%d)',0Dh,0Ah,0>
		writeln(eax, [pGrid], [posx], [posy])
		#endif

		invoke	GridCellContent, [pGrid], [posx], [posy]
		test	eax, eax
		jz		>
		mov		eax, 1
	:
		ret
ENDF

// Return a pointer to the tile
GridCellContent:
	FRAME	pGrid, posx, posy
	USES	esi
		#ifdef GRID_DUMP
		mov		eax, ADDR <'    Before GridCellContent :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		#endif

		invoke	GridWithinBounds, [pGrid], [posx], [posy]
		test	eax, eax
		jz		>.return

		mov		esi, [pGrid]
		add		esi, GRID.cells
		invoke	XYToIdx, [posx], [posy]
		mov		eax, [esi + 4*eax]
	.return:

		#ifdef GRID_DUMP
		pusha
		mov		eax, ADDR <'    After GridCellContent :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		popa
		#endif
		ret
ENDF

// Returns the inserted tile
GridInsertTile:
	FRAME	pGrid, pTile
	USES	ebx,esi,edi
		#ifdef GRID_DEBUG
		mov		eax, ADDR <'Entered GridInsertTile(pGrid=%X,pTile=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid], [pTile])
		invoke	TileWriteln, [pTile]
		writeln()
		#endif

		#ifdef GRID_DUMP
		pusha
		mov		eax, ADDR <'    Before GridInsertTile :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		popa
		#endif

		mov		esi, [pGrid]
		add		esi, GRID.cells
		
		mov		edi, [pTile]
		invoke	XYToIdx, [edi + TILE.x], [edi + TILE.y]
		mov		[esi + 4*eax], edi

		

		#ifdef GRID_DUMP
		pusha
		mov		eax, ADDR <'    After GridInsertTile :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		popa
		#endif

		mov		eax, edi
		ret
ENDF

GridRemoveTile:
	FRAME	pGrid, pTile
	USES	ebx,esi,edi
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridRemoveTile(pGrid=%X,pTile=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid], [pTile])
		#endif

		mov		esi, [pGrid]
		add		esi, GRID.cells
		mov		edi, [pTile]
		invoke	XYToIdx, [edi + TILE.x], [edi + TILE.y]
		mov		D[esi + 4*eax], 0
		ret
ENDF

GridAddStartTiles:
	FRAME	pGrid
	USES	ebx,esi,edi
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridAddStartTiles(pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid])
		#endif

		mov	esi, [pGrid]
		mov	ecx, [esi + GRID.startTiles]
	.l1:
		push	ecx
		invoke	GridAddRandomTile, [pGrid]
		pop		ecx
		loop	<.l1
		ret
ENDF

GridAddRandomTile:
	FRAME	pGrid
	USES	ebx,esi,edi
	LOCALS	value, pos:POS
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridAddRandomTile(pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid])
		#endif

		invoke	GridAvaliableCellsCount, [pGrid]
		test	eax, eax
		jz		>.return
		
		invoke	GridRandomAvailableCell, [pGrid], ADDR pos
		
		invoke	NewTile
		mov		esi, eax
		mov		eax, [pos.x]
		mov		[esi + TILE.x], eax
		mov		eax, [pos.y]
		mov		[esi + TILE.y], eax
		invoke	RandomNumber, 1
		mov		[esi + TILE.value], eax

		invoke	GridInsertTile, [pGrid], esi
	.return:
		ret
ENDF

GridPrepareTiles:
	FRAME	pGrid
	USES	ebx,esi,edi
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridPrepareTiles(pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid])
		#endif

		invoke	GridEachTile, [pGrid], ADDR PrepareCells_CallBack, 0
		ret
ENDF

GridMoveTile:
	FRAME	pGrid, pTile, destX, destY
	USES	ebx,esi,edi
		#ifdef GRID_DEBUG
		mov		eax, ADDR <'Entered GridMoveTile(pGrid=%X,pTile=%X,destX=%d,destY=%d)',0Dh,0Ah,0>
		writeln(eax, [pGrid], [pTile], [destX], [destY])
		#endif
		#ifdef GRID_DUMP
		mov		eax, ADDR <'    Before GridMoveTile :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		#endif

		mov		esi, [pGrid]
		add		esi, GRID.cells
		mov		edi, [pTile]
		invoke	XYToIdx, [edi + TILE.x], [edi + TILE.y]
		mov		D[esi + 4*eax], NULL
		invoke	XYToIdx, [destX], [destY]
		mov		D[esi + 4*eax], edi

		invoke	TileUpdatePosition, edi, [destX], [destY]

		#ifdef GRID_DUMP
		pusha
		mov		eax, ADDR <'    After GridMoveTile :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		popa
		#endif
		ret
ENDF

// return direction vector
// eax = x, edx = y
GetDirVector:
	FRAME	direction
	USES	ebx,esi
		#ifdef AI_DEBUG
			pusha
			mov		eax, ADDR <'Entered GetDirVector(direction=%d)',0Dh,0Ah,0>
			writeln(eax, [direction])
			popa
		#endif
		mov		esi, ADDR DirVector
		mov		ebx, [direction]
		mov		eax, [esi + SIZEOF(POS)*ebx + POS.x]
		mov		edx, [esi + SIZEOF(POS)*ebx + POS.y]
		ret
ENDF

GridMove:
	FRAME	pGrid, direction, pResult
	USES	ebx,esi,edi
	LOCALS	tarverseX[Grid_Size]:D, tarverseY[Grid_Size]:D, \
			dirx, diry, posx, posy, \
			moved:B, score:D, won:B, \
			ptile, ptileNext, posFarthest:POS, posNext:POS

		#ifdef GRID_DEBUG
		mov		eax, ADDR <'Entered GridMove(pGrid=%X,direction=%d,pResult=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid], [direction], [pResult])
		#endif

		mov		B[moved], 0
		mov		B[won], 0
		mov		D[score], 0

		invoke	GetDirVector, [direction]
		mov		[dirx], eax
		mov		[diry], edx
		invoke	GridBuildTarverse, [pGrid], \
									ADDR tarverseX, ADDR tarverseY, \
									eax, edx

		// Save the current tile positions and remove merger information
		invoke	GridPrepareTiles, [pGrid]

		// Traverse the grid in the right direction and move tiles
		mov		ecx, Grid_Size
	.lpX:
		mov		esi, ADDR tarverseX
		mov		eax, [esi + 4*ecx - 4]
		mov		[posx], eax
		push	ecx
		mov		ecx, Grid_Size
	.lpY:
		mov		edi, ADDR tarverseY
		mov		eax, [edi + 4*ecx - 4]
		mov		[posy], eax
		push	ecx

		invoke	GridCellContent, [pGrid], [posx], [posy]
		mov		[ptile], eax
	.if1: ;(ptile != 0)
		test	eax, eax
		jz		>>.fi1
	.then1:
		invoke	GridFindFarthestPosition, [pGrid], [posx], [posy], \
											[dirx], [diry], \
											ADDR posFarthest, ADDR posNext

		invoke	GridCellContent, [pGrid], [posNext.x], [posNext.y]
		mov		[ptileNext], eax
		;if2 (ptileNext != 0 && ptileNext.value == ptile.value && ptileNext.mergedFrom == 0)
			test	eax, eax
			jz		>.else2
			mov		esi, eax
			mov		edi, [ptile]
			mov		eax, [edi + TILE.value]
			cmp		[esi + TILE.value], eax
			jne		>.else2
			mov		eax, [esi + TILE.mergedFrom]
			test	eax, eax
			jnz		>.else2
		.then2:
			invoke	NewTile
			mov		esi, eax
			mov		eax, [posNext.x]
			mov		[esi + TILE.x], eax
			mov		eax, [posNext.y]
			mov		[esi + TILE.y], eax
			mov		eax, [edi + TILE.value] ; eax = pTile->value
			inc		eax
			mov		[esi + TILE.value], eax
			mov		[esi + TILE.mergedFrom], edi
			mov		eax, [ptileNext]
			mov		[esi + TILE.mergedFrom + 4], eax
			invoke	GridInsertTile, [pGrid], esi

			invoke	GridRemoveTile, [pGrid], edi

			invoke	TileUpdatePosition, edi, [posNext.x], [posNext.y]

			mov		eax, [score]
			add		eax, [esi + TILE.value]
			mov		[score], eax

			cmp		D[esi + TILE.value], 10
			jne		>
			mov		B[won], 1
			:
			jmp		>.fi2
		.else2:
			invoke	GridMoveTile, [pGrid], [ptile], [posFarthest.x], [posFarthest.y]
		.fi2:
		
		invoke	GridPositionEqual, [pGrid], [posx], [posy], [ptile]
		test	eax, eax
		jnz		>
		mov		esi, [pGrid]
		mov		B[esi + GRID.playerTurn], 0
		mov		B[moved], 1
		:
	.fi1:
	.continueY:
		pop		ecx
		dec		ecx
		jnz		<<.lpY
	.continueX:
		pop		ecx
		dec		ecx
		jnz		<<.lpX

		mov		esi, [pResult]
		mov		al, [moved]
		mov		[esi + MOVE_RESULT.moved], al
		mov		al, [won]
		mov		[esi + MOVE_RESULT.won], al
		mov		eax, [score]
		mov		[esi + MOVE_RESULT.score], eax

		#ifdef GRID_DUMP
		pusha
		invoke	GridWriteln, [pGrid]
		popa
		#endif
		ret
ENDF

GridPrint:
	FRAME	pGrid
	USES	eax,ebx,ecx,edx,esi,edi
		mov		eax, ADDR <'Print Grid at %X',0Dh,0Ah,0>
		writeln(eax, [pGrid])

		mov		esi, [pGrid]
		mov		edi, [pGrid]
		add		edi, SIZEOF(GRID)-8
		mov		ecx, 3
	.while:
		cmp		esi,edi
		jae		>>.endwhile

		invoke	TilePrint, [esi]
		test	ecx, ecx
		jnz		>
		writeln()
		mov		ecx, 4
		:

		dec		ecx
		add		esi, 4
		jmp		<.while
	.endwhile:
		ret
ENDF

GridWriteln:
	FRAME	pGrid
	USES	eax,ebx,ecx,edx,esi,edi
		mov		eax, ADDR <'Dump Grid at %X',0Dh,0Ah,0>
		writeln(eax, [pGrid])

		mov		esi, [pGrid]
		mov		edi, [pGrid]
		add		edi, SIZEOF(GRID)-8
		mov		ecx, 3
	.while:
		cmp		esi,edi
		jae		>>.endwhile

		invoke	TileWriteln, [esi]
		test	ecx, ecx
		jnz		>
		writeln()
		mov		ecx, 4
		:

		dec		ecx
		add		esi, 4
		jmp		<.while
	.endwhile:
		ret
ENDF

GridComputerMove:
	FRAME	pGrid
	USES	esi
		#ifdef GRID_DEBUG
		mov		eax, ADDR <'Entered GridComputerMove(pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid])
		#endif

		mov		esi, [pGrid]
		invoke	GridAddRandomTile, esi
		mov		B[esi + GRID.playerTurn], 1
		ret
ENDF

GridPositionEqual:
	FRAME	pGrid, posX, posY, pTile
	USES	esi
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridPositionEqual(pGrid=%X,posx=%d,posy=%d,pTile=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid],[posX],[posY],[pTile])
		#endif
		#ifdef GRID_DUMP
		mov		eax, ADDR <'    Before GridPositionEqual :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		#endif

		mov		esi, [pTile]
		mov		eax, [posX]
		mov		edx, [esi + TILE.x]
		cmp		eax, edx
		jne		>.false
		mov		eax, [posY]
		mov		edx, [esi + TILE.y]
		cmp		eax, edx
		jne		>.false
	.true:
		mov		eax, 1
		ret
	.false:
		xor		eax, eax
		ret
ENDF

GridMovesAvaliable:
	FRAME	pGrid
	USES	ebx,esi,edi
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridMovesAvaliable(pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid])
		#endif

		xor		ebx, ebx
		invoke	GridAvaliableCellsCount, [pGrid]
		add		ebx, eax
		invoke	GridTileMatchesAvaliable, [pGrid]
		add		ebx, eax
		mov		eax, ebx

		test	eax, eax
		jz		>
		mov		eax, 1
		:
		ret
ENDF

// Check for available matches between tiles (more expensive check)
GridTileMatchesAvaliable:
	FRAME	pGrid
	USES	ebx,esi,edi
	LOCALS	pTile, nMatches, parameter[2]:D
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridTileMatchesAvaliable(pGrid=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid])
		#endif

		mov		D[nMatches], 0

		mov		esi, ADDR parameter
		mov		eax, ADDR nMatches
		mov		D[esi], eax
		mov		eax, [pGrid]
		mov		D[esi + 4], eax
		invoke	GridEachTile, [pGrid], \
								ADDR TileMatches_CallBack, ADDR parameter

		mov		eax, [nMatches]
		ret
ENDF

GridBuildTarverse:
	FRAME	pGrid, pXBuffer, pYBuffer, DirX, DirY
	USES	esi
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridBuildTarverse(pGrid=%X,pXBuffer=%X,pYBuffer=%X,DirX=%d,DirY=%d)',0Dh,0Ah,0>
		writeln(eax, [pGrid],[pXBuffer],[pYBuffer],[DirX],[DirY])
		#endif

		mov		esi, [pXBuffer]
		mov		eax, [DirX]
		cmp		eax, 1
		je		>.thenX
	.elseX:
		mov		D[esi], 3
		mov		D[esi + 4], 2
		mov		D[esi + 8], 1
		mov		D[esi + 12], 0
		
		jmp		>.fiX
	.thenX:
		mov		D[esi], 0
		mov		D[esi + 4], 1
		mov		D[esi + 8], 2
		mov		D[esi + 12], 3
		
	.fiX:

		mov		esi, [pYBuffer]
		mov		eax, [DirY]
		cmp		eax, 1
		je		>.thenY
	.elseY:
		mov		D[esi], 3
		mov		D[esi + 4], 2
		mov		D[esi + 8], 1
		mov		D[esi + 12], 0
		jmp		>.fiY
	.thenY:
		mov		D[esi], 0
		mov		D[esi + 4], 1
		mov		D[esi + 8], 2
		mov		D[esi + 12], 3
	.fiY:

		ret
ENDF

GridFindFarthestPosition:
	FRAME	pGrid, posX, posY, DirX, DirY, pPOSfarthest, pPOSnext
	USES	ebx,esi,edi
	LOCALS	prevX, prevY, currX, currY
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered GridFindFarthestPosition(pGrid=%X,posX=%d,posY=%d,DirX=%d,DirY=%d,pPOSfarthest=%X,pPOSnext=%X)',0Dh,0Ah,0>
		writeln(eax, [pGrid],[posX],[posY],[DirX],[DirY],[pPOSfarthest],[pPOSnext])
		#endif
		#ifdef GRID_DUMP
		mov		eax, ADDR <'    Before GridFindFarthestPosition :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		#endif

		mov		eax, D[posX]
		mov		edx, D[posY]

	.do:
		mov		D[prevX], eax
		mov		D[prevY], edx
		add		eax, [DirX]
		add		edx, [DirY]
		
		push	eax, edx
		invoke	GridWithinBounds, [pGrid], eax, edx
		test	eax, eax
		jz		>.enddo
		pop		edx, eax
		push	eax, edx
		invoke	GridCellAvaliable, [pGrid], eax, edx
		test	eax, eax
		jz		>.enddo
		pop		edx, eax
		jmp		<.do
	.enddo:
		pop		edx, eax

		mov		esi, [pPOSfarthest]
		mov		edi, [pPOSnext]
		mov		[edi + POS.x], eax
		mov		[edi + POS.y], edx
		mov		eax, [prevX]
		mov		edx, [prevY]
		mov		[esi + POS.x], eax
		mov		[esi + POS.y], edx		
		
		#ifdef GRID_DUMP
		pusha
		mov		eax, ADDR <'    After GridFindFarthestPosition :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		popa
		#endif
		ret
ENDF

GridWithinBounds:
	FRAME	pGrid, posX, posY
		#ifdef GRID_DUMP
		mov		eax, ADDR <'    Before GridWithinBounds :',0Dh,0Ah,0>
		writeln(eax)
		invoke	GridWriteln, [pGrid]
		#endif

		mov		eax, [posX]
		mov		edx, [posY]
		cmp		eax, 0
		jl		>.false
		cmp		eax, Grid_Size
		jge		>.false
		cmp		edx, 0
		jl		>.false
		cmp		edx, Grid_Size
		jge		>.false
		mov		eax, 1
		ret
	.false
		xor		eax, eax
		ret
ENDF

// counts the number of isolated groups. 
GridIslands:
	FRAME	pGrid
	USES	ebx,esi,edi
	LOCALS	islands, x, y
		#ifdef GRID_EVAL_DEBUG
			pusha
			mov		eax, ADDR <'Entered GridIslands(pGrid=%X)',0Dh,0Ah,0>
			writeln(eax, [pGrid])
			invoke	GridPrint, [pGrid]
			writeln()
			popa
		#endif

		mov		D[islands], 0
		
		xor		ecx, ecx
	.while1: ; ecx != Grid_Cell_Count
		cmp		ecx, Grid_Cell_Count
		je		>.endwhile1
	.do1:
		push	ecx
		invoke	IdxToXY, ecx
		invoke	GridCellContent, [pGrid], eax, edx
		test	eax, eax
		jz		>.continue1
		
		mov		esi, eax
		mov		B[esi + TILE.marked], 0
	.continue1:
		pop		ecx
		inc		ecx
		jmp		<.while1
	.endwhile1:
		
		xor		ecx, ecx
	.while2: ; ecx != Grid_Cell_Count
		cmp		ecx, Grid_Cell_Count
		je		>.endwhile2
	.do2:
		push	ecx
		invoke	IdxToXY, ecx
		mov		[x], eax
		mov		[y], edx
		invoke	GridCellContent, [pGrid], eax, edx
		test	eax, eax
		jz		>.continue2
		mov		esi, eax
		mov		al, [esi + TILE.marked]
		test	al, al
		jnz		>.continue2
		
		inc		D[islands]
		invoke	Islands_Mark, [pGrid], [x], [y], [esi + TILE.value]
	.continue2:
		pop		ecx
		inc		ecx
		jmp		<.while2
	.endwhile2:
		
		mov		eax, [islands]

		#ifdef GRID_EVAL_DEBUG
			pusha
			mov		eax, ADDR <'    GridIslands returned %d',0Dh,0Ah,0>
			writeln(eax, [islands])
			popa
		#endif
		ret
ENDF

GridMaxValue:
	FRAME	pGrid
	USES	ebx,esi,edi
	LOCALS	maxValue
		mov		D[maxValue], 0
		invoke	GridEachTile, [pGrid], ADDR MaxValue_Callback, ADDR maxValue

		mov		eax, [maxValue]
		ret
ENDF

/*
GridSmoothness:
	FRAME	PGrid
	USES	ebx,esi,edi
	LOCALS	smoothness
		mov		D[smoothness], 0
		invoke	GridEachTile, [pGrid], ADDR Smoothness_Callback, ADDR smoothness

		mov		eax, [smoothness]
		ret
ENDF
*/

// measures how smooth the grid is (as if the values of the pieces
// were interpreted as elevations). Sums of the pairwise difference
// between neighboring tiles (in log space, so it represents the
// number of merges that need to happen before they can merge).
// Note that the pieces can be distant
GridSmoothness:
	FRAME	pGrid
	USES	ebx,esi,edi
	LOCALS	smoothness, value, direction, \
			posx, posy, \
			posNouse:POS, posNext:POS
		#ifdef GRID_EVAL_DEBUG
			pusha
			mov		eax, ADDR <'Entered GridSmoothness(pGrid=%X)',0Dh,0Ah,0>
			writeln(eax, [pGrid])
			invoke	GridPrint, [pGrid]
			writeln()
			popa
		#endif

		mov		D[smoothness], 0
		
		xor		ecx, ecx
	.while1: ; ecx != Grid_Cell_Count
		cmp		ecx, Grid_Cell_Count
		je		>>.endwhile1

		push	ecx
	.do1:		
		invoke	IdxToXY, ecx
		mov		[posx], eax
		mov		[posy], edx
		invoke	GridCellContent, [pGrid], eax, edx
		test	eax, eax
		jz		>.continue1
		mov		esi, eax
		mov		eax, [esi + TILE.value]
		inc		eax
		mov		[value], eax
		
		mov		D[direction], 1
		.for: ;(direction=1;direction<=2;direction++)
			cmp		D[direction], 2
			ja		>.endfor
			
			invoke	GetDirVector, [direction]
			invoke	GridFindFarthestPosition, [pGrid], [posx], [posy], eax, edx, \
												ADDR posNouse, ADDR posNext
			invoke	GridCellContent, [pGrid], [posNext.x], [posNext.y]
			test	eax, eax
			jz		>
			mov		edi, eax
			; eax = targetValue
			mov		eax, [edi + TILE.value]
			inc		eax
			; eax = (value - targetValue)
			sub		eax, [value]
			; eax = abs(eax)
			abseax()
			sub		[smoothness], eax
			:
		.forcont:
			inc		D[direction]
			jmp		<.for
		.endfor:
	.continue1:
		pop		ecx
		inc		ecx
		jmp		<.while1
	.endwhile1:
	
		mov		eax, [smoothness]

		#ifdef GRID_EVAL_DEBUG
			pusha
			mov		eax, ADDR <'    GridSmoothness returned %d',0Dh,0Ah,0>
			writeln(eax, [smoothness])
			popa
		#endif
		ret
ENDF

// measures how monotonic the grid is. This means the values of the tiles are strictly increasing
// or decreasing in both the left/right and up/down directions
// returns a signed int
GridMonotonicity2:
	FRAME	pGrid
	USES	ebx,esi,edi
	LOCALS	total0, total1, total2, total3, \ //scores for all four directions
			idxX, idxY, \
			current, next, \
			currentValue, nextValue
		#ifdef GRID_EVAL_DEBUG
			pusha
			mov		eax, ADDR <'Entered GridMonotonicity2(pGrid=%X)',0Dh,0Ah,0>
			writeln(eax, [pGrid])
			invoke	GridPrint, [pGrid]
			writeln()
			popa
		#endif

		mov		D[total0], 0
		mov		D[total1], 0
		mov		D[total2], 0
		mov		D[total3], 0

		// up/down direction
		mov		D[idxX], 0
	.for1: ;(idxX = 0; idxX < 4; idxX ++)
		cmp		D[idxX], 4
		jae		>>.endfor1

		mov		D[current], 0
		mov		D[next], 1
		.while1: ;(next < 4)
			cmp		D[next], 4
			jae		>>.endwhile1

			.while2: ;(next < 4 && !GridCellOccupied(x, next))
				cmp		D[next], 4
				jae		>.endwhile2
				invoke	GridCellOccupied, [pGrid], [idxX], [next]
				test	eax, eax
				jnz		>.endwhile2

				inc		D[next]
			.endwhile2:

			.if1: ;(next >=4)
			cmp		D[next], 4
			jb		>.endif1
			dec		D[next]
			.endif1:

			mov		D[currentValue], 0
			invoke	GridCellContent, [pGrid], [idxX], [current]
			test	eax, eax
			jz		>
			mov		edx, [eax + TILE.value]
			inc		edx
			mov		D[currentValue], edx
			:

			mov		D[nextValue], 0
			invoke	GridCellContent, [pGrid], [idxX], [next]
			test	eax, eax
			jz		>
			mov		edx, [eax + TILE.value]
			inc		edx
			mov		D[nextValue], edx
			:

			.if2: ;(currentValue > nextValue)
			mov		eax, [currentValue]
			cmp		eax, [nextValue]
			ja		>.then2
			jb		>.elif2
			.then2:
				mov		edx, [nextValue]
				sub		edx, eax
				add		[total0], edx
				jmp		>.endif2
			.elif2:
				sub		eax, [nextValue]
				add		[total1], eax
			.endif2:

			mov		eax, [next]
			mov		[current], eax
			inc		D[next]
		.endwhile1:
	.continue1:
		inc		D[idxX]
	.endfor1:

		// left/right direction
		mov		D[idxY], 0
	.for2: ;(idxY = 0; idxY < 4; idxY ++)
		cmp		D[idxY], 4
		jae		>>.endfor2

		mov		D[current], 0
		mov		D[next], 1
		.while3: ;(next < 4)
			cmp		D[next], 4
			jae		>>.endwhile3

			.while4: ;(next < 4 && !GridCellOccupied(next, y))
				cmp		D[next], 4
				jae		>.endwhile4
				invoke	GridCellOccupied, [pGrid], [next], [idxY]
				test	eax, eax
				jnz		>.endwhile4

				inc		D[next]
			.endwhile4:

			.if3: ;(next >=4)
			cmp		D[next], 4
			jb		>.endif3
			dec		D[next]
			.endif3:

			mov		D[currentValue], 0
			invoke	GridCellContent, [pGrid], [current], [idxY]
			test	eax, eax
			jz		>
			mov		edx, [eax + TILE.value]
			inc		edx
			mov		D[currentValue], edx
			:

			mov		D[nextValue], 0
			invoke	GridCellContent, [pGrid], [next], [idxY]
			test	eax, eax
			jz		>
			mov		edx, [eax + TILE.value]
			inc		edx
			mov		D[nextValue], edx
			:

			.if4: ;(currentValue > nextValue)
			mov		eax, [currentValue]
			cmp		eax, [nextValue]
			ja		>.then4
			jb		>.elif4
			.then4:
				mov		edx, [nextValue]
				sub		edx, eax
				add		[total2], edx
				jmp		>.endif4
			.elif4:
				sub		eax, [nextValue]
				add		[total3], eax
			.endif4:

			mov		eax, [next]
			mov		[current], eax
			inc		D[next]
		.endwhile3:
	.continue2:
		inc		D[idxY]
	.endfor2:

		mov		eax, [total0]
		cmp		eax, [total1]
		jge		>
		mov		eax, [total1]
		:
		mov		edx, [total2]
		cmp		edx, [total3]
		jge		>
		mov		edx, [total3]
		:

		add		eax, edx

		#ifdef GRID_EVAL_DEBUG
			pusha
			mov		edx, eax
			mov		eax, ADDR <'    GridMonotonicity2 returned %d',0Dh,0Ah,0>
			writeln(eax, edx)
			popa
		#endif
		ret
ENDF
// --------------------------------------------------------------
//                      Private Datas
// --------------------------------------------------------------
	.CONST
DirVector	POS		<-1, 0>, \	; up
					<0, 1>,	\	; right
					<1, 0>,	\	; down
					<0, -1>		; left
					

// --------------------------------------------------------------
//                      Private Functions
// --------------------------------------------------------------
	.CODE

// Returns eax = idx
XYToIdx:
	FRAME	posX, posY
	USES	ebx
		mov		eax, [posX]
		xor		edx, edx
		mov		ebx, Grid_Size
		mul		ebx
		add		eax, [posY]
		ret
ENDF

// Returns eax = x, edx = y
IdxToXY:
	FRAME	idx
	USES	ebx
		mov		eax, [idx]
		mov		ebx, Grid_Size
		xor		edx, edx
		div		ebx
		ret
ENDF

RandomNumber:
	FRAME	Max
	USES	ebx,esi,edi
	LOCALS	hProv, buffer
		invoke	CryptAcquireContext, ADDR hProv, NULL, NULL, \
									PROV_RSA_FULL, \
									CRYPT_VERIFYCONTEXT | CRYPT_SILENT
		invoke	CryptGenRandom, [hProv], 4, ADDR buffer
		invoke	CryptReleaseContext, [hProv], 0
		mov		eax, [buffer]
		xor		edx, edx
		div		D[Max]
		mov		eax, edx
		ret
ENDF

PrepareCells_CallBack:
	FRAME	posx, posy, pTile, pParameter
	USES	ebx,esi,edi
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered PrepareCells_CallBack(posx=%d,posy=%d,pTile=%X,pParameter=%X)',0Dh,0Ah,0>
		writeln(eax, [posx],[posy],[pTile],[pParameter])
		#endif

		mov		esi, [pTile]
		test	esi, esi
		jz		>.return
		invoke	TileClear, esi
		invoke	TileSavePosition, esi
	.return:
		ret
ENDF

TileMatches_CallBack:
	FRAME	posx, posy, pTile, pParameter ; (pParameter[0] = pnMatches, pParameter[1] = pGrid)
	USES	ebx,esi,edi
	LOCALS	dirx, diry, pOther
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Entered TileMatches_CallBack(posx=%d,posy=%d,pTile=%X,pParameter=%X)',0Dh,0Ah,0>
		writeln(eax, [posx],[posy],[pTile],[pParameter])
		#endif

		mov		esi, [pTile]
		test	esi, esi
		jz		>.return
		mov		ecx, 4
	.lp:
		mov		eax, ecx
		dec		eax
		invoke	GetDirVector, eax
		mov		[dirx], eax
		mov		[diry], edx
		add		eax, [posx]
		add		edx, [posy]

		mov		edi, [pParameter]
		invoke	GridCellContent, [edi + 4], eax, edx
		test	eax, eax
		jz		>.continue
		mov		edi, eax
		mov		eax, [esi + TILE.value]
		cmp		[edi + TILE.value], eax
		jne		>.continue
		mov		edi, [pParameter]
		mov		eax, [edi]
		inc		D[eax]
		ret
	.continue:
		loop	<.lp

	.return:
		ret
ENDF

MaxValue_Callback:
	FRAME	posx, posy, pTile, pRes ; (pParameter=pRes)
	USES	ebx,esi,edi
		mov		esi, [pTile]
		test	esi, esi
		jz		>.return

		mov		edi, [pRes]
		mov		eax, [esi + TILE.value]
		mov		edx, [edi]
		cmp		eax, edx
		jbe		>
		mov		D[edi], eax
		:
	.return:
		ret
ENDF

Smoothness_Callback:
	FRAME	posx, posy, pTile, pRes ; (pParameter=pRes)
	USES	ebx,esi,edi
		mov		esi, [pTile]
		test	esi, esi
		jz		>.return

		mov		edi, [pRes]
		mov		eax, [esi + TILE.value]



	.return:
		ret
ENDF

Islands_Mark:
	FRAME	pGrid, posx, posy, value
	USES	ebx,esi,edi
	.if: ; x >= 0 && x <= 3 && y >= 0 && y <= 3
		invoke	GridWithinBounds, [pGrid], [posx], [posy]
		test	eax, eax
		jz		>.endif
		; not null
		invoke	GridCellContent, [pGrid], [posx], [posy]
		test	eax, eax
		jz		>.endif
		; cells[posx][posy].value == value
		mov		esi, eax
		mov		eax, [value]
		cmp		eax, [esi + TILE.value]
		jne		>.endif
		; !cells[posx][posy].marked
		mov		al, [esi + TILE.marked]
		test	al, al
		jnz		>.endif
	.then:
		invoke	GridCellContent, [pGrid], [posx], [posy]
		mov		esi, eax
		mov		B[esi + TILE.marked], 1
		
		; for(ecx in [0,1,2,3])
		xor		ecx, ecx
		.while:
		cmp		ecx, 4
		je		>.endwhile
		.do:
		push	ecx
		
		invoke	GetDirVector, ecx
		add		eax, [posx]
		add		edx, [posy]
		invoke	Islands_Mark, [pGrid], eax, edx, [value]
		
		pop		ecx
		inc		ecx
		jmp		<.while
		.endwhile:
	.endif:
		ret
ENDF