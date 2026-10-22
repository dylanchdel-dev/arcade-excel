@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALAR_FREEDOOM_AMBOS.ps1"
if errorlevel 1 (echo La instalacion no se completo. & pause & exit /b 1)
pause
