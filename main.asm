#include "game.h"
#include "C99\\stdio.h"
#include "C99\\fcntl.h"


#ifdef UNICODE
DSS = DUS
#else
DSS = DB
#endif

;;
;;	RESOURCE IDs
;;

IDI_ICON	= 1h
IDM_MENU	= 1h
IDD_ABOUT	= 1h

IDM_FILEMENU	= 20h
IDM_HELPMENU	= 21h

IDM_EXIT	= 22h

IDM_ABOUT	= 24h

#define IDM_RESTART		0x25
#define IDM_MAN_ADD		0x26
#define IDM_ENABLE_AI	0x27
#define IDM_ENABLE_BGM	0x28
#define IDM_ENABLE_SE	0x29

	.DATA
STDOUT	DD	0
;;
;;	MAIN THREAD, WINDOW, and MESSAGE LOOP
;;
	.CODE
Start:
	#ifdef CONSOLE
	;Initialize a console
		invoke	AllocConsole
		invoke	CreateFile, ADDR "CONOUT$", GENERIC_READ | GENERIC_WRITE, \
							FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, 0
		
		invoke	_open_osfhandle, eax, O_TEXT
		add		esp, 8
		invoke	_fdopen, eax, ADDR "w+"
		add		esp, 8
		mov	[STDOUT], eax
		invoke	setvbuf, [STDOUT], NULL, 0x0004, 0
		add		esp, 10h
	#endif
	;Initialize the Main window
		call	MainINIT

		test	eax,eax		;Z to continue
		jnz		>.Exit		;NZ to exit

	;Process queued messages until WM_QUIT is received
		call	MsgLOOP		;returns exit code in EAX

	;End this process and all its threads
	.Exit
		;push	eax			;uExitCode
		;call	[ExitProcess]		;Kernel32
		invoke	ExitProcess, eax	;Kernel32
		ret


MsgLOOP:
	FRAME
	LOCAL	msg:MSG

		lea		esi,[msg]
		jmp		>.Retrieve

	;Dispatch the message to a window procedure
	.Dispatch
		;push	esi			;lpMsg
		;call	[TranslateMessage]	;User32
		invoke	TranslateMessage, \	;User32
				esi					;lpMsg

		;push	esi			;lpMsg
		;call	[DispatchMessage]	;User32
		invoke	DispatchMessage, \	;User32
				esi					;lpMsg

	;Retrieve a message from the thread message queue
	.Retrieve
		;push	0			;wMsgFilterMax
		;push	0			;wMsgFilterMin
		;push	0			;hWnd
		;push	esi			;lpMsg
		;call	[GetMessage]		;User32
		invoke	GetMessage, \		;User32
				esi, \				;lpMsg
				NULL, 0, 0				;hWnd, wMsgFilterMin, wMsgFilterMax

		cmp		eax,-1
		je		>.Exit		;E if error so exit

		test	eax,eax		;EAX=0 if WM_QUIT
		jnz		<.Dispatch	;NZ if other message retrieved so process it

		mov		eax,[msg.wParam]	;return ExitCode
	.Exit
		ret
ENDF


;;
;;	MAIN WINDOW CREATION
;;

	.CONST
szMainClass	DSS	"Main",0
	.DATA
hInst		DD	?
hwndMain	DD	?
hMemDC		DD	?
hbMemBmp	DD	?
hbMemBmpOld	DD	?

	.CODE
MainINIT:
	FRAME
	LOCAL	wcx:WNDCLASSEX

	;Get module handle for this process
		invoke	GetModuleHandle, 0 ; GetModuleHandle(lpModuleName) in Kernel32

		test	eax,eax
		jz		>>.Error

		mov		[hInst],eax
		mov		ebx,eax		;EBX=hInst

	;Register the Main window class
		xor		eax,eax		;EAX=0
		mov		D[wcx.cbSize], SIZEOF WNDCLASSEX
		mov		[wcx.style], eax
		mov		[wcx.lpfnWndProc], ADDR MainWND
		mov		[wcx.cbClsExtra], eax
		mov		[wcx.cbWndExtra], eax
		mov		[wcx.hInstance], ebx
		mov		D[wcx.hbrBackground], COLOR_WINDOW + 1
		mov		D[wcx.lpszMenuName], IDM_MENU
		mov		[wcx.lpszClassName], ADDR szMainClass

		; -- in User32
		; LoadImage(hinst, lpszName, uType, cxDesired, cyDesired, fuLoad);
		invoke	LoadImage, \
				ebx, IDI_ICON, IMAGE_ICON, \
				32, 32, 0
		mov		[wcx.hIcon], eax

		; -- in User32
		; LoadImage(hinst, lpszName, uType, cxDesired, cyDesired, fuLoad);
		invoke	LoadImage, \
				ebx, IDI_ICON, IMAGE_ICON, \
				16, 16, 0
		mov		[wcx.hIconSm], eax

		; -- in User32
		; LoadImage(hinst, lpszName, uType, cxDesired, cyDesired, fuLoad);
		invoke	LoadImage, \
				0, \ 							; hinst - OEM image
				OCR_NORMAL, IMAGE_CURSOR, \
				0, 0, \							; cxDesired, cyDesired - use default
				LR_DEFAULTSIZE | LR_SHARED		;fuLoad
		mov		[wcx.hCursor], eax


		; -- in User32
		; RegisterClassEx(lpwcx)
		invoke	RegisterClassEx, ADDR wcx

		test	eax,eax
		jz		>>.Error

	;Create the Main window
		xor		eax,eax		;EAX=0

		; -- in User32
		; CreateWindowEx(dwExStyle, lpClassName, lpWindowName, dwStyle,
		;				X, Y, nWidth, nHeight,
		;				hWndParent, hMenu, hInstance, lpParam)
		invoke	CreateWindowEx, \
				0, \
				ADDR szMainClass, ADDR szTitle, \
				WS_OVERLAPPEDWINDOW & ~WS_MAXIMIZEBOX & ~WS_THICKFRAME, \	;dwStyle
				CW_USEDEFAULT, eax, 1FAh, 26ah, \ ; X, Y, nWidth, nHeight
				eax, \ ; hWndParent
				eax, \ ; hMenu - NULL, use class menu
				ebx, \ ; hInstance
				eax ; lpParam

		test 	eax,eax		;EAX=hwndMain
		jz		>.Error
		mov		[hwndMain], eax

	;Show window with animation
		; -- in User32
		; AnimateWindow(hwnd, dwTime, dwFlags)
		;invoke	AnimateWindow, [hwndMain], 200, AW_ACTIVATE | AW_CENTER

		; ShowWindow(hwnd, SW_SHOW)
		invoke	ShowWindow, [hwndMain], SW_SHOW


	;Update the Main window
		; -- in User32
		; UpdateWindow(hWnd)
		invoke	UpdateWindow, [hwndMain]


		xor		eax,eax		;return 0 to continue
	.Return
		ret
	.Error
		inc		eax		;return non-zero exit code
		jmp		<.Return
ENDF




;; --------------------Message processing-----------------------

;; --------------------Message table-----------------------
	.DATA
MainMsg	DD	WM_COMMAND,\
		WM_SIZE,\
		WM_PAINT, WM_KEYDOWN, WM_LBUTTONUP, WM_RBUTTONUP, \
		WM_CREATE, WM_CLOSE, WM_DESTROY, \
		WM_KILLTIMER, WM_TIMER, \
		WM_GRAPHNOTIFY_LOOP, WM_GRAPHNOTIFY_STOP
MainM	DD	MainWM_COMMAND,\
		MainWM_SIZE,\
		MainWM_PAINT, MainWM_KEYDOWN, MainWM_LBUTTONUP, MainWM_RBUTTONUP, \
		MainWM_CREATE, MainWM_CLOSE, MainWM_DESTROY,\
		MainWM_KILLTIMER, MainWM_TIMER, \
		MainWM_GRAPHNOTIFY_LOOP, MainWM_GRAPHNOTIFY_STOP
;; --------------------Message table end-----------------------
;;
;;	MAIN WINDOW MESSAGES
;;
	.CODE
MainWND:
	FRAME	hWnd, uMsg, wParam, lParam
	USES	ebx,esi,edi

	;IF message is not found
		mov		eax,[uMsg]
		mov		edi,ADDR MainMsg
		mov		ecx,SIZEOF(MainMsg)/4
		repne scasd
		je		>.Process

	;THEN let DefWindowProc handle this message
	.Default
		invoke	DefWindowProc, \
				[hWnd], [uMsg], \
				[wParam], [lParam]

		jmp		>.Return
	;ELSE process this message possibly setting carry flag for default processing
	.Process
		call	D[edi+SIZEOF(MainMsg)-4]
		jc		<.Default
	.Return
		ret
ENDF

MainWM_CREATE:
	USEDATA	MainWND
	LOCAL	rc:RECT, hDC
	;Get handle to Main window and save it
		mov		esi, [hWnd]	;ESI=hwndMain
		mov		ebx, [hInst]	;EBX=hInst
		mov		[hwndMain], esi

	; Create a memory DC for double buffer
		invoke	GetDC, [hWnd]
		mov		[hDC], eax
		invoke	CreateCompatibleDC, eax
		mov		[hMemDC], eax
		invoke	GetClientRect, [hWnd], ADDR rc
		mov		eax, [rc.right]
		sub		eax, [rc.left]
		mov		edx, [rc.bottom]
		sub		edx, [rc.top]
		invoke	CreateCompatibleBitmap, [hDC], eax, edx
		mov		[hbMemBmp], eax
		invoke	SelectObject, [hMemDC], eax
		mov		[hbMemBmpOld], eax
		invoke	ReleaseDC, [hWnd], [hDC]
	; Initialize the game now
		invoke	GameInitialize, [hWnd]
		test	eax, eax
		jz		>.Error
	; All things done
		xor		eax,eax		;return 0 to continue
	.Return
		ret
	.Error
		dec		eax		;return -1 to exit
		jmp		<.Return
ENDU

MainWM_CLOSE:
	USEDATA MainWND
	; Uninitialize the game first
		invoke	GameUninitialize, [hWnd]
	; Delete the memory DC
		invoke	SelectObject, [hMemDC], [hbMemBmpOld]
		invoke	DeleteObject, [hbMemBmp]
		invoke	DeleteObject, [hMemDC]
	; Send WM_DESTROY to destroy the Main window
		invoke	DestroyWindow, [hWnd]
	; All things done
		xor		eax,eax		;return 0 - message processed, clear carry flag
		ret
ENDU

MainWM_DESTROY:
	USEDATA	MainWND
	;Post WM_QUIT to the message queue to exit
		invoke	PostQuitMessage, 0

		xor	eax,eax		;return 0 - message processed, clear carry flag
		ret
ENDU

MainWM_SIZE:
	USEDATA	MainWND
	LOCAL	rc:RECT, hDC
	#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered MainWM_SIZE()',0Dh,0Ah,0>
		writeln(eax)
	#endif

	; Get client area of Main window
		invoke	GetClientRect, [hWnd], ADDR rc
	; We must recreate a memory bitmap
		invoke	GetDC, [hWnd]
		mov		[hDC], eax
		mov		eax, [rc.right]
		sub		eax, [rc.left]
		mov		edx, [rc.bottom]
		sub		edx, [rc.top]
		invoke	CreateCompatibleBitmap, [hDC], eax, edx
		mov		[hbMemBmp], eax
		invoke	SelectObject, [hMemDC], eax
		invoke	DeleteObject, eax
		invoke	ReleaseDC, [hWnd], [hDC]

		xor		eax,eax		;return 0 - message processed, clear carry flag
		ret
ENDU

MainWM_PAINT:
	USEDATA	MainWND
	LOCAL	ps:PAINTSTRUCT, hbrush, rc:RECT
	#ifdef ACTUATOR_DEBUG
		mov		eax, ADDR <'Entered MainWM_PAINT()',0Dh,0Ah,0>
		writeln(eax)
	#endif

		invoke	BeginPaint, [hWnd], ADDR ps
	; Get client rect
		invoke	GetClientRect, [hWnd], ADDR rc
	; Double buffer: erase background
		;invoke	GetSysColor, COLOR_WINDOW
		invoke	CreateSolidBrush, RGB(0fah, 0f8h, 0efh)
		mov		[hbrush], eax
    	invoke	FillRect, [hMemDC], ADDR rc, eax
    	invoke	DeleteObject, [hbrush]
	; User paintings
		invoke	GameOnPaint, [hMemDC]
	; Double buffer: bitblt
		mov		eax, [rc.right]
		sub		eax, [rc.left]
		mov		edx, [rc.bottom]
		sub		edx, [rc.top]
		invoke	BitBlt, [ps.hdc], \
           				[rc.left], [rc.top], \
           				eax, edx, \
           				[hMemDC], \
           				0, 0, SRCCOPY

	; All finished
		invoke	EndPaint, [hWnd], ADDR ps
		xor		eax,eax		;return 0 - message processed, clear carry flag
		ret
ENDU

MainWM_KEYDOWN:
	USEDATA MainWND
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Calling KeyMgrOnKeyDown(hWnd=%X, wParam=%X)',0Dh,0Ah,0>
		writeln(eax, [hWnd], [wParam])
		#endif
		invoke	KeyMgrOnKeyDown, [hWnd], [wParam]
		ret
ENDU

MainWM_LBUTTONUP:
	USEDATA	MainWND
	LOCAL	xPos, yPos
		mov		eax, [lParam]
		xor		edx, edx
		mov		dx, ax
		mov		[xPos], edx
		shr		eax, 16
		mov		dx, ax
		mov		[yPos], edx
		invoke	KeyLButtonUp, [hWnd], [xPos], [yPos]
		ret
ENDU

MainWM_RBUTTONUP:
	USEDATA	MainWND
	LOCAL	xPos, yPos
		mov		eax, [lParam]
		xor		edx, edx
		mov		dx, ax
		mov		[xPos], edx
		shr		eax, 16
		mov		dx, ax
		mov		[yPos], edx
		invoke	KeyRButtonUp, [hWnd], [xPos], [yPos]
		ret
ENDU

MainWM_KILLTIMER:
	USEDATA MainWND
		#ifdef MY_DEBUG
		mov		eax, ADDR <'Calling GameOnKillTimer()',0Dh,0Ah,0>
		writeln(eax)
		#endif
		invoke	GameOnKillTimer
		ret
ENDU

MainWM_TIMER:
	USEDATA MainWND
		invoke	GameOnTimer, [wParam]
		ret
ENDU

MainWM_GRAPHNOTIFY_LOOP:
	USEDATA	MainWND
		invoke	DSHandleLoop, [lParam]
		ret
ENDU

MainWM_GRAPHNOTIFY_STOP:
	USEDATA MainWND
		invoke	DSHandleStop, [lParam]
		ret
ENDU


;;
;;	MAIN WINDOW MENU COMMANDS
;;
	.CONST
MainCmd	DD	IDM_EXIT,\
		IDM_ABOUT, IDM_RESTART, IDM_MAN_ADD,\
		IDM_ENABLE_AI, IDM_ENABLE_BGM, IDM_ENABLE_SE
MainC	DD	MainWM_CLOSE,\
		HelpABOUT, MenuRestart, MenuManAdd, \
		MenuEnableAi, MenuEnableBgm, MenuEnableSe

	.CODE
MainWM_COMMAND:
	USEDATA	MainWND

	;IF command is not found
		mov		eax,[wParam]	;LOWORD(wParam)=ID
		mov		edi,ADDR MainCmd
		mov		ecx,SIZEOF(MainCmd)/4
		and		eax,0FFFFh		; unify accelerator and menu command
		repne	scasd
		je		>.Process

	;THEN let DefWindowProc handle this message
		stc			;set carry flag for default processing
		jmp		>.Return

	;ELSE process this message possibly setting carry flag for default processing
	.Process
		call	D[edi+SIZEOF(MainCmd)-4]
	.Return
	 	ret
ENDU

;;
;;	MENU COMMANDS
;;
MenuRestart:
	USEDATA	MainWND
		invoke	GameRestart
		ret
ENDU

MenuManAdd:
	USEDATA	MainWND
	LOCAL	hMenu
		invoke	GetMenu, [hWnd]
		mov		[hMenu], eax
		mov		edx,[wParam]	;LOWORD(wParam)=ID
		and		edx, 0FFFFh     ; unify accelerator and menu command
		invoke	GameSwitchManuallyAddTiles
		test	eax, eax
		jz		>.false
	.true:
		mov		eax, MF_CHECKED 
		jmp		>
	.false:
		mov		eax, MF_UNCHECKED 
	:
		invoke	CheckMenuItem, [hMenu], edx, eax
		ret
ENDU

MenuEnableAi:
	USEDATA	MainWND
	LOCAL	hMenu
		invoke	GetMenu, [hWnd]
		mov		[hMenu], eax
		mov		edx,[wParam]	;LOWORD(wParam)=ID
		and		edx, 0FFFFh     ; unify accelerator and menu command
		invoke	GameSwitchAI
		test	eax, eax
		jz		>.false
	.true:
		mov		eax, MF_CHECKED 
		jmp		>
	.false:
		mov		eax, MF_UNCHECKED 
	:
		invoke	CheckMenuItem, [hMenu], edx, eax
		ret
ENDU

MenuEnableBgm:
	USEDATA	MainWND
	LOCAL	hMenu
		invoke	GetMenu, [hWnd]
		mov		[hMenu], eax
		mov		edx,[wParam]	;LOWORD(wParam)=ID
		and		edx, 0FFFFh     ; unify accelerator and menu command
		invoke	GameSwitchBGM
		test	eax, eax
		jz		>.false
	.true:
		mov		eax, MF_CHECKED 
		jmp		>
	.false:
		mov		eax, MF_UNCHECKED 
	:
		invoke	CheckMenuItem, [hMenu], edx, eax
		ret
ENDU

MenuEnableSe:
	USEDATA	MainWND
	LOCAL	hMenu
		invoke	GetMenu, [hWnd]
		mov		[hMenu], eax
		mov		edx,[wParam]	;LOWORD(wParam)=ID
		and		edx, 0FFFFh     ; unify accelerator and menu command
		invoke	GameSwitchSE
		test	eax, eax
		jz		>.false
	.true:
		mov		eax, MF_CHECKED 
		jmp		>
	.false:
		mov		eax, MF_UNCHECKED 
	:
		invoke	CheckMenuItem, [hMenu], edx, eax
		ret
ENDU

	.CONST
szTitle		DSS	"2048-8402", 0


	.CODE
HelpABOUT:
		; -- in User32
		; DialogBoxParam(hInstance, lpTemplateName, hwndParent, lpDialogFunc, dwInitParam)
		invoke	DialogBoxParam, [hInst], IDD_ABOUT, [hwndMain], ADDR AboutDLG, 0
		xor		eax,eax		;return 0 - message processed, clear carry flag
		ret


AboutDLG:
	FRAME	hWnd, uMsg, wParam, lParam
	;	USES	ebx,esi,edi	;need to save these if used below

		mov		eax,[uMsg]

		cmp		eax, WM_INITDIALOG
		je		>.Processed	;E to process - no initializing required

		cmp		eax, WM_COMMAND
		je		>.Commands
	.Default
		xor		eax, eax		;return FALSE for message not processed
		jmp		>.Return
	.Commands
		mov		eax, [wParam]
		and		eax, 0FFFFh
		cmp		eax, IDOK
		je		>.Done

		cmp		eax, IDCANCEL
		je		>.Done

		jmp		<.Default
	.Done
		; -- in User32
		; EndDialog(hDlg, nResult)
		invoke	EndDialog, [hWnd], TRUE
	.Processed
		mov		eax, TRUE	;return TRUE for message processed
	.Return
		ret
ENDF