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
