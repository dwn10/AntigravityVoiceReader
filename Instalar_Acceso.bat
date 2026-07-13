@echo off
title Instalador Antigravity Voice Reader
echo.
echo ========================================================
echo   Instalando Acceso Directo de Antigravity Voice Reader
echo ========================================================
echo.

:: Obtener la ruta actual donde se descargo el proyecto
set "SCRIPT_DIR=%~dp0"
set "TARGET=%SCRIPT_DIR%Lector.bat"
set "SHORTCUT_NAME=Antigravity Voice Reader.lnk"

:: Ejecutar PowerShell para crear el acceso directo en el Escritorio
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\%SHORTCUT_NAME%'); $Shortcut.TargetPath = '%TARGET%'; $Shortcut.WorkingDirectory = '%SCRIPT_DIR%'; $Shortcut.IconLocation = '%TARGET%'; $Shortcut.Save()"

echo [EXITO] Acceso directo "%SHORTCUT_NAME%" creado en tu Escritorio.
echo.
echo Ya puedes iniciar el programa desde tu escritorio sin tener que abrir esta carpeta.
echo Presiona cualquier tecla para salir...
pause >nul
