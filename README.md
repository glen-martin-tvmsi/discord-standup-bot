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

