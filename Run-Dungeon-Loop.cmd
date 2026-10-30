@echo off
setlocal
if not exist "%~dp0builds\QingYunSect-core-P6-dungeon-loop-win64.exe" (
  echo Missing P6 local build.
  pause
  exit /b 1
)
start "" "%~dp0builds\QingYunSect-core-P6-dungeon-loop-win64.exe"
