@echo off
setlocal
if not exist "%~dp0builds\QingYunSect-core-P5-single-run-win64.exe" (
  echo Missing P5 local build.
  pause
  exit /b 1
)
start "" "%~dp0builds\QingYunSect-core-P5-single-run-win64.exe"
