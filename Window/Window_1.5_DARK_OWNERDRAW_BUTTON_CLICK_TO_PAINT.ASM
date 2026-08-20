include 'win64Wx.inc'
entry main

; ============================================================================
; Window 1.5 - Dark Owner-Drawn Button / Click to Paint
;
; Pure FASM x64 / native Win32.
;
; Window 1.4 already proved the native BUTTON interaction path:
;
;       BUTTON click
;           -> WM_COMMAND / BN_CLICKED
;           -> TextVisible toggles
;           -> InvalidateRect
;           -> WM_PAINT renders the new state
;
; Window 1.5 keeps that behavior intact and changes ONE major thing:
;
;       Windows no longer paints the button face for us.
;
; BS_OWNERDRAW asks the native BUTTON class to send WM_DRAWITEM to its parent.
; USER32 still owns the child HWND, focus, keyboard behavior, mouse capture and
; BN_CLICKED generation. Our parent window only takes over the APPEARANCE.
;
; This version demonstrates:
;   - the complete Window 1.4 click-to-paint behavior
;   - BS_OWNERDRAW on a real native BUTTON
;   - WM_DRAWITEM routed to the parent
;   - Win64 DRAWITEMSTRUCT fields and alignment
;   - ODS_SELECTED for real pressed-state feedback
;   - ODS_FOCUS for the keyboard focus cue
;   - dark button face + subtle border
;   - blue button text while physically pressed
;   - a one-DPI-pixel pressed text offset
;   - retrieving and drawing the BUTTON's current caption
;
; The important lesson:
;   OWNER-DRAW CHANGES PAINTING RESPONSIBILITY, NOT BUTTON BEHAVIOR.
; ============================================================================

WM_DPICHANGED equ 02E0h

; ---------------------------------------------------------------------------
; 96-DPI design values.
;
; Windows reports DPI in pixels-per-inch. 96 DPI is the traditional Win32
; baseline, so every visual measurement starts here and is scaled with MulDiv.
; ---------------------------------------------------------------------------

TITLE_HEIGHT_96       equ 30
CLOSE_BTN_SIZE_96     equ 32
BORDER_SIZE_96        equ 8
GRIP_SIZE_96          equ 28
GRIP_INSET_96         equ 3
GRIP_PEN_WIDTH_96     equ 1

; New Window 1.4 design values.
TEXT_FONT_HEIGHT_96    equ 24
BUTTON_FONT_HEIGHT_96  equ 16
BUTTON_WIDTH_96        equ 150
BUTTON_HEIGHT_96       equ 40
BUTTON_OFFSET_Y_96     equ 58
TEXT_BUTTON_GAP_96     equ 18
BUTTON_PRESSED_OFFSET_96 equ 1

; Owner-draw BUTTON style/notification values.
BUTTON_BS_OWNERDRAW      equ 0000000Bh
BUTTON_ODT_BUTTON        equ 4
BUTTON_ODS_SELECTED      equ 00000001h
BUTTON_ODS_FOCUS         equ 00000010h

; Owner-drawn button COLORREF values.
; The normal face stays close to the #1E1E1E parent background.
; While the native button is physically pressed, the face becomes slightly
; lighter and the caption turns to the same blue used by our painted text.
BUTTON_COLOR_NORMAL       equ 00242424h
BUTTON_COLOR_PRESSED      equ 00343434h
BUTTON_COLOR_BORDER       equ 004A4A4Ah
BUTTON_COLOR_TEXT_NORMAL  equ 00D8D8D8h
BUTTON_COLOR_TEXT_PRESSED equ 00FFA658h

; DrawTextW color. COLORREF byte order is 00BBGGRR, so 00FFA658h is
; RGB #58A6FF -- the same blue used by the tutorial site.
PAINT_TEXT_COLOR       equ 00FFA658h

; Native BUTTON notification values used by this lesson.
ID_BUTTON_DEMO         equ 1001
BUTTON_BN_CLICKED      equ 0
BUTTON_TEXT_CAPACITY   equ 64

; Hit-test values returned from WM_NCHITTEST.
;
; A WS_POPUP window has no standard sizing frame. Returning these values tells
; USER32 to perform the SAME native move/resize operation it would perform for
; a normal framed window. We only decide where the invisible sizing zones are.
HTCLIENT               equ 1
HTCAPTION              equ 2
HTLEFT                 equ 10
HTRIGHT                equ 11
HTTOP                  equ 12
HTTOPLEFT              equ 13
HTTOPRIGHT             equ 14
HTBOTTOM               equ 15
HTBOTTOMLEFT           equ 16
HTBOTTOMRIGHT          equ 17

; Per-Monitor-V2 DPI-awareness pseudo handle.
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 equ -4


; ============================================================================
; Program entry
; ============================================================================

main:
        ; Keep RSP correctly aligned for Win64 calls made through invoke.
        sub     rsp, 8

        ; Tell Windows that this application handles monitor-DPI changes.
        invoke SetProcessDpiAwarenessContext, DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2

        invoke GetModuleHandleW, 0
        mov     [wc.hInstance], rax

        invoke LoadIconW, 0, IDI_APPLICATION
        mov     [wc.hIcon], rax
        mov     [wc.hIconSm], rax

        invoke LoadCursorW, 0, IDC_ARROW
        mov     [wc.hCursor], rax

        ; The class brush is owned by us because CreateSolidBrush created it.
        ; DeleteObject is therefore required during WM_DESTROY.
        invoke CreateSolidBrush, 001E1E1Eh
        test    rax, rax
        jz      error
        mov     [wc.hbrBackground], rax

        ; Start centered on the primary screen.
        invoke GetSystemMetrics, SM_CXSCREEN
        sub     eax, [WinW]
        shr     eax, 1
        mov     [WinX], eax

        invoke GetSystemMetrics, SM_CYSCREEN
        sub     eax, [WinH]
        shr     eax, 1
        mov     [WinY], eax

        invoke RegisterClassExW, wc
        test    rax, rax
        jz      error

        ; WS_POPUP removes the normal non-client frame/title bar.
        ; That is why this example paints and hit-tests its own shell.
        invoke CreateWindowExW, 0, _class, _title,\
               WS_POPUP,\
               [WinX], [WinY], [WinW], [WinH],\
               0, 0, [wc.hInstance], 0

        test    rax, rax
        jz      error

        mov     [MainWindow], rax

        ; Scale the shell for the monitor on which the window starts.
        invoke GetDpiForWindow, [MainWindow]
        mov     [CurrentDpi], eax
        call    UpdateScaledValues

        ; Create the application-owned font used only when TextVisible is TRUE.
        call    UpdateTextFont
        cmp     [hTextFont], 0
        je      error

        ; --------------------------------------------------------------------
        ; Window 1.5 lesson: keep the real native BUTTON, change only painting.
        ;
        ; BS_OWNERDRAW does NOT replace the BUTTON window procedure. USER32 still
        ; handles focus, Space/Enter activation, mouse capture and BN_CLICKED.
        ; The style only redirects the visual work to our parent's WM_DRAWITEM.
        ; --------------------------------------------------------------------
        invoke CreateWindowExW, 0, ButtonClassName, _buttonPaintText,\
               WS_CHILD + WS_VISIBLE + WS_TABSTOP + BUTTON_BS_OWNERDRAW,\
               0, 0, 0, 0,\
               [MainWindow], ID_BUTTON_DEMO, [wc.hInstance], 0

        test    rax, rax
        jz      error

        mov     [hButton], rax

        ; Give the control a smaller DPI-scaled Segoe UI font.
        call    UpdateButtonFont
        cmp     [hButtonFont], 0
        je      error

        call    LayoutButton

        invoke ShowWindow, [MainWindow], SW_SHOW
        invoke UpdateWindow, [MainWindow]

.message_loop:
        invoke GetMessageW, msg, 0, 0, 0
        cmp     eax, 1
        jb      end_loop
        jne     .message_loop

        invoke TranslateMessage, msg
        invoke DispatchMessageW, msg
        jmp     .message_loop

error:
        invoke MessageBoxW, NULL, _error, _title, MB_ICONERROR + MB_OK

end_loop:
        invoke ExitProcess, [msg.wParam]


; ============================================================================
; Main window procedure
; ============================================================================

proc WindowProc uses rbx rsi rdi, hwnd, wmsg, wparam, lparam

        mov     [hwnd], rcx
        mov     [wmsg], rdx
        mov     [wparam], r8
        mov     [lparam], r9

        cmp     [wmsg], WM_PAINT
        je      .wmpaint

        cmp     [wmsg], WM_DRAWITEM
        je      .wmdrawitem

        cmp     [wmsg], WM_COMMAND
        je      .wmcommand

        cmp     [wmsg], WM_LBUTTONDOWN
        je      .wmlbuttondown

        cmp     [wmsg], WM_NCHITTEST
        je      .wmnchittest

        cmp     [wmsg], WM_SIZE
        je      .wmsize

        cmp     [wmsg], WM_DPICHANGED
        je      .wmdpichanged

        cmp     [wmsg], WM_DESTROY
        je      .wmdestroy

.default:
        invoke DefWindowProcW, [hwnd], [wmsg], [wparam], [lparam]
        jmp     .finish


; ---------------------------------------------------------------------------
; WM_DRAWITEM
;
; A BS_OWNERDRAW BUTTON still behaves like a normal native BUTTON. When its
; visual state changes, Windows sends this message to the PARENT and lParam
; points at a DRAWITEMSTRUCT.
;
; The Win64 structure layout used below is defined in our data section after
; checking the supplied project include set. Pointer members require 8-byte
; alignment on x64, making this structure 40h bytes.
;
; We care about:
;   CtlType   = ODT_BUTTON
;   CtlID     = ID_BUTTON_DEMO
;   hwndItem  = exact child HWND
;   hDC       = destination DC supplied by Windows
;   rcItem    = rectangle we must paint
;   itemState = ODS_SELECTED / ODS_FOCUS and other native state bits
; ---------------------------------------------------------------------------

.wmdrawitem:
        mov     rbx, [lparam]

        ; Be strict: future owner-drawn controls may also send WM_DRAWITEM.
        cmp     dword [rbx + DRAWITEMSTRUCT64_LOCAL.CtlType], BUTTON_ODT_BUTTON
        jne     .default

        cmp     dword [rbx + DRAWITEMSTRUCT64_LOCAL.CtlID], ID_BUTTON_DEMO
        jne     .default

        mov     rax, [rbx + DRAWITEMSTRUCT64_LOCAL.hwndItem]
        cmp     rax, [hButton]
        jne     .default

        ; Copy rcItem. Never modify the structure Windows supplied.
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemLeft]
        mov     [buttonRect.left], eax
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemTop]
        mov     [buttonRect.top], eax
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemRight]
        mov     [buttonRect.right], eax
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemBottom]
        mov     [buttonRect.bottom], eax

        ; ---------------------------------------------------------------
        ; Face color from the NATIVE button state.
        ; ---------------------------------------------------------------
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.itemState]
        test    eax, BUTTON_ODS_SELECTED
        jnz     .button_pressed

        invoke CreateSolidBrush, BUTTON_COLOR_NORMAL
        jmp     .have_button_fill

.button_pressed:
        invoke CreateSolidBrush, BUTTON_COLOR_PRESSED

.have_button_fill:
        mov     rsi, rax
        test    rsi, rsi
        jz      .skip_button_fill

        invoke FillRect, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], buttonRect, rsi
        invoke DeleteObject, rsi

.skip_button_fill:
        ; A restrained border is enough to separate #242424 from the parent.
        invoke CreateSolidBrush, BUTTON_COLOR_BORDER
        mov     rsi, rax
        test    rsi, rsi
        jz      .skip_button_frame

        invoke FrameRect, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], buttonRect, rsi
        invoke DeleteObject, rsi

.skip_button_frame:
        ; ---------------------------------------------------------------
        ; Caption
        ; ---------------------------------------------------------------
        ; Owner-draw means Windows no longer draws the BUTTON caption for us.
        ; The caption still belongs to the child HWND, so retrieve its current
        ; text ("Paint Text" or "Clear Text") and draw that exact value.
        mov     eax, [buttonRect.left]
        mov     [buttonTextRect.left], eax
        mov     eax, [buttonRect.top]
        mov     [buttonTextRect.top], eax
        mov     eax, [buttonRect.right]
        mov     [buttonTextRect.right], eax
        mov     eax, [buttonRect.bottom]
        mov     [buttonTextRect.bottom], eax

        invoke GetWindowTextW, [hButton], ButtonTextBuffer, BUTTON_TEXT_CAPACITY

        invoke SelectObject, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], [hButtonFont]
        mov     rdi, rax

        invoke SetBkMode, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], TRANSPARENT

        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.itemState]
        test    eax, BUTTON_ODS_SELECTED
        jnz     .button_text_pressed

        invoke SetTextColor, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], BUTTON_COLOR_TEXT_NORMAL
        jmp     .draw_button_text

.button_text_pressed:
        ; ODS_SELECTED is maintained by the native BUTTON itself. It works for
        ; mouse capture and keyboard activation without a separate "pressed" flag.
        invoke SetTextColor, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], BUTTON_COLOR_TEXT_PRESSED

        ; Nudge only the text by one 96-DPI design pixel while held down.
        invoke MulDiv, BUTTON_PRESSED_OFFSET_96, [CurrentDpi], 96
        test    eax, eax
        jnz     .pressed_offset_ready
        mov     eax, 1

.pressed_offset_ready:
        add     [buttonTextRect.left], eax
        add     [buttonTextRect.top], eax
        add     [buttonTextRect.right], eax
        add     [buttonTextRect.bottom], eax

.draw_button_text:
        invoke DrawTextW, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], ButtonTextBuffer, -1, buttonTextRect,\
               DT_CENTER + DT_VCENTER + DT_SINGLELINE

        ; The DC belongs to Windows; restore the previous font.
        invoke SelectObject, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], rdi

        ; ---------------------------------------------------------------
        ; Keyboard focus cue
        ; ---------------------------------------------------------------
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.itemState]
        test    eax, BUTTON_ODS_FOCUS
        jz      .button_draw_done

        mov     eax, [buttonRect.left]
        mov     [buttonFocusRect.left], eax
        mov     eax, [buttonRect.top]
        mov     [buttonFocusRect.top], eax
        mov     eax, [buttonRect.right]
        mov     [buttonFocusRect.right], eax
        mov     eax, [buttonRect.bottom]
        mov     [buttonFocusRect.bottom], eax

        invoke MulDiv, 4, [CurrentDpi], 96
        test    eax, eax
        jnz     .focus_inset_ready
        mov     eax, 1

.focus_inset_ready:
        neg     eax
        mov     [FocusInsetNeg], eax

        invoke InflateRect, buttonFocusRect, [FocusInsetNeg], [FocusInsetNeg]
        invoke DrawFocusRect, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], buttonFocusRect

.button_draw_done:
        mov     eax, TRUE
        jmp     .finish


; ---------------------------------------------------------------------------
; WM_COMMAND
;
; A BUTTON sends command notifications to its PARENT. For a control message:
;
;   LOWORD(wParam) = child control ID
;   HIWORD(wParam) = notification code
;   lParam         = child HWND
;
; BN_CLICKED therefore arrives here in the top-level WindowProc. We change one
; piece of application state, then invalidate the parent so WM_PAINT can render
; the new state. The click handler does NOT paint directly.
; ---------------------------------------------------------------------------

.wmcommand:
        mov     eax, dword [wparam]
        mov     ecx, eax

        ; LOWORD(wParam) -> control ID.
        and     eax, 0FFFFh
        cmp     eax, ID_BUTTON_DEMO
        jne     .default

        ; HIWORD(wParam) -> notification code.
        shr     ecx, 16
        cmp     ecx, BUTTON_BN_CLICKED
        jne     .default

        ; Toggle our own state: 0 = no painted text, 1 = painted text visible.
        xor     dword [TextVisible], 1

        cmp     dword [TextVisible], 0
        je      .hide_text

        ; The native BUTTON owns its caption text, so change it with the normal
        ; Unicode window-text API rather than painting over the button ourselves.
        invoke SetWindowTextW, [hButton], _buttonClearText
        jmp     .request_repaint

.hide_text:
        invoke SetWindowTextW, [hButton], _buttonPaintText

.request_repaint:
        ; InvalidateRect does not call PaintWindow directly. It marks the client
        ; area dirty; Windows later delivers WM_PAINT through the normal message flow.
        invoke InvalidateRect, [hwnd], NULL, FALSE

        ; The parent repaint and the child repaint are separate update regions.
        ; SetWindowTextW normally causes the BUTTON to redraw, but this explicit
        ; invalidation makes our owner-draw responsibility obvious and deterministic.
        invoke InvalidateRect, [hButton], NULL, FALSE

        xor     eax, eax
        jmp     .finish


; ---------------------------------------------------------------------------
; WM_NCHITTEST
;
; This is what makes a borderless WS_POPUP window resize like a normal window.
; Windows asks: "What part of the window is under this screen coordinate?"
;
; Returning HTBOTTOMRIGHT makes USER32 begin its native bottom-right resize
; loop. No manual mouse tracking is required.
; ---------------------------------------------------------------------------

.wmnchittest:
        ; lParam contains signed 16-bit SCREEN coordinates.
        movsx   eax, word [lparam]
        movsx   edx, word [lparam + 2]

        mov     [pt.x], eax
        mov     [pt.y], edx

        invoke ScreenToClient, [hwnd], pt
        invoke GetClientRect, [hwnd], rect

        mov     eax, [pt.x]
        mov     edx, [pt.y]

        ; ---------------------------------------------------------------
        ; First test the VISIBLE grip.
        ;
        ; The grip is larger than the ordinary 8-pixel resize border.
        ; Returning HTBOTTOMRIGHT for its full rectangle means the drawn
        ; grip and the real mouse target are exactly the same area.
        ; ---------------------------------------------------------------

        mov     ecx, [rect.right]
        sub     ecx, [ScaledGripSize]
        cmp     eax, ecx
        jl      .normal_border_test

        mov     ecx, [rect.bottom]
        sub     ecx, [ScaledGripSize]
        cmp     edx, ecx
        jl      .normal_border_test

        mov     eax, HTBOTTOMRIGHT
        jmp     .finish

.normal_border_test:
        ; Corners/sides first: they are more specific than the client area.
        cmp     eax, [ScaledBorderSize]
        jl      .left_side

        mov     ecx, [rect.right]
        sub     ecx, [ScaledBorderSize]
        cmp     eax, ecx
        jg      .right_side

        cmp     edx, [ScaledBorderSize]
        jl      .top_only

        mov     ecx, [rect.bottom]
        sub     ecx, [ScaledBorderSize]
        cmp     edx, ecx
        jg      .bottom_only

        mov     eax, HTCLIENT
        jmp     .finish

.left_side:
        cmp     edx, [ScaledBorderSize]
        jl      .top_left

        mov     ecx, [rect.bottom]
        sub     ecx, [ScaledBorderSize]
        cmp     edx, ecx
        jg      .bottom_left

        mov     eax, HTLEFT
        jmp     .finish

.right_side:
        cmp     edx, [ScaledBorderSize]
        jl      .top_right

        mov     ecx, [rect.bottom]
        sub     ecx, [ScaledBorderSize]
        cmp     edx, ecx
        jg      .bottom_right

        mov     eax, HTRIGHT
        jmp     .finish

.top_only:
        mov     eax, HTTOP
        jmp     .finish

.bottom_only:
        mov     eax, HTBOTTOM
        jmp     .finish

.top_left:
        mov     eax, HTTOPLEFT
        jmp     .finish

.top_right:
        mov     eax, HTTOPRIGHT
        jmp     .finish

.bottom_left:
        mov     eax, HTBOTTOMLEFT
        jmp     .finish

.bottom_right:
        mov     eax, HTBOTTOMRIGHT
        jmp     .finish


.wmsize:
        ; Child HWNDs do not automatically follow a parent's new client size.
        ; The application owns the layout policy, so re-center the button here.
        call    LayoutButton

        ; The grip and conditional text use client coordinates, so repaint too.
        invoke InvalidateRect, [hwnd], NULL, FALSE
        xor     eax, eax
        jmp     .finish


; ---------------------------------------------------------------------------
; WM_DPICHANGED
;
; Per-Monitor-V2 applications receive this when the window moves to a monitor
; with a different DPI. lParam points to Microsoft's recommended new window
; rectangle. Using it keeps the physical window size visually consistent.
; ---------------------------------------------------------------------------

.wmdpichanged:
        ; LOWORD(wParam) = new X DPI.
        movzx   eax, word [wparam]
        mov     [CurrentDpi], eax

        call    UpdateScaledValues

        ; Both fonts are application-owned pixel-size resources, so rebuild them
        ; from their original 96-DPI design sizes for the new monitor.
        call    UpdateTextFont
        call    UpdateButtonFont

        mov     rbx, [lparam]

        mov     eax, [rbx + RECT.right]
        sub     eax, [rbx + RECT.left]
        mov     ecx, eax

        mov     eax, [rbx + RECT.bottom]
        sub     eax, [rbx + RECT.top]
        mov     edx, eax

        invoke SetWindowPos, [hwnd], 0,\
               [rbx + RECT.left], [rbx + RECT.top],\
               ecx, edx,\
               SWP_NOZORDER + SWP_NOACTIVATE

        invoke InvalidateRect, [hwnd], NULL, FALSE

        xor     eax, eax
        jmp     .finish


.wmpaint:
        mov     rcx, [hwnd]
        call    PaintWindow

        xor     eax, eax
        jmp     .finish


.wmlbuttondown:
        mov     rcx, [hwnd]
        mov     rdx, [lparam]
        call    HandleMouseClick

        xor     eax, eax
        jmp     .finish


.wmdestroy:
        ; Delete only objects that THIS application created.
        cmp     [hTextFont], 0
        je      .no_text_font

        invoke DeleteObject, [hTextFont]
        mov     [hTextFont], 0

.no_text_font:
        cmp     [hButtonFont], 0
        je      .no_button_font

        invoke DeleteObject, [hButtonFont]
        mov     [hButtonFont], 0

.no_button_font:
        cmp     [wc.hbrBackground], 0
        je      .no_background_brush

        invoke DeleteObject, [wc.hbrBackground]
        mov     [wc.hbrBackground], 0

.no_background_brush:
        invoke PostQuitMessage, 0
        xor     eax, eax

.finish:
        ret
endp


; ============================================================================
; UpdateScaledValues
;
; Recalculate every visual pixel size from the original 96-DPI design value.
; Always scaling from the baseline avoids accumulated rounding error when the
; window moves back and forth between monitors.
; ============================================================================

proc UpdateScaledValues

        invoke MulDiv, TITLE_HEIGHT_96, [CurrentDpi], 96
        mov     [ScaledTitleHeight], eax

        invoke MulDiv, CLOSE_BTN_SIZE_96, [CurrentDpi], 96
        mov     [ScaledCloseBtnSize], eax

        invoke MulDiv, BORDER_SIZE_96, [CurrentDpi], 96
        mov     [ScaledBorderSize], eax

        invoke MulDiv, GRIP_SIZE_96, [CurrentDpi], 96
        mov     [ScaledGripSize], eax

        invoke MulDiv, BUTTON_WIDTH_96, [CurrentDpi], 96
        mov     [ScaledButtonWidth], eax

        invoke MulDiv, BUTTON_HEIGHT_96, [CurrentDpi], 96
        mov     [ScaledButtonHeight], eax

        invoke MulDiv, BUTTON_OFFSET_Y_96, [CurrentDpi], 96
        mov     [ScaledButtonOffsetY], eax

        invoke MulDiv, TEXT_BUTTON_GAP_96, [CurrentDpi], 96
        mov     [ScaledTextButtonGap], eax

        ret
endp


; ============================================================================
; UpdateTextFont
;
; DrawTextW paints into our parent HDC, so there is no child HWND to receive
; WM_SETFONT. We select this application-owned HFONT into the paint DC only
; while drawing the conditional text.
; ============================================================================

proc UpdateTextFont uses rbx

        invoke MulDiv, TEXT_FONT_HEIGHT_96, [CurrentDpi], 96
        neg     eax
        mov     [ScaledTextFontHeight], eax

        invoke CreateFontW, [ScaledTextFontHeight], 0, 0, 0, FW_NORMAL,\
               FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,\
               CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH + FF_DONTCARE,\
               _textFontName

        test    rax, rax
        jz      .done

        ; Create the replacement first. If creation failed above, the old font
        ; would still be valid. Only now do we swap handles and delete the old one.
        mov     rbx, [hTextFont]
        mov     [hTextFont], rax

        test    rbx, rbx
        jz      .done

        invoke DeleteObject, rbx

.done:
        ret
endp


; ============================================================================
; UpdateButtonFont
;
; A BUTTON is a real child HWND, so its font relationship is different from
; DrawTextW. WM_SETFONT tells the native control which HFONT it should use.
; Windows stores the handle but does NOT take ownership of the GDI object.
; ============================================================================

proc UpdateButtonFont uses rbx rsi

        cmp     [hButton], 0
        je      .done

        invoke MulDiv, BUTTON_FONT_HEIGHT_96, [CurrentDpi], 96
        neg     eax
        mov     [ScaledButtonFontHeight], eax

        invoke CreateFontW, [ScaledButtonFontHeight], 0, 0, 0, FW_NORMAL,\
               FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,\
               CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH + FF_DONTCARE,\
               _textFontName

        test    rax, rax
        jz      .done

        mov     rsi, rax
        mov     rbx, [hButtonFont]

        mov     [hButtonFont], rsi
        invoke SendMessageW, [hButton], WM_SETFONT, rsi, TRUE

        ; The BUTTON now references the replacement font, so the previous
        ; application-owned HFONT can safely be deleted.
        test    rbx, rbx
        jz      .done

        invoke DeleteObject, rbx

.done:
        ret
endp


; ============================================================================
; LayoutButton
;
; The native button remains centered horizontally and slightly below the
; vertical center of the usable client area. That leaves a clean region above
; it for the text that appears only after BN_CLICKED.
; ============================================================================

proc LayoutButton

        cmp     [hButton], 0
        je      .done

        invoke GetClientRect, [MainWindow], rect

        ; X = (clientWidth - buttonWidth) / 2
        mov     eax, [rect.right]
        sub     eax, [ScaledButtonWidth]
        sar     eax, 1
        mov     [ButtonX], eax

        ; Y = title + ((clientHeight - title - buttonHeight) / 2) + offset
        mov     eax, [rect.bottom]
        sub     eax, [ScaledTitleHeight]
        sub     eax, [ScaledButtonHeight]
        sar     eax, 1
        add     eax, [ScaledTitleHeight]
        add     eax, [ScaledButtonOffsetY]
        mov     [ButtonY], eax

        invoke MoveWindow, [hButton], [ButtonX], [ButtonY],\
               [ScaledButtonWidth], [ScaledButtonHeight], TRUE

.done:
        ret
endp


; ============================================================================
; PaintWindow
; ============================================================================

proc PaintWindow uses rbx rsi rdi, hwnd

        mov     [hwnd], rcx

        invoke BeginPaint, [hwnd], ps
        mov     [hdc], rax

        ; --------------------------------------------------------------------
        ; Dark client background
        ; --------------------------------------------------------------------

        invoke GetClientRect, [hwnd], rect
        invoke FillRect, [hdc], rect, [wc.hbrBackground]

        ; --------------------------------------------------------------------
        ; Custom title strip
        ; --------------------------------------------------------------------

        mov     dword [rect.left], 0
        mov     dword [rect.top], 0

        mov     eax, [ScaledTitleHeight]
        mov     [rect.bottom], eax

        invoke CreateSolidBrush, 00262626h
        mov     [brush], rax

        test    rax, rax
        jz      .skip_title_fill

        invoke FillRect, [hdc], rect, [brush]
        invoke DeleteObject, [brush]

.skip_title_fill:

        ; --------------------------------------------------------------------
        ; Close button
        ; --------------------------------------------------------------------

        mov     eax, [rect.right]
        sub     eax, [ScaledCloseBtnSize]
        mov     [CloseBtnX], eax

        mov     [rect.left], eax
        add     eax, [ScaledCloseBtnSize]
        mov     [rect.right], eax

        mov     dword [rect.top], 0
        mov     eax, [ScaledCloseBtnSize]
        mov     [rect.bottom], eax

        ; Same dark surface as the title strip for this minimal base example.
        invoke CreateSolidBrush, 00262626h
        mov     [brush], rax

        test    rax, rax
        jz      .skip_close_fill

        invoke FillRect, [hdc], rect, [brush]
        invoke DeleteObject, [brush]

.skip_close_fill:
        invoke SetBkMode, [hdc], TRANSPARENT
        invoke SetTextColor, [hdc], 00A0A0A0h

        invoke DrawTextW, [hdc], _closeX, -1, rect,\
               DT_CENTER + DT_VCENTER + DT_SINGLELINE

        ; --------------------------------------------------------------------
        ; Conditional painted text
        ; --------------------------------------------------------------------
        ;
        ; The program opens with TextVisible = FALSE, so this entire section is
        ; skipped. A BN_CLICKED notification toggles the state and invalidates the
        ; window. WM_PAINT then reaches this same code again and draws the new state.
        ;
        ; This separation is important:
        ;     WM_COMMAND changes state.
        ;     WM_PAINT renders state.
        ; --------------------------------------------------------------------

        cmp     dword [TextVisible], 0
        je      .skip_painted_text

        invoke GetClientRect, [hwnd], textRect

        ; Keep text below the custom title strip.
        mov     eax, [ScaledTitleHeight]
        mov     [textRect.top], eax

        ; Keep it above the button so the two teaching elements never overlap.
        mov     eax, [ButtonY]
        sub     eax, [ScaledTextButtonGap]
        mov     [textRect.bottom], eax

        ; If the window becomes extremely short, simply skip this optional text
        ; rather than passing an inverted rectangle to DrawTextW.
        cmp     eax, [textRect.top]
        jle     .skip_painted_text

        invoke SelectObject, [hdc], [hTextFont]
        mov     rdi, rax

        invoke SetBkMode, [hdc], TRANSPARENT
        invoke SetTextColor, [hdc], PAINT_TEXT_COLOR

        invoke DrawTextW, [hdc], _paintText, -1, textRect,\
               DT_CENTER + DT_VCENTER + DT_SINGLELINE

        ; Restore the previous font before EndPaint. The HDC is borrowed from
        ; BeginPaint; we leave it in the same selection state in which we found it.
        invoke SelectObject, [hdc], rdi

.skip_painted_text:

        ; --------------------------------------------------------------------
        ; Dark bottom-right resize grip
        ; --------------------------------------------------------------------
        ;
        ; This is purely our VISUAL representation. The actual resize behavior
        ; comes from WM_NCHITTEST returning HTBOTTOMRIGHT over this same area.
        ;
        ; Three diagonal lines use a medium gray that clearly separates them from
        ; the #1E1E1E window background without looking bright or distracting.
        ; --------------------------------------------------------------------

        invoke GetClientRect, [hwnd], rect

        ; Scale the pen thickness and edge inset too. At 96 DPI these are
        ; one and three pixels; on a high-DPI monitor they grow with the grip.
        invoke MulDiv, GRIP_PEN_WIDTH_96, [CurrentDpi], 96
        test    eax, eax
        jnz     .pen_width_ready
        mov     eax, 1

.pen_width_ready:
        mov     [GripPenWidth], eax

        invoke MulDiv, GRIP_INSET_96, [CurrentDpi], 96
        test    eax, eax
        jnz     .grip_inset_ready
        mov     eax, 1

.grip_inset_ready:
        mov     [GripInset], eax

        invoke CreatePen, PS_SOLID, [GripPenWidth], 00707070h
        test    rax, rax
        jz      .grip_done

        mov     rbx, rax
        invoke SelectObject, [hdc], rbx
        mov     rsi, rax

        ; Each line uses memory-backed coordinates before invoke. This avoids
        ; using RCX/RDX as source operands while invoke is simultaneously
        ; assigning the Win64 argument registers.

        ; ----- longest line -----
        invoke MulDiv, 23, [CurrentDpi], 96
        mov     edi, eax

        mov     eax, [rect.right]
        sub     eax, edi
        mov     [GripX], eax

        mov     eax, [rect.bottom]
        sub     eax, [GripInset]
        mov     [GripY], eax

        invoke MoveToEx, [hdc], [GripX], [GripY], 0

        mov     eax, [rect.right]
        sub     eax, [GripInset]
        mov     [GripX], eax

        mov     eax, [rect.bottom]
        sub     eax, edi
        mov     [GripY], eax

        invoke LineTo, [hdc], [GripX], [GripY]

        ; ----- middle line -----
        invoke MulDiv, 17, [CurrentDpi], 96
        mov     edi, eax

        mov     eax, [rect.right]
        sub     eax, edi
        mov     [GripX], eax

        mov     eax, [rect.bottom]
        sub     eax, [GripInset]
        mov     [GripY], eax

        invoke MoveToEx, [hdc], [GripX], [GripY], 0

        mov     eax, [rect.right]
        sub     eax, [GripInset]
        mov     [GripX], eax

        mov     eax, [rect.bottom]
        sub     eax, edi
        mov     [GripY], eax

        invoke LineTo, [hdc], [GripX], [GripY]

        ; ----- shortest line -----
        invoke MulDiv, 11, [CurrentDpi], 96
        mov     edi, eax

        mov     eax, [rect.right]
        sub     eax, edi
        mov     [GripX], eax

        mov     eax, [rect.bottom]
        sub     eax, [GripInset]
        mov     [GripY], eax

        invoke MoveToEx, [hdc], [GripX], [GripY], 0

        mov     eax, [rect.right]
        sub     eax, [GripInset]
        mov     [GripX], eax

        mov     eax, [rect.bottom]
        sub     eax, edi
        mov     [GripY], eax

        invoke LineTo, [hdc], [GripX], [GripY]

        ; Never delete a GDI object while it is selected in a DC.
        invoke SelectObject, [hdc], rsi
        invoke DeleteObject, rbx

.grip_done:
        invoke EndPaint, [hwnd], ps
        ret
endp


; ============================================================================
; HandleMouseClick
;
; WM_LBUTTONDOWN only reaches us for HTCLIENT areas. Resize zones returned from
; WM_NCHITTEST are handled by USER32 as non-client resizing automatically.
; ============================================================================

proc HandleMouseClick uses rbx rsi rdi, hwnd, packedLParam

        mov     [hwnd], rcx
        mov     [packedLParam], rdx

        ; GET_X_LPARAM / GET_Y_LPARAM equivalent for x64.
        ; Decode from the original low 32 bits because writing EAX clears the
        ; upper half of RAX.
        mov     eax, dword [packedLParam]

        movsx   ecx, ax
        mov     [MouseX], ecx

        shr     eax, 16
        movsx   ecx, ax
        mov     [MouseY], ecx

        ; --------------------------------------------------------------------
        ; Close button hit test
        ; --------------------------------------------------------------------

        mov     eax, [CloseBtnX]
        cmp     [MouseX], eax
        jl      .not_close

        add     eax, [ScaledCloseBtnSize]
        cmp     [MouseX], eax
        jg      .not_close

        cmp     [MouseY], 0
        jl      .not_close

        mov     eax, [ScaledCloseBtnSize]
        cmp     [MouseY], eax
        jg      .not_close

        invoke PostMessageW, [hwnd], WM_CLOSE, 0, 0
        ret

.not_close:
        ; --------------------------------------------------------------------
        ; Custom title drag
        ; --------------------------------------------------------------------
        ;
        ; Instead of writing our own drag loop, ask USER32 to perform a normal
        ; caption drag. This preserves snapping and the rest of Windows' native
        ; move behavior.
        ; --------------------------------------------------------------------

        mov     eax, [ScaledTitleHeight]
        cmp     [MouseY], eax
        jg      .done

        invoke ReleaseCapture
        invoke SendMessageW, [hwnd], WM_NCLBUTTONDOWN, HTCAPTION, 0

.done:
        ret
endp


; ============================================================================
; Data
; ============================================================================

section '.data' data readable writeable

        _title          du 'Window 1.5 - Dark Owner-Drawn Button / Click to Paint', 0
        _class          du 'FASMWIN64_NATIVE_BUTTON_WINDOW', 0
        _error          du 'Startup failed.', 0
        _closeX         du 'X', 0

        ButtonClassName du 'BUTTON', 0
        _buttonPaintText du 'Paint Text', 0
        _buttonClearText du 'Clear Text', 0
        _paintText      du 'Painted after BN_CLICKED', 0
        _textFontName   du 'Segoe UI', 0

; ---------------------------------------------------------------------------
; DRAWITEMSTRUCT - Win64 layout used by WM_DRAWITEM.
;
; The supplied FASM.INC file does not expose a DRAWITEMSTRUCT definition.
; This tutorial therefore keeps a uniquely named local Win64 layout.
;
; x64 alignment:
;   DWORD fields through itemState      = 14h bytes
;   4 bytes padding before HWND         = offset 18h
;   HWND                                = 18h
;   HDC                                 = 20h
;   RECT                                = 28h..37h
;   ULONG_PTR itemData                  = 38h
;   sizeof                              = 40h
; ---------------------------------------------------------------------------

struct DRAWITEMSTRUCT64_LOCAL
  CtlType       dd ?             ; 00h
  CtlID         dd ?             ; 04h
  itemID        dd ?             ; 08h
  itemAction    dd ?             ; 0Ch
  itemState     dd ?             ; 10h
  pad0          dd ?             ; 14h -> align HWND
  hwndItem      dq ?             ; 18h
  hDC           dq ?             ; 20h
  rcItemLeft    dd ?             ; 28h
  rcItemTop     dd ?             ; 2Ch
  rcItemRight   dd ?             ; 30h
  rcItemBottom  dd ?             ; 34h
  itemData      dq ?             ; 38h
ends                              ; sizeof = 40h


        rect            RECT
        textRect        RECT
        buttonRect      RECT
        buttonTextRect  RECT
        buttonFocusRect RECT
        msg             MSG
        ps              PAINTSTRUCT
        pt              POINT

        wc WNDCLASSEX sizeof.WNDCLASSEX, CS_HREDRAW + CS_VREDRAW, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE + 1, NULL, _class, NULL

        WinX            dd 0
        WinY            dd 0
        WinW            dd 600
        WinH            dd 400

        CloseBtnX       dd 0
        MouseX          dd 0
        MouseY          dd 0

        ; Application state controlled by WM_COMMAND / BN_CLICKED.
        TextVisible     dd FALSE

        ; DPI-aware child layout.
        ButtonX         dd 0
        ButtonY         dd 0

        ; Small synchronous scratch values used only while painting the grip.
        GripX           dd 0
        GripY           dd 0
        GripInset       dd GRIP_INSET_96
        GripPenWidth    dd GRIP_PEN_WIDTH_96
        FocusInsetNeg   dd -4

        ; 64 UTF-16 code units = 128 bytes, safely enough for these short captions.
        ButtonTextBuffer rw BUTTON_TEXT_CAPACITY

        hwnd            dq 0
        lparam          dq 0
        hdc             dq 0
        brush           dq 0

        MainWindow      dq 0
        hButton         dq 0
        hTextFont       dq 0
        hButtonFont     dq 0

        CurrentDpi             dd 96
        ScaledTitleHeight      dd TITLE_HEIGHT_96
        ScaledCloseBtnSize     dd CLOSE_BTN_SIZE_96
        ScaledBorderSize       dd BORDER_SIZE_96
        ScaledGripSize         dd GRIP_SIZE_96
        ScaledButtonWidth      dd BUTTON_WIDTH_96
        ScaledButtonHeight     dd BUTTON_HEIGHT_96
        ScaledButtonOffsetY    dd BUTTON_OFFSET_Y_96
        ScaledTextButtonGap    dd TEXT_BUTTON_GAP_96
        ScaledTextFontHeight   dd -TEXT_FONT_HEIGHT_96
        ScaledButtonFontHeight dd -BUTTON_FONT_HEIGHT_96


; ============================================================================
; Imports
; ============================================================================

section '.idata' import data readable writeable

        library kernel32, 'KERNEL32.DLL',\
                user32,   'USER32.DLL',\
                gdi32,    'GDI32.DLL'

        include 'api\kernel32.inc'
        include 'api\user32.inc'
        include 'api\gdi32.inc'
