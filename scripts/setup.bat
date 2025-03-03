@echo off
:: Windows 11 Setup Script for RTX 3070 v1.13
:: Requires PowerShell 7+ and NVIDIA Driver 535+

set LOG_DIR=logs\windows
set PYTHON_URL=https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe
set CUDA_URL=https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_516.94_windows.exe
set TORCH_URL=https://download.pytorch.org/whl/cu117/torch-2.0.1%2Bcu117-cp310-cp310-win_amd64.whl
set FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip

mkdir %LOG_DIR% 2> nul
call :main > %LOG_DIR%\setup.log 2>&1
exit /b

:main
echo [INFO] Starting RTX 3070-optimized setup

:: Verify NVIDIA Driver
echo [STEP 1/6] Checking NVIDIA drivers
nvidia-smi | find "516." > nul || (
    echo [ERROR] Requires NVIDIA Driver 516.x+
    exit /b 1
)

:: Install Python 3.10 with PATH
echo [STEP 2/6] Installing Python 3.10
powershell -Command "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile 'python_installer.exe'"
python_installer.exe /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
del python_installer.exe

:: Install CUDA 11.7
echo [STEP 3/6] Installing CUDA 11.7
powershell -Command "Invoke-WebRequest -Uri '%CUDA_URL%' -OutFile 'cuda_installer.exe'"
cuda_installer.exe -s nvcc_11.7 cudart_11.7 cublas_dev_11.7
del cuda_installer.exe

:: Install FFmpeg
echo [STEP 4/6] Installing FFmpeg
powershell -Command "Expand-Archive -Path ffmpeg.zip -DestinationPath 'C:\Program Files\ffmpeg'"
setx PATH "C:\Program Files\ffmpeg\bin;%PATH%"

:: Create virtual environment
echo [STEP 5/6] Setting up Python environment
python -m venv .venv
call .venv\Scripts\activate.bat

:: Install optimized packages
echo [STEP 6/6] Installing AI components
pip install --no-cache-dir numpy==1.23.5 %TORCH_URL%
pip install --no-cache-dir "torchaudio==2.0.2+cu117" "torchvision==0.15.2+cu117"
pip install --no-cache-dir pydub==0.25.1 whisper-large-v3==1.1.7

:: Final verification
python -c "import torch; assert torch.cuda.get_device_capability()[0] >= 8.6" || (
    echo [ERROR] CUDA acceleration check failed
    exit /b 1
)

echo [SUCCESS] RTX 3070 environment ready
exit /b 0
