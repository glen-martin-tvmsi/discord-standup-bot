<#
.SYNOPSIS
Update v1.16 - Windows-PowerShell-Compatible Deployment

.DESCRIPTION
Configures verbose logging and Windows-specific setup while maintaining Linux compatibility
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param()

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$script:Version = "1.16"

# Configure logging
$LogDir = "logs\windows-updates"
$LogFile = "$LogDir\update-$($script:Version)-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level="INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-File $LogFile -Append -Encoding utf8
    if ($Level -eq "ERROR") { Write-Host $Message -ForegroundColor Red }
}

try {
    # Create log directory
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null

    Start-Transcript -Path $LogFile -Append

    Write-Log "Starting update v$($script:Version)"
    Write-Verbose "Verbose logging enabled" -Verbose

    # Update setup script with enhanced logging
    $setupScript = @'
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$LogDir = "logs\windows"
$LogFile = "$LogDir\setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

try {
    # Require admin privileges
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        throw "Run this script as Administrator"
    }

    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    Start-Transcript -Path $LogFile -Append

    Write-Host "Installing Python 3.10..." -ForegroundColor Cyan
    $pythonUrl = "https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe"
    Invoke-WebRequest -Uri $pythonUrl -OutFile "python_installer.exe" -UseBasicParsing
    
    Start-Process python_installer.exe -ArgumentList '/quiet InstallAllUsers=0 PrependPath=1 Include_test=0' -Wait
    Remove-Item python_installer.exe -Force

    # Verify Python
    if (-NOT (Get-Command python -ErrorAction SilentlyContinue)) {
        throw "Python installation failed"
    }

    Write-Host "Installing CUDA 11.7..." -ForegroundColor Cyan
    $cudaUrl = "https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_516.94_windows.exe"
    Invoke-WebRequest -Uri $cudaUrl -OutFile "cuda_installer.exe" -UseBasicParsing
    Start-Process cuda_installer.exe -ArgumentList '-s nvcc_11.7 cudart_11.7 cublas_dev_11.7' -Wait
    Remove-Item cuda_installer.exe -Force

    # Create venv
    Write-Host "Creating Python environment..." -ForegroundColor Cyan
    python -m venv .venv
    
    # Install packages with verbose output
    .\.venv\Scripts\activate.ps1
    pip install -v --no-cache-dir numpy==1.23.5 torch==2.0.1+cu117 torchaudio==2.0.2+cu117 torchvision==0.15.2+cu117

    # Final verification
    python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
    
} catch {
    Write-Log "SETUP FAILED: $_" -Level ERROR
    throw
} finally {
    Stop-Transcript
}
'@

    Set-Content -Path "scripts\setup.ps1" -Value $setupScript -Encoding utf8
    Write-Log "Created updated setup.ps1"

    # Update documentation
    Add-Content -Path README.md @"

## Windows Setup Guide (v1.16+)

### Requirements
- PowerShell 5.1+
- Administrator privileges
- NVIDIA Driver 516.94+

### Usage
Run setup with verbose logging
.\scripts\setup.ps1 -Verbose

Check logs
Get-Content $(Resolve-Path $LogFile)

text

### Troubleshooting
- If scripts are blocked: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Enable developer mode for symlink support
"@

    Write-Log "Update v$($script:Version) completed successfully"
    Write-Host "✅ Update completed! Log: $LogFile" -ForegroundColor Green

} catch {
    Write-Log "UPDATE FAILED: $_" -Level ERROR
    Write-Host "❌ Update failed! Check $LogFile" -ForegroundColor Red
    exit 1
} finally {
    Stop-Transcript
}