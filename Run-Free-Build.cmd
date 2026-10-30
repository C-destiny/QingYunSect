@echo off
setlocal
if not exist "%~dp0builds\QingYunSect-core-P1-free-build-win64.exe" (
  echo Missing local build: builds\QingYunSect-core-P1-free-build-win64.exe
  echo See docs\CORE_P1_FREE_BUILD.md
  pause
  exit /b 1
)
start "" "%~dp0builds\QingYunSect-core-P1-free-build-win64.exe"
