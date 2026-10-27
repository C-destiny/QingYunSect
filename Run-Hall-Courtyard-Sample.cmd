@echo off
setlocal
if not exist "%~dp0builds\QingYunSect-v0.8-unified28-win64.exe" (
  echo Missing local build: builds\QingYunSect-v0.8-unified28-win64.exe
  echo See docs/V0.8_UNIFIED_COURTYARD28.md for details.
  pause
  exit /b 1
)
start "" "%~dp0builds\QingYunSect-v0.8-unified28-win64.exe" -- --unified-courtyard-sample
