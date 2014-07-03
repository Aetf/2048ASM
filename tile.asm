#include "game.h"
	.CODE
TileConstruct:
	FRAME	pTile
	USES	ebx,esi,edi
		mov		eax, [pTile]
		mov		esi, eax

		mov		D[esi + TILE.previousPos + POS.x], -1
		mov		D[esi + TILE.previousPos + POS.y], -1
		mov		D[esi + TILE.mergedFrom], 0
		mov		B[esi + TILE.marked], 0
		ret
ENDF

TileDeconstruct:
	FRAME	pTile
	USES	ebx,esi,edi
		mov		esi, [pTile]
		mov		eax, [esi + TILE.mergedFrom]
		test	eax, eax
		jz		>
		invoke	DeleteTile, eax
		:
		mov		eax, [esi + TILE.mergedFrom + 4]
		test	eax, eax
		jz		>
		invoke	DeleteTile, eax
		:
		ret
ENDF

NewTile:
	FRAME
	USES	ebx,esi,edi
	LOCALS	pTile
	; Allocate a new Tile object		
		invoke	Malloc, SIZEOF(TILE)

		push	eax
		invoke	TileConstruct, eax
		pop		eax
		ret
ENDF

MakeTile:
	FRAME	pPos, value
	USES	ebx,esi,edi
	LOCALS	pTile
		mov		esi, [pPos]
		invoke	NewTile
		mov		edx, [esi + POS.x]
		mov		[eax + TILE.x], edx
		mov		edx, [esi + POS.y]
		mov		[eax + TILE.y], edx
		mov		edx, [value]
		mov		[eax + TILE.value], edx
		ret
ENDF

DeleteTile:
	FRAME	pTile
	USES	ebx,esi,edi
		mov		eax, [pTile]
		test	eax, eax
		jz		>.return

		invoke	TileDeconstruct, eax

		invoke	Free, [pTile]
	.return:
		ret
ENDF

TileClone:
	FRAME	pTile
	USES	ebx,esi,edi
	LOCALS	pNewTile
		invoke	NewTile
		mov		edi, eax
		mov		esi, [pTile]

		mov		eax, [esi + TILE.x]
		mov		[edi + TILE.x], eax
		mov		eax, [esi + TILE.y]
		mov		[edi + TILE.y], eax
		mov		eax, [esi + TILE.value]
		mov		[edi + TILE.value], eax

		mov		D[edi + TILE.previousPos + POS.x], -1
		mov		D[edi + TILE.previousPos + POS.y], -1

		mov		D[edi + TILE.mergedFrom], 0
		mov		D[edi + TILE.mergedFrom + 4], 0

		mov		eax, edi
		ret
ENDF

TileClear:
	FRAME	pTile
	USES	esi
		#ifdef TILE_DEBUG
			pusha
			mov		eax, ADDR <'Entered TileClear(pTile=%X)',0Dh,0Ah,0>
			writeln(eax, [pTile])
			popa
		#endif

		mov		esi, [pTile]
		mov		eax, [esi + TILE.mergedFrom]
		test	eax, eax
		jz		>
		invoke	DeleteTile, eax
		mov		D[esi + TILE.mergedFrom], 0
		
		:
		mov		eax, [esi + TILE.mergedFrom + 4]
		test	eax, eax
		jz		>
		invoke	DeleteTile, eax
		mov		D[esi + TILE.mergedFrom + 4], 0
		
		:
		ret
ENDF

TileSavePosition:
	FRAME	pTile
	USES	ebx,esi
		#ifdef TILE_DEBUG
			pusha
			mov		eax, ADDR <'Entered TileSavePosition(pTile=%X)',0Dh,0Ah,0>
			writeln(eax, [pTile])
			popa
		#endif
		
		mov		esi, [pTile]
		mov		eax, [esi + TILE.x]
		mov		ebx, [esi + TILE.y]

		mov		[esi + TILE.previousPos.x], eax
		mov		[esi + TILE.previousPos.y], ebx
		ret
ENDF

TileUpdatePosition:
	FRAME	pTile, posX, posY
	USES	ebx,esi
		mov		esi, [pTile]
		mov		eax, [posX]
		mov		ebx, [posY]
		mov		[esi + TILE.x], eax
		mov		[esi + TILE.y], ebx
		ret
ENDF

TilePrint:
	FRAME	pTile
	USES	eax,ebx,ecx,edx,esi,edi
		mov		ebx, [pTile]
		test	ebx, ebx
		jz		>>
		mov		ecx, [ebx + TILE.value]
		mov		edx, 2
		shl		edx, cl
		mov		eax, ADDR <' %d ',0>
		writeln(eax, edx)

		jmp		>.endif
		:
		mov		eax, ADDR <' - ',0>
		writeln(eax)
		.endif:
		ret
ENDF

TileWriteln:
	FRAME	pTile
	USES	eax,ebx,ecx,edx,esi,edi
		mov		ebx, [pTile]
		test	ebx, ebx
		jz		>>
		mov		ecx, [ebx + TILE.value]
		mov		edx, 2
		shl		edx, cl
		mov		eax, ADDR <' %dp{%d,%d}m{',0>
		writeln(eax, edx,[ebx+TILE.x],[ebx+TILE.y])

		invoke	TileWriteln, [ebx + TILE.mergedFrom]
		mov		eax, ADDR <',',0>
		writeln(eax)
		invoke	TileWriteln, [ebx + TILE.mergedFrom+4]
		mov		eax, ADDR <' }f{%d,%d}@%X',0>
		writeln(eax, [ebx+TILE.previousPos+POS.x], [ebx+TILE.previousPos+POS.y], ebx)
		jmp		>.endif
		:
		mov		eax, ADDR <' - ',0>
		writeln(eax)
		.endif:
		ret
ENDF