# FASM-Win64-Controls

Native Win64 GUI control examples written in pure FASM x64.

This repository is a learning/reference project built around native Win32 controls. The examples are intentionally self-contained and heavily commented so each source can be studied on its own.

## Project goals

- Pure FASM x64 and native Win32 APIs
- Prefer Unicode `W` APIs and messages
- Respect the Windows x64 calling convention
- Per-Monitor DPI-aware examples
- Native dark-theme/custom-draw techniques where practical
- Explain *why* Windows behaves the way it does, not only what code to write
- Keep each important learning step as a separate working example

## Controls

### ListBox

#### ListBox 1.7 — EOF File Report — Dynamic Box Width

[`ListBox/ListBox_1.7_EOF_DYNAMIC_BOX.ASM`](ListBox/ListBox_1.7_EOF_DYNAMIC_BOX.ASM)

A practical ListBox showcase built from the earlier control lessons. Drop one file onto the window and the ListBox becomes a dark, scrollable report surface showing file information and basic PE information.

Highlights:

- Native Unicode `LISTBOX`
- `LBS_OWNERDRAWFIXED` + `LBS_HASSTRINGS`
- `LBS_NOSEL` for a display-only report surface
- Dark owner-drawn rows with a DPI-scaled Consolas font
- Thin Unicode box-drawing characters
- Drag-and-drop through `WM_DROPFILES`
- 64-bit file size and local timestamps
- Defensive MZ / PE validation
- PE32 / PE32+ architecture, executable/DLL type, and section count
- Dynamic report width based on the full file path
- `LB_SETHORIZONTALEXTENT` for horizontal scrolling when needed
- Heap-allocated scratch buffers when report rows can exceed the project's static-buffer limit

Real EOF/overlay detection is intentionally left for the next evolution.

### TabControl

#### TabControl 1.6.4 — Integrated Controls + Project Links

[`TabControl/TabControl_1.6.4_PROJECT_LINK_FIX.ASM`](TabControl/TabControl_1.6.4_PROJECT_LINK_FIX.ASM)

A larger native TabControl example with four real page windows: Overview, Processes, Files, and Project.

Highlights:

- Native `SysTabControl32` with `TCS_OWNERDRAWFIXED`
- Dark owner-drawn tab headers
- TabControl subclass that covers native light-theme chrome while preserving native selection, keyboard, hit testing, and layout behavior
- Real Processes page with the process ListView, DPI-scaled body/header fonts, dark custom draw, and context menu
- Real Files page with the lazy filesystem TreeView and borrowed Shell system icons
- Project page using native ComCtl32 v6 `SysLink` controls
- Working GitHub profile and repositories links through `ShellExecuteW`
- DPI-scaled Project-link alignment with the page text
- Deferred `WM_EXITSIZEMOVE` redraw of the nested Processes page/ListView/Header after interactive resize
- Per-Monitor V2 DPI handling

---

More native Win64 control examples will be added as the project grows.
