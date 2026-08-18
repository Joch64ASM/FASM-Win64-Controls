include 'win64Wx.inc'
entry main

WM_DPICHANGED equ 02E0h

; =========================================================
; ListBox 1.7 - EOF File Report - DYNAMIC BOX WIDTH
;
; This is the first merger of two ideas:
;
;   1) our clean native dark ListBox lesson
;   2) the useful file-information idea from the old EOF.ASM
;
; One significant evolution from ListBox 1.3:
;
;   * remove the artificial "ListBox item 1...8" demo data
;   * accept ONE file by drag/drop
;   * show a real FILE INFORMATION report inside the ListBox
;
; One significant evolution from 1.4:
;
;   * keep the proven FILE INFORMATION box unchanged
;   * add a second PE INFORMATION box below it
;   * safely validate MZ / PE before reading PE header fields
;
; One significant evolution from 1.6:
;
;   * remove File: path wrapping again
;   * size the complete report box from the printed File: path
;   * allocate the dynamic report-line scratch block from the process heap
;   * enable horizontal scrolling only when the resulting box is wider
;     than the visible ListBox client area
;
; Real EOF / overlay detection still belongs to the NEXT evolution.
;
; This comparison version uses the THIN Unicode box-drawing set:
;
;   U+250C  ┌     U+2500  ─     U+2510  ┐
;   U+2502  │     U+251C  ├     U+2524  ┤
;   U+2514  └                    U+2518  ┘
;
; These are Unicode characters, not the old OEM/extended-ASCII byte codes.
; The ListBox is also display-only now: LBS_NOSEL prevents row selection.
; =========================================================

; =========================================================
; UI DESIGN VALUES - based on 96 DPI
; =========================================================

TITLE_HEIGHT_96        equ 30
CLOSE_BTN_SIZE_96      equ 32
BORDER_SIZE_96         equ 8
MARGIN_96              equ 10
LISTBOX_FONT_HEIGHT_96 equ 18
LISTBOX_ITEM_HEIGHT_96 equ 18
LISTBOX_TEXT_PAD_96    equ 8

IDC_LISTBOX             equ 1001

; The report is a character-cell layout rendered with Consolas. 1.7 no
; longer hard-codes an 82-character interior. The current box width is
; calculated from the complete printed " File: <path>" line, with a small
; minimum width so short filenames still produce a pleasant report.
;
; IMPORTANT: the row height intentionally matches the 18-pixel design
; font height. A larger owner-draw item creates vertical leading between
; ListBox rows, so separate U+2502 box-line glyphs cannot visually join.
;
; A worst-case MAX_PATH file line is slightly larger than MAX_PATH once the
; label and two border characters are included. In keeping with this project's
; rule, those larger temporary line buffers are allocated from the process heap
; only while a report is being built.
BOX_MIN_INNER_CHARS     equ 60

; LB_SETHORIZONTALEXTENT is required because a ListBox does not calculate
; horizontal scroll width automatically. It is meaningful with WS_HSCROLL.
LB_SETHORIZONTALEXTENT_LOCAL equ 0194h

; Owner-draw values used by WM_MEASUREITEM / WM_DRAWITEM.
ODT_LISTBOX_LOCAL       equ 2

; LBS_NOSEL makes the ListBox a display/scroll surface: items can be
; viewed but USER32 does not allow them to become selected. Define it
; locally so this example does not depend on a particular include set.
LBS_NOSEL_LOCAL         equ 00004000h

; =========================================================
; PE/COFF on-disk values used by the second report box
; =========================================================
;
; These are file-format offsets/constants, not Win64 in-memory ABI
; structures. The PE/COFF header layout on disk is fixed. We need only
; a few fields in this lesson, so there is no reason to duplicate the complete
; IMAGE_NT_HEADERS structures from pe.inc.
;
; DOS header
PE_DOS_E_LFANEW          equ 03Ch

; From the address of the four-byte PE\0\0 signature:
PE_FILE_MACHINE          equ 04h
PE_FILE_SECTIONS         equ 06h
PE_FILE_SIZE_OPTIONAL    equ 14h
PE_FILE_CHARACTERISTICS  equ 16h
PE_OPTIONAL_MAGIC        equ 18h
PE_MIN_BYTES_FOR_MAGIC   equ 1Ah     ; signature + FILE_HEADER + WORD magic

PE_SIGNATURE             equ 00004550h
PE_MAGIC_32               equ 010Bh
PE_MAGIC_64               equ 020Bh

PE_MACHINE_I386          equ 014Ch
PE_MACHINE_AMD64         equ 8664h
PE_MACHINE_ARM           equ 01C0h
PE_MACHINE_ARM64         equ 0AA64h

PE_CHARACTERISTIC_DLL    equ 2000h

; Read-only file mapping values. Defined locally to keep the example
; independent of how a particular FASM include package spells them.
PAGE_READONLY_LOCAL      equ 00000002h
FILE_MAP_READ_LOCAL      equ 00000004h

; Thin Unicode box-drawing characters.
BOX_TOP_LEFT            equ 250Ch   ; ┌
BOX_TOP_RIGHT           equ 2510h   ; ┐
BOX_BOTTOM_LEFT         equ 2514h   ; └
BOX_BOTTOM_RIGHT        equ 2518h   ; ┘
BOX_HORIZONTAL          equ 2500h   ; ─
BOX_VERTICAL            equ 2502h   ; │
BOX_MIDDLE_LEFT         equ 251Ch   ; ├
BOX_MIDDLE_RIGHT        equ 2524h   ; ┤

; Borderless-window hit-test values.
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


main:
        sub rsp, 8

        ; Per-Monitor-V2 must be selected before creating our windows.
        invoke SetProcessDpiAwarenessContext, DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2

        invoke GetModuleHandleW, 0
        mov [wc.hInstance], rax

        invoke LoadIconW, 0, IDI_APPLICATION
        mov [wc.hIcon], rax
        mov [wc.hIconSm], rax

        invoke LoadCursorW, 0, IDC_ARROW
        mov [wc.hCursor], rax

        ; Persistent brushes owned by this application.
        invoke CreateSolidBrush, 001E1E1Eh
        mov [wc.hbrBackground], rax

        invoke CreateSolidBrush, 001E1E1Eh
        mov [hListBrush], rax

        ; Dynamic box rows can become slightly larger than MAX_PATH once the
        ; " File: " label and box sides are included. Keep those transient
        ; builders on the process heap, not in the executable's .data section.
        invoke GetProcessHeap
        test rax, rax
        jz error
        mov [hProcessHeap], rax

        ; Start centered on the primary screen.
        invoke GetSystemMetrics, SM_CXSCREEN
        sub eax, [WinW]
        shr eax, 1
        mov [WinX], eax

        invoke GetSystemMetrics, SM_CYSCREEN
        sub eax, [WinH]
        shr eax, 1
        mov [WinY], eax

        invoke RegisterClassExW, wc
        test rax, rax
        jz error

        invoke CreateWindowExW, 0, _class, _title,\
               WS_POPUP,\
               [WinX], [WinY], [WinW], [WinH],\
               0, 0, [wc.hInstance], 0

        test rax, rax
        jz error

        mov [MainWindow], rax

        ; Register ONLY the top-level window as the WM_DROPFILES recipient.
        ; The HDROP handle is valid for the duration of that message and is
        ; released with DragFinish after the file name has been copied.
        invoke DragAcceptFiles, [MainWindow], TRUE

        ; -------------------------------------------------
        ; Starting DPI and scaled geometry.
        ; -------------------------------------------------

        invoke GetDpiForWindow, [MainWindow]
        mov [CurrentDpi], eax

        invoke MulDiv, TITLE_HEIGHT_96, [CurrentDpi], 96
        mov [ScaledTitleHeight], eax

        invoke MulDiv, CLOSE_BTN_SIZE_96, [CurrentDpi], 96
        mov [ScaledCloseBtnSize], eax

        invoke MulDiv, BORDER_SIZE_96, [CurrentDpi], 96
        mov [ScaledBorderSize], eax

        invoke MulDiv, MARGIN_96, [CurrentDpi], 96
        mov [ScaledMargin], eax

        invoke MulDiv, LISTBOX_FONT_HEIGHT_96, [CurrentDpi], 96
        mov [ScaledListFontHeight], eax

        invoke MulDiv, LISTBOX_ITEM_HEIGHT_96, [CurrentDpi], 96
        mov [ScaledListItemHeight], eax

        invoke MulDiv, LISTBOX_TEXT_PAD_96, [CurrentDpi], 96
        mov [ScaledListTextPad], eax

        ; =================================================
        ; Create the native Unicode LISTBOX.
        ; =================================================
        ;
        ; LBS_OWNERDRAWFIXED:
        ;   USER32 still owns scrolling, hit testing and string storage,
        ;   while the parent paints each row.
        ;
        ; LBS_HASSTRINGS:
        ;   keeps normal LB_ADDSTRING / LB_GETTEXT string behavior.
        ;
        ; LBS_NOSEL:
        ;   makes this report ListBox non-selectable. There is therefore no
        ;   selection bar to paint or suppress -- the rows are display only.
        ; =================================================

        mov eax, [ScaledTitleHeight]
        add eax, [ScaledMargin]

        invoke CreateWindowExW, 0, _listBoxClass, 0,\
               WS_CHILD + WS_VISIBLE + WS_VSCROLL + WS_HSCROLL +\
               LBS_NOINTEGRALHEIGHT + LBS_OWNERDRAWFIXED + LBS_HASSTRINGS + LBS_NOSEL_LOCAL,\
               [ScaledMargin], eax, 760, 360,\
               [MainWindow], IDC_LISTBOX, [wc.hInstance], 0

        test rax, rax
        jz error

        mov [hListBox], rax

        invoke SendMessageW, [hListBox], LB_SETITEMHEIGHT, 0, [ScaledListItemHeight]

        call UpdateListBoxFont

        ; Start CLEAN, like the original EOF.ASM: no welcome/demo rows.
        ; The ListBox stays empty until one file is dropped onto the window.

        mov rcx, [MainWindow]
        call LayoutControls

        invoke ShowWindow, [MainWindow], SW_SHOW
        invoke UpdateWindow, [MainWindow]

msg_loop:
        invoke GetMessageW, msg, 0, 0, 0
        cmp eax, 1
        jb end_loop
        jne msg_loop

        invoke TranslateMessage, msg
        invoke DispatchMessageW, msg
        jmp msg_loop

error:
        invoke MessageBoxW, NULL, _error, NULL, MB_ICONERROR + MB_OK

end_loop:
        invoke ExitProcess, [msg.wParam]


; =========================================================
; Main window procedure
; =========================================================

proc WindowProc uses rbx rsi rdi r12, hwnd, wmsg, wparam, lparam

     mov [hwnd], rcx
     mov [wmsg], rdx
     mov [wparam], r8
     mov [lparam], r9

     cmp [wmsg], WM_PAINT
     je .wmpaint

     cmp [wmsg], WM_MEASUREITEM
     je .wmmeasureitem

     cmp [wmsg], WM_DRAWITEM
     je .wmdrawitem

     cmp [wmsg], WM_CTLCOLORLISTBOX
     je .wmctlcolorlistbox

     cmp [wmsg], WM_DROPFILES
     je .wmdropfiles

     cmp [wmsg], WM_LBUTTONDOWN
     je .wmlbuttondown

     cmp [wmsg], WM_NCHITTEST
     je .wmnchittest

     cmp [wmsg], WM_SIZE
     je .wmsize

     cmp [wmsg], WM_DPICHANGED
     je .wmdpichanged

     cmp [wmsg], WM_DESTROY
     je .wmdestroy

     invoke DefWindowProcW, [hwnd], [wmsg], [wparam], [lparam]
     jmp .finish


.wmmeasureitem:
     ; LBS_OWNERDRAWFIXED asks the PARENT for the common row height.
     ; This can happen during CreateWindowExW before hListBox is assigned,
     ; so identify the request by type + control ID.

     mov rbx, [lparam]

     cmp dword [rbx + MEASUREITEMSTRUCT64_LOCAL.CtlType], ODT_LISTBOX_LOCAL
     jne .measure_not_ours

     cmp dword [rbx + MEASUREITEMSTRUCT64_LOCAL.CtlID], IDC_LISTBOX
     jne .measure_not_ours

     mov eax, [ScaledListItemHeight]
     mov [rbx + MEASUREITEMSTRUCT64_LOCAL.itemHeight], eax

     mov eax, TRUE
     jmp .finish

.measure_not_ours:
     invoke DefWindowProcW, [hwnd], [wmsg], [wparam], [lparam]
     jmp .finish


.wmdrawitem:
     ; -----------------------------------------------------
     ; Owner-drawn dark ListBox rows.
     ;
     ; 1.7 can contain a row slightly wider than MAX_PATH, so WM_DRAWITEM
     ; retrieves each row into an exact-size temporary heap buffer.
     ; -----------------------------------------------------

     mov rbx, [lparam]

     cmp dword [rbx + DRAWITEMSTRUCT64_LOCAL.CtlType], ODT_LISTBOX_LOCAL
     jne .draw_not_ours

     cmp dword [rbx + DRAWITEMSTRUCT64_LOCAL.CtlID], IDC_LISTBOX
     jne .draw_not_ours

     ; Copy Windows' row rectangle because we add text padding.
     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemLeft]
     mov [ownerDrawRect.left], eax
     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemTop]
     mov [ownerDrawRect.top], eax
     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemRight]
     mov [ownerDrawRect.right], eax
     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemBottom]
     mov [ownerDrawRect.bottom], eax

     ; This ListBox uses LBS_NOSEL, so every report row has the same
     ; background. There is intentionally no selected-row visual state.
     mov rdi, [hListBrush]
     invoke FillRect, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], ownerDrawRect, rdi

     ; itemID == -1 describes a non-item/empty area.
     mov esi, [rbx + DRAWITEMSTRUCT64_LOCAL.itemID]
     cmp esi, -1
     je .draw_done

     ; 1.7 report rows are dynamic. A long File: path can make one row a
     ; little larger than MAX_PATH, so do not reintroduce a large static
     ; owner-draw buffer. Ask USER32 for the exact item length and allocate
     ; only that many WCHARs for this synchronous WM_DRAWITEM call.
     invoke SendMessageW, [rbx + DRAWITEMSTRUCT64_LOCAL.hwndItem], LB_GETTEXTLEN, rsi, 0
     cmp rax, LB_ERR
     je .draw_done

     inc rax                         ; terminating WCHAR
     shl rax, 1                      ; WCHAR count -> bytes

     invoke HeapAlloc, [hProcessHeap], 0, rax
     test rax, rax
     jz .draw_done

     mov rdi, rax                    ; RDI = temporary row string

     invoke SendMessageW, [rbx + DRAWITEMSTRUCT64_LOCAL.hwndItem], LB_GETTEXT, rsi, rdi
     cmp rax, LB_ERR
     je .draw_free_text

     ; WM_DRAWITEM gives us a control-owned HDC. Select our font only for
     ; this draw and restore the previous object before returning.
     invoke SelectObject, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], [hListFont]
     mov r12, rax                    ; previous HFONT

     invoke SetBkMode, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], TRANSPARENT
     invoke SetTextColor, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], 00D8D8D8h

     mov eax, [ScaledListTextPad]
     add [ownerDrawRect.left], eax
     sub [ownerDrawRect.right], eax

     ; No ellipsis now. If the dynamic box is wider than the ListBox, the
     ; horizontal scrollbar exposes the remaining cells instead of replacing
     ; them with "...".
     invoke DrawTextW, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], rdi, -1, ownerDrawRect,\
            DT_LEFT + DT_VCENTER + DT_SINGLELINE

     invoke SelectObject, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], r12

.draw_free_text:
     invoke HeapFree, [hProcessHeap], 0, rdi

.draw_done:
     mov eax, TRUE
     jmp .finish

.draw_not_ours:
     invoke DefWindowProcW, [hwnd], [wmsg], [wparam], [lparam]
     jmp .finish


.wmctlcolorlistbox:
     ; Covers any ListBox client area that is not occupied by an item row.

     mov rax, [lparam]
     cmp rax, [hListBox]
     jne .color_not_ours

     invoke SetTextColor, [wparam], 00D8D8D8h
     invoke SetBkColor, [wparam], 001E1E1Eh
     invoke SetBkMode, [wparam], TRANSPARENT

     mov rax, [hListBrush]
     jmp .finish

.color_not_ours:
     invoke DefWindowProcW, [hwnd], [wmsg], [wparam], [lparam]
     jmp .finish


.wmdropfiles:
     ; wParam is the HDROP supplied by the Shell.
     mov rcx, [wparam]
     call HandleDroppedFiles

     xor eax, eax
     jmp .finish


.wmnchittest:
     ; lParam contains SCREEN coordinates packed into signed WORDs.
     movsx eax, word [lparam]
     movsx edx, word [lparam + 2]

     mov [pt.x], eax
     mov [pt.y], edx
     invoke ScreenToClient, [hwnd], pt

     invoke GetClientRect, [hwnd], rect

     mov eax, [pt.x]
     mov edx, [pt.y]

     cmp eax, [ScaledBorderSize]
     jl .left_side

     mov ecx, [rect.right]
     sub ecx, [ScaledBorderSize]
     cmp eax, ecx
     jg .right_side

     cmp edx, [ScaledBorderSize]
     jl .top_only

     mov ecx, [rect.bottom]
     sub ecx, [ScaledBorderSize]
     cmp edx, ecx
     jg .bottom_only

     mov eax, HTCLIENT
     jmp .finish

.left_side:
     cmp edx, [ScaledBorderSize]
     jl .topleft

     mov ecx, [rect.bottom]
     sub ecx, [ScaledBorderSize]
     cmp edx, ecx
     jg .bottomleft

     mov eax, HTLEFT
     jmp .finish

.right_side:
     cmp edx, [ScaledBorderSize]
     jl .topright

     mov ecx, [rect.bottom]
     sub ecx, [ScaledBorderSize]
     cmp edx, ecx
     jg .bottomright

     mov eax, HTRIGHT
     jmp .finish

.top_only:
     mov eax, HTTOP
     jmp .finish

.bottom_only:
     mov eax, HTBOTTOM
     jmp .finish

.topleft:
     mov eax, HTTOPLEFT
     jmp .finish

.topright:
     mov eax, HTTOPRIGHT
     jmp .finish

.bottomleft:
     mov eax, HTBOTTOMLEFT
     jmp .finish

.bottomright:
     mov eax, HTBOTTOMRIGHT
     jmp .finish


.wmsize:
     mov rcx, [hwnd]
     call LayoutControls

     invoke InvalidateRect, [hwnd], NULL, FALSE

     xor eax, eax
     jmp .finish


.wmdpichanged:
     movzx eax, word [wparam]
     mov [CurrentDpi], eax

     invoke MulDiv, TITLE_HEIGHT_96, eax, 96
     mov [ScaledTitleHeight], eax

     mov eax, [CurrentDpi]
     invoke MulDiv, CLOSE_BTN_SIZE_96, eax, 96
     mov [ScaledCloseBtnSize], eax

     mov eax, [CurrentDpi]
     invoke MulDiv, BORDER_SIZE_96, eax, 96
     mov [ScaledBorderSize], eax

     mov eax, [CurrentDpi]
     invoke MulDiv, MARGIN_96, eax, 96
     mov [ScaledMargin], eax

     mov eax, [CurrentDpi]
     invoke MulDiv, LISTBOX_FONT_HEIGHT_96, eax, 96
     mov [ScaledListFontHeight], eax

     mov eax, [CurrentDpi]
     invoke MulDiv, LISTBOX_ITEM_HEIGHT_96, eax, 96
     mov [ScaledListItemHeight], eax

     mov eax, [CurrentDpi]
     invoke MulDiv, LISTBOX_TEXT_PAD_96, eax, 96
     mov [ScaledListTextPad], eax

     call UpdateListBoxFont
     invoke SendMessageW, [hListBox], LB_SETITEMHEIGHT, 0, [ScaledListItemHeight]

     ; The horizontal extent is measured in pixels, so a DPI/font change
     ; requires recalculating it even though the character count is unchanged.
     cmp [CurrentBoxInnerChars], 0
     je .dpi_extent_done
     call UpdateListHorizontalExtent

.dpi_extent_done:
     invoke InvalidateRect, [hListBox], NULL, TRUE

     ; Microsoft supplies the recommended top-level rectangle.
     mov rbx, [lparam]

     mov eax, [rbx + RECT.right]
     sub eax, [rbx + RECT.left]
     mov ecx, eax

     mov eax, [rbx + RECT.bottom]
     sub eax, [rbx + RECT.top]
     mov edx, eax

     invoke SetWindowPos, [hwnd], 0,\
            [rbx + RECT.left], [rbx + RECT.top],\
            ecx, edx,\
            SWP_NOZORDER + SWP_NOACTIVATE

     invoke InvalidateRect, [hwnd], NULL, FALSE

     xor eax, eax
     jmp .finish


.wmpaint:
     mov rcx, [hwnd]
     call PaintWindow

     xor eax, eax
     jmp .finish


.wmlbuttondown:
     mov rcx, [hwnd]
     mov rdx, [lparam]
     call HandleMouseClick

     xor eax, eax
     jmp .finish


.wmdestroy:
     invoke DragAcceptFiles, [hwnd], FALSE

     ; Normally report scratch exists only during BuildFileReport, but keep
     ; shutdown defensive if a future edit introduces an early-exit path.
     call FreeReportScratch

     ; WM_SETFONT does not transfer ownership of our HFONT.
     cmp [hListFont], 0
     je .no_list_font

     invoke DeleteObject, [hListFont]
     mov [hListFont], 0

.no_list_font:
     cmp [hListBrush], 0
     je .no_list_brush

     invoke DeleteObject, [hListBrush]
     mov [hListBrush], 0

.no_list_brush:
     cmp [wc.hbrBackground], 0
     je .no_window_brush

     invoke DeleteObject, [wc.hbrBackground]
     mov [wc.hbrBackground], 0

.no_window_brush:
     invoke PostQuitMessage, 0
     xor eax, eax

.finish:
     ret
endp


; =========================================================
; HandleDroppedFiles
;
; RCX = HDROP
;
; Keep this first useful ListBox/EOF merger deliberately simple:
; accept exactly ONE file and copy its Unicode path into a MAX_PATH
; buffer, just like the spirit of the original EOF.ASM. MAX_PATH is
; explicitly within this project's static-buffer rule.
; =========================================================

proc HandleDroppedFiles uses rbx rsi rdi, hDrop

     mov [hDrop], rcx
     mov rbx, rcx

     ; iFile = FFFFFFFFh asks how many files are in this HDROP.
     invoke DragQueryFileW, rbx, -1, 0, 0
     cmp eax, 1
     jne .wrong_count

     ; Copy file #0 directly into our bounded Unicode path buffer.
     ; DragQueryFileW returns zero on failure.
     invoke DragQueryFileW, rbx, 0, DroppedPath, MAX_PATH
     test eax, eax
     jz .drop_failed

     ; We have copied everything we need from the shell-owned HDROP.
     invoke DragFinish, rbx

     mov rcx, DroppedPath
     call BuildFileReport
     ret

.drop_failed:
     invoke DragFinish, rbx
     mov rcx, sDropReadError
     call ShowSimpleErrorReport
     ret

.wrong_count:
     invoke DragFinish, rbx
     mov rcx, sOneFileOnly
     call ShowSimpleErrorReport
     ret
endp


; =========================================================
; BuildFileReport
;
; RCX = zero-terminated Unicode path
;
; 1.7 keeps the proven FILE INFORMATION work and also collects the small
; PE/COFF fields needed by the second report box. EOF/overlay calculation
; is deliberately still not part of this version.
; =========================================================

proc BuildFileReport uses rbx rsi rdi r12, pathPointer

     mov [pathPointer], rcx
     mov r12, rcx                    ; persistent only for this synchronous call

     mov [FileTimesValid], 0

     ; PE parser state is rebuilt from scratch for every dropped file.
     mov [PeDosValid], 0
     mov [PeHeaderValid], 0
     mov [PeMachine], 0
     mov [PeOptionalMagic], 0
     mov [PeCharacteristics], 0
     mov [PeSectionCount], 0

     invoke CreateFileW, r12, GENERIC_READ, FILE_SHARE_READ, 0,\
            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0

     cmp rax, INVALID_HANDLE_VALUE
     je .open_failed

     mov rbx, rax                    ; RBX = file HANDLE

     ; GetFileSizeEx gives the complete 64-bit physical file size.
     invoke GetFileSizeEx, rbx, FileSize
     test eax, eax
     jz .file_info_failed

     ; GetFileTime order is:
     ;   creation, last-access, last-write(modified)
     invoke GetFileTime, rbx, ftCreated, ftAccessed, ftModified
     test eax, eax
     jz .file_info_failed

     ; The file is already open. Reuse that HANDLE for one synchronous,
     ; read-only mapping and collect only the PE fields needed by this lesson.
     mov rcx, rbx
     call ParsePeInformation

     invoke CloseHandle, rbx

     ; Convert UTC FILETIME values to local FILETIME, then SYSTEMTIME.
     ; Keeping the names explicit avoids the modified/accessed swap that
     ; existed in the old experimental EOF source.
     invoke FileTimeToLocalFileTime, ftCreated, ftLocalCreated
     test eax, eax
     jz .times_ready

     invoke FileTimeToSystemTime, ftLocalCreated, stCreated
     test eax, eax
     jz .times_ready

     invoke FileTimeToLocalFileTime, ftModified, ftLocalModified
     test eax, eax
     jz .times_ready

     invoke FileTimeToSystemTime, ftLocalModified, stModified
     test eax, eax
     jz .times_ready

     invoke FileTimeToLocalFileTime, ftAccessed, ftLocalAccessed
     test eax, eax
     jz .times_ready

     invoke FileTimeToSystemTime, ftLocalAccessed, stAccessed
     test eax, eax
     jz .times_ready

     mov [FileTimesValid], 1

.times_ready:

     ; =====================================================
     ; Calculate ONE box width for this complete report.
     ; =====================================================
     ; The File: row is the only field whose length varies dramatically.
     ; Make the interior wide enough for " File: " + the complete dropped
     ; path, while retaining a pleasant minimum for short filenames.

     mov dword [CurrentBoxInnerChars], BOX_MIN_INNER_CHARS

     mov rcx, sLabelFile
     call UnicodeLengthChars
     mov ebx, eax

     mov rcx, r12
     call UnicodeLengthChars
     add eax, ebx

     cmp eax, [CurrentBoxInnerChars]
     jbe .box_width_ready
     mov [CurrentBoxInnerChars], eax

.box_width_ready:
     call AllocateReportScratch
     test eax, eax
     jz .report_memory_failed

     invoke SendMessageW, [hListBox], LB_RESETCONTENT, 0, 0
     call UpdateListHorizontalExtent

     ; ╔════════════╗
     mov ecx, BOX_TOP_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_TOP_RIGHT
     call AddFrameLine

     mov rcx, sFileInformationTitle
     call AddBoxText

     ; ╠════════════╣
     mov ecx, BOX_MIDDLE_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_MIDDLE_RIGHT
     call AddFrameLine

     ; The box itself was sized from this complete printed row, so the path
     ; now stays on ONE line -- no wrapping and no truncation.
     mov rcx, sLabelFile
     mov rdx, r12
     call AddBoxLabelText

     ; 64-bit file size. Do NOT use wsprintfW with %I64u here: wsprintfW
     ; has an old, restricted format set and does not define that conversion.
     ; Convert the UINT64 ourselves, then append the small Unicode suffix.
     mov rcx, [FileSize]
     call FormatFileSizeText

     mov rcx, sLabelSize
     mov rdx, numberText
     call AddBoxLabelText

     mov rcx, sEmpty
     call AddBoxText

     cmp [FileTimesValid], 0
     je .times_unavailable

     ; Created. Store the WORD fields into DWORD temporaries before the
     ; variadic wsprintfW call. This keeps the call site simple and avoids
     ; depending on argument-register contents while invoke prepares RCX/RDX/R8/R9.
     movzx eax, word [stCreated.wDay]
     mov [TempDay], eax
     movzx eax, word [stCreated.wMonth]
     mov [TempMonth], eax
     movzx eax, word [stCreated.wYear]
     mov [TempYear], eax
     movzx eax, word [stCreated.wHour]
     mov [TempHour], eax
     movzx eax, word [stCreated.wMinute]
     mov [TempMinute], eax
     movzx eax, word [stCreated.wSecond]
     mov [TempSecond], eax

     invoke wsprintfW, timeText, sTimeFormat, [TempDay], [TempMonth], [TempYear], [TempHour], [TempMinute], [TempSecond]

     mov rcx, sLabelCreated
     mov rdx, timeText
     call AddBoxLabelText

     ; Modified / last-write
     movzx eax, word [stModified.wDay]
     mov [TempDay], eax
     movzx eax, word [stModified.wMonth]
     mov [TempMonth], eax
     movzx eax, word [stModified.wYear]
     mov [TempYear], eax
     movzx eax, word [stModified.wHour]
     mov [TempHour], eax
     movzx eax, word [stModified.wMinute]
     mov [TempMinute], eax
     movzx eax, word [stModified.wSecond]
     mov [TempSecond], eax

     invoke wsprintfW, timeText, sTimeFormat, [TempDay], [TempMonth], [TempYear], [TempHour], [TempMinute], [TempSecond]

     mov rcx, sLabelModified
     mov rdx, timeText
     call AddBoxLabelText

     ; Accessed
     movzx eax, word [stAccessed.wDay]
     mov [TempDay], eax
     movzx eax, word [stAccessed.wMonth]
     mov [TempMonth], eax
     movzx eax, word [stAccessed.wYear]
     mov [TempYear], eax
     movzx eax, word [stAccessed.wHour]
     mov [TempHour], eax
     movzx eax, word [stAccessed.wMinute]
     mov [TempMinute], eax
     movzx eax, word [stAccessed.wSecond]
     mov [TempSecond], eax

     invoke wsprintfW, timeText, sTimeFormat, [TempDay], [TempMonth], [TempYear], [TempHour], [TempMinute], [TempSecond]

     mov rcx, sLabelAccessed
     mov rdx, timeText
     call AddBoxLabelText
     jmp .finish_report

.times_unavailable:
     mov rcx, sTimesUnavailable
     call AddBoxText

.finish_report:
     ; └────────────┘
     mov ecx, BOX_BOTTOM_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_BOTTOM_RIGHT
     call AddFrameLine

     ; =====================================================
     ; Second box: PE INFORMATION
     ; =====================================================
     ; One intentionally empty ListBox item gives the two logical report
     ; boxes a clean visual gap while preserving the same tight row height.
     invoke SendMessageW, [hListBox], LB_ADDSTRING, 0, sEmpty

     mov ecx, BOX_TOP_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_TOP_RIGHT
     call AddFrameLine

     mov rcx, sPeInformationTitle
     call AddBoxText

     mov ecx, BOX_MIDDLE_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_MIDDLE_RIGHT
     call AddFrameLine

     ; DOS header result. PeDosValid is set only after seeing the real
     ; little-endian MZ signature at offset zero.
     cmp [PeDosValid], 0
     je .pe_bad_mz

     mov rcx, sLabelDosHeader
     mov rdx, sValidMZ
     call AddBoxLabelText
     jmp .pe_header_line

.pe_bad_mz:
     mov rcx, sLabelDosHeader
     mov rdx, sInvalidMZ
     call AddBoxLabelText

.pe_header_line:
     cmp [PeHeaderValid], 0
     je .pe_invalid_header

     mov rcx, sLabelPeHeader
     mov rdx, sValidPE
     call AddBoxLabelText
     jmp .pe_architecture

.pe_invalid_header:
     mov rcx, sLabelPeHeader
     mov rdx, sInvalidPE
     call AddBoxLabelText

     ; Without a valid PE header, the remaining fields are not meaningful.
     mov rcx, sLabelArchitecture
     mov rdx, sUnavailable
     call AddBoxLabelText

     mov rcx, sLabelType
     mov rdx, sUnavailable
     call AddBoxLabelText

     mov rcx, sLabelSections
     mov rdx, sUnavailable
     call AddBoxLabelText
     jmp .pe_box_bottom

.pe_architecture:
     ; OptionalHeader.Magic tells us PE32 versus PE32+. Machine refines the
     ; CPU name. Unknown combinations are reported instead of guessed.
     movzx eax, word [PeOptionalMagic]
     cmp eax, PE_MAGIC_64
     je .pe_is_64
     cmp eax, PE_MAGIC_32
     je .pe_is_32

     mov rdx, sArchitectureUnknown
     jmp .pe_arch_ready

.pe_is_64:
     movzx eax, word [PeMachine]
     cmp eax, PE_MACHINE_AMD64
     je .pe_amd64
     cmp eax, PE_MACHINE_ARM64
     je .pe_arm64

     mov rdx, sArchitecturePE64Unknown
     jmp .pe_arch_ready

.pe_amd64:
     mov rdx, sArchitectureAMD64
     jmp .pe_arch_ready

.pe_arm64:
     mov rdx, sArchitectureARM64
     jmp .pe_arch_ready

.pe_is_32:
     movzx eax, word [PeMachine]
     cmp eax, PE_MACHINE_I386
     je .pe_i386
     cmp eax, PE_MACHINE_ARM
     je .pe_arm32

     mov rdx, sArchitecturePE32Unknown
     jmp .pe_arch_ready

.pe_i386:
     mov rdx, sArchitectureI386
     jmp .pe_arch_ready

.pe_arm32:
     mov rdx, sArchitectureARM32

.pe_arch_ready:
     mov rcx, sLabelArchitecture
     call AddBoxLabelText

     ; IMAGE_FILE_DLL distinguishes DLL images from ordinary executable
     ; images for this first PE report.
     movzx eax, word [PeCharacteristics]
     test eax, PE_CHARACTERISTIC_DLL
     jnz .pe_type_dll

     mov rdx, sTypeExecutable
     jmp .pe_type_ready

.pe_type_dll:
     mov rdx, sTypeDLL

.pe_type_ready:
     mov rcx, sLabelType
     call AddBoxLabelText

     movzx eax, word [PeSectionCount]
     mov [TempNumber], eax
     invoke wsprintfW, numberText, sUnsignedFormat, [TempNumber]

     mov rcx, sLabelSections
     mov rdx, numberText
     call AddBoxLabelText

.pe_box_bottom:
     mov ecx, BOX_BOTTOM_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_BOTTOM_RIGHT
     call AddFrameLine

     ; LBS_NOSEL means there is no current row selection to clear.
     invoke SendMessageW, [hListBox], LB_SETTOPINDEX, 0, 0

     ; LB_ADDSTRING copied every row into USER32's own storage. The dynamic
     ; builders are no longer needed after the report has been assembled.
     call FreeReportScratch
     ret

.file_info_failed:
     invoke GetLastError
     mov [LastFileError], eax
     invoke CloseHandle, rbx
     jmp .show_file_error

.open_failed:
     invoke GetLastError
     mov [LastFileError], eax

.show_file_error:
     invoke wsprintfW, numberText, sWindowsErrorFormat, [LastFileError]

     mov dword [CurrentBoxInnerChars], BOX_MIN_INNER_CHARS
     call AllocateReportScratch
     test eax, eax
     jz .report_memory_failed

     invoke SendMessageW, [hListBox], LB_RESETCONTENT, 0, 0
     call UpdateListHorizontalExtent

     mov ecx, BOX_TOP_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_TOP_RIGHT
     call AddFrameLine

     mov rcx, sErrorTitle
     call AddBoxText

     mov ecx, BOX_MIDDLE_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_MIDDLE_RIGHT
     call AddFrameLine

     mov rcx, sFileOpenError
     call AddBoxText

     mov rcx, sLabelWindowsError
     mov rdx, numberText
     call AddBoxLabelText

     mov ecx, BOX_BOTTOM_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_BOTTOM_RIGHT
     call AddFrameLine


     call FreeReportScratch
     ret

.report_memory_failed:
     invoke MessageBoxW, [MainWindow], sMemoryError, _title, MB_ICONERROR + MB_OK
     ret
endp


; =========================================================
; ParsePeInformation
;
; RCX = open read-only file HANDLE
;
; 1.7 deliberately reads only the minimum PE/COFF fields needed for the
; second ListBox box. The mapped file is treated as untrusted input:
;
;   1) physical file must contain a complete DOS header prefix
;   2) offset zero must contain MZ
;   3) e_lfanew must stay inside the physical file
;   4) the PE signature + COFF header + OptionalHeader.Magic must fit
;   5) only then are Machine / Sections / Characteristics / Magic read
;
; A non-PE file is NOT an application error. The parser simply leaves the
; corresponding validity flags clear and the report says Invalid / N/A.
; =========================================================

proc ParsePeInformation uses rbx rsi rdi r12 r13, hFile

     mov [hFile], rcx

     ; IMAGE_DOS_HEADER.e_lfanew lives at 3Ch and is a DWORD ending at 40h.
     cmp qword [FileSize], 40h
     jb .done

     invoke CreateFileMappingW, [hFile], 0, PAGE_READONLY_LOCAL, 0, 0, 0
     test rax, rax
     jz .done

     mov r12, rax                    ; mapping HANDLE

     invoke MapViewOfFile, r12, FILE_MAP_READ_LOCAL, 0, 0, 0
     test rax, rax
     jz .close_mapping

     mov r13, rax                    ; mapped base address

     ; DOS e_magic == WORD 'MZ'. FASM emits the same little-endian WORD
     ; representation that exists in a PE file on x86/x64 Windows.
     cmp word [r13], 'MZ'
     jne .unmap

     mov [PeDosValid], 1

     ; Read e_lfanew only after proving the first 40h bytes exist.
     mov eax, [r13 + PE_DOS_E_LFANEW]

     ; A PE signature cannot sensibly overlap the 40h-byte DOS header.
     cmp eax, 40h
     jb .unmap

     ; We are about to read through OptionalHeader.Magic, which lies 1Ah
     ; bytes from the PE signature. Check using subtraction so a malicious
     ; e_lfanew cannot overflow pointer arithmetic.
     mov rsi, [FileSize]
     cmp rsi, PE_MIN_BYTES_FOR_MAGIC
     jb .unmap

     sub rsi, PE_MIN_BYTES_FOR_MAGIC
     cmp rax, rsi
     ja .unmap

     lea rdi, [r13 + rax]            ; RDI = address of PE\0\0 signature

     cmp dword [rdi], PE_SIGNATURE
     jne .unmap

     mov [PeHeaderValid], 1

     mov ax, [rdi + PE_FILE_MACHINE]
     mov [PeMachine], ax

     mov ax, [rdi + PE_FILE_SECTIONS]
     mov [PeSectionCount], ax

     ; SizeOfOptionalHeader should contain at least the Magic WORD before
     ; we interpret that optional-header field.
     movzx eax, word [rdi + PE_FILE_SIZE_OPTIONAL]
     cmp eax, 2
     jb .characteristics_only

     mov ax, [rdi + PE_OPTIONAL_MAGIC]
     mov [PeOptionalMagic], ax

.characteristics_only:
     mov ax, [rdi + PE_FILE_CHARACTERISTICS]
     mov [PeCharacteristics], ax

.unmap:
     invoke UnmapViewOfFile, r13

.close_mapping:
     invoke CloseHandle, r12

.done:
     ret
endp


; =========================================================
; ShowSimpleErrorReport
;
; RCX = pointer to one short Unicode error sentence.
; =========================================================

proc ShowSimpleErrorReport uses rbx rsi rdi, messagePointer

     mov [messagePointer], rcx

     mov dword [CurrentBoxInnerChars], BOX_MIN_INNER_CHARS
     call AllocateReportScratch
     test eax, eax
     jz .memory_failed

     invoke SendMessageW, [hListBox], LB_RESETCONTENT, 0, 0
     call UpdateListHorizontalExtent

     mov ecx, BOX_TOP_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_TOP_RIGHT
     call AddFrameLine

     mov rcx, sErrorTitle
     call AddBoxText

     mov ecx, BOX_MIDDLE_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_MIDDLE_RIGHT
     call AddFrameLine

     mov rcx, [messagePointer]
     call AddBoxText

     mov ecx, BOX_BOTTOM_LEFT
     mov edx, BOX_HORIZONTAL
     mov r8d, BOX_BOTTOM_RIGHT
     call AddFrameLine

     call FreeReportScratch
     ret

.memory_failed:
     invoke MessageBoxW, [MainWindow], sMemoryError, _title, MB_ICONERROR + MB_OK
     ret
endp


; =========================================================
; FormatFileSizeText
;
; RCX = unsigned 64-bit file size
;
; Produces a zero-terminated Unicode string in numberText:
;
;   123456 bytes
;
; Why not wsprintfW "%I64u"?
; wsprintfW is an old USER32 formatter with a restricted conversion set.
; A tiny integer-to-decimal routine is clearer and keeps this example
; independent from CRT formatting functions.
; =========================================================

proc FormatFileSizeText uses rbx rsi rdi

     mov rbx, rcx
     lea rdi, [decimalReverse]
     xor esi, esi                    ; digit count

     test rbx, rbx
     jnz .convert

     mov word [numberText], '0'
     lea rax, [numberText + 2]
     jmp .append_suffix

.convert:
     ; Generate decimal digits least-significant first.
.next_digit:
     mov rax, rbx
     xor edx, edx
     mov ecx, 10
     div rcx                         ; RAX = quotient, RDX = remainder

     add dx, '0'
     mov [rdi + rsi*2], dx
     inc esi

     mov rbx, rax
     test rbx, rbx
     jnz .next_digit

     ; Reverse the temporary digits into numberText.
     lea rdi, [numberText]
     dec esi

.copy_digit:
     mov ax, [decimalReverse + rsi*2]
     mov [rdi], ax
     add rdi, 2

     test esi, esi
     jz .digits_done
     dec esi
     jmp .copy_digit

.digits_done:
     mov rax, rdi

.append_suffix:
     ; RAX points at the first WCHAR after the decimal digits.
     mov word [rax + 0],  ' '
     mov word [rax + 2],  'b'
     mov word [rax + 4],  'y'
     mov word [rax + 6],  't'
     mov word [rax + 8],  'e'
     mov word [rax + 10], 's'
     mov word [rax + 12], 0
     ret
endp


; =========================================================
; UnicodeLengthChars
;
; RCX = zero-terminated Unicode string
; Returns RAX = WCHAR count, excluding the terminating NUL.
; =========================================================

proc UnicodeLengthChars uses rsi, textPointer

     mov [textPointer], rcx
     mov rsi, rcx
     xor eax, eax

.next_char:
     cmp word [rsi + rax*2], 0
     je .done

     inc rax
     jmp .next_char

.done:
     ret
endp


; =========================================================
; AllocateReportScratch / FreeReportScratch
;
; The dynamic report can be slightly wider than MAX_PATH after adding
; " File: " and the two box sides. Allocate two equally sized Unicode
; working lines in ONE heap block and free them as soon as LB_ADDSTRING
; has copied the report into USER32's own ListBox storage.
; =========================================================

proc AllocateReportScratch uses rbx rsi rdi

     ; Defensive cleanup in case a future edit calls this twice.
     cmp [pReportScratch], 0
     je .calculate
     call FreeReportScratch

.calculate:
     mov eax, [CurrentBoxInnerChars]
     add eax, 3                     ; left side + right side + terminating NUL
     shl eax, 1                     ; WCHARs -> bytes for ONE line
     mov ebx, eax

     ; Two same-capacity lines: pBoxLine and pContentLine.
     shl rax, 1
     invoke HeapAlloc, [hProcessHeap], 0, rax
     test rax, rax
     jz .failed

     mov [pReportScratch], rax
     mov [pBoxLine], rax

     add rax, rbx
     mov [pContentLine], rax

     mov eax, TRUE
     ret

.failed:
     xor eax, eax
     ret
endp


proc FreeReportScratch uses rbx rsi rdi

     cmp [pReportScratch], 0
     je .done

     invoke HeapFree, [hProcessHeap], 0, [pReportScratch]

     mov qword [pReportScratch], 0
     mov qword [pBoxLine], 0
     mov qword [pContentLine], 0

.done:
     ret
endp


; =========================================================
; UpdateListHorizontalExtent
;
; The ListBox's scroll width is measured in PIXELS, not characters.
; Because Consolas is monospace, measure one character cell in the actual
; DPI-scaled ListBox font, multiply by the complete box width, then tell
; USER32 the scrollable width with LB_SETHORIZONTALEXTENT.
;
; If the ListBox is already wider than this extent, USER32 hides the
; horizontal scrollbar automatically. If the box is wider, it appears.
; =========================================================

proc UpdateListHorizontalExtent uses rbx rsi rdi

     cmp [hListBox], 0
     je .done

     cmp [hListFont], 0
     je .done

     cmp [CurrentBoxInnerChars], 0
     jne .measure

     invoke SendMessageW, [hListBox], LB_SETHORIZONTALEXTENT_LOCAL, 0, 0
     jmp .done

.measure:
     invoke GetDC, [hListBox]
     test rax, rax
     jz .done

     mov rbx, rax                   ; ListBox HDC

     invoke SelectObject, rbx, [hListFont]
     mov rsi, rax                   ; previous HFONT

     invoke GetTextExtentPoint32W, rbx, sMeasureCell, 1, CharExtent
     test eax, eax
     jz .restore

     mov eax, [CurrentBoxInnerChars]
     add eax, 2                     ; the two vertical/border cells
     imul eax, [CharExtent]         ; width of one Consolas cell
     mov edi, eax

     ; WM_DRAWITEM also applies this many pixels of left/right text padding.
     mov eax, [ScaledListTextPad]
     shl eax, 1
     add edi, eax
     add edi, 4                     ; small clipping breathing room

     invoke SendMessageW, [hListBox], LB_SETHORIZONTALEXTENT_LOCAL, rdi, 0

.restore:
     invoke SelectObject, rbx, rsi
     invoke ReleaseDC, [hListBox], rbx

.done:
     ret
endp


; =========================================================
; AddFrameLine
;
; RCX = left Unicode character
; RDX = repeated fill Unicode character
; R8  = right Unicode character
;
; The line buffer is sized dynamically for CurrentBoxInnerChars.
; LB_ADDSTRING copies the completed string into the ListBox immediately.
; =========================================================

proc AddFrameLine uses rbx rsi rdi, leftChar, fillChar, rightChar

     mov [leftChar], rcx
     mov [fillChar], rdx
     mov [rightChar], r8

     cld
     mov rdi, [pBoxLine]

     mov ax, word [leftChar]
     stosw

     mov ax, word [fillChar]
     mov ecx, [CurrentBoxInnerChars]
     rep stosw

     mov ax, word [rightChar]
     stosw

     xor eax, eax
     stosw

     invoke SendMessageW, [hListBox], LB_ADDSTRING, 0, [pBoxLine]
     ret
endp


; =========================================================
; AddBoxText
;
; RCX = Unicode content string
;
; Produces one dynamically padded row:
;
;   │content.................................................│
; =========================================================

proc AddBoxText uses rbx rsi rdi, textPointer

     mov [textPointer], rcx
     cld

     ; Start with: │ + CurrentBoxInnerChars spaces + │ + NUL
     mov rdi, [pBoxLine]

     mov ax, BOX_VERTICAL
     stosw

     mov ax, 0020h
     mov ecx, [CurrentBoxInnerChars]
     rep stosw

     mov ax, BOX_VERTICAL
     stosw

     xor eax, eax
     stosw

     ; Overlay the supplied content onto the padded interior.
     mov rsi, [textPointer]
     mov rdi, [pBoxLine]
     add rdi, 2
     mov ecx, [CurrentBoxInnerChars]

.copy_text:
     lodsw
     test ax, ax
     jz .add_line

     stosw
     loop .copy_text

.add_line:
     invoke SendMessageW, [hListBox], LB_ADDSTRING, 0, [pBoxLine]
     ret
endp


; =========================================================
; AddBoxLabelText
;
; RCX = Unicode label
; RDX = Unicode value
;
; Concatenates label + value into the current dynamically sized working
; line, then lets AddBoxText add/pad the vertical box sides.
; =========================================================

proc AddBoxLabelText uses rbx rsi rdi, labelPointer, valuePointer

     mov [labelPointer], rcx
     mov [valuePointer], rdx

     cld
     mov rdi, [pContentLine]
     mov ebx, [CurrentBoxInnerChars]

     mov rsi, [labelPointer]

.copy_label:
     test ebx, ebx
     jz .terminate

     lodsw
     test ax, ax
     jz .copy_value_start

     stosw
     dec ebx
     jmp .copy_label

.copy_value_start:
     mov rsi, [valuePointer]

.copy_value:
     test ebx, ebx
     jz .terminate

     lodsw
     test ax, ax
     jz .terminate

     stosw
     dec ebx
     jmp .copy_value

.terminate:
     xor eax, eax
     stosw

     mov rcx, [pContentLine]
     call AddBoxText
     ret
endp


; =========================================================
; UpdateListBoxFont
; =========================================================

proc UpdateListBoxFont uses rbx rsi rdi

     cmp [hListBox], 0
     je .done

     invoke CreateFontW, [ScaledListFontHeight], 0, 0, 0, FW_NORMAL,\
            FALSE, FALSE, FALSE,\
            DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,\
            DEFAULT_QUALITY, DEFAULT_PITCH + FF_DONTCARE, _listFontName

     test rax, rax
     jz .done

     mov rbx, rax
     mov rsi, [hListFont]

     mov [hListFont], rbx
     invoke SendMessageW, [hListBox], WM_SETFONT, rbx, TRUE

     test rsi, rsi
     jz .done

     invoke DeleteObject, rsi

.done:
     ret
endp


; =========================================================
; Paint common borderless dark window shell
; =========================================================

proc PaintWindow

     mov [hwnd], rcx

     invoke BeginPaint, [hwnd], ps
     mov [hdc], rax

     invoke GetClientRect, [hwnd], rect
     invoke FillRect, [hdc], rect, [wc.hbrBackground]

     ; Custom title strip.
     mov dword [rect.left], 0
     mov dword [rect.top], 0

     mov eax, [ScaledTitleHeight]
     mov [rect.bottom], eax

     invoke CreateSolidBrush, 00262626h
     mov [brush], rax
     invoke FillRect, [hdc], rect, [brush]
     invoke DeleteObject, [brush]

     ; Close-button background.
     mov eax, [rect.right]
     sub eax, [ScaledCloseBtnSize]
     mov [CloseBtnX], eax

     mov [rect.left], eax
     add eax, [ScaledCloseBtnSize]
     mov [rect.right], eax

     mov dword [rect.top], 0
     mov eax, [ScaledCloseBtnSize]
     mov [rect.bottom], eax

     invoke CreateSolidBrush, 00262626h
     mov [brush], rax
     invoke FillRect, [hdc], rect, [brush]
     invoke DeleteObject, [brush]

     invoke SetBkMode, [hdc], TRANSPARENT
     invoke SetTextColor, [hdc], 00FFFFFFh

     invoke DrawTextW, [hdc], _closeX, -1, rect,\
            DT_CENTER + DT_VCENTER + DT_SINGLELINE

     ; Window title in the remaining custom title-bar area.
     mov eax, [ScaledMargin]
     mov [rect.left], eax
     mov dword [rect.top], 0

     mov eax, [CloseBtnX]
     sub eax, [ScaledMargin]
     mov [rect.right], eax

     mov eax, [ScaledTitleHeight]
     mov [rect.bottom], eax

     invoke SetTextColor, [hdc], 00D0D0D0h
     invoke DrawTextW, [hdc], _title, -1, rect,\
            DT_LEFT + DT_VCENTER + DT_SINGLELINE + DT_END_ELLIPSIS

     invoke EndPaint, [hwnd], ps
     ret
endp


; =========================================================
; Custom close button / title drag
; =========================================================

proc HandleMouseClick

     mov [hwnd], rcx
     mov [lparam], rdx

     mov eax, dword [lparam]

     movsx ecx, ax
     mov [MouseX], ecx

     shr eax, 16
     movsx ecx, ax
     mov [MouseY], ecx

     ; Close button.
     mov eax, [CloseBtnX]
     cmp [MouseX], eax
     jl .no_close

     add eax, [ScaledCloseBtnSize]
     cmp [MouseX], eax
     jg .no_close

     cmp [MouseY], 0
     jl .no_close

     mov eax, [ScaledCloseBtnSize]
     cmp [MouseY], eax
     jg .no_close

     invoke PostMessageW, [hwnd], WM_CLOSE, 0, 0
     ret

.no_close:
     ; Click in custom title strip -> ask Windows to perform normal caption drag.
     mov eax, [ScaledTitleHeight]
     cmp [MouseY], eax
     jg .done

     invoke ReleaseCapture
     invoke SendMessageW, [hwnd], WM_NCLBUTTONDOWN, HTCAPTION, 0

.done:
     ret
endp


; =========================================================
; LayoutControls
; =========================================================

proc LayoutControls uses rbx rsi rdi, hwnd

     mov [hwnd], rcx

     cmp [hListBox], 0
     je .done

     invoke GetClientRect, [hwnd], rect

     ; width = client width - left/right margins
     mov esi, [rect.right]
     mov eax, [ScaledMargin]
     shl eax, 1
     sub esi, eax

     ; height = client height - titlebar - top/bottom margins
     mov ebx, [rect.bottom]
     sub ebx, [ScaledTitleHeight]

     mov eax, [ScaledMargin]
     shl eax, 1
     sub ebx, eax

     ; y = title bar + margin
     mov edi, [ScaledTitleHeight]
     add edi, [ScaledMargin]

     invoke MoveWindow, [hListBox],\
            [ScaledMargin], edi, esi, ebx, TRUE

.done:
     ret
endp


section '.data' data readable writeable

  _title          du 'ListBox 1.7 - EOF File Report - Dynamic Box Width',0
  _class          du 'FASMWIN64LISTBOXEOF',0
  _error          du 'Startup failed.',0
  _closeX         du 'X',0

  ; A monospace font is deliberate here: the ListBox is displaying a
  ; character-cell report whose Unicode box sides should line up vertically.
  _listFontName   du 'Consolas',0

  _listBoxClass   du 'LISTBOX',0

  ; -------------------------------------------------------
  ; Report text
  ; -------------------------------------------------------

  sFileInformationTitle  du ' FILE INFORMATION',0
  sPeInformationTitle    du ' PE INFORMATION',0
  sErrorTitle            du ' ERROR',0

  sLabelFile             du ' File: ',0
  sLabelSize             du ' Size: ',0
  sLabelCreated          du ' Created:  ',0
  sLabelModified         du ' Modified: ',0
  sLabelAccessed         du ' Accessed: ',0
  sLabelWindowsError     du ' Windows error: ',0

  ; Second-box PE report labels/results.
  sLabelDosHeader        du ' DOS Header:     ',0
  sLabelPeHeader         du ' PE Header:      ',0
  sLabelArchitecture     du ' Architecture:   ',0
  sLabelType             du ' Type:           ',0
  sLabelSections         du ' Sections:       ',0

  sValidMZ               du 'Valid MZ',0
  sInvalidMZ             du 'Invalid',0
  sValidPE               du 'Valid PE',0
  sInvalidPE             du 'Invalid',0
  sUnavailable           du 'N/A',0

  sArchitectureAMD64     du 'PE64 / AMD64',0
  sArchitectureARM64     du 'PE64 / ARM64',0
  sArchitecturePE64Unknown du 'PE64 / Unknown CPU',0
  sArchitectureI386      du 'PE32 / I386',0
  sArchitectureARM32     du 'PE32 / ARM',0
  sArchitecturePE32Unknown du 'PE32 / Unknown CPU',0
  sArchitectureUnknown   du 'Unknown PE magic',0

  sTypeExecutable        du 'Executable',0
  sTypeDLL               du 'DLL',0

  sOneFileOnly           du ' Please drop exactly ONE file.',0
  sDropReadError         du ' Could not read the dropped file name.',0
  sFileOpenError         du ' Could not read file information.',0
  sTimesUnavailable      du ' File timestamps could not be converted to local time.',0
  sMemoryError           du ' Could not allocate temporary report memory.',0

  sEmpty                 du 0
  sMeasureCell           du '0',0

  ; wsprintfW output formats. These buffers are small and bounded by the
  ; maximum textual representation of their numeric fields.
  sWindowsErrorFormat    du '%u',0
  sUnsignedFormat        du '%u',0
  sTimeFormat            du '%02u/%02u/%04u - %02u:%02u:%02u',0

  numberText             rw 32
  decimalReverse         rw 32
  timeText               rw 48

  ; MAX_PATH itself is explicitly allowed by the project rule. The wider
  ; report-line builders are heap allocations and therefore do not bloat .data.
  DroppedPath            rw MAX_PATH

  pReportScratch         dq 0
  pBoxLine               dq 0
  pContentLine           dq 0

  ; GetTextExtentPoint32W writes SIZE.cx / SIZE.cy as two LONGs. Keeping the
  ; pair explicitly avoids introducing another structure just for two DWORDs.
  CharExtent             dd 0
  CharExtentY            dd 0

  ; -------------------------------------------------------
  ; File information
  ; -------------------------------------------------------

  FileSize               dq 0
  LastFileError          dd 0
  FileTimesValid         dd 0
  TempDay                dd 0
  TempMonth              dd 0
  TempYear               dd 0
  TempHour               dd 0
  TempMinute             dd 0
  TempSecond             dd 0
  TempNumber             dd 0

  ; Small PE/COFF parser state. These are values copied out of the mapped
  ; file; the mapping itself exists only inside ParsePeInformation.
  PeDosValid             dd 0
  PeHeaderValid          dd 0
  PeMachine              dw 0
  PeOptionalMagic        dw 0
  PeCharacteristics      dw 0
  PeSectionCount         dw 0

  ; FILETIME and SYSTEMTIME already come from the FASM Windows includes.
  ; They are small fixed Win32 records, not large scratch buffers.
  ftCreated              FILETIME
  ftAccessed             FILETIME
  ftModified             FILETIME

  ftLocalCreated         FILETIME
  ftLocalAccessed        FILETIME
  ftLocalModified        FILETIME

  stCreated              SYSTEMTIME
  stAccessed             SYSTEMTIME
  stModified             SYSTEMTIME


; ---------------------------------------------------------
; Local Win64 owner-draw structures.
; ---------------------------------------------------------

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

  rect                RECT
  ownerDrawRect       RECT
  msg                 MSG
  ps                  PAINTSTRUCT
  pt                  POINT

  wc WNDCLASSEX sizeof.WNDCLASSEX, CS_HREDRAW + CS_VREDRAW, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE + 1, NULL, _class, NULL

  WinX            dd 0
  WinY            dd 0
  WinW            dd 900
  WinH            dd 470

  CloseBtnX       dd 0
  MouseX          dd 0
  MouseY          dd 0

  hwnd            dq 0
  lparam          dq 0
  hdc             dq 0
  brush           dq 0

  MainWindow      dq 0
  hListBox        dq 0
  hListFont       dq 0
  hListBrush      dq 0
  hProcessHeap    dq 0

  CurrentBoxInnerChars dd 0

  CurrentDpi           dd 96
  ScaledTitleHeight    dd TITLE_HEIGHT_96
  ScaledCloseBtnSize   dd CLOSE_BTN_SIZE_96
  ScaledBorderSize     dd BORDER_SIZE_96
  ScaledMargin         dd MARGIN_96
  ScaledListFontHeight dd LISTBOX_FONT_HEIGHT_96
  ScaledListItemHeight dd LISTBOX_ITEM_HEIGHT_96
  ScaledListTextPad    dd LISTBOX_TEXT_PAD_96


section '.idata' import data readable writeable

  library kernel32, 'KERNEL32.DLL',\
          user32,   'USER32.DLL',\
          gdi32,    'GDI32.DLL',\
          shell32,  'SHELL32.DLL'

  ; Keep the drag/drop imports explicit so the Unicode W function used by
  ; this lesson is unambiguous regardless of include aliases.
  import shell32,\
         DragAcceptFiles, 'DragAcceptFiles',\
         DragQueryFileW,  'DragQueryFileW',\
         DragFinish,      'DragFinish'

  include 'api\kernel32.inc'
  include 'api\user32.inc'
  include 'api\gdi32.inc'
