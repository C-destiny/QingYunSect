@echo off
setlocal
if not exist "%~dp0builds\QingYunSect-core-P3-ordinary-preparation-win64.exe" (
  echo Missing local build: builds\QingYunSect-core-P3-ordinary-preparation-win64.exe
  echo See docs\CORE_P3_ORDINARY_PREPARATION.md
  pause
  exit /b 1
)
start "" "%~dp0builds\QingYunSect-core-P3-ordinary-preparation-win64.exe"
