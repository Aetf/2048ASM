#include "game.h"
    .DATA
    .CODE
//--------------------------------------------------------
//                      Memory
//--------------------------------------------------------
Malloc:
    FRAME   nSize
        invoke  GetProcessHeap
        invoke  ntdll:RtlAllocateHeap, eax, \
                            8, \ ; HEAP_ZERO_MEMORY
                            [nSize]
        ret
ENDF

Free:
    FRAME   pVoid
        invoke  GetProcessHeap
        invoke  Kernel32:HeapFree, eax, 0, [pVoid]
        ret
ENDF

MemCpy:
    FRAME   pDest, pSrc, nCount
    USES    esi,edi

        invoke  memcpy, [pDest], [pSrc], [nCount]
        add     esp, 0Ch

        ret
ENDF

//--------------------------------------------------------
//                      ArrayList
//--------------------------------------------------------
ArrayInit:
    FRAME   addrArray, nSize
    USES    ebx,esi,edi
        mov     esi, [addrArray]
        mov     ecx, [nSize]
    :
        mov     D[esi + 4*ecx - 4], 0
        loop    <
        ret
ENDF

ArrayClear:
    FRAME   addrArray, nSize
    USES    ebx,esi,edi
        mov     esi, [addrArray]
        mov     ecx, [nSize]
        lea     edi, [esi + ecx]

    .while: ;(esi != edi && [esi] != 0)
        cmp     esi, edi
        je      >.endwhile
        mov     eax, [esi]
        test    eax, eax
        jz      >.endwhile
    .do:
        invoke  Free, [esi]
        mov     D[esi], 0

        add     esi, 4
    .endwhile:
        ret
ENDF

ArrayAppend:
    FRAME   addrArray, pVoid
    USES    ebx,esi,edi
        mov     esi, [addrArray]

    .while: ;([esi] != 0)
        mov     eax, [esi]
        test    eax, eax
        jz      >.endwhile
    .do:
        add     esi, 4
    .endwhile:

        mov     eax, [pVoid]
        mov     [esi], eax
        mov     D[esi + 4], 0
        ret
ENDF

//--------------------------------------------------------
//                      Animation
//--------------------------------------------------------
// Calculate a intermediate rect
// FLOAT progress : between 0 and 1
LinearRectTranslationInterpolator:
    FRAME   pRectOut, pRectFrom, pRectTo, progress
    USES    ebx,esi,edi
    LOCALS  dPos:POS, scale:Q
        #ifdef ANIMATION_DEBUG
            mov     eax, ADDR <'Entered LinearRectTranslationInterpolator(progress=%f)',0Dh,0Ah,0>
            writeln(eax, [progress])
            mov     eax, ADDR <'    From (%d,%d),(%d,%d) To (%d,%d),(%d,%d)',0Dh,0Ah,0>
            mov     esi, [pRectFrom]
            mov     edi, [pRectTo]
            writeln(eax, [esi+RECT.left], [esi+RECT.top],[esi+RECT.right],[esi+RECT.bottom], \
                        [edi+RECT.left], [edi+RECT.top],[edi+RECT.right],[edi+RECT.bottom])
        #endif
        invoke  MemCpy, [pRectOut], [pRectFrom], SIZEOF(RECT)
        
        mov     esi, [pRectFrom]
        mov     edi, [pRectTo]
        mov     eax, [edi + RECT.left]
        sub     eax, [esi + RECT.left]
        mov     [dPos.x], eax
        mov     eax, [edi + RECT.top]
        sub     eax, [esi + RECT.top]
        mov     [dPos.y], eax

        finit
    // Calc scale
        ;invoke  CubicBezier, [progress], ADDR scale
        fld     D[progress]
        fstp    Q[scale]
    // load scale
        fld     Q[scale]
    // x
        fild    D[dPos.x]
        fmul    st1
        fistp   D[dPos.x]
    // y
        fild    D[dPos.y]
        fmul    st1
        fistp   D[dPos.y]

        mov     esi, [pRectOut]
        mov     eax, [dPos.x]
        add     [esi + RECT.left], eax
        add     [esi + RECT.right], eax
        mov     eax, [dPos.y]
        add     [esi + RECT.top], eax
        add     [esi + RECT.bottom], eax
        
        #ifdef ANIMATION_DEBUG
        mov     eax, ADDR <'    Calculated result (%d,%d),(%d,%d)',0Dh,0Ah,0>
        mov     esi, [pRectOut]
        writeln(eax, [esi+RECT.left], [esi+RECT.top],[esi+RECT.right],[esi+RECT.bottom])
        #endif
        ret
ENDF

// Calculate a intermediate rect
// FLOAT progress : between 0 and 1
    .DATA
CONST2  DQ  2.0
CONST3  DQ  3.0
    .CODE
LinearRectScaleInterpolator:
    FRAME   pRectOut, pRectFrom, progress
    USES    ebx,esi,edi
    LOCALS  fCenterX:Q, fCenterY:Q, scale:Q
        #ifdef ANIMATION_DEBUG3
            mov     eax, ADDR <'Entered LinearRectScaleInterpolator(progress=%f)',0Dh,0Ah,0>
            writeln(eax, [progress])
            mov     eax, ADDR <'    From (%d,%d),(%d,%d)',0Dh,0Ah,0>
            mov     esi, [pRectFrom]
            writeln(eax, [esi+RECT.left], [esi+RECT.top],[esi+RECT.right],[esi+RECT.bottom])
        #endif
        mov     esi, [pRectFrom]
        mov     edi, [pRectOut]
        finit
    // Calc center
        fld     Q[CONST2]
        fild    D[esi + RECT.left]
        fild    D[esi + RECT.right]
        fadd    st1
        fdiv    st2
        fstp    Q[fCenterX]
        fild    D[esi + RECT.top]
        fild    D[esi + RECT.bottom]
        fadd    st1
        fdiv    st3
        fstp    Q[fCenterY]
    // Calc scale
        ;invoke  CubicBezier, [progress], ADDR scale
        ;invoke  Square, [progress], ADDR scale
        fld     D[progress]
        fstp    Q[scale]
    // Load scale and 1-scale
        fld     Q[scale]
        fld1
        fsub    st1
    // Calc new left
        fld     Q[fCenterX]
        fsub    st4
        fmul    st1
        fadd    st4
        fistp   D[edi + RECT.left]
    // Calc new top
        fld     Q[fCenterY]
        fsub    st3
        fmul    st1
        fadd    st3
        fistp   D[edi + RECT.top]
    // Calc new right
        fld     Q[fCenterX]
        fild    D[esi + RECT.right]
        fsub    st1
        fmul    st3
        fadd    Q[fCenterX]
        fistp   D[edi + RECT.right]
    // Calc new bottom
        fld     Q[fCenterY]
        fild    D[esi + RECT.bottom]
        fsub    st1
        fmul    st4
        fadd    Q[fCenterY]
        fistp   D[edi + RECT.bottom]

        
        #ifdef ANIMATION_DEBUG3
            mov     eax, ADDR <'    Calculated result (%d,%d),(%d,%d)',0Dh,0Ah,0>
            mov     esi, [pRectOut]
            writeln(eax, [esi+RECT.left], [esi+RECT.top],[esi+RECT.right],[esi+RECT.bottom])
        #endif
        ret
ENDF

    .DATA
BS_P0   DQ  0.8
BS_P1   DQ  1.1
    .CODE
BounceRectScaleInterpolator:
    FRAME   pRectOut, pRectFrom, progress
    USES    ebx,esi,edi
    LOCALS  fCenterX:Q, fCenterY:Q, scale:Q
        #ifdef ANIMATION_DEBUG4
            mov     eax, ADDR <'Entered BounceRectScaleInterpolator(progress=%f)',0Dh,0Ah,0>
            writeln(eax, [progress])
            mov     eax, ADDR <'    From (%d,%d),(%d,%d)',0Dh,0Ah,0>
            mov     esi, [pRectFrom]
            writeln(eax, [esi+RECT.left], [esi+RECT.top],[esi+RECT.right],[esi+RECT.bottom])
        #endif
        mov     esi, [pRectFrom]
        mov     edi, [pRectOut]
        finit
    // Calc center
        fld     Q[CONST2]
        fild    D[esi + RECT.left]
        fild    D[esi + RECT.right]
        fadd    st1
        fdiv    st2
        fstp    Q[fCenterX]
        fild    D[esi + RECT.top]
        fild    D[esi + RECT.bottom]
        fadd    st1
        fdiv    st3
        fstp    Q[fCenterY]
    // Calc scale
        ;invoke  CubicBezier, [progress], ADDR scale
        ;invoke  Square, [progress], ADDR scale
        fld     D[progress]
        fstp    Q[scale]
    // Load scale and 1-scale
        fld     Q[scale]
        fld1
        fsub    st1
    // Calc new left
        fld     Q[fCenterX]
        fsub    st4
        fmul    st1
        fadd    st4
        fistp   D[edi + RECT.left]
    // Calc new top
        fld     Q[fCenterY]
        fsub    st3
        fmul    st1
        fadd    st3
        fistp   D[edi + RECT.top]
    // Calc new right
        fld     Q[fCenterX]
        fild    D[esi + RECT.right]
        fsub    st1
        fmul    st3
        fadd    Q[fCenterX]
        fistp   D[edi + RECT.right]
    // Calc new bottom
        fld     Q[fCenterY]
        fild    D[esi + RECT.bottom]
        fsub    st1
        fmul    st4
        fadd    Q[fCenterY]
        fistp   D[edi + RECT.bottom]

        
        #ifdef ANIMATION_DEBUG4
            mov     eax, ADDR <'    Calculated result (%d,%d),(%d,%d)',0Dh,0Ah,0>
            mov     esi, [pRectOut]
            writeln(eax, [esi+RECT.left], [esi+RECT.top],[esi+RECT.right],[esi+RECT.bottom])
        #endif
        ret
ENDF

// Cubic Bezier
// t: float
// pQRes: a pointer to qwords(double) which receive the result
// returned value to QRes
    .DATA
CB_P0   DQ 0.42
CB_P1   DQ 0.0
CB_P2   DQ 0.58
CB_P3   DQ 1.0
    .CODE
CubicBezier:
    FRAME   t, pQRes
    USES    ebx,esi,edi
        mov     esi, [pQRes]
        finit
        fld     D[t]
        fld1
        fsub    st1
        fld     st0
        fmul    st1
        fld     st0
        fmul    st2
        ; st0=(1-t)^3, st1=(1-t)^2, st2=(1-t), st3=t
        fld     Q[CB_P0]
        fmul    st1
        fstp    Q[esi]
        ; st0=(1-t)^3, st1=(1-t)^2, st2=(1-t), st3=t
        fld     Q[CONST3]
        fmul    Q[CB_P1]
        fmul    st2
        fmul    st4
        fadd    Q[esi]
        fstp    Q[esi]
        ; st0=(1-t)^3, st1=(1-t)^2, st2=(1-t), st3=t
        fld     Q[CONST3]
        fmul    Q[CB_P2]
        fmul    st3
        fmul    st4
        fmul    st4
        fadd    Q[esi]
        fstp    Q[esi]
        ; st0=(1-t)^3, st1=(1-t)^2, st2=(1-t), st3=t
        fld     Q[CB_P3]
        fmul    st4
        fmul    st4
        fmul    st4
        fadd    Q[esi]
        fstp    Q[esi]
        
        ret
ENDF

// t: float
// QRes = -1.875(t-0.8)^2+1.2
    .DATA
SQ_P0   DQ  -1.875
SQ_P1   DQ  -0.8
SQ_P2   DQ  1.2
SQ_P3   DQ  0.8
    .CODE
Square:
    FRAME   t, pQRes
    USES    ebx,esi,edi
    LOCALS  tmp
        mov     esi, [pQRes]
        finit
        fld     D[t]
        fld     Q[SQ_P1]
        fadd    st1
        fld     st0
        fmul    st1
        fld     Q[SQ_P0]
        fmul    st1
        fadd    Q[SQ_P2]

        fst     D[tmp]
        fstp    Q[esi]

        #ifdef ANIMATION_DEBUG4
            mov     eax, ADDR <'Square: t=%.8f, y=%.8f',0Dh,0Ah,0>
            sub     esp, 4
            fld     D[tmp]
            fstp    D[esp]
            sub     esp, 4
            fld     D[t]
            fstp    D[esp]
            push    eax
            push    [STDOUT]
            call    fprintf
            add     esp, 10h
        #endif
        ret
ENDF

dwtoa:
    FRAME dwValue, lpBuffer
    USES esi,edi
   
    ; -------------------------------------------------------------
    ; convert DWORD to ascii string
    ; dwValue is value to be converted
    ; lpBuffer is the address of the receiving buffer
    ; EXAMPLE:
    ; invoke dwtoa,edx,addr buffer
    ;
    ; Uses: eax, ecx, edx.
    ; -------------------------------------------------------------

    mov eax,[dwValue]
    mov edi,[lpBuffer]
    test eax,eax     ; Is the value negative?
    jns >

    mov B[edi],'-'   ; store a minus sign
    inc edi
    neg eax          ; and invert the value
:
    mov esi,edi      ; save pointer to first digit
    mov ecx,10
.convert
    test eax,eax     ; while there is more to convert...
    jz >

    xor edx,edx
    div ecx          ; put next digit in edx
    add dl,'0'       ; convert to ASCII
    mov [edi],dl     ; store it
    inc edi
    jmp <.convert
:
    mov B[edi], 0    ; terminate the string
.reverse             ; We now have all the digits, but in reverse order
    cmp esi,edi
    jae >

    dec edi
    mov al,[esi]
    mov ah,[edi]
    mov [edi],al
    mov [esi],ah
    inc esi
    jmp <.reverse
:   
    ret    
    ENDF