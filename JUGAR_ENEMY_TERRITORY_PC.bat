@echo off
setlocal
set "ROOT=%~dp0juegos\enemy-territory"
if not exist "%ROOT%\etl.exe" (
 echo No se encontro etl.exe. Descarga la distribucion Windows de https://www.etlegacy.com/download
 pause
 exit /b 1
)
if not exist "%ROOT%\etmain\pak0.pk3" (
 echo Faltan los datos originales pak0.pk3 en etmain. Consulta juegos\enemy-territory\LEEME.txt
 pause
 exit /b 1
)
pushd "%ROOT%"
start "Enemy Territory" "etl.exe"
popd
