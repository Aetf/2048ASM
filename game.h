;UNICODE = 1             ;Remove to build ANSI version
;STRINGS UNICODE         ;Remove to build ANSI version
#include "windows.h"
#include "helpers.h"

;#define CONSOLE
;#define MY_DEBUG
;#define GRID_DUMP
;#define GRID_DEBUG
;#define GRID_EVAL_DEBUG
;#define GRID_EACH_DEBUG
;#define ACTUATOR_DEBUG
;#define TRANSITION_DEBUG
;#define NO_TRANSITION
;#define ANIMATION_DEBUG
;#define ANIMATION_DEBUG2
;#define ANIMATION_DEBUG3
;#define ANIMATION_DEBUG4
;#define ANIMATION_DEBUG5
;#define	AI_DEBUG
;#define MOUSE_DEBUG
#define GUI
;#define CLI

//----------------------------------------------------------------------
//    Common classes
//----------------------------------------------------------------------
POS		STRUCT
	x		DD
	y		DD
ENDS

POSVS	STRUCT
	x		DD
	y		DD
	value	DD
	score	DD
ENDS

//----------------------------------------------------------------------
//    Grid classes
//----------------------------------------------------------------------
#define	Grid_Cell_Count	16
#define	Grid_Size	4

GRID	STRUCT
	cells		DD	Grid_Cell_Count dup 0
	startTiles	DD	2
	playerTurn	DB	1
ENDS

MOVE_RESULT	STRUCT
	score	DD
	moved	DB
	won		DB
ENDS

//----------------------------------------------------------------------
//    Tile class
//----------------------------------------------------------------------
TILE	STRUCT
	x		DD
	y		DD
	value	DD

	previousPos	POS
	mergedFrom	DD	NULL
				DD	NULL

	marked		DB
ENDS

#define TILE_STRUCT_SIZE SIZEOF(TILE)

//----------------------------------------------------------------------
//    AI class
//----------------------------------------------------------------------
AI	STRUCT
	pGrid			DD
	minSearchTime	DD
ENDS

AI_RESULT	STRUCT
	move		DD
	score		DD
	positions	DD
	cutoffs		DD
ENDS

#define	AUTORUN_TIMER 124

//----------------------------------------------------------------------
//    Window Actuator classes
//----------------------------------------------------------------------
#define WM_KILLTIMER		WM_USER + 1
#define WM_GRAPHNOTIFY_LOOP	WM_USER + 2
#define WM_GRAPHNOTIFY_STOP	WM_USER + 3

#define	ACTUATOR_TIMER	123

#define TRANS_DURA 100
#define TRANS_END  TRANS_DURA + 50
#define MERGE_DURA  100
#define NEW_DURA   60
#define	ANIMA_DELAY	TRANS_END + MERGE_DURA

#define SNAPSHOP_MAX_TILE 32
CDispTile		STRUCT
	rect		RECT
	value		DD
ENDS

CDispSnapshot	STRUCT
	gridRect	RECT
	// No need to store count
	// terminate at first NULL
	dispTiles	DD	SNAPSHOP_MAX_TILE dup 0
ENDS

CAnimMeta		STRUCT
	fromPos		POS
	toPos		POS

	// start and end time, in ms
	startTime	DD
	endTime		DD

	// the type of the animation
	// 0: None
	// 1: Bounce in
	// 2: Merge bounce
	// 4: Translation
	type		DD

	// the behavior when the animation end
	// 0: keep final value
	// 1: not show
	endBehavior	DD
ENDS

#define ANIMATION_TYPE_NONE 0
#define ANIMATION_TYPE_ZOOM_IN_BOUNCE 1
#define ANIMATION_TYPE_ZOOM_IN 2
#define ANIMATION_TYPE_TRANSLATION 4

#define ANIMATION_BEHAVIOR_KEEP_FINAL 0
#define ANIMATION_BEHAVIOR_NOT_SHOW 1

#define TRANSITION_MAX_TILE 32
CDispTransition	STRUCT
	// No need to store count
	// terminate at first NULL
	tiles		DD	TRANSITION_MAX_TILE dup 0
	meta		DD TRANSITION_MAX_TILE dup 0

	// the overall end time, in ms
	endTime		DD

	// target snapshot, used for acuracy
	// CDispSnapshot*
	pTargetSnap	DD
ENDS

CWinActuator	STRUCT
// window stuff	
	// Handle to grid window
	hWndGrid	DD
	// Handle to score window
	hWndScore	DD

// Current status
	// Current snapshot
	// CDispSnapshot*
	pCurrSnap	DD
	// Current score
	dwScore		DD
	// Current message
	// 0: none
	// 1: You Win!!
	// 2: Game Over!!
	dwFlgMsg	DD

// Animation related
	animResolution	DD
	hTimer			DD
	pTransition		DD
	timestamp		DD

	animating		DB
ENDS

#define MESSAGE_FLAG_NONE 0
#define MESSAGE_FLAG_WIN 1
#define	MESSAGE_FLAG_OVER 2