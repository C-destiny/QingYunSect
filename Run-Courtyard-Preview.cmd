@echo off
setlocal
if not exist "%~dp0builds\QingYunSect-v0.8-garden17-win64.exe" (
  echo Missing local build: builds\QingYunSect-v0.8-garden17-win64.exe
  echo See docs/V0.8_GARDEN_REDESIGN.md for build instructions.
  pause
  exit /b 1
)
start "" "%~dp0builds\QingYunSect-v0.8-garden17-win64.exe" -- --fixed-layout-showcase
