include 'win64Wx.inc'
entry main

; ============================================================================
; Window 1.3.1 - Painting with Blue Text
;
; Pure FASM x64 / native Win32.
;
; This is the base shell for the control examples in this repository.
; There are intentionally NO child controls here.
;
; It demonstrates only:
;   - a borderless dark top-level window
;   - a custom dark title strip and close button
;   - dragging the window by the title strip
;   - normal resizing from all edges/corners
;   - a visible dark resize grip in the bottom-right corner
;   - painting Unicode text directly with DrawTextW
;   - application-owned DPI-scaled HFONT handling
;   - Per-Monitor-V2 DPI scaling
;
; Later examples can add ONE control at a time on top of this shell.
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
TEXT_FONT_HEIGHT_96   equ 24

; Painted client text color.
; COLORREF byte order is 00BBGGRR, so 00FFA658h = RGB #58A6FF.
PAINT_TEXT_COLOR      equ 00FFA658h

; Hit-test values returned from WM_NCHITTEST.
;
; A WS_POPUP window has no standard sizing frame. Returning these values tells
; USER32 to perform the SAME native move/resize operation it would perform for
; a normal framed window. We only decide where the invisible sizing zones are.
HTCLIENT              equ 1
HTCAPTION             equ 2
HTLEFT                equ 10
HTRIGHT               equ 11
HTTOP                 equ 12
HTTOPLEFT             equ 13
HTTOPRIGHT            equ 14
HTBOTTOM              equ 15
HTBOTTOMLEFT          equ 16
HTBOTTOMRIGHT         equ 17

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

        ; Create the application-owned font used by our painted text.
        ; This is NOT a control font: there is no child HWND involved.
        call    UpdateTextFont
        cmp     [hTextFont], 0
        je      error

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
        ; The grip is painted in client coordinates, so repaint after resize.
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

        ; The window moved to a monitor with a different DPI, so recreate
        ; our painted-text font from its original 96-DPI design height.
        call    UpdateTextFont

        mov     rbx, [lparam]

        mov     eax, [rbx + RECT.right]
        sub     eax, [rbx + RECT.left]
        mov     ecx, eax                    ; new width

        mov     eax, [rbx + RECT.bottom]
        sub     eax, [rbx + RECT.top]
        mov     edx, eax                    ; new height

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
        ; DrawTextW does not own the HFONT we selected into its HDC.
        cmp     [hTextFont], 0
        je      .no_text_font

        invoke DeleteObject, [hTextFont]
        mov     [hTextFont], 0

.no_text_font:
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

        ret
endp


; ============================================================================
; UpdateTextFont
;
; Create the font used by our painted text. Unlike a STATIC control, painted
; text has no HWND and therefore no WM_SETFONT relationship. We simply select
; this HFONT into the paint HDC immediately before DrawTextW.
;
; The negative height requests the character height rather than the complete
; font-cell height. That makes the requested visual size more predictable.
;
; We create the replacement FIRST. If CreateFontW fails, the old working font
; stays valid. Only after the new handle exists do we replace and delete it.
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

        mov     rbx, [hTextFont]
        mov     [hTextFont], rax

        test    rbx, rbx
        jz      .done

        invoke DeleteObject, rbx

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
        invoke SetTextColor, [hdc], 00FFFFFFh

        invoke DrawTextW, [hdc], _closeX, -1, rect,\
               DT_CENTER + DT_VCENTER + DT_SINGLELINE

        ; --------------------------------------------------------------------
        ; Paint Unicode text directly into the window
        ; --------------------------------------------------------------------
        ;
        ; This is the key lesson in Window 1.3.1:
        ;
        ;   DrawTextW paints pixels into an HDC.
        ;
        ; There is NO child window, no control class and no text HWND here.
        ; If this area is invalidated, WM_PAINT runs again and we redraw the
        ; text. That is fundamentally different from creating a STATIC control.
        ;
        ; SelectObject returns the object previously selected into the DC.
        ; Always restore that object before leaving the paint operation.
        ; --------------------------------------------------------------------

        invoke GetClientRect, [hwnd], textRect

        ; Keep the text out of our custom title strip. The rest of the client
        ; area becomes the DrawTextW layout rectangle.
        mov     eax, [ScaledTitleHeight]
        mov     [textRect.top], eax

        invoke SelectObject, [hdc], [hTextFont]
        mov     rdi, rax

        invoke SetBkMode, [hdc], TRANSPARENT
        invoke SetTextColor, [hdc], PAINT_TEXT_COLOR

        invoke DrawTextW, [hdc], _paintText, -1, textRect,\
               DT_CENTER + DT_VCENTER + DT_SINGLELINE

        ; The HDC belongs to BeginPaint/EndPaint. Restore its previous font
        ; before EndPaint so we leave the DC exactly as we received it.
        invoke SelectObject, [hdc], rdi

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

        mov     rbx, rax                    ; our HPEN
        invoke SelectObject, [hdc], rbx
        mov     rsi, rax                    ; previous GDI object

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

        _title          du 'Window 1.3.1 - Painting with Blue Text', 0
        _class          du 'FASMWIN64_BASE_WINDOW', 0
        _error          du 'Startup failed.', 0
        _closeX         du 'X', 0
        _paintText      du 'Painted with DrawTextW', 0
        _textFontName   du 'Segoe UI', 0

        rect            RECT
        textRect        RECT
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

        ; Small synchronous scratch values used only while painting the grip.
        GripX           dd 0
        GripY           dd 0
        GripInset       dd GRIP_INSET_96
        GripPenWidth    dd GRIP_PEN_WIDTH_96

        hwnd            dq 0
        lparam          dq 0
        hdc             dq 0
        brush           dq 0

        MainWindow      dq 0
        hTextFont       dq 0

        CurrentDpi          dd 96
        ScaledTitleHeight   dd TITLE_HEIGHT_96
        ScaledCloseBtnSize  dd CLOSE_BTN_SIZE_96
        ScaledBorderSize    dd BORDER_SIZE_96
        ScaledGripSize      dd GRIP_SIZE_96
        ScaledTextFontHeight dd -TEXT_FONT_HEIGHT_96


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
