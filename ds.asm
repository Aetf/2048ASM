#include "game.h"
#include "Dshow.h"


	.DATA
useguid(CLSID_FilterGraph)
useguid(IID_IGraphBuilder)
useguid(IID_IMediaControl)
useguid(IID_IMediaEventEx)
useguid(IID_IMediaPosition)

	.CODE
DSInitialize:
	FRAME	hWnd, ppBGMCtrl, ppSECtrl
	USES	ebx,esi,edi
	LOCALS	pEventEx
		invoke	CoInitialize, NULL
		cmp		eax, S_OK
		je		>
			mov		ebx, ADDR <'CoInitialize failed with code %d(%X)',0Dh,0Ah,0>
			writeln(ebx, eax, eax)
			jmp		>>.Error
		:

		invoke	PrepareSound, ADDR L'Resources\\loop06a.mp3'
		test	eax, eax
		jz		>>.Error
		mov		esi, [ppBGMCtrl]
		mov		[esi], eax

		coinvoke(eax, IMediaControl.QueryInterface, ADDR IID_IMediaEventEx, ADDR pEventEx)
		mov		esi, [ppBGMCtrl]
		mov		eax, [esi]
		coinvoke([pEventEx], IMediaEventEx.SetNotifyWindow, [hWnd], WM_GRAPHNOTIFY_LOOP, eax)
		coinvoke([pEventEx], IMediaEventEx.Release)

		invoke	PrepareSound, ADDR L'Resources\\move.mp3'
		test	eax, eax
		jz		>.Error
		mov		esi, [ppSECtrl]
		mov		[esi], eax

		;coinvoke(eax, IMediaControl.QueryInterface, ADDR IID_IMediaEventEx, ADDR pEventEx)
		;mov		esi, [ppSECtrl]
		;mov		eax, [esi]
		;coinvoke([pEventEx], IMediaEventEx.SetNotifyWindow, [hWnd], WM_GRAPHNOTIFY_STOP, eax)
		;coinvoke([pEventEx], IMediaEventEx.Release)
		
		mov		eax, 1
		ret
	.Error:
		xor		eax, eax
		ret
ENDF

DSUninitialize:
	FRAME	pBGMCtrl, pSECtrl
	USES	ebx,esi,edi
	LOCALS	pBGMEvent, pSEEvent
		coinvoke([pBGMCtrl], IMediaControl.QueryInterface, ADDR IID_IMediaEventEx, ADDR pBGMEvent)
		coinvoke([pBGMEvent], IMediaEventEx.SetNotifyWindow, NULL, 0, 0)
		coinvoke([pBGMEvent], IMediaEventEx.Release)

		;coinvoke([pSECtrl], IMediaControl.QueryInterface, ADDR IID_IMediaEventEx, ADDR pSEEvent)
		;coinvoke([pSEEvent], IMediaEventEx.SetNotifyWindow, NULL, 0, 0)
		;coinvoke([pSEEvent], IMediaEventEx.Release)

		coinvoke([pBGMCtrl], IMediaControl.Release)
		coinvoke([pSECtrl], IMediaControl.Release)
		invoke	CoUninitialize
		ret
ENDF

DSPlay:
	FRAME	pControl
	USES	ebx,esi,edi
	LOCALS	fstate
		coinvoke([pControl], IMediaControl.GetState, 5, ADDR fstate)
		mov		eax, [fstate]
		cmp		eax, State_Running
		jne		>
		invoke	DSStop, [pControl]
		:
		coinvoke([pControl], IMediaControl.Run)
		ret
ENDF

DSStop:
	FRAME	pControl
	USES	ebx,esi,edi
	LOCALS	pPositions
		coinvoke([pControl], IMediaControl.Stop)
		coinvoke([pControl], IMediaControl.QueryInterface, ADDR IID_IMediaPosition, ADDR pPositions)
		coinvoke([pPositions], IMediaPosition.put_CurrentPosition, 0)
		coinvoke([pPositions], IMediaPosition.Release)
		ret
ENDF

DSPause:
	FRAME	pControl
	USES	ebx,esi,edi
	coinvoke([pControl], IMediaControl.Stop)
	ret
ENDF

DSHandleLoop:
	FRAME	instanceData
	USES	ebx,esi,edi
	LOCALS	pEventEx
		coinvoke([instanceData], IMediaControl.QueryInterface, ADDR IID_IMediaEventEx, ADDR pEventEx)
		invoke	LoopGetEvent, [pEventEx], ADDR DoLoopback, [instanceData]
		coinvoke([pEventEx], IMediaEventEx.Release)
		ret
ENDF

DSHandleStop:
	FRAME	instanceData
	USES	ebx,esi,edi
	LOCALS	pEventEx
		coinvoke([instanceData], IMediaControl.QueryInterface, ADDR IID_IMediaEventEx, ADDR pEventEx)
		invoke	LoopGetEvent, [pEventEx], ADDR DSStop, [instanceData]
		coinvoke([pEventEx], IMediaEventEx.Release)
		ret
ENDF



LoopGetEvent:
	FRAME	pEventEx, pCallback, pControl
	USES	ebx,esi,edi
	LOCALS	evCode, param1, param2
	.while:
		coinvoke([pEventEx], IMediaEventEx.GetEvent, ADDR evCode, ADDR param1, ADDR param2, 0)
		cmp		eax, S_OK
		jne		>.endwhile
		coinvoke([pEventEx], IMediaEventEx.FreeEventParams, [evCode], [param1], [param2])
		mov		eax, [evCode]
		cmp		eax, EC_COMPLETE
		jne		>.continue
		invoke	[pCallback], [pControl]
	.continue:
		jmp		<.while
	.endwhile:
		ret
ENDF

DoLoopback:
	FRAME	pControl
	USES	ebx,esi,edi
	LOCALS	pPositions
		invoke	DSPlay, [pControl]
		ret
ENDF

// return a pointer to IMediaControl in eax
PrepareSound:
	FRAME	pwStrPath
	USES	ebx,esi,edi
	LOCALS	pGraph, pControl
		invoke	CoCreateInstance, ADDR CLSID_FilterGraph, NULL, \
								CLSCTX_INPROC_SERVER, ADDR IID_IGraphBuilder, ADDR pGraph
		cmp		eax, S_OK
		je		>
			mov		ebx, ADDR <'CoCreateInstance failed with code %d(%X)',0Dh,0Ah,0>
			writeln(ebx, eax, eax)
			jmp		>>.Error
		:

		coinvoke([pGraph], IGraphBuilder.QueryInterface, ADDR IID_IMediaControl, ADDR pControl)
		cmp		eax, S_OK
		je		>
			mov		ebx, ADDR <'IGraphBuilder.QueryInterface for IID_IMediaControl failed with code %d(%X)',0Dh,0Ah,0>
			writeln(ebx, eax, eax)
			jmp		>>.Error
		:

		coinvoke([pGraph], IGraphBuilder.RenderFile, [pwStrPath], NULL)
		cmp		eax, S_OK
		je		>
			;invoke	GetLastError
			mov		ebx, ADDR <'IGraphBuilder.RenderFile failed with code %d(%X)',0Dh,0Ah,0>
			writeln(ebx, eax, eax)
			jmp		>>.Error
		:

		coinvoke([pGraph], IGraphBuilder.Release)

		mov		eax, [pControl]
		ret
	.Error:
		xor		eax, eax
		ret
ENDF