@echo off
:: Windows Setup Script v1.16 (Verbose)
setlocal enabledelayedexpansion

set LOG_DIR=logs\windows
set LOG_FILE=%LOG_DIR%\setup-%DATE%-%TIME%.log
set PYTHON_URL=https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe
set CUDA_URL=https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_516.94_windows.exe

mkdir "%LOG_DIR%" 2> nul

call :main %*
exit /b

:main
echo [%DATE% %TIME%] === Starting Setup === >> "%LOG_FILE%"

:: Check admin privileges
echo [%DATE% %TIME%] Checking administrator privileges... >> "%LOG_FILE%"
net session >nul 2>&1 || (
    echo [ERROR] Please run as Administrator >> "%LOG_FILE%"
    echo "❌ Run this script as Administrator (right-click > Run as Administrator)"
    timeout /t 5
    exit /b 1
)

:: Install Python with verbose logging
echo [%DATE% %TIME%] Starting Python installation... >> "%LOG_FILE%"
echo Installing Python 3.10...
powershell -Command "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile 'python_installer.exe'" >> "%LOG_FILE%" 2>&1 || (
    echo [ERROR] Python download failed >> "%LOG_FILE%"
    exit /b 1
)

start /wait python_installer.exe /passive InstallAllUsers=0 PrependPath=1 Include_test=0 >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Python installation failed (code %ERRORLEVEL%) >> "%LOG_FILE%"
    exit /b 1
)
del python_installer.exe

:: Verify Python installation
echo [%DATE% %TIME%] Verifying Python... >> "%LOG_FILE%"
python --version >> "%LOG_FILE%" 2>&1 || (
    echo [ERROR] Python not in PATH >> "%LOG_FILE%"
    exit /b 1
)

:: Install CUDA Toolkit
echo [%DATE% %TIME%] Starting CUDA installation... >> "%LOG_FILE%"
echo Installing CUDA 11.7...
powershell -Command "Invoke-WebRequest -Uri '%CUDA_URL%' -OutFile 'cuda_installer.exe'" >> "%LOG_FILE%" 2>&1 || (
    echo [ERROR] CUDA download failed >> "%LOG_FILE%"
    exit /b 1
)

start /wait cuda_installer.exe -s nvcc_11.7 cudart_11.7 cublas_dev_11.7 >> "%LOG_FILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] CUDA installation failed (code %ERRORLEVEL%) >> "%LOG_FILE%"
    exit /b 1
)
del cuda_installer.exe

:: Create virtual environment
echo [%DATE% %TIME%] Creating Python environment... >> "%LOG_FILE%"
echo Creating virtual environment...
python -m venv .venv >> "%LOG_FILE%" 2>&1 || (
    echo [ERROR] venv creation failed >> "%LOG_FILE%"
    exit /b 1
)

:: Install packages with detailed output
echo [%DATE% %TIME%] Installing Python packages... >> "%LOG_FILE%"
call .venv\Scripts\activate.bat
echo Installing requirements...
pip install -v --no-cache-dir numpy==1.23.5 torch==2.0.1+cu117 -f https://download.pytorch.org/whl/cu117/torch_stable.html >> "%LOG_FILE%" 2>&1 || (
    echo [ERROR] Package installation failed >> "%LOG_FILE%"
    exit /b 1
)

:: Final verification
echo [%DATE% %TIME%] Running final checks... >> "%LOG_FILE%"
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')" >> "%LOG_FILE%" 2>&1 || (
    echo [ERROR] CUDA verification failed >> "%LOG_FILE%"
    exit /b 1
)

echo [%DATE% %TIME%] Setup completed successfully >> "%LOG_FILE%"
echo "✅ Setup completed! Log saved to %LOG_FILE%"
timeout /t 10
exit /b 0
