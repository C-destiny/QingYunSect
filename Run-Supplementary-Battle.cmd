@echo off
setlocal
if not exist "%~dp0builds\QingYunSect-core-P6-supplementary-win64.exe" (
  echo Missing local build: builds\QingYunSect-core-P6-supplementary-win64.exe
  echo See docs\CORE_P7_CONTENT.md
  pause
  exit /b 1
)
start "" "%~dp0builds\QingYunSect-core-P6-supplementary-win64.exe"
