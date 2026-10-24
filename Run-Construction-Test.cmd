@echo off
setlocal
if not exist "%~dp0builds\QingYunSect-v0.8-material24-win64.exe" (
  echo Missing local build: builds\QingYunSect-v0.8-material24-win64.exe
  echo See docs/V0.8_NEAR_MATERIAL24.md for build instructions.
  pause
  exit /b 1
)
start "" "%~dp0builds\QingYunSect-v0.8-material24-win64.exe" -- --fixed-layout-demo
