@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ==========================================
REM ChatBot - Development Runner
REM ==========================================

title ChatBot - Development

REM ==========================================
REM Project Paths
REM ==========================================

set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

set "APP_DIR=%PROJECT_DIR%\app"
set "APP_FILE=%APP_DIR%\streamlit_app.py"
set "VENV_DIR=%PROJECT_DIR%\.venv"

set "PYTHON_BIN=%VENV_DIR%\Scripts\python.exe"

set "OLLAMA_LOG=%TEMP%\chatbot-ollama.log"
set "STREAMLIT_LOG=%TEMP%\chatbot-streamlit.log"

set "OLLAMA_PID="
set "STREAMLIT_PID="

REM ==========================================
REM Startup
REM ==========================================

cls

echo ==========================================
echo              ChatBot
echo ==========================================
echo.

echo Project directory:
echo %PROJECT_DIR%
echo.

REM ==========================================
REM Validation
REM ==========================================

if not exist "%APP_FILE%" (
    echo ERROR: Streamlit application not found:
    echo %APP_FILE%
    echo.
    pause
    exit /b 1
)

if not exist "%PYTHON_BIN%" (
    echo ERROR: Python virtual environment not found:
    echo %VENV_DIR%
    echo.
    echo Create it with:
    echo python -m venv .venv
    echo .venv\Scripts\python.exe -m pip install -r requirements.txt
    echo.
    pause
    exit /b 1
)

where ollama >nul 2>&1

if errorlevel 1 (
    echo ERROR: Ollama was not found in PATH.
    echo Install Ollama first.
    echo.
    pause
    exit /b 1
)

REM ==========================================
REM Ollama
REM ==========================================

echo Checking Ollama...

tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I "ollama.exe" >NUL

if not errorlevel 1 (
    echo Ollama is already running.
) else (
    echo Starting Ollama...

    start "ChatBot - Ollama" /B cmd /c "ollama serve > "%OLLAMA_LOG%" 2>&1"

    timeout /t 3 /nobreak >nul

    tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I "ollama.exe" >NUL

    if errorlevel 1 (
        echo ERROR: Ollama failed to start.
        echo.
        if exist "%OLLAMA_LOG%" (
            type "%OLLAMA_LOG%"
        )
        pause
        exit /b 1
    )

    echo Ollama started.
)

echo.

REM ==========================================
REM Streamlit
REM ==========================================

echo Starting Streamlit...

cd /d "%APP_DIR%"

start "ChatBot - Streamlit" /B cmd /c ""%PYTHON_BIN%" -m streamlit run "%APP_FILE%" > "%STREAMLIT_LOG%" 2>&1"

timeout /t 4 /nobreak >nul

tasklist /FI "IMAGENAME eq python.exe" 2>NUL | find /I "python.exe" >NUL

if errorlevel 1 (
    echo ERROR: Streamlit may have failed to start.
    echo.
    if exist "%STREAMLIT_LOG%" (
        type "%STREAMLIT_LOG%"
    )
    pause
    exit /b 1
)

REM ==========================================
REM Running Information
REM ==========================================

echo.
echo ==========================================
echo            ChatBot Running
echo ==========================================
echo.
echo Project:
echo %PROJECT_DIR%
echo.
echo Streamlit log:
echo %STREAMLIT_LOG%
echo.
echo Ollama log:
echo %OLLAMA_LOG%
echo.
echo Press Ctrl+C to close this runner.
echo Type q and press Enter to stop ChatBot.
echo.

:COMMAND_LOOP

set "USER_COMMAND="

set /p "USER_COMMAND=ChatBot^> "

if /I "%USER_COMMAND%"=="q" goto STOP
if /I "%USER_COMMAND%"=="quit" goto STOP
if /I "%USER_COMMAND%"=="exit" goto STOP

echo Unknown command. Use q, quit, exit, or Ctrl+C.
goto COMMAND_LOOP

REM ==========================================
REM Stop
REM ==========================================

:STOP

echo.
echo Stopping ChatBot...

REM Stop Streamlit Python processes.
REM Warning: this stops Python processes started under this user.
taskkill /FI "WINDOWTITLE eq ChatBot - Streamlit*" /T /F >nul 2>&1

REM Stop Ollama only if it was started by this script.
REM Because Windows does not provide a simple reliable PID here,
REM we close the dedicated Ollama console window.
taskkill /FI "WINDOWTITLE eq ChatBot - Ollama*" /T /F >nul 2>&1

echo ChatBot stopped.
echo.

endlocal
exit /b 0