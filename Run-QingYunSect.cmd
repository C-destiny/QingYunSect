@echo off
setlocal
if not exist "%~dp0builds\QingYunSect-core-P8-delivery-win64.exe" (
  echo Missing local build: builds\QingYunSect-core-P8-delivery-win64.exe
  echo See docs\CORE_P8_DELIVERY.md
  pause
  exit /b 1
)
start "" "%~dp0builds\QingYunSect-core-P8-delivery-win64.exe"
