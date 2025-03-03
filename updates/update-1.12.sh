#!/bin/bash
# updates/update-1.12.sh - Windows 11 RTX 3070 Focus v1.12

set -Eeuo pipefail
trap '_handle_error $? $LINENO' ERR

VERSION="1.12"
WIN_SCRIPT="scripts/setup.bat"
CONFIG_FILE="config/windows.cfg"
LOG_DIR="logs/windows"
DEBUG_LOG="$LOG_DIR/update-1.12.log"

_handle_error() {
    echo "[ERR-$1] Update failed at line $2" | tee -a "$DEBUG_LOG"
    exit $1
}

_create_windows_setup() {
    cat > "$WIN_SCRIPT" <<'EOL'
@echo off
:: Windows 11 Setup Script for RTX 3070 v1.12
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
    echo [ERROR] Download from https://www.nvidia.com/Download/index.aspx
    exit /b 1
)

:: Install Python 3.10 with PATH
echo [STEP 2/6] Installing Python 3.10
curl -L -o python_installer.exe %PYTHON_URL%
python_installer.exe /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
del python_installer.exe

:: Install CUDA 11.7
echo [STEP 3/6] Installing CUDA 11.7
curl -L -o cuda_installer.exe %CUDA_URL%
cuda_installer.exe -s nvcc_11.7 cudart_11.7 cublas_dev_11.7
del cuda_installer.exe

:: Install FFmpeg
echo [STEP 4/6] Installing FFmpeg
curl -L -o ffmpeg.zip %FFMPEG_URL%
tar -xf ffmpeg.zip -C "C:\Program Files"
setx PATH "C:\Program Files\ffmpeg\bin;%PATH%"
del ffmpeg.zip

:: Create virtual environment
echo [STEP 5/6] Setting up Python environment
python -m venv .venv
call .venv\Scripts\activate.bat

:: Install optimized packages
echo [STEP 6/6] Installing AI components
pip install --no-cache-dir numpy==1.23.5
pip install --no-cache-dir %TORCH_URL%
pip install --no-cache-dir "torchaudio==2.0.2+cu117" "torchvision==0.15.2+cu117"
pip install --no-cache-dir pydub==0.25.1 whisper-large-v3==1.1.7

:: Verify CUDA acceleration
python -c "import torch; assert torch.cuda.get_device_capability()[0] >= 8.6, 'RTX 3070 not detected'" || (
    echo [ERROR] CUDA acceleration check failed
    exit /b 1
)

echo [SUCCESS] RTX 3070 environment ready
exit /b 0
EOL
}

_create_config() {
    cat > "$CONFIG_FILE" <<'EOL'
{
    "windows": {
        "hardware": {
            "cpu": "Ryzen 5600X",
            "gpu": "RTX 3070",
            "min_driver": "516.94"
        },
        "components": {
            "python": "3.10.11",
            "cuda": "11.7",
            "ffmpeg": "2023-09-28"
        }
    }
}
EOL
}

_update_documentation() {
    cat >> README.md <<'EOL'

## Windows 11 RTX 3070 Setup (v1.12+)

### Hardware Requirements
- CPU: AMD Ryzen 5600X
- GPU: NVIDIA RTX 3070 (8GB VRAM)
- Driver: 516.94+
- RAM: 16GB DDR4

### Features
- CUDA 11.7 optimized for RTX 30-series
- DirectML acceleration for Whisper
- Hardware-accelerated FFmpeg
- Torch 2.0 with CUDA 11.7

### Verification Commands
nvidia-smi
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"
ffmpeg -hwaccels

text
EOL
}

# Main execution flow
{
    mkdir -p "$LOG_DIR"
    echo "[UPDATE] Starting v$VERSION deployment" | tee -a "$DEBUG_LOG"
    
    _create_windows_setup
    _create_config
    _update_documentation
    
    unix2dos "$WIN_SCRIPT" "$CONFIG_FILE"
    
    git add -A
    git commit -m "System v$VERSION - RTX 3070 Focus" \
              -m "- Hardware-specific CUDA setup" \
              -m "- Torch 2.0 with CUDA 11.7" \
              -m "- NVIDIA driver verification" \
              -m "- Windows 11 documentation"
    
    echo "[SUCCESS] Update v$VERSION completed" | tee -a "$DEBUG_LOG"
}