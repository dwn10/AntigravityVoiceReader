@echo off
title Instalador / Installer / Installationsprogramm - Antigravity Voice Reader
echo.
echo ===================================================================
echo   Instalador de Acceso Directo / Shortcut Installer / Verknuepfung
echo   Antigravity Voice Reader (ES / DE / EN)
echo ===================================================================
echo.

:: Obtener la ruta actual donde se descargo el proyecto
set "SCRIPT_DIR=%~dp0"
set "TARGET=%SCRIPT_DIR%Lector.bat"
set "SHORTCUT_NAME=Antigravity Voice Reader.lnk"

:: Ejecutar PowerShell para crear el acceso directo en el Escritorio
powershell -NoProfile -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\%SHORTCUT_NAME%'); $Shortcut.TargetPath = '%TARGET%'; $Shortcut.WorkingDirectory = '%SCRIPT_DIR%'; $Shortcut.IconLocation = '%TARGET%'; $Shortcut.Save()"

echo -------------------------------------------------------------------
echo  [ESPANOL]
echo  [EXITO] Acceso directo "%SHORTCUT_NAME%" creado en tu Escritorio.
echo  Ya puedes iniciar el programa desde tu escritorio sin abrir esta carpeta.
echo.
echo  [DEUTSCH]
echo  [ERFOLG] Verknuepfung "%SHORTCUT_NAME%" auf dem Desktop erstellt.
echo  Du kannst das Programm nun direkt von deinem Desktop aus starten.
echo.
echo  [ENGLISH]
echo  [SUCCESS] Shortcut "%SHORTCUT_NAME%" created on your Desktop.
echo  You can now launch the program directly from your desktop.
echo -------------------------------------------------------------------
echo.
echo Presiona cualquier tecla para salir / Taste druecken / Press any key...
pause >nul
