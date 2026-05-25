# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the App

Always launch via the VBScript wrapper — it hides the console window:
```
wscript start_pomodoro.vbs
```

Direct execution (console visible):
```
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File pomodoro.ps1
```

`-ExecutionPolicy Bypass` is required; the default policy blocks unsigned scripts.

## Architecture

Single-file PowerShell GUI app using System.Windows.Forms. State is held in `$script:`-scoped variables. The timer fires every 1000ms; when `$script:timeLeft` reaches 0 it auto-advances the mode.

Session cycle: 4 × work (25 min) → long break (15 min); between work sessions: short break (5 min).

## Code Conventions

**Unicode for UI strings** — all Chinese labels are built from `[char]0xXXXX` codes, not string literals. This avoids file-encoding issues. Follow this pattern when adding or editing any UI text.

**Color palette** — Catppuccin Mocha; constants are defined at the top of `pomodoro.ps1`. Do not hardcode RGB values inline; use or extend the existing constants.

**Variable naming** — camelCase for variables, UPPER_SNAKE_CASE for constants (e.g., `$WORK_SEC`, `$MAX_SESSIONS`).

**Double buffering** — intentionally enabled on the form and circle panel to prevent flicker. Do not remove it.

## Keyboard Shortcuts

Space → play/pause, R → reset, N → skip to next mode. These are wired in the `KeyDown` handler.
