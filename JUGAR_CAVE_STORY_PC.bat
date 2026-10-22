@echo off
cd /d "%~dp0"
set "ROOT=%~dp0juegos\cave-story"
for /r "%ROOT%" %%F in (Doukutsu.exe) do (
  if exist "%%~fF" (
    start "Cave Story" /D "%%~dpF" "%%~fF"
    exit /b 0
  )
)
echo Cave Story no esta instalado. Ejecuta INSTALAR_CAVE_STORY.bat primero.
pause
