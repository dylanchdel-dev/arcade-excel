@echo off
setlocal
chcp 65001 >nul
set "DIR=%~dp0juegos\enemy-territory"
echo === ENEMY TERRITORY / ET: LEGACY ===
echo Carpeta esperada: %DIR%
if exist "%DIR%\etl.exe" (echo [OK] Motor etl.exe) else (echo [FALTA] etl.exe - descargalo de https://www.etlegacy.com/download)
for %%F in (pak0.pk3 pak1.pk3 pak2.pk3) do (
  if exist "%DIR%\etmain\%%F" (echo [OK] %%F) else (echo [FALTA] %%F - usa el instalador oficial ET:Legacy o datos originales autorizados)
)
echo.
echo Los paquetes Windows oficiales vienen como instalador o archivo comprimido.
echo Si usas el archivo comprimido, extraelo en juegos\enemy-territory y agrega los PK3 en etmain.
echo No copies datos desde sitios no oficiales.
pause
