#include "game.h"
	.CODE
//--------------------------------------------------------------------
//                  CDispTile methods
//--------------------------------------------------------------------
CDispTileConstruct:
	FRAME	pDispTile
	USES	ebx,esi,edi
		mov		esi, [pDispTile]
		mov		D[esi + CDispTile.value], 0
		ret
ENDF

CDispTileDeconstruct:
	FRAME	pDispTile
	USES	ebx,esi,edi
		mov		esi, [pDispTile]

		ret
ENDF

NewCDispTile:
	FRAME
	USES	ebx,esi,edi
	LOCALS	__fix ; due to a goasm bug
	; Allocate a new Tile object		
		invoke	Malloc, SIZEOF(CDispTile)

		push	eax
		invoke	CDispTileConstruct, eax
		pop		eax
		ret
ENDF

DeleteCDispTile:
	FRAME	pDispTile
	USES	ebx,esi,edi
		mov		eax, [pDispTile]
		test	eax, eax
		jz		>.return

		invoke	CDispTileDeconstruct, eax

		invoke	Free, [pDispTile]
	.return:
		ret
ENDF

CDispTileWriteln:
	FRAME	pDispTile
	USES	ebx,esi,edi
		mov		esi, [pDispTile]
		test	esi, esi
		jnz		>
		mov		eax, ADDR <'null',0>
		writeln(eax)
		jmp		>.return
		:

		mov		ecx, [esi + CDispTile.value]
		mov		edx, 2
		shl		edx, cl
		lea		edi, [esi + CDispTile.rect]
		mov		eax, ADDR <'%d@[%d,%d]-[%d,%d]',0>
		writeln(eax, edx, [edi + RECT.left], [edi+RECT.top],[edi+RECT.right],[edi+RECT.bottom])
	.return:
		ret
ENDF

//--------------------------------------------------------------------
//                  CDispSnapshot methods
//--------------------------------------------------------------------
CDispSnapshotConstruct:
	FRAME	pDispSnapshot
	USES	ebx,esi,edi
		mov		esi, [pDispSnapshot]
		
		mov		edi, esi
		add		edi, CDispSnapshot.dispTiles

		mov		ecx, SNAPSHOP_MAX_TILE
		:
		mov		D[edi + 4*ecx - 4], 0
		loop	<
		
		ret
ENDF

CDispSnapshotDeconstruct:
	FRAME	pDispSnapshot
	USES	ebx,esi,edi
		mov		esi, [pDispSnapshot]
		mov		edi, esi
		add		edi, CDispSnapshot.dispTiles

	.while: ; ([edi] != NULL)
		mov		eax, [edi]
		test	eax, eax
		jz		>.endwhile
		invoke	DeleteCDispTile, eax
		mov		D[edi], 0
		add		edi, 4
		jmp		<.while
	.endwhile:

		ret
ENDF

NewCDispSnapshot:
	FRAME
	USES	ebx,esi,edi
	LOCALS	__fix ; due to a goasm bug
	; Allocate a new Tile object		
		invoke	Malloc, SIZEOF(CDispSnapshot)

		mov		ebx, eax
		invoke	CDispSnapshotConstruct, eax
		mov		eax, ebx

		#ifdef ANIMATION_DEBUG5
		pusha
		mov		edx, ADDR <'New CDispSnapshot@%X',0Dh,0Ah,0>
		writeln(edx, ebx)
		popa
		#endif
		ret
ENDF

DeleteCDispSnapshot:
	FRAME	pDispSnapshot
	USES	ebx,esi,edi
	LOCALS	__fix ; due to a goasm bug
		mov		eax, [pDispSnapshot]
		test	eax, eax
		jz		>.return

		#ifdef ANIMATION_DEBUG5
		pusha
		mov		edx, ADDR <'Delete CDispSnapshot@%X',0Dh,0Ah,0>
		writeln(edx, [pDispSnapshot])
		popa
		#endif

		invoke	CDispSnapshotDeconstruct, eax

		invoke	Free, [pDispSnapshot]
	.return:
		ret
ENDF

CDispSnapshotAppendTile:
	FRAME	pDispSnapshot, pDispTile
	USES	ebx,esi,edi
		mov		edi, [pDispSnapshot]
		add		edi, CDispSnapshot.dispTiles
		mov		esi, [pDispTile]

	#ifdef	ANIMATION_DEBUG
		pusha
		mov		eax, ADDR <'Added CDispTile',0>
		writeln(eax)
		invoke	CDispTileWriteln, esi
		mov		eax, ADDR <' to snapshot %X',0Dh,0Ah,0>
		writeln(eax)
		popa
	#endif

	.while: ; ([edi] != NULL)
		mov		eax, [edi]
		test	eax, eax
		jz		>.endwhile
		add		edi, 4
		jmp		<.while
	.endwhile:

		mov		D[edi], esi
		mov		D[edi + 4], 0
		ret
ENDF

CDispSnapshotWriteln:
	FRAME	pDispSnapshot
	USES	ebx,esi,edi
		mov		esi, [pDispSnapshot]

		mov		eax, ADDR <'    DispSnapshot@%X',0Dh,0Ah,0>
		writeln(eax, [pDispSnapshot])

		mov		eax, ADDR <'    GridRect= (%d,%d),(%d,%d)',0Dh,0Ah,0>
		writeln(eax, [esi + CDispSnapshot.gridRect+RECT.left],\
					[esi + CDispSnapshot.gridRect+RECT.top],\
					[esi + CDispSnapshot.gridRect+RECT.right],\
					[esi + CDispSnapshot.gridRect+RECT.bottom])

		mov		esi, [pDispSnapshot]
		add		esi, CDispSnapshot.dispTiles
	.while: ; ([esi] != NULL)
		mov		eax, [esi]
		test	eax, eax
		jz		>.endwhile

		mov		ebx, ADDR <'    ',0>
		writeln(ebx)
		invoke	CDispTileWriteln, eax
		writeln()

		add		esi, 4
		jmp		<.while
	.endwhile:
		ret
ENDF

// return true to continue, false to break
CDispSnapshotEachDispTile:
	FRAME	pDispSnapshot, pCallback, pParameter
	USES	ebx,esi,edi
		mov		esi, [pDispSnapshot]
		add		esi, CDispSnapshot.dispTiles

	.while: ; ([esi] != NULL)
		mov		eax, [esi]
		test	eax, eax
		jz		>.endwhile

		invoke	[pCallback], eax, [pParameter]
		test	eax, eax
		jz		>.endwhile

		add		esi, 4
		jmp		<.while
	.endwhile:
		ret
ENDF

//--------------------------------------------------------------------
//                  CAnimMeta methods
//--------------------------------------------------------------------
CAnimMetaConstruct:
	FRAME	pMeta
	USES	ebx,esi,edi
		mov		esi, [pMeta]

		mov		D[esi + CAnimMeta.endTime], 0
		mov		D[esi + CAnimMeta.startTime], 0

		mov		D[esi + CAnimMeta.type], ANIMATION_TYPE_NONE
		mov		D[esi + CAnimMeta.endBehavior], ANIMATION_BEHAVIOR_KEEP_FINAL
		ret
ENDF

CAnimMetaDeconstruct:
	FRAME	pMeta
	USES	ebx,esi,edi
		mov		esi, [pMeta]

		ret
ENDF

NewCAnimMeta:
	FRAME
	USES	ebx,esi,edi
	LOCALS	__fix ; due to a goasm bug
	; Allocate a new Tile object		
		invoke	Malloc, SIZEOF(CAnimMeta)

		push	eax
		invoke	CAnimMetaConstruct, eax
		pop		eax
		ret
ENDF

DeleteCAnimMeta:
	FRAME	pMeta
	USES	ebx,esi,edi
	LOCALS	__fix ; due to a goasm bug
		mov		eax, [pMeta]
		test	eax, eax
		jz		>.return

		invoke	CAnimMetaDeconstruct, eax

		invoke	Free, [pMeta]
	.return:
		ret
ENDF

// Construct a CanimMeta from a moved tile
CAnimMetaFromMovedTile:
	FRAME	pMerged, type, start, duration
	USES	ebx,esi,edi
		#ifdef ANIMATION_DEBUG
		pusha
		pushf
		mov		eax, ADDR <'Entered CAnimMetaFromMovedTile(pMerged=%X,type=%d,start=%d,duration=%d)',0Dh,0Ah,0>
		writeln(eax, [pMerged], [type], [start], [duration])
		popf
		popa
		#endif

		mov		esi, [pMerged]
		invoke	NewCAnimMeta
		mov		edi, eax
		// fromPos
		mov		eax, [esi + TILE.previousPos+POS.x]
		mov		[edi + CAnimMeta.fromPos + POS.x], eax
		mov		eax, [esi + TILE.previousPos+POS.y]
		mov		[edi + CAnimMeta.fromPos + POS.y], eax
		// toPos
		mov		eax, [esi + TILE.x]
		mov		[edi + CAnimMeta.toPos + POS.x], eax
		mov		eax, [esi + TILE.y]
		mov		[edi + CAnimMeta.toPos + POS.y], eax
		// start&end time
		mov		eax, [start]
		mov		D[edi + CAnimMeta.startTime], eax
		add		eax, [duration]
		mov		D[edi + CAnimMeta.endTime], eax
		// type
		mov		eax, [type]
		mov		D[edi + CAnimMeta.type], eax

		mov		eax, edi
		ret
ENDF

// Construct a CanimMeta from a new appeared tile
CAnimMetaFromNoMoveTile:
	FRAME	pNewTile, type, start, duration
	USES	ebx,esi,edi
		#ifdef ANIMATION_DEBUG
		pusha
		pushf
		mov		eax, ADDR <'Entered CAnimMetaFromNoMoveTile(pNewTile=%X,type=%d,start=%d,duration=%d)',0Dh,0Ah,0>
		writeln(eax, [pNewTile], [type], [start], [duration])
		popf
		popa
		#endif

		mov		esi, [pNewTile]
		invoke	NewCAnimMeta
		mov		edi, eax
		// fromPos & toPos
		mov		eax, [esi + TILE.x]
		mov		[edi + CAnimMeta.fromPos + POS.x], eax
		mov		[edi + CAnimMeta.toPos + POS.x], eax
		mov		eax, [esi + TILE.y]
		mov		[edi + CAnimMeta.fromPos + POS.y], eax
		mov		[edi + CAnimMeta.toPos + POS.y], eax
		
		// start&end time
		mov		eax, [start]
		mov		D[edi + CAnimMeta.startTime], eax
		add		eax, [duration]
		mov		D[edi + CAnimMeta.endTime], eax
		// type
		mov		eax, [type]
		mov		D[edi + CAnimMeta.type], eax

		mov		eax, edi
		ret
ENDF
//--------------------------------------------------------------------
//                  CDispTransition methods
//--------------------------------------------------------------------
CDispTransitionConstruct:
	FRAME	pTransition
	USES	ebx,esi,edi
		mov		esi, [pTransition]
		mov		edi, esi

		mov		D[esi + CDispTransition.endTime], 0
		mov		D[esi + CDispTransition.pTargetSnap], 0

		add		esi, CDispTransition.tiles
		add		edi, CDispTransition.meta

		mov		ecx, TRANSITION_MAX_TILE
		:
		mov		D[esi + 4*ecx - 4], 0
		mov		D[edi + 4*ecx - 4], 0
		loop	<
		ret
ENDF

CDispTransitionDeconstruct:
	FRAME	pTransition
	USES	ebx,esi,edi
		mov		esi, [pTransition]
		mov		edi, esi

		invoke	DeleteCDispSnapshot, [esi + CDispTransition.pTargetSnap]

		add		esi, CDispTransition.tiles
		add		edi, CDispTransition.meta

	.while: ; ([edi] != NULL)
		mov		eax, [edi]
		test	eax, eax
		jz		>.endwhile
		invoke	DeleteTile, [esi]
		mov		D[esi], 0
		invoke	DeleteCAnimMeta, [edi]
		mov		D[edi], 0
		add		esi, 4
		add		edi, 4
		jmp		<.while
	.endwhile:
		ret
ENDF

NewCDispTransition:
	FRAME
	USES	ebx,esi,edi
	LOCALS	__fix ; due to a goasm bug
	; Allocate a new Tile object		
		invoke	Malloc, SIZEOF(CDispTransition)

		push	eax
		invoke	CDispTransitionConstruct, eax
		pop		eax
		ret
ENDF

DeleteCDispTransition:
	FRAME	pTransition
	USES	ebx,esi,edi
	LOCALS	__fix ; due to a goasm bug
		mov		eax, [pTransition]
		test	eax, eax
		jz		>.return

		invoke	CDispTransitionDeconstruct, eax

		invoke	Free, [pTransition]
	.return:
		ret
ENDF

CDispTransitionAppendAnimTile:
	FRAME	pTransition, pTile, pMeta
	USES	ebx,esi,edi
		mov		esi, [pTransition]
		mov		edi, esi

		add		esi, CDispTransition.tiles
		add		edi, CDispTransition.meta
	.while: ; ([edi] != NULL)
		mov		eax, [edi]
		test	eax, eax
		jz		>.endwhile
		add		edi, 4
		add		esi, 4
		jmp		<.while
	.endwhile:
		mov		eax, [pMeta]
		mov		D[edi], eax
		mov		D[edi + 4], 0
		mov		eax, [pTile]
		mov		D[esi], eax
		mov		D[esi + 4], 0

		mov		esi, [pTransition]
		mov		edi, [pMeta]
		mov		eax, [esi + CDispTransition.endTime]
		mov		ebx, [edi + CAnimMeta.endTime]
		cmp		eax, ebx
		jae		>
		mov		[esi + CDispTransition.endTime], ebx
		:

		ret
ENDF

CDispTransitionEachAnimTile:
	FRAME	pTransition, pCallback, pParameter
	USES	ebx,esi,edi
	#ifdef TRANSITION_DEBUG
	mov		eax, ADDR <'Entered CDispTransitionEachAnimTile(pTransition=%X,pCallback=%X,pParameter=%X)',0Dh,0Ah,0>
	writeln(eax, [pTransition],[pCallback],[pParameter])
	#endif

		mov		esi, [pTransition]
		mov		edi, esi

		add		esi, CDispTransition.tiles
		add		edi, CDispTransition.meta

	.while: ; ([esi] != NULL)
		mov		eax, [esi]
		test	eax, eax
		jz		>.endwhile
		
		invoke	[pCallback], [esi], [edi], [pParameter]

		add		esi, 4
		add		edi, 4
		jmp		<.while
	.endwhile:
		ret
ENDF