@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ==========================================
REM ChatBot - Windows Installer
REM ==========================================

title ChatBot - Installation

REM ==========================================
REM Configuration
REM ==========================================

set "SOURCE_DIR=%~dp0"
set "SOURCE_DIR=%SOURCE_DIR:~0,-1%"

set "APP_NAME=ChatBot"
set "INSTALL_DIR=%LOCALAPPDATA%\ChatBot"
set "COMMAND_DIR=%LOCALAPPDATA%\Microsoft\WindowsApps"
set "COMMAND_PATH=%COMMAND_DIR%\ChatBot.bat"

set "VENV_DIR=%INSTALL_DIR%\.venv"
set "PYTHON_BIN=%VENV_DIR%\Scripts\python.exe"

REM ==========================================
REM Startup
REM ==========================================

cls

echo ==========================================
echo          ChatBot Installation
echo ==========================================
echo.

echo Source directory:
echo %SOURCE_DIR%
echo.

echo Install directory:
echo %INSTALL_DIR%
echo.

echo Command:
echo ChatBot
echo.

REM ==========================================
REM Validation
REM ==========================================

if not exist "%SOURCE_DIR%\requirements.txt" (
    echo ERROR: requirements.txt was not found.
    pause
    exit /b 1
)

if not exist "%SOURCE_DIR%\app\streamlit_app.py" (
    echo ERROR: app\streamlit_app.py was not found.
    pause
    exit /b 1
)

where python >nul 2>&1

if errorlevel 1 (
    echo ERROR: Python was not found in PATH.
    echo Install Python and enable "Add Python to PATH".
    pause
    exit /b 1
)

echo This will install ChatBot into:
echo %INSTALL_DIR%
echo.

choice /M "Continue installation"

if errorlevel 2 (
    echo Installation cancelled.
    exit /b 0
)

REM ==========================================
REM Remove Old Installation
REM ==========================================

if exist "%INSTALL_DIR%" (
    echo Removing old installation...
    rmdir /S /Q "%INSTALL_DIR%"
)

REM ==========================================
REM Create Installation Directory
REM ==========================================

echo Creating installation directory...

mkdir "%INSTALL_DIR%"

REM ==========================================
REM Copy Project
REM ==========================================

echo Copying project files...

xcopy "%SOURCE_DIR%\app" "%INSTALL_DIR%\app" /E /I /Y >nul

if exist "%SOURCE_DIR%\src" (
    xcopy "%SOURCE_DIR%\src" "%INSTALL_DIR%\src" /E /I /Y >nul
)

if exist "%SOURCE_DIR%\bots" (
    xcopy "%SOURCE_DIR%\bots" "%INSTALL_DIR%\bots" /E /I /Y >nul
)

if exist "%SOURCE_DIR%\generated" (
    xcopy "%SOURCE_DIR%\generated" "%INSTALL_DIR%\generated" /E /I /Y >nul
)

copy /Y "%SOURCE_DIR%\requirements.txt" "%INSTALL_DIR%\requirements.txt" >nul

if exist "%SOURCE_DIR%\.env.example" (
    copy /Y "%SOURCE_DIR%\.env.example" "%INSTALL_DIR%\.env.example" >nul
)

REM ==========================================
REM Create Virtual Environment
REM ==========================================

echo.
echo Creating Python virtual environment...

python -m venv "%VENV_DIR%"

if errorlevel 1 (
    echo ERROR: Could not create virtual environment.
    pause
    exit /b 1
)

REM ==========================================
REM Install Dependencies
REM ==========================================

echo.
echo Upgrading pip...

"%PYTHON_BIN%" -m pip install --upgrade pip

if errorlevel 1 (
    echo ERROR: Could not upgrade pip.
    pause
    exit /b 1
)

echo.
echo Installing dependencies...

"%PYTHON_BIN%" -m pip install -r "%INSTALL_DIR%\requirements.txt"

if errorlevel 1 (
    echo ERROR: Could not install dependencies.
    pause
    exit /b 1
)

REM ==========================================
REM Create Command Directory
REM ==========================================

if not exist "%COMMAND_DIR%" (
    mkdir "%COMMAND_DIR%"
)

REM ==========================================
REM Create Global Launcher
REM ==========================================

echo.
echo Creating ChatBot command...

(
    echo @echo off
    echo setlocal EnableExtensions EnableDelayedExpansion
    echo title ChatBot
    echo.
    echo set "INSTALL_DIR=%INSTALL_DIR%"
    echo set "PYTHON_BIN=%%INSTALL_DIR%%\.venv\Scripts\python.exe"
    echo set "STREAMLIT_APP=%%INSTALL_DIR%%\app\streamlit_app.py"
    echo set "OLLAMA_LOG=%%TEMP%%\chatbot-ollama.log"
    echo set "STREAMLIT_LOG=%%TEMP%%\chatbot-streamlit.log"
    echo.
    echo if not exist "%%PYTHON_BIN%%" ^(
    echo     echo ERROR: Python virtual environment not found.
    echo     echo %%PYTHON_BIN%%
    echo     exit /b 1
    echo ^)
    echo.
    echo where ollama ^>nul 2^>^&1
    echo if errorlevel 1 ^(
    echo     echo ERROR: Ollama was not found in PATH.
    echo     exit /b 1
    echo ^)
    echo.
    echo echo Starting Ollama...
    echo tasklist /FI "IMAGENAME eq ollama.exe" 2^>NUL ^| find /I "ollama.exe" ^>NUL
    echo.
    echo if errorlevel 1 ^(
    echo     start "ChatBot - Ollama" /B cmd /c "ollama serve ^> \"%%OLLAMA_LOG%%\" 2^>^&1"
    echo     timeout /t 3 /nobreak ^>nul
    echo ^) else ^(
    echo     echo Ollama is already running.
    echo ^)
    echo.
    echo echo Starting Streamlit...
    echo cd /d "%%INSTALL_DIR%%"
    echo start "ChatBot - Streamlit" /B cmd /c ""%%PYTHON_BIN%%" -m streamlit run "%%STREAMLIT_APP%%" ^> "%%STREAMLIT_LOG%%" 2^>^&1"
    echo.
    echo timeout /t 4 /nobreak ^>nul
    echo.
    echo echo.
    echo echo ==========================================
    echo echo            ChatBot Running
    echo echo ==========================================
    echo echo.
    echo echo Streamlit log: %%STREAMLIT_LOG%%
    echo echo Ollama log: %%OLLAMA_LOG%%
    echo echo.
    echo echo Type q and press Enter to stop.
    echo echo Press Ctrl+C to close.
    echo.
    echo :COMMAND_LOOP
    echo set "USER_COMMAND="
    echo set /p "USER_COMMAND=ChatBot^> "
    echo.
    echo if /I "%%USER_COMMAND%%"=="q" goto STOP
    echo if /I "%%USER_COMMAND%%"=="quit" goto STOP
    echo if /I "%%USER_COMMAND%%"=="exit" goto STOP
    echo.
    echo echo Unknown command. Use q, quit, exit, or Ctrl+C.
    echo goto COMMAND_LOOP
    echo.
    echo :STOP
    echo echo.
    echo echo Stopping ChatBot...
    echo taskkill /FI "WINDOWTITLE eq ChatBot - Streamlit*" /T /F ^>nul 2^>^&1
    echo taskkill /FI "WINDOWTITLE eq ChatBot - Ollama*" /T /F ^>nul 2^>^&1
    echo echo ChatBot stopped.
    echo endlocal
) > "%COMMAND_PATH%"

REM ==========================================
REM Finished
REM ==========================================

echo.
echo ==========================================
echo       ChatBot Installed Successfully
echo ==========================================
echo.
echo Installed at:
echo %INSTALL_DIR%
echo.
echo Command:
echo ChatBot
echo.
echo Launcher:
echo %COMMAND_PATH%
echo.
echo You can now open a new CMD or PowerShell
echo window and run:
echo.
echo ChatBot
echo.

pause
endlocal
exit /b 0