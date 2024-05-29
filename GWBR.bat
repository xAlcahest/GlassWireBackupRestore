@echo off
setlocal enabledelayedexpansion

rem Titolo della TUI
title GLASSWIRE DATABASE EXPORTER

rem Percorso dello script
set SCRIPT_DIR=%~dp0

rem Percorsi dei database GlassWire
set GW_PROGRAMDATA=C:\ProgramData\GlassWire
set GW_USERDATA=%USERPROFILE%\AppData\Local\GlassWire
set GW_DB_CONF=C:\ProgramData\GlassWire\service\glasswire.conf

rem Nome del file zip
set ZIP_NAME=glasswire_backup.zip

rem Menu TUI
:MENU
cls
echo GLASSWIRE DATABASE EXPORTER:
echo.
echo Che azione vuoi intraprendere?
echo [1] Esportazione del database (ZIP)
echo [2] Importazione del database
echo [3] Esci
echo.
set /p choice=Inserisci la tua scelta (1, 2 o 3): 

if "%choice%"=="1" goto EXPORT
if "%choice%"=="2" goto IMPORT
if "%choice%"=="3" goto EXIT
goto MENU

rem Esportazione del database
:EXPORT
cls
echo Esportazione del database in corso...
if exist "%SCRIPT_DIR%%ZIP_NAME%" del "%SCRIPT_DIR%%ZIP_NAME%"
rem Creazione delle cartelle temporanee per il backup
mkdir "%SCRIPT_DIR%GlassWireBackup\ProgramData\"
mkdir "%SCRIPT_DIR%GlassWireBackup\UserData\"
xcopy "%GW_PROGRAMDATA%" "%SCRIPT_DIR%GlassWireBackup\ProgramData\" /E /I /Y
xcopy "%GW_USERDATA%" "%SCRIPT_DIR%GlassWireBackup\UserData\" /E /I /Y
rem Verifica se esiste il file di configurazione per il database
if exist "%GW_DB_CONF%" (
    for /F "tokens=2 delims==" %%A in ('findstr DbStorageDirectory "%GW_DB_CONF%"') do set DB_LOCATION=%%A
    if defined DB_LOCATION (
        mkdir "%SCRIPT_DIR%GlassWireBackup\Database\"
        xcopy "!DB_LOCATION!" "%SCRIPT_DIR%GlassWireBackup\Database\" /E /I /Y
    )
)
rem Creazione del file ZIP
powershell Compress-Archive -Path "%SCRIPT_DIR%GlassWireBackup\*" -DestinationPath "%SCRIPT_DIR%%ZIP_NAME%"
rem Pulizia delle cartelle temporanee
rd /s /q "%SCRIPT_DIR%GlassWireBackup"
echo Esportazione completata. File salvato in: %SCRIPT_DIR%%ZIP_NAME%
pause
goto MENU

rem Importazione del database
:IMPORT
cls
echo Importazione del database in corso...
if not exist "%SCRIPT_DIR%%ZIP_NAME%" (
    echo File di backup non trovato: %SCRIPT_DIR%%ZIP_NAME%
    pause
    goto MENU
)
rem Estrazione del file ZIP
powershell Expand-Archive -Path "%SCRIPT_DIR%%ZIP_NAME%" -DestinationPath "%SCRIPT_DIR%GlassWireRestore\"
rem Rimozione delle cartelle esistenti
rd /s /q "%GW_PROGRAMDATA%"
rd /s /q "%GW_USERDATA%"
rem Ripristino delle cartelle
rename "%SCRIPT_DIR%GlassWireRestore\ProgramData\GlassWire" "GlassWire"
rename "%SCRIPT_DIR%GlassWireRestore\UserData\GlassWire" "GlassWire"
move "%SCRIPT_DIR%GlassWireRestore\ProgramData\GlassWire" "%GW_PROGRAMDATA%"
move "%SCRIPT_DIR%GlassWireRestore\UserData\GlassWire" "%GW_USERDATA%"
if exist "%SCRIPT_DIR%GlassWireRestore\Database\" (
    for /F "tokens=2 delims==" %%A in ('findstr DbStorageDirectory "%GW_DB_CONF%"') do set DB_LOCATION=%%A
    if defined DB_LOCATION (
        move "%SCRIPT_DIR%GlassWireRestore\Database\"* "!DB_LOCATION!"
    )
)
rem Pulizia delle cartelle temporanee
rd /s /q "%SCRIPT_DIR%GlassWireRestore"
echo Importazione completata.
pause
goto MENU

:EXIT
exit /b
