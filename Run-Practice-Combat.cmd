@echo off
setlocal
if not exist "%~dp0builds\QingYunSect-core-P4-practice-win64.exe" (
  echo Missing P4 local build.
  pause
  exit /b 1
)
start "" "%~dp0builds\QingYunSect-core-P4-practice-win64.exe"
