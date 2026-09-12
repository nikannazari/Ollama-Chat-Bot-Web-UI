@echo off
setlocal EnableExtensions

REM ==========================================
REM ChatBot - Windows Uninstaller
REM ==========================================

title ChatBot - Uninstallation

set "APP_NAME=ChatBot"
set "INSTALL_DIR=%LOCALAPPDATA%\ChatBot"
set "COMMAND_PATH=%LOCALAPPDATA%\Microsoft\WindowsApps\ChatBot.bat"

cls

echo ==========================================
echo          ChatBot Uninstallation
echo ==========================================
echo.

echo This will remove:

echo %INSTALL_DIR%
echo %COMMAND_PATH%
echo.

echo Warning:
echo Installed bots and generated files will also be removed.
echo.

choice /M "Continue uninstallation"

if errorlevel 2 (
    echo Uninstallation cancelled.
    exit /b 0
)

echo.
echo Removing global command...

if exist "%COMMAND_PATH%" (
    del /F /Q "%COMMAND_PATH%"
)

echo Removing installed project...

if exist "%INSTALL_DIR%" (
    rmdir /S /Q "%INSTALL_DIR%"
)

echo.
echo ==========================================
echo      ChatBot Uninstalled Successfully
echo ==========================================
echo.

pause
endlocal
exit /b 0