@echo off
setlocal
if not exist "%~dp0builds\QingYunSect-v0.8-complete29-win64.exe" (
  echo Missing local build: builds\QingYunSect-v0.8-complete29-win64.exe
  echo See docs\V0.8_COMPLETE_SECT29.md
  pause
  exit /b 1
)
start "" "%~dp0builds\QingYunSect-v0.8-complete29-win64.exe"
