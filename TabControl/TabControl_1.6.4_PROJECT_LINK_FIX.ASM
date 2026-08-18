include 'win64Wx.inc'
entry main

WM_DPICHANGED	equ 02E0h
TAB_WM_EXITSIZEMOVE equ 0232h

; RedrawWindow flags used only after an interactive resize has finished.
; Keeping these local makes the lesson independent of which exact FASM
; Win32 include package/version is installed.
TAB_RDW_INVALIDATE   equ 0001h
TAB_RDW_ERASE	     equ 0004h
TAB_RDW_ALLCHILDREN  equ 0080h
TAB_RDW_UPDATENOW    equ 0100h

; =========================================================
; UI DESIGN VALUES - based on 96 DPI
; =========================================================

TITLE_HEIGHT_96       equ 30
CLOSE_BTN_SIZE_96     equ 32
BORDER_SIZE_96	      equ 8
MARGIN_96	      equ 10
TAB_FONT_HEIGHT_96     equ 20
TREE_FONT_HEIGHT_96    equ 20
PROCESS_FONT_HEIGHT_96 equ 20
HEADER_FONT_SIZE_96    equ 27

; Project-page layout values (96-DPI design pixels)
PROJECT_LINK_LEFT_96	equ 18
PROJECT_LINK_TOP_96	equ 105
PROJECT_LINK_GAP_96	equ 34
PROJECT_LINK_HEIGHT_96	equ 26

; SysLink is a ComCtl32 version-6 common control.
PROJECT_ICC_LINK_CLASS	equ 00008000h
PROJECT_LWS_TRANSPARENT equ 00000001h
PROJECT_NM_CLICK	equ -2
PROJECT_NM_RETURN	equ -4

; =========================================================
; Files-page TreeView: heap scratch / native constants
; =========================================================
; Keep the same rule as our standalone TreeView lesson: large temporary
; filesystem buffers are allocated only while needed, never reserved in
; the executable's .data section. Persistent node paths live on the heap
; and are stored in TVITEM.lParam.

TREE_FIND_DATA_BYTES  equ 250h
TREE_SEARCH_CHARS     equ 260 + 2
TREE_SCRATCH_BYTES    equ TREE_FIND_DATA_BYTES + TREE_SEARCH_CHARS * 2

TV_FIRST	      equ 1100h
TVM_INSERTITEMW       equ TV_FIRST + 50
TVM_EXPAND	      equ TV_FIRST + 2
TVM_SETIMAGELIST      equ TV_FIRST + 9
TVM_GETNEXTITEM       equ TV_FIRST + 10
TVM_SETBKCOLOR	      equ TV_FIRST + 29
TVM_SETTEXTCOLOR      equ TV_FIRST + 30
TVM_SETLINECOLOR      equ TV_FIRST + 40
TVM_GETITEMW	      equ TV_FIRST + 62
TVM_SETITEMW	      equ TV_FIRST + 63

TVIF_TEXT	      equ 0001h
TVIF_IMAGE	      equ 0002h
TVIF_PARAM	      equ 0004h
TVIF_SELECTEDIMAGE    equ 0020h
TVIF_CHILDREN	      equ 0040h

TVE_EXPAND	      equ 0002h
TVGN_CHILD	      equ 0004h
TVSIL_NORMAL	      equ 0

TVN_FIRST	      equ -400
TVN_ITEMEXPANDINGW    equ TVN_FIRST - 54

TREE_FILE_ATTRIBUTE_DIRECTORY equ 0010h
TREE_FILE_ATTRIBUTE_NORMAL    equ 0080h
TREE_FIND_INVALID_HANDLE_VALUE equ -1

SHGFI_SMALLICON 	 equ 00000001h
SHGFI_USEFILEATTRIBUTES  equ 00000010h
SHGFI_SYSICONINDEX	 equ 00004000h
SHFILEINFO_BYTES	 equ 02B8h

TVS_HASBUTTONS	      equ 0001h
TVS_HASLINES	      equ 0002h
TVS_LINESATROOT       equ 0004h
TVS_SHOWSELALWAYS     equ 0020h

TVI_ROOT_VALUE	      equ -10000h
TVI_LAST_VALUE	      equ -0FFFEh

; =========================================================
; Processes-page ListView: custom draw / popup / Toolhelp values
; =========================================================

CDRF_NOTIFYITEMDRAW   equ 00000020h
CDDS_ITEMPREPAINT     equ 00010001h
CDDS_PREPAINT	      equ 00000001h
CDRF_NEWFONT	      equ 00000002h
NM_RCLICK	      equ -5
NM_CUSTOMDRAW	      equ -12

IDM_PROCESS_END       equ 2001
IDM_PROCESS_REFRESH   equ 2002

POPUP_MF_OWNERDRAW    equ 00000100h
POPUP_MF_SEPARATOR    equ 00000800h
POPUP_TPM_RIGHTBUTTON equ 00000002h
POPUP_TPM_RETURNCMD   equ 00000100h
PROCESS_TERMINATE_ACCESS equ 00000001h

POPUP_ODT_MENU	      equ 1
POPUP_ODS_SELECTED    equ 00000001h
POPUP_MIM_BACKGROUND  equ 00000002h

POPUP_ITEM_WIDTH_96   equ 150
POPUP_ITEM_HEIGHT_96  equ 28
POPUP_TEXT_PAD_96     equ 12

HDM_FIRST	      equ 1200h
HDM_GETITEMCOUNT      equ HDM_FIRST + 0
HDM_GETITEMRECT       equ HDM_FIRST + 7
HDM_GETITEMW	      equ HDM_FIRST + 11
HDI_TEXT	      equ 0002h

define LVM_GETHEADER 101Fh
TOOLHELP_SNAP_PROCESS equ 00000002h

; =========================================================
; Native TabControl values used by this lesson
; =========================================================

TCS_OWNERDRAWFIXED    equ 00002000h

; Subclass the native TabControl so we can repaint the small pieces of
; chrome that TCS_OWNERDRAWFIXED does NOT delegate through WM_DRAWITEM.
GWL_WNDPROC	      equ -4

TCM_FIRST	      equ 1300h
TCM_GETITEMCOUNT      equ TCM_FIRST + 4
TCM_GETITEMRECT       equ TCM_FIRST + 10
TCM_GETCURSEL	      equ TCM_FIRST + 11
TCM_ADJUSTRECT	      equ TCM_FIRST + 40
TCM_GETITEMW	      equ TCM_FIRST + 60
TCM_INSERTITEMW       equ TCM_FIRST + 62

TCIF_TEXT	      equ 0001h

; TabControl selection notifications are sent to the PARENT with WM_NOTIFY.
TCN_FIRST	      equ -550
TCN_SELCHANGE	      equ TCN_FIRST - 1

; =========================================================
; Hit-test values used by our borderless top-level window
; =========================================================

HTCLIENT	      equ 1
HTCAPTION	      equ 2
HTLEFT		      equ 10
HTRIGHT 	      equ 11
HTTOP		       equ 12
HTTOPLEFT	       equ 13
HTTOPRIGHT	       equ 14
HTBOTTOM	       equ 15
HTBOTTOMLEFT	       equ 16
HTBOTTOMRIGHT	       equ 17

; DPI awareness
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 equ -4


main:
	sub rsp, 8

	; Per-Monitor V2 keeps our own pixel geometry correct when the
	; borderless window moves between monitors with different DPI.
	invoke SetProcessDpiAwarenessContext, DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2

	invoke GetModuleHandleW, 0
	mov [wc.hInstance], rax

	invoke LoadIconW, 0, IDI_APPLICATION
	mov [wc.hIcon], rax
	mov [wc.hIconSm], rax

	invoke LoadCursorW, 0, IDC_ARROW
	mov [wc.hCursor], rax

	invoke CreateSolidBrush, 001E1E1Eh
	mov [wc.hbrBackground], rax

	; Start centered on the primary screen, exactly like our previous
	; control examples. WM_DPICHANGED takes over after monitor changes.
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

	; -------------------------------------------------
	; Register the simple page-window class used inside
	; the TabControl display area.
	; -------------------------------------------------
	;
	; A TabControl does NOT create or own page windows.
	; It only manages the tab selector. The application
	; supplies whatever child window belongs below it.
	; -------------------------------------------------

	mov rax, [wc.hInstance]
	mov [pageWc.hInstance], rax

	mov rax, [wc.hCursor]
	mov [pageWc.hCursor], rax

	invoke RegisterClassExW, pageWc
	test rax, rax
	jz error

	invoke CreateWindowExW, 0, _class, _title,\
	       WS_POPUP,\
	       [WinX], [WinY], [WinW], [WinH],\
	       0, 0, [wc.hInstance], 0

	test rax, rax
	jz error

	mov [MainWindow], rax

	; -------------------------------------------------
	; Scale our 96-DPI design values for the starting monitor.
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

	invoke MulDiv, TAB_FONT_HEIGHT_96, [CurrentDpi], 96
	mov [ScaledTabFontHeight], eax

	invoke MulDiv, TREE_FONT_HEIGHT_96, [CurrentDpi], 96
	mov [ScaledTreeFontHeight], eax

	invoke MulDiv, PROCESS_FONT_HEIGHT_96, [CurrentDpi], 96
	mov [ScaledProcessFontHeight], eax

	invoke MulDiv, HEADER_FONT_SIZE_96, [CurrentDpi], 96
	mov [ScaledHeaderFontSize], eax

	; TabControl, ListView and TreeView all belong to the common-controls library.
	invoke InitCommonControls

	; SysLink is a version-6 common control. Microsoft requires
	; InitCommonControlsEx with PROJECT_ICC_LINK_CLASS before creating it.
	; The embedded manifest near the end of this source activates
	; ComCtl32 version 6 for this executable.
	mov [iccEx.dwSize], sizeof.INITCOMMONCONTROLSEX_LOCAL
	mov [iccEx.dwICC], PROJECT_ICC_LINK_CLASS
	invoke InitCommonControlsEx, iccEx
	test eax, eax
	jz error

	; Filesystem node paths and temporary enumeration blocks use the
	; process heap, matching the standalone TreeView lesson.
	invoke GetProcessHeap
	test rax, rax
	jz error
	mov [hProcessHeap], rax

	; SHGetFileInfoW is used only to borrow two system icon indexes.
	; If COM initialization fails, the TreeView remains functional and
	; simply falls back to text-only items.
	invoke CoInitialize, 0
	test eax, eax
	js .com_not_initialized
	mov [ComInitialized], 1

.com_not_initialized:

	; =================================================
	; Create the native Unicode TabControl
	; =================================================
	;
	; TCS_OWNERDRAWFIXED is the important style for this lesson.
	; It tells the control:
	;
	;   "Keep managing the tabs, hit testing, selection, keyboard
	;    behavior, etc. -- but ask my parent to PAINT each tab."
	;
	; The request arrives at the parent through WM_DRAWITEM.
	; =================================================

	mov eax, [ScaledTitleHeight]
	add eax, [ScaledMargin]

	invoke CreateWindowExW, 0, SysTabControl32Name, 0,\
	       WS_CHILD + WS_VISIBLE + WS_TABSTOP + WS_CLIPCHILDREN + TCS_OWNERDRAWFIXED,\
	       [ScaledMargin], eax, 500, 300,\
	       [MainWindow], 1001, [wc.hInstance], 0

	test rax, rax
	jz error

	mov [hTabControl], rax

	; -------------------------------------------------
	; Subclass the TabControl itself.
	; -------------------------------------------------
	;
	; TCS_OWNERDRAWFIXED only delegates each TAB ITEM through
	; WM_DRAWITEM. The control still paints the unused tab-row
	; background and the thin frame around its display area. On a
	; light system theme those pieces remain white. The subclass
	; lets the native control do its normal paint first, then covers
	; only those leftover chrome areas with our dark background.
	;
	; Selection, hit testing, keyboard navigation, item layout and
	; WM_DRAWITEM are still handled by the real SysTabControl32.
	; -------------------------------------------------

	invoke SetWindowLongPtrW, [hTabControl], GWL_WNDPROC, TabControlProc
	test rax, rax
	jz error
	mov [OldTabProc], rax

	; The control does not own an HFONT passed through WM_SETFONT.
	; We create one, install it, and delete it ourselves at shutdown.
	call UpdateTabFont

	; =================================================
	; Insert four real TabControl items
	; =================================================
	;
	; TCM_INSERTITEMW copies the Unicode label into the control's
	; internal item storage. The small TCITEMW structure only needs
	; TCIF_TEXT for this first lesson.
	; =================================================

	mov [tci.mask], TCIF_TEXT

	mov [tci.pszText], sTabOverview
	invoke SendMessageW, [hTabControl], TCM_INSERTITEMW, 0, tci

	mov [tci.pszText], sTabProcesses
	invoke SendMessageW, [hTabControl], TCM_INSERTITEMW, 1, tci

	mov [tci.pszText], sTabFiles
	invoke SendMessageW, [hTabControl], TCM_INSERTITEMW, 2, tci

	mov [tci.pszText], sTabProject
	invoke SendMessageW, [hTabControl], TCM_INSERTITEMW, 3, tci

	; =================================================
	; Create FOUR real page windows
	; =================================================
	;
	; A TabControl manages the selector, not the pages. Each page is
	; an ordinary child window created by our application. All four
	; occupy the SAME TCM_ADJUSTRECT display rectangle; we simply show
	; the selected one and hide the other three.
	; =================================================

	invoke CreateWindowExW, 0, _pageClass, 0,\
	       WS_CHILD,\
	       0, 0, 0, 0,\
	       [hTabControl], 2001, [wc.hInstance], 0

	test rax, rax
	jz error
	mov [hPageOverview], rax

	; Container pages that own real child controls use WS_CLIPCHILDREN.
	; This is correct container-window behavior: parent painting excludes
	; child rectangles. It is kept even though the separate nested
	; ListView/Header resize repaint quirk is still under investigation.
	invoke CreateWindowExW, 0, _pageClass, 0,\
	       WS_CHILD + WS_CLIPCHILDREN,\
	       0, 0, 0, 0,\
	       [hTabControl], 2002, [wc.hInstance], 0

	test rax, rax
	jz error
	mov [hPageProcesses], rax

	invoke CreateWindowExW, 0, _pageClass, 0,\
	       WS_CHILD + WS_CLIPCHILDREN,\
	       0, 0, 0, 0,\
	       [hTabControl], 2003, [wc.hInstance], 0

	test rax, rax
	jz error
	mov [hPageFiles], rax

	; ProjectPage owns transparent SysLink children. Unlike the ListView/
	; TreeView pages, we intentionally do NOT use WS_CLIPCHILDREN here:
	; LWS_TRANSPARENT lets the links blend with the page's dark surface.
	invoke CreateWindowExW, 0, _pageClass, 0,\
	       WS_CHILD,\
	       0, 0, 0, 0,\
	       [hTabControl], 2004, [wc.hInstance], 0

	test rax, rax
	jz error
	mov [hPageProject], rax

	; =================================================
	; Project page: native SysLink controls
	; =================================================
	;
	; We deliberately use one SysLink HWND per destination. That means
	; NM_CLICK / NM_RETURN can be routed by NMHDR.hwndFrom and this lesson
	; does not need the much larger NMLINK/LITEM URL structure at all.
	; The visible labels use SysLink <a href="..."> markup; ShellExecuteW
	; opens the same small persistent Unicode URLs stored below.
	; =================================================

	invoke CreateWindowExW, 0, SysLinkClassName, sLinkProfileMarkup,\
	       WS_CHILD + WS_VISIBLE + WS_TABSTOP + PROJECT_LWS_TRANSPARENT,\
	       0, 0, 0, 0,\
	       [hPageProject], 4001, [wc.hInstance], 0

	test rax, rax
	jz error
	mov [hLinkProfile], rax
	invoke SendMessageW, [hLinkProfile], WM_SETFONT, [hTabFont], TRUE

	invoke CreateWindowExW, 0, SysLinkClassName, sLinkRepositoriesMarkup,\
	       WS_CHILD + WS_VISIBLE + WS_TABSTOP + PROJECT_LWS_TRANSPARENT,\
	       0, 0, 0, 0,\
	       [hPageProject], 4002, [wc.hInstance], 0

	test rax, rax
	jz error
	mov [hLinkRepositories], rax
	invoke SendMessageW, [hLinkRepositories], WM_SETFONT, [hTabFont], TRUE

	; -------------------------------------------------
	; Dark SysLink background fix
	; -------------------------------------------------
	; LWS_TRANSPARENT makes the link TEXT background mix transparent,
	; but the SysLink child window can still erase its own client area
	; with the normal light system brush before drawing.  On our dark
	; Project page that shows up as a white rectangle behind each link.
	;
	; Keep the native SysLink for parsing, focus, hit testing, keyboard
	; navigation and NM_CLICK/NM_RETURN.  We subclass only WM_ERASEBKGND
	; so the child surface is erased with the same dark brush as its page.
	; The native SysLink WM_PAINT still draws the actual hyperlink.
	invoke SetWindowLongPtrW, [hLinkProfile], GWL_WNDPROC, DarkSysLinkProc
	test rax, rax
	jz .syslink_subclass_done

	mov [OldSysLinkProc], rax
	invoke SetWindowLongPtrW, [hLinkRepositories], GWL_WNDPROC, DarkSysLinkProc

.syslink_subclass_done:

	; =================================================
	; Embed our REAL process ListView in the Processes page
	; =================================================
	;
	; Architecture in 1.5:
	;
	;   MainWindow -> TabControl -> ProcessesPage -> ListView
	;
	; ListView WM_NOTIFY messages therefore go to ProcessesPage. The
	; temporary process popup menu remains owned by MainWindow, matching
	; the proven standalone ListView example, so its owner-draw menu
	; messages are handled by WindowProc.
	; =================================================

	invoke CreateWindowExW, 0, 'SysListView32', 0,\
	       WS_CHILD + WS_VISIBLE + WS_VSCROLL + LVS_REPORT + LVS_SINGLESEL,\
	       0, 0, 0, 0,\
	       [hPageProcesses], 3000, [wc.hInstance], 0

	test rax, rax
	jz error
	mov [hListView], rax

	invoke SendMessageW, [hListView], LVM_SETEXTENDEDLISTVIEWSTYLE,\
	       LVS_EX_FULLROWSELECT, LVS_EX_FULLROWSELECT

	; Give the process rows an explicit DPI-scaled font instead of
	; relying on whichever default font ComCtl32 happens to choose.
	; This keeps the integrated Processes page at the same comfortable
	; learning-example scale as our other finished controls.
	call UpdateProcessListFont

	invoke SendMessageW, [hListView], LVM_SETBKCOLOR, 0, 001E1E1Eh
	invoke SendMessageW, [hListView], LVM_SETTEXTBKCOLOR, 0, 001E1E1Eh
	invoke SetWindowTheme, [hListView], _DarkModeExplorer, 0

	invoke SendMessageW, [hListView], LVM_GETHEADER, 0, 0
	mov [hHeader], rax
	test rax, rax
	jz error

	call UpdateListViewHeaderFont

	invoke SetWindowLongPtrW, [hHeader], GWL_WNDPROC, RoundHeaderProc
	mov [OldHeaderProc], rax

	; Two real report columns. LayoutProcessesPage later keeps the same
	; original 260:230 proportion as the standalone process example.
	mov [lvc.mask], LVCF_WIDTH + LVCF_TEXT + LVCF_FMT
	mov [lvc.fmt], LVCFMT_CENTER
	mov [lvc.cx], 260
	mov [lvc.pszText], sProcess
	invoke SendMessageW, [hListView], LVM_INSERTCOLUMNW, 0, lvc

	mov [lvc.mask], LVCF_WIDTH + LVCF_TEXT + LVCF_FMT
	mov [lvc.fmt], LVCFMT_CENTER
	mov [lvc.cx], 230
	mov [lvc.pszText], sPID
	invoke SendMessageW, [hListView], LVM_INSERTCOLUMNW, 1, lvc

	mov rcx, [hListView]
	call PopulateProcessList

	; =================================================
	; Embed our REAL filesystem TreeView in the Files page
	; =================================================
	;
	; This remains the Files-page architecture from 1.4:
	;
	;   MainWindow -> TabControl -> FilesPage -> TreeView
	;
	; The TreeView therefore sends WM_NOTIFY to FilesPage, not directly
	; to MainWindow. PageProc handles TVN_ITEMEXPANDINGW and performs the
	; same lazy directory enumeration as the standalone TreeView example.
	; =================================================

	invoke CreateWindowExW, 0, SysTreeView32Name, 0,\
	       WS_CHILD + WS_VISIBLE + WS_TABSTOP + WS_VSCROLL +\
	       TVS_HASBUTTONS + TVS_HASLINES + TVS_LINESATROOT + TVS_SHOWSELALWAYS,\
	       0, 0, 0, 0,\
	       [hPageFiles], 3001, [wc.hInstance], 0

	test rax, rax
	jz error
	mov [hTreeView], rax

	call UpdateTreeViewFont
	call InitSystemIcons

	invoke SendMessageW, [hTreeView], TVM_SETBKCOLOR, 0, 001E1E1Eh
	invoke SendMessageW, [hTreeView], TVM_SETTEXTCOLOR, 0, 00E8E8E8h
	invoke SendMessageW, [hTreeView], TVM_SETLINECOLOR, 0, 00606060h
	invoke SetWindowTheme, [hTreeView], _DarkModeExplorer, 0

	mov rcx, [hTreeView]
	call PopulateTreeView

	mov rcx, [MainWindow]
	call LayoutControls

	; Tab 0 is selected by default. Synchronize visible page with the
	; TabControl instead of assuming that default in the page code.
	call ShowSelectedPage

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

proc WindowProc uses rbx rsi rdi, hwnd, wmsg, wparam, lparam

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
     cmp [wmsg], WM_NOTIFY
     je .wmnotify
     cmp [wmsg], WM_LBUTTONDOWN
     je .wmlbuttondown
     cmp [wmsg], WM_NCHITTEST
     je .wmnchittest
     cmp [wmsg], WM_SIZE
     je .wmsize
     cmp [wmsg], TAB_WM_EXITSIZEMOVE
     je .wmexitsizemove
     cmp [wmsg], WM_DPICHANGED
     je .wmdpichanged
     cmp [wmsg], WM_DESTROY
     je .wmdestroy

     invoke DefWindowProcW, [hwnd], [wmsg], [wparam], [lparam]
     jmp .finish


.wmnotify:

     ; =====================================================
     ; Tab selection changed
     ; =====================================================
     ;
     ; SysTabControl32 sends TCN_SELCHANGE to its PARENT through WM_NOTIFY
     ; after the new tab has become current. The control changes selection;
     ; our application changes which page window is visible.
     ; =====================================================

     mov rbx, [lparam]

     mov rax, [rbx + NMHDR64_LOCAL.hwndFrom]
     cmp rax, [hTabControl]
     jne .notify_not_ours

     mov eax, [rbx + NMHDR64_LOCAL.code]
     cmp eax, TCN_SELCHANGE
     jne .notify_not_ours

     call ShowSelectedPage

     xor eax, eax
     jmp .finish

.notify_not_ours:
     invoke DefWindowProcW, [hwnd], [wmsg], [wparam], [lparam]
     jmp .finish


.wmmeasureitem:

     ; Owner-drawn popup menu used by the process ListView. The menu itself
     ; is owned by MainWindow, so Windows sends WM_MEASUREITEM here even
     ; though the right-click originated inside ProcessesPage.
     mov rbx, [lparam]
     cmp dword [rbx + MEASUREITEMSTRUCT64_LOCAL.CtlType], POPUP_ODT_MENU
     jne .measure_not_ours

     mov eax, [rbx + MEASUREITEMSTRUCT64_LOCAL.itemID]
     cmp eax, IDM_PROCESS_END
     je .measure_process_menu
     cmp eax, IDM_PROCESS_REFRESH
     jne .measure_not_ours

.measure_process_menu:
     invoke MulDiv, POPUP_ITEM_WIDTH_96, [CurrentDpi], 96
     mov [rbx + MEASUREITEMSTRUCT64_LOCAL.itemWidth], eax

     invoke MulDiv, POPUP_ITEM_HEIGHT_96, [CurrentDpi], 96
     mov [rbx + MEASUREITEMSTRUCT64_LOCAL.itemHeight], eax

     mov eax, TRUE
     jmp .finish

.measure_not_ours:
     invoke DefWindowProcW, [hwnd], [wmsg], [wparam], [lparam]
     jmp .finish


.wmdrawitem:

     ; WM_DRAWITEM is now shared by two owner-draw lessons:
     ;	 1) process popup-menu rows (ODT_MENU)
     ;	 2) TabControl headers (TCS_OWNERDRAWFIXED)
     ; Always identify the sender/type before painting.
     mov rbx, [lparam]
     cmp dword [rbx + DRAWITEMSTRUCT64_LOCAL.CtlType], POPUP_ODT_MENU
     jne .draw_tab_item

     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.itemID]
     cmp eax, IDM_PROCESS_END
     je .draw_end_process
     cmp eax, IDM_PROCESS_REFRESH
     je .draw_refresh_processes
     jmp .draw_not_ours

.draw_end_process:
     mov rsi, sEndProcess
     jmp .draw_process_menu

.draw_refresh_processes:
     mov rsi, sRefreshList

.draw_process_menu:
     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemLeft]
     mov [menuRect.left], eax
     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemTop]
     mov [menuRect.top], eax
     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemRight]
     mov [menuRect.right], eax
     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemBottom]
     mov [menuRect.bottom], eax

     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.itemState]
     test eax, POPUP_ODS_SELECTED
     jnz .process_menu_selected

     invoke CreateSolidBrush, 002E2E2Eh
     jmp .have_process_menu_brush

.process_menu_selected:
     invoke CreateSolidBrush, 00424242h

.have_process_menu_brush:
     mov rdi, rax
     test rdi, rdi
     jz .process_menu_no_fill

     invoke FillRect, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], menuRect, rdi
     invoke DeleteObject, rdi

.process_menu_no_fill:
     invoke GetStockObject, DEFAULT_GUI_FONT
     invoke SelectObject, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], rax
     mov rdi, rax

     invoke SetBkMode, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], TRANSPARENT
     invoke SetTextColor, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], 00E8E8E8h

     invoke MulDiv, POPUP_TEXT_PAD_96, [CurrentDpi], 96
     add dword [menuRect.left], eax
     sub dword [menuRect.right], eax

     invoke DrawTextW, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], rsi, -1, menuRect,\
	    DT_LEFT + DT_VCENTER + DT_SINGLELINE

     invoke SelectObject, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], rdi

     mov eax, TRUE
     jmp .finish

.draw_tab_item:

     ; =====================================================
     ; Owner-drawn TabControl headers
     ; =====================================================
     ;
     ; lParam points to DRAWITEMSTRUCT. The TabControl still decides
     ; WHEN a tab must be painted and supplies the exact destination DC
     ; and rectangle. We only replace the visual rendering of that item.
     ; =====================================================

     mov rbx, [lparam]

     ; Do not accidentally claim WM_DRAWITEM from some future owner-drawn
     ; button/menu/control. hwndItem identifies the control that asked us.
     mov rax, [rbx + DRAWITEMSTRUCT64_LOCAL.hwndItem]
     cmp rax, [hTabControl]
     jne .draw_not_ours

     ; itemID is the zero-based TabControl item index.
     mov esi, [rbx + DRAWITEMSTRUCT64_LOCAL.itemID]

     ; Copy Windows' supplied rectangle into our own RECT because we may
     ; adjust it for text/selection decoration.
     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemLeft]
     mov [drawRect.left], eax

     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemTop]
     mov [drawRect.top], eax

     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemRight]
     mov [drawRect.right], eax

     mov eax, [rbx + DRAWITEMSTRUCT64_LOCAL.rcItemBottom]
     mov [drawRect.bottom], eax

     ; -----------------------------------------------------
     ; Determine selection from the TabControl itself.
     ; -----------------------------------------------------
     ;
     ; We deliberately use TCM_GETCURSEL instead of trusting a particular
     ; itemState flag. The TabControl remains the authority on which page
     ; is selected; our paint code merely mirrors that state.
     ; -----------------------------------------------------

     invoke SendMessageW, [hTabControl], TCM_GETCURSEL, 0, 0
     cmp eax, esi
     je .selected_tab

     ; Normal tab background.
     invoke CreateSolidBrush, 002E2E2Eh
     mov rdi, rax

     invoke SetTextColor, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], 00D0D0D0h
     jmp .fill_tab

.selected_tab:

     ; Selected tab uses only a slightly lighter dark surface.
     ; No colored accent is needed: the surface + brighter text are enough
     ; to communicate selection while staying consistent with the dark UI.
     invoke CreateSolidBrush, 00424242h
     mov rdi, rax

     invoke SetTextColor, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], 00F0F0F0h

.fill_tab:

     test rdi, rdi
     jz .after_fill

     invoke FillRect, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], drawRect, rdi
     invoke DeleteObject, rdi

     ; TCS_OWNERDRAWFIXED gives us the tab face, but the native control can
     ; still leave a bright one-pixel item outline around that rectangle.
     ; FrameRect redraws that outline INSIDE the supplied item rectangle in
     ; a restrained dark gray, keeping each tab separated without the light
     ; system-theme border standing out against the dark UI.
     invoke CreateSolidBrush, 00505050h
     test rax, rax
     jz .after_fill

     mov rdi, rax
     invoke FrameRect, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], drawRect, rdi
     invoke DeleteObject, rdi

.after_fill:

     ; -----------------------------------------------------
     ; Retrieve the tab's real Unicode label.
     ; -----------------------------------------------------
     ;
     ; The label belongs to the TabControl. TCM_GETITEMW copies it into
     ; our small 64-WCHAR working buffer for this synchronous paint call.
     ; -----------------------------------------------------

     mov [tci.mask], TCIF_TEXT
     mov [tci.pszText], tabTextBuffer
     mov [tci.cchTextMax], 64

     mov eax, esi
     invoke SendMessageW, [hTabControl], TCM_GETITEMW, rax, tci

     ; Paint with the same DPI-scaled HFONT installed on the control.
     invoke SelectObject, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], [hTabFont]
     mov rdi, rax

     invoke SetBkMode, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], TRANSPARENT

     invoke DrawTextW, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], tabTextBuffer, -1, drawRect,\
	    DT_CENTER + DT_VCENTER + DT_SINGLELINE + DT_END_ELLIPSIS

.restore_font:

     ; WM_DRAWITEM gives us a DC owned by the control. Restore anything
     ; we selected into it before returning.
     invoke SelectObject, [rbx + DRAWITEMSTRUCT64_LOCAL.hDC], rdi

     mov eax, TRUE
     jmp .finish

.draw_not_ours:

     invoke DefWindowProcW, [hwnd], [wmsg], [wparam], [lparam]
     jmp .finish


.wmnchittest:

     ; lParam contains SCREEN coordinates packed as signed 16-bit X/Y.
     movsx eax, word [lparam]
     movsx edx, word [lparam + 2]

     mov [pt.x], eax
     mov [pt.y], edx
     invoke ScreenToClient, [hwnd], pt

     invoke GetClientRect, [hwnd], rect

     mov eax, [pt.x]
     mov edx, [pt.y]

     ; Corners/sides first so the borderless window remains resizable.
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


.wmexitsizemove:

     ; =====================================================
     ; Deferred repaint after interactive move/resize
     ; =====================================================
     ;
     ; During a live border drag Windows can deliver many WM_SIZE messages.
     ; The Processes page contains a deeper custom-painted hierarchy:
     ;
     ;	 ProcessesPage -> ListView -> Header
     ;
     ; We therefore leave WM_SIZE focused on geometry and wait until Windows
     ; sends WM_EXITSIZEMOVE -- once, when the user releases the sizing border.
     ; If the Processes tab is currently selected, invalidate that complete
     ; branch and synchronously paint it once in its final geometry.
     ;
     ; RDW_ALLCHILDREN matters here because the Header is itself a child of
     ; the ListView. This is intentionally a post-resize repaint, not another
     ; repaint attempt inside every WM_SIZE notification.

     cmp [hTabControl], 0
     je .exit_size_done

     invoke SendMessageW, [hTabControl], TCM_GETCURSEL, 0, 0
     cmp eax, 1 			; Processes tab = item 1
     jne .exit_size_done

     cmp [hPageProcesses], 0
     je .exit_size_done

     invoke RedrawWindow, [hPageProcesses], NULL, NULL,\
	    TAB_RDW_INVALIDATE + TAB_RDW_ERASE + TAB_RDW_ALLCHILDREN + TAB_RDW_UPDATENOW

.exit_size_done:
     xor eax, eax
     jmp .finish


.wmdpichanged:

     ; LOWORD(wParam) contains the new X DPI.
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
     invoke MulDiv, TAB_FONT_HEIGHT_96, eax, 96
     mov [ScaledTabFontHeight], eax

     mov eax, [CurrentDpi]
     invoke MulDiv, TREE_FONT_HEIGHT_96, eax, 96
     mov [ScaledTreeFontHeight], eax

     mov eax, [CurrentDpi]
     invoke MulDiv, PROCESS_FONT_HEIGHT_96, eax, 96
     mov [ScaledProcessFontHeight], eax

     mov eax, [CurrentDpi]
     invoke MulDiv, HEADER_FONT_SIZE_96, eax, 96
     mov [ScaledHeaderFontSize], eax

     ; Recreate/install all application-created control fonts first.
     ; Set the ListView body font before its Header font because a ListView
     ; font change may also refresh Header metrics. The custom Header font
     ; is therefore installed last.
     call UpdateTabFont
     call UpdateTreeViewFont
     call UpdateProcessListFont
     call UpdateListViewHeaderFont

     ; Windows supplies the recommended top-level rectangle for the new DPI.
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

     ; Owner-drawn tabs must be asked to repaint using the new font/DPI.
     cmp [hTabControl], 0
     je .dpi_parent_only

     invoke InvalidateRect, [hTabControl], NULL, TRUE

.dpi_parent_only:

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

     ; The child control is destroyed automatically with its parent.
     ; HFONT ownership remains ours because we created it.
     cmp [hTabFont], 0
     je .no_tab_font

     invoke DeleteObject, [hTabFont]
     mov [hTabFont], 0

.no_tab_font:

     cmp [hTreeFont], 0
     je .no_tree_font

     invoke DeleteObject, [hTreeFont]
     mov [hTreeFont], 0

.no_tree_font:

     cmp [hProcessFont], 0
     je .no_process_font

     invoke DeleteObject, [hProcessFont]
     mov [hProcessFont], 0

.no_process_font:

     cmp [hHeaderFont], 0
     je .no_header_font

     invoke DeleteObject, [hHeaderFont]
     mov [hHeaderFont], 0

.no_header_font:

     cmp [ComInitialized], 0
     je .no_com_cleanup

     invoke CoUninitialize
     mov [ComInitialized], 0

.no_com_cleanup:

     cmp [wc.hbrBackground], 0
     je .no_background_brush

     invoke DeleteObject, [wc.hbrBackground]
     mov [wc.hbrBackground], 0

.no_background_brush:

     invoke PostQuitMessage, 0
     xor eax, eax

.finish:
     ret
endp


; =========================================================
; TabControlProc
;
; TCS_OWNERDRAWFIXED is deliberately NOT a full-control custom-draw
; mechanism. Microsoft documents it as owner drawing the individual
; tabs through WM_DRAWITEM. SysTabControl32 still paints the remaining
; control chrome itself.
;
; We keep the native TabControl and subclass only two paint messages:
;
;   WM_ERASEBKGND -> erase with our dark brush, not COLOR_BTNFACE.
;   WM_PAINT	  -> let SysTabControl32 paint normally first, then
;		     cover the small leftover light chrome regions.
;
; This preserves all native TabControl behavior while removing the
; white strip/frame that can be seen around owner-drawn tab items.
; =========================================================

proc TabControlProc uses rbx rsi rdi, hwnd, wmsg, wparam, lparam

     mov [hwnd], rcx
     mov [wmsg], rdx
     mov [wparam], r8
     mov [lparam], r9

     cmp [wmsg], WM_ERASEBKGND
     je .erase

     cmp [wmsg], WM_PAINT
     je .paint

.default:
     invoke CallWindowProcW, [OldTabProc], [hwnd], [wmsg], [wparam], [lparam]
     ret

.erase:
     ; WM_ERASEBKGND gives us the HDC in wParam. Reuse the persistent
     ; dark brush already owned by the main window class.
     invoke GetClientRect, [hwnd], tabChromeRect
     invoke FillRect, [wparam], tabChromeRect, [wc.hbrBackground]
     mov eax, 1
     ret

.paint:
     ; FIRST let the native TabControl paint. This is important because
     ; its normal WM_PAINT path sends our parent the WM_DRAWITEM calls
     ; for Overview / Processes / Files.
     invoke CallWindowProcW, [OldTabProc], [hwnd], [wmsg], [wparam], [lparam]
     mov rbx, rax

     ; THEN cover only the chrome that SysTabControl32 painted itself.
     call PaintTabChrome

     mov rax, rbx
     ret
endp


; =========================================================
; PaintTabChrome
;
; Paints the parts NOT represented by WM_DRAWITEM rectangles:
;
;   * the unused tab-row area to the right of the final tab,
;   * the thin outer frame around the display/page rectangle,
;   * the small top/bottom theme bands left around the tab row.
;
; TCM_ADJUSTRECT supplies the exact native display rectangle, so the
; frame geometry remains tied to Windows' own TabControl metrics.
; =========================================================

proc PaintTabChrome uses rbx rsi rdi r12

     cmp [hTabControl], 0
     je .done

     invoke GetDC, [hTabControl]
     test rax, rax
     jz .done

     mov rbx, rax		     ; RBX = TabControl HDC

     ; Full TabControl client rectangle.
     invoke GetClientRect, [hTabControl], tabChromeClient

     ; Convert that full rectangle into the native display/page area.
     mov eax, [tabChromeClient.left]
     mov [tabChromeDisplay.left], eax
     mov eax, [tabChromeClient.top]
     mov [tabChromeDisplay.top], eax
     mov eax, [tabChromeClient.right]
     mov [tabChromeDisplay.right], eax
     mov eax, [tabChromeClient.bottom]
     mov [tabChromeDisplay.bottom], eax

     invoke SendMessageW, [hTabControl], TCM_ADJUSTRECT, FALSE, tabChromeDisplay

     ; -----------------------------------------------------
     ; Darken the thin frame around the real page/display area.
     ; The page child itself already paints the large center dark.
     ; -----------------------------------------------------

     ; Left frame
     mov eax, [tabChromeClient.left]
     mov [tabChromeRect.left], eax
     mov eax, [tabChromeDisplay.top]
     mov [tabChromeRect.top], eax
     mov eax, [tabChromeDisplay.left]
     mov [tabChromeRect.right], eax
     mov eax, [tabChromeClient.bottom]
     mov [tabChromeRect.bottom], eax
     invoke FillRect, rbx, tabChromeRect, [wc.hbrBackground]

     ; Right frame
     mov eax, [tabChromeDisplay.right]
     mov [tabChromeRect.left], eax
     mov eax, [tabChromeDisplay.top]
     mov [tabChromeRect.top], eax
     mov eax, [tabChromeClient.right]
     mov [tabChromeRect.right], eax
     mov eax, [tabChromeClient.bottom]
     mov [tabChromeRect.bottom], eax
     invoke FillRect, rbx, tabChromeRect, [wc.hbrBackground]

     ; Bottom frame
     mov eax, [tabChromeDisplay.left]
     mov [tabChromeRect.left], eax
     mov eax, [tabChromeDisplay.bottom]
     mov [tabChromeRect.top], eax
     mov eax, [tabChromeDisplay.right]
     mov [tabChromeRect.right], eax
     mov eax, [tabChromeClient.bottom]
     mov [tabChromeRect.bottom], eax
     invoke FillRect, rbx, tabChromeRect, [wc.hbrBackground]

     ; -----------------------------------------------------
     ; Header-row background.
     ; -----------------------------------------------------

     invoke SendMessageW, [hTabControl], TCM_GETITEMCOUNT, 0, 0
     test eax, eax
     jle .no_items

     mov esi, eax
     dec esi			     ; ESI = final item index

     ; First and last item rectangles define the unused left/right
     ; portions of the single-row tab strip.
     invoke SendMessageW, [hTabControl], TCM_GETITEMRECT, 0, tabFirstRect
     invoke SendMessageW, [hTabControl], TCM_GETITEMRECT, rsi, tabLastRect

     ; Left of first tab
     mov eax, [tabChromeClient.left]
     mov [tabChromeRect.left], eax
     mov eax, [tabChromeClient.top]
     mov [tabChromeRect.top], eax
     mov eax, [tabFirstRect.left]
     mov [tabChromeRect.right], eax
     mov eax, [tabChromeDisplay.top]
     mov [tabChromeRect.bottom], eax
     invoke FillRect, rbx, tabChromeRect, [wc.hbrBackground]

     ; Right of final tab -- this is the large white strip visible in
     ; the screenshot.
     mov eax, [tabLastRect.right]
     mov [tabChromeRect.left], eax
     mov eax, [tabChromeClient.top]
     mov [tabChromeRect.top], eax
     mov eax, [tabChromeClient.right]
     mov [tabChromeRect.right], eax
     mov eax, [tabChromeDisplay.top]
     mov [tabChromeRect.bottom], eax
     invoke FillRect, rbx, tabChromeRect, [wc.hbrBackground]

     ; -----------------------------------------------------
     ; Remove the thin light theme bands at the very top of the row
     ; and immediately above the display area. Two 96-DPI pixels match
     ; the native border seen here and scale cleanly on another monitor.
     ; -----------------------------------------------------

     invoke MulDiv, 2, [CurrentDpi], 96
     mov r12d, eax
     test r12d, r12d
     jnz .band_size_ready
     mov r12d, 1

.band_size_ready:

     ; Top band: safe to paint across the complete row because it is
     ; only the native border thickness; tab text lies well below it.
     mov eax, [tabChromeClient.left]
     mov [tabChromeRect.left], eax
     mov eax, [tabChromeClient.top]
     mov [tabChromeRect.top], eax
     mov eax, [tabChromeClient.right]
     mov [tabChromeRect.right], eax
     mov eax, [tabChromeClient.top]
     add eax, r12d
     cmp eax, [tabChromeDisplay.top]
     jle .top_band_ok
     mov eax, [tabChromeDisplay.top]

.top_band_ok:
     mov [tabChromeRect.bottom], eax
     invoke FillRect, rbx, tabChromeRect, [wc.hbrBackground]

     ; Preserve the selected tab's slightly lighter surface all the way to
     ; the display area. Paint the native bottom theme band only to the LEFT
     ; and RIGHT of the selected item's rectangle.
     invoke SendMessageW, [hTabControl], TCM_GETCURSEL, 0, 0
     cmp eax, -1
     je .release_dc

     mov edi, eax
     invoke SendMessageW, [hTabControl], TCM_GETITEMRECT, rdi, tabSelectedRect

     mov eax, [tabChromeDisplay.top]
     sub eax, r12d
     cmp eax, [tabChromeClient.top]
     jge .bottom_band_top_ok
     mov eax, [tabChromeClient.top]

.bottom_band_top_ok:
     mov r12d, eax		     ; reuse R12D = band top Y

     ; Bottom band, left of selected tab
     mov eax, [tabChromeClient.left]
     mov [tabChromeRect.left], eax
     mov [tabChromeRect.top], r12d
     mov eax, [tabSelectedRect.left]
     mov [tabChromeRect.right], eax
     mov eax, [tabChromeDisplay.top]
     mov [tabChromeRect.bottom], eax
     invoke FillRect, rbx, tabChromeRect, [wc.hbrBackground]

     ; Bottom band, right of selected tab
     mov eax, [tabSelectedRect.right]
     mov [tabChromeRect.left], eax
     mov [tabChromeRect.top], r12d
     mov eax, [tabChromeClient.right]
     mov [tabChromeRect.right], eax
     mov eax, [tabChromeDisplay.top]
     mov [tabChromeRect.bottom], eax
     invoke FillRect, rbx, tabChromeRect, [wc.hbrBackground]
     jmp .release_dc

.no_items:
     ; With no tabs there is no item rectangle to preserve, so the
     ; complete header band can simply use the dark control background.
     mov eax, [tabChromeClient.left]
     mov [tabChromeRect.left], eax
     mov eax, [tabChromeClient.top]
     mov [tabChromeRect.top], eax
     mov eax, [tabChromeClient.right]
     mov [tabChromeRect.right], eax
     mov eax, [tabChromeDisplay.top]
     mov [tabChromeRect.bottom], eax
     invoke FillRect, rbx, tabChromeRect, [wc.hbrBackground]

.release_dc:
     invoke ReleaseDC, [hTabControl], rbx

.done:
     ret
endp


; =========================================================
; PageProc
;
; One window procedure serves all four page windows. ProcessesPage owns the
; ListView, FilesPage owns the TreeView, and ProjectPage owns two SysLinks.
; WM_NOTIFY therefore stops at those immediate parent page windows; MainWindow
; only manages the TabControl itself and the process popup menu.
; =========================================================

proc PageProc uses rbx rsi rdi, hwnd, wmsg, wparam, lparam

     mov [hwnd], rcx
     mov [wmsg], rdx
     mov [wparam], r8
     mov [lparam], r9

     cmp [wmsg], WM_NOTIFY
     je .notify

     cmp [wmsg], WM_SIZE
     je .size

     cmp [wmsg], WM_ERASEBKGND
     je .erase

     cmp [wmsg], WM_PAINT
     je .paint

     invoke DefWindowProcW, [hwnd], [wmsg], [wparam], [lparam]
     ret

.notify:
     mov rax, [hwnd]
     cmp rax, [hPageProcesses]
     je .process_notify

     cmp rax, [hPageFiles]
     je .files_notify

     cmp rax, [hPageProject]
     je .project_notify

     jmp .notify_default

.process_notify:
     ; -----------------------------------------------------
     ; The ListView is a child of ProcessesPage, so NM_RCLICK and
     ; NM_CUSTOMDRAW arrive at THIS page window, not MainWindow.
     ; -----------------------------------------------------
     mov rbx, [lparam]

     mov rax, [rbx + NMHDR64_LOCAL.hwndFrom]
     cmp rax, [hListView]
     jne .notify_default

     mov eax, [rbx + NMHDR64_LOCAL.code]
     cmp eax, NM_RCLICK
     je .process_right_click

     cmp eax, NM_CUSTOMDRAW
     jne .notify_done

     mov eax, [rbx + NMLVCUSTOMDRAW.dwDrawStage]
     cmp eax, CDDS_PREPAINT
     je .process_prepaint

     cmp eax, CDDS_ITEMPREPAINT
     je .process_itempaint

     jmp .notify_done

.process_right_click:
     mov eax, [rbx + NMITEMACTIVATE_MIN64.iItem]
     cmp eax, -1
     je .notify_done

     mov ecx, eax
     call ShowProcessContextMenu

     xor eax, eax
     ret

.process_prepaint:
     mov eax, CDRF_NOTIFYITEMDRAW
     ret

.process_itempaint:
     ; Preserve the standalone ListView's dark custom-draw behavior.
     mov dword [rbx + NMLVCUSTOMDRAW.clrText], 0080D080h
     mov dword [rbx + NMLVCUSTOMDRAW.clrTextBk], 001E1E1Eh

     mov eax, [rbx + NMLVCUSTOMDRAW.uItemState]
     test eax, CDIS_SELECTED
     jz .process_item_ready

     mov dword [rbx + NMLVCUSTOMDRAW.clrText], 00E0FFE0h
     mov dword [rbx + NMLVCUSTOMDRAW.clrTextBk], 00303030h

     ; Suppress the native blue selected bar. The custom background above
     ; becomes the complete selection appearance.
     and dword [rbx + NMLVCUSTOMDRAW.uItemState], not CDIS_SELECTED

.process_item_ready:
     mov eax, CDRF_NEWFONT
     ret

.files_notify:
     ; -----------------------------------------------------
     ; FilesPage owns the TreeView, so lazy expansion notifications also
     ; terminate here at the immediate parent page.
     ; -----------------------------------------------------
     mov rbx, [lparam]

     mov rax, [rbx + NMTREEVIEWW64_LOCAL.hdrHwndFrom]
     cmp rax, [hTreeView]
     jne .notify_default

     mov eax, [rbx + NMTREEVIEWW64_LOCAL.hdrCode]
     cmp eax, TVN_ITEMEXPANDINGW
     jne .notify_default

     cmp dword [rbx + NMTREEVIEWW64_LOCAL.action], TVE_EXPAND
     jne .notify_done

     mov rcx, [rbx + NMTREEVIEWW64_LOCAL.itemNew.hItem]
     call PopulateFolderChildren
     jmp .notify_done

.project_notify:
     ; -----------------------------------------------------
     ; SysLink sends NM_CLICK for a mouse activation and NM_RETURN when the
     ; focused link is activated from the keyboard. Because each destination
     ; has its own SysLink HWND, hwndFrom identifies exactly which URL to open.
     ; -----------------------------------------------------
     mov rbx, [lparam]

     mov eax, [rbx + NMHDR64_LOCAL.code]
     cmp eax, PROJECT_NM_CLICK
     je .project_activate
     cmp eax, PROJECT_NM_RETURN
     jne .notify_default

.project_activate:
     mov rax, [rbx + NMHDR64_LOCAL.hwndFrom]
     cmp rax, [hLinkProfile]
     je .open_profile

     cmp rax, [hLinkRepositories]
     je .open_repositories
     jmp .notify_default

.open_profile:
     mov rcx, sGitHubProfileUrl
     call OpenProjectUrl
     jmp .notify_done

.open_repositories:
     mov rcx, sGitHubRepositoriesUrl
     call OpenProjectUrl

.notify_done:
     xor eax, eax
     ret

.notify_default:
     invoke DefWindowProcW, [hwnd], [wmsg], [wparam], [lparam]
     ret

.size:
     ; Each page lays out only the child controls it owns.
     mov rax, [hwnd]
     cmp rax, [hPageProcesses]
     je .size_processes

     cmp rax, [hPageFiles]
     je .size_files

     cmp rax, [hPageProject]
     je .size_project

     xor eax, eax
     ret

.size_processes:
     call LayoutProcessesPage
     xor eax, eax
     ret

.size_files:
     call LayoutFilesPage
     xor eax, eax
     ret

.size_project:
     call LayoutProjectPage
     xor eax, eax
     ret

.erase:
     mov eax, 1
     ret

.paint:
     invoke BeginPaint, [hwnd], pagePs
     mov [pageHdc], rax

     invoke GetClientRect, [hwnd], pageRect

     invoke CreateSolidBrush, 001E1E1Eh
     mov [pageBrush], rax

     test rax, rax
     jz .choose_text

     invoke FillRect, [pageHdc], pageRect, [pageBrush]
     invoke DeleteObject, [pageBrush]

.choose_text:
     ; Processes and Files are full-control pages. Overview and Project keep
     ; lightweight explanatory text painted by the shared page procedure.
     mov rax, [hwnd]
     cmp rax, [hPageProcesses]
     je .paint_done

     cmp rax, [hPageFiles]
     je .paint_done

     cmp rax, [hPageProject]
     je .paint_project

     mov rsi, sPageOverview
     jmp .draw_page_text

.paint_project:
     mov rsi, sPageProjectIntro

.draw_page_text:

     invoke SelectObject, [pageHdc], [hTabFont]
     mov rdi, rax

     invoke SetBkMode, [pageHdc], TRANSPARENT
     invoke SetTextColor, [pageHdc], 00D0D0D0h

     invoke MulDiv, 18, [CurrentDpi], 96
     add [pageRect.left], eax
     add [pageRect.top], eax

     invoke DrawTextW, [pageHdc], rsi, -1, pageRect, DT_LEFT + DT_TOP + DT_WORDBREAK

     invoke SelectObject, [pageHdc], rdi

.paint_done:
     invoke EndPaint, [hwnd], pagePs
     xor eax, eax
     ret
endp


; =========================================================
; UpdateProcessListFont
;
; Sets an explicit DPI-scaled font on the ListView BODY rows. The standalone
; process lesson let Windows choose the row font, but the combined TabControl
; runs under a ComCtl32 v6 manifest for SysLink. Making the row font explicit
; keeps the visual size stable instead of depending on that version/theme
; default. WM_SETFONT does not transfer HFONT ownership to the control.
; =========================================================

proc UpdateProcessListFont uses rbx rsi rdi

     cmp [hListView], 0
     je .done

     invoke CreateFontW, [ScaledProcessFontHeight], 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,\
	    DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,\
	    DEFAULT_QUALITY, DEFAULT_PITCH + FF_DONTCARE, _processFontName

     test rax, rax
     jz .done

     mov rbx, rax
     mov rsi, [hProcessFont]

     mov [hProcessFont], rbx
     invoke SendMessageW, [hListView], WM_SETFONT, rbx, TRUE

     test rsi, rsi
     jz .done

     invoke DeleteObject, rsi

.done:
     ret
endp


; =========================================================
; UpdateListViewHeaderFont
;
; The ListView's Header control does not own the HFONT passed by WM_SETFONT.
; Create/install the replacement first, then delete the previous object.
; =========================================================

proc UpdateListViewHeaderFont uses rbx rsi rdi

     cmp [hHeader], 0
     je .done

     invoke CreateFontW, [ScaledHeaderFontSize], 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,\
	    DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,\
	    5, DEFAULT_PITCH + FF_DONTCARE, _listHeaderFontName

     test rax, rax
     jz .done

     mov rbx, rax
     mov rsi, [hHeaderFont]

     mov [hHeaderFont], rbx
     invoke SendMessageW, [hHeader], WM_SETFONT, rbx, TRUE

     test rsi, rsi
     jz .done

     invoke DeleteObject, rsi

.done:
     ret
endp


; =========================================================
; DarkSysLinkProc
;
; SysLink's LWS_TRANSPARENT style controls the background MIX MODE used
; while drawing the link text.	It does not guarantee that the SysLink
; child window itself will never erase to a light system color first.
;
; We therefore intercept only WM_ERASEBKGND and paint that child surface
; with the same dark brush used by the rest of this application.  Every
; other message goes straight to the original SysLink window procedure,
; so this remains a real native SysLink control with its normal mouse,
; keyboard, focus and NM_CLICK / NM_RETURN behavior.
; =========================================================

proc DarkSysLinkProc uses rbx rsi rdi, hwnd, msg, wparam, lparam

     mov [hwnd], rcx
     mov [msg], rdx
     mov [wparam], r8
     mov [lparam], r9

     cmp [msg], WM_ERASEBKGND
     je .erase

.default:
     invoke CallWindowProcW, [OldSysLinkProc], [hwnd], [msg], [wparam], [lparam]
     ret

.erase:
     ; wParam is the HDC Windows supplied for background erasure.
     ; wc.hbrBackground is our persistent 1E1E1E brush and remains valid
     ; until WM_DESTROY, so there is no reason to create/delete a brush here.
     invoke GetClientRect, [hwnd], linkEraseRect
     invoke FillRect, [wparam], linkEraseRect, [wc.hbrBackground]

     mov eax, 1 		; background has been erased
     ret
endp


; =========================================================
; RoundHeaderProc
;
; Same small native Header subclass used by our standalone ListView lesson.
; The ListView still owns/header-manages columns; we only replace painting.
; =========================================================

proc RoundHeaderProc uses rbx rsi rdi, hwnd, msg, wparam, lparam

     mov [hwnd], rcx
     mov [msg], rdx
     mov [wparam], r8
     mov [lparam], r9

     cmp [msg], WM_PAINT
     je .paint

     cmp [msg], WM_ERASEBKGND
     je .erase

.default:
     invoke CallWindowProcW, [OldHeaderProc], [hwnd], [msg], [wparam], [lparam]
     ret

.erase:
     mov eax, 1
     ret

.paint:
     invoke BeginPaint, [hwnd], ps
     mov [hdc], rax

     invoke GetClientRect, [hwnd], rect

     invoke CreateSolidBrush, 001E1E1Eh
     mov [brush], rax
     invoke FillRect, [hdc], rect, [brush]
     invoke DeleteObject, [brush]

     invoke SendMessageW, [hwnd], HDM_GETITEMCOUNT, 0, 0
     mov ebx, eax

     xor esi, esi

.item_loop:
     cmp esi, ebx
     jge .done

     invoke SendMessageW, [hwnd], HDM_GETITEMRECT, rsi, rect

     add dword [rect.left], 2
     add dword [rect.top], 1
     sub dword [rect.right], 2
     sub dword [rect.bottom], 1

     invoke CreateSolidBrush, 002E2E2Eh
     mov [brush], rax

     invoke SelectObject, [hdc], [brush]
     mov [oldObject], rax

     invoke RoundRect, [hdc],\
	    [rect.left], [rect.top], [rect.right], [rect.bottom],\
	    10, 10

     invoke SelectObject, [hdc], [oldObject]
     invoke DeleteObject, [brush]

     mov eax, ebx
     dec eax
     cmp esi, eax
     jge .no_separator

     mov eax, [rect.right]
     mov [rect.left], eax
     add eax, 3
     mov [rect.right], eax

     add dword [rect.top], 4
     sub dword [rect.bottom], 4

     invoke CreateSolidBrush, 00505050h
     mov [brush], rax
     invoke FillRect, [hdc], rect, [brush]
     invoke DeleteObject, [brush]

.no_separator:
     invoke SetBkMode, [hdc], TRANSPARENT

     cmp esi, 0
     je .col0_color

     invoke SetTextColor, [hdc], 00A070F0h
     jmp .color_done

.col0_color:
     invoke SetTextColor, [hdc], 00E8A070h

.color_done:
     mov [hdi.mask], HDI_TEXT
     mov [hdi.pszText], header_text_buf
     mov [hdi.cchTextMax], 64

     invoke SendMessageW, [hwnd], HDM_GETITEMW, rsi, hdi
     invoke SendMessageW, [hwnd], HDM_GETITEMRECT, rsi, rect

     add dword [rect.left], 4
     sub dword [rect.right], 4

     invoke DrawTextW, [hdc], header_text_buf, -1, rect,\
	    DT_CENTER + DT_VCENTER + DT_SINGLELINE + DT_END_ELLIPSIS

     inc esi
     jmp .item_loop

.done:
     invoke EndPaint, [hwnd], ps
     xor eax, eax
     ret
endp


; =========================================================
; ShowProcessContextMenu
;
; RCX = exact ListView item index from NM_RCLICK.
; =========================================================

proc ShowProcessContextMenu uses rbx rsi rdi, itemIndex

     mov [itemIndex], rcx

     mov eax, dword [itemIndex]
     mov [ContextItem], eax

     ; Synchronize visual selection with the exact row that was right-clicked.
     mov [lvi.state], 0
     mov [lvi.stateMask], LVIS_SELECTED + LVIS_FOCUSED
     invoke SendMessageW, [hListView], LVM_SETITEMSTATE, -1, lvi

     mov [lvi.state], LVIS_SELECTED + LVIS_FOCUSED
     mov [lvi.stateMask], LVIS_SELECTED + LVIS_FOCUSED

     mov esi, [ContextItem]
     invoke SendMessageW, [hListView], LVM_SETITEMSTATE, rsi, lvi
     invoke SetFocus, [hListView]

     invoke CreatePopupMenu
     test rax, rax
     jz .done

     mov rbx, rax

     invoke CreateSolidBrush, 002E2E2Eh
     mov rdi, rax

     mov [popupMenuInfo.cbSize], sizeof.MENUINFO64_LOCAL
     mov [popupMenuInfo.fMask], POPUP_MIM_BACKGROUND
     mov [popupMenuInfo.hbrBack], rdi

     test rdi, rdi
     jz .menu_items
     invoke SetMenuInfo, rbx, popupMenuInfo

.menu_items:
     invoke AppendMenuW, rbx, POPUP_MF_OWNERDRAW, IDM_PROCESS_END, 0
     invoke AppendMenuW, rbx, POPUP_MF_SEPARATOR, 0, 0
     invoke AppendMenuW, rbx, POPUP_MF_OWNERDRAW, IDM_PROCESS_REFRESH, 0

     invoke GetCursorPos, pt
     invoke SetForegroundWindow, [MainWindow]

     ; Keep MainWindow as owner: this is the already-tested popup pattern and
     ; makes its WM_MEASUREITEM/WM_DRAWITEM coexist with the tab owner draw.
     invoke TrackPopupMenu, rbx, POPUP_TPM_RETURNCMD + POPUP_TPM_RIGHTBUTTON,\
	    [pt.x], [pt.y], 0, [MainWindow], 0

     mov esi, eax

     invoke DestroyMenu, rbx

     test rdi, rdi
     jz .menu_brush_done
     invoke DeleteObject, rdi

.menu_brush_done:
     invoke PostMessageW, [MainWindow], WM_NULL, 0, 0

     cmp esi, IDM_PROCESS_END
     je .end_process

     cmp esi, IDM_PROCESS_REFRESH
     je .refresh

     jmp .done

.end_process:
     mov ecx, [ContextItem]
     call EndProcessListItem
     jmp .done

.refresh:
     mov rcx, [hListView]
     call PopulateProcessList

.done:
     ret
endp


; =========================================================
; EndProcessListItem
;
; RCX = ListView row index. PID comes from LVITEM.lParam, never parsed text.
; =========================================================

proc EndProcessListItem uses rbx rsi rdi, itemIndex

     mov [itemIndex], rcx

     mov eax, dword [itemIndex]
     cmp eax, -1
     je .done

     mov [lvi.mask], LVIF_PARAM
     mov [lvi.iItem], eax
     mov [lvi.iSubItem], 0

     invoke SendMessageW, [hListView], LVM_GETITEMW, 0, lvi
     test eax, eax
     jz .done

     mov eax, dword [lvi.lParam]
     mov [TargetPid], eax

     invoke GetCurrentProcessId
     cmp eax, [TargetPid]
     je .self_process

     invoke OpenProcess, PROCESS_TERMINATE_ACCESS, FALSE, [TargetPid]
     test rax, rax
     jz .open_failed

     mov rbx, rax

     invoke wsprintfW, processMessage, _confirmEndFormat, [TargetPid]
     invoke MessageBoxW, [MainWindow], processMessage, _title,\
	    MB_ICONWARNING + MB_YESNO + MB_DEFBUTTON2

     cmp eax, IDYES
     jne .cancel

     invoke TerminateProcess, rbx, 1
     test eax, eax
     jz .terminate_failed

     invoke CloseHandle, rbx

     mov rcx, [hListView]
     call PopulateProcessList
     jmp .done

.cancel:
     invoke CloseHandle, rbx
     jmp .done

.terminate_failed:
     invoke GetLastError
     mov [LastProcessError], eax

     invoke CloseHandle, rbx
     jmp .show_error

.open_failed:
     invoke GetLastError
     mov [LastProcessError], eax

.show_error:
     invoke wsprintfW, processMessage, _endFailedFormat,\
	    [TargetPid], [LastProcessError]

     invoke MessageBoxW, [MainWindow], processMessage, _title, MB_ICONERROR + MB_OK
     jmp .done

.self_process:
     invoke MessageBoxW, [MainWindow], _selfProcessMessage, _title,\
	    MB_ICONINFORMATION + MB_OK

.done:
     ret
endp


; =========================================================
; PopulateProcessList
;
; RCX = ListView HWND.
;
; PROCESSENTRY32W is 238h bytes on Win64, so 1.5 intentionally allocates
; that temporary enumeration record from the process heap. This follows our
; project rule: no large scratch buffers are reserved in the executable.
; =========================================================

proc PopulateProcessList uses rbx rsi rdi r12, hwndList

     mov [hwndList], rcx

     invoke HeapAlloc, [hProcessHeap], 0, sizeof.PROCESSENTRY32W64
     test rax, rax
     jz .memory_error

     mov r12, rax

     invoke CreateToolhelp32Snapshot, TOOLHELP_SNAP_PROCESS, 0
     cmp rax, -1
     je .snapshot_error

     mov [hSnapshot], rax

     mov dword [r12 + PROCESSENTRY32W64.dwSize], sizeof.PROCESSENTRY32W64

     invoke SendMessageW, [hwndList], LVM_DELETEALLITEMS, 0, 0

     invoke Process32FirstW, [hSnapshot], r12
     test eax, eax
     jz .close_snapshot

     xor ebx, ebx

.process_loop:
     mov [lvi.mask], LVIF_TEXT + LVIF_PARAM
     mov [lvi.iItem], ebx
     mov [lvi.iSubItem], 0

     lea rax, [r12 + PROCESSENTRY32W64.szExeFile]
     mov [lvi.pszText], rax

     mov eax, [r12 + PROCESSENTRY32W64.th32ProcessID]
     mov [lvi.lParam], rax

     invoke SendMessageW, [hwndList], LVM_INSERTITEMW, 0, lvi

     cmp eax, -1
     je .next_process
     mov esi, eax

     invoke wsprintfW, pidText, pidFormat,\
	    [r12 + PROCESSENTRY32W64.th32ProcessID]

     mov [lvi.mask], LVIF_TEXT
     mov [lvi.iItem], esi
     mov [lvi.iSubItem], 1
     mov [lvi.pszText], pidText

     invoke SendMessageW, [hwndList], LVM_SETITEMW, 0, lvi

     inc ebx

.next_process:
     invoke Process32NextW, [hSnapshot], r12
     test eax, eax
     jnz .process_loop

.close_snapshot:
     cmp [hSnapshot], 0
     je .free_entry

     invoke CloseHandle, [hSnapshot]
     mov [hSnapshot], 0

.free_entry:
     invoke HeapFree, [hProcessHeap], 0, r12
     ret

.snapshot_error:
     invoke HeapFree, [hProcessHeap], 0, r12
     invoke MessageBoxW, [MainWindow], _snapshotError, _title, MB_ICONERROR + MB_OK
     ret

.memory_error:
     invoke MessageBoxW, [MainWindow], _processMemoryError, _title, MB_ICONERROR + MB_OK
     ret
endp


; =========================================================
; UpdateTreeViewFont
;
; Same ownership rule as the standalone TreeView lesson: WM_SETFONT does not
; transfer ownership. Install the new DPI-scaled font, then delete the old one.
; =========================================================

proc UpdateTreeViewFont uses rbx rsi rdi

     cmp [hTreeView], 0
     je .done

     invoke CreateFontW, [ScaledTreeFontHeight], 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,\
	    DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,\
	    DEFAULT_QUALITY, DEFAULT_PITCH + FF_DONTCARE, _treeFontName

     test rax, rax
     jz .done

     mov rbx, rax
     mov rsi, [hTreeFont]

     mov [hTreeFont], rbx
     invoke SendMessageW, [hTreeView], WM_SETFONT, rbx, TRUE

     test rsi, rsi
     jz .done

     invoke DeleteObject, rsi

.done:
     ret
endp


; =========================================================
; InitSystemIcons
;
; Borrow the Shell's small system image list and remember only one folder and
; one generic file icon index. SHFILEINFOW is larger than our static-buffer
; limit, so the temporary record is heap allocated and freed immediately.
; =========================================================

proc InitSystemIcons uses rbx rsi rdi

     cmp [hTreeView], 0
     je .done

     cmp [ComInitialized], 0
     je .done

     invoke HeapAlloc, [hProcessHeap], 0, SHFILEINFO_BYTES
     test rax, rax
     jz .done

     mov rbx, rax

     invoke SHGetFileInfoW, sFolderIconProbe, TREE_FILE_ATTRIBUTE_DIRECTORY, rbx, SHFILEINFO_BYTES, SHGFI_SYSICONINDEX + SHGFI_SMALLICON + SHGFI_USEFILEATTRIBUTES
     test rax, rax
     jz .free_info

     mov [hSystemImageList], rax
     mov eax, [rbx + SHFILEINFOW64_LOCAL.iIcon]
     mov [FolderIconIndex], eax

     invoke SHGetFileInfoW, sFileIconProbe, TREE_FILE_ATTRIBUTE_NORMAL, rbx, SHFILEINFO_BYTES, SHGFI_SYSICONINDEX + SHGFI_SMALLICON + SHGFI_USEFILEATTRIBUTES
     test rax, rax
     jz .free_info

     mov eax, [rbx + SHFILEINFOW64_LOCAL.iIcon]
     mov [FileIconIndex], eax

     invoke SendMessageW, [hTreeView], TVM_SETIMAGELIST, TVSIL_NORMAL, [hSystemImageList]
     mov [SystemIconsReady], 1

.free_info:
     invoke HeapFree, [hProcessHeap], 0, rbx

.done:
     ret
endp


; =========================================================
; InsertTreeItem -- non-filesystem root ("This PC")
; =========================================================

proc InsertTreeItem uses rbx rsi rdi, parentItem, textPointer

     mov [parentItem], rcx
     mov [textPointer], rdx

     mov rax, [parentItem]
     mov [tvis.hParent], rax
     mov qword [tvis.hInsertAfter], TVI_LAST_VALUE

     mov [tvis.item.mask], TVIF_TEXT
     mov qword [tvis.item.hItem], 0
     mov [tvis.item.state], 0
     mov [tvis.item.stateMask], 0

     mov rax, [textPointer]
     mov [tvis.item.pszText], rax

     mov [tvis.item.cchTextMax], 0
     mov [tvis.item.iImage], 0
     mov [tvis.item.iSelectedImage], 0

     cmp [SystemIconsReady], 0
     je .root_icon_done

     or [tvis.item.mask], TVIF_IMAGE + TVIF_SELECTEDIMAGE
     mov eax, [FolderIconIndex]
     mov [tvis.item.iImage], eax
     mov [tvis.item.iSelectedImage], eax

.root_icon_done:
     mov [tvis.item.cChildren], 0
     mov qword [tvis.item.lParam], 0

     invoke SendMessageW, [hTreeView], TVM_INSERTITEMW, 0, tvis
     ret
endp


; =========================================================
; Tiny Unicode / heap-path helpers
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


proc AllocUnicodeCopy uses rbx rsi rdi, sourceText

     mov [sourceText], rcx
     mov rsi, rcx

     call UnicodeLengthChars
     mov rbx, rax

     inc rax
     shl rax, 1

     invoke HeapAlloc, [hProcessHeap], 0, rax
     test rax, rax
     jz .done

     mov rdi, rax
     mov rcx, rbx
     inc rcx
     rep movsw

.done:
     ret
endp


proc AllocJoinedPath uses rbx rsi rdi r12 r13, parentPath, childName

     mov [parentPath], rcx
     mov [childName], rdx

     mov rsi, rcx
     mov rdi, rdx

     mov rcx, rsi
     call UnicodeLengthChars
     mov rbx, rax

     mov rcx, rdi
     call UnicodeLengthChars
     mov r12, rax

     xor r13d, r13d
     test rbx, rbx
     jz .size_ready

     cmp word [rsi + rbx*2 - 2], 005Ch
     je .size_ready

     mov r13d, 1

.size_ready:
     mov rax, rbx
     add rax, r12
     add rax, r13
     inc rax
     shl rax, 1

     invoke HeapAlloc, [hProcessHeap], 0, rax
     test rax, rax
     jz .done

     mov rdx, rax
     mov rdi, rax

     mov rsi, [parentPath]
     mov rcx, rbx
     rep movsw

     test r13d, r13d
     jz .copy_child

     mov word [rdi], 005Ch
     add rdi, 2

.copy_child:
     mov rsi, [childName]
     mov rcx, r12
     inc rcx
     rep movsw

     mov rax, rdx

.done:
     ret
endp


; =========================================================
; InsertFileSystemItem
;
; Every filesystem node carries a stable full path in TVITEM.lParam. Folder
; items advertise children lazily; file items are leaves.
; =========================================================

proc InsertFileSystemItem uses rbx rsi rdi, parentItem, textPointer, pathPointer, childHint

     mov [parentItem], rcx
     mov [textPointer], rdx
     mov [pathPointer], r8
     mov [childHint], r9

     mov rax, [parentItem]
     mov [tvis.hParent], rax
     mov qword [tvis.hInsertAfter], TVI_LAST_VALUE

     mov [tvis.item.mask], TVIF_TEXT + TVIF_PARAM + TVIF_CHILDREN
     mov qword [tvis.item.hItem], 0
     mov [tvis.item.state], 0
     mov [tvis.item.stateMask], 0

     mov rax, [textPointer]
     mov [tvis.item.pszText], rax

     mov rax, [pathPointer]
     mov [tvis.item.lParam], rax

     mov [tvis.item.cchTextMax], 0
     mov [tvis.item.iImage], 0
     mov [tvis.item.iSelectedImage], 0

     mov eax, dword [childHint]
     mov [tvis.item.cChildren], eax

     cmp [SystemIconsReady], 0
     je .item_icon_done

     or [tvis.item.mask], TVIF_IMAGE + TVIF_SELECTEDIMAGE

     cmp dword [childHint], 0
     je .use_file_icon

     mov eax, [FolderIconIndex]
     jmp .set_item_icon

.use_file_icon:
     mov eax, [FileIconIndex]

.set_item_icon:
     mov [tvis.item.iImage], eax
     mov [tvis.item.iSelectedImage], eax

.item_icon_done:
     invoke SendMessageW, [hTreeView], TVM_INSERTITEMW, 0, tvis
     test rax, rax
     jnz .done

     invoke HeapFree, [hProcessHeap], 0, [pathPointer]
     xor eax, eax

.done:
     ret
endp


; =========================================================
; PopulateFolderChildren -- lazy filesystem expansion
; =========================================================

proc PopulateFolderChildren uses rbx rsi rdi r12, folderItem

     mov [folderItem], rcx

     cmp rcx, [hRootItem]
     je .done

     invoke SendMessageW, [hTreeView], TVM_GETNEXTITEM, TVGN_CHILD, [folderItem]
     test rax, rax
     jnz .done

     mov [tvQuery.mask], TVIF_PARAM
     mov rax, [folderItem]
     mov [tvQuery.hItem], rax

     invoke SendMessageW, [hTreeView], TVM_GETITEMW, 0, tvQuery
     test eax, eax
     jz .done

     mov r12, [tvQuery.lParam]
     test r12, r12
     jz .done

     mov rcx, r12
     call UnicodeLengthChars
     mov rbx, rax

     cmp rbx, 257
     ja .no_children

     invoke HeapAlloc, [hProcessHeap], 0, TREE_SCRATCH_BYTES
     test rax, rax
     jz .no_children

     mov [folderScratch], rax
     mov rdi, rax
     lea rsi, [rax + TREE_FIND_DATA_BYTES]

     mov rcx, rbx
     mov rax, rsi
     mov rdi, rsi
     mov rsi, r12
     rep movsw

     test rbx, rbx
     jz .append_star

     cmp word [r12 + rbx*2 - 2], 005Ch
     je .append_star

     mov word [rdi], 005Ch
     add rdi, 2

.append_star:
     mov word [rdi], 002Ah
     mov word [rdi + 2], 0

     mov rdi, [folderScratch]
     lea rsi, [rdi + TREE_FIND_DATA_BYTES]

     invoke FindFirstFileW, rsi, rdi
     cmp rax, TREE_FIND_INVALID_HANDLE_VALUE
     je .free_scratch_no_children

     mov [folderFindHandle], rax
     xor ebx, ebx

.next_entry:
     cmp word [rdi + WIN32_FIND_DATAW_LOCAL.cFileName], '.'
     jne .insert_entry

     cmp word [rdi + WIN32_FIND_DATAW_LOCAL.cFileName + 2], 0
     je .find_next

     cmp word [rdi + WIN32_FIND_DATAW_LOCAL.cFileName + 2], '.'
     jne .insert_entry

     cmp word [rdi + WIN32_FIND_DATAW_LOCAL.cFileName + 4], 0
     je .find_next

.insert_entry:
     lea rdx, [rdi + WIN32_FIND_DATAW_LOCAL.cFileName]
     mov rcx, r12
     call AllocJoinedPath

     test rax, rax
     jz .find_next

     mov r8, rax

     mov eax, [rdi + WIN32_FIND_DATAW_LOCAL.dwFileAttributes]
     test eax, TREE_FILE_ATTRIBUTE_DIRECTORY
     jz .file_leaf

     mov r9d, 1
     jmp .insert_item

.file_leaf:
     xor r9d, r9d

.insert_item:
     mov rcx, [folderItem]
     lea rdx, [rdi + WIN32_FIND_DATAW_LOCAL.cFileName]
     call InsertFileSystemItem

     test rax, rax
     jz .find_next

     inc ebx

.find_next:
     invoke FindNextFileW, [folderFindHandle], rdi
     test eax, eax
     jnz .next_entry

     invoke FindClose, [folderFindHandle]
     mov qword [folderFindHandle], 0

     invoke HeapFree, [hProcessHeap], 0, [folderScratch]
     mov qword [folderScratch], 0

     test ebx, ebx
     jnz .done
     jmp .no_children

.free_scratch_no_children:
     invoke HeapFree, [hProcessHeap], 0, [folderScratch]
     mov qword [folderScratch], 0

.no_children:
     mov [tvQuery.mask], TVIF_CHILDREN
     mov rax, [folderItem]
     mov [tvQuery.hItem], rax
     mov [tvQuery.cChildren], 0

     invoke SendMessageW, [hTreeView], TVM_SETITEMW, 0, tvQuery

.done:
     ret
endp


; =========================================================
; PopulateTreeView -- startup inserts only This PC + drives
; =========================================================

proc PopulateTreeView uses rbx rsi rdi r12, hwndTree

     mov [hwndTree], rcx

     mov rcx, TVI_ROOT_VALUE
     mov rdx, sThisPC
     call InsertTreeItem

     test rax, rax
     jz .done

     mov [hRootItem], rax

     invoke GetLogicalDriveStringsW, 0, 0
     test eax, eax
     jz .drive_error

     mov ebx, eax

     mov eax, ebx
     shl rax, 1
     invoke HeapAlloc, [hProcessHeap], 0, rax
     test rax, rax
     jz .drive_error

     mov r12, rax

     invoke GetLogicalDriveStringsW, ebx, r12
     test eax, eax
     jz .drive_buffer_error

     cmp eax, ebx
     ja .drive_buffer_error

     mov rsi, r12

.next_drive:
     cmp word [rsi], 0
     je .free_drive_buffer

     mov rcx, rsi
     call AllocUnicodeCopy
     test rax, rax
     jz .skip_drive_text

     mov r8, rax
     mov r9d, 1
     mov rcx, [hRootItem]
     mov rdx, rsi
     call InsertFileSystemItem

.skip_drive_text:
     cmp word [rsi], 0
     je .after_drive_text

     add rsi, 2
     jmp .skip_drive_text

.after_drive_text:
     add rsi, 2
     jmp .next_drive

.drive_buffer_error:
     invoke HeapFree, [hProcessHeap], 0, r12

.drive_error:
     invoke MessageBoxW, [MainWindow], _driveError, _title, MB_ICONERROR + MB_OK
     jmp .expand_root

.free_drive_buffer:
     invoke HeapFree, [hProcessHeap], 0, r12

.expand_root:
     invoke SendMessageW, [hwndTree], TVM_EXPAND, TVE_EXPAND, [hRootItem]

.done:
     ret
endp


; =========================================================
; UpdateTabFont
;
; Creates a new DPI-scaled HFONT, installs it in the TabControl, and only
; then deletes the previous HFONT. WM_SETFONT does NOT transfer ownership.
; =========================================================

proc UpdateTabFont uses rbx rsi rdi

     cmp [hTabControl], 0
     je .done

     invoke CreateFontW, [ScaledTabFontHeight], 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,\
	    DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,\
	    DEFAULT_QUALITY, DEFAULT_PITCH + FF_DONTCARE, _tabFontName

     test rax, rax
     jz .done

     mov rbx, rax
     mov rsi, [hTabFont]

     mov [hTabFont], rbx
     invoke SendMessageW, [hTabControl], WM_SETFONT, rbx, TRUE

     ; Project-page SysLinks share this same DPI-scaled font. Update every
     ; control that may still reference the previous HFONT BEFORE deleting it.
     cmp [hLinkProfile], 0
     je .skip_profile_font
     invoke SendMessageW, [hLinkProfile], WM_SETFONT, rbx, TRUE

.skip_profile_font:
     cmp [hLinkRepositories], 0
     je .font_users_updated
     invoke SendMessageW, [hLinkRepositories], WM_SETFONT, rbx, TRUE

.font_users_updated:
     test rsi, rsi
     jz .done

     invoke DeleteObject, rsi

.done:
     ret
endp


; =========================================================
; Paint our common borderless dark window shell
; =========================================================

proc PaintWindow

     mov [hwnd], rcx

     invoke BeginPaint, [hwnd], ps
     mov [hdc], rax

     ; Full client background
     invoke GetClientRect, [hwnd], rect

     invoke CreateSolidBrush, 001E1E1Eh
     mov [brush], rax
     invoke FillRect, [hdc], rect, [brush]
     invoke DeleteObject, [brush]

     ; Custom title bar
     mov dword [rect.left], 0
     mov dword [rect.top], 0

     mov eax, [ScaledTitleHeight]
     mov [rect.bottom], eax

     invoke CreateSolidBrush, 00262626h
     mov [brush], rax
     invoke FillRect, [hdc], rect, [brush]
     invoke DeleteObject, [brush]

     ; Close button rectangle
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

     invoke EndPaint, [hwnd], ps
     ret
endp


; =========================================================
; Mouse handling for the custom close button / title drag
; =========================================================

proc HandleMouseClick

     mov [hwnd], rcx
     mov [lparam], rdx

     ; Decode the original packed 32-bit LPARAM safely on x64.
     mov eax, dword [lparam]

     movsx ecx, ax
     mov [MouseX], ecx

     shr eax, 16
     movsx ecx, ax
     mov [MouseY], ecx

     ; Close button hit test
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

     ; A click in our custom title strip starts a normal caption drag.
     mov eax, [ScaledTitleHeight]
     cmp [MouseY], eax
     jg .done

     invoke ReleaseCapture
     invoke SendMessageW, [hwnd], WM_NCLBUTTONDOWN, HTCAPTION, 0

.done:
     ret
endp


; =========================================================
; Keep the TabControl filling the client area below the custom title bar.
; =========================================================

proc LayoutControls uses rbx rsi rdi, hwnd

     mov [hwnd], rcx

     cmp [hTabControl], 0
     je .done

     invoke GetClientRect, [hwnd], rect

     ; width = client width - left/right margins
     mov esi, [rect.right]
     mov eax, [ScaledMargin]
     shl eax, 1
     sub esi, eax

     ; height = client height - title bar - top/bottom margins
     mov ebx, [rect.bottom]
     sub ebx, [ScaledTitleHeight]

     mov eax, [ScaledMargin]
     shl eax, 1
     sub ebx, eax

     ; y = custom title bar + top margin
     mov edi, [ScaledTitleHeight]
     add edi, [ScaledMargin]

     invoke MoveWindow, [hTabControl], [ScaledMargin], edi, esi, ebx, TRUE

     ; The TabControl itself knows the exact display rectangle beneath
     ; its tab row. Ask it for that rectangle instead of hard-coding
     ; header heights or theme-dependent border sizes.
     call LayoutTabPages

.done:
     ret
endp


; =========================================================
; LayoutTabPages
;
; All four page windows occupy the exact SAME native display rectangle.
; TCM_ADJUSTRECT with wParam = FALSE converts the TabControl client RECT
; into the rectangle Windows reserves for application page content.
; =========================================================

proc LayoutTabPages uses rbx rsi rdi

     cmp [hTabControl], 0
     je .done

     invoke GetClientRect, [hTabControl], pageLayoutRect
     invoke SendMessageW, [hTabControl], TCM_ADJUSTRECT, FALSE, pageLayoutRect

     mov esi, [pageLayoutRect.right]
     sub esi, [pageLayoutRect.left]

     mov ebx, [pageLayoutRect.bottom]
     sub ebx, [pageLayoutRect.top]

     cmp [hPageOverview], 0
     je .processes
     invoke MoveWindow, [hPageOverview],\
	    [pageLayoutRect.left], [pageLayoutRect.top],\
	    esi, ebx, TRUE

.processes:
     cmp [hPageProcesses], 0
     je .settings
     invoke MoveWindow, [hPageProcesses],\
	    [pageLayoutRect.left], [pageLayoutRect.top],\
	    esi, ebx, TRUE

.settings:
     cmp [hPageFiles], 0
     je .project
     invoke MoveWindow, [hPageFiles],\
	    [pageLayoutRect.left], [pageLayoutRect.top],\
	    esi, ebx, TRUE

.project:
     cmp [hPageProject], 0
     je .done
     invoke MoveWindow, [hPageProject],\
	    [pageLayoutRect.left], [pageLayoutRect.top],\
	    esi, ebx, TRUE

.done:
     ret
endp


; =========================================================
; LayoutProcessesPage
;
; ProcessesPage owns the ListView. Keep one DPI-scaled margin around it and
; resize the two report columns with the original 260:230 proportion.
; =========================================================

proc LayoutProcessesPage uses rbx rsi rdi

     cmp [hPageProcesses], 0
     je .done

     cmp [hListView], 0
     je .done

     invoke GetClientRect, [hPageProcesses], listLayoutRect

     mov esi, [listLayoutRect.right]
     mov eax, [ScaledMargin]
     shl eax, 1
     sub esi, eax
     jns .width_ok
     xor esi, esi

.width_ok:
     mov ebx, [listLayoutRect.bottom]
     mov eax, [ScaledMargin]
     shl eax, 1
     sub ebx, eax
     jns .height_ok
     xor ebx, ebx

.height_ok:
     invoke MoveWindow, [hListView], [ScaledMargin], [ScaledMargin], esi, ebx, TRUE

     ; Resize report columns after the ListView has its final client width.
     invoke GetClientRect, [hListView], listLayoutRect

     mov ebx, [listLayoutRect.right]
     sub ebx, [listLayoutRect.left]

     invoke MulDiv, ebx, 260, 490
     mov esi, eax

     mov edi, ebx
     sub edi, esi

     invoke SendMessageW, [hListView], LVM_SETCOLUMNWIDTH, 0, esi
     invoke SendMessageW, [hListView], LVM_SETCOLUMNWIDTH, 1, edi

.done:
     ret
endp


; =========================================================
; LayoutFilesPage
;
; FilesPage is the parent of the TreeView. This helper therefore uses the
; PAGE client rectangle, not the MainWindow or TabControl rectangle. A small
; DPI-scaled margin keeps the embedded control visually separate from the tab
; frame while preserving the standalone TreeView's resize behavior.
; =========================================================

proc LayoutFilesPage uses rbx rsi rdi

     cmp [hPageFiles], 0
     je .done

     cmp [hTreeView], 0
     je .done

     invoke GetClientRect, [hPageFiles], treeLayoutRect

     mov esi, [treeLayoutRect.right]
     mov eax, [ScaledMargin]
     shl eax, 1
     sub esi, eax
     jns .width_ok
     xor esi, esi

.width_ok:
     mov ebx, [treeLayoutRect.bottom]
     mov eax, [ScaledMargin]
     shl eax, 1
     sub ebx, eax
     jns .height_ok
     xor ebx, ebx

.height_ok:
     invoke MoveWindow, [hTreeView], [ScaledMargin], [ScaledMargin], esi, ebx, TRUE

.done:
     ret
endp


; =========================================================
; LayoutProjectPage
;
; ProjectPage owns two SysLink controls. Keep them aligned with the same
; DPI-scaled page margin used by the other embedded controls. The explanatory
; text is painted by PageProc above them; only the clickable link HWNDs need
; explicit child-window layout here.
; =========================================================

proc LayoutProjectPage uses rbx rsi rdi r12

     cmp [hPageProject], 0
     je .done

     invoke GetClientRect, [hPageProject], projectLayoutRect

     ; PageProc paints the Project-page text with an 18-pixel design inset.
     ; Use that exact same DPI-scaled X position for the SysLinks so the
     ; clickable rows line up visually with "FASM Win64 Controls" above.
     invoke MulDiv, PROJECT_LINK_LEFT_96, [CurrentDpi], 96
     mov r12d, eax

     ; width = client right - link left - normal right margin
     mov esi, [projectLayoutRect.right]
     sub esi, r12d
     sub esi, [ScaledMargin]
     jns .width_ok
     xor esi, esi

.width_ok:
     invoke MulDiv, PROJECT_LINK_TOP_96, [CurrentDpi], 96
     mov ebx, eax

     invoke MulDiv, PROJECT_LINK_HEIGHT_96, [CurrentDpi], 96
     mov edi, eax

     cmp [hLinkProfile], 0
     je .repositories
     invoke MoveWindow, [hLinkProfile], r12d, ebx, esi, edi, TRUE

.repositories:
     invoke MulDiv, PROJECT_LINK_GAP_96, [CurrentDpi], 96
     add ebx, eax

     cmp [hLinkRepositories], 0
     je .done
     invoke MoveWindow, [hLinkRepositories], r12d, ebx, esi, edi, TRUE

.done:
     ret
endp


; =========================================================
; OpenProjectUrl
;
; RCX = pointer to a zero-terminated Unicode URL.
;
; SysLink only reports that the user activated a link; the host application
; decides what the activation means. ShellExecuteW with the "open" verb lets
; Windows hand an https URL to the user's configured default browser.
; =========================================================

proc OpenProjectUrl uses rbx rsi rdi, urlPointer

     mov [urlPointer], rcx

     invoke ShellExecuteW, [hPageProject], sOpenVerb, [urlPointer], 0, 0, SW_SHOWNORMAL

     ; ShellExecuteW returns a value greater than 32 on success. Keep failure
     ; handling small and visible for a learning example.
     cmp rax, 32
     ja .done

     invoke MessageBoxW, [hPageProject], sOpenUrlFailed, _title, MB_ICONERROR + MB_OK

.done:
     ret
endp


; =========================================================
; ShowSelectedPage
;
; The TabControl owns ONLY the current item index. Our application owns the
; page HWNDs, so TCN_SELCHANGE becomes a small set of ShowWindow calls.
; Keeping this logic in one helper also makes future real controls/pages easy
; to add without mixing page management into WM_NOTIFY itself.
; =========================================================

proc ShowSelectedPage uses rbx rsi rdi

     cmp [hTabControl], 0
     je .done

     invoke SendMessageW, [hTabControl], TCM_GETCURSEL, 0, 0
     mov ebx, eax

     ; First hide every page. ShowWindow is harmless if a page is already
     ; hidden, and this keeps the state unambiguous.
     cmp [hPageOverview], 0
     je .hide_processes
     invoke ShowWindow, [hPageOverview], SW_HIDE

.hide_processes:
     cmp [hPageProcesses], 0
     je .hide_settings
     invoke ShowWindow, [hPageProcesses], SW_HIDE

.hide_settings:
     cmp [hPageFiles], 0
     je .hide_project
     invoke ShowWindow, [hPageFiles], SW_HIDE

.hide_project:
     cmp [hPageProject], 0
     je .choose_page
     invoke ShowWindow, [hPageProject], SW_HIDE

.choose_page:
     cmp ebx, 0
     je .show_overview
     cmp ebx, 1
     je .show_processes
     cmp ebx, 2
     je .show_settings
     cmp ebx, 3
     je .show_project
     jmp .repaint_tabs

.show_overview:
     invoke ShowWindow, [hPageOverview], SW_SHOW
     jmp .repaint_tabs

.show_processes:
     invoke ShowWindow, [hPageProcesses], SW_SHOW
     jmp .repaint_tabs

.show_settings:
     invoke ShowWindow, [hPageFiles], SW_SHOW
     jmp .repaint_tabs

.show_project:
     invoke ShowWindow, [hPageProject], SW_SHOW

.repaint_tabs:
     ; Selection painting is still owner-drawn. Invalidate the TabControl so
     ; the newly selected header and its new subtle selected surface redraw immediately.
     invoke InvalidateRect, [hTabControl], NULL, FALSE

.done:
     ret
endp


section '.data' data readable writeable

  _title	     du 'TabControl 1.6.3 - ExitSizeMove Repaint Test',0
  _pageClass	     du 'FASMWIN64TABPAGE',0
  _class	     du 'FASMWIN64TABCONTROL',0
  _error	     du 'Startup failed.',0
  _closeX	     du 'X',0
  _tabFontName	     du 'Segoe UI',0
  _treeFontName      du 'Segoe UI',0
  _processFontName   du 'Segoe UI',0
  _listHeaderFontName du 'Consolas',0

  SysTabControl32Name du 'SysTabControl32',0
  SysTreeView32Name  du 'SysTreeView32',0
  SysLinkClassName   du 'SysLink',0
  _DarkModeExplorer  du 'DarkMode_Explorer',0

  ; Four TabControl labels. These strings are tiny and persistent, so there is
  ; no reason to heap-allocate them. Our project's large-buffer rule remains
  ; unchanged: no static scratch buffers larger than MAX_PATH.
  sTabOverview	     du 'Overview',0
  sTabProcesses      du 'Processes',0
  sTabFiles	     du 'Files',0
  sTabProject	     du 'Project',0

  ; Overview remains intentionally simple; Processes/Files host real controls,
  ; while Project demonstrates native hyperlink controls.
  sPageOverview      du 'Overview page',0

  ; Project page. Keep the visible SysLink markup and the persistent URLs
  ; identical. The host opens the persistent URL selected by hwndFrom.
  sPageProjectIntro  du 'FASM Win64 Controls',13,10,\
			'Pure FASM x64 + native Win32 API learning/reference project.',13,10,13,10,\
			'Current GitHub links:',0
  sLinkProfileMarkup du '<a href="https://github.com/Joch64ASM">GitHub profile - Joch64ASM</a>',0
  sLinkRepositoriesMarkup du '<a href="https://github.com/Joch64ASM?tab=repositories">Public repositories</a>',0
  sGitHubProfileUrl  du 'https://github.com/Joch64ASM',0
  sGitHubRepositoriesUrl du 'https://github.com/Joch64ASM?tab=repositories',0
  sOpenVerb	     du 'open',0
  sOpenUrlFailed     du 'Windows could not open the selected GitHub link.',0

  ; Processes-page ListView labels / popup text.
  sProcess	     du ' Process',0
  sPID		     du ' PID',0
  pidFormat	     du '%u',0
  pidText	     rw 16

  _snapshotError     du 'Could not create the process snapshot.',0
  _processMemoryError du 'Could not allocate process enumeration memory.',0
  sEndProcess	     du 'End Process',0
  sRefreshList	     du 'Refresh List',0
  _confirmEndFormat  du 'End process PID %u?',0
  _endFailedFormat   du 'Could not end PID %u.',13,10,'Windows error: %u',0
  _selfProcessMessage du 'This demo will not terminate its own process.',0

  ; 120 WCHARs = 240 bytes, deliberately below our MAX_PATH/static-buffer rule.
  processMessage     rw 120

  ; Files-page TreeView contents / tiny Shell icon probes.
  sThisPC	     du 'This PC',0
  _driveError	     du 'Could not enumerate logical drives.',0
  sFolderIconProbe   du 'Folder',0
  sFileIconProbe     du 'File.txt',0

  ; A paint-time label buffer of 64 WCHARs = 128 bytes, well below MAX_PATH.
  tabTextBuffer      rw 64


; ---------------------------------------------------------
; INITCOMMONCONTROLSEX is two DWORDs on both Win32 and Win64. SysLink is
; registered by InitCommonControlsEx when dwICC contains PROJECT_ICC_LINK_CLASS.
; ---------------------------------------------------------

struct INITCOMMONCONTROLSEX_LOCAL
  dwSize	dd ?
  dwICC 	dd ?
ends


; ---------------------------------------------------------
; TCITEMW - Win64 layout used for TCM_INSERTITEMW / TCM_GETITEMW.
;
; The FASM include tree is not present in this workspace, so this structure
; has a unique local name rather than risking a collision with the user's
; local includes.
;
; Win64 offsets:
;   mask	00h DWORD
;   dwState	04h DWORD
;   dwStateMask 08h DWORD
;   padding	0Ch DWORD -> align pointer
;   pszText	10h QWORD
;   cchTextMax	18h DWORD
;   iImage	1Ch DWORD
;   lParam	20h QWORD
; sizeof = 28h
; ---------------------------------------------------------

struct TCITEMW64_LOCAL
  mask		dd ?
  dwState	dd ?
  dwStateMask	dd ?
  pad0		dd ?
  pszText	dq ?
  cchTextMax	dd ?
  iImage	dd ?
  lParam	dq ?
ends



; ---------------------------------------------------------
; NMHDR - Win64 layout used by WM_NOTIFY / TCN_SELCHANGE.
;
; HWND and UINT_PTR are 8 bytes. The notification code is a DWORD at 10h,
; followed by padding to make the complete structure 18h bytes.
; ---------------------------------------------------------

struct NMHDR64_LOCAL
  hwndFrom	dq ?		 ; 00h
  idFrom	dq ?		 ; 08h
  code		dd ?		 ; 10h
  pad0		dd ?		 ; 14h
ends				; sizeof = 18h


; ---------------------------------------------------------
; DRAWITEMSTRUCT - Win64 layout.
;
; TCS_OWNERDRAWFIXED causes the TabControl's parent to receive WM_DRAWITEM.
; lParam points to this structure. The same verified x64 layout was already
; used successfully by our owner-drawn popup-menu work in the ListView lesson.
; ---------------------------------------------------------

struct DRAWITEMSTRUCT64_LOCAL
  CtlType	dd ?		 ; 00h
  CtlID 	dd ?		 ; 04h
  itemID	dd ?		 ; 08h
  itemAction	dd ?		 ; 0Ch
  itemState	dd ?		 ; 10h
  pad0		dd ?		 ; 14h -> align HWND
  hwndItem	dq ?		 ; 18h
  hDC		dq ?		 ; 20h
  rcItemLeft	dd ?		 ; 28h
  rcItemTop	dd ?		 ; 2Ch
  rcItemRight	dd ?		 ; 30h
  rcItemBottom	dd ?		 ; 34h
  itemData	dq ?		 ; 38h
ends				; sizeof = 40h



; ---------------------------------------------------------
; Processes-page ListView structures.
; Large PROCESSENTRY32W instances are heap allocated; only the layout lives
; here. The remaining records are small message/item structures.
; ---------------------------------------------------------

struct PROCESSENTRY32W64
  dwSize	       dd ?
  cntUsage		dd ?
  th32ProcessID 	dd ?
  pad0			dd ?
  th32DefaultHeapID	dq ?
  th32ModuleID		dd ?
  cntThreads		dd ?
  th32ParentProcessID	dd ?
  pcPriClassBase	dd ?
  dwFlags		dd ?
  szExeFile		rw MAX_PATH
  padEnd		dd ?
ends

struct MENUINFO64_LOCAL
  cbSize	  dd ?
  fMask 	  dd ?
  dwStyle	  dd ?
  cyMax 	  dd ?
  hbrBack	  dq ?
  dwContextHelpID dd ?
  pad0		  dd ?
  dwMenuData	  dq ?
ends

struct MEASUREITEMSTRUCT64_LOCAL
  CtlType	  dd ?
  CtlID 	  dd ?
  itemID	  dd ?
  itemWidth	  dd ?
  itemHeight	  dd ?
  pad0		  dd ?
  itemData	  dq ?
ends

struct NMITEMACTIVATE_MIN64
  hwndFrom	  dq ?
  idFrom	  dq ?
  code		  dd ?
  pad0		  dd ?
  iItem 	  dd ?
  iSubItem	  dd ?
ends

struct NMLVCUSTOMDRAW
  hwndFrom	  dq ?
  idFrom	  dq ?
  code		  dd ?
  pad0		  dd ?
  dwDrawStage	  dd ?
  pad1		  dd ?
  hdc		  dq ?
  rc.left	  dd ?
  rc.top	  dd ?
  rc.right	  dd ?
  rc.bottom	  dd ?
  dwItemSpec	  dq ?
  uItemState	  dd ?
  pad2		  dd ?
  lItemParam	  dq ?
  clrText	  dd ?
  clrTextBk	  dd ?
  iSubItem	  dd ?
ends

struct LVCOLUMN64_LOCAL
  mask		  dd ?
  fmt		  dd ?
  cx		  dd ?
  pad0		  dd ?
  pszText	  dq ?
  cchTextMax	  dd ?
  iSubItem	  dd ?
  iImage	  dd ?
  iOrder	  dd ?
  pad1		  dd ?
ends

struct LVITEM64_LOCAL
  mask		  dd ?
  iItem 	  dd ?
  iSubItem	  dd ?
  state 	  dd ?
  stateMask	  dd ?
  pad0		  dd ?
  pszText	  dq ?
  cchTextMax	  dd ?
  iImage	  dd ?
  lParam	  dq ?
  iIndent	  dd ?
  iGroupId	  dd ?
  cColumns	  dd ?
  pad1		  dd ?
  puColumns	  dq ?
ends

struct HDITEM64_LOCAL
  mask		  dd ?
  cxy		  dd ?
  pszText	  dq ?
  hbm		  dq ?
  cchTextMax	  dd ?
  fmt		  dd ?
ends

; ---------------------------------------------------------
; Files-page TreeView structures.
; These keep the same verified Win64 layouts as our standalone TreeView 1.5.
; Large instances such as SHFILEINFOW / WIN32_FIND_DATAW are NOT declared;
; their working memory is allocated from the process heap.
; ---------------------------------------------------------

struct SHFILEINFOW64_LOCAL
  hIcon 	    dq ?
  iIcon 	    dd ?
  dwAttributes	    dd ?
  szDisplayName     rw 260
  szTypeName	    rw 80
ends

struct WIN32_FIND_DATAW_LOCAL
  dwFileAttributes   dd ?
  ftCreationLow      dd ?
  ftCreationHigh     dd ?
  ftAccessLow	     dd ?
  ftAccessHigh	     dd ?
  ftWriteLow	     dd ?
  ftWriteHigh	     dd ?
  nFileSizeHigh      dd ?
  nFileSizeLow	     dd ?
  dwReserved0	     dd ?
  dwReserved1	     dd ?
  cFileName	     rw 260
  cAlternateFileName rw 14
ends

struct TVITEMW64_LOCAL
  mask		    dd ?
  pad0		    dd ?
  hItem 	    dq ?
  state 	    dd ?
  stateMask	    dd ?
  pszText	    dq ?
  cchTextMax	    dd ?
  iImage	    dd ?
  iSelectedImage    dd ?
  cChildren	    dd ?
  lParam	    dq ?
ends

struct TVINSERTSTRUCTW64_LOCAL
  hParent	    dq ?
  hInsertAfter	    dq ?
  item		    TVITEMW64_LOCAL
ends

struct NMTREEVIEWW64_LOCAL
  hdrHwndFrom	    dq ?
  hdrIdFrom	    dq ?
  hdrCode	    dd ?
  hdrPad	    dd ?
  action	    dd ?
  actionPad	    dd ?
  itemOld	    TVITEMW64_LOCAL
  itemNew	    TVITEMW64_LOCAL
  ptDrag	    POINT
ends

  rect		    RECT
  drawRect	    RECT
  msg		    MSG
  ps		    PAINTSTRUCT
  pt		    POINT

  ; Separate paint/layout storage shared by the four dark page children.
  pageRect	    RECT
  pageLayoutRect    RECT
  pagePs	    PAINTSTRUCT

  ; TabControl-subclass paint geometry. These are tiny fixed RECTs, not
  ; large scratch buffers, so they belong naturally in .data.
  tabChromeClient   RECT
  tabChromeDisplay  RECT
  tabChromeRect     RECT
  tabFirstRect	    RECT
  tabLastRect	    RECT
  tabSelectedRect   RECT

  iccEx 	    INITCOMMONCONTROLSEX_LOCAL
  tci		    TCITEMW64_LOCAL

  lvc		    LVCOLUMN64_LOCAL
  lvi		    LVITEM64_LOCAL
  hdi		    HDITEM64_LOCAL
  menuRect	    RECT
  popupMenuInfo     MENUINFO64_LOCAL
  listLayoutRect    RECT
  oldObject	    dq 0
  header_text_buf   rw 64

  tvis		    TVINSERTSTRUCTW64_LOCAL
  tvQuery	    TVITEMW64_LOCAL
  treeLayoutRect    RECT
  projectLayoutRect RECT

  wc WNDCLASSEX sizeof.WNDCLASSEX, CS_HREDRAW + CS_VREDRAW, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE + 1, NULL, _class, NULL

  ; hInstance/hCursor are copied from wc at runtime before registration.
  ; PageProc paints the background, so hbrBackground intentionally stays 0.
  pageWc WNDCLASSEX sizeof.WNDCLASSEX, CS_HREDRAW + CS_VREDRAW, PageProc, 0, 0, NULL, NULL, NULL, NULL, NULL, _pageClass, NULL

  WinX		    dd 0
  WinY		    dd 0
  WinW		    dd 600
  WinH		    dd 430

  CloseBtnX	    dd 0
  MouseX	    dd 0
  MouseY	    dd 0

  hwnd		    dq 0
  lparam	    dq 0
  hdc		    dq 0
  brush 	    dq 0

  pageHdc	    dq 0
  pageBrush	    dq 0

  MainWindow	    dq 0
  hTabControl	    dq 0
  OldTabProc	    dq 0

  hPageOverview     dq 0
  hPageProcesses    dq 0
  hPageFiles	    dq 0
  hPageProject	    dq 0

  hLinkProfile	    dq 0
  hLinkRepositories dq 0

  hTabFont	    dq 0

  hListView	    dq 0
  hProcessFont	    dq 0
  hHeader	    dq 0
  OldHeaderProc     dq 0
  OldSysLinkProc    dq 0
  linkEraseRect     RECT
  hHeaderFont	    dq 0
  hSnapshot	    dq 0

  hTreeView	    dq 0
  hTreeFont	    dq 0
  hProcessHeap	    dq 0

  ; Borrowed Shell system image list; never destroy it.
  hSystemImageList  dq 0
  FolderIconIndex   dd 0
  FileIconIndex     dd 0
  SystemIconsReady  dd 0
  ComInitialized    dd 0

  ; Large scratch memory itself is heap allocated; these are only handles.
  folderScratch     dq 0
  folderFindHandle  dq 0
  hRootItem	    dq 0

  ; Process ListView popup/action state.
  ContextItem	    dd -1
  TargetPid	    dd 0
  LastProcessError  dd 0

  CurrentDpi	    dd 96

  ScaledTitleHeight dd TITLE_HEIGHT_96
  ScaledCloseBtnSize dd CLOSE_BTN_SIZE_96
  ScaledBorderSize  dd BORDER_SIZE_96
  ScaledMargin	    dd MARGIN_96
  ScaledTabFontHeight dd TAB_FONT_HEIGHT_96
  ScaledTreeFontHeight dd TREE_FONT_HEIGHT_96
  ScaledProcessFontHeight dd PROCESS_FONT_HEIGHT_96
  ScaledHeaderFontSize dd HEADER_FONT_SIZE_96



; =========================================================
; Embedded application manifest
; =========================================================
; SysLink is implemented by ComCtl32 version 6. Unlike ListView/TreeView,
; simply importing ComCtl32 is not enough to make the SysLink class available.
; This RT_MANIFEST resource activates version 6 for the whole executable.
; Resource type 24 = RT_MANIFEST, ID 1 = process manifest.
; =========================================================

section '.rsrc' resource data readable

  directory 24, manifests
  resource manifests, 1, 0, app_manifest

  resdata app_manifest
    db '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    db '<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">'
    db '<dependency><dependentAssembly>'
    db '<assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" processorArchitecture="amd64" publicKeyToken="6595b64144ccf1df" language="*"/>'
    db '</dependentAssembly></dependency>'
    db '</assembly>'
  endres


section '.idata' import data readable writeable

  library kernel32, 'KERNEL32.DLL',\
	  user32, 'USER32.DLL',\
	  gdi32, 'GDI32.DLL',\
	  comctl32, 'COMCTL32.DLL',\
	  uxtheme, 'UXTHEME.DLL',\
	  shell32, 'SHELL32.DLL',\
	  ole32, 'OLE32.DLL'

  import uxtheme,\
	 SetWindowTheme, 'SetWindowTheme'

  import shell32,\
	 SHGetFileInfoW, 'SHGetFileInfoW',\
	 ShellExecuteW, 'ShellExecuteW'

  import ole32,\
	 CoInitialize, 'CoInitialize',\
	 CoUninitialize, 'CoUninitialize'

  include 'api\kernel32.inc'
  include 'api\user32.inc'
  include 'api\gdi32.inc'
  include 'api\comctl32.inc'
