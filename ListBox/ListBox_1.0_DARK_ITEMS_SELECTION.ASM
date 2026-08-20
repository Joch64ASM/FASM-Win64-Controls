include 'win64Wx.inc'
entry main

; ============================================================================
; ListBox 1.0 - Dark Items & Selection
;
; Pure FASM x64 / native Win32.
;
; The learner has already reached Window 1.5 and therefore already knows the
; owner-draw relationship from the BUTTON lesson:
;
;       native child control
;              -> WM_DRAWITEM goes to the parent
;              -> parent paints the supplied HDC / rectangle
;
; So this lesson does NOT go back to a bright stock control just to introduce
; ListBox. We reuse the same owner-draw model immediately and concentrate on
; what is NEW about a native LISTBOX:
;
;       * the control owns a COLLECTION of string items
;       * LB_ADDSTRING adds items to that collection
;       * the control owns its CURRENT SELECTION
;       * LBN_SELCHANGE notifies the parent through WM_COMMAND
;       * LB_GETCURSEL retrieves the selected item index
;       * LB_GETTEXT retrieves the selected string
;
; The parent mirrors the current selection into application state only because
; it wants to paint the selected name above the ListBox. The ListBox itself
; remains the authoritative owner of its internal selection state.
;
; IMPORTANT CONTINUITY NOTE FOR THE TUTORIAL:
;
;   You already know why WM_DRAWITEM goes to the parent; now we're applying
;   that same model to a different native control.
;
; One significant change from Window 1.5:
;
;       replace the BUTTON lesson with one dark native LISTBOX lesson.
;
; The advanced file/PE report viewer belongs later. This source deliberately
; uses only five short, fixed strings so the ListBox message/state model stays
; visible before drag/drop, heap-backed report lines and horizontal scrolling
; are introduced.
; ============================================================================

WM_DPICHANGED equ 02E0h

; ---------------------------------------------------------------------------
; 96-DPI design values.
; ---------------------------------------------------------------------------

TITLE_HEIGHT_96          equ 30
CLOSE_BTN_SIZE_96        equ 32
BORDER_SIZE_96           equ 8
GRIP_SIZE_96             equ 28
GRIP_INSET_96            equ 3
GRIP_PEN_WIDTH_96        equ 1

CONTENT_MARGIN_96        equ 14
STATUS_HEIGHT_96         equ 36
STATUS_TO_LIST_GAP_96    equ 8
STATUS_LABEL_WIDTH_96    equ 92
STATUS_LABEL_GAP_96      equ 8

LISTBOX_FONT_HEIGHT_96   equ 18
LISTBOX_ITEM_HEIGHT_96   equ 32
LISTBOX_TEXT_PAD_96      equ 10
LISTBOX_FOCUS_INSET_96   equ 3

; ---------------------------------------------------------------------------
; Native LISTBOX styles / notification values used by this lesson.
;
; Local names keep the tutorial independent of spelling differences between
; include packages while avoiding collisions with any constants they expose.
; ---------------------------------------------------------------------------

LISTBOX_LBS_NOTIFY           equ 00000001h
LISTBOX_LBS_OWNERDRAWFIXED   equ 00000010h
LISTBOX_LBS_HASSTRINGS       equ 00000040h
LISTBOX_LBS_NOINTEGRALHEIGHT equ 00000100h

LISTBOX_LBN_SELCHANGE        equ 1
LISTBOX_ODT_LISTBOX          equ 2
LISTBOX_ODS_SELECTED         equ 00000001h
LISTBOX_ODS_FOCUS            equ 00000010h

IDC_LISTBOX                  equ 1001

; The two buffers below only ever receive one of the five fixed demo strings.
; 64 UTF-16 code units are therefore deliberately sufficient and stay well
; below the project's threshold for large static scratch buffers.
LISTBOX_TEXT_CAPACITY        equ 64

; ---------------------------------------------------------------------------
; COLORREF values (00BBGGRR).
; ---------------------------------------------------------------------------

WINDOW_COLOR                 equ 001E1E1Eh       ; RGB #1E1E1E
TITLE_COLOR                  equ 00262626h       ; RGB #262626
LISTBOX_COLOR_NORMAL         equ 00242424h       ; RGB #242424
LISTBOX_COLOR_SELECTED       equ 003D3630h       ; RGB #30363D
LISTBOX_TEXT_NORMAL          equ 00D8D8D8h       ; RGB #D8D8D8
LISTBOX_TEXT_SELECTED        equ 00FFA658h       ; RGB #58A6FF
STATUS_TEXT_DIM              equ 00A0A0A0h
STATUS_TEXT_SELECTED         equ 00FFA658h       ; RGB #58A6FF

; ---------------------------------------------------------------------------
; Borderless-window hit-test values.
; ---------------------------------------------------------------------------

HTCLIENT       equ 1
HTCAPTION      equ 2
HTLEFT         equ 10
HTRIGHT        equ 11
HTTOP          equ 12
HTTOPLEFT      equ 13
HTTOPRIGHT     equ 14
HTBOTTOM       equ 15
HTBOTTOMLEFT   equ 16
HTBOTTOMRIGHT  equ 17

DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 equ -4


; ============================================================================
; Program entry
; ============================================================================

main:
        ; Keep RSP correctly aligned for Win64 calls made through invoke.
        sub     rsp, 8

        invoke SetProcessDpiAwarenessContext, DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2

        invoke GetModuleHandleW, 0
        mov     [wc.hInstance], rax

        invoke LoadIconW, 0, IDI_APPLICATION
        mov     [wc.hIcon], rax
        mov     [wc.hIconSm], rax

        invoke LoadCursorW, 0, IDC_ARROW
        mov     [wc.hCursor], rax

        ; Persistent brushes are application-owned because WE create them.
        invoke CreateSolidBrush, WINDOW_COLOR
        test    rax, rax
        jz      error
        mov     [wc.hbrBackground], rax

        invoke CreateSolidBrush, LISTBOX_COLOR_NORMAL
        test    rax, rax
        jz      error
        mov     [hListBrushNormal], rax

        invoke CreateSolidBrush, LISTBOX_COLOR_SELECTED
        test    rax, rax
        jz      error
        mov     [hListBrushSelected], rax

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

        invoke CreateWindowExW, 0, _class, _title,\
               WS_POPUP,\
               [WinX], [WinY], [WinW], [WinH],\
               0, 0, [wc.hInstance], 0

        test    rax, rax
        jz      error

        mov     [MainWindow], rax

        ; Scale every visual value from the 96-DPI baseline before the child
        ; is created. WM_MEASUREITEM may arrive DURING CreateWindowExW.
        invoke GetDpiForWindow, [MainWindow]
        mov     [CurrentDpi], eax
        call    UpdateScaledValues

        ; --------------------------------------------------------------------
        ; Create a real native LISTBOX child window.
        ;
        ; LBS_OWNERDRAWFIXED
        ;   reuses the owner-draw model learned with BUTTON. The parent paints
        ;   each row, but USER32 still owns the ListBox HWND and behavior.
        ;
        ; LBS_HASSTRINGS
        ;   is especially important with owner-draw. It tells the ListBox that
        ;   LB_ADDSTRING receives string pointers and that USER32 should COPY
        ;   those strings into the control's own item storage.
        ;
        ; LBS_NOTIFY
        ;   asks the control to notify the parent when selection changes.
        ; --------------------------------------------------------------------
        invoke CreateWindowExW, 0, ListBoxClassName, 0,\
               WS_CHILD + WS_VISIBLE + WS_TABSTOP + WS_VSCROLL +\
               LISTBOX_LBS_NOTIFY + LISTBOX_LBS_OWNERDRAWFIXED +\
               LISTBOX_LBS_HASSTRINGS + LISTBOX_LBS_NOINTEGRALHEIGHT,\
               0, 0, 0, 0,\
               [MainWindow], IDC_LISTBOX, [wc.hInstance], 0

        test    rax, rax
        jz      error

        mov     [hListBox], rax

        ; One application-owned HFONT is shared by the parent status text and
        ; the owner-drawn ListBox rows. WM_SETFONT stores the handle in the
        ; child; it does NOT transfer ownership to USER32.
        call    UpdateUiFont
        cmp     [hUiFont], 0
        je      error

        ; Add five fixed strings. With LBS_HASSTRINGS, USER32 copies them into
        ; ListBox-owned item storage immediately.
        call    AddDemoItems
        test    eax, eax
        jz      error

        call    LayoutControls

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

proc WindowProc uses rbx rsi rdi r12, hwnd, wmsg, wparam, lparam

        mov     [hwnd], rcx
        mov     [wmsg], rdx
        mov     [wparam], r8
        mov     [lparam], r9

        cmp     [wmsg], WM_PAINT
        je      .wmpaint

        cmp     [wmsg], WM_MEASUREITEM
        je      .wmmeasureitem

        cmp     [wmsg], WM_DRAWITEM
        je      .wmdrawitem

        cmp     [wmsg], WM_CTLCOLORLISTBOX
        je      .wmctlcolorlistbox

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
; WM_MEASUREITEM
;
; LBS_OWNERDRAWFIXED asks the PARENT for one common row height. This message
; can arrive during CreateWindowExW before hListBox has been assigned, so the
; safe identity check here is control TYPE + control ID.
; ---------------------------------------------------------------------------

.wmmeasureitem:
        mov     rbx, [lparam]

        cmp     dword [rbx + MEASUREITEMSTRUCT64_LOCAL.CtlType], LISTBOX_ODT_LISTBOX
        jne     .default

        cmp     dword [rbx + MEASUREITEMSTRUCT64_LOCAL.CtlID], IDC_LISTBOX
        jne     .default

        mov     eax, [ScaledListItemHeight]
        mov     [rbx + MEASUREITEMSTRUCT64_LOCAL.itemHeight], eax

        mov     eax, TRUE
        jmp     .finish


; ---------------------------------------------------------------------------
; WM_DRAWITEM
;
; The painting model is deliberately familiar from the owner-drawn BUTTON:
;
;   * Windows supplies the destination HDC and row rectangle.
;   * ODS_SELECTED tells us whether THIS item is selected.
;   * ODS_FOCUS tells us whether the native ListBox wants a focus cue.
;   * We paint only appearance; USER32 still performs hit-testing, keyboard
;     navigation, selection changes, scrolling and notification generation.
;
; What is different now is that itemID identifies one entry in a collection.
; Because LBS_HASSTRINGS is active, LB_GETTEXT retrieves the string that the
; ListBox copied into its own item storage.
; ---------------------------------------------------------------------------

.wmdrawitem:
        mov     rbx, [lparam]

        cmp     dword [rbx + DRAWITEMSTRUCT64_LOCAL.CtlType], LISTBOX_ODT_LISTBOX
        jne     .default

        cmp     dword [rbx + DRAWITEMSTRUCT64_LOCAL.CtlID], IDC_LISTBOX
        jne     .default

        ; Copy Windows' rectangle because text padding/focus work may adjust it.
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemLeft]
        mov     [ownerDrawRect.left], eax
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemTop]
        mov     [ownerDrawRect.top], eax
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemRight]
        mov     [ownerDrawRect.right], eax
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemBottom]
        mov     [ownerDrawRect.bottom], eax

        ; Save the borrowed HDC's state. RestoreDC below returns font, colors,
        ; background mode and any other attributes to the state Windows gave us.
        invoke SaveDC, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC]
        mov     r12d, eax

        ; The ListBox owns selected/unselected state. We do NOT keep a separate
        ; "row is selected" flag merely for painting.
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.itemState]
        test    eax, LISTBOX_ODS_SELECTED
        jnz     .draw_selected

        mov     rdi, [hListBrushNormal]
        invoke SetTextColor, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], LISTBOX_TEXT_NORMAL
        jmp     .have_row_style

.draw_selected:
        mov     rdi, [hListBrushSelected]
        invoke SetTextColor, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], LISTBOX_TEXT_SELECTED

.have_row_style:
        invoke FillRect, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], ownerDrawRect, rdi

        ; itemID == -1 can describe an empty/non-item draw request. The row
        ; background above is enough; there is no string to retrieve.
        mov     esi, [rbx + DRAWITEMSTRUCT64_LOCAL.itemID]
        cmp     esi, -1
        je      .draw_focus

        ; This small static buffer is safe HERE because this tutorial inserts
        ; only five fixed strings, all far shorter than LISTBOX_TEXT_CAPACITY.
        invoke SendMessageW, [rbx + DRAWITEMSTRUCT64_LOCAL.hwndItem],\
               LB_GETTEXT, rsi, DrawItemTextBuffer
        cmp     eax, -1
        je      .draw_focus

        invoke SelectObject, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], [hUiFont]
        invoke SetBkMode, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], TRANSPARENT

        mov     eax, [ScaledListTextPad]
        add     [ownerDrawRect.left], eax
        sub     [ownerDrawRect.right], eax

        invoke DrawTextW, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC],\
               DrawItemTextBuffer, -1, ownerDrawRect,\
               DT_LEFT + DT_VCENTER + DT_SINGLELINE + DT_END_ELLIPSIS

.draw_focus:
        ; Reuse the native focus state rather than inventing our own keyboard
        ; focus flag. This is exactly the same ownership principle as BUTTON.
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.itemState]
        test    eax, LISTBOX_ODS_FOCUS
        jz      .draw_restore_dc

        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemLeft]
        mov     [focusRect.left], eax
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemTop]
        mov     [focusRect.top], eax
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemRight]
        mov     [focusRect.right], eax
        mov     eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemBottom]
        mov     [focusRect.bottom], eax

        mov     eax, [ScaledListFocusInset]
        neg     eax
        mov     [FocusInsetNeg], eax

        invoke InflateRect, focusRect, [FocusInsetNeg], [FocusInsetNeg]
        invoke DrawFocusRect, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], focusRect

.draw_restore_dc:
        ; SaveDC can theoretically fail and return zero. Restore only when a
        ; valid state ID was created.
        test    r12d, r12d
        jz      .draw_done

        invoke RestoreDC, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], r12d

.draw_done:
        mov     eax, TRUE
        jmp     .finish


; ---------------------------------------------------------------------------
; WM_CTLCOLORLISTBOX
;
; Owner-draw handles ITEM rows. WM_CTLCOLORLISTBOX still matters because a
; ListBox can have client pixels not occupied by an item (for example below the
; last row). Returning our normal brush keeps that remaining control area dark.
; ---------------------------------------------------------------------------

.wmctlcolorlistbox:
        mov     rax, [lparam]
        cmp     rax, [hListBox]
        jne     .default

        invoke SetTextColor, [wparam], LISTBOX_TEXT_NORMAL
        invoke SetBkColor, [wparam], LISTBOX_COLOR_NORMAL
        invoke SetBkMode, [wparam], TRANSPARENT

        mov     rax, [hListBrushNormal]
        jmp     .finish


; ---------------------------------------------------------------------------
; WM_COMMAND / LBN_SELCHANGE
;
; BUTTON introduced WM_COMMAND with BN_CLICKED. LISTBOX uses the SAME parent
; message family but a different notification contract:
;
;   LOWORD(wParam) = IDC_LISTBOX
;   HIWORD(wParam) = LBN_SELCHANGE
;   lParam         = ListBox child HWND
;
; The ListBox already changed its own internal selection BEFORE notifying us.
; We query that control-owned state with LB_GETCURSEL, then retrieve the string
; with LB_GETTEXT. Only after that do we mirror the result into application
; state for the parent status line.
; ---------------------------------------------------------------------------

.wmcommand:
        mov     eax, dword [wparam]
        mov     ecx, eax

        and     eax, 0FFFFh
        cmp     eax, IDC_LISTBOX
        jne     .default

        shr     ecx, 16
        cmp     ecx, LISTBOX_LBN_SELCHANGE
        jne     .default

        mov     rax, [lparam]
        cmp     rax, [hListBox]
        jne     .default

        ; Ask the native ListBox which item it currently owns as selected.
        invoke SendMessageW, [hListBox], LB_GETCURSEL, 0, 0
        cmp     eax, -1
        je      .selection_unavailable

        mov     esi, eax
        mov     [CurrentSelection], eax

        ; Fixed demo strings only: the 64-WCHAR buffer is intentionally enough.
        invoke SendMessageW, [hListBox], LB_GETTEXT, rsi, SelectedTextBuffer
        cmp     eax, -1
        je      .selection_unavailable

        jmp     .invalidate_status

.selection_unavailable:
        mov     dword [CurrentSelection], -1
        mov     word [SelectedTextBuffer], 0

.invalidate_status:
        ; Event handling changes state; it does not paint directly. Invalidate
        ; only the parent area ABOVE the ListBox so WM_PAINT can render the new
        ; application state without pointlessly repainting the whole child.
        invoke GetClientRect, [hwnd], statusInvalidateRect

        mov     eax, [ScaledTitleHeight]
        mov     [statusInvalidateRect.top], eax

        mov     eax, [ListBoxY]
        mov     [statusInvalidateRect.bottom], eax

        invoke InvalidateRect, [hwnd], statusInvalidateRect, FALSE

        xor     eax, eax
        jmp     .finish


; ---------------------------------------------------------------------------
; Borderless resize hit testing.
; ---------------------------------------------------------------------------

.wmnchittest:
        movsx   eax, word [lparam]
        movsx   edx, word [lparam + 2]

        mov     [pt.x], eax
        mov     [pt.y], edx

        invoke ScreenToClient, [hwnd], pt
        invoke GetClientRect, [hwnd], rect

        mov     eax, [pt.x]
        mov     edx, [pt.y]

        ; Visible bottom-right grip first so its larger mouse target wins.
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
        mov     ebx, [ScaledBorderSize]

        ; left?
        cmp     eax, ebx
        jge     .not_left

        ; top-left?
        cmp     edx, ebx
        jl      .top_left

        ; bottom-left?
        mov     ecx, [rect.bottom]
        sub     ecx, ebx
        cmp     edx, ecx
        jge     .bottom_left

        mov     eax, HTLEFT
        jmp     .finish

.not_left:
        ; right?
        mov     ecx, [rect.right]
        sub     ecx, ebx
        cmp     eax, ecx
        jl      .not_right

        ; top-right?
        cmp     edx, ebx
        jl      .top_right

        ; bottom-right?
        mov     ecx, [rect.bottom]
        sub     ecx, ebx
        cmp     edx, ecx
        jge     .bottom_right

        mov     eax, HTRIGHT
        jmp     .finish

.not_right:
        ; top?
        cmp     edx, ebx
        jl      .top

        ; bottom?
        mov     ecx, [rect.bottom]
        sub     ecx, ebx
        cmp     edx, ecx
        jge     .bottom

        mov     eax, HTCLIENT
        jmp     .finish

.top:
        mov     eax, HTTOP
        jmp     .finish

.bottom:
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
        call    LayoutControls
        invoke InvalidateRect, [hwnd], NULL, FALSE

        xor     eax, eax
        jmp     .finish


; ---------------------------------------------------------------------------
; Per-monitor DPI change.
; ---------------------------------------------------------------------------

.wmdpichanged:
        movzx   eax, word [wparam]
        mov     [CurrentDpi], eax

        call    UpdateScaledValues
        call    UpdateUiFont

        ; WM_MEASUREITEM is a creation-time contract for owner-draw-fixed.
        ; After a live DPI change, explicitly update the fixed item height.
        cmp     [hListBox], 0
        je      .dpi_no_list_height

        invoke SendMessageW, [hListBox], LB_SETITEMHEIGHT, 0, [ScaledListItemHeight]

.dpi_no_list_height:
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

        call    LayoutControls

        invoke InvalidateRect, [hwnd], NULL, FALSE
        invoke InvalidateRect, [hListBox], NULL, TRUE

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
        ; A child HWND is destroyed automatically when its parent is destroyed.
        ; GDI objects created by this application remain OUR responsibility.
        cmp     [hUiFont], 0
        je      .no_ui_font

        invoke DeleteObject, [hUiFont]
        mov     [hUiFont], 0

.no_ui_font:
        cmp     [hListBrushSelected], 0
        je      .no_selected_brush

        invoke DeleteObject, [hListBrushSelected]
        mov     [hListBrushSelected], 0

.no_selected_brush:
        cmp     [hListBrushNormal], 0
        je      .no_normal_brush

        invoke DeleteObject, [hListBrushNormal]
        mov     [hListBrushNormal], 0

.no_normal_brush:
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
; AddDemoItems
;
; LB_ADDSTRING is a ListBox message -- not a function call into our own storage.
; With LBS_HASSTRINGS, USER32 copies each UTF-16 string into the control's item
; collection. The source strings therefore do not become the ListBox storage.
; ============================================================================

proc AddDemoItems

        invoke SendMessageW, [hListBox], LB_ADDSTRING, 0, sItemButton
        test    eax, eax
        js      .failed

        invoke SendMessageW, [hListBox], LB_ADDSTRING, 0, sItemListBox
        test    eax, eax
        js      .failed

        invoke SendMessageW, [hListBox], LB_ADDSTRING, 0, sItemListView
        test    eax, eax
        js      .failed

        invoke SendMessageW, [hListBox], LB_ADDSTRING, 0, sItemTreeView
        test    eax, eax
        js      .failed

        invoke SendMessageW, [hListBox], LB_ADDSTRING, 0, sItemTabControl
        test    eax, eax
        js      .failed

        mov     eax, TRUE
        ret

.failed:
        xor     eax, eax
        ret
endp


; ============================================================================
; UpdateScaledValues
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

        invoke MulDiv, CONTENT_MARGIN_96, [CurrentDpi], 96
        mov     [ScaledContentMargin], eax

        invoke MulDiv, STATUS_HEIGHT_96, [CurrentDpi], 96
        mov     [ScaledStatusHeight], eax

        invoke MulDiv, STATUS_TO_LIST_GAP_96, [CurrentDpi], 96
        mov     [ScaledStatusToListGap], eax

        invoke MulDiv, STATUS_LABEL_WIDTH_96, [CurrentDpi], 96
        mov     [ScaledStatusLabelWidth], eax

        invoke MulDiv, STATUS_LABEL_GAP_96, [CurrentDpi], 96
        mov     [ScaledStatusLabelGap], eax

        invoke MulDiv, LISTBOX_ITEM_HEIGHT_96, [CurrentDpi], 96
        mov     [ScaledListItemHeight], eax

        invoke MulDiv, LISTBOX_TEXT_PAD_96, [CurrentDpi], 96
        mov     [ScaledListTextPad], eax

        invoke MulDiv, LISTBOX_FOCUS_INSET_96, [CurrentDpi], 96
        mov     [ScaledListFocusInset], eax

        ret
endp


; ============================================================================
; UpdateUiFont
;
; One HFONT is application-owned. The ListBox receives the handle with
; WM_SETFONT but does not take ownership of it.
; ============================================================================

proc UpdateUiFont uses rbx rsi

        mov     rbx, [hUiFont]

        invoke MulDiv, LISTBOX_FONT_HEIGHT_96, [CurrentDpi], 96
        neg     eax
        mov     esi, eax

        invoke CreateFontW, esi, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,\
               DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,\
               CLEARTYPE_QUALITY, DEFAULT_PITCH + FF_DONTCARE, UiFontName

        test    rax, rax
        jz      .failed

        mov     [hUiFont], rax

        cmp     [hListBox], 0
        je      .font_not_sent

        invoke SendMessageW, [hListBox], WM_SETFONT, rax, TRUE

.font_not_sent:
        test    rbx, rbx
        jz      .success

        invoke DeleteObject, rbx

.success:
        mov     eax, TRUE
        ret

.failed:
        mov     [hUiFont], rbx
        xor     eax, eax
        ret
endp


; ============================================================================
; LayoutControls
;
; Parent WM_SIZE owns child geometry. The ListBox receives one rectangle with
; DPI-aware margins. There is intentionally no extra framework/layout layer.
; ============================================================================

proc LayoutControls uses rbx rsi rdi

        cmp     [hListBox], 0
        je      .done

        invoke GetClientRect, [MainWindow], rect

        mov     eax, [ScaledContentMargin]
        mov     [ListBoxX], eax

        mov     eax, [ScaledTitleHeight]
        add     eax, [ScaledContentMargin]
        add     eax, [ScaledStatusHeight]
        add     eax, [ScaledStatusToListGap]
        mov     [ListBoxY], eax

        mov     eax, [rect.right]
        sub     eax, [ScaledContentMargin]
        sub     eax, [ListBoxX]
        mov     [ListBoxW], eax

        mov     eax, [rect.bottom]
        sub     eax, [ScaledContentMargin]
        sub     eax, [ListBoxY]
        mov     [ListBoxH], eax

        ; Guard tiny window sizes so MoveWindow never receives negative values.
        cmp     [ListBoxW], 1
        jge     .width_ok
        mov     dword [ListBoxW], 1
.width_ok:
        cmp     [ListBoxH], 1
        jge     .height_ok
        mov     dword [ListBoxH], 1
.height_ok:

        invoke MoveWindow, [hListBox],\
               [ListBoxX], [ListBoxY], [ListBoxW], [ListBoxH], TRUE

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

        invoke GetClientRect, [hwnd], rect
        invoke FillRect, [hdc], rect, [wc.hbrBackground]

        ; --------------------------------------------------------------------
        ; Custom title strip.
        ; --------------------------------------------------------------------
        mov     dword [rect.left], 0
        mov     dword [rect.top], 0
        mov     eax, [ScaledTitleHeight]
        mov     [rect.bottom], eax

        invoke CreateSolidBrush, TITLE_COLOR
        mov     [brush], rax
        test    rax, rax
        jz      .skip_title_fill

        invoke FillRect, [hdc], rect, [brush]
        invoke DeleteObject, [brush]

.skip_title_fill:
        ; --------------------------------------------------------------------
        ; Custom close button.
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

        invoke CreateSolidBrush, TITLE_COLOR
        mov     [brush], rax
        test    rax, rax
        jz      .skip_close_fill

        invoke FillRect, [hdc], rect, [brush]
        invoke DeleteObject, [brush]

.skip_close_fill:
        invoke SetBkMode, [hdc], TRANSPARENT
        invoke SetTextColor, [hdc], STATUS_TEXT_DIM

        invoke DrawTextW, [hdc], _closeX, -1, rect,\
               DT_CENTER + DT_VCENTER + DT_SINGLELINE

        ; --------------------------------------------------------------------
        ; Application state painted above the ListBox.
        ;
        ; Before a selection exists we show an instruction. After LBN_SELCHANGE
        ; the handler mirrors the selected string into SelectedTextBuffer and
        ; invalidates only this status region. WM_PAINT renders that state here.
        ; --------------------------------------------------------------------
        invoke GetClientRect, [hwnd], statusRect

        mov     eax, [ScaledContentMargin]
        mov     [statusRect.left], eax

        mov     eax, [statusRect.right]
        sub     eax, [ScaledContentMargin]
        mov     [statusRect.right], eax

        mov     eax, [ScaledTitleHeight]
        add     eax, [ScaledContentMargin]
        mov     [statusRect.top], eax

        add     eax, [ScaledStatusHeight]
        mov     [statusRect.bottom], eax

        invoke SelectObject, [hdc], [hUiFont]
        mov     rdi, rax
        invoke SetBkMode, [hdc], TRANSPARENT

        cmp     dword [CurrentSelection], -1
        jne     .paint_selected_status

        invoke SetTextColor, [hdc], STATUS_TEXT_DIM
        invoke DrawTextW, [hdc], StatusPrompt, -1, statusRect,\
               DT_LEFT + DT_VCENTER + DT_SINGLELINE
        jmp     .status_done

.paint_selected_status:
        ; Divide one line into a fixed-width label region and a value region.
        mov     eax, [statusRect.left]
        mov     [statusLabelRect.left], eax
        mov     eax, [statusRect.top]
        mov     [statusLabelRect.top], eax
        mov     eax, [statusRect.bottom]
        mov     [statusLabelRect.bottom], eax

        mov     eax, [statusRect.left]
        add     eax, [ScaledStatusLabelWidth]
        mov     [statusLabelRect.right], eax

        mov     eax, [statusLabelRect.right]
        add     eax, [ScaledStatusLabelGap]
        mov     [statusValueRect.left], eax
        mov     eax, [statusRect.top]
        mov     [statusValueRect.top], eax
        mov     eax, [statusRect.right]
        mov     [statusValueRect.right], eax
        mov     eax, [statusRect.bottom]
        mov     [statusValueRect.bottom], eax

        invoke SetTextColor, [hdc], STATUS_TEXT_DIM
        invoke DrawTextW, [hdc], StatusLabel, -1, statusLabelRect,\
               DT_LEFT + DT_VCENTER + DT_SINGLELINE

        invoke SetTextColor, [hdc], STATUS_TEXT_SELECTED
        invoke DrawTextW, [hdc], SelectedTextBuffer, -1, statusValueRect,\
               DT_LEFT + DT_VCENTER + DT_SINGLELINE + DT_END_ELLIPSIS

.status_done:
        invoke SelectObject, [hdc], rdi

        ; --------------------------------------------------------------------
        ; Dark bottom-right resize grip retained from the Window lessons.
        ; --------------------------------------------------------------------
        invoke GetClientRect, [hwnd], rect

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

        invoke SelectObject, [hdc], rsi
        invoke DeleteObject, rbx

.grip_done:
        invoke EndPaint, [hwnd], ps
        ret
endp


; ============================================================================
; HandleMouseClick
; ============================================================================

proc HandleMouseClick uses rbx rsi rdi, hwnd, packedLParam

        mov     [hwnd], rcx
        mov     [packedLParam], rdx

        mov     eax, dword [packedLParam]

        movsx   ecx, ax
        mov     [MouseX], ecx

        shr     eax, 16
        movsx   ecx, ax
        mov     [MouseY], ecx

        ; Close button.
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
        ; Client click in the title strip -> hand the drag loop back to USER32.
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

        _title          du 'ListBox 1.0 - Dark Items & Selection', 0
        _class          du 'FASMWIN64_DARK_LISTBOX_SELECTION', 0
        _error          du 'Startup failed.', 0
        _closeX         du 'X', 0

        ListBoxClassName du 'LISTBOX', 0
        UiFontName       du 'Segoe UI', 0

        StatusPrompt     du 'Click one of the items shown in the window.', 0
        StatusLabel      du 'Selected:', 0

        sItemButton      du 'Button', 0
        sItemListBox     du 'ListBox', 0
        sItemListView    du 'ListView', 0
        sItemTreeView    du 'TreeView', 0
        sItemTabControl  du 'TabControl', 0

; ---------------------------------------------------------------------------
; Owner-draw structures.
;
; The project's proven ListBox 1.7 source uses these exact Win64 layouts.
; Pointer-sized members require 8-byte alignment on x64.
;
; MEASUREITEMSTRUCT64_LOCAL = 20h bytes
; DRAWITEMSTRUCT64_LOCAL    = 40h bytes
; ---------------------------------------------------------------------------

struct MEASUREITEMSTRUCT64_LOCAL
  CtlType      dd ?                 ; 00h
  CtlID        dd ?                 ; 04h
  itemID       dd ?                 ; 08h
  itemWidth    dd ?                 ; 0Ch
  itemHeight   dd ?                 ; 10h
  pad0         dd ?                 ; 14h -> align ULONG_PTR
  itemData     dq ?                 ; 18h
ends                                  ; sizeof = 20h

struct DRAWITEMSTRUCT64_LOCAL
  CtlType      dd ?                 ; 00h
  CtlID        dd ?                 ; 04h
  itemID       dd ?                 ; 08h
  itemAction   dd ?                 ; 0Ch
  itemState    dd ?                 ; 10h
  pad0         dd ?                 ; 14h -> align HWND
  hwndItem     dq ?                 ; 18h
  hDC          dq ?                 ; 20h
  rcItemLeft   dd ?                 ; 28h
  rcItemTop    dd ?                 ; 2Ch
  rcItemRight  dd ?                 ; 30h
  rcItemBottom dd ?                 ; 34h
  itemData     dq ?                 ; 38h
ends                                  ; sizeof = 40h

        rect                 RECT
        ownerDrawRect        RECT
        focusRect            RECT
        statusRect           RECT
        statusLabelRect      RECT
        statusValueRect      RECT
        statusInvalidateRect RECT
        msg                  MSG
        ps                   PAINTSTRUCT
        pt                   POINT

        wc WNDCLASSEX sizeof.WNDCLASSEX, CS_HREDRAW + CS_VREDRAW, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE + 1, NULL, _class, NULL

        WinX                 dd 0
        WinY                 dd 0
        WinW                 dd 620
        WinH                 dd 470

        CloseBtnX            dd 0
        MouseX               dd 0
        MouseY               dd 0

        ; --------------------------------------------------------------------
        ; Application state.
        ;
        ; The ListBox owns its real selected index internally. These two values
        ; are a mirror used only so the PARENT can paint "Selected: ...".
        ; --------------------------------------------------------------------
        CurrentSelection     dd -1
        SelectedTextBuffer   rw LISTBOX_TEXT_CAPACITY
        DrawItemTextBuffer   rw LISTBOX_TEXT_CAPACITY

        ; DPI-aware child layout.
        ListBoxX             dd 0
        ListBoxY             dd 0
        ListBoxW             dd 0
        ListBoxH             dd 0

        ; Small synchronous scratch values for the familiar resize grip.
        GripX                dd 0
        GripY                dd 0
        GripInset            dd GRIP_INSET_96
        GripPenWidth         dd GRIP_PEN_WIDTH_96
        FocusInsetNeg        dd -LISTBOX_FOCUS_INSET_96

        hwnd                 dq 0
        lparam               dq 0
        packedLParam         dq 0
        hdc                  dq 0
        brush                dq 0

        MainWindow           dq 0
        hListBox             dq 0
        hUiFont              dq 0
        hListBrushNormal     dq 0
        hListBrushSelected   dq 0

        CurrentDpi                 dd 96
        ScaledTitleHeight          dd TITLE_HEIGHT_96
        ScaledCloseBtnSize         dd CLOSE_BTN_SIZE_96
        ScaledBorderSize           dd BORDER_SIZE_96
        ScaledGripSize             dd GRIP_SIZE_96
        ScaledContentMargin        dd CONTENT_MARGIN_96
        ScaledStatusHeight         dd STATUS_HEIGHT_96
        ScaledStatusToListGap      dd STATUS_TO_LIST_GAP_96
        ScaledStatusLabelWidth     dd STATUS_LABEL_WIDTH_96
        ScaledStatusLabelGap       dd STATUS_LABEL_GAP_96
        ScaledListItemHeight       dd LISTBOX_ITEM_HEIGHT_96
        ScaledListTextPad          dd LISTBOX_TEXT_PAD_96
        ScaledListFocusInset       dd LISTBOX_FOCUS_INSET_96


; ============================================================================
; Imports
; ============================================================================

section '.idata' import data readable writeable

        library kernel32, 'KERNEL32.DLL',\
                user32,   'USER32.DLL',\
                gdi32,    'GDI32.DLL'

        import kernel32,\
               GetModuleHandleW, 'GetModuleHandleW',\
               ExitProcess,      'ExitProcess',\
               MulDiv,           'MulDiv'

        import user32,\
               RegisterClassExW,              'RegisterClassExW',\
               CreateWindowExW,               'CreateWindowExW',\
               DefWindowProcW,                'DefWindowProcW',\
               ShowWindow,                    'ShowWindow',\
               UpdateWindow,                  'UpdateWindow',\
               GetMessageW,                   'GetMessageW',\
               TranslateMessage,              'TranslateMessage',\
               DispatchMessageW,              'DispatchMessageW',\
               PostQuitMessage,               'PostQuitMessage',\
               PostMessageW,                  'PostMessageW',\
               SendMessageW,                  'SendMessageW',\
               MessageBoxW,                   'MessageBoxW',\
               LoadIconW,                     'LoadIconW',\
               LoadCursorW,                   'LoadCursorW',\
               GetSystemMetrics,              'GetSystemMetrics',\
               GetClientRect,                 'GetClientRect',\
               ScreenToClient,                'ScreenToClient',\
               MoveWindow,                    'MoveWindow',\
               SetWindowPos,                  'SetWindowPos',\
               BeginPaint,                    'BeginPaint',\
               EndPaint,                      'EndPaint',\
               FillRect,                      'FillRect',\
               FrameRect,                     'FrameRect',\
               InflateRect,                   'InflateRect',\
               DrawFocusRect,                 'DrawFocusRect',\
               DrawTextW,                     'DrawTextW',\
               SetProcessDpiAwarenessContext, 'SetProcessDpiAwarenessContext',\
               GetDpiForWindow,               'GetDpiForWindow',\
               InvalidateRect,                'InvalidateRect',\
               ReleaseCapture,                'ReleaseCapture'

        import gdi32,\
               CreateSolidBrush, 'CreateSolidBrush',\
               CreateFontW,      'CreateFontW',\
               CreatePen,        'CreatePen',\
               SelectObject,     'SelectObject',\
               DeleteObject,     'DeleteObject',\
               SetBkMode,        'SetBkMode',\
               SetBkColor,       'SetBkColor',\
               SetTextColor,     'SetTextColor',\
               SaveDC,           'SaveDC',\
               RestoreDC,        'RestoreDC',\
               MoveToEx,         'MoveToEx',\
               LineTo,           'LineTo'
