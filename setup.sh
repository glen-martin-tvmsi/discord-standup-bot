#!/bin/bash
# setup.sh - Full Environment Initialization for Discord Voice Bot

set -eo pipefail

# Create project structure
mkdir -p {src/audio_processing,src/bot_handlers,config,scripts,test/unit,test/integration,logs}

# Install system dependencies
sudo apt-get update && sudo apt-get install -y \
    python3.10-venv \
    ffmpeg \
    python3-pip \
    libportaudio2 \
    libasound2-dev

# Set up Python environment
python3 -m venv .venv --upgrade-deps
source .venv/bin/activate

# Install Python dependencies
pip install --no-cache-dir \
    discord.py==2.3.2 \
    python-dotenv==1.0.0 \
    pydub==0.25.1 \
    ffmpeg-python==0.2.0 \
    soundfile==0.12.1 \
    numpy==1.24.3 \
    requests==2.31.0

# Create configuration files
cat > config/.env <<'ENV'
DISCORD_TOKEN=your_token_here
RECORDINGS_DIR=./recordings
WHISPER_MODEL=medium.en
LOG_LEVEL=INFO
ENV

cat > .gitignore <<'GIT'
.venv/
__pycache__/
*.log
*.wav
*.mp3
*.env
*.swp
recordings/
logs/
GIT

# Create core bot files
cat > src/bot_handlers/voice_recorder.py <<'PY'
import os
import discord
from discord.ext import commands
from dotenv import load_dotenv

load_dotenv('../config/.env')

class VoiceRecorder(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
        self.recordings_dir = os.getenv('RECORDINGS_DIR', './recordings')
        os.makedirs(self.recordings_dir, exist_ok=True)

    @commands.Cog.listener()
    async def on_voice_state_update(self, member, before, after):
        if before.channel != after.channel:
            print(f"Member {member} changed voice channels")

async def setup(bot):
    await bot.add_cog(VoiceRecorder(bot))
PY

cat > src/bot_handlers/event_monitor.py <<'PY'
from discord.ext import commands
import logging

logging.basicConfig(level=logging.INFO)

class EventMonitor(commands.Cog):
    def __init__(self, bot):
        self.bot = bot

    @commands.Cog.listener()
    async def on_ready(self):
        logging.info(f'Logged in as {self.bot.user}')

async def setup(bot):
    await bot.add_cog(EventMonitor(bot))
PY

# Create helper scripts
cat > scripts/deploy.sh <<'DEPLOY'
#!/bin/bash
set -eo pipefail

source ../.venv/bin/activate
python -m src.bot_handlers.voice_recorder &
python -m src.bot_handlers.event_monitor &
wait
DEPLOY

cat > scripts/verify_environment.sh <<'VERIFY'
#!/bin/bash
declare -A deps=(
    ["python3"]="3.8"
    ["ffmpeg"]="4.2"
    ["pip"]="20.0"
)

for cmd in "${!deps[@]}"; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ Missing dependency: $cmd"
        exit 1
    fi
done
echo "✅ Environment verified"
VERIFY

# Set permissions
chmod +x scripts/*.sh

# Install Python type stubs
pip install pyright types-requests types-python-dateutil

# Post-setup message
echo -e "\n\033[1;32mSetup complete!\033[0m
Next steps:
1. Set your Discord token in config/.env
2. Activate virtual environment:
   source .venv/bin/activate
3. Start the bot:
   ./scripts/deploy.sh
"
