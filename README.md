# Discord Standup Bot Project

## Project Overview
Automated standup recording and task management system for Discord

## Installation
git clone https://github.com/yourrepo/discord-standup-bot.git
cd discord-standup-bot
bash scripts/setup.sh

text


## Bot Configuration Guide
1. Create Discord application at [developer portal](https://discord.com/developers)
2. Copy bot token into config/config.json
3. Set recording quality:
   - 720p: 3Mbps video, 96kbps audio
   - 480p: 1.5Mbps video, 64kbps audio
4. Choose AI models based on hardware:
   - Minimum (RTX 2060): Whisper Tiny + Mistral-7B
   - Recommended (RTX 3070): Whisper Medium + Mistral-7B-Q4


## Bot Configuration Guide
1. Create Discord application at [developer portal](https://discord.com/developers)
2. Copy bot token into config/config.json
3. Set recording quality:
   - 720p: 3Mbps video, 96kbps audio
   - 480p: 1.5Mbps video, 64kbps audio
4. Choose AI models based on hardware:
   - Minimum (RTX 2060): Whisper Tiny + Mistral-7B
   - Recommended (RTX 3070): Whisper Medium + Mistral-7B-Q4


## Logging Architecture (v1.6+)
- **Unified Format**: `[YYYY-MM-DDTHH:MM:SS+TZ] [LEVEL] Message`
- **Log Files**:
  - `update.log`: System update records
  - `setup.log`: Environment configuration
  - `build.log`: Compilation outputs  
  - `test.log`: Validation results
  - `deploy.log`: Service management
  - `aifeedback.log`: Diagnostic reports


## AI Context Builder (v1.7+)

Generate project snapshot
bash scripts/ai_search.sh

Output format:
#PROJECT_CONTEXT v1.7
##META|<unix_ts>|<git_sha>
##DIRTREE
DIR|<path>|<file_count>
##DEPS
<dependency_line>
##SCRIPTS
SCRIPT|<path>|<desc>|<version>|<log_lines>
##CONFIG
CFG|<file>|<type>
##TESTS
PYTEST|<count>
CASES|<count>
##ERRORS
<error_line>
##ARTIFACTS
BUILD_OUT|<count>

text


## AI Context Builder v1.8+

### Machine-Readable Format
#PROJECT_CONTEXT v1.8
##META|<unix_ts>|<git_ref>
##DIRTREE
DIR|<path>|<file_count>|<size>
##DEPS
<type>|<name>|<version>
##SCRIPTS
SCRIPT|<path>|<version>|<log_count>|<gpu_usage>
##CONFIG
CFG|<path>|<mime_type>|<validation>
##TESTS
PYTEST|<count>|<cases>|<coverage>
##ERRORS
<type>|<message>
##ARTIFACTS
ARTIFACT|<path>|<size>|<md5>
### Usage
Generate context (outputs to project_context.txt)
./scripts/ai_search.sh

Validate context format
file project_context.txt | grep 'ASCII text'

text

### Monitoring
Watch context generation
tail -f logs/project_scan/context_builder.log

Verify artifact integrity
md5sum project_context.txt

text

## Logging Architecture v1.9+

### Error Code Mapping
| Code | Description | Source |
|------|-------------|--------|
| 101  | Missing required command | ai_search.sh |
| 102  | Empty context file | ai_search.sh |
| E102 | Missing Python venv | aifeedback.sh |
| E110 | GPU inaccessible | aifeedback.sh |

### Debugging Commands
Full system check
./scripts/aifeedback.sh

Generate debug context
DEBUG=1 ./scripts/ai_search.sh

Monitor GPU utilization
nvidia-smi -l 5 --query-gpu=utilization.gpu --format=csv

text

## AI Context Builder v1.10+

### Error Code Mapping
| Code | Description | Category |
|------|-------------|----------|
| E101 | Missing command | Dependency |
| E201 | Insufficient VRAM | Hardware |
| E203 | Missing GPU | Hardware |
| E301 | Missing model | AI Config |
| E401 | Encryption issue | Security |

### Report Format
#PROJECT_CONTEXT v1.10
##META|<unix_ts>|<git_ref>
##DEPCHECK
DEP|<status>|<command>|<code>
##HARDWARE
GPU|<name>|<driver>|<vram>
##INFRA
DIR|<name>|<file_count>
##ISSUES
ISSUE|<code>|<description>

text

### Usage
Generate context with full diagnostics
./scripts/ai_search.sh

Check for critical errors
grep 'ISSUE|E[2-3]' project_context.txt

text

## Update v1.11 Fixes

### Error Code Enhancements
- E101: Missing required command (aligned with ai_feedback.sh checks)
- E103: Missing directory (matches update-1.4 infrastructure requirements)

### Verification Command
Check for unbound variables
bash -n scripts/ai_search.sh

Test context generation
rm -rf logs/project_scan && ./scripts/ai_search.sh

text

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

## Windows 11 RTX 3070 Setup (v1.13+)

### System Requirements
- OS: Windows 11 22H2+
- CPU: AMD Ryzen 5600X
- GPU: NVIDIA RTX 3070 (8GB VRAM)
- Driver: 516.94+
- RAM: 16GB DDR4

### Features
- Automatic CUDA 11.7 installation
- Hardware-accelerated media processing
- Pre-configured Python environment
- NVIDIA GPU verification

### Verification Commands
nvidia-smi
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"
ffmpeg -hwaccels | Select-String 'cuda'

text

## VS Code Configuration (v1.14+)

### Recommended Setup
1. Install [VS Code](https://code.visualstudio.com/)
2. Open the project folder
3. Accept extension recommendations when prompted

### Key Features
- Preconfigured Python environment paths
- Integrated debugging profiles
- AI-assisted development (GitHub Copilot)
- Auto-formatting with Black
- Linting with Pylance/Ruff

### Debugging
- **Discord Bot**: F5 to start with production settings
- **AI Pipeline**: Test runner configuration
- **Full System**: Launch all components


## Linux VSCode Setup (v1.15+)

### Configuration Features
- Python virtual environment integration
- Pylance/Ruff language server setup
- Preconfigured debug profiles
- Git-ignored temporary files

### First-Time Setup
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

text

### Recommended Workflow
1. Open workspace: `code discord-standup-bot.code-workspace`
2. Install recommended extensions
3. Select Python interpreter (Ctrl+Shift+P > "Python: Select Interpreter")
4. Start debugging with F5

## Windows Setup Troubleshooting (v1.16+)

### Log File Location
`logs/windows/setup-<date>-<time>.log`

### Common Errors
| Error Code | Description | Solution |
|-----------|-------------|----------|
| E101 | Python download failed | Check internet connection |
| E102 | CUDA install failed | Verify driver version ≥516.94 |
| E103 | Virtual env creation | Delete existing .venv directory |

### Verbose Logging Features
- Timestamped operation tracking
- Full package install output
- Error code capture
- Environment verification

